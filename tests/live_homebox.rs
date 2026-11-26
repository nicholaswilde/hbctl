//! Live container integration test against `ghcr.io/sysadminsmedia/homebox:latest`.
//! Run explicitly with: `cargo test --test live_homebox -- --ignored --nocapture`

use std::fs;
use std::time::{SystemTime, UNIX_EPOCH};

use reqwest::blocking::Client;
use serde_json::json;
use tempfile::tempdir;
use testcontainers::core::{IntoContainerPort, WaitFor};
use testcontainers::runners::SyncRunner;
use testcontainers::{GenericImage, ImageExt};

use hbctl::client::models::{CreateEntityRequest, CustomField, EntityPatch, FieldValueType};
use hbctl::client::resolve::Resolver;
use hbctl::client::{HomeboxClient, ListEntitiesQuery};

#[test]
#[ignore = "requires Docker and pulls ghcr.io/sysadminsmedia/homebox:latest"]
fn test_live_homebox_end_to_end() {
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("system clock")
        .as_nanos();
    let pepper = format!("hbctl-live-pepper-{nanos:0>32}");

    let container = GenericImage::new("ghcr.io/sysadminsmedia/homebox", "latest")
        .with_exposed_port(7745.tcp())
        .with_wait_for(WaitFor::message_on_either_std("Server is running on"))
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
    let email = format!("hbctl-test-{nanos}@example.com");
    let password = "TestPassword123!";

    // 1. Register test user
    let reg = http
        .post(format!("{base_url}/api/v1/users/register"))
        .json(&json!({
            "name": "HBCTL Test User",
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

    // 2. Login via HomeboxClient::login + verify /users/self + /users/refresh (`raw` alias)
    let login = HomeboxClient::login(&base_url, &email, password, 30).expect("login");
    assert!(!login.token.is_empty());

    let client =
        HomeboxClient::with_defaults(&base_url, &login.token).expect("construct HomeboxClient");
    let me = client.get_current_user().expect("get /users/self");
    assert_eq!(me.email, email);

    let refreshed = client.refresh_token().expect("refresh token");
    assert!(!refreshed.token.is_empty());
    let client = HomeboxClient::with_defaults(&base_url, &refreshed.token)
        .expect("construct refreshed HomeboxClient");

    // 3. Entity types (highlighting isLocation) & tag resolution + auto-creation
    let entity_types = client.list_entity_types().expect("list entity-types");
    assert!(entity_types.iter().any(|et| et.is_location));
    assert!(entity_types.iter().any(|et| !et.is_location));

    let mut resolver = Resolver::new(&client);
    let item_type_id = resolver
        .resolve_entity_type_id("item")
        .expect("resolve Item entity type");
    let tag_id = resolver
        .resolve_tag_id("hbctl-live-tag", true)
        .expect("auto-create tag");
    assert!(!tag_id.is_empty());

    // 4. Create entity with typed custom fields (text, integer number, boolean)
    //    verifying POST -> follow-up PUT persistence on real Homebox v0.27+
    let req = CreateEntityRequest {
        name: "Live Test ESP32".to_string(),
        description: Some("Created by hbctl live container test".to_string()),
        quantity: Some(2),
        entity_type_id: Some(item_type_id),
        tag_ids: vec![tag_id.clone()],
        purchase_price: Some(12.5),
        purchase_from: Some("Mouser".to_string()),
        fields: vec![
            CustomField::new_typed("Manufacturer", FieldValueType::Text, "Espressif").unwrap(),
            CustomField::new_typed("Pins", FieldValueType::Number, "38").unwrap(),
            CustomField::new_typed("Tested", FieldValueType::Boolean, "true").unwrap(),
        ],
        ..Default::default()
    };

    let created = client.create_entity(&req).expect("create entity");
    assert!(!created.id.is_empty());

    let fetched = client.get_entity(&created.id).expect("get created entity");
    assert_eq!(fetched.name, "Live Test ESP32");
    assert_eq!(
        fetched.field_value("Manufacturer").as_deref(),
        Some("Espressif")
    );
    assert_eq!(fetched.field_value("Pins").as_deref(), Some("38"));
    assert_eq!(fetched.field_value("Tested").as_deref(), Some("true"));
    assert_eq!(fetched.effective_tag_ids(), vec![tag_id.clone()]);

    // 5. GET -> Merge -> PUT update preserves unrelated custom fields and tags
    let patch = EntityPatch {
        quantity: Some(5),
        fields: vec![CustomField::new_typed("Notes", FieldValueType::Text, "Bin A").unwrap()],
        ..Default::default()
    };
    let updated = client
        .update_entity(&created.id, &patch)
        .expect("GET -> Merge -> PUT update");
    assert_eq!(updated.quantity, 5);
    assert_eq!(
        updated.field_value("Manufacturer").as_deref(),
        Some("Espressif")
    );
    assert_eq!(updated.field_value("Pins").as_deref(), Some("38"));
    assert_eq!(updated.field_value("Notes").as_deref(), Some("Bin A"));
    assert_eq!(updated.effective_tag_ids(), vec![tag_id]);

    // 6. List entities omits `fields` on summary -> hydrate_entity_fields populates them
    let listed = client
        .list_entities(&ListEntitiesQuery::default(), true)
        .expect("list entities");
    let summary = listed
        .iter()
        .find(|e| e.id == created.id)
        .expect("created entity in list");
    assert!(summary.needs_field_hydration());

    let hydrated = client
        .hydrate_entity_fields(listed)
        .expect("hydrate entity fields");
    let full = hydrated
        .iter()
        .find(|e| e.id == created.id)
        .expect("hydrated entity");
    assert_eq!(
        full.field_value("Manufacturer").as_deref(),
        Some("Espressif")
    );

    // 7. Attachment upload, streaming download (byte-exact), and delete
    let tmp = tempdir().expect("create tempdir");
    let sample_file = tmp.path().join("manual.txt");
    let payload = b"Homebox live attachment roundtrip bytes";
    fs::write(&sample_file, payload).expect("write temp file");

    let uploaded = client
        .upload_attachment(&created.id, &sample_file)
        .expect("upload attachment");
    assert!(!uploaded.id.is_empty());

    let downloaded_path = tmp.path().join("downloaded.txt");
    let nbytes = client
        .download_attachment(&created.id, &uploaded.id, &downloaded_path)
        .expect("download attachment");
    assert_eq!(nbytes as usize, payload.len());
    assert_eq!(fs::read(&downloaded_path).unwrap(), payload);

    client
        .delete_attachment(&created.id, &uploaded.id)
        .expect("delete attachment");

    // 8. Delete entity
    client.delete_entity(&created.id).expect("delete entity");
}
