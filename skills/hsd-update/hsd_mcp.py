#!/usr/bin/env python3
"""
HSD (Hardware Sighting Database) — MCP Server (stdio transport).

Exposes HSD article read, query, and update operations as MCP tools
so VS Code Chat and Copilot CLI can call them natively.

Run:  python hsd_mcp.py
"""

import json
import sys
import os

from mcp.server.fastmcp import FastMCP

# Re-use the core HSD client
sys.path.insert(0, os.path.dirname(__file__))
from hsd_client import HSDAPIClient

mcp = FastMCP("hsd-update")

# Shared client instance (lazy-init on first tool call)
_client: HSDAPIClient = None


def _get_client() -> HSDAPIClient:
    """Get or create a shared HSD client with Kerberos auth + SSL verification disabled."""
    global _client
    if _client is None:
        _client = HSDAPIClient(verify_ssl=False, auth_method="auto")
    return _client


# ── Read Tools ────────────────────────────────────────────────────

@mcp.tool()
def hsd_get_article(sighting_id: str, fields: str = "") -> str:
    """Retrieve an HSD article/sighting by its ID.

    Args:
        sighting_id: The HSD article/sighting ID (e.g. '1306793693').
        fields: Optional comma-separated list of fields to return
                (e.g. 'id,title,status,priority,owner,description').
                Leave empty to return all fields.
    """
    client = _get_client()
    fields_list = [f.strip() for f in fields.split(",") if f.strip()] if fields else None
    result = client.get_article(sighting_id=sighting_id, fields=fields_list)
    return json.dumps(result, indent=2)


@mcp.tool()
def hsd_query_by_title(title: str) -> str:
    """Query/search HSD articles by title substring.

    Args:
        title: Search string to match against article titles (e.g. 'geni').
    """
    client = _get_client()
    result = client.query_by_title(title=title)
    return json.dumps(result, indent=2)


# ── Update Tools ──────────────────────────────────────────────────

@mcp.tool()
def hsd_update_article(
    sighting_id: str,
    tenant: str,
    subject: str,
    field_values_json: str,
) -> str:
    """Update an HSD article with new field values.

    IMPORTANT: The caller MUST confirm with the user before invoking this tool.

    If you don't know the tenant/subject, call hsd_get_article first to inspect them.

    Args:
        sighting_id: The HSD article/sighting ID (e.g. '1306793693').
        tenant: The HSD tenant (e.g. 'sighting_central', 'server', 'client').
        subject: The article subject type (e.g. 'sighting').
        field_values_json: JSON object string of fields to update,
                           e.g. '{"status": "closed", "priority": "high"}'.
    """
    client = _get_client()
    try:
        field_values = json.loads(field_values_json)
    except json.JSONDecodeError as e:
        return json.dumps({
            "success": False,
            "error": f"Invalid JSON in field_values_json: {e}",
        })
    if not isinstance(field_values, dict):
        return json.dumps({
            "success": False,
            "error": "field_values_json must be a JSON object (dict)",
        })
    result = client.update_article(
        sighting_id=sighting_id,
        tenant=tenant,
        subject=subject,
        field_values=field_values,
    )
    return json.dumps(result, indent=2)


if __name__ == "__main__":
    mcp.run(transport="stdio")
