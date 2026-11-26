---
name: release
description: Automates versioning, tagging, and deployment using scripts/release.sh. Trigger: /release, "release", "cut release", "tag release".
---

# /release [patch|minor|major|<version>]

Automates the versioning, tagging, and deployment process for `hbx`.

## Description

This skill handles the release process by executing the `scripts/release.sh` utility. The script automatically determines the target version (default: next patch, or increments minor/major, or accepts an explicit version), runs static analysis and unit tests (`task check`, `task test`), bumps `Cargo.toml` and `Cargo.lock` (skipping the bump commit if `Cargo.toml` already matches an untagged initial version), commits, tags, and pushes atomically to the remote repository.

## Protocol

1. Execute the script in the terminal or use `task`:

   ```bash
   # Release next patch version (e.g. 0.1.0 -> 0.1.1)
   ./scripts/release.sh
   # or
   task release

   # Release minor or major version
   ./scripts/release.sh minor
   ./scripts/release.sh major

   # Release explicit version
   ./scripts/release.sh 0.2.0
   ```

2. If it succeeds, the new version is tagged and pushed to trigger the GitHub Actions release workflow (`.github/workflows/release.yml`), which builds cross-compiled archives and `.deb` packages, publishes the GitHub Release, and dispatches updates to `nicholaswilde/apt`, `nicholaswilde/homebrew-tap`, and `nicholaswilde/scoop-bucket`.
