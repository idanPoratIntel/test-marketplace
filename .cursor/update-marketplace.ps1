# Cursor Marketplace Update Script
# Checks for updates to the marketplace and installs new plugins for Cursor

# Support running from both the extension install dir and the repo's .cursor dir
if ((Split-Path $PSScriptRoot -Leaf) -eq '.cursor') {
    $repoRoot = Split-Path $PSScriptRoot -Parent
} else {
    # Running from extension install dir — read the repo path written at install time
    $configFile = Join-Path $PSScriptRoot 'repo-config.json'
    if (-not (Test-Path $configFile)) {
        Write-Error "Cannot locate repo root. Expected config file: $configFile"
        exit 1
    }
    $repoRoot = (Get-Content $configFile | ConvertFrom-Json).repoRoot
}
$repo = $repoRoot
$json = Join-Path $repo ".cursor\plugin\marketplace.json"

if (-not (Test-Path $json)) {
    Write-Error "Cursor marketplace manifest not found: $json"
    exit 1
}

$before = (Get-Content $json | ConvertFrom-Json).plugins.name

Write-Host "Checking for marketplace updates (Cursor)..." -ForegroundColor Cyan
git -C $repo fetch 2>&1 | Out-Null

$behind = git -C $repo rev-list HEAD..origin/main --count 2>$null
if ($behind -gt 0) {
    Write-Host "Updates available ($behind new commit(s)). Pulling..." -ForegroundColor Yellow
    git -C $repo pull --ff-only

    $after = (Get-Content $json | ConvertFrom-Json).plugins
    $new = $after | Where-Object { $_.name -notin $before }

    if ($new) {
        Write-Host "`nNew plugins available:" -ForegroundColor Green
        $new | ForEach-Object { Write-Host "  + $($_.name)" -ForegroundColor Green }

        # Run any install scripts defined by new plugins
        foreach ($plugin in $new) {
            if ($plugin.installScript) {
                $pluginSrc = Join-Path $repo ($plugin.source -replace '^\.\/', '')
                $scriptPath = Join-Path $pluginSrc $plugin.installScript
                if (Test-Path $scriptPath) {
                    Write-Host "`nRunning install script for '$($plugin.name)'..." -ForegroundColor Cyan
                    try {
                        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath
                        if ($LASTEXITCODE -ne 0) { throw "exited with code $LASTEXITCODE" }
                        Write-Host "  Install script completed for '$($plugin.name)'." -ForegroundColor Green
                    } catch {
                        Write-Warning "  Install script failed for '$($plugin.name)': $_"
                    }
                } else {
                    Write-Warning "  Install script not found for '$($plugin.name)': $scriptPath"
                }
            }
        }

        Write-Host "`nNext steps:" -ForegroundColor Cyan
        Write-Host "  1. Copy MCP configurations from plugin .cursor-mcp.json files to your Cursor settings" -ForegroundColor White
        Write-Host "  2. Copy agent and skill files to your Cursor configuration directory" -ForegroundColor White
        Write-Host "  3. Restart Cursor to activate the plugins" -ForegroundColor White
        Write-Host "`nSee docs/CURSOR_SETUP.md for detailed instructions." -ForegroundColor Yellow
    } else {
        Write-Host "Marketplace updated (no new plugins added)." -ForegroundColor Yellow
    }
} else {
    $after = (Get-Content $json | ConvertFrom-Json).plugins
    Write-Host "Already up to date. No new updates." -ForegroundColor Green
}

# Run install scripts for any plugin whose checkCommand is missing from PATH
foreach ($plugin in $after) {
    if ($plugin.checkCommand -and $plugin.installScript) {
        $toolPresent = Get-Command $plugin.checkCommand -ErrorAction SilentlyContinue
        if (-not $toolPresent) {
            $pluginSrc = Join-Path $repo ($plugin.source -replace '^\.\/', '')
            $scriptPath = Join-Path $pluginSrc $plugin.installScript
            if (Test-Path $scriptPath) {
                Write-Host "`n'$($plugin.checkCommand)' not found. Running install script for '$($plugin.name)'..." -ForegroundColor Yellow
                try {
                    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath
                    if ($LASTEXITCODE -ne 0) { throw "exited with code $LASTEXITCODE" }
                    Write-Host "  Install script completed for '$($plugin.name)'." -ForegroundColor Green
                } catch {
                    Write-Warning "  Install script failed for '$($plugin.name)': $_"
                }
            } else {
                Write-Warning "  Install script not found for '$($plugin.name)': $scriptPath"
            }
        }
    }
}

# Display current MCP server configurations for Cursor
Write-Host "`nCursor MCP Server Configurations:" -ForegroundColor Cyan
Write-Host "Add these to your Cursor settings.json under 'mcpServers':" -ForegroundColor White
Write-Host ""

foreach ($plugin in $after) {
    if ($plugin.mcpConfig) {
        $pluginSrc = Join-Path $repo ($plugin.source -replace '^\.\/', '')
        $mcpConfigPath = Join-Path $pluginSrc $plugin.mcpConfig
        if (Test-Path $mcpConfigPath) {
            Write-Host "=== $($plugin.name) ===" -ForegroundColor Yellow
            Get-Content $mcpConfigPath | Write-Host
            Write-Host ""
        }
    }
}

Write-Host "For full setup instructions, see: docs/CURSOR_SETUP.md" -ForegroundColor Cyan
