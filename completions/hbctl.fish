# Print an optspec for argparse to handle cmd's options that are independent of any subcommand.
function __fish_hbctl_global_optspecs
    string join \n url= api-key= output= json select= dry-run q/quiet C/config= P/profile= asset-id h/help V/version
end

function __fish_hbctl_needs_command
    # Figure out if the current invocation already has a command.
    set -l cmd (commandline -opc)
    set -e cmd[1]
    argparse -s (__fish_hbctl_global_optspecs) -- $cmd 2>/dev/null
    or return
    if set -q argv[1]
        # Also print the command, so this can be used to figure out what it is.
        echo $argv[1]
        return 1
    end
    return 0
end

function __fish_hbctl_using_subcommand
    set -l cmd (__fish_hbctl_needs_command)
    test -z "$cmd"
    and return 1
    contains -- $cmd[1] $argv
end

complete -c hbctl -n "__fish_hbctl_needs_command" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_needs_command" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_needs_command" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_needs_command" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_needs_command" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_needs_command" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_needs_command" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_needs_command" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_needs_command" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_needs_command" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_needs_command" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_needs_command" -s V -l version -d 'Print version'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "auth" -d 'Authenticate with a remote Homebox instance (login, status, logout, refresh)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "item" -d 'Manage inventory items (/api/v1/entities)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "attachment" -d 'Manage item attachments (/api/v1/entities/{id}/attachments)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "search" -d 'Full-text and structured item search'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "field" -d 'List, get, set, or delete typed custom fields on an item'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "tag" -d 'Manage tags (/api/v1/tags)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "entity-types" -d 'Manage Homebox entity types (/api/v1/entity-types)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "entity-type" -d 'Manage Homebox entity types (/api/v1/entity-types)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "status" -d 'Check remote Homebox server connectivity and version (/api/v1/status)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "api" -d 'Issue a raw authenticated HTTP request against any Homebox API endpoint'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "maintenance" -d 'Manage maintenance log entries (/api/v1/maintenance)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "export" -d 'Export filtered items to JSON, CSV, or Markdown'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "backup" -d 'Create a portable full-inventory backup (directory or .tar.gz archive)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "label" -d 'Generate or print a Homebox item, asset, or location label (/api/v1/labelmaker)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "qr" -d 'Generate a QR code image (/api/v1/qrcode)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "actions" -d 'Run Homebox server maintenance actions (/api/v1/actions/*)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "action" -d 'Run Homebox server maintenance actions (/api/v1/actions/*)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "stats" -d 'Display inventory statistics and breakdowns (/api/v1/groups/statistics*)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "config" -d 'Inspect effective configuration and manage named profiles'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "template" -d 'Manage item templates and create items from templates (/api/v1/templates)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "templates" -d 'Manage item templates and create items from templates (/api/v1/templates)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "barcode" -d 'Look up product metadata by barcode (/api/v1/products/search-from-barcode)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "notifier" -d 'Manage Shoutrrr notification channels (/api/v1/notifiers)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "notifiers" -d 'Manage Shoutrrr notification channels (/api/v1/notifiers)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "completions" -d 'Generate shell completion scripts'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "man" -d 'Generate UNIX roff man page'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "update" -d 'Check for and install the latest hbctl release from GitHub'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "self-update" -d 'Check for and install the latest hbctl release from GitHub'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -f -a "login" -d 'Authenticate with Homebox via API key (--with-token) or email/password'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -f -a "status" -d 'Check authentication status and validate the active session'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -f -a "logout" -d 'Remove stored credentials from OS keyring and local fallback store'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -f -a "refresh" -d 'Refresh an active JWT session token'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -s u -l username -d 'Email or username for password login (POST /api/v1/users/login)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -l with-token -d 'Read a Homebox API key (hb_...) or Bearer token from stdin'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -l password-stdin -d 'Read login password from stdin instead of prompting interactively'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -l insecure-storage -d 'Store token in 0600 local file store instead of OS keyring'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -l insecure-storage -d 'Skip OS keyring and only clear local 0600 fallback store'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -l insecure-storage -d 'Store refreshed token in 0600 local file store instead of OS keyring'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from help" -f -a "login" -d 'Authenticate with Homebox via API key (--with-token) or email/password'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from help" -f -a "status" -d 'Check authentication status and validate the active session'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from help" -f -a "logout" -d 'Remove stored credentials from OS keyring and local fallback store'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from help" -f -a "refresh" -d 'Refresh an active JWT session token'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -f -a "list" -d 'List inventory items'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -f -a "get" -d 'Fetch a single item by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -f -a "create" -d 'Create a new item (auto-persists custom fields via follow-up PUT)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -f -a "update" -d 'Update an existing item via GET -> Merge -> PUT'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -f -a "upsert" -d 'Create or update an item matched by name'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -f -a "delete" -d 'Delete an item by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -f -a "import" -d 'Bulk import items from JSON or CSV (file or \'-\' for stdin)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -f -a "dedup" -d 'Detect (and optionally delete or merge) duplicate items'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -f -a "move" -d 'Move an item under a parent item/location (or \'none\' to unparent)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -f -a "duplicate" -d 'Duplicate an existing item one or more times'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -f -a "path" -d 'Display the location/parent breadcrumb path for an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -f -a "tree" -d 'Render item parent/location hierarchy as a tree'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup move duplicate path tree help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l tag -d 'Filter by tag name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l type -d 'Filter by entity type name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l parent -d 'Filter by parent item name, ID, or \'none\' for top-level items' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l has-field -d 'Only include items having the named custom field (hydrates details if missing)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l page-size -d 'Page size for listing' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l warranty-expiring -d 'Only show items with a warranty expiring within the next DAYS days (excludes lifetime warranties)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l all -d 'Fetch all pages'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l include-archived -d 'Include archived items in results'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l archived-only -d 'Only show archived items (implies --include-archived)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -l with-path -d 'Include full location/parent breadcrumb path in output'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l name -d 'Item name (required unless supplied via --from-json or --from-barcode)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l description -d 'Item description' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l type -d 'Entity type name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l parent -d 'Parent item/location name, ID, or \'none\'' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l tag -d 'Tag name or UUID (repeatable; missing tags auto-created)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l manufacturer -d 'Manufacturer (normalized into custom field \'Manufacturer\')' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l model -d 'Model number (normalized into custom field \'Model Number\')' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l serial -d 'Serial number (normalized into custom field \'Serial Number\')' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l notes -d 'Notes (normalized into custom field \'Notes\')' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l quantity -d 'Item quantity' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l purchase-price -d 'Purchase price' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l purchase-date -d 'Purchase date (YYYY-MM-DD)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l purchase-from -d 'Purchase vendor/source' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l archived -d 'Mark item as archived (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l insured -d 'Mark item as insured (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l lifetime-warranty -d 'Mark item as having a lifetime warranty (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l warranty-expires -d 'Warranty expiration date (YYYY-MM-DD or RFC3339)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l warranty-details -d 'Warranty details or terms' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l sold-time -d 'Date/time the item was sold (YYYY-MM-DD or RFC3339)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l sold-to -d 'Buyer name or recipient the item was sold to' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l sold-price -d 'Sale price' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l sold-notes -d 'Notes about the sale' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l field -d 'Custom field KEY=VAL (repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l field-type -d 'Value type for --field entries' -r -f -a "text\t''
number\t''
boolean\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l from-json -d 'Load initial item JSON from file path or \'-\' for stdin' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l from-barcode -d 'Prefill name, description, manufacturer, and model from a barcode lookup' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l attach -d 'Local file path(s) to attach after creating the item (`FILE` or `FILE=REMOTE_NAME`, repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l attach-url -d 'Remote HTTP(S) URL(s) to download and attach (`URL` or `URL=REMOTE_NAME`, repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l attach-best-effort -d 'Treat attachment failures as non-fatal warnings and include `attachmentErrors` in JSON output'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l optimize -d 'Automatically resize/compress oversized images before upload'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l force -d 'Allow attaching images larger than 500KB'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l items-from -d 'Read newline-delimited entity IDs to update from a file or \'-\' (stdin)' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l filter-tag -d 'Select items to update matching this tag name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l filter-parent -d 'Select items to update under this parent item/location name, ID, or \'none\'' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l filter-type -d 'Select items to update matching this entity type name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l name -d 'Updated item name' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l description -d 'Updated item description' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l type -d 'Entity type name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l parent -d 'Parent item/location name, ID, or \'none\' to unparent' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l tag -d 'Tag name or UUID to merge (repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l add-tag -d 'Tag name or UUID to add while preserving existing tags (repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l remove-tag -d 'Tag name or UUID to remove while preserving other existing tags (repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l manufacturer -d 'Manufacturer (merged into custom field \'Manufacturer\')' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l model -d 'Model number (merged into custom field \'Model Number\')' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l serial -d 'Serial number (merged into custom field \'Serial Number\')' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l quantity -d 'Updated quantity' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l purchase-price -d 'Updated purchase price' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l purchase-date -d 'Updated purchase date (YYYY-MM-DD)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l purchase-from -d 'Updated purchase source' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l archived -d 'Mark item as archived (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l insured -d 'Mark item as insured (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l lifetime-warranty -d 'Mark item as having a lifetime warranty (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l warranty-expires -d 'Warranty expiration date (YYYY-MM-DD or RFC3339)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l warranty-details -d 'Warranty details or terms' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l sold-time -d 'Date/time the item was sold (YYYY-MM-DD or RFC3339)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l sold-to -d 'Buyer name or recipient the item was sold to' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l sold-price -d 'Sale price' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l sold-notes -d 'Notes about the sale' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l notes -d 'Notes (merged into custom field \'Notes\')' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l field -d 'Custom field KEY=VAL to upsert (repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l field-type -d 'Value type for --field entries' -r -f -a "text\t''
number\t''
boolean\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l from-json -d 'Load patch JSON from file path or \'-\' for stdin' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l fill-missing -d 'Only populate blank/missing/zero fields; preserve existing non-empty values'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l name -d 'Item name to match or create (required unless supplied via --from-json)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l description -d 'Item description' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l type -d 'Entity type name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l parent -d 'Parent item/location name, ID, or \'none\'' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l tag -d 'Tag name or UUID (repeatable; missing tags auto-created)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l manufacturer -d 'Manufacturer' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l model -d 'Model number' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l serial -d 'Serial number' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l notes -d 'Notes' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l quantity -d 'Quantity' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l purchase-price -d 'Purchase price' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l purchase-date -d 'Purchase date (YYYY-MM-DD)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l purchase-from -d 'Purchase source' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l archived -d 'Mark item as archived (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l insured -d 'Mark item as insured (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l lifetime-warranty -d 'Mark item as having a lifetime warranty (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l warranty-expires -d 'Warranty expiration date (YYYY-MM-DD or RFC3339)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l warranty-details -d 'Warranty details or terms' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l sold-time -d 'Date/time the item was sold (YYYY-MM-DD or RFC3339)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l sold-to -d 'Buyer name or recipient the item was sold to' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l sold-price -d 'Sale price' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l sold-notes -d 'Notes about the sale' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l field -d 'Custom field KEY=VAL (repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l field-type -d 'Value type for --field entries' -r -f -a "text\t''
number\t''
boolean\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l from-json -d 'Load item JSON from file path or \'-\' for stdin' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l match-by -d 'Match existing items by key in priority order: name, model, serial, or field:KEY (repeatable; defaults to name)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l match-mode -d 'Matching strategy for --match-by keys (exact, contains, fuzzy)' -r -f -a "exact\t''
contains\t''
fuzzy\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l on-match -d 'Action to take when an existing item matches (update, skip, attach-only)' -r -f -a "update\t''
skip\t''
attach-only\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l attach -d 'Local file path(s) to attach after upserting the item (`FILE` or `FILE=REMOTE_NAME`, repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l attach-url -d 'Remote HTTP(S) URL(s) to download and attach (`URL` or `URL=REMOTE_NAME`, repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l fill-missing -d 'When updating an existing item, only populate blank/missing/zero fields'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l attach-best-effort -d 'Treat attachment failures as non-fatal warnings and include `attachmentErrors` in JSON output'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l optimize -d 'Automatically resize/compress oversized images before upload'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l force -d 'Allow attaching images larger than 500KB'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -l items-from -d 'Read newline-delimited entity IDs to delete from a file or \'-\' (stdin)' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -l tag -l filter-tag -d 'Select items to delete matching this tag name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -l parent -l filter-parent -d 'Select items to delete under this parent item/location name, ID, or \'none\'' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -l type -l filter-type -d 'Select items to delete matching this entity type name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -s y -l yes -d 'Skip interactive/bulk confirmation prompt'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -l force -d 'Skip interactive/bulk confirmation prompt'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l format -d 'Input format (inferred from extension if omitted; defaults to json for stdin)' -r -f -a "json\t''
csv\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l match-by -d 'Match existing items by key in priority order: name, model, serial, or field:KEY (repeatable; defaults to name)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l match-mode -d 'Matching strategy for --match-by keys (exact, contains, fuzzy)' -r -f -a "exact\t''
contains\t''
fuzzy\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l parent -d 'Default parent item/location name, ID, or \'none\' for imported records without one' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l attach -d 'Local file path(s) to attach to each imported item (`FILE` or `FILE=REMOTE_NAME`, repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l skip-existing -d 'Skip items whose name already exists in Homebox'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l update-existing -d 'Update items whose name already exists in Homebox'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l fill-missing -d 'With --update-existing, only populate blank/missing/zero fields on existing items'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l optimize -d 'Automatically resize/compress oversized images before upload'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l force -d 'Allow attaching images larger than 500KB'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -l threshold -d 'Jaccard similarity threshold for near-duplicate detection (0.0..=1.0)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -l delete -d 'Delete detected duplicate items, retaining only the keeper'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -l merge -d 'Sum duplicate quantities onto the keeper before deleting duplicates (implies --delete)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from move" -l to -d 'Target parent item name, ID, or \'none\' to unparent (required when using selectors without trailing positional parent)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from move" -l items-from -d 'Read newline-delimited entity IDs to move from a file or \'-\' (stdin)' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from move" -l tag -l filter-tag -d 'Select items to move matching this tag name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from move" -l parent -l filter-parent -d 'Select items to move under this parent item/location name, ID, or \'none\'' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from move" -l type -l filter-type -d 'Select items to move matching this entity type name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from move" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from move" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from move" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from move" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from move" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from move" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from move" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from move" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from move" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from move" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from move" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from duplicate" -l count -d 'Number of duplicates to create' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from duplicate" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from duplicate" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from duplicate" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from duplicate" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from duplicate" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from duplicate" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from duplicate" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from duplicate" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from duplicate" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from duplicate" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from duplicate" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from path" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from path" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from path" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from path" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from path" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from path" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from path" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from path" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from path" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from path" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from path" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from tree" -l root -d 'Optional root item name or ID to start the tree from' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from tree" -l max-depth -d 'Optional maximum depth to display (0 = roots only)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from tree" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from tree" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from tree" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from tree" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from tree" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from tree" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from tree" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from tree" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from tree" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from tree" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from tree" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "list" -d 'List inventory items'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "get" -d 'Fetch a single item by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "create" -d 'Create a new item (auto-persists custom fields via follow-up PUT)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "update" -d 'Update an existing item via GET -> Merge -> PUT'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "upsert" -d 'Create or update an item matched by name'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete an item by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "import" -d 'Bulk import items from JSON or CSV (file or \'-\' for stdin)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "dedup" -d 'Detect (and optionally delete or merge) duplicate items'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "move" -d 'Move an item under a parent item/location (or \'none\' to unparent)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "duplicate" -d 'Duplicate an existing item one or more times'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "path" -d 'Display the location/parent breadcrumb path for an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "tree" -d 'Render item parent/location hierarchy as a tree'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete set-primary update add-link help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete set-primary update add-link help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete set-primary update add-link help" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete set-primary update add-link help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete set-primary update add-link help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete set-primary update add-link help" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete set-primary update add-link help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete set-primary update add-link help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete set-primary update add-link help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete set-primary update add-link help" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete set-primary update add-link help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete set-primary update add-link help" -f -a "upload" -d 'Upload one or more files as item attachments'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete set-primary update add-link help" -f -a "list" -d 'List attachments on an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete set-primary update add-link help" -f -a "download" -d 'Stream-download attachments from one or multiple items'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete set-primary update add-link help" -f -a "delete" -d 'Delete an attachment from an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete set-primary update add-link help" -f -a "set-primary" -d 'Mark an existing attachment as the item\'s primary photo'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete set-primary update add-link help" -f -a "update" -d 'Update attachment metadata (title, type, primary)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete set-primary update add-link help" -f -a "add-link" -d 'Attach an external HTTP(S) URL link to an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete set-primary update add-link help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l attach-url -d 'Remote HTTP(S) URL(s) to download and attach (`URL` or `URL=REMOTE_NAME`, repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l name -d 'Override remote filename/title (for single-file or stdin \'-\' uploads)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l primary -d 'Mark the uploaded attachment as the item\'s primary photo'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l skip-existing -d 'Skip files that already exist on the item (default behavior)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l overwrite -d 'Delete and re-upload files that already exist on the item'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l optimize -d 'Automatically resize/compress oversized images before upload'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l force -d 'Allow uploading images larger than 500KB'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l tag -d 'Download matching attachments across items matching this tag name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l items-from -d 'Download matching attachments for newline-delimited entity IDs from a file or \'-\' (stdin)' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l mime -d 'Filter attachments by MIME type (e.g. application/pdf)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l ext -d 'Filter attachments by file extension (e.g. pdf)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l out -d 'Output file path (single download) or directory (multi-download / --all / bulk)' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l all -d 'Download all matching attachments on the item'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l all-items -d 'Download matching attachments across all items'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l overwrite -d 'Overwrite existing local files instead of skipping'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from set-primary" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from set-primary" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from set-primary" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from set-primary" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from set-primary" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from set-primary" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from set-primary" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from set-primary" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from set-primary" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from set-primary" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from set-primary" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from update" -l title -d 'Updated attachment title' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from update" -l type -d 'Updated attachment type (e.g. photo, manual, warranty, receipt, attachment)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from update" -l primary -d 'Mark or unmark as the primary attachment (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from update" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from update" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from update" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from update" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from update" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from update" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from update" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from update" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from update" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from update" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from update" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from add-link" -l title -d 'Display title for the external link (defaults to sanitized URL)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from add-link" -l type -d 'Attachment type (photo, manual, warranty, receipt, attachment)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from add-link" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from add-link" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from add-link" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from add-link" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from add-link" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from add-link" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from add-link" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from add-link" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from add-link" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from add-link" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from add-link" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from help" -f -a "upload" -d 'Upload one or more files as item attachments'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from help" -f -a "list" -d 'List attachments on an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from help" -f -a "download" -d 'Stream-download attachments from one or multiple items'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete an attachment from an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from help" -f -a "set-primary" -d 'Mark an existing attachment as the item\'s primary photo'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from help" -f -a "update" -d 'Update attachment metadata (title, type, primary)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from help" -f -a "add-link" -d 'Attach an external HTTP(S) URL link to an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l tag -d 'Filter by tag name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l type -d 'Filter by entity type name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l parent -d 'Filter by parent item name, ID, or \'none\' for top-level items' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l limit -d 'Maximum number of matching results to return' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l warranty-expiring -d 'Only include items with a warranty expiring within the next DAYS days (excludes lifetime warranties)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l model -d 'Filter by model number (exact or substring, case-insensitive)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l serial -d 'Filter by serial number (exact or substring, case-insensitive)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l manufacturer -d 'Filter by manufacturer (exact or substring, case-insensitive)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l field -d 'Filter by custom field existence (KEY) or substring value (KEY=VAL), case-insensitive (repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l include-archived -d 'Include archived items in search results'
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l archived-only -d 'Only search archived items (implies --include-archived)'
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l any -d 'Match items satisfying ANY provided filter (OR) instead of ALL filters (AND)'
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l with-path -d 'Include full location/parent breadcrumb path for each matching item'
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from list get set delete help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from list get set delete help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from list get set delete help" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from list get set delete help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from list get set delete help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from list get set delete help" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from list get set delete help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from list get set delete help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from list get set delete help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from list get set delete help" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from list get set delete help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from list get set delete help" -f -a "list" -d 'List all custom fields on an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from list get set delete help" -f -a "get" -d 'Get a custom field value from an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from list get set delete help" -f -a "set" -d 'Set a typed custom field on an item via GET -> Merge -> PUT'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from list get set delete help" -f -a "delete" -d 'Delete a custom field from an item via GET -> Remove -> PUT'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from list get set delete help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from list" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from list" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from list" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from list" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from list" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from list" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from list" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from list" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from list" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from list" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -l type -d 'Custom field value type' -r -f -a "text\t''
number\t''
boolean\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from delete" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from delete" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from delete" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from delete" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from delete" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from delete" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from delete" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from delete" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from delete" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from delete" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from help" -f -a "list" -d 'List all custom fields on an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from help" -f -a "get" -d 'Get a custom field value from an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from help" -f -a "set" -d 'Set a typed custom field on an item via GET -> Merge -> PUT'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete a custom field from an item via GET -> Remove -> PUT'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create update delete help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create update delete help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create update delete help" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create update delete help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create update delete help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create update delete help" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create update delete help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create update delete help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create update delete help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create update delete help" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create update delete help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create update delete help" -f -a "list" -d 'List all tags'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create update delete help" -f -a "create" -d 'Create a new tag'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create update delete help" -f -a "update" -d 'Update an existing tag by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create update delete help" -f -a "delete" -d 'Delete a tag by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create update delete help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from update" -l name -d 'Updated tag name' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from update" -l description -d 'Updated tag description' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from update" -l color -d 'Updated tag hex color' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from update" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from update" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from update" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from update" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from update" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from update" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from update" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from update" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from update" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from update" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from update" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from delete" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from delete" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from delete" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from delete" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from delete" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from delete" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from delete" -l force -d 'Skip interactive confirmation prompt'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from delete" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from delete" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from delete" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from delete" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from help" -f -a "list" -d 'List all tags'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from help" -f -a "create" -d 'Create a new tag'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from help" -f -a "update" -d 'Update an existing tag by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete a tag by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list create delete help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list create delete help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list create delete help" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list create delete help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list create delete help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list create delete help" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list create delete help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list create delete help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list create delete help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list create delete help" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list create delete help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list create delete help" -f -a "list" -d 'List all entity types'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list create delete help" -f -a "create" -d 'Create a new entity type'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list create delete help" -f -a "delete" -d 'Delete an entity type by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list create delete help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from create" -l description -d 'Optional description' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from create" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from create" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from create" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from create" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from create" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from create" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from create" -l is-location -d 'Mark this entity type as a location/container'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from create" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from create" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from create" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from create" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from create" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from delete" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from delete" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from delete" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from delete" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from delete" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from delete" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from delete" -l force -d 'Skip interactive confirmation prompt'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from delete" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from delete" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from delete" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from delete" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from help" -f -a "list" -d 'List all entity types'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from help" -f -a "create" -d 'Create a new entity type'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete an entity type by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list create delete help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list create delete help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list create delete help" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list create delete help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list create delete help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list create delete help" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list create delete help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list create delete help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list create delete help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list create delete help" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list create delete help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list create delete help" -f -a "list" -d 'List all entity types'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list create delete help" -f -a "create" -d 'Create a new entity type'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list create delete help" -f -a "delete" -d 'Delete an entity type by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list create delete help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from create" -l description -d 'Optional description' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from create" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from create" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from create" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from create" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from create" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from create" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from create" -l is-location -d 'Mark this entity type as a location/container'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from create" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from create" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from create" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from create" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from create" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from delete" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from delete" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from delete" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from delete" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from delete" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from delete" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from delete" -l force -d 'Skip interactive confirmation prompt'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from delete" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from delete" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from delete" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from delete" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from help" -f -a "list" -d 'List all entity types'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from help" -f -a "create" -d 'Create a new entity type'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete an entity type by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand status" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand status" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand status" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand status" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand status" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand status" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand status" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand status" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand status" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand status" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand status" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand api" -s d -l data -d 'Inline JSON request body' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand api" -l from-json -d 'Read JSON request body from a file path or \'-\' for stdin' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand api" -l query -d 'Query parameter KEY=VALUE (repeatable; appended to any inline path query)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand api" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand api" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand api" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand api" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand api" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand api" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand api" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand api" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand api" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand api" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand api" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and not __fish_seen_subcommand_from list create update delete help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and not __fish_seen_subcommand_from list create update delete help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and not __fish_seen_subcommand_from list create update delete help" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and not __fish_seen_subcommand_from list create update delete help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and not __fish_seen_subcommand_from list create update delete help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and not __fish_seen_subcommand_from list create update delete help" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and not __fish_seen_subcommand_from list create update delete help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and not __fish_seen_subcommand_from list create update delete help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and not __fish_seen_subcommand_from list create update delete help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and not __fish_seen_subcommand_from list create update delete help" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and not __fish_seen_subcommand_from list create update delete help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and not __fish_seen_subcommand_from list create update delete help" -f -a "list" -d 'List maintenance log entries (globally or for a specific entity)'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and not __fish_seen_subcommand_from list create update delete help" -f -a "create" -d 'Create a maintenance log entry on an entity'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and not __fish_seen_subcommand_from list create update delete help" -f -a "update" -d 'Update an existing maintenance log entry by entry ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and not __fish_seen_subcommand_from list create update delete help" -f -a "delete" -d 'Delete a maintenance log entry by entry ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and not __fish_seen_subcommand_from list create update delete help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from list" -l status -d 'Filter by maintenance status (both, completed, scheduled)' -r -f -a "both\t''
completed\t''
scheduled\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from list" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from list" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from list" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from list" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from list" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from list" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from list" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from list" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from list" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from list" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from create" -l name -d 'Maintenance task/entry name' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from create" -l completed-date -d 'Completion date (YYYY-MM-DD or YYYY-MM)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from create" -l scheduled-date -d 'Scheduled date (YYYY-MM-DD or YYYY-MM)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from create" -l cost -d 'Maintenance cost (e.g. 29.99 or $29.99)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from create" -l description -d 'Maintenance description or notes' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from create" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from create" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from create" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from create" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from create" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from create" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from create" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from create" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from create" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from create" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from create" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from update" -l name -d 'Updated maintenance task/entry name' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from update" -l completed-date -d 'Updated completion date (YYYY-MM-DD or YYYY-MM)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from update" -l scheduled-date -d 'Updated scheduled date (YYYY-MM-DD or YYYY-MM)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from update" -l cost -d 'Updated maintenance cost (e.g. 29.99 or $29.99)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from update" -l description -d 'Updated maintenance description or notes' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from update" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from update" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from update" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from update" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from update" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from update" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from update" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from update" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from update" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from update" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from update" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from delete" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from delete" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from delete" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from delete" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from delete" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from delete" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from delete" -l force -d 'Skip interactive confirmation prompt'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from delete" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from delete" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from delete" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from delete" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from help" -f -a "list" -d 'List maintenance log entries (globally or for a specific entity)'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from help" -f -a "create" -d 'Create a maintenance log entry on an entity'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from help" -f -a "update" -d 'Update an existing maintenance log entry by entry ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete a maintenance log entry by entry ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand maintenance; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l tag -d 'Filter by tag name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l has-field -d 'Require items to have the named custom field' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l field -d 'Custom field column(s) to include in export (repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l sort -d 'Sort exported items (name, id, purchase-price, purchase-date, updated-at, asset-id)' -r -f -a "name\t''
id\t''
purchase-price\t''
purchase-date\t''
updated-at\t''
asset-id\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l format -d 'Export format (json, csv, markdown)' -r -f -a "json\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l columns -d 'Custom column list and order (comma-separated or repeatable; supports \'key=Header Alias\')' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l align -d 'Markdown table column alignment (default, left, right, center)' -r -f -a "default\t''
left\t''
right\t''
center\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l empty -d 'Placeholder string for empty/missing cells' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand backup" -s o -l out -d 'Destination directory or .tar.gz / .tgz archive path' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand backup" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand backup" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand backup" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand backup" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand backup" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand backup" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand backup" -l no-attachments -d 'Skip downloading attachment binary files (attachment metadata stays in entities.json)'
complete -c hbctl -n "__fish_hbctl_using_subcommand backup" -l exclude-archived -d 'Exclude archived items from the backup (archived items are included by default)'
complete -c hbctl -n "__fish_hbctl_using_subcommand backup" -l overwrite -d 'Overwrite an existing archive file or write into a non-empty directory'
complete -c hbctl -n "__fish_hbctl_using_subcommand backup" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand backup" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand backup" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand backup" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand backup" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand label" -s o -l out -d 'Output file path, or \'-\' to write raw label bytes to stdout' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand label" -l kind -d 'Target label endpoint kind (auto detects numeric/dashed asset IDs)' -r -f -a "auto\t''
item\t''
asset\t''
location\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand label" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand label" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand label" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand label" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand label" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand label" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand label" -l print -d 'Send the label directly to the server\'s configured printer (?print=true)'
complete -c hbctl -n "__fish_hbctl_using_subcommand label" -l overwrite -d 'Overwrite output file if it already exists'
complete -c hbctl -n "__fish_hbctl_using_subcommand label" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand label" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand label" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand label" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand label" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand qr" -s o -l out -d 'Output file path, or \'-\' to write raw QR image bytes to stdout' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand qr" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand qr" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand qr" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand qr" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand qr" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand qr" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand qr" -l raw -d 'Encode <ID> verbatim as QR `data` instead of building a Homebox item/asset URL'
complete -c hbctl -n "__fish_hbctl_using_subcommand qr" -l overwrite -d 'Overwrite output file if it already exists'
complete -c hbctl -n "__fish_hbctl_using_subcommand qr" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand qr" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand qr" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand qr" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand qr" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -f -a "ensure-asset-ids" -d 'Ensure all items in Homebox have an asset ID assigned (/api/v1/actions/ensure-asset-ids)'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -f -a "create-missing-thumbnails" -d 'Create thumbnails for attachments missing them (/api/v1/actions/create-missing-thumbnails)'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from ensure-asset-ids" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from ensure-asset-ids" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from ensure-asset-ids" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from ensure-asset-ids" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from ensure-asset-ids" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from ensure-asset-ids" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from ensure-asset-ids" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from ensure-asset-ids" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from ensure-asset-ids" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from ensure-asset-ids" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from ensure-asset-ids" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from create-missing-thumbnails" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from create-missing-thumbnails" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from create-missing-thumbnails" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from create-missing-thumbnails" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from create-missing-thumbnails" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from create-missing-thumbnails" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from create-missing-thumbnails" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from create-missing-thumbnails" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from create-missing-thumbnails" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from create-missing-thumbnails" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from create-missing-thumbnails" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from help" -f -a "ensure-asset-ids" -d 'Ensure all items in Homebox have an asset ID assigned (/api/v1/actions/ensure-asset-ids)'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from help" -f -a "create-missing-thumbnails" -d 'Create thumbnails for attachments missing them (/api/v1/actions/create-missing-thumbnails)'
complete -c hbctl -n "__fish_hbctl_using_subcommand actions; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -f -a "ensure-asset-ids" -d 'Ensure all items in Homebox have an asset ID assigned (/api/v1/actions/ensure-asset-ids)'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -f -a "create-missing-thumbnails" -d 'Create thumbnails for attachments missing them (/api/v1/actions/create-missing-thumbnails)'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and not __fish_seen_subcommand_from ensure-asset-ids create-missing-thumbnails help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from ensure-asset-ids" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from ensure-asset-ids" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from ensure-asset-ids" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from ensure-asset-ids" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from ensure-asset-ids" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from ensure-asset-ids" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from ensure-asset-ids" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from ensure-asset-ids" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from ensure-asset-ids" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from ensure-asset-ids" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from ensure-asset-ids" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from create-missing-thumbnails" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from create-missing-thumbnails" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from create-missing-thumbnails" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from create-missing-thumbnails" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from create-missing-thumbnails" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from create-missing-thumbnails" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from create-missing-thumbnails" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from create-missing-thumbnails" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from create-missing-thumbnails" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from create-missing-thumbnails" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from create-missing-thumbnails" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from help" -f -a "ensure-asset-ids" -d 'Ensure all items in Homebox have an asset ID assigned (/api/v1/actions/ensure-asset-ids)'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from help" -f -a "create-missing-thumbnails" -d 'Create thumbnails for attachments missing them (/api/v1/actions/create-missing-thumbnails)'
complete -c hbctl -n "__fish_hbctl_using_subcommand action; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -l warranty-days -d 'Also count non-lifetime warranties expiring within DAYS days' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -f -a "overview" -d 'Group-wide overview statistics (/api/v1/groups/statistics + upcoming maintenance)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -f -a "tags" -d 'Tag purchase-value breakdown (/api/v1/groups/statistics/tags)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -f -a "locations" -d 'Location purchase-value breakdown (/api/v1/groups/statistics/locations)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -f -a "entity-types" -d 'Entity-type count and purchase-value breakdown'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -f -a "types" -d 'Entity-type count and purchase-value breakdown'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -f -a "purchase-price" -d 'Purchase value over time (/api/v1/groups/statistics/purchase-price)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -f -a "price" -d 'Purchase value over time (/api/v1/groups/statistics/purchase-price)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and not __fish_seen_subcommand_from overview tags locations entity-types types purchase-price price help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from overview" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from overview" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from overview" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from overview" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from overview" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from overview" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from overview" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from overview" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from overview" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from overview" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from overview" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from tags" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from tags" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from tags" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from tags" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from tags" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from tags" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from tags" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from tags" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from tags" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from tags" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from tags" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from locations" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from locations" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from locations" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from locations" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from locations" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from locations" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from locations" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from locations" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from locations" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from locations" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from locations" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from entity-types" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from entity-types" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from entity-types" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from entity-types" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from entity-types" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from entity-types" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from entity-types" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from entity-types" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from entity-types" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from entity-types" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from entity-types" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from types" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from types" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from types" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from types" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from types" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from types" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from types" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from types" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from types" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from types" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from types" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from purchase-price" -l start -d 'Start date (YYYY-MM-DD)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from purchase-price" -l end -d 'End date (YYYY-MM-DD)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from purchase-price" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from purchase-price" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from purchase-price" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from purchase-price" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from purchase-price" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from purchase-price" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from purchase-price" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from purchase-price" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from purchase-price" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from purchase-price" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from purchase-price" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from price" -l start -d 'Start date (YYYY-MM-DD)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from price" -l end -d 'End date (YYYY-MM-DD)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from price" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from price" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from price" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from price" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from price" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from price" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from price" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from price" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from price" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from price" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from price" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from help" -f -a "overview" -d 'Group-wide overview statistics (/api/v1/groups/statistics + upcoming maintenance)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from help" -f -a "tags" -d 'Tag purchase-value breakdown (/api/v1/groups/statistics/tags)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from help" -f -a "locations" -d 'Location purchase-value breakdown (/api/v1/groups/statistics/locations)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from help" -f -a "entity-types" -d 'Entity-type count and purchase-value breakdown'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from help" -f -a "purchase-price" -d 'Purchase value over time (/api/v1/groups/statistics/purchase-price)'
complete -c hbctl -n "__fish_hbctl_using_subcommand stats; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and not __fish_seen_subcommand_from show profiles use help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and not __fish_seen_subcommand_from show profiles use help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and not __fish_seen_subcommand_from show profiles use help" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and not __fish_seen_subcommand_from show profiles use help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and not __fish_seen_subcommand_from show profiles use help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and not __fish_seen_subcommand_from show profiles use help" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and not __fish_seen_subcommand_from show profiles use help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and not __fish_seen_subcommand_from show profiles use help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and not __fish_seen_subcommand_from show profiles use help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and not __fish_seen_subcommand_from show profiles use help" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and not __fish_seen_subcommand_from show profiles use help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and not __fish_seen_subcommand_from show profiles use help" -f -a "show" -d 'Display effective resolved configuration (secrets redacted as Bearer ***)'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and not __fish_seen_subcommand_from show profiles use help" -f -a "profiles" -d 'List configured profiles and indicate active/default selection'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and not __fish_seen_subcommand_from show profiles use help" -f -a "use" -d 'Switch the active default profile in user config'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and not __fish_seen_subcommand_from show profiles use help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from show" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from show" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from show" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from show" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from show" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from show" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from show" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from show" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from show" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from show" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from show" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from profiles" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from profiles" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from profiles" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from profiles" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from profiles" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from profiles" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from profiles" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from profiles" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from profiles" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from profiles" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from profiles" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from use" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from use" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from use" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from use" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from use" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from use" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from use" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from use" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from use" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from use" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from help" -f -a "show" -d 'Display effective resolved configuration (secrets redacted as Bearer ***)'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from help" -f -a "profiles" -d 'List configured profiles and indicate active/default selection'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from help" -f -a "use" -d 'Switch the active default profile in user config'
complete -c hbctl -n "__fish_hbctl_using_subcommand config; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and not __fish_seen_subcommand_from list get create update delete apply help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and not __fish_seen_subcommand_from list get create update delete apply help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and not __fish_seen_subcommand_from list get create update delete apply help" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and not __fish_seen_subcommand_from list get create update delete apply help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and not __fish_seen_subcommand_from list get create update delete apply help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and not __fish_seen_subcommand_from list get create update delete apply help" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and not __fish_seen_subcommand_from list get create update delete apply help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and not __fish_seen_subcommand_from list get create update delete apply help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and not __fish_seen_subcommand_from list get create update delete apply help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and not __fish_seen_subcommand_from list get create update delete apply help" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and not __fish_seen_subcommand_from list get create update delete apply help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and not __fish_seen_subcommand_from list get create update delete apply help" -f -a "list" -d 'List all entity templates'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and not __fish_seen_subcommand_from list get create update delete apply help" -f -a "get" -d 'Fetch a single entity template by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and not __fish_seen_subcommand_from list get create update delete apply help" -f -a "create" -d 'Create a new entity template'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and not __fish_seen_subcommand_from list get create update delete apply help" -f -a "update" -d 'Update an existing entity template (GET -> Merge -> PUT)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and not __fish_seen_subcommand_from list get create update delete apply help" -f -a "delete" -d 'Delete an entity template'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and not __fish_seen_subcommand_from list get create update delete apply help" -f -a "apply" -d 'Create a new item from a template (/api/v1/templates/{id}/create-item)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and not __fish_seen_subcommand_from list get create update delete apply help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from list" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from list" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from list" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from list" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from list" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from list" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from list" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from list" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from list" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from list" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from get" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from get" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from get" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from get" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from get" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from get" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from get" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from get" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from get" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from get" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from get" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l name -d 'Template name' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l description -d 'Template description' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l notes -d 'Template notes' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l default-name -d 'Default item name' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l default-description -d 'Default item description' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l default-quantity -d 'Default item quantity' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l default-manufacturer -d 'Default item manufacturer' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l default-model -d 'Default item model number' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l default-insured -d 'Default insured flag (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l default-lifetime-warranty -d 'Default lifetime warranty flag (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l default-warranty-details -d 'Default warranty details' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l default-location -d 'Default location name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l default-tag -d 'Default tag name or UUID (repeatable; missing tags auto-created)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l include-warranty-fields -d 'Include warranty fields on created items (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l include-purchase-fields -d 'Include purchase fields on created items (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l include-sold-fields -d 'Include sold fields on created items (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l field -d 'Default custom field KEY=VAL (repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l field-type -d 'Value type for --field entries' -r -f -a "text\t''
number\t''
boolean\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from create" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l name -d 'Updated template name' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l description -d 'Updated template description' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l notes -d 'Updated template notes' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l default-name -d 'Updated default item name' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l default-description -d 'Updated default item description' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l default-quantity -d 'Updated default item quantity' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l default-manufacturer -d 'Updated default item manufacturer' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l default-model -d 'Updated default item model number' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l default-insured -d 'Updated default insured flag (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l default-lifetime-warranty -d 'Updated default lifetime warranty flag (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l default-warranty-details -d 'Updated default warranty details' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l default-location -d 'Updated default location name, UUID, or \'none\'' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l default-tag -d 'Updated default tag name or UUID (repeatable; replaces tag list)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l include-warranty-fields -d 'Include warranty fields on created items (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l include-purchase-fields -d 'Include purchase fields on created items (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l include-sold-fields -d 'Include sold fields on created items (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l field -d 'Default custom field KEY=VAL to add/update (repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l field-type -d 'Value type for --field entries' -r -f -a "text\t''
number\t''
boolean\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from update" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from delete" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from delete" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from delete" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from delete" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from delete" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from delete" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from delete" -s y -l yes -d 'Skip interactive confirmation prompt'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from delete" -l force -d 'Skip interactive confirmation prompt'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from delete" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from delete" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from delete" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from delete" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from apply" -l name -d 'Item name (defaults to template\'s defaultName if omitted)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from apply" -l description -d 'Item description (defaults to template\'s defaultDescription if omitted)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from apply" -l parent -d 'Parent item/location name, ID, or \'none\'' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from apply" -l location -d 'Location name or ID (falls back to template\'s defaultLocation if omitted)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from apply" -l type -d 'Entity type name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from apply" -l tag -d 'Tag name or UUID (repeatable; defaults to template\'s defaultTags if omitted)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from apply" -l quantity -d 'Item quantity override' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from apply" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from apply" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from apply" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from apply" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from apply" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from apply" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from apply" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from apply" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from apply" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from apply" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from apply" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from help" -f -a "list" -d 'List all entity templates'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from help" -f -a "get" -d 'Fetch a single entity template by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from help" -f -a "create" -d 'Create a new entity template'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from help" -f -a "update" -d 'Update an existing entity template (GET -> Merge -> PUT)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete an entity template'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from help" -f -a "apply" -d 'Create a new item from a template (/api/v1/templates/{id}/create-item)'
complete -c hbctl -n "__fish_hbctl_using_subcommand template; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and not __fish_seen_subcommand_from list get create update delete apply help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and not __fish_seen_subcommand_from list get create update delete apply help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and not __fish_seen_subcommand_from list get create update delete apply help" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and not __fish_seen_subcommand_from list get create update delete apply help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and not __fish_seen_subcommand_from list get create update delete apply help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and not __fish_seen_subcommand_from list get create update delete apply help" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and not __fish_seen_subcommand_from list get create update delete apply help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and not __fish_seen_subcommand_from list get create update delete apply help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and not __fish_seen_subcommand_from list get create update delete apply help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and not __fish_seen_subcommand_from list get create update delete apply help" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and not __fish_seen_subcommand_from list get create update delete apply help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and not __fish_seen_subcommand_from list get create update delete apply help" -f -a "list" -d 'List all entity templates'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and not __fish_seen_subcommand_from list get create update delete apply help" -f -a "get" -d 'Fetch a single entity template by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and not __fish_seen_subcommand_from list get create update delete apply help" -f -a "create" -d 'Create a new entity template'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and not __fish_seen_subcommand_from list get create update delete apply help" -f -a "update" -d 'Update an existing entity template (GET -> Merge -> PUT)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and not __fish_seen_subcommand_from list get create update delete apply help" -f -a "delete" -d 'Delete an entity template'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and not __fish_seen_subcommand_from list get create update delete apply help" -f -a "apply" -d 'Create a new item from a template (/api/v1/templates/{id}/create-item)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and not __fish_seen_subcommand_from list get create update delete apply help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from list" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from list" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from list" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from list" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from list" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from list" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from list" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from list" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from list" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from list" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from get" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from get" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from get" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from get" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from get" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from get" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from get" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from get" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from get" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from get" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from get" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l name -d 'Template name' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l description -d 'Template description' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l notes -d 'Template notes' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l default-name -d 'Default item name' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l default-description -d 'Default item description' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l default-quantity -d 'Default item quantity' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l default-manufacturer -d 'Default item manufacturer' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l default-model -d 'Default item model number' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l default-insured -d 'Default insured flag (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l default-lifetime-warranty -d 'Default lifetime warranty flag (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l default-warranty-details -d 'Default warranty details' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l default-location -d 'Default location name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l default-tag -d 'Default tag name or UUID (repeatable; missing tags auto-created)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l include-warranty-fields -d 'Include warranty fields on created items (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l include-purchase-fields -d 'Include purchase fields on created items (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l include-sold-fields -d 'Include sold fields on created items (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l field -d 'Default custom field KEY=VAL (repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l field-type -d 'Value type for --field entries' -r -f -a "text\t''
number\t''
boolean\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from create" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l name -d 'Updated template name' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l description -d 'Updated template description' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l notes -d 'Updated template notes' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l default-name -d 'Updated default item name' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l default-description -d 'Updated default item description' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l default-quantity -d 'Updated default item quantity' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l default-manufacturer -d 'Updated default item manufacturer' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l default-model -d 'Updated default item model number' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l default-insured -d 'Updated default insured flag (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l default-lifetime-warranty -d 'Updated default lifetime warranty flag (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l default-warranty-details -d 'Updated default warranty details' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l default-location -d 'Updated default location name, UUID, or \'none\'' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l default-tag -d 'Updated default tag name or UUID (repeatable; replaces tag list)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l include-warranty-fields -d 'Include warranty fields on created items (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l include-purchase-fields -d 'Include purchase fields on created items (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l include-sold-fields -d 'Include sold fields on created items (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l field -d 'Default custom field KEY=VAL to add/update (repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l field-type -d 'Value type for --field entries' -r -f -a "text\t''
number\t''
boolean\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from update" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from delete" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from delete" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from delete" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from delete" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from delete" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from delete" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from delete" -s y -l yes -d 'Skip interactive confirmation prompt'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from delete" -l force -d 'Skip interactive confirmation prompt'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from delete" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from delete" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from delete" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from delete" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from apply" -l name -d 'Item name (defaults to template\'s defaultName if omitted)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from apply" -l description -d 'Item description (defaults to template\'s defaultDescription if omitted)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from apply" -l parent -d 'Parent item/location name, ID, or \'none\'' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from apply" -l location -d 'Location name or ID (falls back to template\'s defaultLocation if omitted)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from apply" -l type -d 'Entity type name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from apply" -l tag -d 'Tag name or UUID (repeatable; defaults to template\'s defaultTags if omitted)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from apply" -l quantity -d 'Item quantity override' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from apply" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from apply" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from apply" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from apply" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from apply" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from apply" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from apply" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from apply" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from apply" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from apply" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from apply" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from help" -f -a "list" -d 'List all entity templates'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from help" -f -a "get" -d 'Fetch a single entity template by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from help" -f -a "create" -d 'Create a new entity template'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from help" -f -a "update" -d 'Update an existing entity template (GET -> Merge -> PUT)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete an entity template'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from help" -f -a "apply" -d 'Create a new item from a template (/api/v1/templates/{id}/create-item)'
complete -c hbctl -n "__fish_hbctl_using_subcommand templates; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand barcode" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand barcode" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand barcode" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand barcode" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand barcode" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand barcode" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand barcode" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand barcode" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand barcode" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand barcode" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand barcode" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and not __fish_seen_subcommand_from list create update delete test help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and not __fish_seen_subcommand_from list create update delete test help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and not __fish_seen_subcommand_from list create update delete test help" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and not __fish_seen_subcommand_from list create update delete test help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and not __fish_seen_subcommand_from list create update delete test help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and not __fish_seen_subcommand_from list create update delete test help" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and not __fish_seen_subcommand_from list create update delete test help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and not __fish_seen_subcommand_from list create update delete test help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and not __fish_seen_subcommand_from list create update delete test help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and not __fish_seen_subcommand_from list create update delete test help" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and not __fish_seen_subcommand_from list create update delete test help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and not __fish_seen_subcommand_from list create update delete test help" -f -a "list" -d 'List configured notifiers (URLs redacted unless --reveal is passed)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and not __fish_seen_subcommand_from list create update delete test help" -f -a "create" -d 'Create a new notifier'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and not __fish_seen_subcommand_from list create update delete test help" -f -a "update" -d 'Update an existing notifier'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and not __fish_seen_subcommand_from list create update delete test help" -f -a "delete" -d 'Delete a notifier'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and not __fish_seen_subcommand_from list create update delete test help" -f -a "test" -d 'Send a test notification to a notifier ID/name or Shoutrrr URL'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and not __fish_seen_subcommand_from list create update delete test help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from list" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from list" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from list" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from list" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from list" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from list" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from list" -l reveal -d 'Display unredacted notifier URLs'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from list" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from list" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from list" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from list" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from create" -l name -d 'Notifier display name' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from create" -l notifier-url -l target -d 'Shoutrrr destination URL' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from create" -l active -d 'Whether the notifier is active (true/false; bare flag means true, defaults to true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from create" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from create" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from create" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from create" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from create" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from create" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from create" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from create" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from create" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from create" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from create" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from update" -l name -d 'Updated notifier name' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from update" -l notifier-url -l target -d 'Updated Shoutrrr destination URL' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from update" -l active -d 'Updated active state (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from update" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from update" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from update" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from update" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from update" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from update" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from update" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from update" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from update" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from update" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from update" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from delete" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from delete" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from delete" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from delete" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from delete" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from delete" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from delete" -s y -l yes -d 'Skip interactive confirmation prompt'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from delete" -l force -d 'Skip interactive confirmation prompt'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from delete" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from delete" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from delete" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from delete" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from test" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from test" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from test" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from test" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from test" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from test" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from test" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from test" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from test" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from test" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from test" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from help" -f -a "list" -d 'List configured notifiers (URLs redacted unless --reveal is passed)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from help" -f -a "create" -d 'Create a new notifier'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from help" -f -a "update" -d 'Update an existing notifier'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete a notifier'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from help" -f -a "test" -d 'Send a test notification to a notifier ID/name or Shoutrrr URL'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifier; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and not __fish_seen_subcommand_from list create update delete test help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and not __fish_seen_subcommand_from list create update delete test help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and not __fish_seen_subcommand_from list create update delete test help" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and not __fish_seen_subcommand_from list create update delete test help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and not __fish_seen_subcommand_from list create update delete test help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and not __fish_seen_subcommand_from list create update delete test help" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and not __fish_seen_subcommand_from list create update delete test help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and not __fish_seen_subcommand_from list create update delete test help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and not __fish_seen_subcommand_from list create update delete test help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and not __fish_seen_subcommand_from list create update delete test help" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and not __fish_seen_subcommand_from list create update delete test help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and not __fish_seen_subcommand_from list create update delete test help" -f -a "list" -d 'List configured notifiers (URLs redacted unless --reveal is passed)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and not __fish_seen_subcommand_from list create update delete test help" -f -a "create" -d 'Create a new notifier'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and not __fish_seen_subcommand_from list create update delete test help" -f -a "update" -d 'Update an existing notifier'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and not __fish_seen_subcommand_from list create update delete test help" -f -a "delete" -d 'Delete a notifier'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and not __fish_seen_subcommand_from list create update delete test help" -f -a "test" -d 'Send a test notification to a notifier ID/name or Shoutrrr URL'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and not __fish_seen_subcommand_from list create update delete test help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from list" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from list" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from list" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from list" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from list" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from list" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from list" -l reveal -d 'Display unredacted notifier URLs'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from list" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from list" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from list" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from list" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from create" -l name -d 'Notifier display name' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from create" -l notifier-url -l target -d 'Shoutrrr destination URL' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from create" -l active -d 'Whether the notifier is active (true/false; bare flag means true, defaults to true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from create" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from create" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from create" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from create" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from create" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from create" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from create" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from create" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from create" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from create" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from create" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from update" -l name -d 'Updated notifier name' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from update" -l notifier-url -l target -d 'Updated Shoutrrr destination URL' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from update" -l active -d 'Updated active state (true/false; bare flag means true)' -r -f -a "true\t''
false\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from update" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from update" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from update" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from update" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from update" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from update" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from update" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from update" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from update" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from update" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from update" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from delete" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from delete" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from delete" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from delete" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from delete" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from delete" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from delete" -s y -l yes -d 'Skip interactive confirmation prompt'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from delete" -l force -d 'Skip interactive confirmation prompt'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from delete" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from delete" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from delete" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from delete" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from test" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from test" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from test" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from test" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from test" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from test" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from test" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from test" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from test" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from test" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from test" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from help" -f -a "list" -d 'List configured notifiers (URLs redacted unless --reveal is passed)'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from help" -f -a "create" -d 'Create a new notifier'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from help" -f -a "update" -d 'Update an existing notifier'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete a notifier'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from help" -f -a "test" -d 'Send a test notification to a notifier ID/name or Shoutrrr URL'
complete -c hbctl -n "__fish_hbctl_using_subcommand notifiers; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -l version -d 'Target a specific release version or tag (e.g. 0.1.0 or v0.1.0)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -l check -d 'Check for available updates without installing'
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -s y -l yes -d 'Skip confirmation prompt before installing'
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -l version -d 'Target a specific release version or tag (e.g. 0.1.0 or v0.1.0)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -l output -d 'Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -s P -l profile -d 'Named configuration profile (env: HBCTL_PROFILE)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -l check -d 'Check for available updates without installing'
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -s y -l yes -d 'Skip confirmation prompt before installing'
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -l asset-id -d 'Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)'
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "auth" -d 'Authenticate with a remote Homebox instance (login, status, logout, refresh)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "item" -d 'Manage inventory items (/api/v1/entities)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "attachment" -d 'Manage item attachments (/api/v1/entities/{id}/attachments)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "search" -d 'Full-text and structured item search'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "field" -d 'List, get, set, or delete typed custom fields on an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "tag" -d 'Manage tags (/api/v1/tags)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "entity-types" -d 'Manage Homebox entity types (/api/v1/entity-types)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "status" -d 'Check remote Homebox server connectivity and version (/api/v1/status)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "api" -d 'Issue a raw authenticated HTTP request against any Homebox API endpoint'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "maintenance" -d 'Manage maintenance log entries (/api/v1/maintenance)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "export" -d 'Export filtered items to JSON, CSV, or Markdown'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "backup" -d 'Create a portable full-inventory backup (directory or .tar.gz archive)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "label" -d 'Generate or print a Homebox item, asset, or location label (/api/v1/labelmaker)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "qr" -d 'Generate a QR code image (/api/v1/qrcode)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "actions" -d 'Run Homebox server maintenance actions (/api/v1/actions/*)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "stats" -d 'Display inventory statistics and breakdowns (/api/v1/groups/statistics*)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "config" -d 'Inspect effective configuration and manage named profiles'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "template" -d 'Manage item templates and create items from templates (/api/v1/templates)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "barcode" -d 'Look up product metadata by barcode (/api/v1/products/search-from-barcode)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "notifier" -d 'Manage Shoutrrr notification channels (/api/v1/notifiers)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "completions" -d 'Generate shell completion scripts'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "man" -d 'Generate UNIX roff man page'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "update" -d 'Check for and install the latest hbctl release from GitHub'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types status api maintenance export backup label qr actions stats config template barcode notifier completions man update help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from auth" -f -a "login" -d 'Authenticate with Homebox via API key (--with-token) or email/password'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from auth" -f -a "status" -d 'Check authentication status and validate the active session'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from auth" -f -a "logout" -d 'Remove stored credentials from OS keyring and local fallback store'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from auth" -f -a "refresh" -d 'Refresh an active JWT session token'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from item" -f -a "list" -d 'List inventory items'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from item" -f -a "get" -d 'Fetch a single item by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from item" -f -a "create" -d 'Create a new item (auto-persists custom fields via follow-up PUT)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from item" -f -a "update" -d 'Update an existing item via GET -> Merge -> PUT'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from item" -f -a "upsert" -d 'Create or update an item matched by name'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from item" -f -a "delete" -d 'Delete an item by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from item" -f -a "import" -d 'Bulk import items from JSON or CSV (file or \'-\' for stdin)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from item" -f -a "dedup" -d 'Detect (and optionally delete or merge) duplicate items'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from item" -f -a "move" -d 'Move an item under a parent item/location (or \'none\' to unparent)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from item" -f -a "duplicate" -d 'Duplicate an existing item one or more times'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from item" -f -a "path" -d 'Display the location/parent breadcrumb path for an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from item" -f -a "tree" -d 'Render item parent/location hierarchy as a tree'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from attachment" -f -a "upload" -d 'Upload one or more files as item attachments'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from attachment" -f -a "list" -d 'List attachments on an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from attachment" -f -a "download" -d 'Stream-download attachments from one or multiple items'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from attachment" -f -a "delete" -d 'Delete an attachment from an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from attachment" -f -a "set-primary" -d 'Mark an existing attachment as the item\'s primary photo'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from attachment" -f -a "update" -d 'Update attachment metadata (title, type, primary)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from attachment" -f -a "add-link" -d 'Attach an external HTTP(S) URL link to an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from field" -f -a "list" -d 'List all custom fields on an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from field" -f -a "get" -d 'Get a custom field value from an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from field" -f -a "set" -d 'Set a typed custom field on an item via GET -> Merge -> PUT'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from field" -f -a "delete" -d 'Delete a custom field from an item via GET -> Remove -> PUT'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from tag" -f -a "list" -d 'List all tags'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from tag" -f -a "create" -d 'Create a new tag'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from tag" -f -a "update" -d 'Update an existing tag by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from tag" -f -a "delete" -d 'Delete a tag by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from entity-types" -f -a "list" -d 'List all entity types'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from entity-types" -f -a "create" -d 'Create a new entity type'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from entity-types" -f -a "delete" -d 'Delete an entity type by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from maintenance" -f -a "list" -d 'List maintenance log entries (globally or for a specific entity)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from maintenance" -f -a "create" -d 'Create a maintenance log entry on an entity'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from maintenance" -f -a "update" -d 'Update an existing maintenance log entry by entry ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from maintenance" -f -a "delete" -d 'Delete a maintenance log entry by entry ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from actions" -f -a "ensure-asset-ids" -d 'Ensure all items in Homebox have an asset ID assigned (/api/v1/actions/ensure-asset-ids)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from actions" -f -a "create-missing-thumbnails" -d 'Create thumbnails for attachments missing them (/api/v1/actions/create-missing-thumbnails)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from stats" -f -a "overview" -d 'Group-wide overview statistics (/api/v1/groups/statistics + upcoming maintenance)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from stats" -f -a "tags" -d 'Tag purchase-value breakdown (/api/v1/groups/statistics/tags)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from stats" -f -a "locations" -d 'Location purchase-value breakdown (/api/v1/groups/statistics/locations)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from stats" -f -a "entity-types" -d 'Entity-type count and purchase-value breakdown'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from stats" -f -a "purchase-price" -d 'Purchase value over time (/api/v1/groups/statistics/purchase-price)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from config" -f -a "show" -d 'Display effective resolved configuration (secrets redacted as Bearer ***)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from config" -f -a "profiles" -d 'List configured profiles and indicate active/default selection'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from config" -f -a "use" -d 'Switch the active default profile in user config'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from template" -f -a "list" -d 'List all entity templates'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from template" -f -a "get" -d 'Fetch a single entity template by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from template" -f -a "create" -d 'Create a new entity template'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from template" -f -a "update" -d 'Update an existing entity template (GET -> Merge -> PUT)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from template" -f -a "delete" -d 'Delete an entity template'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from template" -f -a "apply" -d 'Create a new item from a template (/api/v1/templates/{id}/create-item)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from notifier" -f -a "list" -d 'List configured notifiers (URLs redacted unless --reveal is passed)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from notifier" -f -a "create" -d 'Create a new notifier'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from notifier" -f -a "update" -d 'Update an existing notifier'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from notifier" -f -a "delete" -d 'Delete a notifier'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from notifier" -f -a "test" -d 'Send a test notification to a notifier ID/name or Shoutrrr URL'
