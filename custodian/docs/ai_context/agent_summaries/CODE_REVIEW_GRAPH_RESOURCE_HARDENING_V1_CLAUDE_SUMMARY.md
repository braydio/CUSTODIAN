# code-review-graph resource hardening v1

## Done
- Audit: one live graph (root, 585 MB). Seven stale worktree graphs (~1.7 GB) and 12 abandoned uv `.tmp*` dirs (3.6 GB) deleted; uv cache 9.5 GB -> 6.0 GB. Root graph untouched.
- Root graph `embeddings` table has 0 rows, so the `[embeddings]` extra (torch + CUDA, ~5.9 GB) was never used. `semantic_search_nodes_tool` ran in `keyword` mode against the root graph with the lightweight install.
- `tools/crg-pin.env` is now the single source for the version (2.3.8, no extras) and the read-only MCP `--tools` allowlist.
- `.mcp.json` and `tools/crg-refresh.sh` use the pin; `~/.codex/config.toml` (user-level, backup `~/.codex/config.toml.bak-crg-20261027`) updated the same way, other settings preserved.
- MCP servers no longer expose build/postprocess/embed/refactor-apply/wiki tools (verified: `build_or_update_graph_tool` returns "Unknown tool"). Graph updates stay in the CLI hook.
- `tools/check_crg_config.py` checks pin/allowlist/root cwd for `.mcp.json` and Codex, and exercises the hook with a fake `uvx`: linked worktree skips update, `CRG_HOOK_WORKTREES=1` allows it, root runs a pinned update.
- `AGENTS.md` documents the install contract and that search is keyword/FTS without embeddings.

## Not done / risks
- Live sessions (a Claude session on pts/7, the Codex app-server daemon) still run the old embeddings env; not killed. They pick up the new config on restart. After that, `uv cache clean` (or `prune`) can reclaim most of the remaining 5.9 GB; not run yet, so the final cache size is unmeasured.
- A direct `code-review-graph build|update` CLI call is not intercepted.
- Other tracked client configs (`opencode.jsonc`, `.qoder/`, `.gemini/`, `.kiro/`, `.codebuddy/`) are unpinned and untouched; only Claude and Codex are in use, so they could be removed in a separate change.
