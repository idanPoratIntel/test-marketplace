# Cursor Configuration

This directory contains Cursor IDE-specific marketplace configuration and automation.

## Files

### `plugin/marketplace.json`
The Cursor-specific plugin registry that lists all available plugins with:
- Plugin metadata (name, version, description)
- Source paths to plugin directories
- References to `.cursor-mcp.json` MCP configuration files
- Plugin owners

This is the canonical list for Cursor plugin discovery and management.

### `update-marketplace.ps1`
PowerShell script that:
- Checks for marketplace repository updates
- Lists new plugins added since last update
- Runs install scripts for new plugins or missing dependencies
- Displays MCP server configurations that need to be added to Cursor settings

**Usage:**
```powershell
.\.cursor\update-marketplace.ps1
```

### `tasks.json`
VS Code/Cursor task configuration that automatically runs the update script when you open the workspace folder.

## Plugin Structure

Each plugin in the marketplace includes Cursor support through:

1. **`.cursor-mcp.json`** - MCP server configuration for Cursor
   - Format matches Cursor's MCP settings schema
   - Includes server type (http/stdio), URLs, commands, and args

2. **`plugin.json`** - Plugin manifest with `cursorMcpServers` field pointing to the `.cursor-mcp.json` file

3. **`agents/`** (optional) - Agent definition files (`.agent.md`)
4. **`skills/`** (optional) - Reusable skill definitions (`SKILL.md`)

## Adding Cursor Support to a New Plugin

When adding a new plugin to the marketplace:

1. Create `.cursor-mcp.json` in the plugin directory with MCP server config
2. Add `"cursorMcpServers": "./.cursor-mcp.json"` to `plugin.json`
3. Add plugin entry to `.cursor/plugin/marketplace.json`
4. Update plugin entry in `.github/plugin/marketplace.json` (VS Code registry)

## Manual MCP Configuration

Cursor users can manually add MCP servers by copying configurations from plugin `.cursor-mcp.json` files to Cursor's settings:

**Cursor Settings Location:**
- Command Palette: `Preferences: Open User Settings (JSON)`
- macOS: `~/Library/Application Support/Cursor/User/settings.json`
- Windows: `%APPDATA%\Cursor\User\settings.json`
- Linux: `~/.config/Cursor/User/settings.json`

Add to the `mcpServers` section in your settings.

For detailed setup instructions, see [`../docs/CURSOR_SETUP.md`](../docs/CURSOR_SETUP.md).
