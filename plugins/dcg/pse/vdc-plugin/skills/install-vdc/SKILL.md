---
name: install-vdc
description: "Install the VDC CLI so the vdc MCP server can be started via `vdc start-mcp`. Use when: the vdc command is not found, first-time setup, or after a VDC CLI update."
argument-hint: "install | check"
---

# Install VDC CLI

## When to Use

Load and follow this skill **before any VDC MCP tool call** if the `vdc` CLI is not yet installed on this machine, or whenever a `command not found` error is returned for `vdc`.

## Procedure

### 1. Check whether the CLI is already installed

Run the following command to verify the CLI is present and on the `PATH`:

```
vdc --version
```

If this succeeds, the CLI is installed — **stop here**. If it fails with `command not found` or a similar error, continue with step 2.

### 2. Explain to the user before running the script

Before executing any command, tell the user:

> "To set up the VDC MCP server I need to download the VDC CLI from Intel's internal Artifactory, run its self-installer, and then remove the bootstrap executable. The script runs locally and only connects to `af01p-fm.devtools.intel.com` (Intel-internal network / VPN required). Please approve the terminal command to continue.
>
> **Tip — skip this prompt in future:** In the approval dialog, click **Always Allow** to add this command to your allow list. Alternatively, add the following to your workspace `.vscode/settings.json`:
> ```json
> "github.copilot.chat.agent.terminal.allowList": {
>     "powershell -ExecutionPolicy Bypass -File plugins/vdc-plugin/skills/install-vdc/scripts/install-vdc.ps1": true
> }
> ```
> After saving, the install script will run automatically without prompting."

### 3. Run the install script

| Platform | Command |
|----------|---------|
| Windows (PowerShell) | `powershell -ExecutionPolicy Bypass -File plugins/vdc-plugin/skills/install-vdc/scripts/install-vdc.ps1` |

> **Note:** The VDC CLI installer currently targets **Windows (x64)** only. Linux/macOS support is not yet available via this installer.

### 4. Verify the installation

After the script exits successfully, confirm the CLI is on the `PATH`:

```
vdc --version
```

If this still fails, ask the user to open a new terminal session (the installer may have updated `PATH` for new sessions only) and try again.

### 5. On script failure

If the install script exits with a non-zero code:

- Confirm the machine is connected to the Intel network or VPN (`af01p-fm.devtools.intel.com` must be reachable).
- Report the error output to the user and do not attempt to call VDC MCP tools.

## Debugging

- Installer source: [./scripts/install-vdc.ps1](./scripts/install-vdc.ps1)
- Artifactory URL: `https://af01p-fm.devtools.intel.com/artifactory/vdc-client-fm-local/vdc/cli/prod/win-x64/vdc.exe`
