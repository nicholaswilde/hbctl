use std::fs;
use std::path::PathBuf;
use std::process::Command as StdCommand;

use assert_cmd::Command;
use mockito::{Matcher, Server};
use predicates::prelude::*;
use serde_json::{json, Value};
use tempfile::tempdir;

fn fixture(name: &str) -> String {
    let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("tests")
        .join("fixtures")
        .join(name);
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("failed to read fixture {name}: {e}"))
}

/// Preflight guard for `cross`/QEMU environments without binfmt_misc sysroot.
fn can_execute_binary() -> bool {
    let bin = env!("CARGO_BIN_EXE_hbx");
    matches!(
        StdCommand::new(bin).arg("--version").output(),
        Ok(o) if o.status.success()
    )
}

fn hbx(server_url: &str) -> Command {
    let mut cmd = Command::new(env!("CARGO_BIN_EXE_hbx"));
    cmd.env_clear()
        .env("PATH", std::env::var("PATH").unwrap_or_default())
        .arg("--url")
        .arg(server_url)
        .arg("--api-key")
        .arg("hb_test_secret_token_999");
    cmd
}

#[test]
fn test_item_crud_and_followup_put_for_fields() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();

    let tags_mock = server
        .mock("GET", "/api/v1/tags")
        .match_header("authorization", "Bearer hb_test_secret_token_999")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(fixture("tags.json"))
        .create();

    let post_mock = server
        .mock("POST", "/api/v1/entities")
        .match_header("authorization", "Bearer hb_test_secret_token_999")
        .with_status(201)
        .with_header("content-type", "application/json")
        .with_body(
            json!({
                "id": "ent-new-1",
                "name": "STM32 Nucleo",
                "description": "ARM board",
                "quantity": 2,
                "tagIds": ["tag-elec"],
                "fields": []
            })
            .to_string(),
        )
        .create();

    // Homebox POST drops custom fields -> client MUST issue follow-up PUT with fields
    let followup_put = server
        .mock("PUT", "/api/v1/entities/ent-new-1")
        .match_header("authorization", "Bearer hb_test_secret_token_999")
        .match_body(Matcher::AllOf(vec![
            Matcher::Regex("\"Manufacturer\"".to_string()),
            Matcher::Regex("\"STMicro\"".to_string()),
            Matcher::Regex("\"Voltage\"".to_string()),
        ]))
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(
            json!({
                "id": "ent-new-1",
                "name": "STM32 Nucleo",
                "description": "ARM board",
                "quantity": 2,
                "tagIds": ["tag-elec"],
                "fields": [
                    {"name": "Manufacturer", "type": "text", "value": "STMicro", "textValue": "STMicro"},
                    {"name": "Voltage", "type": "text", "value": "3.3", "textValue": "3.3"}
                ]
            })
            .to_string(),
        )
        .create();

    let output = hbx(&server.url())
        .args([
            "--json",
            "item",
            "create",
            "--name",
            "STM32 Nucleo",
            "--description",
            "ARM board",
            "--quantity",
            "2",
            "--tag",
            "Electronics",
            "--manufacturer",
            "STMicro",
            "--field",
            "Voltage=3.3",
        ])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();

    tags_mock.assert();
    post_mock.assert();
    followup_put.assert();

    let created: Value = serde_json::from_slice(&output).unwrap();
    assert_eq!(created["id"], "ent-new-1");
    assert_eq!(created["fields"].as_array().unwrap().len(), 2);

    // GET + Merge + PUT update preserves existing Manufacturer while updating quantity and adding Notes
    let get_mock = server
        .mock("GET", "/api/v1/entities/ent-1")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(fixture("entity_detail.json"))
        .create();

    let update_put = server
        .mock("PUT", "/api/v1/entities/ent-1")
        .match_body(Matcher::AllOf(vec![
            Matcher::Regex("\"quantity\":5".to_string()),
            Matcher::Regex("\"Manufacturer\"".to_string()),
            Matcher::Regex("\"Notes\"".to_string()),
            Matcher::Regex("\"Drawer B\"".to_string()),
        ]))
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(fixture("entity_detail.json"))
        .create();

    hbx(&server.url())
        .args([
            "--quiet",
            "item",
            "update",
            "ent-1",
            "--quantity",
            "5",
            "--notes",
            "Drawer B",
        ])
        .assert()
        .success()
        .stdout(predicate::eq("ent-1\n"));

    get_mock.assert();
    update_put.assert();

    // Delete item
    let del_mock = server
        .mock("DELETE", "/api/v1/entities/ent-1")
        .with_status(204)
        .create();

    hbx(&server.url())
        .args(["-q", "item", "delete", "ent-1", "--force"])
        .assert()
        .success()
        .stdout(predicate::eq("ent-1\n"));

    del_mock.assert();
}

#[test]
fn test_item_list_json_select_and_hydration() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();

    let list_mock = server
        .mock("GET", "/api/v1/entities")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(fixture("entities_list.json"))
        .create();

    let detail_1 = server
        .mock("GET", "/api/v1/entities/ent-1")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(fixture("entity_detail.json"))
        .create();

    let detail_2 = server
        .mock("GET", "/api/v1/entities/ent-2")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(
            json!({
                "id": "ent-2",
                "name": "Fluke 87V",
                "quantity": 1,
                "fields": []
            })
            .to_string(),
        )
        .create();

    let out = hbx(&server.url())
        .args([
            "--json",
            "--select",
            "id,name,fields",
            "item",
            "list",
            "--has-field",
            "Voltage",
        ])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();

    list_mock.assert();
    detail_1.assert();
    detail_2.assert();

    let text = String::from_utf8(out).unwrap();
    // Compact single-line JSON
    assert_eq!(text.lines().count(), 1);
    let arr: Value = serde_json::from_str(&text).unwrap();
    assert_eq!(arr.as_array().unwrap().len(), 1);
    assert_eq!(arr[0]["id"], "ent-1");
    assert_eq!(arr[0]["name"], "ESP32 DevKitC");
    assert!(arr[0].get("fields").is_some());
    assert!(arr[0].get("description").is_none());
}

#[test]
fn test_item_upsert_existing_and_new() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();

    // Upsert existing item by case-insensitive name
    let _tags = server
        .mock("GET", "/api/v1/tags")
        .with_status(200)
        .with_body(fixture("tags.json"))
        .create();

    let list_mock = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_body(fixture("entities_list.json"))
        .create();

    let get_mock = server
        .mock("GET", "/api/v1/entities/ent-1")
        .with_status(200)
        .with_body(fixture("entity_detail.json"))
        .create();

    let put_mock = server
        .mock("PUT", "/api/v1/entities/ent-1")
        .match_body(Matcher::Regex("\"numberValue\":5\\.0".to_string()))
        .with_status(200)
        .with_body(fixture("entity_detail.json"))
        .create();

    hbx(&server.url())
        .args([
            "-q",
            "item",
            "upsert",
            "--name",
            "esp32 devkitc",
            "--field",
            "Voltage=5",
            "--field-type",
            "number",
        ])
        .assert()
        .success()
        .stdout(predicate::eq("ent-1\n"));

    list_mock.assert();
    get_mock.assert();
    put_mock.assert();
}

#[test]
fn test_item_import_skip_and_update_existing() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();
    let import_json_path =
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("tests/fixtures/import_items.json");

    let _tags = server
        .mock("GET", "/api/v1/tags")
        .with_status(200)
        .with_body(fixture("tags.json"))
        .create();

    let existing_list = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_body(
            json!({
                "items": [{
                    "id": "ent-exist",
                    "name": "Existing Widget",
                    "quantity": 1,
                    "fields": []
                }],
                "total": 1
            })
            .to_string(),
        )
        .expect_at_least(2)
        .create();

    // --skip-existing creates only "Brand New Sensor" (+ follow-up PUT for Model Number)
    let post_new = server
        .mock("POST", "/api/v1/entities")
        .match_body(Matcher::Regex("Brand New Sensor".to_string()))
        .with_status(201)
        .with_body(
            json!({"id": "ent-created-2", "name": "Brand New Sensor", "quantity": 2, "fields": []})
                .to_string(),
        )
        .expect(2)
        .create();

    let put_new = server
        .mock("PUT", "/api/v1/entities/ent-created-2")
        .with_status(200)
        .with_body(
            json!({"id": "ent-created-2", "name": "Brand New Sensor", "quantity": 2, "fields": []})
                .to_string(),
        )
        .expect(2)
        .create();

    let out = hbx(&server.url())
        .args([
            "--json",
            "item",
            "import",
            import_json_path.to_str().unwrap(),
            "--skip-existing",
        ])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();

    let summary: Value = serde_json::from_slice(&out).unwrap();
    assert_eq!(summary["created"], 1);
    assert_eq!(summary["skipped"], 1);
    assert_eq!(summary["updated"], 0);

    // --update-existing updates Existing Widget AND creates Brand New Sensor
    let get_exist = server
        .mock("GET", "/api/v1/entities/ent-exist")
        .with_status(200)
        .with_body(
            json!({"id": "ent-exist", "name": "Existing Widget", "quantity": 1, "fields": []})
                .to_string(),
        )
        .create();

    let put_exist = server
        .mock("PUT", "/api/v1/entities/ent-exist")
        .with_status(200)
        .with_body(
            json!({"id": "ent-exist", "name": "Existing Widget", "quantity": 4, "fields": []})
                .to_string(),
        )
        .create();

    let out2 = hbx(&server.url())
        .args([
            "--json",
            "item",
            "import",
            import_json_path.to_str().unwrap(),
            "--update-existing",
        ])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();

    let summary2: Value = serde_json::from_slice(&out2).unwrap();
    assert_eq!(summary2["created"], 1);
    assert_eq!(summary2["updated"], 1);
    assert_eq!(summary2["skipped"], 0);

    existing_list.assert();
    post_new.assert();
    put_new.assert();
    get_exist.assert();
    put_exist.assert();
}

#[test]
fn test_item_dedup_dry_run_and_merge() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();

    let list_mock = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_body(fixture("dedup_entities.json"))
        .expect(2)
        .create();

    // 1. Dry-run merge: ZERO PUT/DELETE requests, Authorization redacted
    let dry_out = hbx(&server.url())
        .args(["--json", "item", "dedup", "--merge", "--dry-run"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();

    let dry_text = String::from_utf8(dry_out).unwrap();
    assert!(dry_text.contains("Bearer ***"));
    assert!(!dry_text.contains("hb_test_secret_token_999"));
    let reqs: Value = serde_json::from_str(&dry_text).unwrap();
    assert_eq!(reqs.as_array().unwrap().len(), 2);
    assert_eq!(reqs[0]["method"], "PUT");
    assert_eq!(reqs[0]["body"]["quantity"], 5);
    assert_eq!(reqs[1]["method"], "DELETE");

    // 2. Real merge: updates keeper dup-1 quantity to 5 and deletes dup-2
    let get_keeper = server
        .mock("GET", "/api/v1/entities/dup-1")
        .with_status(200)
        .with_body(
            json!({"id": "dup-1", "name": "BME280 Sensor Module v1.0", "quantity": 2, "fields": []})
                .to_string(),
        )
        .create();

    let put_keeper = server
        .mock("PUT", "/api/v1/entities/dup-1")
        .match_body(Matcher::Regex("\"quantity\":5".to_string()))
        .with_status(200)
        .with_body(
            json!({"id": "dup-1", "name": "BME280 Sensor Module v1.0", "quantity": 5, "fields": []})
                .to_string(),
        )
        .create();

    let del_dup = server
        .mock("DELETE", "/api/v1/entities/dup-2")
        .with_status(204)
        .create();

    hbx(&server.url())
        .args(["-q", "item", "dedup", "--merge"])
        .assert()
        .success()
        .stdout(predicate::eq("dup-2\n"));

    list_mock.assert();
    get_keeper.assert();
    put_keeper.assert();
    del_dup.assert();
}

#[test]
fn test_attachment_upload_skip_existing_and_image_guard() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();
    let tmp = tempdir().unwrap();

    // Existing file (matches title "datasheet.pdf" on ent-1) and new file
    let existing_pdf = tmp.path().join("datasheet.pdf");
    fs::write(&existing_pdf, b"%PDF-1.4 existing").unwrap();
    let new_txt = tmp.path().join("notes.txt");
    fs::write(&new_txt, b"hello notes").unwrap();

    // Oversized PNG (>500KB)
    let big_png = tmp.path().join("huge.png");
    fs::write(&big_png, vec![0u8; 520 * 1024]).unwrap();

    // 1. Oversized image rejected without --force (no HTTP calls needed)
    hbx(&server.url())
        .args(["attachment", "upload", "ent-1", big_png.to_str().unwrap()])
        .assert()
        .failure()
        .stderr(predicate::str::contains("exceeds"))
        .stderr(predicate::str::contains("--force"));

    // 2. Multi-file upload: datasheet.pdf skipped, notes.txt uploaded
    let get_ent = server
        .mock("GET", "/api/v1/entities/ent-1")
        .with_status(200)
        .with_body(fixture("entity_detail.json"))
        .create();

    let upload_mock = server
        .mock("POST", "/api/v1/entities/ent-1/attachments")
        .with_status(201)
        .with_body(
            json!({"id": "att-new-9", "title": "notes.txt", "mimeType": "text/plain"}).to_string(),
        )
        .expect(1)
        .create();

    let out = hbx(&server.url())
        .args([
            "--json",
            "attachment",
            "upload",
            "ent-1",
            existing_pdf.to_str().unwrap(),
            new_txt.to_str().unwrap(),
            "--skip-existing",
        ])
        .assert()
        .success()
        .stderr(predicate::str::contains("skipping existing attachment"))
        .get_output()
        .stdout
        .clone();

    get_ent.assert();
    upload_mock.assert();

    let results: Value = serde_json::from_slice(&out).unwrap();
    assert_eq!(results[0]["status"], "skipped");
    assert_eq!(results[1]["status"], "uploaded");
    assert_eq!(results[1]["id"], "att-new-9");
}

#[test]
fn test_attachment_download_all_ext_pdf_streaming() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();
    let out_dir = tempdir().unwrap();

    let get_ent = server
        .mock("GET", "/api/v1/entities/ent-1")
        .with_status(200)
        .with_body(fixture("entity_detail.json"))
        .create();

    let dl_pdf = server
        .mock("GET", "/api/v1/entities/ent-1/attachments/att-pdf-1")
        .with_status(200)
        .with_header("content-type", "application/pdf")
        .with_body(b"%PDF-1.7 streamed bytes")
        .expect(1)
        .create();

    hbx(&server.url())
        .args([
            "--json",
            "attachment",
            "download",
            "ent-1",
            "--all",
            "--ext",
            "pdf",
            "--out",
            out_dir.path().to_str().unwrap(),
        ])
        .assert()
        .success();

    get_ent.assert();
    dl_pdf.assert();

    let saved = out_dir.path().join("datasheet.pdf");
    assert!(saved.is_file());
    assert_eq!(fs::read(&saved).unwrap(), b"%PDF-1.7 streamed bytes");
    assert!(!out_dir.path().join("pinout.png").exists());
}

#[test]
fn test_search_field_tag_entity_types_export_and_dry_run() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();

    // 1. Search with structured --manufacturer (triggers field hydration)
    let search_list = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_body(fixture("entities_list.json"))
        .expect_at_least(2)
        .create();

    let get_e1 = server
        .mock("GET", "/api/v1/entities/ent-1")
        .with_status(200)
        .with_body(fixture("entity_detail.json"))
        .expect_at_least(3)
        .create();

    let get_e2 = server
        .mock("GET", "/api/v1/entities/ent-2")
        .with_status(200)
        .with_body(
            json!({
                "id": "ent-2",
                "name": "Fluke 87V",
                "quantity": 1,
                "tags": [{"id": "tag-tools", "name": "tools"}],
                "fields": [
                    {"name": "Manufacturer", "type": "text", "value": "Fluke"}
                ]
            })
            .to_string(),
        )
        .expect_at_least(2)
        .create();

    hbx(&server.url())
        .args(["-q", "search", "--manufacturer", "Espressif"])
        .assert()
        .success()
        .stdout(predicate::eq("ent-1\n"));

    // 2. field get (prefers numberValue = 3.3 over stale value)
    hbx(&server.url())
        .args(["-q", "field", "get", "ent-1", "Voltage"])
        .assert()
        .success()
        .stdout(predicate::eq("3.3\n"));

    // 3. field set (typed boolean via GET -> Merge -> PUT)
    let put_field = server
        .mock("PUT", "/api/v1/entities/ent-1")
        .match_body(Matcher::Regex("\"booleanValue\":false".to_string()))
        .with_status(200)
        .with_body(fixture("entity_detail.json"))
        .create();

    hbx(&server.url())
        .args([
            "-q", "field", "set", "ent-1", "Tested", "false", "--type", "boolean",
        ])
        .assert()
        .success()
        .stdout(predicate::eq("ent-1\n"));
    put_field.assert();

    // 4. tag list & create
    let tags_list = server
        .mock("GET", "/api/v1/tags")
        .with_status(200)
        .with_body(fixture("tags.json"))
        .create();

    hbx(&server.url())
        .args(["--json", "tag", "list"])
        .assert()
        .success()
        .stdout(predicate::str::contains("electronics"));
    tags_list.assert();

    let tag_create = server
        .mock("POST", "/api/v1/tags")
        .with_status(201)
        .with_body(json!({"id": "tag-new", "name": "sensors"}).to_string())
        .create();

    hbx(&server.url())
        .args(["-q", "tag", "create", "sensors"])
        .assert()
        .success()
        .stdout(predicate::eq("tag-new\n"));
    tag_create.assert();

    // 5. entity-types highlights isLocation
    let et_mock = server
        .mock("GET", "/api/v1/entity-types")
        .with_status(200)
        .with_body(fixture("entity_types.json"))
        .create();

    hbx(&server.url())
        .args(["entity-types"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Storage Bin"))
        .stdout(predicate::str::contains("yes [location]"));
    et_mock.assert();

    // 6. export --format markdown --field Manufacturer --field Voltage
    let md = hbx(&server.url())
        .args([
            "export",
            "--format",
            "markdown",
            "--field",
            "Manufacturer",
            "--field",
            "Voltage",
            "--sort",
            "name",
        ])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();

    let md_str = String::from_utf8(md).unwrap();
    assert!(md_str.contains("| id | name | quantity | tags | Manufacturer | Voltage |"));
    assert!(md_str.contains("| ent-1 | ESP32 DevKitC | 3 | electronics | Espressif | 3.3 |"));
    assert!(md_str.contains("| ent-2 | Fluke 87V | 1 | tools | Fluke |  |"));

    // 7. --dry-run never hits server and redacts Authorization
    let dry = hbx("http://127.0.0.1:1")
        .args([
            "item",
            "create",
            "--name",
            "Offline Preview",
            "--field",
            "Voltage=3.3",
            "--dry-run",
        ])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();

    let dry_str = String::from_utf8(dry).unwrap();
    assert!(dry_str.contains("Authorization: Bearer ***"));
    assert!(!dry_str.contains("hb_test_secret_token_999"));
    assert!(dry_str.contains("POST http://127.0.0.1:1/api/v1/entities"));
    assert!(dry_str.contains("PUT http://127.0.0.1:1/api/v1/entities/<created-id>"));

    search_list.assert();
    get_e1.assert();
    get_e2.assert();
}

#[test]
fn test_csv_import_attachment_ops_and_csv_export() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();
    let csv_path =
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("tests/fixtures/import_items.csv");

    let tags_mock = server
        .mock("GET", "/api/v1/tags")
        .with_status(200)
        .with_body(fixture("tags.json"))
        .create();

    let post_csv = server
        .mock("POST", "/api/v1/entities")
        .match_body(Matcher::Regex("CSV Resistor Pack".to_string()))
        .with_status(201)
        .with_body(
            json!({"id": "ent-csv-1", "name": "CSV Resistor Pack", "quantity": 10, "fields": []})
                .to_string(),
        )
        .create();

    let put_csv = server
        .mock("PUT", "/api/v1/entities/ent-csv-1")
        .match_body(Matcher::AllOf(vec![
            Matcher::Regex("Manufacturer".to_string()),
            Matcher::Regex("Yageo".to_string()),
            Matcher::Regex("Voltage".to_string()),
        ]))
        .with_status(200)
        .with_body(
            json!({"id": "ent-csv-1", "name": "CSV Resistor Pack", "quantity": 10, "fields": []})
                .to_string(),
        )
        .create();

    hbx(&server.url())
        .args(["-q", "item", "import", csv_path.to_str().unwrap()])
        .assert()
        .success()
        .stdout(predicate::eq("ent-csv-1\n"));

    tags_mock.assert();
    post_csv.assert();
    put_csv.assert();

    // attachment list + delete + upload --force (>500KB image)
    let get_ent = server
        .mock("GET", "/api/v1/entities/ent-1")
        .with_status(200)
        .with_body(fixture("entity_detail.json"))
        .expect(2)
        .create();

    hbx(&server.url())
        .args(["--json", "attachment", "list", "ent-1"])
        .assert()
        .success()
        .stdout(predicate::str::contains("datasheet.pdf"))
        .stdout(predicate::str::contains("pinout.png"));

    let del_att = server
        .mock("DELETE", "/api/v1/entities/ent-1/attachments/att-img-1")
        .with_status(204)
        .create();

    hbx(&server.url())
        .args(["-q", "attachment", "delete", "ent-1", "att-img-1"])
        .assert()
        .success()
        .stdout(predicate::eq("att-img-1\n"));
    del_att.assert();

    let tmp = tempdir().unwrap();
    let big_png = tmp.path().join("huge.png");
    fs::write(&big_png, vec![0u8; 520 * 1024]).unwrap();
    let upload_force = server
        .mock("POST", "/api/v1/entities/ent-1/attachments")
        .with_status(201)
        .with_body(
            json!({"id": "att-big-1", "title": "huge.png", "mimeType": "image/png"}).to_string(),
        )
        .create();

    hbx(&server.url())
        .args([
            "-q",
            "attachment",
            "upload",
            "ent-1",
            big_png.to_str().unwrap(),
            "--force",
        ])
        .assert()
        .success()
        .stderr(predicate::str::contains(
            "warning: uploading oversized image",
        ))
        .stdout(predicate::eq("att-big-1\n"));

    get_ent.assert();
    upload_force.assert();

    // export --format csv
    let list_csv = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_body(
            json!({
                "items": [{
                    "id": "ent-1",
                    "name": "ESP32 DevKitC",
                    "quantity": 3,
                    "tags": [{"id": "tag-elec", "name": "electronics"}],
                    "fields": [{"name": "Voltage", "type": "number", "numberValue": 3.3}]
                }],
                "total": 1
            })
            .to_string(),
        )
        .create();

    hbx(&server.url())
        .args(["export", "--format", "csv", "--field", "Voltage"])
        .assert()
        .success()
        .stdout(predicate::str::contains("id,name,quantity,tags,Voltage"))
        .stdout(predicate::str::contains(
            "ent-1,ESP32 DevKitC,3,electronics,3.3",
        ));
    list_csv.assert();
}
