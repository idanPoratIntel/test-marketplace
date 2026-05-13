// Geni MCP — Token acquisition script
// Fetches Kerberos-backed tokens for AxonTool and HSDIndexTool.
// Tokens are cached in %TEMP%/geni-mcp/tokens.json until their server-provided expiration.
//
// Usage:  node get-tokens.js [axon|hsd|all]
// Output: JSON to stdout — { axonToken, ibiToken }

'use strict';

const { execFile } = require('node:child_process');
const { promisify } = require('node:util');
const { mkdirSync, readFileSync, writeFileSync, existsSync } = require('node:fs');
const { tmpdir, platform } = require('node:os');
const { join } = require('node:path');

const execFileAsync = promisify(execFile);

const AXON_URL_BASE   = 'https://axon.intel.com/api/v1';
const IBI_URL_BASE    = 'https://ibi-daas-api.intel.com';
const CURL_TIMEOUT_MS = 5_000;

const CACHE_DIR  = join(tmpdir(), 'geni-mcp');
const CACHE_FILE = join(CACHE_DIR, 'tokens.json');

/** Returns -1 if d1 > d2 (still valid), 0 if equal, 1 if d1 < d2 (expired). */
function compareDateFunc(date1, date2) {
    const d1 = new Date(date1);
    const d2 = new Date(date2);
    if (d1.getTime() === d2.getTime()) return 0;
    if (d1 > d2) return -1;
    if (d1 < d2) return 1;
    return -1;
}

function isExpired(expiration) {
    if (!expiration) return true;
    return compareDateFunc(expiration, new Date()) === 1;
}

function readCache() {
    try {
        if (!existsSync(CACHE_FILE)) return {};
        return JSON.parse(readFileSync(CACHE_FILE, 'utf8'));
    } catch {
        return {};
    }
}

function writeCache(cache) {
    mkdirSync(CACHE_DIR, { recursive: true });
    writeFileSync(CACHE_FILE, JSON.stringify(cache), { mode: 0o600 });
    // On Windows, mode 0o600 is ignored by Node.js; restrict ACLs explicitly so
    // only the current user can read the token cache.
    if (platform() === 'win32') {
        try {
            execFile('icacls', [CACHE_FILE, '/inheritance:r', '/grant:r', `${process.env.USERNAME}:(R,W)`]);
        } catch { /* non-fatal; %TEMP% is already user-private */ }
    }
}

async function curlWithKerberos(url, insecure = false) {
    const curl = platform() === 'win32' ? 'curl.exe' : 'curl';
    const args = ['--negotiate', '-u', ':', '-s', '-f', '-L'];
    if (insecure) args.push('-k');
    args.push(url);
    const { stdout } = await execFileAsync(curl, args, { timeout: CURL_TIMEOUT_MS });
    return stdout.trim();
}

async function getAxonToken() {
    const cache = readCache();
    if (cache.axonTokenData && !isExpired(cache.axonTokenData.expiration)) {
        return cache.axonTokenData;
    }
    const body = await curlWithKerberos(`${AXON_URL_BASE}/token`);
    const data = JSON.parse(body);
    if (!data.token) throw new Error('Axon response did not contain `token`');
    cache.axonTokenData = data;
    writeCache(cache);
    return data;
}

async function getIbiToken() {
    const cache = readCache();
    if (cache.ibiTokenData && !isExpired(cache.ibiTokenData.expiration)) {
        return cache.ibiTokenData;
    }
    const body = await curlWithKerberos(`${IBI_URL_BASE}/login`, true);
    const data = JSON.parse(body);
    if (!data.accessToken) throw new Error('IBI response did not contain `accessToken`');
    cache.ibiTokenData = data;
    writeCache(cache);
    return data;
}

async function main() {
    const target = (process.argv[2] ?? 'all').toLowerCase();
    const result = {
        axonToken: null,
        ibiToken:  null,
    };

    if (target === 'axon' || target === 'all') {
        const data = await getAxonToken();
        result.axonToken = data.token;
    }

    if (target === 'hsd' || target === 'all') {
        const data = await getIbiToken();
        result.ibiToken = data.accessToken;
    }

    process.stdout.write(JSON.stringify(result, null, 2) + '\n');
}

main().catch(err => {
    process.stderr.write('[get-tokens] ' + err.message + '\n');
    process.exit(1);
});
