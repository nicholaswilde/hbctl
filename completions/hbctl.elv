
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
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
            cand completions 'Generate shell completion scripts'
            cand man 'Generate UNIX roff man page'
            cand update 'Check for and install the latest hbctl release from GitHub'
            cand self-update 'Check for and install the latest hbctl release from GitHub'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;auth'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;auth;status'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;auth;logout'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;auth;refresh'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;item;get'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;item;create'= {
            cand --name 'Item name (required unless supplied via --from-json)'
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
            cand --attach 'Local file path(s) to attach after creating the item (`FILE` or `FILE=REMOTE_NAME`, repeatable)'
            cand --attach-url 'Remote HTTP(S) URL(s) to download and attach (`URL` or `URL=REMOTE_NAME`, repeatable)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;item;dedup'= {
            cand --threshold 'Jaccard similarity threshold for near-duplicate detection (0.0..=1.0)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;item;duplicate'= {
            cand --count 'Number of duplicates to create'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;item;path'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;item;tree'= {
            cand --root 'Optional root item name or ID to start the tree from'
            cand --max-depth 'Optional maximum depth to display (0 = roots only)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
            cand upload 'Upload one or more files as item attachments'
            cand list 'List attachments on an item'
            cand download 'Stream-download attachments from one or multiple items'
            cand delete 'Delete an attachment from an item'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbctl;attachment;upload'= {
            cand --attach-url 'Remote HTTP(S) URL(s) to download and attach (`URL` or `URL=REMOTE_NAME`, repeatable)'
            cand --name 'Override remote filename/title (for single-file or stdin ''-'' uploads)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --skip-existing 'Skip files that already exist on the item (default behavior)'
            cand --overwrite 'Delete and re-upload files that already exist on the item'
            cand --optimize 'Automatically resize/compress oversized images before upload'
            cand --force 'Allow uploading images larger than 500KB'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;attachment;list'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;attachment;delete'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;attachment;help'= {
            cand upload 'Upload one or more files as item attachments'
            cand list 'List attachments on an item'
            cand download 'Stream-download attachments from one or multiple items'
            cand delete 'Delete an attachment from an item'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;field'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;field;get'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;field;set'= {
            cand --type 'Custom field value type'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;field;delete'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;tag;create'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;tag;update'= {
            cand --name 'Updated tag name'
            cand --description 'Updated tag description'
            cand --color 'Updated tag hex color'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;tag;delete'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;entity-type;list'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;entity-types;create'= {
            cand --description 'Optional description'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;entity-type;create'= {
            cand --description 'Optional description'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;entity-types;delete'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;entity-type;delete'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;maintenance'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;maintenance;delete'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;completions'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;man'= {
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand -P 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --profile 'Named configuration profile (env: HBCTL_PROFILE)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;update'= {
            cand --version 'Target a specific release version or tag (e.g. 0.1.0 or v0.1.0)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbctl;self-update'= {
            cand --version 'Target a specific release version or tag (e.g. 0.1.0 or v0.1.0)'
            cand --url 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBCTL_OUTPUT]'
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
        }
        &'hbctl;help;attachment;upload'= {
        }
        &'hbctl;help;attachment;list'= {
        }
        &'hbctl;help;attachment;download'= {
        }
        &'hbctl;help;attachment;delete'= {
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
