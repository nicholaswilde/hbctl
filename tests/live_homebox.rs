//! Optional live container integration test against `ghcr.io/sysadminsmedia/homebox:latest`.
//! Run explicitly with: `cargo test --test live_homebox -- --ignored`

use std::time::{SystemTime, UNIX_EPOCH};

use reqwest::blocking::Client;
use serde_json::{json, Value};
use tempfile::tempdir;
use testcontainers::core::{IntoContainerPort, WaitFor};
use testcontainers::runners::SyncRunner;
use testcontainers::{GenericImage, ImageExt};

use hbx::client::models::{CreateEntityRequest, CustomField, FieldValueType};
use hbx::client::{HomeboxClient, ListEntitiesQuery};

#[test]
#[ignore = "requires Docker and pulls ghcr.io/sysadminsmedia/homebox:latest"]
fn test_live_homebox_end_to_end() {
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("system clock")
        .as_nanos();
    let pepper = format!("hbx-live-pepper-{nanos}");

    let container = GenericImage::new("ghcr.io/sysadminsmedia/homebox", "latest")
        .with_exposed_port(7745.tcp())
        .with_wait_for(WaitFor::message_on_stdout("Server started"))
        .with_env_var("HBOX_LOG_LEVEL", "info")
        .with_env_var("HBOX_AUTH_API_KEY_PEPPER", pepper)
        .with_env_var("HBOX_OPTIONS_ALLOW_REGISTRATION", "true")
        .start()
        .expect("start Homebox container");

    let host_port = container
        .get_host_port_ipv4(7745)
        .expect("resolve mapped port 7745");
    let base_url = format!("http://127.0.0.1:{host_port}");

    let http = Client::new();
    let email = format!("hbx-test-{nanos}@example.com");
    let password = "TestPassword123!";

    // Register test user
    let reg = http
        .post(format!("{base_url}/api/v1/users/register"))
        .json(&json!({
            "name": "HBX Test User",
            "email": email,
            "password": password
        }))
        .send()
        .expect("register request");
    assert!(
        reg.status().is_success(),
        "register failed: {}",
        reg.status()
    );

    // Login to acquire Bearer token
    let login = http
        .post(format!("{base_url}/api/v1/users/login"))
        .json(&json!({
            "username": email,
            "password": password,
            "stayLoggedIn": false
        }))
        .send()
        .expect("login request");
    assert!(
        login.status().is_success(),
        "login failed: {}",
        login.status()
    );
    let login_json: Value = login.json().expect("parse login json");
    let token = login_json["token"]
        .as_str()
        .expect("token field in login response");

    // Exercise HomeboxClient end-to-end
    let client = HomeboxClient::with_defaults(&base_url, token).expect("construct HomeboxClient");

    let req = CreateEntityRequest {
        name: "Live Test ESP32".to_string(),
        description: Some("Created by hbx live container test".to_string()),
        quantity: Some(2),
        fields: vec![
            CustomField::new_typed("Manufacturer", FieldValueType::Text, "Espressif").unwrap(),
            CustomField::new_typed("Voltage", FieldValueType::Number, "3.3").unwrap(),
        ],
        ..Default::default()
    };

    // Create + verify follow-up PUT persisted custom fields
    let created = client.create_entity(&req).expect("create entity");
    assert!(!created.id.is_empty());

    let fetched = client.get_entity(&created.id).expect("get created entity");
    assert_eq!(fetched.name, "Live Test ESP32");
    assert_eq!(
        fetched.field_value("Manufacturer").as_deref(),
        Some("Espressif")
    );
    assert_eq!(fetched.field_value("Voltage").as_deref(), Some("3.3"));

    // Verify listing includes the created entity
    let listed = client
        .list_entities(&ListEntitiesQuery::default(), true)
        .expect("list entities");
    assert!(listed.iter().any(|e| e.id == created.id));

    // Verify attachment upload
    let tmp = tempdir().expect("create tempdir");
    let sample_file = tmp.path().join("manual.txt");
    std::fs::write(&sample_file, b"Homebox live attachment test").expect("write temp file");
    let uploaded = client
        .upload_attachment(&created.id, &sample_file)
        .expect("upload attachment");
    assert!(!uploaded.id.is_empty());
}
