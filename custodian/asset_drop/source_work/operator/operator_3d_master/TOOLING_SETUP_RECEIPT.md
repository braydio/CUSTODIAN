# Blender MCP tooling receipt (2026-10-27)

- Blender 5.2.3 LTS (not reinstalled). uv 0.5.9 already present. No pre-existing `blender` MCP server; nothing listening on 9876 beforehand.
- Upstream: https://projects.blender.org/lab/blender_mcp.git @ dbbf836, cloned to ~/.local/share/blender_mcp (outside CUSTODIAN). Code inspected: socket bridge binds localhost by default; execution is only a "weak sandbox".
- Add-on: built from addon/blender_mcp_addon with `blender --command extension build`, installed with `extension install-file -r user_default --enable` (id `mcp` 1.0.0). Zip not committed.
- Claude Code: `claude mcp add --scope local blender -- uv --directory ~/.local/share/blender_mcp/mcp run blender-mcp`, local scope for this worktree only. No CUSTODIAN .mcp.json or other MCP entries changed. `claude mcp get blender`: Connected. A new Claude session is needed before the tools appear in-session.
- Blender side: headless on a disposable copy of the exp-005 .blend, `blender --online-mode -b copy.blend --command blender_mcp` (online flag is per-launch only). `ss -ltn` showed 127.0.0.1:9876 only.
- Round trip verified through the real MCP server with a stdio client: tool discovery returned 26 tools; get_objects_summary returned the exp-005 scene; read-only execute_blender_code returned "5.2.3 LTS" and 103 objects. Server then stopped; no listener or process remains.
- Residual risk: execute_blender_code runs arbitrary Python in Blender. Use it only on disposable copies; production proofs stay scripted (`blender -b`). This is not a separate Unix user or container.
