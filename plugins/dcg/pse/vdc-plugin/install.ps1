# Run when the plugin is installed (before or independently of MCP). Idempotent.
#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'skills/install-vdc/scripts/install-vdc.ps1')
