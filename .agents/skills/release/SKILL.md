---
name: release
description: Automates versioning, tagging, and deployment using scripts/release.sh. Trigger: /release, "release", "cut release", "tag release".
---

# /release [patch|minor|major|<version>]

Automates versioning, tagging, and deployment via `scripts/release.sh`.

```bash
task release
./scripts/release.sh minor
./scripts/release.sh major
```
