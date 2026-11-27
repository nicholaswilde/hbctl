use std::io::Cursor;
use std::path::Path;

use image::codecs::jpeg::JpegEncoder;
use image::codecs::png::{CompressionType, FilterType as PngFilterType, PngEncoder};
use image::imageops::FilterType;
use image::{
    DynamicImage, GenericImageView, ImageDecoder, ImageFormat, ImageReader, Rgb, RgbImage,
};

use crate::config::AppConfig;
use crate::error::{HbctlError, Result};

const JPEG_QUALITIES: [u8; 6] = [85, 75, 65, 55, 45, 35];
const FALLBACK_QUALITIES: [u8; 3] = [75, 55, 35];
const MAX_SCALE_ROUNDS: usize = 10;
const MIN_SCALE_DIMENSION: u32 = 64;

/// Runtime options controlling image upload size guard and optimization.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ImageOptOptions {
    pub optimize: bool,
    pub force: bool,
    pub max_bytes: u64,
    pub max_dimension: u32,
}

impl ImageOptOptions {
    pub fn from_config(config: &AppConfig, cli_optimize: bool, force: bool) -> Self {
        Self {
            optimize: cli_optimize || config.auto_optimize,
            force,
            max_bytes: config.max_image_bytes(),
            max_dimension: config.max_image_dimension,
        }
    }
}

/// Prepared attachment payload ready for upload.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PreparedImageBytes {
    pub bytes: Vec<u8>,
    pub remote_name: String,
    pub original_bytes: u64,
    pub optimized: bool,
    pub original_dimensions: Option<(u32, u32)>,
    pub final_dimensions: Option<(u32, u32)>,
}

/// Optimize oversized image bytes in memory when `opts.optimize` is enabled,
/// preserving non-image attachments, compliant images, and `--force` overrides untouched.
pub fn optimize_attachment_bytes(
    display_path: &str,
    remote_name: &str,
    bytes: Vec<u8>,
    opts: ImageOptOptions,
) -> Result<PreparedImageBytes> {
    let original_bytes = bytes.len() as u64;
    let mime = mime_guess::from_path(remote_name).first_or_octet_stream();
    if mime.type_() != "image" || original_bytes <= opts.max_bytes || opts.force {
        return Ok(PreparedImageBytes {
            bytes,
            remote_name: remote_name.to_string(),
            original_bytes,
            optimized: false,
            original_dimensions: None,
            final_dimensions: None,
        });
    }

    if !opts.optimize {
        return Err(HbctlError::ImageTooLarge {
            path: display_path.to_string(),
            size_bytes: original_bytes,
            max_bytes: opts.max_bytes,
        });
    }

    let reader = ImageReader::new(Cursor::new(&bytes))
        .with_guessed_format()
        .map_err(|e| optimize_decode_err(display_path, e))?;
    let detected_format = reader.format();
    let mut decoder = reader
        .into_decoder()
        .map_err(|e| optimize_decode_err(display_path, e))?;
    let orientation = decoder
        .orientation()
        .map_err(|e| optimize_decode_err(display_path, e))?;
    let mut img =
        DynamicImage::from_decoder(decoder).map_err(|e| optimize_decode_err(display_path, e))?;
    img.apply_orientation(orientation);

    let orig_dims = img.dimensions();
    if img.width() > opts.max_dimension || img.height() > opts.max_dimension {
        img = img.resize(
            opts.max_dimension,
            opts.max_dimension,
            FilterType::CatmullRom,
        );
    }

    let source_format = detected_format.or_else(|| ImageFormat::from_path(remote_name).ok());
    let mut last_size = original_bytes;

    match source_format {
        Some(ImageFormat::Png) => {
            if let Ok(encoded) = encode_png(&img) {
                last_size = encoded.len() as u64;
                if last_size <= opts.max_bytes {
                    return Ok(PreparedImageBytes {
                        bytes: encoded,
                        remote_name: remote_name.to_string(),
                        original_bytes,
                        optimized: true,
                        original_dimensions: Some(orig_dims),
                        final_dimensions: Some(img.dimensions()),
                    });
                }
            }
        }
        Some(ImageFormat::WebP) => {
            if let Ok(encoded) = encode_webp(&img) {
                last_size = encoded.len() as u64;
                if last_size <= opts.max_bytes {
                    return Ok(PreparedImageBytes {
                        bytes: encoded,
                        remote_name: remote_name.to_string(),
                        original_bytes,
                        optimized: true,
                        original_dimensions: Some(orig_dims),
                        final_dimensions: Some(img.dimensions()),
                    });
                }
            }
        }
        _ => {}
    }

    let jpeg_name = resolve_jpeg_remote_name(remote_name, source_format);
    if let Some(encoded) = try_jpeg_ladder(&img, &JPEG_QUALITIES, opts.max_bytes)? {
        return Ok(PreparedImageBytes {
            bytes: encoded,
            remote_name: jpeg_name,
            original_bytes,
            optimized: true,
            original_dimensions: Some(orig_dims),
            final_dimensions: Some(img.dimensions()),
        });
    } else if let Some(size) = try_jpeg_last_size(&img, &JPEG_QUALITIES)? {
        last_size = size;
    }

    for _ in 0..MAX_SCALE_ROUNDS {
        if img.width().max(img.height()) <= MIN_SCALE_DIMENSION {
            break;
        }
        let next_w = ((img.width() as f64) * 0.75).round().max(1.0) as u32;
        let next_h = ((img.height() as f64) * 0.75).round().max(1.0) as u32;
        if next_w == img.width() && next_h == img.height() {
            break;
        }
        img = img.resize_exact(next_w, next_h, FilterType::CatmullRom);
        if let Some(encoded) = try_jpeg_ladder(&img, &FALLBACK_QUALITIES, opts.max_bytes)? {
            return Ok(PreparedImageBytes {
                bytes: encoded,
                remote_name: jpeg_name,
                original_bytes,
                optimized: true,
                original_dimensions: Some(orig_dims),
                final_dimensions: Some(img.dimensions()),
            });
        } else if let Some(size) = try_jpeg_last_size(&img, &FALLBACK_QUALITIES)? {
            last_size = size;
        }
    }

    Err(HbctlError::ImageTooLarge {
        path: display_path.to_string(),
        size_bytes: last_size,
        max_bytes: opts.max_bytes,
    })
}

fn optimize_decode_err(display_path: &str, err: impl std::fmt::Display) -> HbctlError {
    HbctlError::InvalidInput(format!(
        "failed to optimize image '{display_path}': {err} (pass --force to upload as-is)"
    ))
}

fn encode_png(img: &DynamicImage) -> std::result::Result<Vec<u8>, image::ImageError> {
    let mut buf = Vec::new();
    let encoder =
        PngEncoder::new_with_quality(&mut buf, CompressionType::Default, PngFilterType::Adaptive);
    img.write_with_encoder(encoder)?;
    Ok(buf)
}

fn encode_webp(img: &DynamicImage) -> std::result::Result<Vec<u8>, image::ImageError> {
    let mut buf = Vec::new();
    img.write_to(&mut Cursor::new(&mut buf), ImageFormat::WebP)?;
    Ok(buf)
}

fn encode_jpeg(rgb: &RgbImage, quality: u8) -> Result<Vec<u8>> {
    let mut buf = Vec::new();
    let encoder = JpegEncoder::new_with_quality(&mut buf, quality);
    rgb.write_with_encoder(encoder)
        .map_err(|e| HbctlError::InvalidInput(format!("failed to encode JPEG: {e}")))?;
    Ok(buf)
}

fn try_jpeg_ladder(
    img: &DynamicImage,
    qualities: &[u8],
    max_bytes: u64,
) -> Result<Option<Vec<u8>>> {
    let rgb = flatten_to_rgb8(img);
    for &q in qualities {
        let encoded = encode_jpeg(&rgb, q)?;
        if encoded.len() as u64 <= max_bytes {
            return Ok(Some(encoded));
        }
    }
    Ok(None)
}

fn try_jpeg_last_size(img: &DynamicImage, qualities: &[u8]) -> Result<Option<u64>> {
    let Some(&q) = qualities.last() else {
        return Ok(None);
    };
    let rgb = flatten_to_rgb8(img);
    let encoded = encode_jpeg(&rgb, q)?;
    Ok(Some(encoded.len() as u64))
}

/// Flatten alpha onto a white background so transparent PNG/WebP convert cleanly to JPEG.
fn flatten_to_rgb8(img: &DynamicImage) -> RgbImage {
    if !img.color().has_alpha() {
        return img.to_rgb8();
    }
    let rgba = img.to_rgba8();
    let (w, h) = rgba.dimensions();
    let mut out = RgbImage::new(w, h);
    for (x, y, px) in rgba.enumerate_pixels() {
        let [r, g, b, a] = px.0;
        let alpha = a as u16;
        let inv = 255 - alpha;
        let blend = |c: u8| -> u8 { ((c as u16 * alpha + 255 * inv + 127) / 255) as u8 };
        out.put_pixel(x, y, Rgb([blend(r), blend(g), blend(b)]));
    }
    out
}

fn resolve_jpeg_remote_name(remote_name: &str, source_format: Option<ImageFormat>) -> String {
    let path = Path::new(remote_name);
    let has_jpeg_ext = path
        .extension()
        .and_then(|e| e.to_str())
        .map(|e| e.eq_ignore_ascii_case("jpg") || e.eq_ignore_ascii_case("jpeg"))
        .unwrap_or(false);
    if source_format == Some(ImageFormat::Jpeg) || has_jpeg_ext {
        return remote_name.to_string();
    }
    if path.extension().is_some() {
        path.with_extension("jpg").to_string_lossy().into_owned()
    } else {
        format!("{remote_name}.jpg")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use image::RgbaImage;

    fn noisy_rgb(width: u32, height: u32) -> DynamicImage {
        let mut img = RgbImage::new(width, height);
        let mut state: u64 = 0x9E37_79B9_7F4A_7C15;
        for (x, y, px) in img.enumerate_pixels_mut() {
            state ^= state << 13;
            state ^= state >> 7;
            state ^= state << 17;
            let r = ((state ^ (x as u64 * 17)) & 0xFF) as u8;
            let g = (((state >> 8) ^ (y as u64 * 31)) & 0xFF) as u8;
            let b = (((state >> 16) ^ ((x + y) as u64 * 13)) & 0xFF) as u8;
            *px = Rgb([r, g, b]);
        }
        DynamicImage::ImageRgb8(img)
    }

    fn noisy_rgba(width: u32, height: u32) -> DynamicImage {
        let mut img = RgbaImage::new(width, height);
        let mut state: u64 = 0xD1B5_4A32_D192_ED03;
        for (x, y, px) in img.enumerate_pixels_mut() {
            state ^= state << 13;
            state ^= state >> 7;
            state ^= state << 17;
            let r = ((state ^ (x as u64 * 19)) & 0xFF) as u8;
            let g = (((state >> 8) ^ (y as u64 * 23)) & 0xFF) as u8;
            let b = (((state >> 16) ^ ((x ^ y) as u64 * 29)) & 0xFF) as u8;
            let a = if (x + y) % 10 == 0 { 128 } else { 255 };
            *px = image::Rgba([r, g, b, a]);
        }
        DynamicImage::ImageRgba8(img)
    }

    fn encode_test(img: &DynamicImage, fmt: ImageFormat) -> Vec<u8> {
        let mut buf = Vec::new();
        img.write_to(&mut Cursor::new(&mut buf), fmt).unwrap();
        buf
    }

    fn default_opt_opts() -> ImageOptOptions {
        ImageOptOptions {
            optimize: true,
            force: false,
            max_bytes: 500 * 1024,
            max_dimension: 1920,
        }
    }

    #[test]
    fn test_optimize_oversized_jpeg_resizes_and_compresses_under_budget() {
        let img = noisy_rgb(2400, 1800);
        let raw = encode_test(&img, ImageFormat::Jpeg);
        assert!(raw.len() > 500 * 1024, "fixture must exceed 500KB");

        let res =
            optimize_attachment_bytes("photo.jpg", "photo.jpg", raw, default_opt_opts()).unwrap();
        assert!(res.optimized);
        assert_eq!(res.remote_name, "photo.jpg");
        assert!(res.bytes.len() as u64 <= 500 * 1024);
        assert_eq!(res.original_dimensions, Some((2400, 1800)));
        let (fw, fh) = res.final_dimensions.unwrap();
        assert!(fw <= 1920 && fh <= 1920);
        let decoded = ImageReader::new(Cursor::new(&res.bytes))
            .with_guessed_format()
            .unwrap();
        assert_eq!(decoded.format(), Some(ImageFormat::Jpeg));
    }

    #[test]
    fn test_optimize_simple_oversized_png_stays_png() {
        // Large low-entropy PNG > 500KB that shrinks < 500KB as PNG after resizing
        let mut img = RgbImage::new(3200, 2400);
        for (x, y, px) in img.enumerate_pixels_mut() {
            // Smooth-ish banded pattern that still exceeds 500KB at 3200x2400 but compresses well at <=1920
            let band = ((x / 8 + y / 8) % 255) as u8;
            let fine = ((x % 3) * 15) as u8;
            *px = Rgb([band, band.wrapping_add(fine), (y % 255) as u8]);
        }
        let dyn_img = DynamicImage::ImageRgb8(img);
        let raw = encode_test(&dyn_img, ImageFormat::Png);
        // Ensure fixture is oversized for a budget just below raw size
        let budget = (raw.len() as u64).saturating_sub(1024).min(500 * 1024);
        // Use a budget slightly smaller than raw if raw <= 500KB, or 500KB if raw > 500KB
        let effective_budget = if raw.len() as u64 > 500 * 1024 {
            500 * 1024
        } else {
            budget
        };
        let opts = ImageOptOptions {
            optimize: true,
            force: false,
            max_bytes: effective_budget,
            max_dimension: 1200,
        };
        let res = optimize_attachment_bytes("diagram.png", "diagram.png", raw, opts).unwrap();
        assert!(res.optimized);
        assert!(res.bytes.len() as u64 <= effective_budget);
        assert_eq!(res.remote_name, "diagram.png");
        let decoded = ImageReader::new(Cursor::new(&res.bytes))
            .with_guessed_format()
            .unwrap();
        assert_eq!(decoded.format(), Some(ImageFormat::Png));
    }

    #[test]
    fn test_optimize_noisy_png_falls_back_to_jpeg() {
        let img = noisy_rgba(1200, 900);
        let raw = encode_test(&img, ImageFormat::Png);
        assert!(raw.len() > 500 * 1024, "noisy PNG must exceed 500KB");

        let res =
            optimize_attachment_bytes("camera.png", "camera.png", raw, default_opt_opts()).unwrap();
        assert!(res.optimized);
        assert_eq!(res.remote_name, "camera.jpg");
        assert!(res.bytes.len() as u64 <= 500 * 1024);
        let decoded = ImageReader::new(Cursor::new(&res.bytes))
            .with_guessed_format()
            .unwrap();
        assert_eq!(decoded.format(), Some(ImageFormat::Jpeg));
    }

    #[test]
    fn test_optimize_oversized_webp_compresses_under_budget() {
        let img = noisy_rgb(1200, 900);
        let raw = encode_test(&img, ImageFormat::WebP);
        assert!(
            raw.len() > 500 * 1024,
            "lossless noisy WebP must exceed 500KB"
        );

        let res =
            optimize_attachment_bytes("scan.webp", "scan.webp", raw, default_opt_opts()).unwrap();
        assert!(res.optimized);
        assert!(res.bytes.len() as u64 <= 500 * 1024);
        assert!(res.remote_name == "scan.webp" || res.remote_name == "scan.jpg");
    }

    #[test]
    fn test_optimize_compression_fallback_scales_dimensions_for_tight_budget() {
        let img = noisy_rgb(1600, 1200);
        let raw = encode_test(&img, ImageFormat::Jpeg);
        assert!(raw.len() > 25 * 1024);

        let opts = ImageOptOptions {
            optimize: true,
            force: false,
            max_bytes: 25 * 1024,
            max_dimension: 1920,
        };
        let res = optimize_attachment_bytes("tight.jpg", "tight.jpg", raw, opts).unwrap();
        assert!(res.optimized);
        assert!(res.bytes.len() as u64 <= 25 * 1024);
        let (fw, fh) = res.final_dimensions.unwrap();
        assert!(fw < 1600 && fh < 1200);
    }

    #[test]
    fn test_non_image_and_compliant_and_force_passthrough() {
        // Non-image > 500KB passes through untouched
        let pdf_bytes = vec![b'%'; 600 * 1024];
        let pdf_res = optimize_attachment_bytes(
            "manual.pdf",
            "manual.pdf",
            pdf_bytes.clone(),
            default_opt_opts(),
        )
        .unwrap();
        assert!(!pdf_res.optimized);
        assert_eq!(pdf_res.bytes, pdf_bytes);
        assert_eq!(pdf_res.remote_name, "manual.pdf");

        // Compliant image <= 500KB passes through untouched
        let small_img = noisy_rgb(100, 100);
        let small_jpg = encode_test(&small_img, ImageFormat::Jpeg);
        assert!(small_jpg.len() < 500 * 1024);
        let small_res = optimize_attachment_bytes(
            "small.jpg",
            "small.jpg",
            small_jpg.clone(),
            default_opt_opts(),
        )
        .unwrap();
        assert!(!small_res.optimized);
        assert_eq!(small_res.bytes, small_jpg);

        // --force bypasses optimization even when optimize=true
        let big_raw = vec![0u8; 520 * 1024];
        let force_res = optimize_attachment_bytes(
            "huge.png",
            "huge.png",
            big_raw.clone(),
            ImageOptOptions {
                optimize: true,
                force: true,
                max_bytes: 500 * 1024,
                max_dimension: 1920,
            },
        )
        .unwrap();
        assert!(!force_res.optimized);
        assert_eq!(force_res.bytes, big_raw);

        // Without optimize or force, oversized image returns ImageTooLarge
        let err = optimize_attachment_bytes(
            "huge.png",
            "huge.png",
            big_raw,
            ImageOptOptions {
                optimize: false,
                force: false,
                max_bytes: 500 * 1024,
                max_dimension: 1920,
            },
        )
        .unwrap_err();
        assert!(matches!(err, HbctlError::ImageTooLarge { .. }));

        // Corrupt oversized image with optimize=true fails cleanly with InvalidInput
        let corrupt = vec![b'x'; 520 * 1024];
        let corrupt_err =
            optimize_attachment_bytes("bad.jpg", "bad.jpg", corrupt, default_opt_opts())
                .unwrap_err();
        assert!(matches!(corrupt_err, HbctlError::InvalidInput(_)));
    }
}
