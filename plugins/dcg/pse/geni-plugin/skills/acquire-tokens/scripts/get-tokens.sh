#!/usr/bin/env bash
# Geni MCP — Token acquisition script (Bash, no Node.js required)
# Fetches Kerberos-backed tokens for AxonTool and HSDIndexTool.
# Tokens are cached in /tmp/geni-mcp/tokens.json until their server-provided expiration.
#
# Usage:  bash get-tokens.sh [axon|hsd|all]
# Output: JSON to stdout — { axonToken, ibiToken }
#
# Requirements: curl (standard on Linux/macOS), Kerberos ticket (kinit)

set -euo pipefail

TARGET="${1:-all}"
AXON_URL="https://axon.intel.com/api/v1/token"
IBI_URL="https://ibi-daas-api.intel.com/login"
CACHE_DIR="/tmp/geni-mcp"
CACHE_FILE="$CACHE_DIR/tokens.json"
CURL_TIMEOUT=5

mkdir -p "$CACHE_DIR"
chmod 700 "$CACHE_DIR"

# ── Cache helpers ─────────────────────────────────────────────────────────────

is_expired() {
    local expiration="$1"
    [[ -z "$expiration" ]] && return 0  # treat missing as expired
    local exp_epoch
    exp_epoch=$(date -d "$expiration" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "$expiration" +%s 2>/dev/null || echo 0)
    local now_epoch
    now_epoch=$(date +%s)
    [[ "$exp_epoch" -le "$now_epoch" ]]
}

read_cache_field() {
    local field="$1"
    [[ -f "$CACHE_FILE" ]] || { echo "{}"; return; }
    # Extract the nested object for the given top-level key using grep+sed (no jq required)
    python3 -c "
import json, sys
data = json.load(open('$CACHE_FILE'))
print(json.dumps(data.get('$field', {})))
" 2>/dev/null || echo "{}"
}

write_cache_field() {
    local field="$1"
    local value="$2"
    local existing="{}"
    [[ -f "$CACHE_FILE" ]] && existing=$(cat "$CACHE_FILE")
    python3 -c "
import json, sys
data = json.loads(sys.argv[1])
data['$field'] = json.loads(sys.argv[2])
print(json.dumps(data))
" "$existing" "$value" > "$CACHE_FILE"
    chmod 600 "$CACHE_FILE"
}

# ── Token fetchers ────────────────────────────────────────────────────────────

get_axon_token() {
    local cached
    cached=$(read_cache_field "axonTokenData")
    local expiration
    expiration=$(echo "$cached" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('expiration',''))" 2>/dev/null || echo "")
    if [[ -n "$expiration" ]] && ! is_expired "$expiration"; then
        echo "$cached"
        return
    fi

    local body
    body=$(curl --negotiate -u : -s -f -L --max-time "$CURL_TIMEOUT" "$AXON_URL")
    local token
    token=$(echo "$body" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['token'])" 2>/dev/null || echo "")
    [[ -z "$token" ]] && { echo "[get-tokens] Axon response did not contain 'token'" >&2; exit 1; }

    write_cache_field "axonTokenData" "$body"
    echo "$body"
}

get_ibi_token() {
    local cached
    cached=$(read_cache_field "ibiTokenData")
    local expiration
    expiration=$(echo "$cached" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('expiration',''))" 2>/dev/null || echo "")
    if [[ -n "$expiration" ]] && ! is_expired "$expiration"; then
        echo "$cached"
        return
    fi

    local body
    body=$(curl --negotiate -u : -s -f -L -k --max-time "$CURL_TIMEOUT" "$IBI_URL")
    local token
    token=$(echo "$body" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['accessToken'])" 2>/dev/null || echo "")
    [[ -z "$token" ]] && { echo "[get-tokens] IBI response did not contain 'accessToken'" >&2; exit 1; }

    write_cache_field "ibiTokenData" "$body"
    echo "$body"
}

# ── Main ──────────────────────────────────────────────────────────────────────

AXON_TOKEN="null"
IBI_TOKEN="null"

if [[ "$TARGET" == "axon" || "$TARGET" == "all" ]]; then
    data=$(get_axon_token)
    token=$(echo "$data" | python3 -c "import json,sys; print(json.load(sys.stdin)['token'])")
    AXON_TOKEN="\"$token\""
fi

if [[ "$TARGET" == "hsd" || "$TARGET" == "all" ]]; then
    data=$(get_ibi_token)
    token=$(echo "$data" | python3 -c "import json,sys; print(json.load(sys.stdin)['accessToken'])")
    IBI_TOKEN="\"$token\""
fi

python3 - "$AXON_TOKEN" "$IBI_TOKEN" <<'PY'
import json
import sys

axon_token, ibi_token = [json.loads(value) for value in sys.argv[1:3]]

print(json.dumps({
    'axonToken': axon_token,
    'ibiToken': ibi_token,
}, indent=2))
PY
