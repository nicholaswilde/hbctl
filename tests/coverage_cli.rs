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

fn hbctl_bare(xdg_dir: &std::path::Path) -> Command {
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
    cmd.env("XDG_CONFIG_HOME", xdg_dir)
        .env("HBCTL_INSECURE_STORAGE", "1");
    cmd
}

fn hbctl(server_url: &str) -> Command {
    let xdg = std::env::temp_dir().join("hbctl-cov-empty-xdg");
    let mut cmd = hbctl_bare(&xdg);
    cmd.arg("--url")
        .arg(server_url)
        .arg("--api-key")
        .arg("hb_test_secret_token_999");
    cmd
}

#[test]
fn test_item_coverage_edge_paths() {
    if !can_execute_binary() {
        return;
    }
    let dir = tempdir().unwrap();
    let mut server = Server::new();

    // 1. item create --from-json - missing name -> error
    hbctl(&server.url())
        .args(["item", "create", "--from-json", "-"])
        .write_stdin(r#"{"description":"no name"}"#)
        .assert()
        .failure()
        .stderr(predicate::str::contains("item name is required"));

    // 2. item create --from-json <file> with tagIds and attachments array (object + string)
    let f1 = dir.path().join("doc1.txt");
    let f2 = dir.path().join("doc2.txt");
    fs::write(&f1, b"doc1").unwrap();
    fs::write(&f2, b"doc2").unwrap();
    let json_arr_path = dir.path().join("create_arr.json");
    fs::write(
        &json_arr_path,
        json!({
            "name": "JsonArrayItem",
            "tagIds": ["tag-elec", "  "],
            "attachments": [
                {"path": f1.to_str().unwrap(), "name": "renamed.txt"},
                f2.to_str().unwrap()
            ]
        })
        .to_string(),
    )
    .unwrap();

    let m_tags = server
        .mock("GET", "/api/v1/tags")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(fixture("tags.json"))
        .expect_at_least(1)
        .create();
    let m_create_arr = server
        .mock("POST", "/api/v1/entities")
        .with_status(201)
        .with_header("content-type", "application/json")
        .with_body(r#"{"id":"ent-j1","name":"JsonArrayItem","quantity":1,"fields":[]}"#)
        .expect(1)
        .create();
    let m_up_1 = server
        .mock("POST", "/api/v1/entities/ent-j1/attachments")
        .match_body(Matcher::Regex("renamed.txt".to_string()))
        .with_status(201)
        .with_header("content-type", "application/json")
        .with_body(r#"{"id":"att-j1","title":"renamed.txt"}"#)
        .expect(1)
        .create();
    let m_up_2 = server
        .mock("POST", "/api/v1/entities/ent-j1/attachments")
        .match_body(Matcher::Regex("doc2.txt".to_string()))
        .with_status(201)
        .with_header("content-type", "application/json")
        .with_body(r#"{"id":"att-j2","title":"doc2.txt"}"#)
        .expect(1)
        .create();

    hbctl(&server.url())
        .args([
            "--json",
            "item",
            "create",
            "--from-json",
            json_arr_path.to_str().unwrap(),
        ])
        .assert()
        .success();
    m_create_arr.assert();
    m_up_1.assert();
    m_up_2.assert();

    // 3. item create --from-json <file> with string "attachments" & dry-run
    let json_str_path = dir.path().join("create_str.json");
    fs::write(
        &json_str_path,
        json!({
            "name": "JsonStringAttachment",
            "attachments": f1.to_str().unwrap()
        })
        .to_string(),
    )
    .unwrap();
    hbctl(&server.url())
        .args([
            "--dry-run",
            "--json",
            "item",
            "create",
            "--from-json",
            json_str_path.to_str().unwrap(),
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("attachments"));

    // 4. item upsert --dry-run with --match-by and --parent none
    hbctl(&server.url())
        .args([
            "--dry-run",
            "--json",
            "item",
            "upsert",
            "--name",
            "Sensor",
            "--match-by",
            "name,serial",
            "--parent",
            "none",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"matchBy\""))
        .stdout(predicate::str::contains("\"parentId\":null"));

    // 5. item upsert --from-json missing name -> error
    let empty_list = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(r#"{"items":[],"page":1,"pageSize":50,"total":0}"#)
        .expect_at_least(1)
        .create();
    let no_name_json = dir.path().join("no_name.json");
    fs::write(&no_name_json, r#"{"serialNumber":"SN-NO-NAME"}"#).unwrap();
    hbctl(&server.url())
        .args([
            "item",
            "upsert",
            "--match-by",
            "serial",
            "--from-json",
            no_name_json.to_str().unwrap(),
        ])
        .assert()
        .failure()
        .stderr(predicate::str::contains(
            "item name is required to create a new item",
        ));

    // 6. item delete --force in --json and default table mode
    let m_del = server
        .mock("DELETE", "/api/v1/entities/ent-del-1")
        .with_status(204)
        .expect(2)
        .create();
    hbctl(&server.url())
        .args(["--json", "item", "delete", "ent-del-1", "--force"])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"deleted\":true"));
    hbctl(&server.url())
        .args(["item", "delete", "ent-del-1", "--force"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Deleted item ent-del-1"));
    m_del.assert();

    // 7. item move --dry-run and self-parent error
    hbctl(&server.url())
        .args(["--dry-run", "--json", "item", "move", "ent-1", "none"])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"parentId\":null"));
    hbctl(&server.url())
        .args(["--dry-run", "item", "move", "ent-1", "parent-2"])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"parentId\":\"parent-2\""));
    let self_uuid = "11111111-1111-1111-1111-111111111111";
    hbctl(&server.url())
        .args(["item", "move", self_uuid, self_uuid])
        .assert()
        .failure()
        .stderr(predicate::str::contains(format!(
            "cannot move item '{self_uuid}' under itself"
        )));

    // 8. resolver: unknown entity type, UUID passthrough entity type, unknown parent, UUID parent
    let m_ets = server
        .mock("GET", "/api/v1/entity-types")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(fixture("entity_types.json"))
        .expect_at_least(1)
        .create();
    hbctl(&server.url())
        .args([
            "item",
            "create",
            "--name",
            "BadType",
            "--type",
            "NoSuchType",
        ])
        .assert()
        .failure()
        .stderr(predicate::str::contains("entity type"));

    let uuid_et = "11111111-2222-3333-4444-555555555555";
    let m_create_uuid_et = server
        .mock("POST", "/api/v1/entities")
        .match_body(Matcher::Regex(uuid_et.to_string()))
        .with_status(201)
        .with_header("content-type", "application/json")
        .with_body(r#"{"id":"ent-u1","name":"UuidEt","quantity":1,"fields":[]}"#)
        .expect(1)
        .create();
    hbctl(&server.url())
        .args(["item", "create", "--name", "UuidEt", "--type", uuid_et])
        .assert()
        .success();
    m_create_uuid_et.assert();

    hbctl(&server.url())
        .args(["item", "move", "ent-1", "NoSuchParentItem"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("parent item"));

    let uuid_parent = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee";
    let m_get_e1 = server
        .mock("GET", "/api/v1/entities/ent-1")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(r#"{"id":"ent-1","name":"E1","quantity":1,"fields":[]}"#)
        .expect(1)
        .create();
    let m_put_e1 = server
        .mock("PUT", "/api/v1/entities/ent-1")
        .match_body(Matcher::Regex(uuid_parent.to_string()))
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(r#"{"id":"ent-1","name":"E1","quantity":1,"parentId":"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee","fields":[]}"#)
        .expect(1)
        .create();
    hbctl(&server.url())
        .args(["item", "move", "ent-1", uuid_parent])
        .assert()
        .success();
    m_get_e1.assert();
    m_put_e1.assert();

    // 9. item tree in --quiet and --output plain modes
    let m_tree_list = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(
            json!({
                "items": [
                    {"id": "loc-1", "name": "Garage", "quantity": 1},
                    {"id": "bin-1", "name": "Shelf A", "quantity": 1, "parentId": "loc-1"}
                ],
                "page": 1,
                "pageSize": 50,
                "total": 2
            })
            .to_string(),
        )
        .expect(2)
        .create();
    hbctl(&server.url())
        .args(["--quiet", "item", "tree"])
        .assert()
        .success()
        .stdout(predicate::str::contains("loc-1\nbin-1\n"));
    hbctl(&server.url())
        .args(["--output", "plain", "item", "tree"])
        .assert()
        .success()
        .stdout(predicate::str::contains("loc-1\t\t0\tGarage\t1\n"))
        .stdout(predicate::str::contains("bin-1\tloc-1\t1\tShelf A\t1\n"));
    m_tree_list.assert();

    // 10. item import: JSON wrapper object, single JSON object, CSV with purchase/attachments, dry-run --parent none, table output, --update-existing with attachments
    let import_wrap = dir.path().join("wrap.json");
    fs::write(
        &import_wrap,
        json!({
            "items": [
                {"name": "WrappedItem", "quantity": 2}
            ]
        })
        .to_string(),
    )
    .unwrap();
    let import_single = dir.path().join("single.json");
    fs::write(
        &import_single,
        json!({"name": "SingleItem", "quantity": 1}).to_string(),
    )
    .unwrap();
    let import_csv = dir.path().join("items.csv");
    fs::write(
        &import_csv,
        format!(
            "name,purchasePrice,purchaseDate,purchaseFrom,attachments\nBolt,4.50,2026-01-05,McMaster,{}\n",
            f1.display()
        ),
    )
    .unwrap();
    let bad_csv = dir.path().join("bad.csv");
    fs::write(&bad_csv, "name,purchasePrice\nBolt,not-a-float\n").unwrap();

    hbctl(&server.url())
        .args(["item", "import", bad_csv.to_str().unwrap()])
        .assert()
        .failure()
        .stderr(predicate::str::contains("invalid CSV purchasePrice"));

    hbctl(&server.url())
        .args([
            "--dry-run",
            "--json",
            "item",
            "import",
            import_single.to_str().unwrap(),
            "--parent",
            "none",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"parentId\":null"));

    let m_imp_create = server
        .mock("POST", "/api/v1/entities")
        .with_status(201)
        .with_header("content-type", "application/json")
        .with_body(r#"{"id":"ent-imp-1","name":"WrappedItem","quantity":2,"fields":[]}"#)
        .expect(1)
        .create();
    hbctl(&server.url())
        .args(["item", "import", import_wrap.to_str().unwrap()])
        .assert()
        .success()
        .stdout(predicate::str::contains("CREATED"))
        .stdout(predicate::str::contains("1"));
    m_imp_create.assert();

    // --update-existing with CSV attachment upload
    let m_imp_list = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(
            json!({
                "items": [{"id": "ent-bolt", "name": "Bolt", "quantity": 1}],
                "page": 1,
                "pageSize": 50,
                "total": 1
            })
            .to_string(),
        )
        .expect(1)
        .create();
    let m_imp_get = server
        .mock("GET", "/api/v1/entities/ent-bolt")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(r#"{"id":"ent-bolt","name":"Bolt","quantity":1,"fields":[],"attachments":[]}"#)
        .expect(1)
        .create();
    let m_imp_put = server
        .mock("PUT", "/api/v1/entities/ent-bolt")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(r#"{"id":"ent-bolt","name":"Bolt","quantity":1,"fields":[],"attachments":[]}"#)
        .expect(1)
        .create();
    let m_imp_att = server
        .mock("POST", "/api/v1/entities/ent-bolt/attachments")
        .with_status(201)
        .with_header("content-type", "application/json")
        .with_body(r#"{"id":"att-bolt","title":"doc1.txt"}"#)
        .expect(1)
        .create();

    hbctl(&server.url())
        .args([
            "--json",
            "item",
            "import",
            import_csv.to_str().unwrap(),
            "--update-existing",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"updated\":1"));
    m_imp_list.assert();
    m_imp_get.assert();
    m_imp_put.assert();
    m_imp_att.assert();

    let _ = (m_tags, empty_list, m_ets);
}

#[test]
fn test_attachment_coverage_edge_paths() {
    if !can_execute_binary() {
        return;
    }
    let dir = tempdir().unwrap();
    let mut server = Server::new();

    let f1 = dir.path().join("manual.pdf");
    let f2 = dir.path().join("extra.pdf");
    fs::write(&f1, b"%PDF-1.4").unwrap();
    fs::write(&f2, b"%PDF-1.4-2").unwrap();

    // 1. --name with multiple sources -> error
    hbctl(&server.url())
        .args([
            "attachment",
            "upload",
            "ent-1",
            f1.to_str().unwrap(),
            f2.to_str().unwrap(),
            "--name",
            "only-one.pdf",
        ])
        .assert()
        .failure()
        .stderr(predicate::str::contains("--name can only be used"));

    // 2. Stdin upload skip when attachment already exists
    let m_get_existing = server
        .mock("GET", "/api/v1/entities/ent-1")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(
            json!({
                "id": "ent-1",
                "name": "Item",
                "quantity": 1,
                "attachments": [
                    {"id": "att-old", "title": "manual.pdf", "name": "manual.pdf"}
                ]
            })
            .to_string(),
        )
        .expect_at_least(1)
        .create();

    hbctl(&server.url())
        .args([
            "--json",
            "attachment",
            "upload",
            "ent-1",
            "-",
            "--name",
            "manual.pdf",
        ])
        .write_stdin("stdin-pdf-bytes")
        .assert()
        .success()
        .stderr(predicate::str::contains("skipping existing attachment"))
        .stdout(predicate::str::contains("\"status\":\"skipped\""));

    // 3. --attach-url with explicit name matching existing -> skipped before fetch
    hbctl(&server.url())
        .args([
            "--json",
            "attachment",
            "upload",
            "ent-1",
            "--attach-url",
            &format!("{}/remote/any.pdf=manual.pdf", server.url()),
        ])
        .assert()
        .success()
        .stderr(predicate::str::contains("skipping existing attachment"))
        .stdout(predicate::str::contains("\"status\":\"skipped\""));

    // 4. --attach-url without explicit name -> server returns filename matching existing -> skipped after fetch
    let m_remote_same = server
        .mock("GET", "/remote/manual.pdf")
        .with_status(200)
        .with_header("content-type", "application/pdf")
        .with_body(b"%PDF-remote")
        .expect(2)
        .create();
    hbctl(&server.url())
        .args([
            "--json",
            "attachment",
            "upload",
            "ent-1",
            "--attach-url",
            &format!("{}/remote/manual.pdf", server.url()),
        ])
        .assert()
        .success()
        .stderr(predicate::str::contains("skipping existing attachment"))
        .stdout(predicate::str::contains("\"status\":\"skipped\""));

    // 5. attach_single_target via `item upsert --on-match attach-only` hitting duplicate local, explicit URL, derived URL
    let m_list_e1 = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(
            json!({
                "items": [{"id": "ent-1", "name": "Item", "quantity": 1}],
                "page": 1,
                "pageSize": 50,
                "total": 1
            })
            .to_string(),
        )
        .expect(1)
        .create();
    hbctl(&server.url())
        .args([
            "--json",
            "item",
            "upsert",
            "--name",
            "Item",
            "--on-match",
            "attach-only",
            "--attach",
            f1.to_str().unwrap(),
            "--attach-url",
            &format!("{}/remote/other.pdf=manual.pdf", server.url()),
            "--attach-url",
            &format!("{}/remote/manual.pdf", server.url()),
        ])
        .assert()
        .success()
        .stderr(predicate::str::contains("skipping existing attachment"));
    m_list_e1.assert();
    m_remote_same.assert();
    let _ = m_get_existing;

    // 6. Overwrite + Entity-wrapped upload response + upload/download HTTP errors
    let m_get_ov = server
        .mock("GET", "/api/v1/entities/ent-ov")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(
            json!({
                "id": "ent-ov",
                "name": "ItemOv",
                "quantity": 1,
                "attachments": [{"id": "att-1", "title": "manual.pdf"}]
            })
            .to_string(),
        )
        .expect(1)
        .create();
    let m_del_ov = server
        .mock("DELETE", "/api/v1/entities/ent-ov/attachments/att-1")
        .with_status(204)
        .expect(1)
        .create();
    // Return full Entity JSON wrapping the uploaded attachment to exercise upload_attachment_bytes Entity fallback
    let m_post_ov = server
        .mock("POST", "/api/v1/entities/ent-ov/attachments")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(
            json!({
                "id": "ent-ov",
                "name": "ItemOv",
                "quantity": 1,
                "attachments": [{"id": "att-new-wrap", "title": "manual.pdf"}]
            })
            .to_string(),
        )
        .expect(1)
        .create();
    hbctl(&server.url())
        .args([
            "--json",
            "attachment",
            "upload",
            "ent-ov",
            f1.to_str().unwrap(),
            "--overwrite",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("att-new-wrap"));
    m_get_ov.assert();
    m_del_ov.assert();
    m_post_ov.assert();

    // Upload HTTP error redacts secret
    let m_get_err = server
        .mock("GET", "/api/v1/entities/ent-up-err")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(r#"{"id":"ent-up-err","name":"Err","quantity":1,"attachments":[]}"#)
        .expect(1)
        .create();
    let m_post_err = server
        .mock("POST", "/api/v1/entities/ent-up-err/attachments")
        .with_status(400)
        .with_body("bad upload hb_test_secret_token_999")
        .expect(1)
        .create();
    hbctl(&server.url())
        .args(["attachment", "upload", "ent-up-err", f1.to_str().unwrap()])
        .assert()
        .failure()
        .stderr(predicate::str::contains("***"));
    m_get_err.assert();
    m_post_err.assert();

    // 7. attachment download --items-from missing file -> error
    let missing_ids = dir.path().join("missing_ids.txt");
    hbctl(&server.url())
        .args([
            "attachment",
            "download",
            "--items-from",
            missing_ids.to_str().unwrap(),
        ])
        .assert()
        .failure()
        .stderr(predicate::str::contains("cannot read item IDs file"));

    // 8. attachment download --all --mime image/png where mimeType omitted (uses mime_guess)
    let dl_dir = dir.path().join("dl");
    let m_get_dl = server
        .mock("GET", "/api/v1/entities/ent-dl")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(
            json!({
                "id": "ent-dl",
                "name": "Board",
                "quantity": 1,
                "attachments": [
                    {"id": "att-p", "title": "pinout.png"},
                    {"id": "att-t", "title": "notes.txt"},
                    {"id": "att-404", "title": "missing.bin"}
                ]
            })
            .to_string(),
        )
        .expect(1)
        .create();
    let m_dl_png = server
        .mock("GET", "/api/v1/entities/ent-dl/attachments/att-p")
        .with_status(200)
        .with_body(b"png-bytes")
        .expect(1)
        .create();
    hbctl(&server.url())
        .args([
            "--json",
            "attachment",
            "download",
            "ent-dl",
            "--all",
            "--mime",
            "image/png",
            "--out",
            dl_dir.to_str().unwrap(),
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("att-p"));
    m_get_dl.assert();
    m_dl_png.assert();

    // 9. download_attachment HTTP 404 error
    let m_dl_404 = server
        .mock("GET", "/api/v1/entities/ent-dl/attachments/att-404")
        .with_status(404)
        .with_body("missing hb_test_secret_token_999")
        .expect(1)
        .create();
    hbctl(&server.url())
        .args([
            "attachment",
            "download",
            "ent-dl",
            "att-404",
            "--out",
            dir.path().join("nope.bin").to_str().unwrap(),
        ])
        .assert()
        .failure()
        .stderr(predicate::str::contains("404"));
    m_dl_404.assert();

    // 10. attachment delete in --json and default table mode
    let m_att_del = server
        .mock("DELETE", "/api/v1/entities/ent-1/attachments/att-9")
        .with_status(204)
        .expect(2)
        .create();
    hbctl(&server.url())
        .args(["--json", "attachment", "delete", "ent-1", "att-9"])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"deleted\":true"));
    hbctl(&server.url())
        .args(["attachment", "delete", "ent-1", "att-9"])
        .assert()
        .success()
        .stdout(predicate::str::contains(
            "Deleted attachment att-9 from item ent-1",
        ));
    m_att_del.assert();
}

#[test]
fn test_export_coverage_all_builtin_columns_and_json_columns() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();

    let m_list = server
        .mock("GET", "/api/v1/entities")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(
            json!({
                "items": [
                    {
                        "id": "ent-b",
                        "name": "Beta Scope",
                        "description": "Bench scope",
                        "quantity": 1,
                        "assetId": "AST-100",
                        "entityTypeId": "et-item",
                        "entityType": {"id": "et-item", "name": "Instrument", "isLocation": false},
                        "parentId": "loc-1",
                        "purchasePrice": 299.5,
                        "purchaseDate": "2025-05-01",
                        "purchaseFrom": "Teledyne",
                        "createdAt": "2025-05-02T00:00:00Z",
                        "updatedAt": "2025-05-03T00:00:00Z",
                        "tags": [],
                        "attachments": [{"id": "a1", "title": "manual.pdf"}],
                        "fields": []
                    },
                    {
                        "id": "ent-a",
                        "name": "Alpha Probe",
                        "description": "",
                        "quantity": 2,
                        "entityTypeId": "et-only-id",
                        "tags": [{"id": "t1", "name": "lab"}],
                        "attachments": [],
                        "fields": []
                    }
                ],
                "page": 1,
                "pageSize": 50,
                "total": 2
            })
            .to_string(),
        )
        .expect(3)
        .create();

    // 1. JSON export with --columns covering every built-in column + --empty fallback
    let out = hbctl(&server.url())
        .args([
            "export",
            "--format",
            "json",
            "--columns",
            "id,name,description,quantity,tags,asset_id,entity_type_id,entity_type,parent_id,purchase_price,purchase_date,purchase_from,created_at,updated_at,attachments",
            "--empty",
            "N/A",
        ])
        .output()
        .unwrap();
    assert!(out.status.success());
    let records: Vec<Value> = serde_json::from_slice(&out.stdout).unwrap();
    assert_eq!(records.len(), 2);
    // Sorted by name: Alpha Probe first, Beta Scope second
    assert_eq!(records[0]["id"], "ent-a");
    assert_eq!(records[0]["description"], "N/A");
    assert_eq!(records[0]["entity_type"], "et-only-id");
    assert_eq!(records[1]["id"], "ent-b");
    assert_eq!(records[1]["asset_id"], "AST-100");
    assert_eq!(records[1]["entity_type"], "Instrument");
    assert_eq!(records[1]["purchase_price"], "299.50");
    assert_eq!(records[1]["tags"], "N/A");
    assert_eq!(records[1]["attachments"], "1");

    // 2. --quiet --sort id
    hbctl(&server.url())
        .args(["--quiet", "export", "--sort", "id"])
        .assert()
        .success()
        .stdout("ent-a\nent-b\n");

    // 3. CSV with --select (covers select fallback in resolve_export_columns)
    hbctl(&server.url())
        .args(["--select", "id,name", "export", "--format", "csv"])
        .assert()
        .success()
        .stdout(predicate::str::contains("id,name\nent-a,Alpha Probe"));

    m_list.assert();

    // 4. Invalid --columns specs
    hbctl(&server.url())
        .args(["export", "--columns", "=Alias"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("invalid --columns spec"));
    hbctl(&server.url())
        .args(["export", "--columns", "   "])
        .assert()
        .failure()
        .stderr(predicate::str::contains("column key cannot be empty"));
}

#[test]
fn test_maintenance_coverage_formats_and_errors() {
    if !can_execute_binary() {
        return;
    }
    let mut server = Server::new();

    // 1. dry-run entity maintenance list with scheduled and both
    hbctl(&server.url())
        .args([
            "--dry-run",
            "maintenance",
            "list",
            "ent-1",
            "--status",
            "scheduled",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains(
            "entities/ent-1/maintenance?status=scheduled",
        ));
    hbctl(&server.url())
        .args([
            "--dry-run",
            "maintenance",
            "list",
            "ent-1",
            "--status",
            "both",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("entities/ent-1/maintenance\n"));

    // 2. list table mode + --select across completed, scheduled, and undated entries
    let m_list = server
        .mock("GET", "/api/v1/maintenance")
        .match_query(Matcher::Any)
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(
            json!([
                {
                    "id": "m-1",
                    "name": "Filter",
                    "completedDate": "2026-01-01",
                    "cost": "10.00",
                    "itemName": "HVAC"
                },
                {
                    "id": "m-2",
                    "name": "Inspect",
                    "scheduledDate": "2027-01-01",
                    "cost": "",
                    "itemID": "ent-2"
                },
                {
                    "id": "m-3",
                    "name": "NoteOnly"
                }
            ])
            .to_string(),
        )
        .expect(2)
        .create();
    hbctl(&server.url())
        .args(["maintenance", "list"])
        .assert()
        .success()
        .stdout(predicate::str::contains("completed"))
        .stdout(predicate::str::contains("scheduled"))
        .stdout(predicate::str::contains("NoteOnly"));
    hbctl(&server.url())
        .args(["--select", "id,name", "maintenance", "list"])
        .assert()
        .success()
        .stdout(predicate::str::contains("m-1"));
    m_list.assert();

    // 3. create in default table mode + --select table mode (all optional entry fields populated)
    let m_create = server
        .mock("POST", "/api/v1/entities/ent-1/maintenance")
        .with_status(201)
        .with_header("content-type", "application/json")
        .with_body(
            json!({
                "id": "m-new",
                "name": "Oil",
                "itemName": "Compressor",
                "itemID": "ent-1",
                "completedDate": "2026-01-01",
                "scheduledDate": "2026-07-01",
                "cost": "25.50",
                "description": "Synthetic"
            })
            .to_string(),
        )
        .expect(2)
        .create();
    hbctl(&server.url())
        .args([
            "maintenance",
            "create",
            "ent-1",
            "--name",
            "Oil",
            "--completed-date",
            "2026-01",
            "--scheduled-date",
            "2026-07-01",
            "--cost",
            "$25.50",
            "--description",
            "Synthetic",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("completedDate"))
        .stdout(predicate::str::contains("scheduledDate"))
        .stdout(predicate::str::contains("Synthetic"));
    hbctl(&server.url())
        .args([
            "--select",
            "id,name",
            "maintenance",
            "create",
            "ent-1",
            "--name",
            "Oil",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("m-new"));
    m_create.assert();

    // 4. delete in --quiet and default text modes
    let m_del = server
        .mock("DELETE", "/api/v1/maintenance/m-new")
        .with_status(204)
        .expect(2)
        .create();
    hbctl(&server.url())
        .args(["--quiet", "maintenance", "delete", "m-new", "--force"])
        .assert()
        .success()
        .stdout("m-new\n");
    hbctl(&server.url())
        .args(["maintenance", "delete", "m-new", "--force"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Deleted maintenance entry m-new"));
    m_del.assert();

    // 5. validation errors + HTTP 500 on list
    for args in [
        vec!["maintenance", "create", "ent-1", "--name", "   "],
        vec!["maintenance", "update", "m-1", "--name", "   "],
        vec![
            "maintenance",
            "create",
            "ent-1",
            "--name",
            "Ok",
            "--completed-date",
            "bad-date",
        ],
        vec![
            "maintenance",
            "create",
            "ent-1",
            "--name",
            "Ok",
            "--completed-date",
            "2026-13-01",
        ],
        vec![
            "maintenance",
            "create",
            "ent-1",
            "--name",
            "Ok",
            "--cost",
            "abc",
        ],
        vec![
            "maintenance",
            "create",
            "ent-1",
            "--name",
            "Ok",
            "--cost",
            "-5",
        ],
        vec![
            "maintenance",
            "create",
            "ent-1",
            "--name",
            "Ok",
            "--cost",
            " ",
        ],
    ] {
        hbctl(&server.url()).args(args).assert().failure();
    }

    let m_err = server
        .mock("GET", "/api/v1/maintenance")
        .match_query(Matcher::Any)
        .with_status(500)
        .with_body("server error hb_test_secret_token_999")
        .expect(1)
        .create();
    hbctl(&server.url())
        .args(["maintenance", "list"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("***"));
    m_err.assert();
}

#[test]
fn test_auth_coverage_table_logout_and_errors() {
    if !can_execute_binary() {
        return;
    }
    let dir = tempdir().unwrap();
    let mut server = Server::new();

    // Write config + credentials in isolated XDG_CONFIG_HOME
    let hbctl_dir = dir.path().join("hbctl");
    fs::create_dir_all(&hbctl_dir).unwrap();
    let base_api = format!("{}/api/v1", server.url());
    fs::write(
        hbctl_dir.join("config.toml"),
        format!(
            "default_profile = \"staging\"\n\n[profiles.staging]\nurl = \"{}\"\ntoken_type = \"jwt\"\nexpires_at = \"2027-01-01T00:00:00Z\"\ncredential_backend = \"file\"\n",
            server.url()
        ),
    )
    .unwrap();
    fs::write(
        hbctl_dir.join("credentials.json"),
        json!({
            format!("profile:staging:{base_api}"): "eyJ_test_jwt_token"
        })
        .to_string(),
    )
    .unwrap();

    // 1. auth status in table mode with profile + user + email + expires_at
    let m_user = server
        .mock("GET", "/api/v1/users/self")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(r#"{"name":"Alice","email":"alice@example.com"}"#)
        .expect(1)
        .create();
    hbctl_bare(dir.path())
        .args(["auth", "status"])
        .assert()
        .success()
        .stdout(predicate::str::contains("staging"))
        .stdout(predicate::str::contains("alice@example.com"))
        .stdout(predicate::str::contains("2027-01-01T00:00:00Z"));
    m_user.assert();

    // 2. auth logout in default text mode with profile, then without profile
    hbctl_bare(dir.path())
        .args(["auth", "logout"])
        .assert()
        .success()
        .stdout(predicate::str::contains("(profile: staging)"));
    hbctl(&server.url())
        .args(["auth", "logout"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Logged out of"));

    // 3. auth login non-interactive error paths & HTTP 401 redaction
    let empty_xdg = dir.path().join("empty_xdg");
    hbctl_bare(&empty_xdg)
        .args(["auth", "login", "--with-token"])
        .write_stdin("hb_tok")
        .assert()
        .failure();
    hbctl(&server.url())
        .args(["auth", "login", "--password-stdin"])
        .write_stdin("pass")
        .assert()
        .failure()
        .stderr(predicate::str::contains("--username is required"));
    hbctl(&server.url())
        .args(["auth", "login"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("non-interactive login requires"));

    let m_login_401 = server
        .mock("POST", "/api/v1/users/login")
        .with_status(401)
        .with_body("invalid creds secret_pw_999")
        .expect(1)
        .create();
    hbctl(&server.url())
        .args([
            "auth",
            "login",
            "--username",
            "alice@example.com",
            "--password-stdin",
        ])
        .write_stdin("secret_pw_999\n")
        .assert()
        .failure()
        .stderr(predicate::str::contains("***"));
    m_login_401.assert();
}

#[test]
fn test_tag_entity_type_field_api_status_update_cli_paths() {
    if !can_execute_binary() {
        return;
    }
    let dir = tempdir().unwrap();
    let mut server = Server::new();

    // --- Tag ---
    let m_tag_create = server
        .mock("POST", "/api/v1/tags")
        .with_status(201)
        .with_header("content-type", "application/json")
        .with_body(r#"{"id":"tag-new","name":"Foo","description":""}"#)
        .expect(1)
        .create();
    hbctl(&server.url())
        .args(["--json", "tag", "create", "Foo"])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"id\":\"tag-new\""));
    m_tag_create.assert();

    hbctl(&server.url())
        .args([
            "--dry-run",
            "--json",
            "tag",
            "update",
            "tag-1",
            "--name",
            "New",
            "--description",
            "Desc",
            "--color",
            "#ff0000",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"#ff0000\""));

    let m_tag_get = server
        .mock("GET", "/api/v1/tags/tag-1")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(r#"{"id":"","name":"Old","description":""}"#)
        .expect(1)
        .create();
    let m_tag_put = server
        .mock("PUT", "/api/v1/tags/tag-1")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(r#"{"id":"tag-1","name":"New","description":"Desc","color":"ff0000"}"#)
        .expect(1)
        .create();
    hbctl(&server.url())
        .args([
            "tag",
            "update",
            "tag-1",
            "--name",
            "New",
            "--description",
            "Desc",
            "--color",
            "#ff0000",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("New"))
        .stdout(predicate::str::contains("Desc"));
    m_tag_get.assert();
    m_tag_put.assert();

    let m_tag_del = server
        .mock("DELETE", "/api/v1/tags/tag-1")
        .with_status(204)
        .expect(1)
        .create();
    hbctl(&server.url())
        .args(["tag", "delete", "tag-1", "--force"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Deleted tag tag-1"));
    m_tag_del.assert();

    let m_tag_del_err = server
        .mock("DELETE", "/api/v1/tags/tag-err")
        .with_status(500)
        .with_body("fail hb_test_secret_token_999")
        .expect(1)
        .create();
    hbctl(&server.url())
        .args(["tag", "delete", "tag-err", "--force"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("***"));
    m_tag_del_err.assert();

    // --- Entity types ---
    let m_et_list = server
        .mock("GET", "/api/v1/entity-types")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(fixture("entity_types.json"))
        .expect(1)
        .create();
    hbctl(&server.url())
        .args(["--select", "id,name", "entity-types", "list"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Storage Bin"));
    m_et_list.assert();

    hbctl(&server.url())
        .args(["entity-types", "create", "   "])
        .assert()
        .failure()
        .stderr(predicate::str::contains("entity type name cannot be empty"));

    let m_et_create = server
        .mock("POST", "/api/v1/entity-types")
        .with_status(201)
        .with_header("content-type", "application/json")
        .with_body(r#"{"id":"et-new","name":"Box","description":"Storage","isLocation":true}"#)
        .expect(3)
        .create();
    hbctl(&server.url())
        .args([
            "entity-types",
            "create",
            "Box",
            "--is-location",
            "--description",
            "Storage",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("yes [location]"));
    hbctl(&server.url())
        .args(["--select", "id,name", "entity-types", "create", "Box"])
        .assert()
        .success()
        .stdout(predicate::str::contains("et-new"));
    hbctl(&server.url())
        .args(["--quiet", "entity-types", "create", "Box"])
        .assert()
        .success()
        .stdout("et-new\n");
    m_et_create.assert();

    let m_et_del = server
        .mock("DELETE", "/api/v1/entity-types/et-new")
        .with_status(204)
        .expect(1)
        .create();
    hbctl(&server.url())
        .args(["entity-types", "delete", "et-new", "--force"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Deleted entity type et-new"));
    m_et_del.assert();

    // --- Field ---
    let m_field_ent = server
        .mock("GET", "/api/v1/entities/ent-f")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(
            json!({
                "id": "ent-f",
                "name": "Meter",
                "quantity": 1,
                "manufacturer": "Fluke",
                "fields": [{"name": "Voltage", "type": "number", "numberValue": 9}]
            })
            .to_string(),
        )
        .expect(4)
        .create();
    hbctl(&server.url())
        .args(["--quiet", "field", "get", "ent-f", "manufacturer"])
        .assert()
        .success()
        .stdout("Fluke\n");
    hbctl(&server.url())
        .args(["--json", "field", "get", "ent-f", "manufacturer"])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"value\":\"Fluke\""));
    hbctl(&server.url())
        .args(["field", "get", "ent-f", "manufacturer"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Fluke"));

    let m_field_put = server
        .mock("PUT", "/api/v1/entities/ent-f")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(r#"{"id":"ent-f","name":"Meter","quantity":1,"fields":[]}"#)
        .expect(1)
        .create();
    hbctl(&server.url())
        .args(["field", "delete", "ent-f", "Voltage"])
        .assert()
        .success()
        .stdout(predicate::str::contains(
            "Deleted field 'Voltage' from item ent-f",
        ));
    m_field_ent.assert();
    m_field_put.assert();

    // --- API ---
    let m_health = server
        .mock("GET", "/api/v1/health")
        .with_status(200)
        .with_header("content-type", "text/plain")
        .with_body("ok")
        .expect(2)
        .create();
    hbctl(&server.url())
        .args(["api", "GET", "health"])
        .assert()
        .success()
        .stdout("ok\n");
    hbctl(&server.url())
        .args(["--json", "api", "GET", "health"])
        .assert()
        .success()
        .stdout("\"ok\"\n");
    m_health.assert();

    let m_api_obj = server
        .mock("GET", "/api/v1/entities/e1")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(r#"{"id":"e1","name":"One"}"#)
        .expect(1)
        .create();
    hbctl(&server.url())
        .args(["--select", "id,name", "api", "GET", "entities/e1"])
        .assert()
        .success()
        .stdout(predicate::str::contains("One"));
    m_api_obj.assert();

    let m_api_num_id = server
        .mock("GET", "/api/v1/items-num")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(r#"{"id":123}"#)
        .expect(1)
        .create();
    hbctl(&server.url())
        .args(["--quiet", "api", "GET", "items-num"])
        .assert()
        .success()
        .stdout("123\n");
    m_api_num_id.assert();

    let m_api_scalar = server
        .mock("GET", "/api/v1/items-scalar")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(r#""scalar""#)
        .expect(1)
        .create();
    hbctl(&server.url())
        .args(["--quiet", "api", "GET", "items-scalar"])
        .assert()
        .success()
        .stdout("");
    m_api_scalar.assert();

    hbctl(&server.url())
        .args(["api", "GET", "items", "--query", "=bad"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("empty key"));

    let bad_json_file = dir.path().join("bad.json");
    fs::write(&bad_json_file, "{not-json").unwrap();
    hbctl(&server.url())
        .args([
            "api",
            "POST",
            "items",
            "--from-json",
            bad_json_file.to_str().unwrap(),
        ])
        .assert()
        .failure()
        .stderr(predicate::str::contains("invalid JSON from"));

    for method in ["PATCH", "HEAD", "OPTIONS"] {
        hbctl(&server.url())
            .args(["--dry-run", "api", method, "status"])
            .assert()
            .success()
            .stdout(predicate::str::contains(method));
    }

    // --- Status error ---
    let m_status_err = server
        .mock("GET", "/api/v1/status")
        .with_status(500)
        .with_body("down")
        .expect(1)
        .create();
    hbctl(&server.url())
        .args(["status"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("500"));
    m_status_err.assert();

    // --- Update with --json (covers src/lib.rs:46) ---
    hbctl(&server.url())
        .args(["--json", "update"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("non-interactive mode"));
}
