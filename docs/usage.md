# Usage

```bash
hbctl [GLOBAL OPTIONS] <COMMAND>
```

## :globe_with_meridians: Global Options

| Flag | Description | Env / Default |
| :--- | :--- | :--- |
| `--url <URL>` | Homebox base URL | `HBCTL_URL` > `HOMEBOX_URL` > `HOMEBOX_IP` |
| `--api-key <KEY>` | Homebox API key (`hb_...`) or Bearer token | `HBCTL_API_KEY` > `HOMEBOX_API_KEY` |
| `--output <FORMAT>` | Output format (`table`, `json`, `plain`) | `HBCTL_OUTPUT` (default: `table`) |
| `--json` | Shorthand for `--output json` (emits compact JSON) | `false` |
| `--select <FIELDS>` | Comma-separated field projection for JSON/table output (e.g. `id,name,fields`) | `None` |
| `--dry-run` | Preview mutating HTTP requests without hitting the server (redacts `Authorization`) | `false` |
| `-q`, `--quiet` | Output only created/affected IDs for shell piping | `false` |
| `-C`, `--config <PATH>` | Path to explicit TOML configuration file | `None` |
| `-P`, `--profile <NAME>` | Named configuration profile | `HBCTL_PROFILE` |

## :keyboard: Commands

| Command | Description | Example |
| :--- | :--- | :--- |
| `auth` | Authenticate with Homebox (`login`, `status`, `logout`, `refresh`) | `hbctl auth status` |
| `status` | Check remote Homebox server connectivity and version (`/api/v1/status`) | `hbctl status --url http://192.168.1.50:7745` |
| `item` | Manage inventory items (`list`, `get`, `create`, `update`, `upsert`, `delete`, `import`, `dedup`, `move`, `tree`) | `hbctl item list --all --json` |
| `attachment` | Upload, list, stream-download, and delete item attachments | `hbctl attachment upload <ID> manual.pdf` |
| `search` | Full-text and structured item search | `hbctl search --manufacturer Espressif` |
| `field` | List, get, set, or delete typed custom fields on an item | `hbctl field set <ID> Voltage 3.3 --type number` |
| `tag` | List, create, update, or delete tags | `hbctl tag list` |
| `entity-types` (`entity-type`) | List, create, or delete Homebox entity types | `hbctl entity-types create "Storage Bin" --is-location` |
| `export` | Export filtered items to JSON, CSV, or Markdown | `hbctl export --format markdown` |
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
# List items (filter by tag, entity type, parent, or custom field existence)
hbctl item list --tag electronics --all
hbctl item list --type "Storage Bin" --parent none
hbctl item list --has-field Voltage --page-size 50

# Fetch a single item by ID
hbctl item get <ITEM_ID> --json

# Render parent/location hierarchy as a tree
hbctl item tree
hbctl item tree --root "Workshop" --max-depth 2

# Move an item under a parent item/location (or 'none' to unparent)
hbctl item move <ITEM_ID> "Storage Bin A"
hbctl item move <ITEM_ID> none
```

### Creating, Updating & Upserting

`hbctl item create` automatically persists custom fields via a follow-up `PUT`. `hbctl item update` performs a safe `GET -> Merge -> PUT` so existing fields and attachments are preserved.

```bash
# Create an item with tags, standard metadata, and typed custom fields
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
  --field Voltage=3.3 --field-type number \
  --attach datasheet.pdf --attach photo.jpg --optimize

# Create or update from a JSON file or stdin ('-')
cat item.json | hbctl item create --from-json -
hbctl item update <ITEM_ID> --from-json patch.json

# Incrementally adjust tags and fill only missing fields on update
hbctl item update <ITEM_ID> --add-tag verified --remove-tag draft --fill-missing --notes "Tested OK"

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

# Delete an item (pass --force to skip interactive confirmation)
hbctl item delete <ITEM_ID> --force
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
# Upload one or more local files (skips existing filenames by default)
hbctl attachment upload <ITEM_ID> manual.pdf schematic.png

# Overwrite existing remote attachments or upload from stdin
cat diagram.png | hbctl attachment upload <ITEM_ID> - --name diagram.png --overwrite

# Download and attach from a remote URL
hbctl attachment upload <ITEM_ID> --attach-url "https://example.com/manual.pdf=manual.pdf"

# Auto-optimize oversized images (> 500 KB) or bypass the size guard with --force
hbctl attachment upload <ITEM_ID> bench_photo.png --optimize
hbctl attachment upload <ITEM_ID> raw_scan.png --force

# List attachments on an item
hbctl attachment list <ITEM_ID>

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

# Structured search combining tag, model, serial, manufacturer, and custom fields (AND)
hbctl search --tag electronics --manufacturer Espressif --field Voltage=3.3

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

## :outbox_tray: Exporting & Agent Piping

```bash
# Export filtered items to JSON, CSV, or Markdown
hbctl export --tag electronics --field Manufacturer --field Voltage --sort name --format json
hbctl export --has-field Voltage --format csv
hbctl export --tag electronics --format markdown \
  --columns "name=Item,quantity=Qty,Manufacturer,Voltage=V" \
  --align left --empty "-"

# Agent-friendly field projection and ID piping
hbctl item list --json --select id,name,Manufacturer,Voltage
hbctl item list --tag obsolete -q | xargs -r -n1 hbctl item delete --force

# Safe dry-run inspection (shows method, URL, redacted Authorization, and body)
hbctl --dry-run item create --name "Test Part" --field Voltage=5
```
