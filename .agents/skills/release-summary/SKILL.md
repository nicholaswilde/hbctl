---
name: release-summary
description: Generates clean GitHub release summary based on git logs using scripts/release_summary.py. Trigger: /release-summary, "release summary", "generate release notes".
---

# /release-summary [range]

Generates a clean, categorized GitHub release summary for `hbctl` based on git logs.

## Description

This skill uses `scripts/release_summary.py` to retrieve git commit logs, format them into a structured Markdown summary (New Features, Bug Fixes, Improvements, Documentation), and update the GitHub release in-place without flipping a published release back to draft (use `--draft` or `--prerelease` explicitly if desired).

## Protocol

1. Execute the Python script. If no range is provided, it automatically detects the latest two tags:

   ```bash
   rtk uv run scripts/release_summary.py [range]
   # or
   task release:summary

   # Preview without modifying GitHub
   rtk uv run scripts/release_summary.py --dry-run
   ```

2. **Special Thanks**: If the user asks to add special thanks (e.g. to a contributor or tester), pass `--thanks` (and optionally `--for` / `--reason`):

   ```bash
   # Name and reason
   rtk uv run scripts/release_summary.py [range] --thanks "<Name>" --for "<reason>"

   # Or full message
   rtk uv run scripts/release_summary.py [range] --thanks "Huge thanks to **<Name>** for <reason>!"
   ```

   This generates the section:

   ```markdown
   ### 🙏 **Special Thanks**

   Huge thanks to **<Name>** for <reason>!
   ```

3. The script parses Conventional Commits, generates the Markdown notes, and runs `gh release edit` to update the release in-place.
