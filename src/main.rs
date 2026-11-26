//! Homebox (`hbx`) CLI application entrypoint.
//!
//! A thin binary dispatch wrapper delegating execution to the `hbx` library crate.

fn main() -> anyhow::Result<()> {
    hbx::run()
}
