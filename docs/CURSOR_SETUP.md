# Using Marketplace Plugins with Cursor

This guide explains how to use plugins from this marketplace with Cursor IDE.

## Quick Start

The marketplace includes Cursor-specific files:
- **`.cursor/plugin/marketplace.json`** - Plugin registry for Cursor
- **`.cursor/update-marketplace.ps1`** - Script to check for plugin updates
- **Plugin `.cursor-mcp.json`** files - MCP server configurations

## Prerequisites

- Cursor IDE installed
- Git installed
- Access to the marketplace repository

## Installation

### 1. Clone the marketplace repository

```bash
git clone <repository-url>
cd applications.agents-marketplace.plugins
```

### 1.5. Check for Updates (Optional)

Run the Cursor update script to see available plugins and their configurations:

```powershell
.\.cursor\update-marketplace.ps1
```

This script will:
- Check for marketplace updates
- List available plugins
- Display MCP configurations that need to be added to Cursor settings
- Run any required install scripts

### 2. Configure MCP servers in Cursor

For each plugin you want to use, you need to add its MCP server configuration to Cursor's settings.

#### Finding Cursor's MCP Settings

Cursor supports MCP servers through its settings. To configure them:

1. **Open Cursor Settings**
   - Use the keyboard shortcut: `Cmd + ,` (macOS) or `Ctrl + ,` (Windows/Linux)
   - Or: Click the gear icon → Settings

2. **Access the settings JSON**
   - Click the "Open Settings (JSON)" icon in the top right (or search for "settings.json")
   - This opens your Cursor `settings.json` file

3. **Add MCP Server Configuration**
   - Add or update the `mcpServers` section in your settings
   - Each server configuration goes inside the `mcpServers` object

#### Example Cursor Settings Structure

Your Cursor `settings.json` should have a structure like this:

```json
{
  "editor.fontSize": 14,
  "...": "other settings...",
  "mcpServers": {
    "Intel Geni (prod)": {
      "type": "http",
      "url": "https://laas-aks-prod01.laas.icloud.intel.com/agentgateway/api/a2a/geni/genimcpserver/"
    },
    "trust-mcp-server": {
      "type": "http",
      "url": "https://laas-aks-prod01.laas.icloud.intel.com/agentgateway/api/a2a/trust/trustmcpserver/"
    }
  }
}
```

#### Option A: Quick Setup via Settings UI

1. Open Cursor Settings (Cmd/Ctrl + ,)
2. Search for "MCP" in the settings search bar
3. Click "Edit in settings.json" next to any MCP-related setting
4. Add the MCP server configurations from the plugin's `.cursor-mcp.json` file

#### Option B: Manually edit Cursor settings

1. Open Cursor's settings file:
   - Use Command Palette (`Cmd/Ctrl + Shift + P`) → "Preferences: Open User Settings (JSON)"
   - Or manually locate:
     - **macOS**: `~/Library/Application Support/Cursor/User/settings.json`
     - **Windows**: `%APPDATA%\Cursor\User\settings.json`
     - **Linux**: `~/.config/Cursor/User/settings.json`

2. Add the `mcpServers` configuration from each plugin's `.cursor-mcp.json` file

### 3. Install plugin dependencies

Some plugins require additional setup. Check each plugin's README for specific requirements.

#### Example: VDC Plugin

```powershell
cd plugins/dcg/pse/vdc-plugin
./install.ps1
```

## Available Plugins

### Geni Plugin

**Location**: `plugins/dcg/pse/geni-plugin/`

**Type**: HTTP MCP Server

**Cursor MCP Config**: Add to your Cursor settings (`mcpServers` section):

```json
{
  "Intel Geni (prod)": {
    "type": "http",
    "url": "https://laas-aks-prod01.laas.icloud.intel.com/agentgateway/api/a2a/geni/genimcpserver/"
  }
}
```

### VDC Plugin

**Location**: `plugins/dcg/pse/vdc-plugin/`

**Type**: stdio MCP Server

**Prerequisites**: Run `install.ps1` first to install VDC CLI

**Cursor MCP Config**: Add to your Cursor settings, replacing `<path-to-marketplace>` with the full path to your cloned marketplace repository:

```json
{
  "vdc": {
    "type": "stdio",
    "command": "node",
    "args": [
      "<path-to-marketplace>/plugins/dcg/pse/vdc-plugin/skills/install-vdc/scripts/ensure-vdc-and-start-mcp.js"
    ]
  }
}
```

**Example** (Windows):
```json
{
  "vdc": {
    "type": "stdio",
    "command": "node",
    "args": [
      "C:/Views/applications.agents-marketplace.plugins/plugins/dcg/pse/vdc-plugin/skills/install-vdc/scripts/ensure-vdc-and-start-mcp.js"
    ]
  }
}
```

### TRUST MCP Server

**Location**: `plugins/dcg/pse/trust-mcp-server/`

**Type**: HTTP MCP Server

**Cursor MCP Config**: Add to your Cursor settings:

```json
{
  "trust-mcp-server": {
    "type": "http",
    "url": "https://laas-aks-prod01.laas.icloud.intel.com/agentgateway/api/a2a/trust/trustmcpserver/"
  }
}
```

## Updating Plugins

To update plugins to the latest version:

```powershell
cd applications.agents-marketplace.plugins
.\.cursor\update-marketplace.ps1
```

The script will:
- Pull the latest changes from the repository
- Notify you of any new plugins
- Display the MCP configurations for new plugins
- Run install scripts for plugins with missing dependencies

Then restart Cursor to reload the MCP server configurations.

## Troubleshooting

### MCP server not connecting

1. Check that the MCP server configuration is correct in Cursor settings
2. Verify any required CLI tools are installed (e.g., VDC CLI for vdc-plugin)
3. Check Cursor's MCP logs: View → Output → select "MCP" from dropdown

### Plugin not working

1. Ensure you've copied the agent and skill files to Cursor's configuration directory
2. Restart Cursor after making configuration changes
3. Check that all dependencies are installed

## Support

For issues or questions:
- Check the plugin's specific README in its directory
- Contact the plugin owners listed in `.github/plugin/marketplace.json`
