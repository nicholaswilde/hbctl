# Usage

```bash
hbctl [GLOBAL OPTIONS] <COMMAND>
```

## :globe_with_meridians: Global Options

| Flag | Description | Env / Default |
| :--- | :--- | :--- |
| `--url <URL>` | Homebox base URL | `HBCTL_URL` > `HOMEBOX_URL` > `HOMEBOX_IP` |
| `--api-key <KEY>` | Homebox API key (`hb_...`) or Bearer token | `HBCTL_API_KEY` > `HOMEBOX_API_KEY` |
| `--output <FORMAT>` | Output format (`table`, `json`, `plain`, `csv`, `markdown`) | `HBCTL_OUTPUT` (default: `table`) |
| `--json` | Shorthand for `--output json` (emits compact JSON) | `false` |
| `--select <FIELDS>` | Comma-separated field projection for JSON/table output (e.g. `id,name,fields`) | `None` |
| `--dry-run` | Preview mutating HTTP requests without hitting the server (redacts `Authorization`) | `false` |
| `-q`, `--quiet` | Output only created/affected IDs for shell piping | `false` |
| `-C`, `--config <PATH>` | Path to explicit TOML configuration file | `None` |
| `-P`, `--profile <NAME>` | Named configuration profile | `HBCTL_PROFILE` |
| `--asset-id` | Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like `000-001`) | `false` |

## :keyboard: Commands

| Command | Description | Example |
| :--- | :--- | :--- |
| `auth` | Authenticate with Homebox (`login`, `status`, `logout`, `refresh`) | `hbctl auth status` |
| `status` | Check remote Homebox server connectivity and version (`/api/v1/status`) | `hbctl status --url http://192.168.1.50:7745` |
| `item` | Manage inventory items (`list`, `get`, `create`, `update`, `upsert`, `delete`, `import`, `dedup`, `move`, `duplicate`, `path`, `tree`) | `hbctl item list --all --json` |
| `attachment` | Upload, list, download, update, link, and delete item attachments (`upload`, `list`, `download`, `delete`, `set-primary`, `update`, `add-link`) | `hbctl attachment upload <ID> manual.pdf` |
| `search` | Full-text and structured item search | `hbctl search --manufacturer Espressif` |
| `field` | List, get, set, or delete typed custom fields on an item | `hbctl field set <ID> Voltage 3.3 --type number` |
| `tag` | List, create, update, or delete tags | `hbctl tag list` |
| `entity-types` (`entity-type`) | List, create, or delete Homebox entity types | `hbctl entity-types create "Storage Bin" --is-location` |
| `maintenance` | Manage maintenance log entries (`list`, `create`, `update`, `delete`) | `hbctl maintenance list --status scheduled` |
| `export` | Export filtered items to JSON, CSV, or Markdown | `hbctl export --format markdown` |
| `backup` | Create a portable full-inventory backup (directory or `.tar.gz` archive) | `hbctl backup --out ./homebox-backup.tar.gz` |
| `label` | Generate or print a Homebox item, asset, or location label | `hbctl label 000-001 --out label.png` |
| `qr` | Generate a QR code image (`/api/v1/qrcode`) | `hbctl qr <ITEM_ID> --out qr.png` |
| `actions` (`action`) | Run Homebox server maintenance actions (`ensure-asset-ids`, `create-missing-thumbnails`) | `hbctl actions ensure-asset-ids` |
| `stats` | Display inventory statistics and breakdowns (`overview`, `tags`, `locations`, `entity-types`, `purchase-price`) | `hbctl stats overview --warranty-days 30` |
| `config` | Inspect effective configuration and manage named profiles (`show`, `profiles`, `use`) | `hbctl config show` |
| `template` (`templates`) | Manage item templates and create items from templates (`list`, `get`, `create`, `update`, `delete`, `apply`) | `hbctl template apply <TEMPLATE_ID>` |
| `barcode` | Look up product metadata by barcode | `hbctl barcode 012345678905` |
| `notifier` (`notifiers`) | Manage Shoutrrr notification channels (`list`, `create`, `update`, `delete`, `test`) | `hbctl notifier list` |
| `api` | Issue a raw authenticated HTTP request against any Homebox API endpoint | `hbctl api GET groups` |
| `update` (`self-update`) | Check for and install the latest `hbctl` release from GitHub | `hbctl update --check` |
| `completions` | Generate shell completion scripts (`bash`, `zsh`, `fish`, `powershell`, `elvish`) | `hbctl completions zsh` |
| `man` | Output UNIX roff man page | `hbctl man > assets/hbctl.1` |

## :key: Authentication & Server Status

```bash
# Authenticate using an API key read from stdin (avoids shell history leaks)
echo "$HOMEBOX_API_KEY" | hbctl auth login --url http://192.168.1.50:7745 --with-token

# Authenticate with email/username (prompts securely for password)
hbctl auth login --url http://192.168.1.50:7745 --username you@example.com

# Non-interactive password login via stdin
printf '%s\n' "$HOMEBOX_PASSWORD" | hbctl auth login --url http://192.168.1.50:7745 -u you@example.com --password-stdin

# Force 0600 local file storage instead of OS keyring (headless/SSH/containers)
echo "$HOMEBOX_API_KEY" | hbctl auth login --url http://192.168.1.50:7745 --with-token --insecure-storage

# Check active authentication status (token is always redacted as Bearer ***)
hbctl auth status

# Refresh an active JWT session token
hbctl auth refresh

# Remove stored credentials (pass --insecure-storage to only clear the local file store)
hbctl auth logout

# Check remote server reachability and version (no auth required)
hbctl status
```

## :package: Managing Inventory Items

### Listing, Reading & Hierarchy

```bash
# List items (filter by tag, entity type, parent, custom field, archived state, or expiring warranties)
hbctl item list --tag electronics --all
hbctl item list --type "Storage Bin" --parent none
hbctl item list --has-field Voltage --page-size 50
hbctl item list --include-archived
hbctl item list --archived-only --warranty-expiring 30

# Fetch a single item by UUID or Homebox asset ID (auto-detected for 000-001, or pass --asset-id)
hbctl item get <ITEM_ID> --json
hbctl item get 000-001 --json
hbctl --asset-id item get A42

# Show location/parent breadcrumb path or duplicate an item
hbctl item path <ITEM_ID>
hbctl item duplicate <ITEM_ID> --count 2

# Render parent/location hierarchy as a tree
hbctl item tree
hbctl item tree --root "Workshop" --max-depth 2

# Move single or multiple items under a parent item/location (or 'none' to unparent)
hbctl item move <ITEM_ID> "Storage Bin A"
hbctl item move <ITEM_ID_1> <ITEM_ID_2> --to "Storage Bin A"
hbctl item move --tag staging --to "Warehouse"
hbctl item list --tag unsorted -q | hbctl item move --items-from - --to "Inbox"
hbctl item move <ITEM_ID> none
```

### Creating, Updating & Upserting

`hbctl item create` automatically persists custom fields via a follow-up `PUT`. `hbctl item update` performs a safe `GET -> Merge -> PUT` so existing fields and attachments are preserved.

```bash
# Create an item with tags, standard metadata, warranty/insurance/sold fields, and typed custom fields
hbctl item create \
  --name "ESP32 DevKit" \
  --description "Wi-Fi/BLE microcontroller" \
  --type "Component" \
  --parent "Parts Bin 1" \
  --tag microcontroller --tag wifi \
  --manufacturer "Espressif" \
  --model "ESP32-WROOM-32" \
  --serial "SN-001" \
  --quantity 4 \
  --purchase-price 6.50 \
  --purchase-date 2026-01-15 \
  --purchase-from "Mouser" \
  --insured \
  --warranty-expires 2028-01-15 \
  --warranty-details "2-year replacement" \
  --field Voltage=3.3 --field-type number \
  --attach datasheet.pdf --attach photo.jpg --optimize

# Prefill item metadata from a barcode lookup
hbctl item create --from-barcode 012345678905 --parent "Pantry"

# Create or update from a JSON file or stdin ('-')
cat item.json | hbctl item create --from-json -
hbctl item update <ITEM_ID> --from-json patch.json

# Incrementally adjust tags, warranty/sold/archived fields, or bulk-update multiple items
hbctl item update <ITEM_ID> --add-tag verified --remove-tag draft --fill-missing --notes "Tested OK"
hbctl item update <ITEM_ID> --sold-time 2026-06-01 --sold-to "Alice" --sold-price 15.00 --archived
hbctl item update --filter-tag temp --add-tag reviewed
hbctl item list --tag old -q | hbctl item update --items-from - --archived

# Idempotent upsert matched by serial, model, name, or custom field
hbctl item upsert \
  --name "ESP32 DevKit" \
  --model "ESP32-WROOM-32" \
  --match-by serial,model,name \
  --match-mode exact \
  --on-match update \
  --fill-missing \
  --field QuantityInBin=5 --field-type number \
  --attach-url "https://example.com/datasheet.pdf=datasheet.pdf" \
  --attach-best-effort

# Delete one or multiple items (pass -y / --yes / --force to skip confirmation)
hbctl item delete <ITEM_ID> --force
hbctl item delete --tag obsolete --yes
hbctl item list --tag scrap -q | hbctl item delete --items-from - --yes
```

!!! note
    `--match-mode` supports `exact`, `contains`, and `fuzzy`. `--on-match` supports `update` (default), `skip`, and `attach-only`. Use `--attach-best-effort` on `item create` or `item upsert` to treat attachment failures as warnings and include `attachmentErrors` in JSON output.

## :inbox_tray: Bulk Import & Deduplication

### Bulk Import (`item import`)

Import items from JSON or CSV files (or `-` for stdin; format is inferred from file extension and defaults to `json` for stdin):

```bash
# Import JSON array/records, skipping existing items
hbctl item import inventory.json --skip-existing

# Import CSV and update existing matches (filling only blank/zero fields)
hbctl item import inventory.csv --format csv --update-existing --fill-missing \
  --match-by model,name --match-mode exact --parent "Receiving"

# Attach files to every imported item and optimize oversized images
cat items.json | hbctl item import - --attach receipt.jpg --optimize
```

### Deduplication (`item dedup`)

`hbctl item dedup` runs a two-pass detector:

1. **Pass 1 (Exact):** Case-insensitive trimmed name matches.
2. **Pass 2 (Near):** Jaccard token similarity (`>= --threshold`, default `0.8`) after stripping version numbers and common hardware stop-words.

For each duplicate cluster, `hbctl` selects the keeper by longest trimmed name, then highest quantity, then first encountered:

```bash
# Preview duplicate clusters without modifying anything
hbctl item dedup --threshold 0.8

# Preview merging duplicate quantities onto each keeper
hbctl item dedup --threshold 0.8 --merge --dry-run

# Delete duplicates (or sum quantities onto keeper before deleting)
hbctl item dedup --delete
hbctl item dedup --merge
```

## :paperclip: Attachments & Image Optimization

```bash
# Upload one or more local files (skips existing filenames by default; --primary marks as primary photo)
hbctl attachment upload <ITEM_ID> manual.pdf schematic.png
hbctl attachment upload <ITEM_ID> hero.jpg --primary

# Overwrite existing remote attachments or upload from stdin
cat diagram.png | hbctl attachment upload <ITEM_ID> - --name diagram.png --overwrite

# Download and attach from a remote URL
hbctl attachment upload <ITEM_ID> --attach-url "https://example.com/manual.pdf=manual.pdf"

# Auto-optimize oversized images (> 500 KB) or bypass the size guard with --force
hbctl attachment upload <ITEM_ID> bench_photo.png --optimize
hbctl attachment upload <ITEM_ID> raw_scan.png --force

# List attachments, set primary photo, update metadata, or add an external link
hbctl attachment list <ITEM_ID>
hbctl attachment set-primary <ITEM_ID> <ATTACHMENT_ID>
hbctl attachment update <ITEM_ID> <ATTACHMENT_ID> --title "Owner Manual" --type manual --primary=false
hbctl attachment add-link <ITEM_ID> "https://example.com/datasheet.pdf" --title "Datasheet" --type manual

# Stream-download a single attachment or all matching attachments on an item
hbctl attachment download <ITEM_ID> <ATTACHMENT_ID> --out ./manual.pdf
hbctl attachment download <ITEM_ID> --all --ext pdf --out ./manuals

# Bulk download matching attachments across all items, by tag, or from an ID list
hbctl attachment download --all-items --mime application/pdf --out ./all-pdfs
hbctl attachment download --tag electronics --ext pdf --out ./elec-pdfs --overwrite
hbctl item list --tag electronics -q | hbctl attachment download --items-from - --ext jpg --out ./photos

# Delete an attachment
hbctl attachment delete <ITEM_ID> <ATTACHMENT_ID>
```

## :mag: Searching & Custom Fields

```bash
# Free-text search
hbctl search "ESP32"

# Structured search with tag, entity type, parent, limit, archived state, warranty window, and breadcrumb paths
hbctl search --tag electronics --manufacturer Espressif --field Voltage=3.3
hbctl search --type "Component" --parent "Workshop" --warranty-expiring 30 --with-path --limit 25
hbctl search --archived-only --include-archived

# Match ANY provided filter (OR semantics) and filter by field existence
hbctl search "sensor" --model "BME280" --field CalibrationDate --any

# Manage custom fields on an item
hbctl field list <ITEM_ID>
hbctl field get <ITEM_ID> Voltage
hbctl field set <ITEM_ID> Voltage 3.3 --type number
hbctl field set <ITEM_ID> Tested true --type boolean
hbctl field delete <ITEM_ID> Voltage
```

## :label: Tags & Entity Types

```bash
# Tags
hbctl tag list
hbctl tag create "microcontroller"
hbctl tag update <TAG_ID> --name "MCU" --description "Microcontrollers" --color "#89b4fa"
hbctl tag delete <TAG_ID> --force

# Entity types (alias: entity-type; defaults to 'list' when subcommand omitted)
hbctl entity-types
hbctl entity-types list
hbctl entity-types create "Storage Bin" --description "Physical container" --is-location
hbctl entity-types delete <TYPE_ID> --force
```

## :wrench: Maintenance Logs (`maintenance`)

```bash
# List maintenance entries globally or for a single entity
hbctl maintenance list
hbctl maintenance list <ITEM_ID> --status scheduled

# Create, update, and delete maintenance log entries
hbctl maintenance create <ITEM_ID> --name "Replace HEPA filter" --scheduled-date 2026-09-01 --cost 29.99
hbctl maintenance update <ENTRY_ID> --completed-date 2026-09-02 --description "Installed OEM filter"
hbctl maintenance delete <ENTRY_ID> --force
```

## :bar_chart: Statistics (`stats`)

```bash
# Overview statistics (defaults to overview when subcommand omitted)
hbctl stats
hbctl stats overview --warranty-days 30

# Breakdowns by tag, location, entity type, and purchase value over time
hbctl stats tags
hbctl stats locations
hbctl stats entity-types
hbctl stats purchase-price --start 2025-01-01 --end 2026-12-31
```

## :page_with_curl: Templates & Barcode Lookup (`template`, `barcode`)

```bash
# Manage templates
hbctl template list
hbctl template get <TEMPLATE_ID>
hbctl template create --name "USB-C Cable" --default-quantity 1 --default-manufacturer "Anker"
hbctl template update <TEMPLATE_ID> --default-description "Braided cable"
hbctl template apply <TEMPLATE_ID> --name "USB-C Cable 2m" --location "Cable Drawer"
hbctl template delete <TEMPLATE_ID> --force

# Look up product metadata by barcode
hbctl barcode 012345678905
hbctl item create --from-barcode 012345678905
```

## :bookmark_tabs: Labels, QR Codes & Server Actions (`label`, `qr`, `actions`)

```bash
# Generate or server-print labels (kind auto-detects asset IDs like 000-001)
hbctl label 000-001 --out label.png
hbctl label <LOCATION_ID> --kind location --print

# Generate QR code images (or encode raw text with --raw)
hbctl qr <ITEM_ID> --out qr.png
hbctl qr "https://example.com" --raw --out custom-qr.png

# Trigger Homebox server maintenance actions
hbctl actions ensure-asset-ids
hbctl actions create-missing-thumbnails
```

## :bell: Notifiers (`notifier`)

```bash
# List notifiers (Shoutrrr URLs are redacted by default; pass --reveal to show raw URLs)
hbctl notifier list
hbctl notifier list --reveal

# Create, update, test, and delete Shoutrrr notifiers
hbctl notifier create --name "Discord" --notifier-url "discord://token@channel"
hbctl notifier update <NOTIFIER_ID> --active=false
hbctl notifier test <NOTIFIER_ID>
hbctl notifier delete <NOTIFIER_ID> --yes
```

## :gear: Configuration & Profiles (`config`)

```bash
# Show resolved effective configuration (secrets redacted as Bearer ***)
hbctl config show

# List configured profiles and switch default_profile
hbctl config profiles
hbctl config use homelab
```

## :electric_plug: Raw API Requests (`api`)

```bash
# Issue raw authenticated GET/POST/PUT/PATCH/DELETE requests
hbctl api GET groups
hbctl api GET entities --query page=1 --query pageSize=10
hbctl api POST tags -d '{"name":"spare"}'
cat payload.json | hbctl api PUT entities/<ITEM_ID> --from-json -
```

## :outbox_tray: Exporting & Agent Piping

```bash
# Export filtered items to JSON, CSV, or Markdown
# (--sort: name, id, purchase-price, purchase-date, updated-at, asset-id)
hbctl export --tag electronics --field Manufacturer --field Voltage --sort purchase-price --format json
hbctl export --has-field Voltage --format csv
hbctl export --tag electronics --format markdown \
  --columns "name=Item,quantity=Qty,Manufacturer,Voltage=V" \
  --align left --empty "-"

# Render any command output directly as CSV or Markdown
hbctl item list --output csv
hbctl stats tags --output markdown

# Agent-friendly field projection and ID piping
hbctl item list --json --select id,name,Manufacturer,Voltage
hbctl item list --tag obsolete -q | xargs -r -n1 hbctl item delete --force

# Safe dry-run inspection (shows method, URL, redacted Authorization, and body)
hbctl --dry-run item create --name "Test Part" --field Voltage=5
```

## :floppy_disk: Full-Inventory Backup (`backup`)

```bash
# Write a portable directory backup (manifest.json + JSON exports + attachments/)
hbctl backup --out ./homebox-backup

# Write a compressed .tar.gz archive backup (or overwrite an existing destination)
hbctl backup --out ./homebox-backup.tar.gz --overwrite

# Preview backup counts without writing files or downloading attachments
hbctl --dry-run --json backup --out ./homebox-backup.tar.gz

# Back up metadata only (skip binary attachment downloads) and exclude archived items
hbctl backup --out ./homebox-metadata.tar.gz --no-attachments --exclude-archived
```
