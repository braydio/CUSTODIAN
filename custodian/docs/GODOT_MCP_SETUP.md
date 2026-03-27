# Godot MCP Setup Notes

## Default Behavior

The plugin connects to:

- `ws://127.0.0.1:6505`

Source:

- `res://addons/godot_mcp/mcp_client.gd`

## Environment Overrides

Set these before launching Godot:

- `GODOT_MCP_URL`
  - Overrides the default WebSocket URL.
  - Example: `GODOT_MCP_URL=ws://127.0.0.1:7001`

- `GODOT_MCP_DISABLE_AUTOCONNECT`
  - Disables automatic MCP connect on editor startup.
  - Truthy values: `1`, `true`, `yes`

## Quick Launch Examples

```bash
GODOT_MCP_URL=ws://127.0.0.1:6505 godot --path custodian
```

```bash
GODOT_MCP_DISABLE_AUTOCONNECT=1 godot --path custodian
```

## One-Command Launcher

Repository helper script:

- `scripts/start-godot-mcp.sh`

Examples:

```bash
./scripts/start-godot-mcp.sh
```

```bash
./scripts/start-godot-mcp.sh --headless-editor
```

Behavior:

- If MCP server is already listening at `GODOT_MCP_URL` (default `ws://127.0.0.1:6505`), it reuses it.
- Otherwise it starts `npx -y godot-mcp-server`, waits for socket readiness, and then launches Godot.

## Troubleshooting

- If status stays on "Connecting" or "Disconnected", verify the MCP server is already listening at the configured URL.
- If another tool already uses `6505`, pick a free port and set `GODOT_MCP_URL` to match.
- If startup logs show socket permission errors, check local firewall/sandbox restrictions and run outside restricted environments.
