//! Homebox (`hbctl`) CLI application entrypoint.
//!
//! A thin binary dispatch wrapper delegating execution to the `hbctl` library crate.

fn main() -> anyhow::Result<()> {
    hbctl::run()
}
