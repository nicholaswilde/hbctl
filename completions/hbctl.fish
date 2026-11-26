# Print an optspec for argparse to handle cmd's options that are independent of any subcommand.
function __fish_hbctl_global_optspecs
    string join \n url= api-key= output= json select= dry-run q/quiet C/config= h/help V/version
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
complete -c hbctl -n "__fish_hbctl_needs_command" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_needs_command" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_needs_command" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_needs_command" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_needs_command" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_needs_command" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_needs_command" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_needs_command" -s V -l version -d 'Print version'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "auth" -d 'Authenticate with a remote Homebox instance (login, status, logout, refresh)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "item" -d 'Manage inventory items (/api/v1/entities)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "attachment" -d 'Manage item attachments (/api/v1/entities/{id}/attachments)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "search" -d 'Full-text and structured item search'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "field" -d 'Get or set typed custom fields on an item'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "tag" -d 'Manage tags (/api/v1/tags)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "entity-types" -d 'List Homebox entity types (/api/v1/entity-types)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "entity-type" -d 'List Homebox entity types (/api/v1/entity-types)'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "export" -d 'Export filtered items to JSON, CSV, or Markdown'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "completions" -d 'Generate shell completion scripts'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "man" -d 'Generate UNIX roff man page'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "update" -d 'Check for and install the latest hbctl release from GitHub'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "self-update" -d 'Check for and install the latest hbctl release from GitHub'
complete -c hbctl -n "__fish_hbctl_needs_command" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -f -a "login" -d 'Authenticate with Homebox via API key (--with-token) or email/password'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -f -a "status" -d 'Check authentication status and validate the active session'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -f -a "logout" -d 'Remove stored credentials from OS keyring and local fallback store'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -f -a "refresh" -d 'Refresh an active JWT session token'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and not __fish_seen_subcommand_from login status logout refresh help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -s u -l username -d 'Email or username for password login (POST /api/v1/users/login)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -l with-token -d 'Read a Homebox API key (hb_...) or Bearer token from stdin'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -l password-stdin -d 'Read login password from stdin instead of prompting interactively'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -l insecure-storage -d 'Store token in 0600 local file store instead of OS keyring'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from login" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from status" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -l insecure-storage -d 'Skip OS keyring and only clear local 0600 fallback store'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from logout" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -l insecure-storage -d 'Store refreshed token in 0600 local file store instead of OS keyring'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from refresh" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from help" -f -a "login" -d 'Authenticate with Homebox via API key (--with-token) or email/password'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from help" -f -a "status" -d 'Check authentication status and validate the active session'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from help" -f -a "logout" -d 'Remove stored credentials from OS keyring and local fallback store'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from help" -f -a "refresh" -d 'Refresh an active JWT session token'
complete -c hbctl -n "__fish_hbctl_using_subcommand auth; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup help" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup help" -f -a "list" -d 'List inventory items'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup help" -f -a "get" -d 'Fetch a single item by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup help" -f -a "create" -d 'Create a new item (auto-persists custom fields via follow-up PUT)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup help" -f -a "update" -d 'Update an existing item via GET -> Merge -> PUT'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup help" -f -a "upsert" -d 'Create or update an item matched by name'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup help" -f -a "delete" -d 'Delete an item by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup help" -f -a "import" -d 'Bulk import items from JSON or CSV (file or \'-\' for stdin)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup help" -f -a "dedup" -d 'Detect (and optionally delete or merge) duplicate items'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and not __fish_seen_subcommand_from list get create update upsert delete import dedup help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l tag -d 'Filter by tag name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l type -d 'Filter by entity type name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l has-field -d 'Only include items having the named custom field (hydrates details if missing)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l page-size -d 'Page size for listing' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l all -d 'Fetch all pages'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from get" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l name -d 'Item name (required unless supplied via --from-json)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l description -d 'Item description' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l type -d 'Entity type name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l tag -d 'Tag name or UUID (repeatable; missing tags auto-created)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l manufacturer -d 'Manufacturer (normalized into custom field \'Manufacturer\')' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l model -d 'Model number (normalized into custom field \'Model Number\')' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l notes -d 'Notes (normalized into custom field \'Notes\')' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l quantity -d 'Item quantity' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l purchase-price -d 'Purchase price' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l purchase-date -d 'Purchase date (YYYY-MM-DD)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l purchase-from -d 'Purchase vendor/source' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l field -d 'Custom field KEY=VAL (repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l field-type -d 'Value type for --field entries' -r -f -a "text\t''
number\t''
boolean\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l from-json -d 'Load initial item JSON from file path or \'-\' for stdin' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from create" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l name -d 'Updated item name' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l description -d 'Updated item description' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l type -d 'Entity type name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l tag -d 'Tag name or UUID to merge (repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l manufacturer -d 'Manufacturer (merged into custom field \'Manufacturer\')' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l model -d 'Model number (merged into custom field \'Model Number\')' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l quantity -d 'Updated quantity' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l purchase-price -d 'Updated purchase price' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l purchase-date -d 'Updated purchase date (YYYY-MM-DD)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l purchase-from -d 'Updated purchase source' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l notes -d 'Notes (merged into custom field \'Notes\')' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l field -d 'Custom field KEY=VAL to upsert (repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l field-type -d 'Value type for --field entries' -r -f -a "text\t''
number\t''
boolean\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l from-json -d 'Load patch JSON from file path or \'-\' for stdin' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from update" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l name -d 'Item name to match or create' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l description -d 'Item description' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l type -d 'Entity type name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l tag -d 'Tag name or UUID (repeatable; missing tags auto-created)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l manufacturer -d 'Manufacturer' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l model -d 'Model number' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l notes -d 'Notes' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l quantity -d 'Quantity' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l purchase-price -d 'Purchase price' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l purchase-date -d 'Purchase date (YYYY-MM-DD)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l purchase-from -d 'Purchase source' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l field -d 'Custom field KEY=VAL (repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l field-type -d 'Value type for --field entries' -r -f -a "text\t''
number\t''
boolean\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from upsert" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -l force -d 'Skip interactive confirmation prompt'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l format -d 'Input format (inferred from extension if omitted; defaults to json for stdin)' -r -f -a "json\t''
csv\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l skip-existing -d 'Skip items whose name already exists in Homebox'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l update-existing -d 'Update items whose name already exists in Homebox'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from import" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -l threshold -d 'Jaccard similarity threshold for near-duplicate detection (0.0..=1.0)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -l delete -d 'Delete detected duplicate items, retaining only the keeper'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -l merge -d 'Sum duplicate quantities onto the keeper before deleting duplicates (implies --delete)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from dedup" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "list" -d 'List inventory items'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "get" -d 'Fetch a single item by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "create" -d 'Create a new item (auto-persists custom fields via follow-up PUT)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "update" -d 'Update an existing item via GET -> Merge -> PUT'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "upsert" -d 'Create or update an item matched by name'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete an item by ID'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "import" -d 'Bulk import items from JSON or CSV (file or \'-\' for stdin)'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "dedup" -d 'Detect (and optionally delete or merge) duplicate items'
complete -c hbctl -n "__fish_hbctl_using_subcommand item; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete help" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete help" -f -a "upload" -d 'Upload one or more files as item attachments'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete help" -f -a "list" -d 'List attachments on an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete help" -f -a "download" -d 'Stream-download one or all attachments from an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete help" -f -a "delete" -d 'Delete an attachment from an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and not __fish_seen_subcommand_from upload list download delete help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l skip-existing -d 'Skip files that already exist on the item (default behavior)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l overwrite -d 'Delete and re-upload files that already exist on the item'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l force -d 'Allow uploading images larger than 500KB'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from upload" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l mime -d 'Filter attachments by MIME type (e.g. application/pdf)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l ext -d 'Filter attachments by file extension (e.g. pdf)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l out -d 'Output file path (single download) or directory (multi-download / --all)' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l all -d 'Download all matching attachments on the item'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l overwrite -d 'Overwrite existing local files instead of skipping'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from download" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from help" -f -a "upload" -d 'Upload one or more files as item attachments'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from help" -f -a "list" -d 'List attachments on an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from help" -f -a "download" -d 'Stream-download one or all attachments from an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete an attachment from an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand attachment; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l tag -d 'Filter by tag name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l model -d 'Filter by model number (exact or substring, case-insensitive)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l serial -d 'Filter by serial number (exact or substring, case-insensitive)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l manufacturer -d 'Filter by manufacturer (exact or substring, case-insensitive)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand search" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from get set help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from get set help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from get set help" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from get set help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from get set help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from get set help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from get set help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from get set help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from get set help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from get set help" -f -a "get" -d 'Get a custom field value from an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from get set help" -f -a "set" -d 'Set a typed custom field on an item via GET -> Merge -> PUT'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and not __fish_seen_subcommand_from get set help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from get" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -l type -d 'Custom field value type' -r -f -a "text\t''
number\t''
boolean\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from set" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from help" -f -a "get" -d 'Get a custom field value from an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from help" -f -a "set" -d 'Set a typed custom field on an item via GET -> Merge -> PUT'
complete -c hbctl -n "__fish_hbctl_using_subcommand field; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create help" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create help" -f -a "list" -d 'List all tags'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create help" -f -a "create" -d 'Create a new tag'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and not __fish_seen_subcommand_from list create help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from create" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from help" -f -a "list" -d 'List all tags'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from help" -f -a "create" -d 'Create a new tag'
complete -c hbctl -n "__fish_hbctl_using_subcommand tag; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list help" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list help" -f -a "list" -d 'List all entity types'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and not __fish_seen_subcommand_from list help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from help" -f -a "list" -d 'List all entity types'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-types; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list help" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list help" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list help" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list help" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list help" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list help" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list help" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list help" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list help" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list help" -f -a "list" -d 'List all entity types'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and not __fish_seen_subcommand_from list help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from help" -f -a "list" -d 'List all entity types'
complete -c hbctl -n "__fish_hbctl_using_subcommand entity-type; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l tag -d 'Filter by tag name or UUID' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l has-field -d 'Require items to have the named custom field' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l field -d 'Custom field column(s) to include in export (repeatable)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l sort -d 'Sort exported items by name or id' -r -f -a "name\t''
id\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l format -d 'Export format (json, csv, markdown)' -r -f -a "json\t''
csv\t''
markdown\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand export" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand completions" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand man" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -l version -d 'Target a specific release version or tag (e.g. 0.1.0 or v0.1.0)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -l check -d 'Check for available updates without installing'
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -s y -l yes -d 'Skip confirmation prompt before installing'
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand update" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -l version -d 'Target a specific release version or tag (e.g. 0.1.0 or v0.1.0)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -l url -d 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -l api-key -d 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -l output -d 'Output format (table, json, plain) [env: HBCTL_OUTPUT]' -r -f -a "table\t''
json\t''
plain\t''"
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -l select -d 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)' -r
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -s C -l config -d 'Path to explicit TOML configuration file' -r -F
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -l check -d 'Check for available updates without installing'
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -s y -l yes -d 'Skip confirmation prompt before installing'
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -l json -d 'Shorthand for --output json (emits compact JSON)'
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -l dry-run -d 'Preview mutating requests without hitting the server (redacts Authorization)'
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -s q -l quiet -d 'Output only created/affected IDs for shell piping'
complete -c hbctl -n "__fish_hbctl_using_subcommand self-update" -s h -l help -d 'Print help'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types export completions man update help" -f -a "auth" -d 'Authenticate with a remote Homebox instance (login, status, logout, refresh)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types export completions man update help" -f -a "item" -d 'Manage inventory items (/api/v1/entities)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types export completions man update help" -f -a "attachment" -d 'Manage item attachments (/api/v1/entities/{id}/attachments)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types export completions man update help" -f -a "search" -d 'Full-text and structured item search'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types export completions man update help" -f -a "field" -d 'Get or set typed custom fields on an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types export completions man update help" -f -a "tag" -d 'Manage tags (/api/v1/tags)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types export completions man update help" -f -a "entity-types" -d 'List Homebox entity types (/api/v1/entity-types)'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types export completions man update help" -f -a "export" -d 'Export filtered items to JSON, CSV, or Markdown'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types export completions man update help" -f -a "completions" -d 'Generate shell completion scripts'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types export completions man update help" -f -a "man" -d 'Generate UNIX roff man page'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types export completions man update help" -f -a "update" -d 'Check for and install the latest hbctl release from GitHub'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and not __fish_seen_subcommand_from auth item attachment search field tag entity-types export completions man update help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
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
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from attachment" -f -a "upload" -d 'Upload one or more files as item attachments'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from attachment" -f -a "list" -d 'List attachments on an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from attachment" -f -a "download" -d 'Stream-download one or all attachments from an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from attachment" -f -a "delete" -d 'Delete an attachment from an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from field" -f -a "get" -d 'Get a custom field value from an item'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from field" -f -a "set" -d 'Set a typed custom field on an item via GET -> Merge -> PUT'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from tag" -f -a "list" -d 'List all tags'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from tag" -f -a "create" -d 'Create a new tag'
complete -c hbctl -n "__fish_hbctl_using_subcommand help; and __fish_seen_subcommand_from entity-types" -f -a "list" -d 'List all entity types'
