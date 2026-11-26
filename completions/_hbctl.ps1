
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
            [CompletionResult]::new('entity-types', 'entity-types', [CompletionResultType]::ParameterValue, 'List Homebox entity types (/api/v1/entity-types)')
            [CompletionResult]::new('entity-type', 'entity-type', [CompletionResultType]::ParameterValue, 'List Homebox entity types (/api/v1/entity-types)')
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
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;item;list' {
            [CompletionResult]::new('--tag', '--tag', [CompletionResultType]::ParameterName, 'Filter by tag name or UUID')
            [CompletionResult]::new('--type', '--type', [CompletionResultType]::ParameterName, 'Filter by entity type name or UUID')
            [CompletionResult]::new('--has-field', '--has-field', [CompletionResultType]::ParameterName, 'Only include items having the named custom field (hydrates details if missing)')
            [CompletionResult]::new('--page-size', '--page-size', [CompletionResultType]::ParameterName, 'Page size for listing')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--all', '--all', [CompletionResultType]::ParameterName, 'Fetch all pages')
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
            [CompletionResult]::new('--tag', '--tag', [CompletionResultType]::ParameterName, 'Tag name or UUID (repeatable; missing tags auto-created)')
            [CompletionResult]::new('--manufacturer', '--manufacturer', [CompletionResultType]::ParameterName, 'Manufacturer (normalized into custom field ''Manufacturer'')')
            [CompletionResult]::new('--model', '--model', [CompletionResultType]::ParameterName, 'Model number (normalized into custom field ''Model Number'')')
            [CompletionResult]::new('--serial', '--serial', [CompletionResultType]::ParameterName, 'Serial number (normalized into custom field ''Serial Number'')')
            [CompletionResult]::new('--notes', '--notes', [CompletionResultType]::ParameterName, 'Notes (normalized into custom field ''Notes'')')
            [CompletionResult]::new('--quantity', '--quantity', [CompletionResultType]::ParameterName, 'Item quantity')
            [CompletionResult]::new('--purchase-price', '--purchase-price', [CompletionResultType]::ParameterName, 'Purchase price')
            [CompletionResult]::new('--purchase-date', '--purchase-date', [CompletionResultType]::ParameterName, 'Purchase date (YYYY-MM-DD)')
            [CompletionResult]::new('--purchase-from', '--purchase-from', [CompletionResultType]::ParameterName, 'Purchase vendor/source')
            [CompletionResult]::new('--field', '--field', [CompletionResultType]::ParameterName, 'Custom field KEY=VAL (repeatable)')
            [CompletionResult]::new('--field-type', '--field-type', [CompletionResultType]::ParameterName, 'Value type for --field entries')
            [CompletionResult]::new('--from-json', '--from-json', [CompletionResultType]::ParameterName, 'Load initial item JSON from file path or ''-'' for stdin')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;item;update' {
            [CompletionResult]::new('--name', '--name', [CompletionResultType]::ParameterName, 'Updated item name')
            [CompletionResult]::new('--description', '--description', [CompletionResultType]::ParameterName, 'Updated item description')
            [CompletionResult]::new('--type', '--type', [CompletionResultType]::ParameterName, 'Entity type name or UUID')
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
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;item;upsert' {
            [CompletionResult]::new('--name', '--name', [CompletionResultType]::ParameterName, 'Item name to match or create')
            [CompletionResult]::new('--description', '--description', [CompletionResultType]::ParameterName, 'Item description')
            [CompletionResult]::new('--type', '--type', [CompletionResultType]::ParameterName, 'Entity type name or UUID')
            [CompletionResult]::new('--tag', '--tag', [CompletionResultType]::ParameterName, 'Tag name or UUID (repeatable; missing tags auto-created)')
            [CompletionResult]::new('--manufacturer', '--manufacturer', [CompletionResultType]::ParameterName, 'Manufacturer')
            [CompletionResult]::new('--model', '--model', [CompletionResultType]::ParameterName, 'Model number')
            [CompletionResult]::new('--serial', '--serial', [CompletionResultType]::ParameterName, 'Serial number')
            [CompletionResult]::new('--notes', '--notes', [CompletionResultType]::ParameterName, 'Notes')
            [CompletionResult]::new('--quantity', '--quantity', [CompletionResultType]::ParameterName, 'Quantity')
            [CompletionResult]::new('--purchase-price', '--purchase-price', [CompletionResultType]::ParameterName, 'Purchase price')
            [CompletionResult]::new('--purchase-date', '--purchase-date', [CompletionResultType]::ParameterName, 'Purchase date (YYYY-MM-DD)')
            [CompletionResult]::new('--purchase-from', '--purchase-from', [CompletionResultType]::ParameterName, 'Purchase source')
            [CompletionResult]::new('--field', '--field', [CompletionResultType]::ParameterName, 'Custom field KEY=VAL (repeatable)')
            [CompletionResult]::new('--field-type', '--field-type', [CompletionResultType]::ParameterName, 'Value type for --field entries')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;item;delete' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--force', '--force', [CompletionResultType]::ParameterName, 'Skip interactive confirmation prompt')
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
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--skip-existing', '--skip-existing', [CompletionResultType]::ParameterName, 'Skip items whose name already exists in Homebox')
            [CompletionResult]::new('--update-existing', '--update-existing', [CompletionResultType]::ParameterName, 'Update items whose name already exists in Homebox')
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
        'hbctl;item;help' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List inventory items')
            [CompletionResult]::new('get', 'get', [CompletionResultType]::ParameterValue, 'Fetch a single item by ID')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create a new item (auto-persists custom fields via follow-up PUT)')
            [CompletionResult]::new('update', 'update', [CompletionResultType]::ParameterValue, 'Update an existing item via GET -> Merge -> PUT')
            [CompletionResult]::new('upsert', 'upsert', [CompletionResultType]::ParameterValue, 'Create or update an item matched by name')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete an item by ID')
            [CompletionResult]::new('import', 'import', [CompletionResultType]::ParameterValue, 'Bulk import items from JSON or CSV (file or ''-'' for stdin)')
            [CompletionResult]::new('dedup', 'dedup', [CompletionResultType]::ParameterValue, 'Detect (and optionally delete or merge) duplicate items')
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
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('upload', 'upload', [CompletionResultType]::ParameterValue, 'Upload one or more files as item attachments')
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List attachments on an item')
            [CompletionResult]::new('download', 'download', [CompletionResultType]::ParameterValue, 'Stream-download one or all attachments from an item')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete an attachment from an item')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;attachment;upload' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--skip-existing', '--skip-existing', [CompletionResultType]::ParameterName, 'Skip files that already exist on the item (default behavior)')
            [CompletionResult]::new('--overwrite', '--overwrite', [CompletionResultType]::ParameterName, 'Delete and re-upload files that already exist on the item')
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
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            break
        }
        'hbctl;attachment;download' {
            [CompletionResult]::new('--mime', '--mime', [CompletionResultType]::ParameterName, 'Filter attachments by MIME type (e.g. application/pdf)')
            [CompletionResult]::new('--ext', '--ext', [CompletionResultType]::ParameterName, 'Filter attachments by file extension (e.g. pdf)')
            [CompletionResult]::new('--out', '--out', [CompletionResultType]::ParameterName, 'Output file path (single download) or directory (multi-download / --all)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--all', '--all', [CompletionResultType]::ParameterName, 'Download all matching attachments on the item')
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
            [CompletionResult]::new('download', 'download', [CompletionResultType]::ParameterValue, 'Stream-download one or all attachments from an item')
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
            [CompletionResult]::new('--model', '--model', [CompletionResultType]::ParameterName, 'Filter by model number (exact or substring, case-insensitive)')
            [CompletionResult]::new('--serial', '--serial', [CompletionResultType]::ParameterName, 'Filter by serial number (exact or substring, case-insensitive)')
            [CompletionResult]::new('--manufacturer', '--manufacturer', [CompletionResultType]::ParameterName, 'Filter by manufacturer (exact or substring, case-insensitive)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
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
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List all entity types')
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
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List all entity types')
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
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;entity-types;help;list' {
            break
        }
        'hbctl;entity-types;help;help' {
            break
        }
        'hbctl;entity-type;help' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List all entity types')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbctl;entity-type;help;list' {
            break
        }
        'hbctl;entity-type;help;help' {
            break
        }
        'hbctl;export' {
            [CompletionResult]::new('--tag', '--tag', [CompletionResultType]::ParameterName, 'Filter by tag name or UUID')
            [CompletionResult]::new('--has-field', '--has-field', [CompletionResultType]::ParameterName, 'Require items to have the named custom field')
            [CompletionResult]::new('--field', '--field', [CompletionResultType]::ParameterName, 'Custom field column(s) to include in export (repeatable)')
            [CompletionResult]::new('--sort', '--sort', [CompletionResultType]::ParameterName, 'Sort exported items by name or id')
            [CompletionResult]::new('--format', '--format', [CompletionResultType]::ParameterName, 'Export format (json, csv, markdown)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBCTL_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
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
            [CompletionResult]::new('entity-types', 'entity-types', [CompletionResultType]::ParameterValue, 'List Homebox entity types (/api/v1/entity-types)')
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
        'hbctl;help;attachment' {
            [CompletionResult]::new('upload', 'upload', [CompletionResultType]::ParameterValue, 'Upload one or more files as item attachments')
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List attachments on an item')
            [CompletionResult]::new('download', 'download', [CompletionResultType]::ParameterValue, 'Stream-download one or all attachments from an item')
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
            break
        }
        'hbctl;help;entity-types;list' {
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
