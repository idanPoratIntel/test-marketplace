---
name: acquire-tokens
description: "Acquire authentication tokens before calling AxonTool or HSDIndexTool from the geni_dev_skill MCP server. Use when: invoking AxonTool, invoking HSDIndexTool, tokens are missing or expired, MCP tool call returns auth errors."
argument-hint: "axon | hsd | all"
---
# Acquire Tokens

## When to Use

Load and follow this skill **before every call** to `AxonTool` or `HSDIndexTool` from the `Intel Geni (prod)` MCP server. Tokens expire after 30 minutes; the script handles caching automatically.

> **IMPORTANT:** This skill applies **only** to `AxonTool` and `HSDIndexTool`. Do **NOT** follow this skill for any other tools provided by the `geni_dev_skill` MCP server (e.g., `HSDTool`, `VeWikiTool`, `CodeWithRegistersTool`, `DebugAssistantAgentTool`, `AskWorkspace`, etc.).

## Procedure

1. **Explain to the user before running the script.** Before executing any command, tell the user:

   > "To call [AxonTool / HSDIndexTool] I need to fetch a short-lived authentication token from Intel's internal token service using your Kerberos credentials (your active Windows/Linux/Mac login session). The script runs locally, never transmits your password, and caches the token in your system temp folder (`%TEMP%/geni-mcp/tokens.json` on Windows, `/tmp/geni-mcp/tokens.json` on Linux/Mac) for up to 30 minutes. Please approve the terminal command to continue.
   >
2. **Resolve the script's full path** before running it. The script lives inside the plugin folder, which is installed at a user-specific location. Use the workspace/file context to determine the absolute path to this SKILL.md file, then derive the script path from it (replace `SKILL.md` with `scripts/get-tokens.ps1` or `scripts/get-tokens.sh`). Always pass the **full absolute path** to the script in the command — do not use a relative path.
3. **Run the token script** for the tool you are about to call.

   **Windows** (PowerShell — built-in, no install required):

   | Target           | Command                                                                                   |
   | ---------------- | ----------------------------------------------------------------------------------------- |
   | `AxonTool`     | `powershell -ExecutionPolicy Bypass -File "<full-path-to>\scripts\get-tokens.ps1" axon` |
   | `HSDIndexTool` | `powershell -ExecutionPolicy Bypass -File "<full-path-to>\scripts\get-tokens.ps1" hsd`  |
   | Both             | `powershell -ExecutionPolicy Bypass -File "<full-path-to>\scripts\get-tokens.ps1" all`  |

   **Linux / macOS** (Bash + curl — built-in, no install required):

   | Target           | Command                                              |
   | ---------------- | ---------------------------------------------------- |
   | `AxonTool`     | `bash "<full-path-to>/scripts/get-tokens.sh" axon` |
   | `HSDIndexTool` | `bash "<full-path-to>/scripts/get-tokens.sh" hsd`  |
   | Both             | `bash "<full-path-to>/scripts/get-tokens.sh" all`  |

   Replace `<full-path-to>` with the absolute path to the `acquire-tokens` skill folder derived in step 2.
4. **Parse the JSON output** from stdout:

   ```json
   {
     "axonToken":    "<value>",
     "ibiToken":     "<value>"
   }
   ```

   Unused fields are `null` when a specific target was requested.
5. **Pass the tokens in the MCP tool call**:

   - `AxonTool` → include `axonToken`
   - `HSDIndexTool` → include `ibiToken`
6. **On script failure** (exit 1): report the error to the user — do not call the MCP tool without tokens.

## Token Sources

| Token         | URL                                      | Auth                          |
| ------------- | ---------------------------------------- | ----------------------------- |
| `axonToken` | `https://axon.intel.com/api/v1/token`  | Kerberos (`--negotiate`)    |
| `ibiToken`  | `https://ibi-daas-api.intel.com/login` | Kerberos (`--negotiate -k`) |

## Debugging

- Token cache (30-min TTL): `%TEMP%/geni-mcp/tokens.json` (Windows) / `/tmp/geni-mcp/tokens.json` (Linux/macOS) — delete to force a fresh fetch.
- Windows script: [./scripts/get-tokens.ps1](./scripts/get-tokens.ps1)
- Linux/macOS script: [./scripts/get-tokens.sh](./scripts/get-tokens.sh)
