
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

Register-ArgumentCompleter -Native -CommandName 'hbctl' -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $commandElements = $commandAst.CommandElements
    $command = @(
        'hbctl'
        for ($i = 1; $i -lt $commandElements.Count; $i++) {
            $element = $commandElements[$i]
            if ($element -isnot [StringConstantExpressionAst] -or
                $element.StringConstantType -ne [StringConstantType]::BareWord -or
                $element.Value.StartsWith('-') -or
                $element.Value -eq $wordToComplete) {
                break
        }
        $element.Value
    }) -join ';'

    $completions = @(switch ($command) {
        'hbctl' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('-V', '-V ', [CompletionResultType]::ParameterName, 'Print version')
            [CompletionResult]::new('--version', '--version', [CompletionResultType]::ParameterName, 'Print version')
            [CompletionResult]::new('auth', 'auth', [CompletionResultType]::ParameterValue, 'Authenticate with a remote Homebox instance (login, status, logout, refresh)')
            [CompletionResult]::new('item', 'item', [CompletionResultType]::ParameterValue, 'Manage inventory items (/api/v1/entities)')
            [CompletionResult]::new('attachment', 'attachment', [CompletionResultType]::ParameterValue, 'Manage item attachments (/api/v1/entities/{id}/attachments)')
            [CompletionResult]::new('search', 'search', [CompletionResultType]::ParameterValue, 'Full-text and structured item search')
            [CompletionResult]::new('field', 'field', [CompletionResultType]::ParameterValue, 'List, get, set, or delete typed custom fields on an item')
            [CompletionResult]::new('tag', 'tag', [CompletionResultType]::ParameterValue, 'Manage tags (/api/v1/tags)')
            [CompletionResult]::new('entity-types', 'entity-types', [CompletionResultType]::ParameterValue, 'Manage Homebox entity types (/api/v1/entity-types)')
            [CompletionResult]::new('entity-type', 'entity-type', [CompletionResultType]::ParameterValue, 'Manage Homebox entity types (/api/v1/entity-types)')
            [CompletionResult]::new('status', 'status', [CompletionResultType]::ParameterValue, 'Check remote Homebox server connectivity and version (/api/v1/status)')
            [CompletionResult]::new('api', 'api', [CompletionResultType]::ParameterValue, 'Issue a raw authenticated HTTP request against any Homebox API endpoint')
            [CompletionResult]::new('maintenance', 'maintenance', [CompletionResultType]::ParameterValue, 'Manage maintenance log entries (/api/v1/maintenance)')
            [CompletionResult]::new('export', 'export', [CompletionResultType]::ParameterValue, 'Export filtered items to JSON, CSV, or Markdown')
            [CompletionResult]::new('completions', 'completions', [CompletionResultType]::ParameterValue, 'Generate shell completion scripts')
            [CompletionResult]::new('man', 'man', [CompletionResultType]::ParameterValue, 'Generate UNIX roff man page')
            [CompletionResult]::new('update', 'update', [CompletionResultType]::ParameterValue, 'Check for and install the latest hbctl release from GitHub')
            [CompletionResult]::new('self-update', 'self-update', [CompletionResultType]::ParameterValue, 'Check for and install the latest hbctl release from GitHub')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;auth' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('login', 'login', [CompletionResultType]::ParameterValue, 'Authenticate with Homebox via API key (--with-token) or email/password')
            [CompletionResult]::new('status', 'status', [CompletionResultType]::ParameterValue, 'Check authentication status and validate the active session')
            [CompletionResult]::new('logout', 'logout', [CompletionResultType]::ParameterValue, 'Remove stored credentials from OS keyring and local fallback store')
            [CompletionResult]::new('refresh', 'refresh', [CompletionResultType]::ParameterValue, 'Refresh an active JWT session token')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;auth;login' {
            [CompletionResult]::new('-u', '-u', [CompletionResultType]::ParameterName, 'Email or username for password login (POST /api/v1/users/login)')
            [CompletionResult]::new('--username', '--username', [CompletionResultType]::ParameterName, 'Email or username for password login (POST /api/v1/users/login)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--with-token', '--with-token', [CompletionResultType]::ParameterName, 'Read a Homebox API key (hb_...) or Bearer token from stdin')
            [CompletionResult]::new('--password-stdin', '--password-stdin', [CompletionResultType]::ParameterName, 'Read login password from stdin instead of prompting interactively')
            [CompletionResult]::new('--insecure-storage', '--insecure-storage', [CompletionResultType]::ParameterName, 'Store token in 0600 local file store instead of OS keyring')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;auth;status' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;auth;logout' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--insecure-storage', '--insecure-storage', [CompletionResultType]::ParameterName, 'Skip OS keyring and only clear local 0600 fallback store')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;auth;refresh' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--insecure-storage', '--insecure-storage', [CompletionResultType]::ParameterName, 'Store refreshed token in 0600 local file store instead of OS keyring')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;auth;help' {
            [CompletionResult]::new('login', 'login', [CompletionResultType]::ParameterValue, 'Authenticate with Homebox via API key (--with-token) or email/password')
            [CompletionResult]::new('status', 'status', [CompletionResultType]::ParameterValue, 'Check authentication status and validate the active session')
            [CompletionResult]::new('logout', 'logout', [CompletionResultType]::ParameterValue, 'Remove stored credentials from OS keyring and local fallback store')
            [CompletionResult]::new('refresh', 'refresh', [CompletionResultType]::ParameterValue, 'Refresh an active JWT session token')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;auth;help;login' {
            break
        }
        'hbctl;auth;help;status' {
            break
        }
        'hbctl;auth;help;logout' {
            break
        }
        'hbctl;auth;help;refresh' {
            break
        }
        'hbctl;auth;help;help' {
            break
        }
        'hbctl;item' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List inventory items')
            [CompletionResult]::new('get', 'get', [CompletionResultType]::ParameterValue, 'Fetch a single item by ID')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create a new item (auto-persists custom fields via follow-up PUT)')
            [CompletionResult]::new('update', 'update', [CompletionResultType]::ParameterValue, 'Update an existing item via GET -> Merge -> PUT')
            [CompletionResult]::new('upsert', 'upsert', [CompletionResultType]::ParameterValue, 'Create or update an item matched by name')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete an item by ID')
            [CompletionResult]::new('import', 'import', [CompletionResultType]::ParameterValue, 'Bulk import items from JSON or CSV (file or ''-'' for stdin)')
            [CompletionResult]::new('dedup', 'dedup', [CompletionResultType]::ParameterValue, 'Detect (and optionally delete or merge) duplicate items')
            [CompletionResult]::new('move', 'move', [CompletionResultType]::ParameterValue, 'Move an item under a parent item/location (or ''none'' to unparent)')
            [CompletionResult]::new('duplicate', 'duplicate', [CompletionResultType]::ParameterValue, 'Duplicate an existing item one or more times')
            [CompletionResult]::new('path', 'path', [CompletionResultType]::ParameterValue, 'Display the location/parent breadcrumb path for an item')
            [CompletionResult]::new('tree', 'tree', [CompletionResultType]::ParameterValue, 'Render item parent/location hierarchy as a tree')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;item;list' {
            [CompletionResult]::new('--tag', '--tag', [CompletionResultType]::ParameterName, 'Filter by tag name or UUID')
            [CompletionResult]::new('--type', '--type', [CompletionResultType]::ParameterName, 'Filter by entity type name or UUID')
            [CompletionResult]::new('--parent', '--parent', [CompletionResultType]::ParameterName, 'Filter by parent item name, ID, or ''none'' for top-level items')
            [CompletionResult]::new('--has-field', '--has-field', [CompletionResultType]::ParameterName, 'Only include items having the named custom field (hydrates details if missing)')
            [CompletionResult]::new('--page-size', '--page-size', [CompletionResultType]::ParameterName, 'Page size for listing')
            [CompletionResult]::new('--warranty-expiring', '--warranty-expiring', [CompletionResultType]::ParameterName, 'Only show items with a warranty expiring within the next DAYS days (excludes lifetime warranties)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--all', '--all', [CompletionResultType]::ParameterName, 'Fetch all pages')
            [CompletionResult]::new('--include-archived', '--include-archived', [CompletionResultType]::ParameterName, 'Include archived items in results')
            [CompletionResult]::new('--archived-only', '--archived-only', [CompletionResultType]::ParameterName, 'Only show archived items (implies --include-archived)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;item;get' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--with-path', '--with-path', [CompletionResultType]::ParameterName, 'Include full location/parent breadcrumb path in output')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;item;create' {
            [CompletionResult]::new('--name', '--name', [CompletionResultType]::ParameterName, 'Item name (required unless supplied via --from-json)')
            [CompletionResult]::new('--description', '--description', [CompletionResultType]::ParameterName, 'Item description')
            [CompletionResult]::new('--type', '--type', [CompletionResultType]::ParameterName, 'Entity type name or UUID')
            [CompletionResult]::new('--parent', '--parent', [CompletionResultType]::ParameterName, 'Parent item/location name, ID, or ''none''')
            [CompletionResult]::new('--tag', '--tag', [CompletionResultType]::ParameterName, 'Tag name or UUID (repeatable; missing tags auto-created)')
            [CompletionResult]::new('--manufacturer', '--manufacturer', [CompletionResultType]::ParameterName, 'Manufacturer (normalized into custom field ''Manufacturer'')')
            [CompletionResult]::new('--model', '--model', [CompletionResultType]::ParameterName, 'Model number (normalized into custom field ''Model Number'')')
            [CompletionResult]::new('--serial', '--serial', [CompletionResultType]::ParameterName, 'Serial number (normalized into custom field ''Serial Number'')')
            [CompletionResult]::new('--notes', '--notes', [CompletionResultType]::ParameterName, 'Notes (normalized into custom field ''Notes'')')
            [CompletionResult]::new('--quantity', '--quantity', [CompletionResultType]::ParameterName, 'Item quantity')
            [CompletionResult]::new('--purchase-price', '--purchase-price', [CompletionResultType]::ParameterName, 'Purchase price')
            [CompletionResult]::new('--purchase-date', '--purchase-date', [CompletionResultType]::ParameterName, 'Purchase date (YYYY-MM-DD)')
            [CompletionResult]::new('--purchase-from', '--purchase-from', [CompletionResultType]::ParameterName, 'Purchase vendor/source')
            [CompletionResult]::new('--archived', '--archived', [CompletionResultType]::ParameterName, 'Mark item as archived (true/false; bare flag means true)')
            [CompletionResult]::new('--insured', '--insured', [CompletionResultType]::ParameterName, 'Mark item as insured (true/false; bare flag means true)')
            [CompletionResult]::new('--lifetime-warranty', '--lifetime-warranty', [CompletionResultType]::ParameterName, 'Mark item as having a lifetime warranty (true/false; bare flag means true)')
            [CompletionResult]::new('--warranty-expires', '--warranty-expires', [CompletionResultType]::ParameterName, 'Warranty expiration date (YYYY-MM-DD or RFC3339)')
            [CompletionResult]::new('--warranty-details', '--warranty-details', [CompletionResultType]::ParameterName, 'Warranty details or terms')
            [CompletionResult]::new('--sold-time', '--sold-time', [CompletionResultType]::ParameterName, 'Date/time the item was sold (YYYY-MM-DD or RFC3339)')
            [CompletionResult]::new('--sold-to', '--sold-to', [CompletionResultType]::ParameterName, 'Buyer name or recipient the item was sold to')
            [CompletionResult]::new('--sold-price', '--sold-price', [CompletionResultType]::ParameterName, 'Sale price')
            [CompletionResult]::new('--sold-notes', '--sold-notes', [CompletionResultType]::ParameterName, 'Notes about the sale')
            [CompletionResult]::new('--field', '--field', [CompletionResultType]::ParameterName, 'Custom field KEY=VAL (repeatable)')
            [CompletionResult]::new('--field-type', '--field-type', [CompletionResultType]::ParameterName, 'Value type for --field entries')
            [CompletionResult]::new('--from-json', '--from-json', [CompletionResultType]::ParameterName, 'Load initial item JSON from file path or ''-'' for stdin')
            [CompletionResult]::new('--attach', '--attach', [CompletionResultType]::ParameterName, 'Local file path(s) to attach after creating the item (`FILE` or `FILE=REMOTE_NAME`, repeatable)')
            [CompletionResult]::new('--attach-url', '--attach-url', [CompletionResultType]::ParameterName, 'Remote HTTP(S) URL(s) to download and attach (`URL` or `URL=REMOTE_NAME`, repeatable)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--attach-best-effort', '--attach-best-effort', [CompletionResultType]::ParameterName, 'Treat attachment failures as non-fatal warnings and include `attachmentErrors` in JSON output')
            [CompletionResult]::new('--optimize', '--optimize', [CompletionResultType]::ParameterName, 'Automatically resize/compress oversized images before upload')
            [CompletionResult]::new('--force', '--force', [CompletionResultType]::ParameterName, 'Allow attaching images larger than 500KB')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;item;update' {
            [CompletionResult]::new('--items-from', '--items-from', [CompletionResultType]::ParameterName, 'Read newline-delimited entity IDs to update from a file or ''-'' (stdin)')
            [CompletionResult]::new('--filter-tag', '--filter-tag', [CompletionResultType]::ParameterName, 'Select items to update matching this tag name or UUID')
            [CompletionResult]::new('--filter-parent', '--filter-parent', [CompletionResultType]::ParameterName, 'Select items to update under this parent item/location name, ID, or ''none''')
            [CompletionResult]::new('--filter-type', '--filter-type', [CompletionResultType]::ParameterName, 'Select items to update matching this entity type name or UUID')
            [CompletionResult]::new('--name', '--name', [CompletionResultType]::ParameterName, 'Updated item name')
            [CompletionResult]::new('--description', '--description', [CompletionResultType]::ParameterName, 'Updated item description')
            [CompletionResult]::new('--type', '--type', [CompletionResultType]::ParameterName, 'Entity type name or UUID')
            [CompletionResult]::new('--parent', '--parent', [CompletionResultType]::ParameterName, 'Parent item/location name, ID, or ''none'' to unparent')
            [CompletionResult]::new('--tag', '--tag', [CompletionResultType]::ParameterName, 'Tag name or UUID to merge (repeatable)')
            [CompletionResult]::new('--add-tag', '--add-tag', [CompletionResultType]::ParameterName, 'Tag name or UUID to add while preserving existing tags (repeatable)')
            [CompletionResult]::new('--remove-tag', '--remove-tag', [CompletionResultType]::ParameterName, 'Tag name or UUID to remove while preserving other existing tags (repeatable)')
            [CompletionResult]::new('--manufacturer', '--manufacturer', [CompletionResultType]::ParameterName, 'Manufacturer (merged into custom field ''Manufacturer'')')
            [CompletionResult]::new('--model', '--model', [CompletionResultType]::ParameterName, 'Model number (merged into custom field ''Model Number'')')
            [CompletionResult]::new('--serial', '--serial', [CompletionResultType]::ParameterName, 'Serial number (merged into custom field ''Serial Number'')')
            [CompletionResult]::new('--quantity', '--quantity', [CompletionResultType]::ParameterName, 'Updated quantity')
            [CompletionResult]::new('--purchase-price', '--purchase-price', [CompletionResultType]::ParameterName, 'Updated purchase price')
            [CompletionResult]::new('--purchase-date', '--purchase-date', [CompletionResultType]::ParameterName, 'Updated purchase date (YYYY-MM-DD)')
            [CompletionResult]::new('--purchase-from', '--purchase-from', [CompletionResultType]::ParameterName, 'Updated purchase source')
            [CompletionResult]::new('--archived', '--archived', [CompletionResultType]::ParameterName, 'Mark item as archived (true/false; bare flag means true)')
            [CompletionResult]::new('--insured', '--insured', [CompletionResultType]::ParameterName, 'Mark item as insured (true/false; bare flag means true)')
            [CompletionResult]::new('--lifetime-warranty', '--lifetime-warranty', [CompletionResultType]::ParameterName, 'Mark item as having a lifetime warranty (true/false; bare flag means true)')
            [CompletionResult]::new('--warranty-expires', '--warranty-expires', [CompletionResultType]::ParameterName, 'Warranty expiration date (YYYY-MM-DD or RFC3339)')
            [CompletionResult]::new('--warranty-details', '--warranty-details', [CompletionResultType]::ParameterName, 'Warranty details or terms')
            [CompletionResult]::new('--sold-time', '--sold-time', [CompletionResultType]::ParameterName, 'Date/time the item was sold (YYYY-MM-DD or RFC3339)')
            [CompletionResult]::new('--sold-to', '--sold-to', [CompletionResultType]::ParameterName, 'Buyer name or recipient the item was sold to')
            [CompletionResult]::new('--sold-price', '--sold-price', [CompletionResultType]::ParameterName, 'Sale price')
            [CompletionResult]::new('--sold-notes', '--sold-notes', [CompletionResultType]::ParameterName, 'Notes about the sale')
            [CompletionResult]::new('--notes', '--notes', [CompletionResultType]::ParameterName, 'Notes (merged into custom field ''Notes'')')
            [CompletionResult]::new('--field', '--field', [CompletionResultType]::ParameterName, 'Custom field KEY=VAL to upsert (repeatable)')
            [CompletionResult]::new('--field-type', '--field-type', [CompletionResultType]::ParameterName, 'Value type for --field entries')
            [CompletionResult]::new('--from-json', '--from-json', [CompletionResultType]::ParameterName, 'Load patch JSON from file path or ''-'' for stdin')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--fill-missing', '--fill-missing', [CompletionResultType]::ParameterName, 'Only populate blank/missing/zero fields; preserve existing non-empty values')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;item;upsert' {
            [CompletionResult]::new('--name', '--name', [CompletionResultType]::ParameterName, 'Item name to match or create (required unless supplied via --from-json)')
            [CompletionResult]::new('--description', '--description', [CompletionResultType]::ParameterName, 'Item description')
            [CompletionResult]::new('--type', '--type', [CompletionResultType]::ParameterName, 'Entity type name or UUID')
            [CompletionResult]::new('--parent', '--parent', [CompletionResultType]::ParameterName, 'Parent item/location name, ID, or ''none''')
            [CompletionResult]::new('--tag', '--tag', [CompletionResultType]::ParameterName, 'Tag name or UUID (repeatable; missing tags auto-created)')
            [CompletionResult]::new('--manufacturer', '--manufacturer', [CompletionResultType]::ParameterName, 'Manufacturer')
            [CompletionResult]::new('--model', '--model', [CompletionResultType]::ParameterName, 'Model number')
            [CompletionResult]::new('--serial', '--serial', [CompletionResultType]::ParameterName, 'Serial number')
            [CompletionResult]::new('--notes', '--notes', [CompletionResultType]::ParameterName, 'Notes')
            [CompletionResult]::new('--quantity', '--quantity', [CompletionResultType]::ParameterName, 'Quantity')
            [CompletionResult]::new('--purchase-price', '--purchase-price', [CompletionResultType]::ParameterName, 'Purchase price')
            [CompletionResult]::new('--purchase-date', '--purchase-date', [CompletionResultType]::ParameterName, 'Purchase date (YYYY-MM-DD)')
            [CompletionResult]::new('--purchase-from', '--purchase-from', [CompletionResultType]::ParameterName, 'Purchase source')
            [CompletionResult]::new('--archived', '--archived', [CompletionResultType]::ParameterName, 'Mark item as archived (true/false; bare flag means true)')
            [CompletionResult]::new('--insured', '--insured', [CompletionResultType]::ParameterName, 'Mark item as insured (true/false; bare flag means true)')
            [CompletionResult]::new('--lifetime-warranty', '--lifetime-warranty', [CompletionResultType]::ParameterName, 'Mark item as having a lifetime warranty (true/false; bare flag means true)')
            [CompletionResult]::new('--warranty-expires', '--warranty-expires', [CompletionResultType]::ParameterName, 'Warranty expiration date (YYYY-MM-DD or RFC3339)')
            [CompletionResult]::new('--warranty-details', '--warranty-details', [CompletionResultType]::ParameterName, 'Warranty details or terms')
            [CompletionResult]::new('--sold-time', '--sold-time', [CompletionResultType]::ParameterName, 'Date/time the item was sold (YYYY-MM-DD or RFC3339)')
            [CompletionResult]::new('--sold-to', '--sold-to', [CompletionResultType]::ParameterName, 'Buyer name or recipient the item was sold to')
            [CompletionResult]::new('--sold-price', '--sold-price', [CompletionResultType]::ParameterName, 'Sale price')
            [CompletionResult]::new('--sold-notes', '--sold-notes', [CompletionResultType]::ParameterName, 'Notes about the sale')
            [CompletionResult]::new('--field', '--field', [CompletionResultType]::ParameterName, 'Custom field KEY=VAL (repeatable)')
            [CompletionResult]::new('--field-type', '--field-type', [CompletionResultType]::ParameterName, 'Value type for --field entries')
            [CompletionResult]::new('--from-json', '--from-json', [CompletionResultType]::ParameterName, 'Load item JSON from file path or ''-'' for stdin')
            [CompletionResult]::new('--match-by', '--match-by', [CompletionResultType]::ParameterName, 'Match existing items by key in priority order: name, model, serial, or field:KEY (repeatable; defaults to name)')
            [CompletionResult]::new('--match-mode', '--match-mode', [CompletionResultType]::ParameterName, 'Matching strategy for --match-by keys (exact, contains, fuzzy)')
            [CompletionResult]::new('--on-match', '--on-match', [CompletionResultType]::ParameterName, 'Action to take when an existing item matches (update, skip, attach-only)')
            [CompletionResult]::new('--attach', '--attach', [CompletionResultType]::ParameterName, 'Local file path(s) to attach after upserting the item (`FILE` or `FILE=REMOTE_NAME`, repeatable)')
            [CompletionResult]::new('--attach-url', '--attach-url', [CompletionResultType]::ParameterName, 'Remote HTTP(S) URL(s) to download and attach (`URL` or `URL=REMOTE_NAME`, repeatable)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--fill-missing', '--fill-missing', [CompletionResultType]::ParameterName, 'When updating an existing item, only populate blank/missing/zero fields')
            [CompletionResult]::new('--attach-best-effort', '--attach-best-effort', [CompletionResultType]::ParameterName, 'Treat attachment failures as non-fatal warnings and include `attachmentErrors` in JSON output')
            [CompletionResult]::new('--optimize', '--optimize', [CompletionResultType]::ParameterName, 'Automatically resize/compress oversized images before upload')
            [CompletionResult]::new('--force', '--force', [CompletionResultType]::ParameterName, 'Allow attaching images larger than 500KB')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;item;delete' {
            [CompletionResult]::new('--items-from', '--items-from', [CompletionResultType]::ParameterName, 'Read newline-delimited entity IDs to delete from a file or ''-'' (stdin)')
            [CompletionResult]::new('--tag', '--tag', [CompletionResultType]::ParameterName, 'Select items to delete matching this tag name or UUID')
            [CompletionResult]::new('--filter-tag', '--filter-tag', [CompletionResultType]::ParameterName, 'Select items to delete matching this tag name or UUID')
            [CompletionResult]::new('--parent', '--parent', [CompletionResultType]::ParameterName, 'Select items to delete under this parent item/location name, ID, or ''none''')
            [CompletionResult]::new('--filter-parent', '--filter-parent', [CompletionResultType]::ParameterName, 'Select items to delete under this parent item/location name, ID, or ''none''')
            [CompletionResult]::new('--type', '--type', [CompletionResultType]::ParameterName, 'Select items to delete matching this entity type name or UUID')
            [CompletionResult]::new('--filter-type', '--filter-type', [CompletionResultType]::ParameterName, 'Select items to delete matching this entity type name or UUID')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('-y', '-y', [CompletionResultType]::ParameterName, 'Skip interactive/bulk confirmation prompt')
            [CompletionResult]::new('--yes', '--yes', [CompletionResultType]::ParameterName, 'Skip interactive/bulk confirmation prompt')
            [CompletionResult]::new('--force', '--force', [CompletionResultType]::ParameterName, 'Skip interactive/bulk confirmation prompt')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;item;import' {
            [CompletionResult]::new('--format', '--format', [CompletionResultType]::ParameterName, 'Input format (inferred from extension if omitted; defaults to json for stdin)')
            [CompletionResult]::new('--match-by', '--match-by', [CompletionResultType]::ParameterName, 'Match existing items by key in priority order: name, model, serial, or field:KEY (repeatable; defaults to name)')
            [CompletionResult]::new('--match-mode', '--match-mode', [CompletionResultType]::ParameterName, 'Matching strategy for --match-by keys (exact, contains, fuzzy)')
            [CompletionResult]::new('--parent', '--parent', [CompletionResultType]::ParameterName, 'Default parent item/location name, ID, or ''none'' for imported records without one')
            [CompletionResult]::new('--attach', '--attach', [CompletionResultType]::ParameterName, 'Local file path(s) to attach to each imported item (`FILE` or `FILE=REMOTE_NAME`, repeatable)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--skip-existing', '--skip-existing', [CompletionResultType]::ParameterName, 'Skip items whose name already exists in Homebox')
            [CompletionResult]::new('--update-existing', '--update-existing', [CompletionResultType]::ParameterName, 'Update items whose name already exists in Homebox')
            [CompletionResult]::new('--fill-missing', '--fill-missing', [CompletionResultType]::ParameterName, 'With --update-existing, only populate blank/missing/zero fields on existing items')
            [CompletionResult]::new('--optimize', '--optimize', [CompletionResultType]::ParameterName, 'Automatically resize/compress oversized images before upload')
            [CompletionResult]::new('--force', '--force', [CompletionResultType]::ParameterName, 'Allow attaching images larger than 500KB')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;item;dedup' {
            [CompletionResult]::new('--threshold', '--threshold', [CompletionResultType]::ParameterName, 'Jaccard similarity threshold for near-duplicate detection (0.0..=1.0)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--delete', '--delete', [CompletionResultType]::ParameterName, 'Delete detected duplicate items, retaining only the keeper')
            [CompletionResult]::new('--merge', '--merge', [CompletionResultType]::ParameterName, 'Sum duplicate quantities onto the keeper before deleting duplicates (implies --delete)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;item;move' {
            [CompletionResult]::new('--to', '--to', [CompletionResultType]::ParameterName, 'Target parent item name, ID, or ''none'' to unparent (required when using selectors without trailing positional parent)')
            [CompletionResult]::new('--items-from', '--items-from', [CompletionResultType]::ParameterName, 'Read newline-delimited entity IDs to move from a file or ''-'' (stdin)')
            [CompletionResult]::new('--tag', '--tag', [CompletionResultType]::ParameterName, 'Select items to move matching this tag name or UUID')
            [CompletionResult]::new('--filter-tag', '--filter-tag', [CompletionResultType]::ParameterName, 'Select items to move matching this tag name or UUID')
            [CompletionResult]::new('--parent', '--parent', [CompletionResultType]::ParameterName, 'Select items to move under this parent item/location name, ID, or ''none''')
            [CompletionResult]::new('--filter-parent', '--filter-parent', [CompletionResultType]::ParameterName, 'Select items to move under this parent item/location name, ID, or ''none''')
            [CompletionResult]::new('--type', '--type', [CompletionResultType]::ParameterName, 'Select items to move matching this entity type name or UUID')
            [CompletionResult]::new('--filter-type', '--filter-type', [CompletionResultType]::ParameterName, 'Select items to move matching this entity type name or UUID')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;item;duplicate' {
            [CompletionResult]::new('--count', '--count', [CompletionResultType]::ParameterName, 'Number of duplicates to create')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;item;path' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;item;tree' {
            [CompletionResult]::new('--root', '--root', [CompletionResultType]::ParameterName, 'Optional root item name or ID to start the tree from')
            [CompletionResult]::new('--max-depth', '--max-depth', [CompletionResultType]::ParameterName, 'Optional maximum depth to display (0 = roots only)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;item;help' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List inventory items')
            [CompletionResult]::new('get', 'get', [CompletionResultType]::ParameterValue, 'Fetch a single item by ID')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create a new item (auto-persists custom fields via follow-up PUT)')
            [CompletionResult]::new('update', 'update', [CompletionResultType]::ParameterValue, 'Update an existing item via GET -> Merge -> PUT')
            [CompletionResult]::new('upsert', 'upsert', [CompletionResultType]::ParameterValue, 'Create or update an item matched by name')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete an item by ID')
            [CompletionResult]::new('import', 'import', [CompletionResultType]::ParameterValue, 'Bulk import items from JSON or CSV (file or ''-'' for stdin)')
            [CompletionResult]::new('dedup', 'dedup', [CompletionResultType]::ParameterValue, 'Detect (and optionally delete or merge) duplicate items')
            [CompletionResult]::new('move', 'move', [CompletionResultType]::ParameterValue, 'Move an item under a parent item/location (or ''none'' to unparent)')
            [CompletionResult]::new('duplicate', 'duplicate', [CompletionResultType]::ParameterValue, 'Duplicate an existing item one or more times')
            [CompletionResult]::new('path', 'path', [CompletionResultType]::ParameterValue, 'Display the location/parent breadcrumb path for an item')
            [CompletionResult]::new('tree', 'tree', [CompletionResultType]::ParameterValue, 'Render item parent/location hierarchy as a tree')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;item;help;list' {
            break
        }
        'hbctl;item;help;get' {
            break
        }
        'hbctl;item;help;create' {
            break
        }
        'hbctl;item;help;update' {
            break
        }
        'hbctl;item;help;upsert' {
            break
        }
        'hbctl;item;help;delete' {
            break
        }
        'hbctl;item;help;import' {
            break
        }
        'hbctl;item;help;dedup' {
            break
        }
        'hbctl;item;help;move' {
            break
        }
        'hbctl;item;help;duplicate' {
            break
        }
        'hbctl;item;help;path' {
            break
        }
        'hbctl;item;help;tree' {
            break
        }
        'hbctl;item;help;help' {
            break
        }
        'hbctl;attachment' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('upload', 'upload', [CompletionResultType]::ParameterValue, 'Upload one or more files as item attachments')
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List attachments on an item')
            [CompletionResult]::new('download', 'download', [CompletionResultType]::ParameterValue, 'Stream-download attachments from one or multiple items')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete an attachment from an item')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;attachment;upload' {
            [CompletionResult]::new('--attach-url', '--attach-url', [CompletionResultType]::ParameterName, 'Remote HTTP(S) URL(s) to download and attach (`URL` or `URL=REMOTE_NAME`, repeatable)')
            [CompletionResult]::new('--name', '--name', [CompletionResultType]::ParameterName, 'Override remote filename/title (for single-file or stdin ''-'' uploads)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--skip-existing', '--skip-existing', [CompletionResultType]::ParameterName, 'Skip files that already exist on the item (default behavior)')
            [CompletionResult]::new('--overwrite', '--overwrite', [CompletionResultType]::ParameterName, 'Delete and re-upload files that already exist on the item')
            [CompletionResult]::new('--optimize', '--optimize', [CompletionResultType]::ParameterName, 'Automatically resize/compress oversized images before upload')
            [CompletionResult]::new('--force', '--force', [CompletionResultType]::ParameterName, 'Allow uploading images larger than 500KB')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;attachment;list' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;attachment;download' {
            [CompletionResult]::new('--tag', '--tag', [CompletionResultType]::ParameterName, 'Download matching attachments across items matching this tag name or UUID')
            [CompletionResult]::new('--items-from', '--items-from', [CompletionResultType]::ParameterName, 'Download matching attachments for newline-delimited entity IDs from a file or ''-'' (stdin)')
            [CompletionResult]::new('--mime', '--mime', [CompletionResultType]::ParameterName, 'Filter attachments by MIME type (e.g. application/pdf)')
            [CompletionResult]::new('--ext', '--ext', [CompletionResultType]::ParameterName, 'Filter attachments by file extension (e.g. pdf)')
            [CompletionResult]::new('--out', '--out', [CompletionResultType]::ParameterName, 'Output file path (single download) or directory (multi-download / --all / bulk)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--all', '--all', [CompletionResultType]::ParameterName, 'Download all matching attachments on the item')
            [CompletionResult]::new('--all-items', '--all-items', [CompletionResultType]::ParameterName, 'Download matching attachments across all items')
            [CompletionResult]::new('--overwrite', '--overwrite', [CompletionResultType]::ParameterName, 'Overwrite existing local files instead of skipping')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;attachment;delete' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;attachment;help' {
            [CompletionResult]::new('upload', 'upload', [CompletionResultType]::ParameterValue, 'Upload one or more files as item attachments')
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List attachments on an item')
            [CompletionResult]::new('download', 'download', [CompletionResultType]::ParameterValue, 'Stream-download attachments from one or multiple items')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete an attachment from an item')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;attachment;help;upload' {
            break
        }
        'hbctl;attachment;help;list' {
            break
        }
        'hbctl;attachment;help;download' {
            break
        }
        'hbctl;attachment;help;delete' {
            break
        }
        'hbctl;attachment;help;help' {
            break
        }
        'hbctl;search' {
            [CompletionResult]::new('--tag', '--tag', [CompletionResultType]::ParameterName, 'Filter by tag name or UUID')
            [CompletionResult]::new('--type', '--type', [CompletionResultType]::ParameterName, 'Filter by entity type name or UUID')
            [CompletionResult]::new('--parent', '--parent', [CompletionResultType]::ParameterName, 'Filter by parent item name, ID, or ''none'' for top-level items')
            [CompletionResult]::new('--limit', '--limit', [CompletionResultType]::ParameterName, 'Maximum number of matching results to return')
            [CompletionResult]::new('--warranty-expiring', '--warranty-expiring', [CompletionResultType]::ParameterName, 'Only include items with a warranty expiring within the next DAYS days (excludes lifetime warranties)')
            [CompletionResult]::new('--model', '--model', [CompletionResultType]::ParameterName, 'Filter by model number (exact or substring, case-insensitive)')
            [CompletionResult]::new('--serial', '--serial', [CompletionResultType]::ParameterName, 'Filter by serial number (exact or substring, case-insensitive)')
            [CompletionResult]::new('--manufacturer', '--manufacturer', [CompletionResultType]::ParameterName, 'Filter by manufacturer (exact or substring, case-insensitive)')
            [CompletionResult]::new('--field', '--field', [CompletionResultType]::ParameterName, 'Filter by custom field existence (KEY) or substring value (KEY=VAL), case-insensitive (repeatable)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--include-archived', '--include-archived', [CompletionResultType]::ParameterName, 'Include archived items in search results')
            [CompletionResult]::new('--archived-only', '--archived-only', [CompletionResultType]::ParameterName, 'Only search archived items (implies --include-archived)')
            [CompletionResult]::new('--any', '--any', [CompletionResultType]::ParameterName, 'Match items satisfying ANY provided filter (OR) instead of ALL filters (AND)')
            [CompletionResult]::new('--with-path', '--with-path', [CompletionResultType]::ParameterName, 'Include full location/parent breadcrumb path for each matching item')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;field' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List all custom fields on an item')
            [CompletionResult]::new('get', 'get', [CompletionResultType]::ParameterValue, 'Get a custom field value from an item')
            [CompletionResult]::new('set', 'set', [CompletionResultType]::ParameterValue, 'Set a typed custom field on an item via GET -> Merge -> PUT')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete a custom field from an item via GET -> Remove -> PUT')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;field;list' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;field;get' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;field;set' {
            [CompletionResult]::new('--type', '--type', [CompletionResultType]::ParameterName, 'Custom field value type')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;field;delete' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;field;help' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List all custom fields on an item')
            [CompletionResult]::new('get', 'get', [CompletionResultType]::ParameterValue, 'Get a custom field value from an item')
            [CompletionResult]::new('set', 'set', [CompletionResultType]::ParameterValue, 'Set a typed custom field on an item via GET -> Merge -> PUT')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete a custom field from an item via GET -> Remove -> PUT')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;field;help;list' {
            break
        }
        'hbctl;field;help;get' {
            break
        }
        'hbctl;field;help;set' {
            break
        }
        'hbctl;field;help;delete' {
            break
        }
        'hbctl;field;help;help' {
            break
        }
        'hbctl;tag' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List all tags')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create a new tag')
            [CompletionResult]::new('update', 'update', [CompletionResultType]::ParameterValue, 'Update an existing tag by ID')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete a tag by ID')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;tag;list' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;tag;create' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;tag;update' {
            [CompletionResult]::new('--name', '--name', [CompletionResultType]::ParameterName, 'Updated tag name')
            [CompletionResult]::new('--description', '--description', [CompletionResultType]::ParameterName, 'Updated tag description')
            [CompletionResult]::new('--color', '--color', [CompletionResultType]::ParameterName, 'Updated tag hex color')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;tag;delete' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--force', '--force', [CompletionResultType]::ParameterName, 'Skip interactive confirmation prompt')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;tag;help' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List all tags')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create a new tag')
            [CompletionResult]::new('update', 'update', [CompletionResultType]::ParameterValue, 'Update an existing tag by ID')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete a tag by ID')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;tag;help;list' {
            break
        }
        'hbctl;tag;help;create' {
            break
        }
        'hbctl;tag;help;update' {
            break
        }
        'hbctl;tag;help;delete' {
            break
        }
        'hbctl;tag;help;help' {
            break
        }
        'hbctl;entity-types' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List all entity types')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create a new entity type')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete an entity type by ID')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;entity-type' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List all entity types')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create a new entity type')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete an entity type by ID')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;entity-types;list' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;entity-type;list' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;entity-types;create' {
            [CompletionResult]::new('--description', '--description', [CompletionResultType]::ParameterName, 'Optional description')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--is-location', '--is-location', [CompletionResultType]::ParameterName, 'Mark this entity type as a location/container')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;entity-type;create' {
            [CompletionResult]::new('--description', '--description', [CompletionResultType]::ParameterName, 'Optional description')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--is-location', '--is-location', [CompletionResultType]::ParameterName, 'Mark this entity type as a location/container')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;entity-types;delete' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--force', '--force', [CompletionResultType]::ParameterName, 'Skip interactive confirmation prompt')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;entity-type;delete' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--force', '--force', [CompletionResultType]::ParameterName, 'Skip interactive confirmation prompt')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;entity-types;help' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List all entity types')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create a new entity type')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete an entity type by ID')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;entity-types;help;list' {
            break
        }
        'hbctl;entity-types;help;create' {
            break
        }
        'hbctl;entity-types;help;delete' {
            break
        }
        'hbctl;entity-types;help;help' {
            break
        }
        'hbctl;entity-type;help' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List all entity types')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create a new entity type')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete an entity type by ID')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;entity-type;help;list' {
            break
        }
        'hbctl;entity-type;help;create' {
            break
        }
        'hbctl;entity-type;help;delete' {
            break
        }
        'hbctl;entity-type;help;help' {
            break
        }
        'hbctl;status' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;api' {
            [CompletionResult]::new('-d', '-d', [CompletionResultType]::ParameterName, 'Inline JSON request body')
            [CompletionResult]::new('--data', '--data', [CompletionResultType]::ParameterName, 'Inline JSON request body')
            [CompletionResult]::new('--from-json', '--from-json', [CompletionResultType]::ParameterName, 'Read JSON request body from a file path or ''-'' for stdin')
            [CompletionResult]::new('--query', '--query', [CompletionResultType]::ParameterName, 'Query parameter KEY=VALUE (repeatable; appended to any inline path query)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;maintenance' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List maintenance log entries (globally or for a specific entity)')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create a maintenance log entry on an entity')
            [CompletionResult]::new('update', 'update', [CompletionResultType]::ParameterValue, 'Update an existing maintenance log entry by entry ID')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete a maintenance log entry by entry ID')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;maintenance;list' {
            [CompletionResult]::new('--status', '--status', [CompletionResultType]::ParameterName, 'Filter by maintenance status (both, completed, scheduled)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;maintenance;create' {
            [CompletionResult]::new('--name', '--name', [CompletionResultType]::ParameterName, 'Maintenance task/entry name')
            [CompletionResult]::new('--completed-date', '--completed-date', [CompletionResultType]::ParameterName, 'Completion date (YYYY-MM-DD or YYYY-MM)')
            [CompletionResult]::new('--scheduled-date', '--scheduled-date', [CompletionResultType]::ParameterName, 'Scheduled date (YYYY-MM-DD or YYYY-MM)')
            [CompletionResult]::new('--cost', '--cost', [CompletionResultType]::ParameterName, 'Maintenance cost (e.g. 29.99 or $29.99)')
            [CompletionResult]::new('--description', '--description', [CompletionResultType]::ParameterName, 'Maintenance description or notes')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;maintenance;update' {
            [CompletionResult]::new('--name', '--name', [CompletionResultType]::ParameterName, 'Updated maintenance task/entry name')
            [CompletionResult]::new('--completed-date', '--completed-date', [CompletionResultType]::ParameterName, 'Updated completion date (YYYY-MM-DD or YYYY-MM)')
            [CompletionResult]::new('--scheduled-date', '--scheduled-date', [CompletionResultType]::ParameterName, 'Updated scheduled date (YYYY-MM-DD or YYYY-MM)')
            [CompletionResult]::new('--cost', '--cost', [CompletionResultType]::ParameterName, 'Updated maintenance cost (e.g. 29.99 or $29.99)')
            [CompletionResult]::new('--description', '--description', [CompletionResultType]::ParameterName, 'Updated maintenance description or notes')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;maintenance;delete' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--force', '--force', [CompletionResultType]::ParameterName, 'Skip interactive confirmation prompt')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;maintenance;help' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List maintenance log entries (globally or for a specific entity)')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create a maintenance log entry on an entity')
            [CompletionResult]::new('update', 'update', [CompletionResultType]::ParameterValue, 'Update an existing maintenance log entry by entry ID')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete a maintenance log entry by entry ID')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;maintenance;help;list' {
            break
        }
        'hbctl;maintenance;help;create' {
            break
        }
        'hbctl;maintenance;help;update' {
            break
        }
        'hbctl;maintenance;help;delete' {
            break
        }
        'hbctl;maintenance;help;help' {
            break
        }
        'hbctl;export' {
            [CompletionResult]::new('--tag', '--tag', [CompletionResultType]::ParameterName, 'Filter by tag name or UUID')
            [CompletionResult]::new('--has-field', '--has-field', [CompletionResultType]::ParameterName, 'Require items to have the named custom field')
            [CompletionResult]::new('--field', '--field', [CompletionResultType]::ParameterName, 'Custom field column(s) to include in export (repeatable)')
            [CompletionResult]::new('--sort', '--sort', [CompletionResultType]::ParameterName, 'Sort exported items (name, id, purchase-price, purchase-date, updated-at, asset-id)')
            [CompletionResult]::new('--format', '--format', [CompletionResultType]::ParameterName, 'Export format (json, csv, markdown)')
            [CompletionResult]::new('--columns', '--columns', [CompletionResultType]::ParameterName, 'Custom column list and order (comma-separated or repeatable; supports ''key=Header Alias'')')
            [CompletionResult]::new('--align', '--align', [CompletionResultType]::ParameterName, 'Markdown table column alignment (default, left, right, center)')
            [CompletionResult]::new('--empty', '--empty', [CompletionResultType]::ParameterName, 'Placeholder string for empty/missing cells')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;completions' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;man' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;update' {
            [CompletionResult]::new('--version', '--version', [CompletionResultType]::ParameterName, 'Target a specific release version or tag (e.g. 0.1.0 or v0.1.0)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--check', '--check', [CompletionResultType]::ParameterName, 'Check for available updates without installing')
            [CompletionResult]::new('-y', '-y', [CompletionResultType]::ParameterName, 'Skip confirmation prompt before installing')
            [CompletionResult]::new('--yes', '--yes', [CompletionResultType]::ParameterName, 'Skip confirmation prompt before installing')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;self-update' {
            [CompletionResult]::new('--version', '--version', [CompletionResultType]::ParameterName, 'Target a specific release version or tag (e.g. 0.1.0 or v0.1.0)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('-P', '-P ', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--profile', '--profile', [CompletionResultType]::ParameterName, 'Named configuration profile (env: HBCTL_PROFILE)')
            [CompletionResult]::new('--check', '--check', [CompletionResultType]::ParameterName, 'Check for available updates without installing')
            [CompletionResult]::new('-y', '-y', [CompletionResultType]::ParameterName, 'Skip confirmation prompt before installing')
            [CompletionResult]::new('--yes', '--yes', [CompletionResultType]::ParameterName, 'Skip confirmation prompt before installing')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;help' {
            [CompletionResult]::new('auth', 'auth', [CompletionResultType]::ParameterValue, 'Authenticate with a remote Homebox instance (login, status, logout, refresh)')
            [CompletionResult]::new('item', 'item', [CompletionResultType]::ParameterValue, 'Manage inventory items (/api/v1/entities)')
            [CompletionResult]::new('attachment', 'attachment', [CompletionResultType]::ParameterValue, 'Manage item attachments (/api/v1/entities/{id}/attachments)')
            [CompletionResult]::new('search', 'search', [CompletionResultType]::ParameterValue, 'Full-text and structured item search')
            [CompletionResult]::new('field', 'field', [CompletionResultType]::ParameterValue, 'List, get, set, or delete typed custom fields on an item')
            [CompletionResult]::new('tag', 'tag', [CompletionResultType]::ParameterValue, 'Manage tags (/api/v1/tags)')
            [CompletionResult]::new('entity-types', 'entity-types', [CompletionResultType]::ParameterValue, 'Manage Homebox entity types (/api/v1/entity-types)')
            [CompletionResult]::new('status', 'status', [CompletionResultType]::ParameterValue, 'Check remote Homebox server connectivity and version (/api/v1/status)')
            [CompletionResult]::new('api', 'api', [CompletionResultType]::ParameterValue, 'Issue a raw authenticated HTTP request against any Homebox API endpoint')
            [CompletionResult]::new('maintenance', 'maintenance', [CompletionResultType]::ParameterValue, 'Manage maintenance log entries (/api/v1/maintenance)')
            [CompletionResult]::new('export', 'export', [CompletionResultType]::ParameterValue, 'Export filtered items to JSON, CSV, or Markdown')
            [CompletionResult]::new('completions', 'completions', [CompletionResultType]::ParameterValue, 'Generate shell completion scripts')
            [CompletionResult]::new('man', 'man', [CompletionResultType]::ParameterValue, 'Generate UNIX roff man page')
            [CompletionResult]::new('update', 'update', [CompletionResultType]::ParameterValue, 'Check for and install the latest hbctl release from GitHub')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;help;auth' {
            [CompletionResult]::new('login', 'login', [CompletionResultType]::ParameterValue, 'Authenticate with Homebox via API key (--with-token) or email/password')
            [CompletionResult]::new('status', 'status', [CompletionResultType]::ParameterValue, 'Check authentication status and validate the active session')
            [CompletionResult]::new('logout', 'logout', [CompletionResultType]::ParameterValue, 'Remove stored credentials from OS keyring and local fallback store')
            [CompletionResult]::new('refresh', 'refresh', [CompletionResultType]::ParameterValue, 'Refresh an active JWT session token')
            break
        }
        'hbctl;help;auth;login' {
            break
        }
        'hbctl;help;auth;status' {
            break
        }
        'hbctl;help;auth;logout' {
            break
        }
        'hbctl;help;auth;refresh' {
            break
        }
        'hbctl;help;item' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List inventory items')
            [CompletionResult]::new('get', 'get', [CompletionResultType]::ParameterValue, 'Fetch a single item by ID')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create a new item (auto-persists custom fields via follow-up PUT)')
            [CompletionResult]::new('update', 'update', [CompletionResultType]::ParameterValue, 'Update an existing item via GET -> Merge -> PUT')
            [CompletionResult]::new('upsert', 'upsert', [CompletionResultType]::ParameterValue, 'Create or update an item matched by name')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete an item by ID')
            [CompletionResult]::new('import', 'import', [CompletionResultType]::ParameterValue, 'Bulk import items from JSON or CSV (file or ''-'' for stdin)')
            [CompletionResult]::new('dedup', 'dedup', [CompletionResultType]::ParameterValue, 'Detect (and optionally delete or merge) duplicate items')
            [CompletionResult]::new('move', 'move', [CompletionResultType]::ParameterValue, 'Move an item under a parent item/location (or ''none'' to unparent)')
            [CompletionResult]::new('duplicate', 'duplicate', [CompletionResultType]::ParameterValue, 'Duplicate an existing item one or more times')
            [CompletionResult]::new('path', 'path', [CompletionResultType]::ParameterValue, 'Display the location/parent breadcrumb path for an item')
            [CompletionResult]::new('tree', 'tree', [CompletionResultType]::ParameterValue, 'Render item parent/location hierarchy as a tree')
            break
        }
        'hbctl;help;item;list' {
            break
        }
        'hbctl;help;item;get' {
            break
        }
        'hbctl;help;item;create' {
            break
        }
        'hbctl;help;item;update' {
            break
        }
        'hbctl;help;item;upsert' {
            break
        }
        'hbctl;help;item;delete' {
            break
        }
        'hbctl;help;item;import' {
            break
        }
        'hbctl;help;item;dedup' {
            break
        }
        'hbctl;help;item;move' {
            break
        }
        'hbctl;help;item;duplicate' {
            break
        }
        'hbctl;help;item;path' {
            break
        }
        'hbctl;help;item;tree' {
            break
        }
        'hbctl;help;attachment' {
            [CompletionResult]::new('upload', 'upload', [CompletionResultType]::ParameterValue, 'Upload one or more files as item attachments')
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List attachments on an item')
            [CompletionResult]::new('download', 'download', [CompletionResultType]::ParameterValue, 'Stream-download attachments from one or multiple items')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete an attachment from an item')
            break
        }
        'hbctl;help;attachment;upload' {
            break
        }
        'hbctl;help;attachment;list' {
            break
        }
        'hbctl;help;attachment;download' {
            break
        }
        'hbctl;help;attachment;delete' {
            break
        }
        'hbctl;help;search' {
            break
        }
        'hbctl;help;field' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List all custom fields on an item')
            [CompletionResult]::new('get', 'get', [CompletionResultType]::ParameterValue, 'Get a custom field value from an item')
            [CompletionResult]::new('set', 'set', [CompletionResultType]::ParameterValue, 'Set a typed custom field on an item via GET -> Merge -> PUT')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete a custom field from an item via GET -> Remove -> PUT')
            break
        }
        'hbctl;help;field;list' {
            break
        }
        'hbctl;help;field;get' {
            break
        }
        'hbctl;help;field;set' {
            break
        }
        'hbctl;help;field;delete' {
            break
        }
        'hbctl;help;tag' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List all tags')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create a new tag')
            [CompletionResult]::new('update', 'update', [CompletionResultType]::ParameterValue, 'Update an existing tag by ID')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete a tag by ID')
            break
        }
        'hbctl;help;tag;list' {
            break
        }
        'hbctl;help;tag;create' {
            break
        }
        'hbctl;help;tag;update' {
            break
        }
        'hbctl;help;tag;delete' {
            break
        }
        'hbctl;help;entity-types' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List all entity types')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create a new entity type')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete an entity type by ID')
            break
        }
        'hbctl;help;entity-types;list' {
            break
        }
        'hbctl;help;entity-types;create' {
            break
        }
        'hbctl;help;entity-types;delete' {
            break
        }
        'hbctl;help;status' {
            break
        }
        'hbctl;help;api' {
            break
        }
        'hbctl;help;maintenance' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List maintenance log entries (globally or for a specific entity)')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create a maintenance log entry on an entity')
            [CompletionResult]::new('update', 'update', [CompletionResultType]::ParameterValue, 'Update an existing maintenance log entry by entry ID')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete a maintenance log entry by entry ID')
            break
        }
        'hbctl;help;maintenance;list' {
            break
        }
        'hbctl;help;maintenance;create' {
            break
        }
        'hbctl;help;maintenance;update' {
            break
        }
        'hbctl;help;maintenance;delete' {
            break
        }
        'hbctl;help;export' {
            break
        }
        'hbctl;help;completions' {
            break
        }
        'hbctl;help;man' {
            break
        }
        'hbctl;help;update' {
            break
        }
        'hbctl;help;help' {
            break
        }
    })

    $completions.Where{ $_.CompletionText -like "$wordToComplete*" } |
        Sort-Object -Property ListItemText
}
