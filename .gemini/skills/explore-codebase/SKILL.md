---
name: explore-codebase
description: Navigate and understand codebase structure using the knowledge graph
---

## Explore Codebase

Use the code-review-graph MCP tools to explore and understand the codebase.

### Steps

1. Run `list_graph_stats` to see overall codebase metrics.
2. Run `get_architecture_overview_tool` for high-level community structure.
3. Use `list_communities_tool` to find major modules, then `get_community` for details.
4. Use `semantic_search_nodes_tool` to find specific functions or classes.
5. Use `query_graph_tool` with patterns like `callers_of`, `callees_of`, `imports_of` to trace relationships.
6. Use `list_flows` and `get_flow` to understand execution paths.

### Tips

- Start broad (stats, architecture) then narrow down to specific areas.
- Use `children_of` on a file to see all its functions and classes.
- Use `find_large_functions` to identify complex code.

## Token Efficiency Rules
- In the persistent coordination checkout, start with `get_minimal_context(task="<your task>")` when the graph is ready.
- In a linked/ephemeral worktree, do **not** cold-build a graph merely because the first call reports `missing_graph`, `not_ready`, empty/unmapped, or stale coverage. If baseline structural context is useful, point CRG at the persistent coordination root; then verify every implementation/review fact against the current worktree.
- If the graph is unusable after one cheap attempt, immediately use targeted symbol/path reads. Current worktree files and `git diff` are authoritative for branch-local changes.
- When the task packet provides a bounded `## Context Pack`, generate it once from the claimed worktree with `scripts/ai/pack-context.sh task ...` and use it instead of broad file dumping.
- Use `detail_level="minimal"` on graph calls. Escalate only when minimal is insufficient.
- Target: complete any review/debug/refactor task in ≤5 graph calls and ≤800 graph-output tokens.
