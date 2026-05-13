# Geni MCP — Token acquisition script (PowerShell, no Node.js required)
# Fetches Kerberos-backed tokens for AxonTool and HSDIndexTool.
# Tokens are cached in %TEMP%\geni-mcp\tokens.json until their server-provided expiration.
#
# Usage:  powershell -ExecutionPolicy Bypass -File get-tokens.ps1 [axon|hsd|all]
# Output: JSON to stdout — { axonToken, ibiToken }

#Requires -Version 5.1

param(
    [ValidateSet('axon', 'hsd', 'all')]
    [string]$Target = 'all'
)

$ErrorActionPreference = 'Stop'

$AXON_URL = 'https://axon.intel.com/api/v1/token'
$IBI_URL  = 'https://ibi-daas-api.intel.com/login'

$CacheDir  = Join-Path $env:TEMP 'geni-mcp'
$CacheFile = Join-Path $CacheDir 'tokens.json'

# Compile a trust-all ICertificatePolicy for PS 5.1 — avoids the runspace
# issue that hits ServerCertificateValidationCallback scriptblocks.
if (-not ([System.Management.Automation.PSTypeName]'TrustAllCertsPolicy').Type) {
    Add-Type -TypeDefinition @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(ServicePoint sp, X509Certificate cert,
        WebRequest req, int problem) { return true; }
}
"@
}

function Read-Cache {
    if (-not (Test-Path $CacheFile)) { return @{} }
    try { return Get-Content $CacheFile -Raw | ConvertFrom-Json -AsHashtable }
    catch { return @{} }
}

function Write-Cache([hashtable]$cache) {
    if (-not (Test-Path $CacheDir)) { New-Item -ItemType Directory -Path $CacheDir | Out-Null }
    $cache | ConvertTo-Json -Compress | Set-Content -Path $CacheFile -Encoding UTF8

    # Restrict file to current user only (Windows ACL)
    try {
        $acl  = Get-Acl $CacheFile
        $acl.SetAccessRuleProtection($true, $false)
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $env:USERNAME, 'Read,Write', 'Allow'
        )
        $acl.AddAccessRule($rule)
        Set-Acl -Path $CacheFile -AclObject $acl
    } catch { <# non-fatal; %TEMP% is already user-private #> }
}

function IsExpired([string]$expiration) {
    if (-not $expiration) { return $true }
    try { return ([datetime]$expiration) -le (Get-Date) }
    catch { return $true }
}

function Get-AxonToken {
    $cache = Read-Cache
    if ($cache.axonTokenData -and -not (IsExpired $cache.axonTokenData.expiration)) {
        return $cache.axonTokenData
    }

    $response = Invoke-RestMethod -Uri $AXON_URL `
        -UseDefaultCredentials `
        -TimeoutSec 5

    if (-not $response.token) { throw 'Axon response did not contain `token`' }

    $cache['axonTokenData'] = $response
    Write-Cache $cache
    return $response
}

function Get-IbiToken {
    $cache = Read-Cache
    if ($cache.ibiTokenData -and -not (IsExpired $cache.ibiTokenData.expiration)) {
        return $cache.ibiTokenData
    }

    # -SkipCertificateCheck equivalent for PS 5.1 (self-signed cert on IBI endpoint)
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        $response = Invoke-RestMethod -Uri $IBI_URL `
            -UseDefaultCredentials `
            -SkipCertificateCheck `
            -TimeoutSec 5
    } else {
        # PS 5.1: force TLS 1.2 and use ICertificatePolicy to bypass self-signed cert,
        # then restore both after the call.
        $origProtocol = [System.Net.ServicePointManager]::SecurityProtocol
        $origPolicy   = [System.Net.ServicePointManager]::CertificatePolicy
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        try {
            $response = Invoke-RestMethod -Uri $IBI_URL `
                -UseDefaultCredentials `
                -TimeoutSec 5
        } finally {
            [System.Net.ServicePointManager]::SecurityProtocol = $origProtocol
            [System.Net.ServicePointManager]::CertificatePolicy = $origPolicy
        }
    }

    if (-not $response.accessToken) { throw 'IBI response did not contain `accessToken`' }

    $cache['ibiTokenData'] = $response
    Write-Cache $cache
    return $response
}

# ── Main ──────────────────────────────────────────────────────────────────────

$result = [ordered]@{
    axonToken = $null
    ibiToken  = $null
}

try {
    if ($Target -eq 'axon' -or $Target -eq 'all') {
        $data = Get-AxonToken
        $result.axonToken = $data.token
    }

    if ($Target -eq 'hsd' -or $Target -eq 'all') {
        $data = Get-IbiToken
        $result.ibiToken = $data.accessToken
    }

    $result | ConvertTo-Json
} catch {
    $Host.UI.WriteErrorLine("[get-tokens] $($_.Exception.Message)")
    exit 1
}
