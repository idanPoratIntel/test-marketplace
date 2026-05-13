# Agent Plugin Marketplace

A general marketplace of plugins, agents, and MCP servers — organized by organization and team — for use with AI coding agent clients.


---

## Overview

This marketplace is a collection of **agent plugins** — each plugin bundles AI agent definitions, reusable skills, and optional MCP server configuration. Install a plugin in your preferred AI coding agent client (VS Code Copilot, Cursor, Claude Code) to unlock domain-specific workflows without writing custom prompts.

Plugins are organized hierarchically under `plugins/<org>/<group>/<plugin>` so that multiple organizations and teams can contribute and maintain their own plugins.

```
agent-plugin-marketplace/
├── plugins/
│   └── dcg/
│       └── pse/
│           ├── geni-plugin/          # Query Intel internal knowledge bases via Geni MCP server
│           ├── vdc-plugin/           # Manage Intel Virtual Data Center resources via VDC CLI MCP server
│           └── trust-mcp-server/     # Expose TRUST (Rapid Unit Selection Tool) selected features via MCP
├── docs/
│   ├── agent-plugin-marketplace-slides.html  # HTML slide deck (open in browser)
│   └── CURSOR_SETUP.md              # Cursor IDE setup guide
├── .github/
│   ├── CODEOWNERS                    # Plugin & repo ownership for PR review routing
│   ├── agent-plugin-marketplace-overview.md  # Architecture, diagrams, governance
│   └── plugin/
│       └── marketplace.json          # Plugin registry (VS Code)
└── .cursor/
    ├── plugin/
    │   └── marketplace.json          # Plugin registry (Cursor)
    └── update-marketplace.ps1        # Cursor update script
```

For a fuller picture (diagrams, generic layout, and governance), see **[`.github/agent-plugin-marketplace-overview.md`](.github/agent-plugin-marketplace-overview.md)**. For an **HTML slide version**, open [`docs/agent-plugin-marketplace-slides.html`](docs/agent-plugin-marketplace-slides.html) in your browser (self-contained; no CDN).

### Governance (summary)

- **Blue badge** is the default baseline for the marketplace or hosting surface.
- **Green badge** access is granted via the **AGS group** (not implied by blue badge alone). **Contributors** can use **AGS** when they are entitled under the same policy.
- **Every plugin has owners** for approvals: listed in `marketplace.json` (`owners`) and enforced for PRs via **`CODEOWNERS`** for that plugin path; registry-only edits need marketplace owners as noted in `CODEOWNERS`.

---

## Using Plugins

### For VS Code Copilot Users

The marketplace includes automation that checks for updates and installs new plugins automatically. Simply open the workspace and the task will run.

### For Cursor Users

The marketplace includes:
- **`.cursor/plugin/marketplace.json`** - Cursor-specific plugin registry
- **`.cursor/update-marketplace.ps1`** - Update script for checking new plugins
- **Plugin-specific `.cursor-mcp.json`** files - MCP server configurations

Run the update script to check for new plugins:
```powershell
.\.cursor\update-marketplace.ps1
```

See **[`docs/CURSOR_SETUP.md`](docs/CURSOR_SETUP.md)** for detailed setup instructions.

### For Other AI Coding Clients

Plugins follow standard conventions:
- **Agents**: defined in `agents/*.md` files
- **Skills**: defined in `skills/*/SKILL.md` files  
- **MCP Servers**: configuration in `.mcp.json` (VS Code) or `.cursor-mcp.json` (Cursor)

---

## Plugins

| Plugin                       | Description                                                                 | Category        |
| ---------------------------- | --------------------------------------------------------------------------- | --------------- |
| [`geni-plugin`](#geni-plugin)           | Query Intel internal knowledge bases (Axon, HSD) via the Geni MCP server    | Developer Tools |
| [`vdc-plugin`](#vdc-plugin)             | Manage Intel Virtual Data Center resources via the local VDC CLI MCP server | Developer Tools |
| [`trust-mcp-server`](#trust-mcp-server) | Expose TRUST (Rapid Unit Selection Tool) selected features via MCP           | Developer Tools |

---
