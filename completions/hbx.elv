
use builtin;
use str;

set edit:completion:arg-completer[hbx] = {|@words|
    fn spaces {|n|
        builtin:repeat $n ' ' | str:join ''
    }
    fn cand {|text desc|
        edit:complex-candidate $text &display=$text' '(spaces (- 14 (wcswidth $text)))$desc
    }
    var command = 'hbx'
    for word $words[1..-1] {
        if (str:has-prefix $word '-') {
            break
        }
        set command = $command';'$word
    }
    var completions = [
        &'hbx'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
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
            cand field 'Get or set typed custom fields on an item'
            cand tag 'Manage tags (/api/v1/tags)'
            cand entity-types 'List Homebox entity types (/api/v1/entity-types)'
            cand entity-type 'List Homebox entity types (/api/v1/entity-types)'
            cand export 'Export filtered items to JSON, CSV, or Markdown'
            cand completions 'Generate shell completion scripts'
            cand man 'Generate UNIX roff man page'
            cand update 'Check for and install the latest hbx release from GitHub'
            cand self-update 'Check for and install the latest hbx release from GitHub'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbx;auth'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
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
        &'hbx;auth;login'= {
            cand -u 'Email or username for password login (POST /api/v1/users/login)'
            cand --username 'Email or username for password login (POST /api/v1/users/login)'
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
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
        &'hbx;auth;status'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;auth;logout'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --insecure-storage 'Skip OS keyring and only clear local 0600 fallback store'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;auth;refresh'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --insecure-storage 'Store refreshed token in 0600 local file store instead of OS keyring'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;auth;help'= {
            cand login 'Authenticate with Homebox via API key (--with-token) or email/password'
            cand status 'Check authentication status and validate the active session'
            cand logout 'Remove stored credentials from OS keyring and local fallback store'
            cand refresh 'Refresh an active JWT session token'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbx;auth;help;login'= {
        }
        &'hbx;auth;help;status'= {
        }
        &'hbx;auth;help;logout'= {
        }
        &'hbx;auth;help;refresh'= {
        }
        &'hbx;auth;help;help'= {
        }
        &'hbx;item'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
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
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbx;item;list'= {
            cand --tag 'Filter by tag name or UUID'
            cand --type 'Filter by entity type name or UUID'
            cand --has-field 'Only include items having the named custom field (hydrates details if missing)'
            cand --page-size 'Page size for listing'
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --all 'Fetch all pages'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;item;get'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;item;create'= {
            cand --name 'Item name (required unless supplied via --from-json)'
            cand --description 'Item description'
            cand --type 'Entity type name or UUID'
            cand --tag 'Tag name or UUID (repeatable; missing tags auto-created)'
            cand --manufacturer 'Manufacturer (normalized into custom field ''Manufacturer'')'
            cand --model 'Model number (normalized into custom field ''Model Number'')'
            cand --notes 'Notes (normalized into custom field ''Notes'')'
            cand --quantity 'Item quantity'
            cand --purchase-price 'Purchase price'
            cand --purchase-date 'Purchase date (YYYY-MM-DD)'
            cand --purchase-from 'Purchase vendor/source'
            cand --field 'Custom field KEY=VAL (repeatable)'
            cand --field-type 'Value type for --field entries'
            cand --from-json 'Load initial item JSON from file path or ''-'' for stdin'
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;item;update'= {
            cand --name 'Updated item name'
            cand --description 'Updated item description'
            cand --type 'Entity type name or UUID'
            cand --tag 'Tag name or UUID to merge (repeatable)'
            cand --manufacturer 'Manufacturer (merged into custom field ''Manufacturer'')'
            cand --model 'Model number (merged into custom field ''Model Number'')'
            cand --quantity 'Updated quantity'
            cand --purchase-price 'Updated purchase price'
            cand --purchase-date 'Updated purchase date (YYYY-MM-DD)'
            cand --purchase-from 'Updated purchase source'
            cand --notes 'Notes (merged into custom field ''Notes'')'
            cand --field 'Custom field KEY=VAL to upsert (repeatable)'
            cand --field-type 'Value type for --field entries'
            cand --from-json 'Load patch JSON from file path or ''-'' for stdin'
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;item;upsert'= {
            cand --name 'Item name to match or create'
            cand --description 'Item description'
            cand --type 'Entity type name or UUID'
            cand --tag 'Tag name or UUID (repeatable; missing tags auto-created)'
            cand --manufacturer 'Manufacturer'
            cand --model 'Model number'
            cand --notes 'Notes'
            cand --quantity 'Quantity'
            cand --purchase-price 'Purchase price'
            cand --purchase-date 'Purchase date (YYYY-MM-DD)'
            cand --purchase-from 'Purchase source'
            cand --field 'Custom field KEY=VAL (repeatable)'
            cand --field-type 'Value type for --field entries'
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;item;delete'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --force 'Skip interactive confirmation prompt'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;item;import'= {
            cand --format 'Input format (inferred from extension if omitted; defaults to json for stdin)'
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --skip-existing 'Skip items whose name already exists in Homebox'
            cand --update-existing 'Update items whose name already exists in Homebox'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;item;dedup'= {
            cand --threshold 'Jaccard similarity threshold for near-duplicate detection (0.0..=1.0)'
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --delete 'Delete detected duplicate items, retaining only the keeper'
            cand --merge 'Sum duplicate quantities onto the keeper before deleting duplicates (implies --delete)'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;item;help'= {
            cand list 'List inventory items'
            cand get 'Fetch a single item by ID'
            cand create 'Create a new item (auto-persists custom fields via follow-up PUT)'
            cand update 'Update an existing item via GET -> Merge -> PUT'
            cand upsert 'Create or update an item matched by name'
            cand delete 'Delete an item by ID'
            cand import 'Bulk import items from JSON or CSV (file or ''-'' for stdin)'
            cand dedup 'Detect (and optionally delete or merge) duplicate items'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbx;item;help;list'= {
        }
        &'hbx;item;help;get'= {
        }
        &'hbx;item;help;create'= {
        }
        &'hbx;item;help;update'= {
        }
        &'hbx;item;help;upsert'= {
        }
        &'hbx;item;help;delete'= {
        }
        &'hbx;item;help;import'= {
        }
        &'hbx;item;help;dedup'= {
        }
        &'hbx;item;help;help'= {
        }
        &'hbx;attachment'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
            cand upload 'Upload one or more files as item attachments'
            cand list 'List attachments on an item'
            cand download 'Stream-download one or all attachments from an item'
            cand delete 'Delete an attachment from an item'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbx;attachment;upload'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --skip-existing 'Skip files that already exist on the item (default behavior)'
            cand --overwrite 'Delete and re-upload files that already exist on the item'
            cand --force 'Allow uploading images larger than 500KB'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;attachment;list'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;attachment;download'= {
            cand --mime 'Filter attachments by MIME type (e.g. application/pdf)'
            cand --ext 'Filter attachments by file extension (e.g. pdf)'
            cand --out 'Output file path (single download) or directory (multi-download / --all)'
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --all 'Download all matching attachments on the item'
            cand --overwrite 'Overwrite existing local files instead of skipping'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;attachment;delete'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;attachment;help'= {
            cand upload 'Upload one or more files as item attachments'
            cand list 'List attachments on an item'
            cand download 'Stream-download one or all attachments from an item'
            cand delete 'Delete an attachment from an item'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbx;attachment;help;upload'= {
        }
        &'hbx;attachment;help;list'= {
        }
        &'hbx;attachment;help;download'= {
        }
        &'hbx;attachment;help;delete'= {
        }
        &'hbx;attachment;help;help'= {
        }
        &'hbx;search'= {
            cand --tag 'Filter by tag name or UUID'
            cand --model 'Filter by model number (exact or substring, case-insensitive)'
            cand --serial 'Filter by serial number (exact or substring, case-insensitive)'
            cand --manufacturer 'Filter by manufacturer (exact or substring, case-insensitive)'
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;field'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
            cand get 'Get a custom field value from an item'
            cand set 'Set a typed custom field on an item via GET -> Merge -> PUT'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbx;field;get'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;field;set'= {
            cand --type 'Custom field value type'
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;field;help'= {
            cand get 'Get a custom field value from an item'
            cand set 'Set a typed custom field on an item via GET -> Merge -> PUT'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbx;field;help;get'= {
        }
        &'hbx;field;help;set'= {
        }
        &'hbx;field;help;help'= {
        }
        &'hbx;tag'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
            cand list 'List all tags'
            cand create 'Create a new tag'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbx;tag;list'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;tag;create'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;tag;help'= {
            cand list 'List all tags'
            cand create 'Create a new tag'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbx;tag;help;list'= {
        }
        &'hbx;tag;help;create'= {
        }
        &'hbx;tag;help;help'= {
        }
        &'hbx;entity-types'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
            cand list 'List all entity types'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbx;entity-type'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
            cand list 'List all entity types'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbx;entity-types;list'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;entity-type;list'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;entity-types;help'= {
            cand list 'List all entity types'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbx;entity-types;help;list'= {
        }
        &'hbx;entity-types;help;help'= {
        }
        &'hbx;entity-type;help'= {
            cand list 'List all entity types'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbx;entity-type;help;list'= {
        }
        &'hbx;entity-type;help;help'= {
        }
        &'hbx;export'= {
            cand --tag 'Filter by tag name or UUID'
            cand --has-field 'Require items to have the named custom field'
            cand --field 'Custom field column(s) to include in export (repeatable)'
            cand --sort 'Sort exported items by name or id'
            cand --format 'Export format (json, csv, markdown)'
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;completions'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;man'= {
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
            cand --json 'Shorthand for --output json (emits compact JSON)'
            cand --dry-run 'Preview mutating requests without hitting the server (redacts Authorization)'
            cand -q 'Output only created/affected IDs for shell piping'
            cand --quiet 'Output only created/affected IDs for shell piping'
            cand -h 'Print help'
            cand --help 'Print help'
        }
        &'hbx;update'= {
            cand --version 'Target a specific release version or tag (e.g. 0.1.0 or v0.1.0)'
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
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
        &'hbx;self-update'= {
            cand --version 'Target a specific release version or tag (e.g. 0.1.0 or v0.1.0)'
            cand --url 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)'
            cand --api-key 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)'
            cand --output 'Output format (table, json, plain) [env: HBX_OUTPUT]'
            cand --select 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)'
            cand -C 'Path to explicit TOML configuration file'
            cand --config 'Path to explicit TOML configuration file'
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
        &'hbx;help'= {
            cand auth 'Authenticate with a remote Homebox instance (login, status, logout, refresh)'
            cand item 'Manage inventory items (/api/v1/entities)'
            cand attachment 'Manage item attachments (/api/v1/entities/{id}/attachments)'
            cand search 'Full-text and structured item search'
            cand field 'Get or set typed custom fields on an item'
            cand tag 'Manage tags (/api/v1/tags)'
            cand entity-types 'List Homebox entity types (/api/v1/entity-types)'
            cand export 'Export filtered items to JSON, CSV, or Markdown'
            cand completions 'Generate shell completion scripts'
            cand man 'Generate UNIX roff man page'
            cand update 'Check for and install the latest hbx release from GitHub'
            cand help 'Print this message or the help of the given subcommand(s)'
        }
        &'hbx;help;auth'= {
            cand login 'Authenticate with Homebox via API key (--with-token) or email/password'
            cand status 'Check authentication status and validate the active session'
            cand logout 'Remove stored credentials from OS keyring and local fallback store'
            cand refresh 'Refresh an active JWT session token'
        }
        &'hbx;help;auth;login'= {
        }
        &'hbx;help;auth;status'= {
        }
        &'hbx;help;auth;logout'= {
        }
        &'hbx;help;auth;refresh'= {
        }
        &'hbx;help;item'= {
            cand list 'List inventory items'
            cand get 'Fetch a single item by ID'
            cand create 'Create a new item (auto-persists custom fields via follow-up PUT)'
            cand update 'Update an existing item via GET -> Merge -> PUT'
            cand upsert 'Create or update an item matched by name'
            cand delete 'Delete an item by ID'
            cand import 'Bulk import items from JSON or CSV (file or ''-'' for stdin)'
            cand dedup 'Detect (and optionally delete or merge) duplicate items'
        }
        &'hbx;help;item;list'= {
        }
        &'hbx;help;item;get'= {
        }
        &'hbx;help;item;create'= {
        }
        &'hbx;help;item;update'= {
        }
        &'hbx;help;item;upsert'= {
        }
        &'hbx;help;item;delete'= {
        }
        &'hbx;help;item;import'= {
        }
        &'hbx;help;item;dedup'= {
        }
        &'hbx;help;attachment'= {
            cand upload 'Upload one or more files as item attachments'
            cand list 'List attachments on an item'
            cand download 'Stream-download one or all attachments from an item'
            cand delete 'Delete an attachment from an item'
        }
        &'hbx;help;attachment;upload'= {
        }
        &'hbx;help;attachment;list'= {
        }
        &'hbx;help;attachment;download'= {
        }
        &'hbx;help;attachment;delete'= {
        }
        &'hbx;help;search'= {
        }
        &'hbx;help;field'= {
            cand get 'Get a custom field value from an item'
            cand set 'Set a typed custom field on an item via GET -> Merge -> PUT'
        }
        &'hbx;help;field;get'= {
        }
        &'hbx;help;field;set'= {
        }
        &'hbx;help;tag'= {
            cand list 'List all tags'
            cand create 'Create a new tag'
        }
        &'hbx;help;tag;list'= {
        }
        &'hbx;help;tag;create'= {
        }
        &'hbx;help;entity-types'= {
            cand list 'List all entity types'
        }
        &'hbx;help;entity-types;list'= {
        }
        &'hbx;help;export'= {
        }
        &'hbx;help;completions'= {
        }
        &'hbx;help;man'= {
        }
        &'hbx;help;update'= {
        }
        &'hbx;help;help'= {
        }
    ]
    $completions[$command]
}
