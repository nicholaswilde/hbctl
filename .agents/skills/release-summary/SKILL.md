---
name: release-summary
description: Generates clean GitHub release summary based on git logs using scripts/release_summary.py. Trigger: /release-summary, "release summary", "generate release notes".
---

# /release-summary [range]

Generates categorized GitHub release notes via `scripts/release_summary.py`.

```bash
task release:summary
./scripts/release_summary.py --dry-run
```
