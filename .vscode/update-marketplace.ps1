# Support running from both the extension install dir and the repo's .vscode dir
if ((Split-Path $PSScriptRoot -Leaf) -eq '.vscode') {
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
$json = Join-Path $repo ".github\plugin\marketplace.json"

$before = (Get-Content $json | ConvertFrom-Json).plugins.name

Write-Host "Checking for marketplace updates..." -ForegroundColor Cyan
git -C $repo fetch 2>&1 | Out-Null

$behind = git -C $repo rev-list HEAD..origin/main --count 2>$null
if ($behind -gt 0) {
    Write-Host "Updates available ($behind new commit(s)). Pulling..." -ForegroundColor Yellow
    git -C $repo pull --ff-only

    $after = (Get-Content $json | ConvertFrom-Json).plugins
    $new = $after | Where-Object { $_.name -notin $before }

    if ($new) {
        Write-Host "`n New plugins available:" -ForegroundColor Green
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

        Write-Host "`nRun 'Ctrl+Shift+P > Copilot: Update Plugins' to activate them." -ForegroundColor Cyan
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

# Install any VS Code extension plugins into the extensions folder
$extensionsDir = Join-Path $env:USERPROFILE ".vscode\extensions"
$vsixPlugins = $after | Where-Object { $_.'vscode-extension' -eq $true }

foreach ($plugin in $vsixPlugins) {
    $src = Join-Path $repo ($plugin.source -replace '^\.\/', '')
    $pkgJson = Join-Path $src "package.json"
    if (-not (Test-Path $pkgJson)) { continue }

    $pkg = Get-Content $pkgJson | ConvertFrom-Json
    $destName = "$($pkg.publisher)-$($pkg.name)-$($pkg.version)"
    $dest = Join-Path $extensionsDir $destName

    if (-not (Test-Path $dest)) {
        Write-Host "Installing VS Code extension: $($pkg.displayName)..." -ForegroundColor Cyan
        Copy-Item -Path $src -Destination $dest -Recurse -Force
        # Bundle the update script so the extension is self-contained
        Copy-Item -Path (Join-Path $PSScriptRoot 'update-marketplace.ps1') -Destination $dest -Force
        # Write the repo root so the bundled script can find marketplace.json at runtime
        @{ repoRoot = $repo } | ConvertTo-Json | Set-Content (Join-Path $dest 'repo-config.json')
        Write-Host "  Installed to $dest" -ForegroundColor Green
        Write-Host "  Reload VS Code (Ctrl+Shift+P > 'Reload Window') to activate." -ForegroundColor Yellow
    }
}
