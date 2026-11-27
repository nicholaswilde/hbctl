
use builtin;
use str;

set edit:completion:arg-completer[hbctl] = {|@words|
    fn spaces {|n|
        builtin:repeat $n ' ' | str:join ''
    }
    fn cand {|text desc|
        edit:complex-candidate $text &display=$text' '(spaces (- 14 (wcswidth $text)))$desc
    }
    var command = 'hbctl'
    for word $words[1..-1] {
        if (str:has-prefix $word '-') {
            break
        }
        set command = $command';'$word
    }
    var completions = [
        &'hbctl'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
            cand -V 'Print version'
            cand --version 'Print version'
            cand auth 'Authenticate with a remote Homebox instance (login, status, logout, refresh)'
            cand item 'Manage inventory items (/api/v1/entities)'
            cand attachment 'Manage item attachments (/api/v1/entities/{id}/attachments)'
            cand search 'Full-text and structured item search'
            cand field 'List, get, set, or delete typed custom fields on an item'
            cand tag 'Manage tags (/api/v1/tags)'
            cand entity-types 'Manage Homebox entity types (/api/v1/entity-types)'
            cand entity-type 'Manage Homebox entity types (/api/v1/entity-types)'
            cand status 'Check remote Homebox server connectivity and version (/api/v1/status)'
            cand api 'Issue a raw authenticated HTTP request against any Homebox API endpoint'
            cand maintenance 'Manage maintenance log entries (/api/v1/maintenance)'
            cand export 'Export filtered items to JSON, CSV, or Markdown'
            cand backup 'Create a portable full-inventory backup (directory or .tar.gz archive)'
            cand label 'Generate or print a Homebox item, asset, or location label (/api/v1/labelmaker)'
            cand qr 'Generate a QR code image (/api/v1/qrcode)'
            cand actions 'Run Homebox server maintenance actions (/api/v1/actions/*)'
            cand action 'Run Homebox server maintenance actions (/api/v1/actions/*)'
            cand stats 'Display inventory statistics and breakdowns (/api/v1/groups/statistics*)'
            cand config 'Inspect effective configuration and manage named profiles'
            cand template 'Manage item templates and create items from templates (/api/v1/templates)'
            cand templates 'Manage item templates and create items from templates (/api/v1/templates)'
            cand barcode 'Look up product metadata by barcode (/api/v1/products/search-from-barcode)'
            cand notifier 'Manage Shoutrrr notification channels (/api/v1/notifiers)'
            cand notifiers 'Manage Shoutrrr notification channels (/api/v1/notifiers)'
            cand completions 'Generate shell completion scripts'
            cand man 'Generate UNIX roff man page'
            cand update 'Check for and install the latest hbctl release from GitHub'
            cand self-update 'Check for and install the latest hbctl release from GitHub'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;auth'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
            cand login 'Authenticate with Homebox via API key (--with-token) or email/password'
            cand status 'Check authentication status and validate the active session'
            cand logout 'Remove stored credentials from OS keyring and local fallback store'
            cand refresh 'Refresh an active JWT session token'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;auth;login'= {
            cand -u 'Email or username for password login (POST /api/v1/users/login)'
            cand --username 'Email or username for password login (POST /api/v1/users/login)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --with-token 'Read a Homebox API key (hb_...) or Bearer token from stdin'
            cand --password-stdin 'Read login password from stdin instead of prompting interactively'
            cand --insecure-storage 'Store token in 0600 local file store instead of OS keyring'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;auth;status'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;auth;logout'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --insecure-storage 'Skip OS keyring and only clear local 0600 fallback store'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;auth;refresh'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --insecure-storage 'Store refreshed token in 0600 local file store instead of OS keyring'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;auth;help'= {
            cand login 'Authenticate with Homebox via API key (--with-token) or email/password'
            cand status 'Check authentication status and validate the active session'
            cand logout 'Remove stored credentials from OS keyring and local fallback store'
            cand refresh 'Refresh an active JWT session token'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;auth;help;login'= {
        }
        &'hbctl;auth;help;status'= {
        }
        &'hbctl;auth;help;logout'= {
        }
        &'hbctl;auth;help;refresh'= {
        }
        &'hbctl;auth;help;help'= {
        }
        &'hbctl;item'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
            cand list 'List inventory items'
            cand get 'Fetch a single item by ID'
            cand create 'Create a new item (auto-persists custom fields via follow-up PUT)'
            cand update 'Update an existing item via GET -> Merge -> PUT'
            cand upsert 'Create or update an item matched by name'
            cand delete 'Delete an item by ID'
            cand import 'Bulk import items from JSON or CSV (file or ''-'' for stdin)'
            cand dedup 'Detect (and optionally delete or merge) duplicate items'
            cand move 'Move an item under a parent item/location (or ''none'' to unparent)'
            cand duplicate 'Duplicate an existing item one or more times'
            cand path 'Display the location/parent breadcrumb path for an item'
            cand tree 'Render item parent/location hierarchy as a tree'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;item;list'= {
            cand --tag 'Filter by tag name or UUID'
            cand --type 'Filter by entity type name or UUID'
            cand --parent 'Filter by parent item name, ID, or ''none'' for top-level items'
            cand --has-field 'Only include items having the named custom field (hydrates details if missing)'
            cand --page-size 'Page size for listing'
            cand --warranty-expiring 'Only show items with a warranty expiring within the next DAYS days (excludes lifetime warranties)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --all 'Fetch all pages'
            cand --include-archived 'Include archived items in results'
            cand --archived-only 'Only show archived items (implies --include-archived)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;item;get'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --with-path 'Include full location/parent breadcrumb path in output'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;item;create'= {
            cand --name 'Item name (required unless supplied via --from-json or --from-barcode)'
            cand --description 'Item description'
            cand --type 'Entity type name or UUID'
            cand --parent 'Parent item/location name, ID, or ''none'''
            cand --tag 'Tag name or UUID (repeatable; missing tags auto-created)'
            cand --manufacturer 'Manufacturer (normalized into custom field ''Manufacturer'')'
            cand --model 'Model number (normalized into custom field ''Model Number'')'
            cand --serial 'Serial number (normalized into custom field ''Serial Number'')'
            cand --notes 'Notes (normalized into custom field ''Notes'')'
            cand --quantity 'Item quantity'
            cand --purchase-price 'Purchase price'
            cand --purchase-date 'Purchase date (YYYY-MM-DD)'
            cand --purchase-from 'Purchase vendor/source'
            cand --archived 'Mark item as archived (true/false; bare flag means true)'
            cand --insured 'Mark item as insured (true/false; bare flag means true)'
            cand --lifetime-warranty 'Mark item as having a lifetime warranty (true/false; bare flag means true)'
            cand --warranty-expires 'Warranty expiration date (YYYY-MM-DD or RFC3339)'
            cand --warranty-details 'Warranty details or terms'
            cand --sold-time 'Date/time the item was sold (YYYY-MM-DD or RFC3339)'
            cand --sold-to 'Buyer name or recipient the item was sold to'
            cand --sold-price 'Sale price'
            cand --sold-notes 'Notes about the sale'
            cand --field 'Custom field KEY=VAL (repeatable)'
            cand --field-type 'Value type for --field entries'
            cand --from-json 'Load initial item JSON from file path or ''-'' for stdin'
            cand --from-barcode 'Prefill name, description, manufacturer, and model from a barcode lookup'
            cand --attach 'Local file path(s) to attach after creating the item (`FILE` or `FILE=REMOTE_NAME`, repeatable)'
            cand --attach-url 'Remote HTTP(S) URL(s) to download and attach (`URL` or `URL=REMOTE_NAME`, repeatable)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --attach-best-effort 'Treat attachment failures as non-fatal warnings and include `attachmentErrors` in JSON output'
            cand --optimize 'Automatically resize/compress oversized images before upload'
            cand --force 'Allow attaching images larger than 500KB'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;item;update'= {
            cand --items-from 'Read newline-delimited entity IDs to update from a file or ''-'' (stdin)'
            cand --filter-tag 'Select items to update matching this tag name or UUID'
            cand --filter-parent 'Select items to update under this parent item/location name, ID, or ''none'''
            cand --filter-type 'Select items to update matching this entity type name or UUID'
            cand --name 'Updated item name'
            cand --description 'Updated item description'
            cand --type 'Entity type name or UUID'
            cand --parent 'Parent item/location name, ID, or ''none'' to unparent'
            cand --tag 'Tag name or UUID to merge (repeatable)'
            cand --add-tag 'Tag name or UUID to add while preserving existing tags (repeatable)'
            cand --remove-tag 'Tag name or UUID to remove while preserving other existing tags (repeatable)'
            cand --manufacturer 'Manufacturer (merged into custom field ''Manufacturer'')'
            cand --model 'Model number (merged into custom field ''Model Number'')'
            cand --serial 'Serial number (merged into custom field ''Serial Number'')'
            cand --quantity 'Updated quantity'
            cand --purchase-price 'Updated purchase price'
            cand --purchase-date 'Updated purchase date (YYYY-MM-DD)'
            cand --purchase-from 'Updated purchase source'
            cand --archived 'Mark item as archived (true/false; bare flag means true)'
            cand --insured 'Mark item as insured (true/false; bare flag means true)'
            cand --lifetime-warranty 'Mark item as having a lifetime warranty (true/false; bare flag means true)'
            cand --warranty-expires 'Warranty expiration date (YYYY-MM-DD or RFC3339)'
            cand --warranty-details 'Warranty details or terms'
            cand --sold-time 'Date/time the item was sold (YYYY-MM-DD or RFC3339)'
            cand --sold-to 'Buyer name or recipient the item was sold to'
            cand --sold-price 'Sale price'
            cand --sold-notes 'Notes about the sale'
            cand --notes 'Notes (merged into custom field ''Notes'')'
            cand --field 'Custom field KEY=VAL to upsert (repeatable)'
            cand --field-type 'Value type for --field entries'
            cand --from-json 'Load patch JSON from file path or ''-'' for stdin'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --fill-missing 'Only populate blank/missing/zero fields; preserve existing non-empty values'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;item;upsert'= {
            cand --name 'Item name to match or create (required unless supplied via --from-json)'
            cand --description 'Item description'
            cand --type 'Entity type name or UUID'
            cand --parent 'Parent item/location name, ID, or ''none'''
            cand --tag 'Tag name or UUID (repeatable; missing tags auto-created)'
            cand --manufacturer 'Manufacturer'
            cand --model 'Model number'
            cand --serial 'Serial number'
            cand --notes 'Notes'
            cand --quantity 'Quantity'
            cand --purchase-price 'Purchase price'
            cand --purchase-date 'Purchase date (YYYY-MM-DD)'
            cand --purchase-from 'Purchase source'
            cand --archived 'Mark item as archived (true/false; bare flag means true)'
            cand --insured 'Mark item as insured (true/false; bare flag means true)'
            cand --lifetime-warranty 'Mark item as having a lifetime warranty (true/false; bare flag means true)'
            cand --warranty-expires 'Warranty expiration date (YYYY-MM-DD or RFC3339)'
            cand --warranty-details 'Warranty details or terms'
            cand --sold-time 'Date/time the item was sold (YYYY-MM-DD or RFC3339)'
            cand --sold-to 'Buyer name or recipient the item was sold to'
            cand --sold-price 'Sale price'
            cand --sold-notes 'Notes about the sale'
            cand --field 'Custom field KEY=VAL (repeatable)'
            cand --field-type 'Value type for --field entries'
            cand --from-json 'Load item JSON from file path or ''-'' for stdin'
            cand --match-by 'Match existing items by key in priority order: name, model, serial, or field:KEY (repeatable; defaults to name)'
            cand --match-mode 'Matching strategy for --match-by keys (exact, contains, fuzzy)'
            cand --on-match 'Action to take when an existing item matches (update, skip, attach-only)'
            cand --attach 'Local file path(s) to attach after upserting the item (`FILE` or `FILE=REMOTE_NAME`, repeatable)'
            cand --attach-url 'Remote HTTP(S) URL(s) to download and attach (`URL` or `URL=REMOTE_NAME`, repeatable)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --fill-missing 'When updating an existing item, only populate blank/missing/zero fields'
            cand --attach-best-effort 'Treat attachment failures as non-fatal warnings and include `attachmentErrors` in JSON output'
            cand --optimize 'Automatically resize/compress oversized images before upload'
            cand --force 'Allow attaching images larger than 500KB'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;item;delete'= {
            cand --items-from 'Read newline-delimited entity IDs to delete from a file or ''-'' (stdin)'
            cand --tag 'Select items to delete matching this tag name or UUID'
            cand --filter-tag 'Select items to delete matching this tag name or UUID'
            cand --parent 'Select items to delete under this parent item/location name, ID, or ''none'''
            cand --filter-parent 'Select items to delete under this parent item/location name, ID, or ''none'''
            cand --type 'Select items to delete matching this entity type name or UUID'
            cand --filter-type 'Select items to delete matching this entity type name or UUID'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand -y 'Skip interactive/bulk confirmation prompt'
            cand --yes 'Skip interactive/bulk confirmation prompt'
            cand --force 'Skip interactive/bulk confirmation prompt'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;item;import'= {
            cand --format 'Input format (inferred from extension if omitted; defaults to json for stdin)'
            cand --match-by 'Match existing items by key in priority order: name, model, serial, or field:KEY (repeatable; defaults to name)'
            cand --match-mode 'Matching strategy for --match-by keys (exact, contains, fuzzy)'
            cand --parent 'Default parent item/location name, ID, or ''none'' for imported records without one'
            cand --attach 'Local file path(s) to attach to each imported item (`FILE` or `FILE=REMOTE_NAME`, repeatable)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --skip-existing 'Skip items whose name already exists in Homebox'
            cand --update-existing 'Update items whose name already exists in Homebox'
            cand --fill-missing 'With --update-existing, only populate blank/missing/zero fields on existing items'
            cand --optimize 'Automatically resize/compress oversized images before upload'
            cand --force 'Allow attaching images larger than 500KB'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;item;dedup'= {
            cand --threshold 'Jaccard similarity threshold for near-duplicate detection (0.0..=1.0)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --delete 'Delete detected duplicate items, retaining only the keeper'
            cand --merge 'Sum duplicate quantities onto the keeper before deleting duplicates (implies --delete)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;item;move'= {
            cand --to 'Target parent item name, ID, or ''none'' to unparent (required when using selectors without trailing positional parent)'
            cand --items-from 'Read newline-delimited entity IDs to move from a file or ''-'' (stdin)'
            cand --tag 'Select items to move matching this tag name or UUID'
            cand --filter-tag 'Select items to move matching this tag name or UUID'
            cand --parent 'Select items to move under this parent item/location name, ID, or ''none'''
            cand --filter-parent 'Select items to move under this parent item/location name, ID, or ''none'''
            cand --type 'Select items to move matching this entity type name or UUID'
            cand --filter-type 'Select items to move matching this entity type name or UUID'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;item;duplicate'= {
            cand --count 'Number of duplicates to create'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;item;path'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;item;tree'= {
            cand --root 'Optional root item name or ID to start the tree from'
            cand --max-depth 'Optional maximum depth to display (0 = roots only)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;item;help'= {
            cand list 'List inventory items'
            cand get 'Fetch a single item by ID'
            cand create 'Create a new item (auto-persists custom fields via follow-up PUT)'
            cand update 'Update an existing item via GET -> Merge -> PUT'
            cand upsert 'Create or update an item matched by name'
            cand delete 'Delete an item by ID'
            cand import 'Bulk import items from JSON or CSV (file or ''-'' for stdin)'
            cand dedup 'Detect (and optionally delete or merge) duplicate items'
            cand move 'Move an item under a parent item/location (or ''none'' to unparent)'
            cand duplicate 'Duplicate an existing item one or more times'
            cand path 'Display the location/parent breadcrumb path for an item'
            cand tree 'Render item parent/location hierarchy as a tree'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;item;help;list'= {
        }
        &'hbctl;item;help;get'= {
        }
        &'hbctl;item;help;create'= {
        }
        &'hbctl;item;help;update'= {
        }
        &'hbctl;item;help;upsert'= {
        }
        &'hbctl;item;help;delete'= {
        }
        &'hbctl;item;help;import'= {
        }
        &'hbctl;item;help;dedup'= {
        }
        &'hbctl;item;help;move'= {
        }
        &'hbctl;item;help;duplicate'= {
        }
        &'hbctl;item;help;path'= {
        }
        &'hbctl;item;help;tree'= {
        }
        &'hbctl;item;help;help'= {
        }
        &'hbctl;attachment'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
            cand upload 'Upload one or more files as item attachments'
            cand list 'List attachments on an item'
            cand download 'Stream-download attachments from one or multiple items'
            cand delete 'Delete an attachment from an item'
            cand set-primary 'Mark an existing attachment as the item''s primary photo'
            cand update 'Update attachment metadata (title, type, primary)'
            cand add-link 'Attach an external HTTP(S) URL link to an item'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;attachment;upload'= {
            cand --attach-url 'Remote HTTP(S) URL(s) to download and attach (`URL` or `URL=REMOTE_NAME`, repeatable)'
            cand --name 'Override remote filename/title (for single-file or stdin ''-'' uploads)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --primary 'Mark the uploaded attachment as the item''s primary photo'
            cand --skip-existing 'Skip files that already exist on the item (default behavior)'
            cand --overwrite 'Delete and re-upload files that already exist on the item'
            cand --optimize 'Automatically resize/compress oversized images before upload'
            cand --force 'Allow uploading images larger than 500KB'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;attachment;list'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;attachment;download'= {
            cand --tag 'Download matching attachments across items matching this tag name or UUID'
            cand --items-from 'Download matching attachments for newline-delimited entity IDs from a file or ''-'' (stdin)'
            cand --mime 'Filter attachments by MIME type (e.g. application/pdf)'
            cand --ext 'Filter attachments by file extension (e.g. pdf)'
            cand --out 'Output file path (single download) or directory (multi-download / --all / bulk)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --all 'Download all matching attachments on the item'
            cand --all-items 'Download matching attachments across all items'
            cand --overwrite 'Overwrite existing local files instead of skipping'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;attachment;delete'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;attachment;set-primary'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;attachment;update'= {
            cand --title 'Updated attachment title'
            cand --type 'Updated attachment type (e.g. photo, manual, warranty, receipt, attachment)'
            cand --primary 'Mark or unmark as the primary attachment (true/false; bare flag means true)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;attachment;add-link'= {
            cand --title 'Display title for the external link (defaults to sanitized URL)'
            cand --type 'Attachment type (photo, manual, warranty, receipt, attachment)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;attachment;help'= {
            cand upload 'Upload one or more files as item attachments'
            cand list 'List attachments on an item'
            cand download 'Stream-download attachments from one or multiple items'
            cand delete 'Delete an attachment from an item'
            cand set-primary 'Mark an existing attachment as the item''s primary photo'
            cand update 'Update attachment metadata (title, type, primary)'
            cand add-link 'Attach an external HTTP(S) URL link to an item'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;attachment;help;upload'= {
        }
        &'hbctl;attachment;help;list'= {
        }
        &'hbctl;attachment;help;download'= {
        }
        &'hbctl;attachment;help;delete'= {
        }
        &'hbctl;attachment;help;set-primary'= {
        }
        &'hbctl;attachment;help;update'= {
        }
        &'hbctl;attachment;help;add-link'= {
        }
        &'hbctl;attachment;help;help'= {
        }
        &'hbctl;search'= {
            cand --tag 'Filter by tag name or UUID'
            cand --type 'Filter by entity type name or UUID'
            cand --parent 'Filter by parent item name, ID, or ''none'' for top-level items'
            cand --limit 'Maximum number of matching results to return'
            cand --warranty-expiring 'Only include items with a warranty expiring within the next DAYS days (excludes lifetime warranties)'
            cand --model 'Filter by model number (exact or substring, case-insensitive)'
            cand --serial 'Filter by serial number (exact or substring, case-insensitive)'
            cand --manufacturer 'Filter by manufacturer (exact or substring, case-insensitive)'
            cand --field 'Filter by custom field existence (KEY) or substring value (KEY=VAL), case-insensitive (repeatable)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --include-archived 'Include archived items in search results'
            cand --archived-only 'Only search archived items (implies --include-archived)'
            cand --any 'Match items satisfying ANY provided filter (OR) instead of ALL filters (AND)'
            cand --with-path 'Include full location/parent breadcrumb path for each matching item'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;field'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
            cand list 'List all custom fields on an item'
            cand get 'Get a custom field value from an item'
            cand set 'Set a typed custom field on an item via GET -> Merge -> PUT'
            cand delete 'Delete a custom field from an item via GET -> Remove -> PUT'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;field;list'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;field;get'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;field;set'= {
            cand --type 'Custom field value type'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;field;delete'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;field;help'= {
            cand list 'List all custom fields on an item'
            cand get 'Get a custom field value from an item'
            cand set 'Set a typed custom field on an item via GET -> Merge -> PUT'
            cand delete 'Delete a custom field from an item via GET -> Remove -> PUT'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;field;help;list'= {
        }
        &'hbctl;field;help;get'= {
        }
        &'hbctl;field;help;set'= {
        }
        &'hbctl;field;help;delete'= {
        }
        &'hbctl;field;help;help'= {
        }
        &'hbctl;tag'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
            cand list 'List all tags'
            cand create 'Create a new tag'
            cand update 'Update an existing tag by ID'
            cand delete 'Delete a tag by ID'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;tag;list'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;tag;create'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;tag;update'= {
            cand --name 'Updated tag name'
            cand --description 'Updated tag description'
            cand --color 'Updated tag hex color'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;tag;delete'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --force 'Skip interactive confirmation prompt'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;tag;help'= {
            cand list 'List all tags'
            cand create 'Create a new tag'
            cand update 'Update an existing tag by ID'
            cand delete 'Delete a tag by ID'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;tag;help;list'= {
        }
        &'hbctl;tag;help;create'= {
        }
        &'hbctl;tag;help;update'= {
        }
        &'hbctl;tag;help;delete'= {
        }
        &'hbctl;tag;help;help'= {
        }
        &'hbctl;entity-types'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
            cand list 'List all entity types'
            cand create 'Create a new entity type'
            cand delete 'Delete an entity type by ID'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;entity-type'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
            cand list 'List all entity types'
            cand create 'Create a new entity type'
            cand delete 'Delete an entity type by ID'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;entity-types;list'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;entity-type;list'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;entity-types;create'= {
            cand --description 'Optional description'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --is-location 'Mark this entity type as a location/container'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;entity-type;create'= {
            cand --description 'Optional description'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --is-location 'Mark this entity type as a location/container'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;entity-types;delete'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --force 'Skip interactive confirmation prompt'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;entity-type;delete'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --force 'Skip interactive confirmation prompt'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;entity-types;help'= {
            cand list 'List all entity types'
            cand create 'Create a new entity type'
            cand delete 'Delete an entity type by ID'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;entity-types;help;list'= {
        }
        &'hbctl;entity-types;help;create'= {
        }
        &'hbctl;entity-types;help;delete'= {
        }
        &'hbctl;entity-types;help;help'= {
        }
        &'hbctl;entity-type;help'= {
            cand list 'List all entity types'
            cand create 'Create a new entity type'
            cand delete 'Delete an entity type by ID'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;entity-type;help;list'= {
        }
        &'hbctl;entity-type;help;create'= {
        }
        &'hbctl;entity-type;help;delete'= {
        }
        &'hbctl;entity-type;help;help'= {
        }
        &'hbctl;status'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;api'= {
            cand -d 'Inline JSON request body'
            cand --data 'Inline JSON request body'
            cand --from-json 'Read JSON request body from a file path or ''-'' for stdin'
            cand --query 'Query parameter KEY=VALUE (repeatable; appended to any inline path query)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;maintenance'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
            cand list 'List maintenance log entries (globally or for a specific entity)'
            cand create 'Create a maintenance log entry on an entity'
            cand update 'Update an existing maintenance log entry by entry ID'
            cand delete 'Delete a maintenance log entry by entry ID'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;maintenance;list'= {
            cand --status 'Filter by maintenance status (both, completed, scheduled)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;maintenance;create'= {
            cand --name 'Maintenance task/entry name'
            cand --completed-date 'Completion date (YYYY-MM-DD or YYYY-MM)'
            cand --scheduled-date 'Scheduled date (YYYY-MM-DD or YYYY-MM)'
            cand --cost 'Maintenance cost (e.g. 29.99 or $29.99)'
            cand --description 'Maintenance description or notes'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;maintenance;update'= {
            cand --name 'Updated maintenance task/entry name'
            cand --completed-date 'Updated completion date (YYYY-MM-DD or YYYY-MM)'
            cand --scheduled-date 'Updated scheduled date (YYYY-MM-DD or YYYY-MM)'
            cand --cost 'Updated maintenance cost (e.g. 29.99 or $29.99)'
            cand --description 'Updated maintenance description or notes'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;maintenance;delete'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --force 'Skip interactive confirmation prompt'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;maintenance;help'= {
            cand list 'List maintenance log entries (globally or for a specific entity)'
            cand create 'Create a maintenance log entry on an entity'
            cand update 'Update an existing maintenance log entry by entry ID'
            cand delete 'Delete a maintenance log entry by entry ID'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;maintenance;help;list'= {
        }
        &'hbctl;maintenance;help;create'= {
        }
        &'hbctl;maintenance;help;update'= {
        }
        &'hbctl;maintenance;help;delete'= {
        }
        &'hbctl;maintenance;help;help'= {
        }
        &'hbctl;export'= {
            cand --tag 'Filter by tag name or UUID'
            cand --has-field 'Require items to have the named custom field'
            cand --field 'Custom field column(s) to include in export (repeatable)'
            cand --sort 'Sort exported items (name, id, purchase-price, purchase-date, updated-at, asset-id)'
            cand --format 'Export format (json, csv, markdown)'
            cand --columns 'Custom column list and order (comma-separated or repeatable; supports ''key=Header Alias'')'
            cand --align 'Markdown table column alignment (default, left, right, center)'
            cand --empty 'Placeholder string for empty/missing cells'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;backup'= {
            cand -o 'Destination directory or .tar.gz / .tgz archive path'
            cand --out 'Destination directory or .tar.gz / .tgz archive path'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --no-attachments 'Skip downloading attachment binary files (attachment metadata stays in entities.json)'
            cand --exclude-archived 'Exclude archived items from the backup (archived items are included by default)'
            cand --overwrite 'Overwrite an existing archive file or write into a non-empty directory'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;label'= {
            cand -o 'Output file path, or ''-'' to write raw label bytes to stdout'
            cand --out 'Output file path, or ''-'' to write raw label bytes to stdout'
            cand --kind 'Target label endpoint kind (auto detects numeric/dashed asset IDs)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --print 'Send the label directly to the server''s configured printer (?print=true)'
            cand --overwrite 'Overwrite output file if it already exists'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;qr'= {
            cand -o 'Output file path, or ''-'' to write raw QR image bytes to stdout'
            cand --out 'Output file path, or ''-'' to write raw QR image bytes to stdout'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --raw 'Encode <ID> verbatim as QR `data` instead of building a Homebox item/asset URL'
            cand --overwrite 'Overwrite output file if it already exists'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;actions'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
            cand ensure-asset-ids 'Ensure all items in Homebox have an asset ID assigned (/api/v1/actions/ensure-asset-ids)'
            cand create-missing-thumbnails 'Create thumbnails for attachments missing them (/api/v1/actions/create-missing-thumbnails)'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;action'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
            cand ensure-asset-ids 'Ensure all items in Homebox have an asset ID assigned (/api/v1/actions/ensure-asset-ids)'
            cand create-missing-thumbnails 'Create thumbnails for attachments missing them (/api/v1/actions/create-missing-thumbnails)'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;actions;ensure-asset-ids'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;action;ensure-asset-ids'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;actions;create-missing-thumbnails'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;action;create-missing-thumbnails'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;actions;help'= {
            cand ensure-asset-ids 'Ensure all items in Homebox have an asset ID assigned (/api/v1/actions/ensure-asset-ids)'
            cand create-missing-thumbnails 'Create thumbnails for attachments missing them (/api/v1/actions/create-missing-thumbnails)'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;actions;help;ensure-asset-ids'= {
        }
        &'hbctl;actions;help;create-missing-thumbnails'= {
        }
        &'hbctl;actions;help;help'= {
        }
        &'hbctl;action;help'= {
            cand ensure-asset-ids 'Ensure all items in Homebox have an asset ID assigned (/api/v1/actions/ensure-asset-ids)'
            cand create-missing-thumbnails 'Create thumbnails for attachments missing them (/api/v1/actions/create-missing-thumbnails)'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;action;help;ensure-asset-ids'= {
        }
        &'hbctl;action;help;create-missing-thumbnails'= {
        }
        &'hbctl;action;help;help'= {
        }
        &'hbctl;stats'= {
            cand --warranty-days 'Also count non-lifetime warranties expiring within DAYS days'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
            cand overview 'Group-wide overview statistics (/api/v1/groups/statistics + upcoming maintenance)'
            cand tags 'Tag purchase-value breakdown (/api/v1/groups/statistics/tags)'
            cand locations 'Location purchase-value breakdown (/api/v1/groups/statistics/locations)'
            cand entity-types 'Entity-type count and purchase-value breakdown'
            cand types 'Entity-type count and purchase-value breakdown'
            cand purchase-price 'Purchase value over time (/api/v1/groups/statistics/purchase-price)'
            cand price 'Purchase value over time (/api/v1/groups/statistics/purchase-price)'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;stats;overview'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;stats;tags'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;stats;locations'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;stats;entity-types'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;stats;types'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;stats;purchase-price'= {
            cand --start 'Start date (YYYY-MM-DD)'
            cand --end 'End date (YYYY-MM-DD)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;stats;price'= {
            cand --start 'Start date (YYYY-MM-DD)'
            cand --end 'End date (YYYY-MM-DD)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;stats;help'= {
            cand overview 'Group-wide overview statistics (/api/v1/groups/statistics + upcoming maintenance)'
            cand tags 'Tag purchase-value breakdown (/api/v1/groups/statistics/tags)'
            cand locations 'Location purchase-value breakdown (/api/v1/groups/statistics/locations)'
            cand entity-types 'Entity-type count and purchase-value breakdown'
            cand purchase-price 'Purchase value over time (/api/v1/groups/statistics/purchase-price)'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;stats;help;overview'= {
        }
        &'hbctl;stats;help;tags'= {
        }
        &'hbctl;stats;help;locations'= {
        }
        &'hbctl;stats;help;entity-types'= {
        }
        &'hbctl;stats;help;purchase-price'= {
        }
        &'hbctl;stats;help;help'= {
        }
        &'hbctl;config'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
            cand show 'Display effective resolved configuration (secrets redacted as Bearer ***)'
            cand profiles 'List configured profiles and indicate active/default selection'
            cand use 'Switch the active default profile in user config'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;config;show'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;config;profiles'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;config;use'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;config;help'= {
            cand show 'Display effective resolved configuration (secrets redacted as Bearer ***)'
            cand profiles 'List configured profiles and indicate active/default selection'
            cand use 'Switch the active default profile in user config'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;config;help;show'= {
        }
        &'hbctl;config;help;profiles'= {
        }
        &'hbctl;config;help;use'= {
        }
        &'hbctl;config;help;help'= {
        }
        &'hbctl;template'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
            cand list 'List all entity templates'
            cand get 'Fetch a single entity template by ID'
            cand create 'Create a new entity template'
            cand update 'Update an existing entity template (GET -> Merge -> PUT)'
            cand delete 'Delete an entity template'
            cand apply 'Create a new item from a template (/api/v1/templates/{id}/create-item)'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;templates'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
            cand list 'List all entity templates'
            cand get 'Fetch a single entity template by ID'
            cand create 'Create a new entity template'
            cand update 'Update an existing entity template (GET -> Merge -> PUT)'
            cand delete 'Delete an entity template'
            cand apply 'Create a new item from a template (/api/v1/templates/{id}/create-item)'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;template;list'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;templates;list'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;template;get'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;templates;get'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;template;create'= {
            cand --name 'Template name'
            cand --description 'Template description'
            cand --notes 'Template notes'
            cand --default-name 'Default item name'
            cand --default-description 'Default item description'
            cand --default-quantity 'Default item quantity'
            cand --default-manufacturer 'Default item manufacturer'
            cand --default-model 'Default item model number'
            cand --default-insured 'Default insured flag (true/false; bare flag means true)'
            cand --default-lifetime-warranty 'Default lifetime warranty flag (true/false; bare flag means true)'
            cand --default-warranty-details 'Default warranty details'
            cand --default-location 'Default location name or UUID'
            cand --default-tag 'Default tag name or UUID (repeatable; missing tags auto-created)'
            cand --include-warranty-fields 'Include warranty fields on created items (true/false; bare flag means true)'
            cand --include-purchase-fields 'Include purchase fields on created items (true/false; bare flag means true)'
            cand --include-sold-fields 'Include sold fields on created items (true/false; bare flag means true)'
            cand --field 'Default custom field KEY=VAL (repeatable)'
            cand --field-type 'Value type for --field entries'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;templates;create'= {
            cand --name 'Template name'
            cand --description 'Template description'
            cand --notes 'Template notes'
            cand --default-name 'Default item name'
            cand --default-description 'Default item description'
            cand --default-quantity 'Default item quantity'
            cand --default-manufacturer 'Default item manufacturer'
            cand --default-model 'Default item model number'
            cand --default-insured 'Default insured flag (true/false; bare flag means true)'
            cand --default-lifetime-warranty 'Default lifetime warranty flag (true/false; bare flag means true)'
            cand --default-warranty-details 'Default warranty details'
            cand --default-location 'Default location name or UUID'
            cand --default-tag 'Default tag name or UUID (repeatable; missing tags auto-created)'
            cand --include-warranty-fields 'Include warranty fields on created items (true/false; bare flag means true)'
            cand --include-purchase-fields 'Include purchase fields on created items (true/false; bare flag means true)'
            cand --include-sold-fields 'Include sold fields on created items (true/false; bare flag means true)'
            cand --field 'Default custom field KEY=VAL (repeatable)'
            cand --field-type 'Value type for --field entries'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;template;update'= {
            cand --name 'Updated template name'
            cand --description 'Updated template description'
            cand --notes 'Updated template notes'
            cand --default-name 'Updated default item name'
            cand --default-description 'Updated default item description'
            cand --default-quantity 'Updated default item quantity'
            cand --default-manufacturer 'Updated default item manufacturer'
            cand --default-model 'Updated default item model number'
            cand --default-insured 'Updated default insured flag (true/false; bare flag means true)'
            cand --default-lifetime-warranty 'Updated default lifetime warranty flag (true/false; bare flag means true)'
            cand --default-warranty-details 'Updated default warranty details'
            cand --default-location 'Updated default location name, UUID, or ''none'''
            cand --default-tag 'Updated default tag name or UUID (repeatable; replaces tag list)'
            cand --include-warranty-fields 'Include warranty fields on created items (true/false; bare flag means true)'
            cand --include-purchase-fields 'Include purchase fields on created items (true/false; bare flag means true)'
            cand --include-sold-fields 'Include sold fields on created items (true/false; bare flag means true)'
            cand --field 'Default custom field KEY=VAL to add/update (repeatable)'
            cand --field-type 'Value type for --field entries'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;templates;update'= {
            cand --name 'Updated template name'
            cand --description 'Updated template description'
            cand --notes 'Updated template notes'
            cand --default-name 'Updated default item name'
            cand --default-description 'Updated default item description'
            cand --default-quantity 'Updated default item quantity'
            cand --default-manufacturer 'Updated default item manufacturer'
            cand --default-model 'Updated default item model number'
            cand --default-insured 'Updated default insured flag (true/false; bare flag means true)'
            cand --default-lifetime-warranty 'Updated default lifetime warranty flag (true/false; bare flag means true)'
            cand --default-warranty-details 'Updated default warranty details'
            cand --default-location 'Updated default location name, UUID, or ''none'''
            cand --default-tag 'Updated default tag name or UUID (repeatable; replaces tag list)'
            cand --include-warranty-fields 'Include warranty fields on created items (true/false; bare flag means true)'
            cand --include-purchase-fields 'Include purchase fields on created items (true/false; bare flag means true)'
            cand --include-sold-fields 'Include sold fields on created items (true/false; bare flag means true)'
            cand --field 'Default custom field KEY=VAL to add/update (repeatable)'
            cand --field-type 'Value type for --field entries'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;template;delete'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand -y 'Skip interactive confirmation prompt'
            cand --yes 'Skip interactive confirmation prompt'
            cand --force 'Skip interactive confirmation prompt'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;templates;delete'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand -y 'Skip interactive confirmation prompt'
            cand --yes 'Skip interactive confirmation prompt'
            cand --force 'Skip interactive confirmation prompt'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;template;apply'= {
            cand --name 'Item name (defaults to template''s defaultName if omitted)'
            cand --description 'Item description (defaults to template''s defaultDescription if omitted)'
            cand --parent 'Parent item/location name, ID, or ''none'''
            cand --location 'Location name or ID (falls back to template''s defaultLocation if omitted)'
            cand --type 'Entity type name or UUID'
            cand --tag 'Tag name or UUID (repeatable; defaults to template''s defaultTags if omitted)'
            cand --quantity 'Item quantity override'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;templates;apply'= {
            cand --name 'Item name (defaults to template''s defaultName if omitted)'
            cand --description 'Item description (defaults to template''s defaultDescription if omitted)'
            cand --parent 'Parent item/location name, ID, or ''none'''
            cand --location 'Location name or ID (falls back to template''s defaultLocation if omitted)'
            cand --type 'Entity type name or UUID'
            cand --tag 'Tag name or UUID (repeatable; defaults to template''s defaultTags if omitted)'
            cand --quantity 'Item quantity override'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;template;help'= {
            cand list 'List all entity templates'
            cand get 'Fetch a single entity template by ID'
            cand create 'Create a new entity template'
            cand update 'Update an existing entity template (GET -> Merge -> PUT)'
            cand delete 'Delete an entity template'
            cand apply 'Create a new item from a template (/api/v1/templates/{id}/create-item)'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;template;help;list'= {
        }
        &'hbctl;template;help;get'= {
        }
        &'hbctl;template;help;create'= {
        }
        &'hbctl;template;help;update'= {
        }
        &'hbctl;template;help;delete'= {
        }
        &'hbctl;template;help;apply'= {
        }
        &'hbctl;template;help;help'= {
        }
        &'hbctl;templates;help'= {
            cand list 'List all entity templates'
            cand get 'Fetch a single entity template by ID'
            cand create 'Create a new entity template'
            cand update 'Update an existing entity template (GET -> Merge -> PUT)'
            cand delete 'Delete an entity template'
            cand apply 'Create a new item from a template (/api/v1/templates/{id}/create-item)'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;templates;help;list'= {
        }
        &'hbctl;templates;help;get'= {
        }
        &'hbctl;templates;help;create'= {
        }
        &'hbctl;templates;help;update'= {
        }
        &'hbctl;templates;help;delete'= {
        }
        &'hbctl;templates;help;apply'= {
        }
        &'hbctl;templates;help;help'= {
        }
        &'hbctl;barcode'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;notifier'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
            cand list 'List configured notifiers (URLs redacted unless --reveal is passed)'
            cand create 'Create a new notifier'
            cand update 'Update an existing notifier'
            cand delete 'Delete a notifier'
            cand test 'Send a test notification to a notifier ID/name or Shoutrrr URL'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;notifiers'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
            cand list 'List configured notifiers (URLs redacted unless --reveal is passed)'
            cand create 'Create a new notifier'
            cand update 'Update an existing notifier'
            cand delete 'Delete a notifier'
            cand test 'Send a test notification to a notifier ID/name or Shoutrrr URL'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;notifier;list'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --reveal 'Display unredacted notifier URLs'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;notifiers;list'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --reveal 'Display unredacted notifier URLs'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;notifier;create'= {
            cand --name 'Notifier display name'
            cand --notifier-url 'Shoutrrr destination URL'
            cand --target 'Shoutrrr destination URL'
            cand --active 'Whether the notifier is active (true/false; bare flag means true, defaults to true)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;notifiers;create'= {
            cand --name 'Notifier display name'
            cand --notifier-url 'Shoutrrr destination URL'
            cand --target 'Shoutrrr destination URL'
            cand --active 'Whether the notifier is active (true/false; bare flag means true, defaults to true)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;notifier;update'= {
            cand --name 'Updated notifier name'
            cand --notifier-url 'Updated Shoutrrr destination URL'
            cand --target 'Updated Shoutrrr destination URL'
            cand --active 'Updated active state (true/false; bare flag means true)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;notifiers;update'= {
            cand --name 'Updated notifier name'
            cand --notifier-url 'Updated Shoutrrr destination URL'
            cand --target 'Updated Shoutrrr destination URL'
            cand --active 'Updated active state (true/false; bare flag means true)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;notifier;delete'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand -y 'Skip interactive confirmation prompt'
            cand --yes 'Skip interactive confirmation prompt'
            cand --force 'Skip interactive confirmation prompt'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;notifiers;delete'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand -y 'Skip interactive confirmation prompt'
            cand --yes 'Skip interactive confirmation prompt'
            cand --force 'Skip interactive confirmation prompt'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;notifier;test'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;notifiers;test'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;notifier;help'= {
            cand list 'List configured notifiers (URLs redacted unless --reveal is passed)'
            cand create 'Create a new notifier'
            cand update 'Update an existing notifier'
            cand delete 'Delete a notifier'
            cand test 'Send a test notification to a notifier ID/name or Shoutrrr URL'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;notifier;help;list'= {
        }
        &'hbctl;notifier;help;create'= {
        }
        &'hbctl;notifier;help;update'= {
        }
        &'hbctl;notifier;help;delete'= {
        }
        &'hbctl;notifier;help;test'= {
        }
        &'hbctl;notifier;help;help'= {
        }
        &'hbctl;notifiers;help'= {
            cand list 'List configured notifiers (URLs redacted unless --reveal is passed)'
            cand create 'Create a new notifier'
            cand update 'Update an existing notifier'
            cand delete 'Delete a notifier'
            cand test 'Send a test notification to a notifier ID/name or Shoutrrr URL'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;notifiers;help;list'= {
        }
        &'hbctl;notifiers;help;create'= {
        }
        &'hbctl;notifiers;help;update'= {
        }
        &'hbctl;notifiers;help;delete'= {
        }
        &'hbctl;notifiers;help;test'= {
        }
        &'hbctl;notifiers;help;help'= {
        }
        &'hbctl;completions'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;man'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;update'= {
            cand --version 'Target a specific release version or tag (e.g. 0.1.0 or v0.1.0)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --check 'Check for available updates without installing'
            cand -y 'Skip confirmation prompt before installing'
            cand --yes 'Skip confirmation prompt before installing'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;self-update'= {
            cand --version 'Target a specific release version or tag (e.g. 0.1.0 or v0.1.0)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --check 'Check for available updates without installing'
            cand -y 'Skip confirmation prompt before installing'
            cand --yes 'Skip confirmation prompt before installing'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand --asset-id 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;help'= {
            cand auth 'Authenticate with a remote Homebox instance (login, status, logout, refresh)'
            cand item 'Manage inventory items (/api/v1/entities)'
            cand attachment 'Manage item attachments (/api/v1/entities/{id}/attachments)'
            cand search 'Full-text and structured item search'
            cand field 'List, get, set, or delete typed custom fields on an item'
            cand tag 'Manage tags (/api/v1/tags)'
            cand entity-types 'Manage Homebox entity types (/api/v1/entity-types)'
            cand status 'Check remote Homebox server connectivity and version (/api/v1/status)'
            cand api 'Issue a raw authenticated HTTP request against any Homebox API endpoint'
            cand maintenance 'Manage maintenance log entries (/api/v1/maintenance)'
            cand export 'Export filtered items to JSON, CSV, or Markdown'
            cand backup 'Create a portable full-inventory backup (directory or .tar.gz archive)'
            cand label 'Generate or print a Homebox item, asset, or location label (/api/v1/labelmaker)'
            cand qr 'Generate a QR code image (/api/v1/qrcode)'
            cand actions 'Run Homebox server maintenance actions (/api/v1/actions/*)'
            cand stats 'Display inventory statistics and breakdowns (/api/v1/groups/statistics*)'
            cand config 'Inspect effective configuration and manage named profiles'
            cand template 'Manage item templates and create items from templates (/api/v1/templates)'
            cand barcode 'Look up product metadata by barcode (/api/v1/products/search-from-barcode)'
            cand notifier 'Manage Shoutrrr notification channels (/api/v1/notifiers)'
            cand completions 'Generate shell completion scripts'
            cand man 'Generate UNIX roff man page'
            cand update 'Check for and install the latest hbctl release from GitHub'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;help;auth'= {
            cand login 'Authenticate with Homebox via API key (--with-token) or email/password'
            cand status 'Check authentication status and validate the active session'
            cand logout 'Remove stored credentials from OS keyring and local fallback store'
            cand refresh 'Refresh an active JWT session token'
        }
        &'hbctl;help;auth;login'= {
        }
        &'hbctl;help;auth;status'= {
        }
        &'hbctl;help;auth;logout'= {
        }
        &'hbctl;help;auth;refresh'= {
        }
        &'hbctl;help;item'= {
            cand list 'List inventory items'
            cand get 'Fetch a single item by ID'
            cand create 'Create a new item (auto-persists custom fields via follow-up PUT)'
            cand update 'Update an existing item via GET -> Merge -> PUT'
            cand upsert 'Create or update an item matched by name'
            cand delete 'Delete an item by ID'
            cand import 'Bulk import items from JSON or CSV (file or ''-'' for stdin)'
            cand dedup 'Detect (and optionally delete or merge) duplicate items'
            cand move 'Move an item under a parent item/location (or ''none'' to unparent)'
            cand duplicate 'Duplicate an existing item one or more times'
            cand path 'Display the location/parent breadcrumb path for an item'
            cand tree 'Render item parent/location hierarchy as a tree'
        }
        &'hbctl;help;item;list'= {
        }
        &'hbctl;help;item;get'= {
        }
        &'hbctl;help;item;create'= {
        }
        &'hbctl;help;item;update'= {
        }
        &'hbctl;help;item;upsert'= {
        }
        &'hbctl;help;item;delete'= {
        }
        &'hbctl;help;item;import'= {
        }
        &'hbctl;help;item;dedup'= {
        }
        &'hbctl;help;item;move'= {
        }
        &'hbctl;help;item;duplicate'= {
        }
        &'hbctl;help;item;path'= {
        }
        &'hbctl;help;item;tree'= {
        }
        &'hbctl;help;attachment'= {
            cand upload 'Upload one or more files as item attachments'
            cand list 'List attachments on an item'
            cand download 'Stream-download attachments from one or multiple items'
            cand delete 'Delete an attachment from an item'
            cand set-primary 'Mark an existing attachment as the item''s primary photo'
            cand update 'Update attachment metadata (title, type, primary)'
            cand add-link 'Attach an external HTTP(S) URL link to an item'
        }
        &'hbctl;help;attachment;upload'= {
        }
        &'hbctl;help;attachment;list'= {
        }
        &'hbctl;help;attachment;download'= {
        }
        &'hbctl;help;attachment;delete'= {
        }
        &'hbctl;help;attachment;set-primary'= {
        }
        &'hbctl;help;attachment;update'= {
        }
        &'hbctl;help;attachment;add-link'= {
        }
        &'hbctl;help;search'= {
        }
        &'hbctl;help;field'= {
            cand list 'List all custom fields on an item'
            cand get 'Get a custom field value from an item'
            cand set 'Set a typed custom field on an item via GET -> Merge -> PUT'
            cand delete 'Delete a custom field from an item via GET -> Remove -> PUT'
        }
        &'hbctl;help;field;list'= {
        }
        &'hbctl;help;field;get'= {
        }
        &'hbctl;help;field;set'= {
        }
        &'hbctl;help;field;delete'= {
        }
        &'hbctl;help;tag'= {
            cand list 'List all tags'
            cand create 'Create a new tag'
            cand update 'Update an existing tag by ID'
            cand delete 'Delete a tag by ID'
        }
        &'hbctl;help;tag;list'= {
        }
        &'hbctl;help;tag;create'= {
        }
        &'hbctl;help;tag;update'= {
        }
        &'hbctl;help;tag;delete'= {
        }
        &'hbctl;help;entity-types'= {
            cand list 'List all entity types'
            cand create 'Create a new entity type'
            cand delete 'Delete an entity type by ID'
        }
        &'hbctl;help;entity-types;list'= {
        }
        &'hbctl;help;entity-types;create'= {
        }
        &'hbctl;help;entity-types;delete'= {
        }
        &'hbctl;help;status'= {
        }
        &'hbctl;help;api'= {
        }
        &'hbctl;help;maintenance'= {
            cand list 'List maintenance log entries (globally or for a specific entity)'
            cand create 'Create a maintenance log entry on an entity'
            cand update 'Update an existing maintenance log entry by entry ID'
            cand delete 'Delete a maintenance log entry by entry ID'
        }
        &'hbctl;help;maintenance;list'= {
        }
        &'hbctl;help;maintenance;create'= {
        }
        &'hbctl;help;maintenance;update'= {
        }
        &'hbctl;help;maintenance;delete'= {
        }
        &'hbctl;help;export'= {
        }
        &'hbctl;help;backup'= {
        }
        &'hbctl;help;label'= {
        }
        &'hbctl;help;qr'= {
        }
        &'hbctl;help;actions'= {
            cand ensure-asset-ids 'Ensure all items in Homebox have an asset ID assigned (/api/v1/actions/ensure-asset-ids)'
            cand create-missing-thumbnails 'Create thumbnails for attachments missing them (/api/v1/actions/create-missing-thumbnails)'
        }
        &'hbctl;help;actions;ensure-asset-ids'= {
        }
        &'hbctl;help;actions;create-missing-thumbnails'= {
        }
        &'hbctl;help;stats'= {
            cand overview 'Group-wide overview statistics (/api/v1/groups/statistics + upcoming maintenance)'
            cand tags 'Tag purchase-value breakdown (/api/v1/groups/statistics/tags)'
            cand locations 'Location purchase-value breakdown (/api/v1/groups/statistics/locations)'
            cand entity-types 'Entity-type count and purchase-value breakdown'
            cand purchase-price 'Purchase value over time (/api/v1/groups/statistics/purchase-price)'
        }
        &'hbctl;help;stats;overview'= {
        }
        &'hbctl;help;stats;tags'= {
        }
        &'hbctl;help;stats;locations'= {
        }
        &'hbctl;help;stats;entity-types'= {
        }
        &'hbctl;help;stats;purchase-price'= {
        }
        &'hbctl;help;config'= {
            cand show 'Display effective resolved configuration (secrets redacted as Bearer ***)'
            cand profiles 'List configured profiles and indicate active/default selection'
            cand use 'Switch the active default profile in user config'
        }
        &'hbctl;help;config;show'= {
        }
        &'hbctl;help;config;profiles'= {
        }
        &'hbctl;help;config;use'= {
        }
        &'hbctl;help;template'= {
            cand list 'List all entity templates'
            cand get 'Fetch a single entity template by ID'
            cand create 'Create a new entity template'
            cand update 'Update an existing entity template (GET -> Merge -> PUT)'
            cand delete 'Delete an entity template'
            cand apply 'Create a new item from a template (/api/v1/templates/{id}/create-item)'
        }
        &'hbctl;help;template;list'= {
        }
        &'hbctl;help;template;get'= {
        }
        &'hbctl;help;template;create'= {
        }
        &'hbctl;help;template;update'= {
        }
        &'hbctl;help;template;delete'= {
        }
        &'hbctl;help;template;apply'= {
        }
        &'hbctl;help;barcode'= {
        }
        &'hbctl;help;notifier'= {
            cand list 'List configured notifiers (URLs redacted unless --reveal is passed)'
            cand create 'Create a new notifier'
            cand update 'Update an existing notifier'
            cand delete 'Delete a notifier'
            cand test 'Send a test notification to a notifier ID/name or Shoutrrr URL'
        }
        &'hbctl;help;notifier;list'= {
        }
        &'hbctl;help;notifier;create'= {
        }
        &'hbctl;help;notifier;update'= {
        }
        &'hbctl;help;notifier;delete'= {
        }
        &'hbctl;help;notifier;test'= {
        }
        &'hbctl;help;completions'= {
        }
        &'hbctl;help;man'= {
        }
        &'hbctl;help;update'= {
        }
        &'hbctl;help;help'= {
        }
    ]
    $completions[$command]
}
