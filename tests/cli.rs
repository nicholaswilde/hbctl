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
    let bin = env!("CARGO_BIN_EXE_hbctl");
    matches!(
        StdCommand::new(bin).arg("--version").output(),
        Ok(o) if o.status.success()
    )
}

fn hbctl(server_url: &str) -> Command {
    let mut cmd = Command::new(env!("CARGO_BIN_EXE_hbctl"));
    for var in [
        "HBCTL_URL",
        "HBCTL_API_KEY",
        "HBCTL_OUTPUT",
        "HBCTL_CONFIG",
        "HBCTL_PROFILE",
        "HOMEBOX_URL",
        "HOMEBOX_IP",
        "HOMEBOX_API_KEY",
    ] {
        cmd.env_remove(var);
    }
    cmd.env(
        "XDG_CONFIG_HOME",
        std::env::temp_dir().join("hbctl-test-empty-xdg"),
    )
    .env("HBCTL_INSECURE_STORAGE", "1")
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

    let output = hbctl(&server.url())
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

    hbctl(&server.url())
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

    hbctl(&server.url())
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

    let out = hbctl(&server.url())
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
        .match_body(Matcher::Regex("\"numberValue\":5[,}]".to_string()))
        .with_status(200)
        .with_body(fixture("entity_detail.json"))
        .create();

    hbctl(&server.url())
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

    let out = hbctl(&server.url())
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

    let out2 = hbctl(&server.url())
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
    let dry_out = hbctl(&server.url())
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

    hbctl(&server.url())
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
    hbctl(&server.url())
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

    let out = hbctl(&server.url())
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

    hbctl(&server.url())
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

    hbctl(&server.url())
        .args(["-q", "search", "--manufacturer", "Espressif"])
        .assert()
        .success()
        .stdout(predicate::eq("ent-1\n"));

    // 2. field get (prefers numberValue = 3.3 over stale value)
    hbctl(&server.url())
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

    hbctl(&server.url())
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

    hbctl(&server.url())
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

    hbctl(&server.url())
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

    hbctl(&server.url())
        .args(["entity-types"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Storage Bin"))
        .stdout(predicate::str::contains("yes [location]"));
    et_mock.assert();

    // 6. export --format markdown --field Manufacturer --field Voltage
    let md = hbctl(&server.url())
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
    let dry = hbctl("http://127.0.0.1:1")
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

    hbctl(&server.url())
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

    hbctl(&server.url())
        .args(["--json", "attachment", "list", "ent-1"])
        .assert()
        .success()
        .stdout(predicate::str::contains("datasheet.pdf"))
        .stdout(predicate::str::contains("pinout.png"));

    let del_att = server
        .mock("DELETE", "/api/v1/entities/ent-1/attachments/att-img-1")
        .with_status(204)
        .create();

    hbctl(&server.url())
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

    hbctl(&server.url())
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

    hbctl(&server.url())
        .args(["export", "--format", "csv", "--field", "Voltage"])
        .assert()
        .success()
        .stdout(predicate::str::contains("id,name,quantity,tags,Voltage"))
        .stdout(predicate::str::contains(
            "ent-1,ESP32 DevKitC,3,electronics,3.3",
        ));
    list_csv.assert();
}

#[test]
fn test_item_get_list_pagination_from_json_upsert_new_and_dry_runs() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();
    let tmp = tempdir().unwrap();

    // 1. item get in table, plain, and projected table (--select)
    let get_detail = server
        .mock("GET", "/api/v1/entities/ent-1")
        .with_status(200)
        .with_body(fixture("entity_detail.json"))
        .expect(3)
        .create();

    hbctl(&server.url())
        .args(["item", "get", "ent-1"])
        .assert()
        .success()
        .stdout(predicate::str::contains("ESP32 DevKitC"))
        .stdout(predicate::str::contains("purchasePrice"))
        .stdout(predicate::str::contains("field:Voltage"));

    hbctl(&server.url())
        .args(["--output", "plain", "item", "get", "ent-1"])
        .assert()
        .success()
        .stdout(predicate::str::contains("id\tent-1"));

    hbctl(&server.url())
        .args(["--select", "id,name,Voltage", "item", "get", "ent-1"])
        .assert()
        .success()
        .stdout(predicate::str::contains("3.3"));
    get_detail.assert();

    // 2. item list with --tag, --type, and multi-page --all pagination
    let tags_mock = server
        .mock("GET", "/api/v1/tags")
        .with_status(200)
        .with_body(fixture("tags.json"))
        .expect_at_least(2)
        .create();

    let types_mock = server
        .mock("GET", "/api/v1/entity-types")
        .with_status(200)
        .with_body(fixture("entity_types.json"))
        .expect_at_least(2)
        .create();

    let page1 = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::AllOf(vec![
            Matcher::UrlEncoded("tags".into(), "tag-elec".into()),
            Matcher::UrlEncoded("entityTypeId".into(), "et-item".into()),
            Matcher::UrlEncoded("page".into(), "1".into()),
            Matcher::UrlEncoded("pageSize".into(), "1".into()),
        ]))
        .with_status(200)
        .with_body(
            json!({
                "items": [{"id": "ent-1", "name": "ESP32", "quantity": 1, "tags": [{"id": "tag-elec", "name": "electronics"}]}],
                "page": 1, "pageSize": 1, "total": 2
            })
            .to_string(),
        )
        .create();

    let page2 = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::AllOf(vec![
            Matcher::UrlEncoded("tags".into(), "tag-elec".into()),
            Matcher::UrlEncoded("entityTypeId".into(), "et-item".into()),
            Matcher::UrlEncoded("page".into(), "2".into()),
            Matcher::UrlEncoded("pageSize".into(), "1".into()),
        ]))
        .with_status(200)
        .with_body(
            json!({
                "items": [{"id": "ent-2", "name": "Sensor", "quantity": 2, "tags": []}],
                "page": 2, "pageSize": 1, "total": 2
            })
            .to_string(),
        )
        .create();

    hbctl(&server.url())
        .args([
            "item",
            "list",
            "--tag",
            "electronics",
            "--type",
            "Item",
            "--page-size",
            "1",
            "--all",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("ESP32"))
        .stdout(predicate::str::contains("Sensor"));
    page1.assert();
    page2.assert();

    // 3. item create --from-json with aliases & entityType object
    let create_json = tmp.path().join("create.json");
    fs::write(
        &create_json,
        json!({
            "name": "Json Board",
            "description": "From JSON",
            "quantity": 4,
            "entityType": {"id": "et-item", "name": "Item"},
            "tags": [{"name": "electronics"}],
            "manufacturer": "SparkFun",
            "model_number": "DEV-123",
            "notes": "Shelf 1",
            "purchasePrice": 19.99,
            "purchaseDate": "2026-03-01",
            "purchaseFrom": "SparkFun"
        })
        .to_string(),
    )
    .unwrap();

    let post_json = server
        .mock("POST", "/api/v1/entities")
        .with_status(201)
        .with_body(
            json!({"id": "ent-j1", "name": "Json Board", "quantity": 4, "fields": []}).to_string(),
        )
        .create();
    let put_json = server
        .mock("PUT", "/api/v1/entities/ent-j1")
        .with_status(200)
        .with_body(
            json!({"id": "ent-j1", "name": "Json Board", "quantity": 4, "fields": []}).to_string(),
        )
        .create();

    hbctl(&server.url())
        .args([
            "item",
            "create",
            "--from-json",
            create_json.to_str().unwrap(),
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("Json Board"));
    post_json.assert();
    put_json.assert();

    // 4. item upsert create path with auto-created tag + boolean field
    let create_tag = server
        .mock("POST", "/api/v1/tags")
        .match_body(Matcher::Regex("AutoNewTag".into()))
        .with_status(201)
        .with_body(json!({"id": "tag-auto", "name": "AutoNewTag"}).to_string())
        .create();
    let empty_search = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::AllOf(vec![
            Matcher::UrlEncoded("q".into(), "Fresh Module".into()),
            Matcher::UrlEncoded("page".into(), "1".into()),
            Matcher::UrlEncoded("pageSize".into(), "50".into()),
        ]))
        .with_status(200)
        .with_body(json!({"items": [], "total": 0}).to_string())
        .create();
    let post_upsert = server
        .mock("POST", "/api/v1/entities")
        .with_status(201)
        .with_body(
            json!({"id": "ent-up-1", "name": "Fresh Module", "quantity": 1, "fields": []})
                .to_string(),
        )
        .create();
    let put_upsert = server
        .mock("PUT", "/api/v1/entities/ent-up-1")
        .match_body(Matcher::Regex("\"booleanValue\":true".into()))
        .with_status(200)
        .with_body(
            json!({"id": "ent-up-1", "name": "Fresh Module", "quantity": 1, "fields": []})
                .to_string(),
        )
        .create();

    hbctl(&server.url())
        .args([
            "-q",
            "item",
            "upsert",
            "--name",
            "Fresh Module",
            "--tag",
            "AutoNewTag",
            "--field",
            "Active=true",
            "--field-type",
            "boolean",
        ])
        .assert()
        .success()
        .stdout(predicate::eq("ent-up-1\n"));
    create_tag.assert();
    empty_search.assert();
    post_upsert.assert();
    put_upsert.assert();
    tags_mock.assert();
    types_mock.assert();

    // 5. dry-run previews for update, upsert, delete, import
    hbctl("http://127.0.0.1:1")
        .args(["item", "update", "ent-1", "--name", "Renamed", "--dry-run"])
        .assert()
        .success()
        .stdout(predicate::str::contains(
            "PUT http://127.0.0.1:1/api/v1/entities/ent-1",
        ))
        .stdout(predicate::str::contains("Bearer ***"));

    hbctl("http://127.0.0.1:1")
        .args(["item", "upsert", "--name", "Preview", "--dry-run"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Bearer ***"));

    hbctl("http://127.0.0.1:1")
        .args(["item", "delete", "ent-1", "--dry-run"])
        .assert()
        .success()
        .stdout(predicate::str::contains(
            "DELETE http://127.0.0.1:1/api/v1/entities/ent-1",
        ));

    let import_json_path =
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("tests/fixtures/import_items.json");
    hbctl("http://127.0.0.1:1")
        .args([
            "item",
            "import",
            import_json_path.to_str().unwrap(),
            "--dry-run",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains(
            "POST http://127.0.0.1:1/api/v1/entities",
        ));
}

#[test]
fn test_dedup_report_and_attachment_overwrite_single_download() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();
    let tmp = tempdir().unwrap();

    // 1. dedup report-only (table) + empty result
    let dedup_list = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_body(fixture("dedup_entities.json"))
        .create();

    hbctl(&server.url())
        .args(["item", "dedup"])
        .assert()
        .success()
        .stdout(predicate::str::contains("near"))
        .stdout(predicate::str::contains("BME280 Sensor Module v1.0"));
    dedup_list.assert();

    let empty_list = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_body(
            json!({"items": [{"id": "u1", "name": "Solo Item", "quantity": 1}], "total": 1})
                .to_string(),
        )
        .create();

    hbctl(&server.url())
        .args(["item", "dedup"])
        .assert()
        .success()
        .stdout(predicate::str::contains("No duplicate items found."));
    empty_list.assert();

    // 2. attachment upload --overwrite + table output + dry-run
    let pdf = tmp.path().join("datasheet.pdf");
    fs::write(&pdf, b"%PDF-1.7 updated").unwrap();

    let get_ent = server
        .mock("GET", "/api/v1/entities/ent-1")
        .with_status(200)
        .with_body(fixture("entity_detail.json"))
        .expect(5)
        .create();

    let del_old = server
        .mock("DELETE", "/api/v1/entities/ent-1/attachments/att-pdf-1")
        .with_status(204)
        .create();
    let post_new = server
        .mock("POST", "/api/v1/entities/ent-1/attachments")
        .with_status(201)
        .with_body(
            json!({"id": "att-pdf-2", "title": "datasheet.pdf", "mimeType": "application/pdf"})
                .to_string(),
        )
        .create();

    hbctl(&server.url())
        .args([
            "attachment",
            "upload",
            "ent-1",
            pdf.to_str().unwrap(),
            "--overwrite",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("uploaded"))
        .stdout(predicate::str::contains("att-pdf-2"));
    del_old.assert();
    post_new.assert();

    // attachment list (table)
    hbctl(&server.url())
        .args(["attachment", "list", "ent-1"])
        .assert()
        .success()
        .stdout(predicate::str::contains("datasheet.pdf"));

    // single attachment download -> skip existing -> overwrite
    let out_file = tmp.path().join("saved_manual.pdf");
    let dl_single = server
        .mock("GET", "/api/v1/entities/ent-1/attachments/att-pdf-1")
        .with_status(200)
        .with_body(b"pdf-body-bytes")
        .expect(2)
        .create();

    hbctl(&server.url())
        .args([
            "attachment",
            "download",
            "ent-1",
            "att-pdf-1",
            "--out",
            out_file.to_str().unwrap(),
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("downloaded"));

    // Second run without --overwrite skips existing file
    hbctl(&server.url())
        .args([
            "attachment",
            "download",
            "ent-1",
            "att-pdf-1",
            "--out",
            out_file.to_str().unwrap(),
        ])
        .assert()
        .success()
        .stderr(predicate::str::contains("skipping existing file"))
        .stdout(predicate::str::contains("skipped"));

    // Third run with --overwrite downloads again
    hbctl(&server.url())
        .args([
            "-q",
            "attachment",
            "download",
            "ent-1",
            "att-pdf-1",
            "--out",
            out_file.to_str().unwrap(),
            "--overwrite",
        ])
        .assert()
        .success()
        .stdout(predicate::eq("att-pdf-1\n"));

    dl_single.assert();
    get_ent.assert();

    // attachment dry-runs
    hbctl("http://127.0.0.1:1")
        .args([
            "attachment",
            "upload",
            "ent-1",
            pdf.to_str().unwrap(),
            "--dry-run",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains(
            "POST http://127.0.0.1:1/api/v1/entities/ent-1/attachments",
        ));

    hbctl("http://127.0.0.1:1")
        .args(["attachment", "delete", "ent-1", "att-1", "--dry-run"])
        .assert()
        .success()
        .stdout(predicate::str::contains(
            "DELETE http://127.0.0.1:1/api/v1/entities/ent-1/attachments/att-1",
        ));
}

#[test]
fn test_field_tag_entity_types_export_config_completions_and_error_redaction() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();
    let tmp = tempdir().unwrap();

    // 1. field get (table + json + missing field error) & field set (table + json + dry-run)
    let get_ent = server
        .mock("GET", "/api/v1/entities/ent-1")
        .with_status(200)
        .with_body(fixture("entity_detail.json"))
        .expect(5)
        .create();
    let put_ent = server
        .mock("PUT", "/api/v1/entities/ent-1")
        .with_status(200)
        .with_body(fixture("entity_detail.json"))
        .expect(2)
        .create();

    hbctl(&server.url())
        .args(["field", "get", "ent-1", "Voltage"])
        .assert()
        .success()
        .stdout(predicate::str::contains("3.3"));

    hbctl(&server.url())
        .args(["--json", "field", "get", "ent-1", "Voltage"])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"numberValue\":3.3"));

    hbctl(&server.url())
        .args(["field", "get", "ent-1", "NoSuchField"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("field not found"));

    hbctl(&server.url())
        .args([
            "field", "set", "ent-1", "Voltage", "3.3", "--type", "number",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("Voltage"));

    hbctl(&server.url())
        .args([
            "--json", "field", "set", "ent-1", "Voltage", "3.3", "--type", "number",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"name\":\"Voltage\""));

    hbctl("http://127.0.0.1:1")
        .args([
            "field",
            "set",
            "ent-1",
            "Voltage",
            "5",
            "--type",
            "number",
            "--dry-run",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("Bearer ***"));

    get_ent.assert();
    put_ent.assert();

    // 2. tag list (table + quiet + select) & tag create (table + dry-run)
    let tags_mock = server
        .mock("GET", "/api/v1/tags")
        .with_status(200)
        .with_body(fixture("tags.json"))
        .expect(5)
        .create();

    hbctl(&server.url())
        .args(["tag", "list"])
        .assert()
        .success()
        .stdout(predicate::str::contains("electronics"));

    hbctl(&server.url())
        .args(["-q", "tag", "list"])
        .assert()
        .success()
        .stdout(predicate::str::contains("tag-elec"));

    hbctl(&server.url())
        .args(["--select", "id,name", "tag", "list"])
        .assert()
        .success()
        .stdout(predicate::str::contains("tools"));

    let tag_create = server
        .mock("POST", "/api/v1/tags")
        .with_status(201)
        .with_body(json!({"id": "tag-c", "name": "cables"}).to_string())
        .create();

    hbctl(&server.url())
        .args(["tag", "create", "cables"])
        .assert()
        .success()
        .stdout(predicate::str::contains("cables"));
    tag_create.assert();

    hbctl("http://127.0.0.1:1")
        .args(["tag", "create", "cables", "--dry-run"])
        .assert()
        .success()
        .stdout(predicate::str::contains(
            "POST http://127.0.0.1:1/api/v1/tags",
        ));

    // 3. entity-types (--json + -q)
    let et_mock = server
        .mock("GET", "/api/v1/entity-types")
        .with_status(200)
        .with_body(fixture("entity_types.json"))
        .expect(2)
        .create();
    hbctl(&server.url())
        .args(["--json", "entity-types"])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"isLocation\":true"));
    hbctl(&server.url())
        .args(["-q", "entity-types"])
        .assert()
        .success()
        .stdout(predicate::str::contains("et-loc"));
    et_mock.assert();

    // 4. export --format json (with & without --field, --has-field, --sort id)
    let exp_list = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_body(
            json!({
                "items": [{
                    "id": "ent-1",
                    "name": "ESP32",
                    "quantity": 3,
                    "tags": [{"id": "tag-elec", "name": "electronics"}],
                    "fields": [{"name": "Voltage", "type": "number", "numberValue": 3.3}]
                }],
                "total": 1
            })
            .to_string(),
        )
        .expect(2)
        .create();

    hbctl(&server.url())
        .args([
            "export",
            "--tag",
            "electronics",
            "--has-field",
            "Voltage",
            "--field",
            "Voltage",
            "--sort",
            "id",
            "--format",
            "json",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"Voltage\":\"3.3\""));

    hbctl(&server.url())
        .args(["export", "--format", "json"])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"id\":\"ent-1\""));
    exp_list.assert();

    // 5. Explicit --config file loading & HTTP error secret redaction
    let cfg_file = tmp.path().join("custom.toml");
    fs::write(
        &cfg_file,
        format!(
            "url = \"{}\"\napi_key = \"hb_super_secret_leaked_check\"\noutput = \"json\"\n",
            server.url()
        ),
    )
    .unwrap();

    let mut cfg_cmd = Command::new(env!("CARGO_BIN_EXE_hbctl"));
    for var in [
        "HBCTL_URL",
        "HBCTL_API_KEY",
        "HBCTL_OUTPUT",
        "HBCTL_CONFIG",
        "HBCTL_PROFILE",
        "HOMEBOX_URL",
        "HOMEBOX_IP",
        "HOMEBOX_API_KEY",
    ] {
        cfg_cmd.env_remove(var);
    }
    cfg_cmd
        .args(["--config", cfg_file.to_str().unwrap(), "tag", "list"])
        .assert()
        .success()
        .stdout(predicate::str::contains("electronics"));
    tags_mock.assert();

    let err_mock = server
        .mock("GET", "/api/v1/entities/bad-id")
        .with_status(401)
        .with_body("unauthorized for Bearer hb_test_secret_token_999")
        .create();
    hbctl(&server.url())
        .args(["item", "get", "bad-id"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("Bearer ***"))
        .stderr(predicate::str::contains("hb_test_secret_token_999").not());
    err_mock.assert();

    // 6. completions & man subcommands
    Command::new(env!("CARGO_BIN_EXE_hbctl"))
        .args(["completions", "bash"])
        .assert()
        .success()
        .stdout(predicate::str::contains("_hbctl"));

    Command::new(env!("CARGO_BIN_EXE_hbctl"))
        .args(["man"])
        .assert()
        .success()
        .stdout(predicate::str::contains(".TH hbctl"));
}

#[test]
fn test_auth_login_status_refresh_logout_precedence_and_redaction() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();
    let xdg_dir = tempdir().unwrap();

    let base_cmd = || {
        let mut cmd = Command::new(env!("CARGO_BIN_EXE_hbctl"));
        for var in [
            "HBCTL_URL",
            "HBCTL_API_KEY",
            "HBCTL_OUTPUT",
            "HBCTL_CONFIG",
            "HOMEBOX_URL",
            "HOMEBOX_IP",
            "HOMEBOX_API_KEY",
        ] {
            cmd.env_remove(var);
        }
        cmd.env("XDG_CONFIG_HOME", xdg_dir.path())
            .env("HBCTL_INSECURE_STORAGE", "1");
        cmd
    };

    // 1. Dry-run previews redact secrets & password without hitting server
    base_cmd()
        .args([
            "--url",
            "http://127.0.0.1:1",
            "auth",
            "login",
            "--with-token",
            "--dry-run",
        ])
        .write_stdin("hb_secret_never_print\n")
        .assert()
        .success()
        .stdout(predicate::str::contains("Authorization: Bearer ***"))
        .stdout(predicate::str::contains("hb_secret_never_print").not());

    base_cmd()
        .args([
            "--url",
            "http://127.0.0.1:1",
            "--json",
            "auth",
            "login",
            "--username",
            "nick@example.com",
            "--password-stdin",
            "--dry-run",
        ])
        .write_stdin("MySuperSecretPass123!\n")
        .assert()
        .success()
        .stdout(predicate::str::contains("\"password\":\"***\""))
        .stdout(predicate::str::contains("MySuperSecretPass123!").not());

    // 2. auth login --with-token persists metadata in config.toml (no plaintext api_key)
    //    and secret in 0600 credentials.json
    let self_apikey = server
        .mock("GET", "/api/v1/users/self")
        .match_header("authorization", "Bearer hb_live_api_key_42")
        .with_status(200)
        .with_body(
            json!({
                "item": {
                    "id": "usr-1",
                    "name": "Nicholas",
                    "email": "nick@example.com"
                }
            })
            .to_string(),
        )
        .expect(2)
        .create();

    let login_out = base_cmd()
        .args([
            "--url",
            &server.url(),
            "--json",
            "auth",
            "login",
            "--with-token",
            "--insecure-storage",
        ])
        .write_stdin("hb_live_api_key_42\n")
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();

    let login_str = String::from_utf8(login_out).unwrap();
    assert!(!login_str.contains("hb_live_api_key_42"));
    let login_json: Value = serde_json::from_str(&login_str).unwrap();
    assert_eq!(login_json["authenticated"], true);
    assert_eq!(login_json["token_type"], "api_key");
    assert_eq!(login_json["source"], "file");
    assert_eq!(login_json["authorization"], "Bearer ***");
    assert_eq!(login_json["email"], "nick@example.com");

    // Ensure config.toml does NOT contain plaintext secret
    let cfg_contents = fs::read_to_string(xdg_dir.path().join("hbctl/config.toml")).unwrap();
    assert!(!cfg_contents.contains("hb_live_api_key_42"));
    assert!(cfg_contents.contains("token_type = \"api_key\""));

    // 3. auth status works WITHOUT --url or --api-key (loads stored metadata + secret)
    let status_out = base_cmd()
        .args(["--json", "auth", "status"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let status_json: Value = serde_json::from_slice(&status_out).unwrap();
    assert_eq!(status_json["authenticated"], true);
    assert_eq!(status_json["source"], "credentials_file");
    assert_eq!(status_json["token_type"], "api_key");
    assert_eq!(status_json["authorization"], "Bearer ***");
    self_apikey.assert();

    // Subsequent API command uses stored credentials automatically
    let tags_mock = server
        .mock("GET", "/api/v1/tags")
        .match_header("authorization", "Bearer hb_live_api_key_42")
        .with_status(200)
        .with_body(fixture("tags.json"))
        .create();
    base_cmd()
        .args(["-q", "tag", "list"])
        .assert()
        .success()
        .stdout(predicate::str::contains("tag-elec"));
    tags_mock.assert();

    // 4. Precedence: HOMEBOX_API_KEY env overrides stored credentials
    let self_env = server
        .mock("GET", "/api/v1/users/self")
        .match_header("authorization", "Bearer hb_env_override_key")
        .with_status(200)
        .with_body(
            json!({"id": "usr-1", "name": "EnvUser", "email": "env@example.com"}).to_string(),
        )
        .create();

    let env_status = base_cmd()
        .env("HOMEBOX_API_KEY", "hb_env_override_key")
        .args(["--json", "auth", "status"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let env_json: Value = serde_json::from_slice(&env_status).unwrap();
    assert_eq!(env_json["source"], "env");
    assert_eq!(env_json["user"], "EnvUser");
    self_env.assert();

    // 5. Email + password login (POST /api/v1/users/login) + JWT refresh (GET /api/v1/users/refresh)
    let pwd_login = server
        .mock("POST", "/api/v1/users/login")
        .match_body(Matcher::AllOf(vec![
            Matcher::Regex("\"username\":\"nick@example.com\"".into()),
            Matcher::Regex("\"stayLoggedIn\":true".into()),
        ]))
        .with_status(200)
        .with_body(
            json!({
                "token": "Bearer eyJ_initial_jwt",
                "expiresAt": "2026-12-01T00:00:00Z"
            })
            .to_string(),
        )
        .create();
    let self_jwt = server
        .mock("GET", "/api/v1/users/self")
        .match_header("authorization", "Bearer eyJ_initial_jwt")
        .with_status(200)
        .with_body(
            json!({"id": "usr-1", "name": "Nicholas", "email": "nick@example.com"}).to_string(),
        )
        .create();

    let jwt_out = base_cmd()
        .args([
            "--url",
            &server.url(),
            "--json",
            "auth",
            "login",
            "--username",
            "nick@example.com",
            "--password-stdin",
            "--insecure-storage",
        ])
        .write_stdin("CorrectHorseBatteryStaple\n")
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let jwt_str = String::from_utf8(jwt_out).unwrap();
    assert!(!jwt_str.contains("eyJ_initial_jwt"));
    assert!(!jwt_str.contains("CorrectHorseBatteryStaple"));
    let jwt_json: Value = serde_json::from_str(&jwt_str).unwrap();
    assert_eq!(jwt_json["token_type"], "jwt");
    assert_eq!(jwt_json["expires_at"], "2026-12-01T00:00:00Z");
    pwd_login.assert();
    self_jwt.assert();

    // Refresh dry-run
    base_cmd()
        .args(["auth", "refresh", "--dry-run"])
        .assert()
        .success()
        .stdout(predicate::str::contains("GET"))
        .stdout(predicate::str::contains("/api/v1/users/refresh"))
        .stdout(predicate::str::contains("Bearer ***"));

    // Refresh live (GET returns 405 -> falls back to POST)
    let refresh_405 = server
        .mock("GET", "/api/v1/users/refresh")
        .match_header("authorization", "Bearer eyJ_initial_jwt")
        .with_status(405)
        .create();
    let refresh_post = server
        .mock("POST", "/api/v1/users/refresh")
        .match_header("authorization", "Bearer eyJ_initial_jwt")
        .with_status(200)
        .with_body(
            json!({
                "token": "Bearer eyJ_refreshed_jwt",
                "expiresAt": "2027-01-01T00:00:00Z"
            })
            .to_string(),
        )
        .create();

    let ref_out = base_cmd()
        .args(["--json", "auth", "refresh", "--insecure-storage"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let ref_str = String::from_utf8(ref_out).unwrap();
    assert!(!ref_str.contains("eyJ_refreshed_jwt"));
    let ref_json: Value = serde_json::from_str(&ref_str).unwrap();
    assert_eq!(ref_json["expires_at"], "2027-01-01T00:00:00Z");
    refresh_405.assert();
    refresh_post.assert();

    // 6. auth logout (--dry-run then real) clears credentials; subsequent status fails
    base_cmd()
        .args(["auth", "logout", "--dry-run"])
        .assert()
        .success()
        .stdout(predicate::str::contains("[dry-run] logout"));

    let logout_out = base_cmd()
        .args(["--json", "auth", "logout", "--insecure-storage"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let logout_json: Value = serde_json::from_slice(&logout_out).unwrap();
    assert_eq!(logout_json["logged_out"], true);
    assert_eq!(logout_json["removed_secret"], true);

    base_cmd()
        .args(["auth", "status"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("API key is not configured"));
}

#[test]
fn test_update_and_self_update_non_interactive_requires_yes() {
    if !can_execute_binary() {
        return;
    }

    // Works without Homebox URL/API key configured and rejects non-TTY without --yes
    Command::new(env!("CARGO_BIN_EXE_hbctl"))
        .args(["update"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("non-interactive mode"))
        .stderr(predicate::str::contains("--yes"));

    // Alias `self-update` behaves identically
    Command::new(env!("CARGO_BIN_EXE_hbctl"))
        .args(["self-update"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("--yes"));

    // Help text advertises flags
    Command::new(env!("CARGO_BIN_EXE_hbctl"))
        .args(["update", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("--check"))
        .stdout(predicate::str::contains("--yes"))
        .stdout(predicate::str::contains("--version"));
}

#[test]
fn test_crud_gaps_field_tag_and_item_flags() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();

    // 1. field list (table, --json, -q, --select)
    let get_ent_list = server
        .mock("GET", "/api/v1/entities/ent-1")
        .with_status(200)
        .with_body(fixture("entity_detail.json"))
        .expect(4)
        .create();

    hbctl(&server.url())
        .args(["field", "list", "ent-1"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Manufacturer"))
        .stdout(predicate::str::contains("Voltage"))
        .stdout(predicate::str::contains("3.3"));

    hbctl(&server.url())
        .args(["--json", "field", "list", "ent-1"])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"name\":\"Voltage\""));

    hbctl(&server.url())
        .args(["-q", "field", "list", "ent-1"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Manufacturer\n"))
        .stdout(predicate::str::contains("Voltage\n"));

    hbctl(&server.url())
        .args(["field", "list", "ent-1", "--select", "name,type"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Manufacturer"))
        .stdout(predicate::str::contains("number"));
    get_ent_list.assert();

    // 2. field delete (case-insensitive, dry-run, json, quiet, and NotFound)
    hbctl("http://127.0.0.1:1")
        .args(["field", "delete", "ent-1", "Voltage", "--dry-run"])
        .assert()
        .success()
        .stdout(predicate::str::contains(
            "PUT http://127.0.0.1:1/api/v1/entities/ent-1",
        ))
        .stdout(predicate::str::contains("removeFields"));

    let get_ent_del = server
        .mock("GET", "/api/v1/entities/ent-1")
        .with_status(200)
        .with_body(fixture("entity_detail.json"))
        .expect(3)
        .create();

    let put_field_del = server
        .mock("PUT", "/api/v1/entities/ent-1")
        .match_body(Matcher::AllOf(vec![
            Matcher::Regex("Manufacturer".to_string()),
            Matcher::Regex("tag-elec".to_string()),
            Matcher::Regex(r#""id":"fld-3"[^}]*\},\{"id":"fld-5""#.to_string()),
        ]))
        .with_status(200)
        .with_body(fixture("entity_detail.json"))
        .expect(2)
        .create();

    hbctl(&server.url())
        .args(["--json", "field", "delete", "ent-1", "voltage"])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"field\":\"voltage\""))
        .stdout(predicate::str::contains("\"deleted\":true"));

    hbctl(&server.url())
        .args(["-q", "field", "delete", "ent-1", "voltage"])
        .assert()
        .success()
        .stdout(predicate::eq("ent-1\n"));

    hbctl(&server.url())
        .args(["field", "delete", "ent-1", "NoSuchField"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("field not found"));

    get_ent_del.assert();
    put_field_del.assert();

    // 3. tag update (validation, dry-run, GET->PUT preserving description, json, quiet)
    hbctl(&server.url())
        .args(["tag", "update", "tag-elec"])
        .assert()
        .failure()
        .stderr(predicate::str::contains(
            "provide at least one of --name, --description, or --color",
        ));

    hbctl("http://127.0.0.1:1")
        .args([
            "tag",
            "update",
            "tag-elec",
            "--name",
            "Electronics v2",
            "--dry-run",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains(
            "PUT http://127.0.0.1:1/api/v1/tags/tag-elec",
        ))
        .stdout(predicate::str::contains("Electronics v2"));

    let get_tag = server
        .mock("GET", "/api/v1/tags/tag-elec")
        .with_status(200)
        .with_body(r#"{"id":"tag-elec","name":"electronics","description":"Electronic parts"}"#)
        .expect(2)
        .create();
    let put_tag = server
        .mock("PUT", "/api/v1/tags/tag-elec")
        .match_body(Matcher::AllOf(vec![
            Matcher::Regex("Electronics v2".to_string()),
            Matcher::Regex("Electronic parts".to_string()),
            Matcher::Regex("#00ff00".to_string()),
        ]))
        .with_status(200)
        .with_body(
            r##"{"id":"tag-elec","name":"Electronics v2","description":"Electronic parts","color":"#00ff00"}"##,
        )
        .expect(2)
        .create();

    hbctl(&server.url())
        .args([
            "--json",
            "tag",
            "update",
            "tag-elec",
            "--name",
            "Electronics v2",
            "--color",
            "#00ff00",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"name\":\"Electronics v2\""))
        .stdout(predicate::str::contains("\"color\":\"#00ff00\""));

    hbctl(&server.url())
        .args([
            "-q",
            "tag",
            "update",
            "tag-elec",
            "--name",
            "Electronics v2",
            "--color",
            "#00ff00",
        ])
        .assert()
        .success()
        .stdout(predicate::eq("tag-elec\n"));
    get_tag.assert();
    put_tag.assert();

    // 4. tag delete (dry-run, json, quiet)
    hbctl("http://127.0.0.1:1")
        .args(["tag", "delete", "tag-elec", "--dry-run"])
        .assert()
        .success()
        .stdout(predicate::str::contains(
            "DELETE http://127.0.0.1:1/api/v1/tags/tag-elec",
        ));

    let del_tag = server
        .mock("DELETE", "/api/v1/tags/tag-elec")
        .with_status(204)
        .expect(2)
        .create();

    hbctl(&server.url())
        .args(["--json", "tag", "delete", "tag-elec", "--force"])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"id\":\"tag-elec\""))
        .stdout(predicate::str::contains("\"deleted\":true"));

    hbctl(&server.url())
        .args(["-q", "tag", "delete", "tag-elec"])
        .assert()
        .success()
        .stdout(predicate::eq("tag-elec\n"));
    del_tag.assert();

    // 5. item create --serial
    let post_serial = server
        .mock("POST", "/api/v1/entities")
        .with_status(201)
        .with_body(r#"{"id":"ent-sn-1","name":"Bench PSU","quantity":1,"fields":[]}"#)
        .expect(1)
        .create();
    let put_serial = server
        .mock("PUT", "/api/v1/entities/ent-sn-1")
        .match_body(Matcher::AllOf(vec![
            Matcher::Regex("Serial Number".to_string()),
            Matcher::Regex("SN-001".to_string()),
        ]))
        .with_status(200)
        .with_body(r#"{"id":"ent-sn-1","name":"Bench PSU","quantity":1,"fields":[{"name":"Serial Number","type":"text","value":"SN-001","textValue":"SN-001"}]}"#)
        .expect(1)
        .create();

    hbctl(&server.url())
        .args([
            "-q",
            "item",
            "create",
            "--name",
            "Bench PSU",
            "--serial",
            "SN-001",
        ])
        .assert()
        .success()
        .stdout(predicate::eq("ent-sn-1\n"));
    post_serial.assert();
    put_serial.assert();

    // 6. item update --add-tag / --remove-tag / --serial (plus dry-run & unknown remove-tag)
    hbctl("http://127.0.0.1:1")
        .args([
            "item",
            "update",
            "ent-1",
            "--add-tag",
            "tools",
            "--remove-tag",
            "electronics",
            "--serial",
            "SN-002",
            "--dry-run",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("addTagIds"))
        .stdout(predicate::str::contains("removeTagIds"))
        .stdout(predicate::str::contains("SN-002"));

    let tags_for_update = server
        .mock("GET", "/api/v1/tags")
        .with_status(200)
        .with_body(fixture("tags.json"))
        .expect(2)
        .create();
    let get_for_update = server
        .mock("GET", "/api/v1/entities/ent-1")
        .with_status(200)
        .with_body(fixture("entity_detail.json"))
        .expect(1)
        .create();
    let put_for_update = server
        .mock("PUT", "/api/v1/entities/ent-1")
        .match_body(Matcher::AllOf(vec![
            Matcher::Regex(r#""tagIds":\["tag-tools"\]"#.to_string()),
            Matcher::Regex(r#""tags":\[\]"#.to_string()),
            Matcher::Regex("SN-002".to_string()),
        ]))
        .with_status(200)
        .with_body(fixture("entity_detail.json"))
        .expect(1)
        .create();

    hbctl(&server.url())
        .args([
            "-q",
            "item",
            "update",
            "ent-1",
            "--add-tag",
            "tools",
            "--remove-tag",
            "electronics",
            "--serial",
            "SN-002",
        ])
        .assert()
        .success()
        .stdout(predicate::eq("ent-1\n"));

    hbctl(&server.url())
        .args(["item", "update", "ent-1", "--remove-tag", "nonexistent-tag"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("tag not found"));

    tags_for_update.assert();
    get_for_update.assert();
    put_for_update.assert();

    // 7. item upsert --serial
    let search_upsert = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::UrlEncoded("q".into(), "Signal Gen".into()))
        .with_status(200)
        .with_body("[]")
        .expect(1)
        .create();
    let post_upsert = server
        .mock("POST", "/api/v1/entities")
        .with_status(201)
        .with_body(r#"{"id":"ent-sn-3","name":"Signal Gen","quantity":1,"fields":[]}"#)
        .expect(1)
        .create();
    let put_upsert = server
        .mock("PUT", "/api/v1/entities/ent-sn-3")
        .match_body(Matcher::AllOf(vec![
            Matcher::Regex("Serial Number".to_string()),
            Matcher::Regex("SN-003".to_string()),
        ]))
        .with_status(200)
        .with_body(r#"{"id":"ent-sn-3","name":"Signal Gen","quantity":1,"fields":[{"name":"Serial Number","type":"text","value":"SN-003","textValue":"SN-003"}]}"#)
        .expect(1)
        .create();

    hbctl(&server.url())
        .args([
            "-q",
            "item",
            "upsert",
            "--name",
            "Signal Gen",
            "--serial",
            "SN-003",
        ])
        .assert()
        .success()
        .stdout(predicate::eq("ent-sn-3\n"));
    search_upsert.assert();
    post_upsert.assert();
    put_upsert.assert();
}

#[test]
fn test_item_fill_missing_update_upsert_and_import() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();

    let tags_mock = server
        .mock("GET", "/api/v1/tags")
        .with_status(200)
        .with_body(fixture("tags.json"))
        .expect(3)
        .create();

    let existing_entity = json!({
        "id": "ent-fill-1",
        "name": "Multimeter",
        "description": "True RMS multimeter",
        "quantity": 2,
        "entityTypeId": "et-item",
        "tags": [{ "id": "tag-elec", "name": "electronics" }],
        "tagIds": ["tag-elec"],
        "purchasePrice": 120.0,
        "purchaseDate": "2026-01-15",
        "purchaseFrom": "",
        "fields": [
            {
                "id": "fld-mfg",
                "name": "Manufacturer",
                "type": "text",
                "value": "Fluke",
                "textValue": "Fluke"
            },
            {
                "id": "fld-model",
                "name": "Model Number",
                "type": "text",
                "value": "",
                "textValue": ""
            }
        ]
    });

    // 1. item update --fill-missing
    let get_update = server
        .mock("GET", "/api/v1/entities/ent-fill-1")
        .with_status(200)
        .with_body(existing_entity.to_string())
        .expect(1)
        .create();

    let put_update = server
        .mock("PUT", "/api/v1/entities/ent-fill-1")
        .match_body(Matcher::AllOf(vec![
            Matcher::Regex(r#""description":"True RMS multimeter""#.to_string()),
            Matcher::Regex(r#""purchasePrice":120\.0"#.to_string()),
            Matcher::Regex(r#""purchaseDate":"2026-01-15""#.to_string()),
            Matcher::Regex(r#""purchaseFrom":"DigiKey""#.to_string()),
            Matcher::Regex(r#""tagIds":\["tag-elec","tag-tools"\]"#.to_string()),
            Matcher::Regex(r#""name":"Manufacturer"[^}]*"value":"Fluke""#.to_string()),
            Matcher::Regex(r#""name":"Model Number"[^}]*"value":"87V""#.to_string()),
            Matcher::Regex(r#""name":"Notes"[^}]*"value":"Calibrated""#.to_string()),
        ]))
        .with_status(200)
        .with_body(existing_entity.to_string())
        .expect(1)
        .create();

    hbctl(&server.url())
        .args([
            "-q",
            "item",
            "update",
            "ent-fill-1",
            "--fill-missing",
            "--description",
            "Overwrite attempt",
            "--purchase-price",
            "999",
            "--purchase-date",
            "2026-12-31",
            "--purchase-from",
            "DigiKey",
            "--manufacturer",
            "OtherMfg",
            "--model",
            "87V",
            "--notes",
            "Calibrated",
            "--add-tag",
            "tools",
        ])
        .assert()
        .success()
        .stdout(predicate::eq("ent-fill-1\n"));

    get_update.assert();
    put_update.assert();

    // 2. item upsert --fill-missing
    let list_upsert = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::UrlEncoded("q".into(), "Multimeter".into()))
        .with_status(200)
        .with_body(json!([existing_entity]).to_string())
        .expect(1)
        .create();

    let get_upsert = server
        .mock("GET", "/api/v1/entities/ent-fill-1")
        .with_status(200)
        .with_body(existing_entity.to_string())
        .expect(1)
        .create();

    let put_upsert = server
        .mock("PUT", "/api/v1/entities/ent-fill-1")
        .match_body(Matcher::AllOf(vec![
            Matcher::Regex(r#""description":"True RMS multimeter""#.to_string()),
            Matcher::Regex(r#""purchaseFrom":"Mouser""#.to_string()),
            Matcher::Regex(r#""tagIds":\["tag-elec","tag-tools"\]"#.to_string()),
            Matcher::Regex(r#""name":"Manufacturer"[^}]*"value":"Fluke""#.to_string()),
            Matcher::Regex(r#""name":"Model Number"[^}]*"value":"87V""#.to_string()),
        ]))
        .with_status(200)
        .with_body(existing_entity.to_string())
        .expect(1)
        .create();

    hbctl(&server.url())
        .args([
            "-q",
            "item",
            "upsert",
            "--name",
            "Multimeter",
            "--fill-missing",
            "--description",
            "Overwrite attempt",
            "--purchase-from",
            "Mouser",
            "--manufacturer",
            "OtherMfg",
            "--model",
            "87V",
            "--tag",
            "tools",
        ])
        .assert()
        .success()
        .stdout(predicate::eq("ent-fill-1\n"));

    list_upsert.assert();
    get_upsert.assert();
    put_upsert.assert();

    // 3. item import --update-existing --fill-missing
    let tmp = tempdir().unwrap();
    let import_file = tmp.path().join("fill_missing_import.json");
    fs::write(
        &import_file,
        json!([
            {
                "name": "Multimeter",
                "description": "Overwrite attempt",
                "quantity": 99,
                "purchasePrice": 999.0,
                "purchaseDate": "2026-12-31",
                "purchaseFrom": "Amazon",
                "manufacturer": "OtherMfg",
                "modelNumber": "87V",
                "notes": "From invoice",
                "tags": ["tools"]
            }
        ])
        .to_string(),
    )
    .unwrap();

    let list_import = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_body(json!({ "items": [existing_entity], "total": 1 }).to_string())
        .expect(1)
        .create();

    let get_import = server
        .mock("GET", "/api/v1/entities/ent-fill-1")
        .with_status(200)
        .with_body(existing_entity.to_string())
        .expect(1)
        .create();

    let put_import = server
        .mock("PUT", "/api/v1/entities/ent-fill-1")
        .match_body(Matcher::AllOf(vec![
            Matcher::Regex(r#""description":"True RMS multimeter""#.to_string()),
            Matcher::Regex(r#""quantity":2"#.to_string()),
            Matcher::Regex(r#""purchasePrice":120\.0"#.to_string()),
            Matcher::Regex(r#""purchaseDate":"2026-01-15""#.to_string()),
            Matcher::Regex(r#""purchaseFrom":"Amazon""#.to_string()),
            Matcher::Regex(r#""tagIds":\["tag-elec","tag-tools"\]"#.to_string()),
            Matcher::Regex(r#""name":"Manufacturer"[^}]*"value":"Fluke""#.to_string()),
            Matcher::Regex(r#""name":"Model Number"[^}]*"value":"87V""#.to_string()),
            Matcher::Regex(r#""name":"Notes"[^}]*"value":"From invoice""#.to_string()),
        ]))
        .with_status(200)
        .with_body(existing_entity.to_string())
        .expect(1)
        .create();

    let out = hbctl(&server.url())
        .args([
            "--json",
            "item",
            "import",
            import_file.to_str().unwrap(),
            "--update-existing",
            "--fill-missing",
        ])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();

    let summary: Value = serde_json::from_slice(&out).unwrap();
    assert_eq!(summary["created"], 0);
    assert_eq!(summary["updated"], 1);
    assert_eq!(summary["skipped"], 0);
    assert_eq!(summary["ids"], json!(["ent-fill-1"]));

    tags_mock.assert();
    list_import.assert();
    get_import.assert();
    put_import.assert();
}

#[test]
fn test_item_upsert_from_json_match_by_and_action_output() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();
    let tmp = tempdir().unwrap();

    let _tags = server
        .mock("GET", "/api/v1/tags")
        .with_status(200)
        .with_body(fixture("tags.json"))
        .expect_at_least(1)
        .create();

    // Summary list omits fields (`fields: null`) -> triggers hydration when --match-by uses serial/model/field
    let list_summary = json!([
        { "id": "ent-by-name", "name": "Fluke 87V", "quantity": 1 },
        { "id": "ent-by-serial", "name": "Bench DMM", "quantity": 1 }
    ]);

    let detail_by_name = json!({
        "id": "ent-by-name",
        "name": "Fluke 87V",
        "quantity": 1,
        "fields": [
            { "id": "f1", "name": "Model Number", "type": "text", "value": "87V", "textValue": "87V" },
            { "id": "f2", "name": "Serial Number", "type": "text", "value": "SN-OLD", "textValue": "SN-OLD" }
        ]
    });

    let detail_by_serial = json!({
        "id": "ent-by-serial",
        "name": "Bench DMM",
        "quantity": 1,
        "fields": [
            { "id": "f3", "name": "Model Number", "type": "text", "value": "87V", "textValue": "87V" },
            { "id": "f4", "name": "Serial Number", "type": "text", "value": "SN-MATCH-1", "textValue": "SN-MATCH-1" }
        ]
    });

    // 1. item upsert --from-json <file> --match-by serial --match-by model --match-by name
    let list_1 = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_body(list_summary.to_string())
        .expect(1)
        .create();
    let get_name_1 = server
        .mock("GET", "/api/v1/entities/ent-by-name")
        .with_status(200)
        .with_body(detail_by_name.to_string())
        .expect(1)
        .create();
    // Hydrate + update_entity GET = 2 calls
    let get_serial_1 = server
        .mock("GET", "/api/v1/entities/ent-by-serial")
        .with_status(200)
        .with_body(detail_by_serial.to_string())
        .expect(2)
        .create();
    let put_serial_1 = server
        .mock("PUT", "/api/v1/entities/ent-by-serial")
        .match_body(Matcher::Regex(r#""quantity":3"#.to_string()))
        .with_status(200)
        .with_body(
            json!({
                "id": "ent-by-serial",
                "name": "Bench DMM",
                "quantity": 3,
                "fields": detail_by_serial["fields"]
            })
            .to_string(),
        )
        .expect(1)
        .create();

    let upsert_json = tmp.path().join("upsert.json");
    fs::write(
        &upsert_json,
        json!({
            "name": "Fluke 87V",
            "quantity": 3,
            "modelNumber": "87V",
            "serialNumber": "SN-MATCH-1",
            "manufacturer": "Fluke"
        })
        .to_string(),
    )
    .unwrap();

    let out_update = hbctl(&server.url())
        .args([
            "--json",
            "item",
            "upsert",
            "--from-json",
            upsert_json.to_str().unwrap(),
            "--match-by",
            "serial",
            "--match-by",
            "model",
            "--match-by",
            "name",
        ])
        .assert()
        .success()
        .stderr(predicate::str::contains(
            "updated item 'Bench DMM' (ent-by-serial)",
        ))
        .get_output()
        .stdout
        .clone();

    let updated_val: Value = serde_json::from_slice(&out_update).unwrap();
    assert_eq!(updated_val["id"], "ent-by-serial");
    assert_eq!(updated_val["action"], "updated");

    list_1.assert();
    get_name_1.assert();
    get_serial_1.assert();
    put_serial_1.assert();

    // 2. item upsert --from-json - (stdin) -> creates new item when no match found
    let list_2 = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_body("[]")
        .expect(1)
        .create();
    let post_2 = server
        .mock("POST", "/api/v1/entities")
        .match_body(Matcher::Regex(r#""name":"Oscilloscope""#.to_string()))
        .with_status(201)
        .with_body(r#"{"id":"ent-new-1","name":"Oscilloscope","quantity":1,"fields":[]}"#)
        .expect(1)
        .create();
    let put_2 = server
        .mock("PUT", "/api/v1/entities/ent-new-1")
        .match_body(Matcher::Regex(r#""name":"Serial Number"[^}]*"value":"SN-NEW-9""#.to_string()))
        .with_status(200)
        .with_body(r#"{"id":"ent-new-1","name":"Oscilloscope","quantity":1,"fields":[{"name":"Serial Number","type":"text","value":"SN-NEW-9","textValue":"SN-NEW-9"}]}"#)
        .expect(1)
        .create();

    let stdin_payload = json!({
        "name": "Oscilloscope",
        "serialNumber": "SN-NEW-9",
        "fields": [{ "name": "SKU", "type": "text", "value": "SKU-OSC-1", "textValue": "SKU-OSC-1" }]
    })
    .to_string();

    let out_create = hbctl(&server.url())
        .args([
            "--json",
            "item",
            "upsert",
            "--from-json",
            "-",
            "--match-by",
            "field:SKU",
            "--match-by",
            "name",
        ])
        .write_stdin(stdin_payload)
        .assert()
        .success()
        .stderr(predicate::str::contains(
            "created item 'Oscilloscope' (ent-new-1)",
        ))
        .get_output()
        .stdout
        .clone();

    let created_val: Value = serde_json::from_slice(&out_create).unwrap();
    assert_eq!(created_val["id"], "ent-new-1");
    assert_eq!(created_val["action"], "created");

    list_2.assert();
    post_2.assert();
    put_2.assert();

    // 3. -q keeps stdout strictly ID-only while stderr reports action
    let list_3 = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::UrlEncoded("q".into(), "Fluke 87V".into()))
        .with_status(200)
        .with_body(json!([detail_by_name]).to_string())
        .expect(1)
        .create();
    let get_3 = server
        .mock("GET", "/api/v1/entities/ent-by-name")
        .with_status(200)
        .with_body(detail_by_name.to_string())
        .expect(1)
        .create();
    let put_3 = server
        .mock("PUT", "/api/v1/entities/ent-by-name")
        .with_status(200)
        .with_body(detail_by_name.to_string())
        .expect(1)
        .create();

    hbctl(&server.url())
        .args([
            "-q",
            "item",
            "upsert",
            "--from-json",
            upsert_json.to_str().unwrap(),
        ])
        .assert()
        .success()
        .stdout(predicate::eq("ent-by-name\n"))
        .stderr(predicate::str::contains(
            "updated item 'Fluke 87V' (ent-by-name)",
        ));

    list_3.assert();
    get_3.assert();
    put_3.assert();

    // 4. item import --update-existing --match-by serial,model,name
    let import_file = tmp.path().join("import_match_by.json");
    fs::write(
        &import_file,
        json!([
            { "name": "Fluke 87V", "serialNumber": "SN-MATCH-1", "quantity": 5 },
            { "name": "Renamed Meter", "modelNumber": "87V", "quantity": 6 },
            { "name": "Brand New Probe", "quantity": 2 }
        ])
        .to_string(),
    )
    .unwrap();

    let list_imp = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_body(list_summary.to_string())
        .expect(1)
        .create();
    // Row 2 matches ent-by-name via modelNumber=87V (1 hydrate + 1 update_entity GET)
    let get_imp_name = server
        .mock("GET", "/api/v1/entities/ent-by-name")
        .with_status(200)
        .with_body(detail_by_name.to_string())
        .expect(2)
        .create();
    // Row 1 matches ent-by-serial via serialNumber=SN-MATCH-1 (1 hydrate + 1 update_entity GET)
    let get_imp_serial = server
        .mock("GET", "/api/v1/entities/ent-by-serial")
        .with_status(200)
        .with_body(detail_by_serial.to_string())
        .expect(2)
        .create();
    let put_imp_serial = server
        .mock("PUT", "/api/v1/entities/ent-by-serial")
        .match_body(Matcher::Regex(r#""quantity":5"#.to_string()))
        .with_status(200)
        .with_body(detail_by_serial.to_string())
        .expect(1)
        .create();
    let put_imp_name = server
        .mock("PUT", "/api/v1/entities/ent-by-name")
        .match_body(Matcher::Regex(r#""quantity":6"#.to_string()))
        .with_status(200)
        .with_body(detail_by_name.to_string())
        .expect(1)
        .create();
    let post_imp_new = server
        .mock("POST", "/api/v1/entities")
        .match_body(Matcher::Regex(r#""name":"Brand New Probe""#.to_string()))
        .with_status(201)
        .with_body(r#"{"id":"ent-probe","name":"Brand New Probe","quantity":2,"fields":[]}"#)
        .expect(1)
        .create();

    let imp_out = hbctl(&server.url())
        .args([
            "--json",
            "item",
            "import",
            import_file.to_str().unwrap(),
            "--update-existing",
            "--match-by",
            "serial,model,name",
        ])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();

    let imp_summary: Value = serde_json::from_slice(&imp_out).unwrap();
    assert_eq!(imp_summary["created"], 1);
    assert_eq!(imp_summary["updated"], 2);
    assert_eq!(imp_summary["skipped"], 0);
    assert_eq!(
        imp_summary["ids"],
        json!(["ent-by-serial", "ent-by-name", "ent-probe"])
    );

    list_imp.assert();
    get_imp_name.assert();
    get_imp_serial.assert();
    put_imp_serial.assert();
    put_imp_name.assert();
    post_imp_new.assert();
}

#[test]
fn test_search_custom_field_filters_and_hydration() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();

    let _tags = server
        .mock("GET", "/api/v1/tags")
        .with_status(200)
        .with_body(fixture("tags.json"))
        .expect_at_least(1)
        .create();

    let summary_all = json!([
        { "id": "ent-s1", "name": "Fluke 87V Meter", "quantity": 1 },
        { "id": "ent-s2", "name": "Rigol Meter", "quantity": 1 },
        { "id": "ent-s3", "name": "Spare Probe", "quantity": 1 }
    ]);

    let detail_s1 = json!({
        "id": "ent-s1",
        "name": "Fluke 87V Meter",
        "quantity": 1,
        "fields": [
            { "id": "f1", "name": "Manufacturer", "type": "text", "value": "Fluke", "textValue": "Fluke" },
            { "id": "f2", "name": "ASIN", "type": "text", "value": "B000VR66FA", "textValue": "B000VR66FA" },
            { "id": "f3", "name": "Order Number", "type": "text", "value": "ORD-42-991", "textValue": "ORD-42-991" },
            { "id": "f4", "name": "Tare Weight (g)", "type": "number", "value": "25.5", "textValue": "25.5", "numberValue": 25.5 }
        ]
    });

    let detail_s2 = json!({
        "id": "ent-s2",
        "name": "Rigol Meter",
        "quantity": 1,
        "fields": [
            { "id": "f5", "name": "Manufacturer", "type": "text", "value": "Rigol", "textValue": "Rigol" },
            { "id": "f6", "name": "ASIN", "type": "text", "value": "   ", "textValue": "   " },
            { "id": "f7", "name": "Order Number", "type": "text", "value": "ORD-42-777", "textValue": "ORD-42-777" }
        ]
    });

    let detail_s3 = json!({
        "id": "ent-s3",
        "name": "Spare Probe",
        "quantity": 1,
        "fields": [
            { "id": "f8", "name": "ASIN", "type": "text", "value": "B009PROBES", "textValue": "B009PROBES" }
        ]
    });

    let list_combined = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::AllOf(vec![
            Matcher::UrlEncoded("q".into(), "meter".into()),
            Matcher::UrlEncoded("tags".into(), "tag-elec".into()),
        ]))
        .with_status(200)
        .with_body(json!([summary_all[0], summary_all[1]]).to_string())
        .expect(1)
        .create();

    let list_plain = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_body(summary_all.to_string())
        .expect(2)
        .create();

    let get_s1 = server
        .mock("GET", "/api/v1/entities/ent-s1")
        .with_status(200)
        .with_body(detail_s1.to_string())
        .expect(3)
        .create();

    let get_s2 = server
        .mock("GET", "/api/v1/entities/ent-s2")
        .with_status(200)
        .with_body(detail_s2.to_string())
        .expect(3)
        .create();

    let get_s3 = server
        .mock("GET", "/api/v1/entities/ent-s3")
        .with_status(200)
        .with_body(detail_s3.to_string())
        .expect(2)
        .create();

    // 1. Existence check (--field ASIN) ignores missing/blank ASIN
    hbctl(&server.url())
        .args(["-q", "search", "--field", "ASIN"])
        .assert()
        .success()
        .stdout(predicate::eq("ent-s1\nent-s3\n"));

    // 2. Substring case-insensitive value check (--field "Order Number=ord-42")
    hbctl(&server.url())
        .args(["-q", "search", "--field", "Order Number=ord-42"])
        .assert()
        .success()
        .stdout(predicate::eq("ent-s1\nent-s2\n"));

    // 3. Combined query + --tag + --manufacturer + multiple --field filters (logical AND)
    hbctl(&server.url())
        .args([
            "-q",
            "search",
            "meter",
            "--tag",
            "electronics",
            "--manufacturer",
            "Fluke",
            "--field",
            "ASIN",
            "--field",
            "Tare Weight (g)=25",
        ])
        .assert()
        .success()
        .stdout(predicate::eq("ent-s1\n"));

    // 4. Invalid --field fails fast
    hbctl(&server.url())
        .args(["search", "--field", "=bad"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("key cannot be empty"));

    list_plain.assert();
    list_combined.assert();
    get_s1.assert();
    get_s2.assert();
    get_s3.assert();
}

#[test]
fn test_export_custom_columns_aliases_align_and_empty() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();

    let summary = json!([
        { "id": "ent-e1", "name": "Canister A", "quantity": 1 },
        { "id": "ent-e2", "name": "Canister B", "quantity": 2 }
    ]);

    let detail_e1 = json!({
        "id": "ent-e1",
        "name": "Canister A",
        "quantity": 1,
        "fields": [
            { "id": "f1", "name": "Manufacturer", "type": "text", "value": "OXO", "textValue": "OXO" },
            { "id": "f2", "name": "Tare Weight (g)", "type": "number", "value": "182", "textValue": "182", "numberValue": 182 }
        ]
    });

    let detail_e2 = json!({
        "id": "ent-e2",
        "name": "Canister B",
        "quantity": 2,
        "fields": [
            { "id": "f3", "name": "Manufacturer", "type": "text", "value": "OXO", "textValue": "OXO" }
        ]
    });

    let list_mock = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_body(summary.to_string())
        .expect(4)
        .create();

    // Hydrated on the first 3 calls (custom fields requested), NOT on the 4th call (summary built-ins only)
    let get_e1 = server
        .mock("GET", "/api/v1/entities/ent-e1")
        .with_status(200)
        .with_body(detail_e1.to_string())
        .expect(3)
        .create();
    let get_e2 = server
        .mock("GET", "/api/v1/entities/ent-e2")
        .with_status(200)
        .with_body(detail_e2.to_string())
        .expect(3)
        .create();

    // 1. Markdown with --columns, header alias, --align left, and --empty placeholder
    hbctl(&server.url())
        .args([
            "export",
            "--format",
            "markdown",
            "--columns",
            "name=Container / Item,Tare Weight (g)",
            "--align",
            "left",
            "--empty",
            "—",
        ])
        .assert()
        .success()
        .stdout(predicate::eq(
            "| Container / Item | Tare Weight (g) |\n| :--- | :--- |\n| Canister A | 182 |\n| Canister B | — |\n",
        ));

    // 2. Markdown with --select, --align right, and --empty N/A
    hbctl(&server.url())
        .args([
            "export",
            "--format",
            "markdown",
            "--select",
            "name,Tare Weight (g)",
            "--align",
            "right",
            "--empty",
            "N/A",
        ])
        .assert()
        .success()
        .stdout(predicate::eq(
            "| name | Tare Weight (g) |\n| ---: | ---: |\n| Canister A | 182 |\n| Canister B | N/A |\n",
        ));

    // 3. CSV with --columns, header aliases, and --empty placeholder
    hbctl(&server.url())
        .args([
            "export",
            "--format",
            "csv",
            "--columns",
            "name=Item,Manufacturer,Tare Weight (g)=Tare (g)",
            "--empty",
            "-",
        ])
        .assert()
        .success()
        .stdout(predicate::eq(
            "Item,Manufacturer,Tare (g)\nCanister A,OXO,182\nCanister B,OXO,-\n",
        ));

    // 4. Built-in summary columns only with --align center (skips hydration)
    hbctl(&server.url())
        .args([
            "export",
            "--format",
            "markdown",
            "--columns",
            "name,quantity",
            "--align",
            "center",
        ])
        .assert()
        .success()
        .stdout(predicate::eq(
            "| name | quantity |\n| :---: | :---: |\n| Canister A | 1 |\n| Canister B | 2 |\n",
        ));

    list_mock.assert();
    get_e1.assert();
    get_e2.assert();
}

#[test]
fn test_item_parent_resolution_move_and_tree() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();

    let _tags = server
        .mock("GET", "/api/v1/tags")
        .with_status(200)
        .with_body(fixture("tags.json"))
        .expect_at_least(1)
        .create();

    let garage = json!({ "id": "ent-garage", "name": "Garage", "quantity": 1, "fields": [] });
    let shelf = json!({
        "id": "ent-shelf",
        "name": "Shelf A",
        "quantity": 1,
        "parentId": "ent-garage",
        "fields": []
    });
    let dmm_in_shelf = json!({
        "id": "ent-dmm",
        "name": "Multimeter",
        "quantity": 1,
        "parentId": "ent-shelf",
        "fields": [{ "id": "f1", "name": "Manufacturer", "type": "text", "value": "Fluke", "textValue": "Fluke" }]
    });
    let dmm_in_garage = json!({
        "id": "ent-dmm",
        "name": "Multimeter",
        "quantity": 1,
        "parentId": "ent-garage",
        "fields": dmm_in_shelf["fields"]
    });
    let dmm_unparented = json!({
        "id": "ent-dmm",
        "name": "Multimeter",
        "quantity": 1,
        "fields": dmm_in_shelf["fields"]
    });

    // List mocks in specific-before-generic order so item create/list/move/tree resolve cleanly
    let list_all = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_body(json!([garage, shelf, dmm_in_shelf]).to_string())
        .expect_at_least(6)
        .create();

    // 1. item create --parent "Shelf A" --field Manufacturer=Fluke (POST + follow-up PUT both preserve parentId)
    let post_create = server
        .mock("POST", "/api/v1/entities")
        .match_body(Matcher::Regex(r#""parentId":"ent-shelf""#.to_string()))
        .with_status(201)
        .with_body(
            json!({
                "id": "ent-dmm",
                "name": "Multimeter",
                "quantity": 1,
                "parentId": "ent-shelf",
                "fields": []
            })
            .to_string(),
        )
        .expect(1)
        .create();
    let put_create = server
        .mock("PUT", "/api/v1/entities/ent-dmm")
        .match_body(Matcher::AllOf(vec![
            Matcher::Regex(r#""parentId":"ent-shelf""#.to_string()),
            Matcher::Regex(r#""Manufacturer""#.to_string()),
        ]))
        .with_status(200)
        .with_body(dmm_in_shelf.to_string())
        .expect(1)
        .create();

    hbctl(&server.url())
        .args([
            "-q",
            "item",
            "create",
            "--name",
            "Multimeter",
            "--parent",
            "Shelf A",
            "--field",
            "Manufacturer=Fluke",
        ])
        .assert()
        .success()
        .stdout(predicate::eq("ent-dmm\n"));

    post_create.assert();
    put_create.assert();

    // 2. item list --parent "Shelf A" and --parent none
    hbctl(&server.url())
        .args(["-q", "item", "list", "--parent", "Shelf A"])
        .assert()
        .success()
        .stdout(predicate::eq("ent-dmm\n"));

    hbctl(&server.url())
        .args(["-q", "item", "list", "--parent", "none"])
        .assert()
        .success()
        .stdout(predicate::eq("ent-garage\n"));

    // 3. item move ent-dmm "Garage", then item move ent-dmm none
    let get_dmm_1 = server
        .mock("GET", "/api/v1/entities/ent-dmm")
        .with_status(200)
        .with_body(dmm_in_shelf.to_string())
        .expect(2)
        .create();
    let put_move_garage = server
        .mock("PUT", "/api/v1/entities/ent-dmm")
        .match_body(Matcher::Regex(r#""parentId":"ent-garage""#.to_string()))
        .with_status(200)
        .with_body(dmm_in_garage.to_string())
        .expect(1)
        .create();

    hbctl(&server.url())
        .args(["-q", "item", "move", "ent-dmm", "Garage"])
        .assert()
        .success()
        .stdout(predicate::eq("ent-dmm\n"))
        .stderr(predicate::str::contains(
            "moved item 'Multimeter' (ent-dmm) under ent-garage",
        ));

    let put_move_none = server
        .mock("PUT", "/api/v1/entities/ent-dmm")
        .match_body(Matcher::Regex(r#""quantity":1,"tags":"#.to_string()))
        .with_status(200)
        .with_body(dmm_unparented.to_string())
        .expect(1)
        .create();

    hbctl(&server.url())
        .args(["-q", "item", "move", "ent-dmm", "none"])
        .assert()
        .success()
        .stdout(predicate::eq("ent-dmm\n"))
        .stderr(predicate::str::contains(
            "unparented item 'Multimeter' (ent-dmm)",
        ));

    get_dmm_1.assert();
    put_move_garage.assert();
    put_move_none.assert();

    // 4. item tree (Unicode hierarchy, --json nested tree, and --root subtree)
    hbctl(&server.url())
        .args(["item", "tree"])
        .assert()
        .success()
        .stdout(predicate::eq(
            "Garage (ent-garage) [qty: 1]\n└── Shelf A (ent-shelf) [qty: 1]\n    └── Multimeter (ent-dmm) [qty: 1]\n",
        ));

    let tree_json_out = hbctl(&server.url())
        .args(["--json", "item", "tree"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let tree_json: Value = serde_json::from_slice(&tree_json_out).unwrap();
    assert_eq!(tree_json[0]["id"], "ent-garage");
    assert_eq!(tree_json[0]["children"][0]["id"], "ent-shelf");
    assert_eq!(tree_json[0]["children"][0]["children"][0]["id"], "ent-dmm");

    hbctl(&server.url())
        .args(["item", "tree", "--root", "Shelf A"])
        .assert()
        .success()
        .stdout(predicate::eq(
            "Shelf A (ent-shelf) [qty: 1]\n└── Multimeter (ent-dmm) [qty: 1]\n",
        ));

    list_all.assert();
}

#[test]
fn test_inline_attach_name_override_stdin_and_dry_run() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();
    let tmp = tempdir().unwrap();

    let raw_tmp_file = tmp.path().join("tmpblob.bin");
    fs::write(&raw_tmp_file, b"%PDF-1.4\nhello custom\n").unwrap();

    let small_pdf = tmp.path().join("datasheet.pdf");
    fs::write(&small_pdf, b"%PDF-1.4\ninline\n").unwrap();

    let big_png = tmp.path().join("big_photo.png");
    fs::write(&big_png, vec![0u8; 510 * 1024]).unwrap();

    let get_ent1 = server
        .mock("GET", "/api/v1/entities/ent-1")
        .with_status(200)
        .with_body(r#"{"id":"ent-1","name":"Board","quantity":1,"attachments":[]}"#)
        .expect(2)
        .create();

    // 1. attachment upload --name custom-manual.pdf
    let post_custom_name = server
        .mock("POST", "/api/v1/entities/ent-1/attachments")
        .match_body(Matcher::AllOf(vec![
            Matcher::Regex("filename=\"custom-manual\\.pdf\"".to_string()),
            Matcher::Regex("hello custom".to_string()),
        ]))
        .with_status(200)
        .with_body(r#"{"id":"att-c1","title":"custom-manual.pdf","name":"custom-manual.pdf","mimeType":"application/pdf"}"#)
        .expect(1)
        .create();

    let out_custom = hbctl(&server.url())
        .args([
            "--json",
            "attachment",
            "upload",
            "ent-1",
            raw_tmp_file.to_str().unwrap(),
            "--name",
            "custom-manual.pdf",
        ])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let parsed_custom: Value = serde_json::from_slice(&out_custom).unwrap();
    assert_eq!(parsed_custom[0]["file"], "custom-manual.pdf");
    assert_eq!(parsed_custom[0]["status"], "uploaded");

    // 2. attachment upload - --name piped.pdf (stdin) + failure without --name
    hbctl(&server.url())
        .args(["attachment", "upload", "ent-1", "-"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("--name <FILENAME> is required"));

    let post_stdin = server
        .mock("POST", "/api/v1/entities/ent-1/attachments")
        .match_body(Matcher::AllOf(vec![
            Matcher::Regex("filename=\"piped\\.pdf\"".to_string()),
            Matcher::Regex("piped bytes".to_string()),
        ]))
        .with_status(200)
        .with_body(r#"{"id":"att-s1","title":"piped.pdf","name":"piped.pdf","mimeType":"application/pdf"}"#)
        .expect(1)
        .create();

    let out_stdin = hbctl(&server.url())
        .args([
            "--json",
            "attachment",
            "upload",
            "ent-1",
            "-",
            "--name",
            "piped.pdf",
        ])
        .write_stdin(b"%PDF-1.4\npiped bytes\n".as_slice())
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let parsed_stdin: Value = serde_json::from_slice(&out_stdin).unwrap();
    assert_eq!(parsed_stdin[0]["file"], "piped.pdf");
    assert_eq!(parsed_stdin[0]["status"], "uploaded");

    // 3. attachment upload - --name piped.pdf --dry-run (does not read stdin)
    let dry_upload_out = hbctl("http://127.0.0.1:1")
        .args([
            "--json",
            "attachment",
            "upload",
            "ent-1",
            "-",
            "--name",
            "piped.pdf",
            "--dry-run",
        ])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let dry_upload: Value = serde_json::from_slice(&dry_upload_out).unwrap();
    assert_eq!(dry_upload[0]["method"], "POST");
    assert_eq!(
        dry_upload[0]["url"],
        "http://127.0.0.1:1/api/v1/entities/ent-1/attachments"
    );
    assert_eq!(dry_upload[0]["body"]["name"], "piped.pdf");
    assert_eq!(dry_upload[0]["body"]["file"], "-");

    // 4. item create --attach --dry-run
    let dry_create_out = hbctl("http://127.0.0.1:1")
        .args([
            "--json",
            "item",
            "create",
            "--name",
            "Board",
            "--attach",
            small_pdf.to_str().unwrap(),
            "--dry-run",
        ])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let dry_create: Value = serde_json::from_slice(&dry_create_out).unwrap();
    assert_eq!(dry_create.as_array().unwrap().len(), 2);
    assert_eq!(dry_create[0]["method"], "POST");
    assert_eq!(
        dry_create[1]["url"],
        "http://127.0.0.1:1/api/v1/entities/<created-id>/attachments"
    );

    // 5. item create --attach oversized PNG fails without --force, succeeds with --force
    hbctl(&server.url())
        .args([
            "item",
            "create",
            "--name",
            "Board",
            "--attach",
            big_png.to_str().unwrap(),
        ])
        .assert()
        .failure()
        .stderr(predicate::str::contains("exceeds"));

    let post_item_big = server
        .mock("POST", "/api/v1/entities")
        .match_body(Matcher::Regex(r#""name":"Board""#.to_string()))
        .with_status(201)
        .with_body(r#"{"id":"ent-board","name":"Board","quantity":1,"attachments":[]}"#)
        .expect(1)
        .create();
    let post_att_big = server
        .mock("POST", "/api/v1/entities/ent-board/attachments")
        .match_body(Matcher::Regex("filename=\"big_photo\\.png\"".to_string()))
        .with_status(200)
        .with_body(r#"{"id":"att-big","title":"big_photo.png","name":"big_photo.png"}"#)
        .expect(1)
        .create();

    hbctl(&server.url())
        .args([
            "-q",
            "item",
            "create",
            "--name",
            "Board",
            "--attach",
            big_png.to_str().unwrap(),
            "--force",
        ])
        .assert()
        .success()
        .stdout(predicate::eq("ent-board\n"))
        .stderr(predicate::str::contains("due to --force"));

    // 6. item upsert --attach <pdf>
    let list_upsert = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::UrlEncoded("q".into(), "Board".into()))
        .with_status(200)
        .with_body(r#"[{"id":"ent-board","name":"Board","quantity":1,"attachments":[]}]"#)
        .expect(1)
        .create();
    let get_upsert = server
        .mock("GET", "/api/v1/entities/ent-board")
        .with_status(200)
        .with_body(r#"{"id":"ent-board","name":"Board","quantity":1,"attachments":[]}"#)
        .expect(1)
        .create();
    let put_upsert = server
        .mock("PUT", "/api/v1/entities/ent-board")
        .with_status(200)
        .with_body(r#"{"id":"ent-board","name":"Board","quantity":1,"attachments":[]}"#)
        .expect(1)
        .create();
    let post_att_upsert = server
        .mock("POST", "/api/v1/entities/ent-board/attachments")
        .match_body(Matcher::Regex("filename=\"datasheet\\.pdf\"".to_string()))
        .with_status(200)
        .with_body(r#"{"id":"att-ds","title":"datasheet.pdf","name":"datasheet.pdf"}"#)
        .expect(1)
        .create();

    hbctl(&server.url())
        .args([
            "-q",
            "item",
            "upsert",
            "--name",
            "Board",
            "--attach",
            small_pdf.to_str().unwrap(),
        ])
        .assert()
        .success()
        .stdout(predicate::eq("ent-board\n"));

    // 7. item import with JSON "attachments" array
    let import_json = tmp.path().join("import_with_att.json");
    fs::write(
        &import_json,
        json!([
            {
                "name": "Imported Board",
                "quantity": 1,
                "attachments": [small_pdf.to_str().unwrap()]
            }
        ])
        .to_string(),
    )
    .unwrap();

    let post_imp = server
        .mock("POST", "/api/v1/entities")
        .match_body(Matcher::Regex(r#""name":"Imported Board""#.to_string()))
        .with_status(201)
        .with_body(r#"{"id":"ent-imp-1","name":"Imported Board","quantity":1,"attachments":[]}"#)
        .expect(1)
        .create();
    let post_att_imp = server
        .mock("POST", "/api/v1/entities/ent-imp-1/attachments")
        .match_body(Matcher::Regex("filename=\"datasheet\\.pdf\"".to_string()))
        .with_status(200)
        .with_body(r#"{"id":"att-imp-1","title":"datasheet.pdf","name":"datasheet.pdf"}"#)
        .expect(1)
        .create();

    let imp_out = hbctl(&server.url())
        .args(["--json", "item", "import", import_json.to_str().unwrap()])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let imp_summary: Value = serde_json::from_slice(&imp_out).unwrap();
    assert_eq!(imp_summary["created"], 1);
    assert_eq!(imp_summary["ids"], json!(["ent-imp-1"]));

    get_ent1.assert();
    post_custom_name.assert();
    post_stdin.assert();
    post_item_big.assert();
    post_att_big.assert();
    list_upsert.assert();
    get_upsert.assert();
    put_upsert.assert();
    post_att_upsert.assert();
    post_imp.assert();
    post_att_imp.assert();
}

#[test]
fn test_bulk_attachment_download_all_tag_items_from_skip_overwrite_and_dry_run() {
    if !can_execute_binary() {
        return;
    }

    let tmp = tempdir().unwrap();

    // 1. --all-items --ext pdf --out <dir> --json (+ skip existing + --overwrite -q + --dry-run)
    {
        let mut server = Server::new();
        let out_dir = tmp.path().join("all_items");

        let list_all = server
            .mock("GET", "/api/v1/entities")
            .match_query(Matcher::Any)
            .with_status(200)
            .with_body(
                json!({
                    "items": [
                        {
                            "id": "ent-w",
                            "name": "Washer",
                            "quantity": 1,
                            "tags": [{"id": "tag-app", "name": "appliances"}],
                            "attachments": null
                        },
                        {
                            "id": "ent-d",
                            "name": "Dryer",
                            "quantity": 1,
                            "tags": [{"id": "tag-app", "name": "appliances"}],
                            "attachments": null
                        }
                    ],
                    "page": 1,
                    "pageSize": 50,
                    "total": 2
                })
                .to_string(),
            )
            .expect(4)
            .create();

        let get_w = server
            .mock("GET", "/api/v1/entities/ent-w")
            .with_status(200)
            .with_body(
                json!({
                    "id": "ent-w",
                    "name": "Washer",
                    "quantity": 1,
                    "attachments": [
                        {"id": "att-w-pdf", "title": "manual.pdf", "mimeType": "application/pdf"},
                        {"id": "att-w-png", "title": "diagram.png", "mimeType": "image/png"}
                    ]
                })
                .to_string(),
            )
            .expect(4)
            .create();

        let get_d = server
            .mock("GET", "/api/v1/entities/ent-d")
            .with_status(200)
            .with_body(
                json!({
                    "id": "ent-d",
                    "name": "Dryer",
                    "quantity": 1,
                    "attachments": [
                        {"id": "att-d-pdf", "title": "manual.pdf", "mimeType": "application/pdf"},
                        {"id": "att-d-spec", "title": "dryer_spec.pdf", "mimeType": "application/pdf"}
                    ]
                })
                .to_string(),
            )
            .expect(4)
            .create();

        let dl_w = server
            .mock("GET", "/api/v1/entities/ent-w/attachments/att-w-pdf")
            .with_status(200)
            .with_body(b"%PDF washer manual")
            .expect(2)
            .create();
        let dl_d = server
            .mock("GET", "/api/v1/entities/ent-d/attachments/att-d-pdf")
            .with_status(200)
            .with_body(b"%PDF dryer manual")
            .expect(2)
            .create();
        let dl_spec = server
            .mock("GET", "/api/v1/entities/ent-d/attachments/att-d-spec")
            .with_status(200)
            .with_body(b"%PDF dryer spec")
            .expect(2)
            .create();

        let out_first = hbctl(&server.url())
            .args([
                "--json",
                "attachment",
                "download",
                "--all-items",
                "--ext",
                "pdf",
                "--out",
                out_dir.to_str().unwrap(),
            ])
            .assert()
            .success()
            .get_output()
            .stdout
            .clone();

        let rows: Vec<Value> = serde_json::from_slice(&out_first).unwrap();
        assert_eq!(rows.len(), 3);
        assert_eq!(rows[0]["entityId"], "ent-w");
        assert_eq!(rows[0]["entityName"], "Washer");
        assert_eq!(rows[0]["id"], "att-w-pdf");
        assert_eq!(rows[0]["status"], "downloaded");
        assert_eq!(rows[1]["entityId"], "ent-d");
        assert_eq!(rows[1]["entityName"], "Dryer");
        assert_eq!(rows[1]["id"], "att-d-pdf");
        assert_eq!(rows[2]["id"], "att-d-spec");

        assert_eq!(
            fs::read(out_dir.join("washer_manual.pdf")).unwrap(),
            b"%PDF washer manual"
        );
        assert_eq!(
            fs::read(out_dir.join("dryer_manual.pdf")).unwrap(),
            b"%PDF dryer manual"
        );
        assert_eq!(
            fs::read(out_dir.join("dryer_spec.pdf")).unwrap(),
            b"%PDF dryer spec"
        );
        assert!(!out_dir.join("diagram.png").exists());

        // Second run without --overwrite skips all existing files
        let out_skip = hbctl(&server.url())
            .args([
                "--json",
                "attachment",
                "download",
                "--all-items",
                "--ext",
                "pdf",
                "--out",
                out_dir.to_str().unwrap(),
            ])
            .assert()
            .success()
            .stderr(predicate::str::contains("skipping existing file"))
            .get_output()
            .stdout
            .clone();
        let skip_rows: Vec<Value> = serde_json::from_slice(&out_skip).unwrap();
        assert_eq!(skip_rows.len(), 3);
        assert!(skip_rows.iter().all(|r| r["status"] == "skipped"));

        // Third run with --overwrite -q re-downloads and outputs only attachment IDs
        hbctl(&server.url())
            .args([
                "-q",
                "attachment",
                "download",
                "--all-items",
                "--ext",
                "pdf",
                "--out",
                out_dir.to_str().unwrap(),
                "--overwrite",
            ])
            .assert()
            .success()
            .stdout(predicate::eq("att-w-pdf\natt-d-pdf\natt-d-spec\n"));

        // Dry-run previews GET requests with entityId, entityName, and out without downloading
        let dry_dir = tmp.path().join("dry_never_created");
        let dry_out = hbctl(&server.url())
            .args([
                "--dry-run",
                "--json",
                "attachment",
                "download",
                "--all-items",
                "--ext",
                "pdf",
                "--out",
                dry_dir.to_str().unwrap(),
            ])
            .assert()
            .success()
            .get_output()
            .stdout
            .clone();
        let dry_rows: Vec<Value> = serde_json::from_slice(&dry_out).unwrap();
        assert_eq!(dry_rows.len(), 3);
        assert_eq!(dry_rows[0]["method"], "GET");
        assert_eq!(dry_rows[0]["body"]["entityId"], "ent-w");
        assert_eq!(dry_rows[0]["body"]["entityName"], "Washer");
        assert!(!dry_dir.exists());

        list_all.assert();
        get_w.assert();
        get_d.assert();
        dl_w.assert();
        dl_d.assert();
        dl_spec.assert();
    }

    // 2. --tag appliances --mime application/pdf --out <dir> (table output)
    {
        let mut server = Server::new();
        let tag_dir = tmp.path().join("by_tag");

        let list_tags = server
            .mock("GET", "/api/v1/tags")
            .with_status(200)
            .with_body(fixture("tags.json"))
            .expect(1)
            .create();
        let list_tagged = server
            .mock("GET", "/api/v1/entities")
            .match_query(Matcher::UrlEncoded(
                "tags".to_string(),
                "tag-elec".to_string(),
            ))
            .with_status(200)
            .with_body(
                json!({
                    "items": [{
                        "id": "ent-t1",
                        "name": "Oven",
                        "quantity": 1,
                        "tags": [{"id": "tag-elec", "name": "electronics"}],
                        "attachments": null
                    }],
                    "page": 1,
                    "pageSize": 50,
                    "total": 1
                })
                .to_string(),
            )
            .expect(1)
            .create();
        let get_t1 = server
            .mock("GET", "/api/v1/entities/ent-t1")
            .with_status(200)
            .with_body(
                json!({
                    "id": "ent-t1",
                    "name": "Oven",
                    "quantity": 1,
                    "attachments": [
                        {"id": "att-oven-pdf", "title": "oven.pdf", "mimeType": "application/pdf"},
                        {"id": "att-oven-txt", "title": "notes.txt", "mimeType": "text/plain"}
                    ]
                })
                .to_string(),
            )
            .expect(1)
            .create();
        let dl_oven = server
            .mock("GET", "/api/v1/entities/ent-t1/attachments/att-oven-pdf")
            .with_status(200)
            .with_body(b"oven manual")
            .expect(1)
            .create();

        hbctl(&server.url())
            .args([
                "attachment",
                "download",
                "--tag",
                "electronics",
                "--mime",
                "application/pdf",
                "--out",
                tag_dir.to_str().unwrap(),
            ])
            .assert()
            .success()
            .stdout(
                predicate::str::contains("ENTITY_ID")
                    .and(predicate::str::contains("ENTITY"))
                    .and(predicate::str::contains("ent-t1"))
                    .and(predicate::str::contains("Oven"))
                    .and(predicate::str::contains("att-oven-pdf")),
            );
        assert_eq!(fs::read(tag_dir.join("oven.pdf")).unwrap(), b"oven manual");
        assert!(!tag_dir.join("notes.txt").exists());

        list_tags.assert();
        list_tagged.assert();
        get_t1.assert();
        dl_oven.assert();
    }

    // 3. --items-from <file> and --items-from - (stdin with blank lines, comments, duplicates)
    {
        let mut server = Server::new();
        let file_dir = tmp.path().join("from_file");
        let stdin_dir = tmp.path().join("from_stdin");
        let ids_file = tmp.path().join("ids.txt");
        fs::write(&ids_file, "# appliances\nent-f1\n\nent-f2\nent-f1\n").unwrap();

        let get_f1 = server
            .mock("GET", "/api/v1/entities/ent-f1")
            .with_status(200)
            .with_body(
                json!({
                    "id": "ent-f1",
                    "name": "Toaster",
                    "quantity": 1,
                    "attachments": [{"id": "att-f1", "title": "toaster.pdf", "mimeType": "application/pdf"}]
                })
                .to_string(),
            )
            .expect(2)
            .create();
        let get_f2 = server
            .mock("GET", "/api/v1/entities/ent-f2")
            .with_status(200)
            .with_body(
                json!({
                    "id": "ent-f2",
                    "name": "Blender",
                    "quantity": 1,
                    "attachments": [{"id": "att-f2", "title": "blender.pdf", "mimeType": "application/pdf"}]
                })
                .to_string(),
            )
            .expect(2)
            .create();
        let dl_f1 = server
            .mock("GET", "/api/v1/entities/ent-f1/attachments/att-f1")
            .with_status(200)
            .with_body(b"toaster bytes")
            .expect(2)
            .create();
        let dl_f2 = server
            .mock("GET", "/api/v1/entities/ent-f2/attachments/att-f2")
            .with_status(200)
            .with_body(b"blender bytes")
            .expect(2)
            .create();

        hbctl(&server.url())
            .args([
                "--json",
                "attachment",
                "download",
                "--items-from",
                ids_file.to_str().unwrap(),
                "--out",
                file_dir.to_str().unwrap(),
            ])
            .assert()
            .success();
        assert_eq!(
            fs::read(file_dir.join("toaster.pdf")).unwrap(),
            b"toaster bytes"
        );
        assert_eq!(
            fs::read(file_dir.join("blender.pdf")).unwrap(),
            b"blender bytes"
        );

        hbctl(&server.url())
            .args([
                "--json",
                "attachment",
                "download",
                "--items-from",
                "-",
                "--out",
                stdin_dir.to_str().unwrap(),
            ])
            .write_stdin("ent-f1\n# ignore\n\nent-f2\nent-f1\n")
            .assert()
            .success();
        assert_eq!(
            fs::read(stdin_dir.join("toaster.pdf")).unwrap(),
            b"toaster bytes"
        );
        assert_eq!(
            fs::read(stdin_dir.join("blender.pdf")).unwrap(),
            b"blender bytes"
        );

        get_f1.assert();
        get_f2.assert();
        dl_f1.assert();
        dl_f2.assert();
    }

    // 4. Missing selector fails clearly
    hbctl("http://127.0.0.1:1")
        .args(["attachment", "download"])
        .assert()
        .failure()
        .stderr(predicate::str::contains(
            "specify an <ITEM_ID> or one of --all-items, --tag, or --items-from",
        ));
}

#[test]
fn test_server_status_unauthenticated_and_entity_types_crud() {
    if !can_execute_binary() {
        return;
    }

    let mut server = Server::new();
    let empty_cfg = tempdir().unwrap();

    let status_mock = server
        .mock("GET", "/api/v1/status")
        .match_header("authorization", Matcher::Missing)
        .with_status(200)
        .with_body(
            r#"{"version":"v0.26.2","commit":"abc1234","buildTime":"2026-01-10T00:00:00Z","title":"Homebox","health":true}"#,
        )
        .expect(3)
        .create();

    let unauth_hbctl = || {
        let mut cmd = Command::new(env!("CARGO_BIN_EXE_hbctl"));
        for var in [
            "HBCTL_URL",
            "HBCTL_API_KEY",
            "HBCTL_OUTPUT",
            "HBCTL_CONFIG",
            "HOMEBOX_URL",
            "HOMEBOX_IP",
            "HOMEBOX_API_KEY",
        ] {
            cmd.env_remove(var);
        }
        cmd.env("HOME", empty_cfg.path())
            .env("XDG_CONFIG_HOME", empty_cfg.path())
            .env("HBCTL_INSECURE_STORAGE", "1")
            .args(["--url", &server.url()]);
        cmd
    };

    // 1. Unauthenticated `hbctl status --json`
    let status_json = unauth_hbctl()
        .args(["--json", "status"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let parsed_status: Value = serde_json::from_slice(&status_json).unwrap();
    assert_eq!(parsed_status["reachable"], true);
    assert_eq!(parsed_status["version"], "v0.26.2");
    assert_eq!(parsed_status["commit"], "abc1234");
    assert!(parsed_status["url"].as_str().unwrap().ends_with("/api/v1"));

    // 2. Unauthenticated `hbctl status` default table
    unauth_hbctl()
        .args(["status"])
        .assert()
        .success()
        .stdout(predicate::str::contains("v0.26.2").and(predicate::str::contains("yes")));

    // 3. Unauthenticated `-q status`
    unauth_hbctl()
        .args(["-q", "status"])
        .assert()
        .success()
        .stdout(predicate::eq("v0.26.2\n"));

    // 4. `--dry-run --json status`
    let status_dry = unauth_hbctl()
        .args(["--dry-run", "--json", "status"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let status_dry_val: Value = serde_json::from_slice(&status_dry).unwrap();
    assert_eq!(status_dry_val[0]["method"], "GET");
    assert!(status_dry_val[0]["url"]
        .as_str()
        .unwrap()
        .ends_with("/api/v1/status"));

    status_mock.assert();

    // 5. `entity-types create` dry-run & live
    let create_dry = hbctl("http://127.0.0.1:1")
        .args([
            "--dry-run",
            "--json",
            "entity-types",
            "create",
            "Storage Bin",
            "--description",
            "Container",
            "--is-location",
        ])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let create_dry_val: Value = serde_json::from_slice(&create_dry).unwrap();
    assert_eq!(create_dry_val[0]["method"], "POST");
    assert_eq!(
        create_dry_val[0]["url"],
        "http://127.0.0.1:1/api/v1/entity-types"
    );
    assert_eq!(create_dry_val[0]["body"]["isLocation"], true);

    let m_create = server
        .mock("POST", "/api/v1/entity-types")
        .match_body(Matcher::PartialJson(json!({
            "name": "Storage Bin",
            "description": "Container",
            "isLocation": true
        })))
        .with_status(201)
        .with_body(
            r#"{"id":"et-bin","name":"Storage Bin","description":"Container","isLocation":true}"#,
        )
        .expect(1)
        .create();
    let create_live = hbctl(&server.url())
        .args([
            "--json",
            "entity-types",
            "create",
            "Storage Bin",
            "--description",
            "Container",
            "--is-location",
        ])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let created: Value = serde_json::from_slice(&create_live).unwrap();
    assert_eq!(created["id"], "et-bin");
    assert_eq!(created["isLocation"], true);
    m_create.assert();

    // 6. `entity-types delete` dry-run & live (--json and -q)
    let delete_dry = hbctl("http://127.0.0.1:1")
        .args(["--dry-run", "--json", "entity-types", "delete", "et-bin"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let delete_dry_val: Value = serde_json::from_slice(&delete_dry).unwrap();
    assert_eq!(delete_dry_val[0]["method"], "DELETE");
    assert_eq!(
        delete_dry_val[0]["url"],
        "http://127.0.0.1:1/api/v1/entity-types/et-bin"
    );

    let m_delete = server
        .mock("DELETE", "/api/v1/entity-types/et-bin")
        .with_status(204)
        .expect(2)
        .create();
    let delete_json = hbctl(&server.url())
        .args(["--json", "entity-types", "delete", "et-bin", "--force"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let deleted: Value = serde_json::from_slice(&delete_json).unwrap();
    assert_eq!(deleted, json!({ "id": "et-bin", "deleted": true }));

    hbctl(&server.url())
        .args(["-q", "entity-types", "delete", "et-bin", "--force"])
        .assert()
        .success()
        .stdout(predicate::eq("et-bin\n"));

    m_delete.assert();
}

#[test]
fn test_multi_instance_profiles_auth_and_isolation() {
    if !can_execute_binary() {
        return;
    }

    let tmp = tempdir().unwrap();
    let cfg_home = tmp.path().join("xdg");
    let empty_cwd = tmp.path().join("cwd");
    fs::create_dir_all(&cfg_home).unwrap();
    fs::create_dir_all(&empty_cwd).unwrap();

    let mut s_homelab = Server::new();
    let mut s_staging = Server::new();

    let m_hl_self = s_homelab
        .mock("GET", "/api/v1/users/self")
        .match_header("authorization", "Bearer hb_homelab_1")
        .with_status(200)
        .with_body(r#"{"item":{"name":"Homelab User","email":"homelab@example.com"}}"#)
        .expect(3)
        .create();
    let m_hl_items = s_homelab
        .mock("GET", "/api/v1/entities")
        .match_header("authorization", "Bearer hb_homelab_1")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_body(r#"{"items":[{"id":"hl-1","name":"Homelab Drill","quantity":1,"tags":[]}],"page":1,"pageSize":50,"total":1}"#)
        .expect(1)
        .create();

    let m_st_self = s_staging
        .mock("GET", "/api/v1/users/self")
        .match_header("authorization", "Bearer hb_staging_1")
        .with_status(200)
        .with_body(r#"{"item":{"name":"Staging User","email":"staging@example.com"}}"#)
        .expect(2)
        .create();
    let m_st_items = s_staging
        .mock("GET", "/api/v1/entities")
        .match_header("authorization", "Bearer hb_staging_1")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_body(r#"{"items":[{"id":"st-1","name":"Staging Sensor","quantity":2,"tags":[]}],"page":1,"pageSize":50,"total":1}"#)
        .expect(1)
        .create();
    let m_st_refresh = s_staging
        .mock("GET", "/api/v1/users/refresh")
        .match_header("authorization", "Bearer hb_staging_1")
        .with_status(200)
        .with_body(r#"{"token":"jwt_staging_refreshed","expiresAt":"2028-01-01T00:00:00Z"}"#)
        .expect(1)
        .create();

    let run_profiled = |extra_env: Option<(&str, &str)>| {
        let mut cmd = Command::new(env!("CARGO_BIN_EXE_hbctl"));
        cmd.current_dir(&empty_cwd);
        for var in [
            "HBCTL_URL",
            "HBCTL_API_KEY",
            "HBCTL_OUTPUT",
            "HBCTL_CONFIG",
            "HBCTL_PROFILE",
            "HOMEBOX_URL",
            "HOMEBOX_IP",
            "HOMEBOX_API_KEY",
        ] {
            cmd.env_remove(var);
        }
        cmd.env("HOME", tmp.path())
            .env("XDG_CONFIG_HOME", &cfg_home)
            .env("HBCTL_INSECURE_STORAGE", "1");
        if let Some((k, v)) = extra_env {
            cmd.env(k, v);
        }
        cmd
    };

    // 1. Login both profiles cleanly into isolated config sections and credentials entries
    run_profiled(None)
        .args([
            "--profile",
            "homelab",
            "--json",
            "auth",
            "login",
            "--url",
            &s_homelab.url(),
            "--with-token",
            "--insecure-storage",
        ])
        .write_stdin("hb_homelab_1\n")
        .assert()
        .success()
        .stdout(predicate::str::contains(r#""profile":"homelab""#));

    run_profiled(None)
        .args([
            "-P",
            "staging",
            "--json",
            "auth",
            "login",
            "--url",
            &s_staging.url(),
            "--with-token",
            "--insecure-storage",
        ])
        .write_stdin("hb_staging_1\n")
        .assert()
        .success()
        .stdout(predicate::str::contains(r#""profile":"staging""#));

    let cfg_path = cfg_home.join("hbctl").join("config.toml");
    let creds_path = cfg_home.join("hbctl").join("credentials.json");
    let cfg_text = fs::read_to_string(&cfg_path).unwrap();
    assert!(cfg_text.contains("[profiles.homelab]"));
    assert!(cfg_text.contains("[profiles.staging]"));
    assert!(!cfg_text.contains("hb_homelab_1"));
    assert!(!cfg_text.contains("hb_staging_1"));

    let creds_text = fs::read_to_string(&creds_path).unwrap();
    assert!(creds_text.contains("profile:homelab:"));
    assert!(creds_text.contains("profile:staging:"));

    // 2. HBCTL_PROFILE targets staging, --profile homelab overrides HBCTL_PROFILE
    let st_status = run_profiled(Some(("HBCTL_PROFILE", "staging")))
        .args(["--json", "auth", "status"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let st_val: Value = serde_json::from_slice(&st_status).unwrap();
    assert_eq!(st_val["profile"], "staging");
    assert_eq!(st_val["email"], "staging@example.com");

    let hl_status = run_profiled(Some(("HBCTL_PROFILE", "staging")))
        .args(["--profile", "homelab", "--json", "auth", "status"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let hl_val: Value = serde_json::from_slice(&hl_status).unwrap();
    assert_eq!(hl_val["profile"], "homelab");
    assert_eq!(hl_val["email"], "homelab@example.com");

    // 3. Set default_profile = "homelab" and verify fallback + override
    fs::write(
        &cfg_path,
        format!("default_profile = \"homelab\"\n{cfg_text}"),
    )
    .unwrap();

    let hl_list = run_profiled(None)
        .args(["--json", "item", "list"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let hl_items: Vec<Value> = serde_json::from_slice(&hl_list).unwrap();
    assert_eq!(hl_items[0]["id"], "hl-1");

    let st_list = run_profiled(None)
        .args(["--profile", "staging", "--json", "item", "list"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let st_items: Vec<Value> = serde_json::from_slice(&st_list).unwrap();
    assert_eq!(st_items[0]["id"], "st-1");

    // 4. Refresh & logout on staging leave homelab completely intact
    let st_refreshed = run_profiled(None)
        .args([
            "--profile",
            "staging",
            "--json",
            "auth",
            "refresh",
            "--insecure-storage",
        ])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let st_ref_val: Value = serde_json::from_slice(&st_refreshed).unwrap();
    assert_eq!(st_ref_val["profile"], "staging");
    assert_eq!(st_ref_val["token_type"], "jwt");

    let st_logout = run_profiled(None)
        .args([
            "--profile",
            "staging",
            "--json",
            "auth",
            "logout",
            "--insecure-storage",
        ])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let logout_val: Value = serde_json::from_slice(&st_logout).unwrap();
    assert_eq!(logout_val["profile"], "staging");
    assert_eq!(logout_val["logged_out"], true);
    assert_eq!(logout_val["removed_secret"], true);

    // Homelab still authenticated; staging now missing API key
    run_profiled(None)
        .args(["--profile", "homelab", "--json", "auth", "status"])
        .assert()
        .success();
    run_profiled(None)
        .args(["--profile", "staging", "auth", "status"])
        .assert()
        .failure();

    // 5. Backwards compatibility with legacy single-instance config and unprefixed credentials
    let legacy_cfg_home = tmp.path().join("legacy_xdg");
    let legacy_dir = legacy_cfg_home.join("hbctl");
    fs::create_dir_all(&legacy_dir).unwrap();
    let mut legacy_server = Server::new();
    let m_legacy = legacy_server
        .mock("GET", "/api/v1/users/self")
        .match_header("authorization", "Bearer hb_legacy_999")
        .with_status(200)
        .with_body(r#"{"item":{"name":"Legacy","email":"legacy@example.com"}}"#)
        .expect(2)
        .create();
    fs::write(
        legacy_dir.join("config.toml"),
        format!("url = \"{}/api/v1\"\n", legacy_server.url()),
    )
    .unwrap();
    fs::write(
        legacy_dir.join("credentials.json"),
        json!({ format!("{}/api/v1", legacy_server.url()): "hb_legacy_999" }).to_string(),
    )
    .unwrap();

    for args in [
        vec!["--json", "auth", "status"],
        vec!["--profile", "default", "--json", "auth", "status"],
    ] {
        let mut cmd = Command::new(env!("CARGO_BIN_EXE_hbctl"));
        cmd.current_dir(&empty_cwd);
        for var in [
            "HBCTL_URL",
            "HBCTL_API_KEY",
            "HBCTL_OUTPUT",
            "HBCTL_CONFIG",
            "HBCTL_PROFILE",
            "HOMEBOX_URL",
            "HOMEBOX_IP",
            "HOMEBOX_API_KEY",
        ] {
            cmd.env_remove(var);
        }
        cmd.env("HOME", tmp.path())
            .env("XDG_CONFIG_HOME", &legacy_cfg_home)
            .env("HBCTL_INSECURE_STORAGE", "1")
            .args(args)
            .assert()
            .success()
            .stdout(predicate::str::contains("legacy@example.com"));
    }

    m_hl_self.assert();
    m_hl_items.assert();
    m_st_self.assert();
    m_st_items.assert();
    m_st_refresh.assert();
    m_legacy.assert();
}
