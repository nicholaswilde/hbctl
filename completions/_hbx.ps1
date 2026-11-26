
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

Register-ArgumentCompleter -Native -CommandName 'hbx' -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $commandElements = $commandAst.CommandElements
    $command = @(
        'hbx'
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
        'hbx' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
            [CompletionResult]::new('item', 'item', [CompletionResultType]::ParameterValue, 'Manage inventory items (/api/v1/entities)')
            [CompletionResult]::new('attachment', 'attachment', [CompletionResultType]::ParameterValue, 'Manage item attachments (/api/v1/entities/{id}/attachments)')
            [CompletionResult]::new('search', 'search', [CompletionResultType]::ParameterValue, 'Full-text and structured item search')
            [CompletionResult]::new('field', 'field', [CompletionResultType]::ParameterValue, 'Get or set typed custom fields on an item')
            [CompletionResult]::new('tag', 'tag', [CompletionResultType]::ParameterValue, 'Manage tags (/api/v1/tags)')
            [CompletionResult]::new('entity-types', 'entity-types', [CompletionResultType]::ParameterValue, 'List Homebox entity types (/api/v1/entity-types)')
            [CompletionResult]::new('entity-type', 'entity-type', [CompletionResultType]::ParameterValue, 'List Homebox entity types (/api/v1/entity-types)')
            [CompletionResult]::new('export', 'export', [CompletionResultType]::ParameterValue, 'Export filtered items to JSON, CSV, or Markdown')
            [CompletionResult]::new('completions', 'completions', [CompletionResultType]::ParameterValue, 'Generate shell completion scripts')
            [CompletionResult]::new('man', 'man', [CompletionResultType]::ParameterValue, 'Generate UNIX roff man page')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbx;item' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;item;list' {
            [CompletionResult]::new('--tag', '--tag', [CompletionResultType]::ParameterName, 'Filter by tag name or UUID')
            [CompletionResult]::new('--type', '--type', [CompletionResultType]::ParameterName, 'Filter by entity type name or UUID')
            [CompletionResult]::new('--has-field', '--has-field', [CompletionResultType]::ParameterName, 'Only include items having the named custom field (hydrates details if missing)')
            [CompletionResult]::new('--page-size', '--page-size', [CompletionResultType]::ParameterName, 'Page size for listing')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;item;get' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;item;create' {
            [CompletionResult]::new('--name', '--name', [CompletionResultType]::ParameterName, 'Item name (required unless supplied via --from-json)')
            [CompletionResult]::new('--description', '--description', [CompletionResultType]::ParameterName, 'Item description')
            [CompletionResult]::new('--type', '--type', [CompletionResultType]::ParameterName, 'Entity type name or UUID')
            [CompletionResult]::new('--tag', '--tag', [CompletionResultType]::ParameterName, 'Tag name or UUID (repeatable; missing tags auto-created)')
            [CompletionResult]::new('--manufacturer', '--manufacturer', [CompletionResultType]::ParameterName, 'Manufacturer (normalized into custom field ''Manufacturer'')')
            [CompletionResult]::new('--model', '--model', [CompletionResultType]::ParameterName, 'Model number (normalized into custom field ''Model Number'')')
            [CompletionResult]::new('--notes', '--notes', [CompletionResultType]::ParameterName, 'Notes (normalized into custom field ''Notes'')')
            [CompletionResult]::new('--quantity', '--quantity', [CompletionResultType]::ParameterName, 'Item quantity')
            [CompletionResult]::new('--purchase-price', '--purchase-price', [CompletionResultType]::ParameterName, 'Purchase price')
            [CompletionResult]::new('--purchase-date', '--purchase-date', [CompletionResultType]::ParameterName, 'Purchase date (YYYY-MM-DD)')
            [CompletionResult]::new('--purchase-from', '--purchase-from', [CompletionResultType]::ParameterName, 'Purchase vendor/source')
            [CompletionResult]::new('--field', '--field', [CompletionResultType]::ParameterName, 'Custom field KEY=VAL (repeatable)')
            [CompletionResult]::new('--field-type', '--field-type', [CompletionResultType]::ParameterName, 'Value type for --field entries')
            [CompletionResult]::new('--from-json', '--from-json', [CompletionResultType]::ParameterName, 'Load initial item JSON from file path or ''-'' for stdin')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;item;update' {
            [CompletionResult]::new('--name', '--name', [CompletionResultType]::ParameterName, 'Updated item name')
            [CompletionResult]::new('--description', '--description', [CompletionResultType]::ParameterName, 'Updated item description')
            [CompletionResult]::new('--type', '--type', [CompletionResultType]::ParameterName, 'Entity type name or UUID')
            [CompletionResult]::new('--tag', '--tag', [CompletionResultType]::ParameterName, 'Tag name or UUID to merge (repeatable)')
            [CompletionResult]::new('--manufacturer', '--manufacturer', [CompletionResultType]::ParameterName, 'Manufacturer (merged into custom field ''Manufacturer'')')
            [CompletionResult]::new('--model', '--model', [CompletionResultType]::ParameterName, 'Model number (merged into custom field ''Model Number'')')
            [CompletionResult]::new('--quantity', '--quantity', [CompletionResultType]::ParameterName, 'Updated quantity')
            [CompletionResult]::new('--purchase-price', '--purchase-price', [CompletionResultType]::ParameterName, 'Updated purchase price')
            [CompletionResult]::new('--purchase-date', '--purchase-date', [CompletionResultType]::ParameterName, 'Updated purchase date (YYYY-MM-DD)')
            [CompletionResult]::new('--purchase-from', '--purchase-from', [CompletionResultType]::ParameterName, 'Updated purchase source')
            [CompletionResult]::new('--notes', '--notes', [CompletionResultType]::ParameterName, 'Notes (merged into custom field ''Notes'')')
            [CompletionResult]::new('--field', '--field', [CompletionResultType]::ParameterName, 'Custom field KEY=VAL to upsert (repeatable)')
            [CompletionResult]::new('--field-type', '--field-type', [CompletionResultType]::ParameterName, 'Value type for --field entries')
            [CompletionResult]::new('--from-json', '--from-json', [CompletionResultType]::ParameterName, 'Load patch JSON from file path or ''-'' for stdin')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;item;upsert' {
            [CompletionResult]::new('--name', '--name', [CompletionResultType]::ParameterName, 'Item name to match or create')
            [CompletionResult]::new('--description', '--description', [CompletionResultType]::ParameterName, 'Item description')
            [CompletionResult]::new('--type', '--type', [CompletionResultType]::ParameterName, 'Entity type name or UUID')
            [CompletionResult]::new('--tag', '--tag', [CompletionResultType]::ParameterName, 'Tag name or UUID (repeatable; missing tags auto-created)')
            [CompletionResult]::new('--manufacturer', '--manufacturer', [CompletionResultType]::ParameterName, 'Manufacturer')
            [CompletionResult]::new('--model', '--model', [CompletionResultType]::ParameterName, 'Model number')
            [CompletionResult]::new('--notes', '--notes', [CompletionResultType]::ParameterName, 'Notes')
            [CompletionResult]::new('--quantity', '--quantity', [CompletionResultType]::ParameterName, 'Quantity')
            [CompletionResult]::new('--purchase-price', '--purchase-price', [CompletionResultType]::ParameterName, 'Purchase price')
            [CompletionResult]::new('--purchase-date', '--purchase-date', [CompletionResultType]::ParameterName, 'Purchase date (YYYY-MM-DD)')
            [CompletionResult]::new('--purchase-from', '--purchase-from', [CompletionResultType]::ParameterName, 'Purchase source')
            [CompletionResult]::new('--field', '--field', [CompletionResultType]::ParameterName, 'Custom field KEY=VAL (repeatable)')
            [CompletionResult]::new('--field-type', '--field-type', [CompletionResultType]::ParameterName, 'Value type for --field entries')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;item;delete' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;item;import' {
            [CompletionResult]::new('--format', '--format', [CompletionResultType]::ParameterName, 'Input format (inferred from extension if omitted; defaults to json for stdin)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;item;dedup' {
            [CompletionResult]::new('--threshold', '--threshold', [CompletionResultType]::ParameterName, 'Jaccard similarity threshold for near-duplicate detection (0.0..=1.0)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;item;help' {
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
        'hbx;item;help;list' {
            break
        }
        'hbx;item;help;get' {
            break
        }
        'hbx;item;help;create' {
            break
        }
        'hbx;item;help;update' {
            break
        }
        'hbx;item;help;upsert' {
            break
        }
        'hbx;item;help;delete' {
            break
        }
        'hbx;item;help;import' {
            break
        }
        'hbx;item;help;dedup' {
            break
        }
        'hbx;item;help;help' {
            break
        }
        'hbx;attachment' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;attachment;upload' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;attachment;list' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;attachment;download' {
            [CompletionResult]::new('--mime', '--mime', [CompletionResultType]::ParameterName, 'Filter attachments by MIME type (e.g. application/pdf)')
            [CompletionResult]::new('--ext', '--ext', [CompletionResultType]::ParameterName, 'Filter attachments by file extension (e.g. pdf)')
            [CompletionResult]::new('--out', '--out', [CompletionResultType]::ParameterName, 'Output file path (single download) or directory (multi-download / --all)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;attachment;delete' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;attachment;help' {
            [CompletionResult]::new('upload', 'upload', [CompletionResultType]::ParameterValue, 'Upload one or more files as item attachments')
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List attachments on an item')
            [CompletionResult]::new('download', 'download', [CompletionResultType]::ParameterValue, 'Stream-download one or all attachments from an item')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete an attachment from an item')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbx;attachment;help;upload' {
            break
        }
        'hbx;attachment;help;list' {
            break
        }
        'hbx;attachment;help;download' {
            break
        }
        'hbx;attachment;help;delete' {
            break
        }
        'hbx;attachment;help;help' {
            break
        }
        'hbx;search' {
            [CompletionResult]::new('--tag', '--tag', [CompletionResultType]::ParameterName, 'Filter by tag name or UUID')
            [CompletionResult]::new('--model', '--model', [CompletionResultType]::ParameterName, 'Filter by model number (exact or substring, case-insensitive)')
            [CompletionResult]::new('--serial', '--serial', [CompletionResultType]::ParameterName, 'Filter by serial number (exact or substring, case-insensitive)')
            [CompletionResult]::new('--manufacturer', '--manufacturer', [CompletionResultType]::ParameterName, 'Filter by manufacturer (exact or substring, case-insensitive)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;field' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
            [CompletionResult]::new('--select', '--select', [CompletionResultType]::ParameterName, 'Comma-separated field projection for JSON/table output (e.g. id,name,fields)')
            [CompletionResult]::new('-C', '-C ', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--config', '--config', [CompletionResultType]::ParameterName, 'Path to explicit TOML configuration file')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'Shorthand for --output json (emits compact JSON)')
            [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Preview mutating requests without hitting the server (redacts Authorization)')
            [CompletionResult]::new('-q', '-q', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('--quiet', '--quiet', [CompletionResultType]::ParameterName, 'Output only created/affected IDs for shell piping')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Print help')
            [CompletionResult]::new('get', 'get', [CompletionResultType]::ParameterValue, 'Get a custom field value from an item')
            [CompletionResult]::new('set', 'set', [CompletionResultType]::ParameterValue, 'Set a typed custom field on an item via GET -> Merge -> PUT')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbx;field;get' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;field;set' {
            [CompletionResult]::new('--type', '--type', [CompletionResultType]::ParameterName, 'Custom field value type')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;field;help' {
            [CompletionResult]::new('get', 'get', [CompletionResultType]::ParameterValue, 'Get a custom field value from an item')
            [CompletionResult]::new('set', 'set', [CompletionResultType]::ParameterValue, 'Set a typed custom field on an item via GET -> Merge -> PUT')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbx;field;help;get' {
            break
        }
        'hbx;field;help;set' {
            break
        }
        'hbx;field;help;help' {
            break
        }
        'hbx;tag' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbx;tag;list' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;tag;create' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;tag;help' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List all tags')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create a new tag')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbx;tag;help;list' {
            break
        }
        'hbx;tag;help;create' {
            break
        }
        'hbx;tag;help;help' {
            break
        }
        'hbx;entity-types' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;entity-type' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;entity-types;list' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;entity-type;list' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;entity-types;help' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List all entity types')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbx;entity-types;help;list' {
            break
        }
        'hbx;entity-types;help;help' {
            break
        }
        'hbx;entity-type;help' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List all entity types')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbx;entity-type;help;list' {
            break
        }
        'hbx;entity-type;help;help' {
            break
        }
        'hbx;export' {
            [CompletionResult]::new('--tag', '--tag', [CompletionResultType]::ParameterName, 'Filter by tag name or UUID')
            [CompletionResult]::new('--has-field', '--has-field', [CompletionResultType]::ParameterName, 'Require items to have the named custom field')
            [CompletionResult]::new('--field', '--field', [CompletionResultType]::ParameterName, 'Custom field column(s) to include in export (repeatable)')
            [CompletionResult]::new('--sort', '--sort', [CompletionResultType]::ParameterName, 'Sort exported items by name or id')
            [CompletionResult]::new('--format', '--format', [CompletionResultType]::ParameterName, 'Export format (json, csv, markdown)')
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;completions' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;man' {
            [CompletionResult]::new('--url', '--url', [CompletionResultType]::ParameterName, 'Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)')
            [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)')
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'Output format (table, json, plain) [env: HBX_OUTPUT]')
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
        'hbx;help' {
            [CompletionResult]::new('item', 'item', [CompletionResultType]::ParameterValue, 'Manage inventory items (/api/v1/entities)')
            [CompletionResult]::new('attachment', 'attachment', [CompletionResultType]::ParameterValue, 'Manage item attachments (/api/v1/entities/{id}/attachments)')
            [CompletionResult]::new('search', 'search', [CompletionResultType]::ParameterValue, 'Full-text and structured item search')
            [CompletionResult]::new('field', 'field', [CompletionResultType]::ParameterValue, 'Get or set typed custom fields on an item')
            [CompletionResult]::new('tag', 'tag', [CompletionResultType]::ParameterValue, 'Manage tags (/api/v1/tags)')
            [CompletionResult]::new('entity-types', 'entity-types', [CompletionResultType]::ParameterValue, 'List Homebox entity types (/api/v1/entity-types)')
            [CompletionResult]::new('export', 'export', [CompletionResultType]::ParameterValue, 'Export filtered items to JSON, CSV, or Markdown')
            [CompletionResult]::new('completions', 'completions', [CompletionResultType]::ParameterValue, 'Generate shell completion scripts')
            [CompletionResult]::new('man', 'man', [CompletionResultType]::ParameterValue, 'Generate UNIX roff man page')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'hbx;help;item' {
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
        'hbx;help;item;list' {
            break
        }
        'hbx;help;item;get' {
            break
        }
        'hbx;help;item;create' {
            break
        }
        'hbx;help;item;update' {
            break
        }
        'hbx;help;item;upsert' {
            break
        }
        'hbx;help;item;delete' {
            break
        }
        'hbx;help;item;import' {
            break
        }
        'hbx;help;item;dedup' {
            break
        }
        'hbx;help;attachment' {
            [CompletionResult]::new('upload', 'upload', [CompletionResultType]::ParameterValue, 'Upload one or more files as item attachments')
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List attachments on an item')
            [CompletionResult]::new('download', 'download', [CompletionResultType]::ParameterValue, 'Stream-download one or all attachments from an item')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete an attachment from an item')
            break
        }
        'hbx;help;attachment;upload' {
            break
        }
        'hbx;help;attachment;list' {
            break
        }
        'hbx;help;attachment;download' {
            break
        }
        'hbx;help;attachment;delete' {
            break
        }
        'hbx;help;search' {
            break
        }
        'hbx;help;field' {
            [CompletionResult]::new('get', 'get', [CompletionResultType]::ParameterValue, 'Get a custom field value from an item')
            [CompletionResult]::new('set', 'set', [CompletionResultType]::ParameterValue, 'Set a typed custom field on an item via GET -> Merge -> PUT')
            break
        }
        'hbx;help;field;get' {
            break
        }
        'hbx;help;field;set' {
            break
        }
        'hbx;help;tag' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List all tags')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create a new tag')
            break
        }
        'hbx;help;tag;list' {
            break
        }
        'hbx;help;tag;create' {
            break
        }
        'hbx;help;entity-types' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List all entity types')
            break
        }
        'hbx;help;entity-types;list' {
            break
        }
        'hbx;help;export' {
            break
        }
        'hbx;help;completions' {
            break
        }
        'hbx;help;man' {
            break
        }
        'hbx;help;help' {
            break
        }
    })

    $completions.Where{ $_.CompletionText -like "$wordToComplete*" } |
        Sort-Object -Property ListItemText
}
