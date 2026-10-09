---
name: debug-issue
description: Systematically debug issues using graph-powered code navigation
---

## Debug Issue

Use the knowledge graph to systematically trace and debug issues.

### Steps

1. Use `semantic_search_nodes_tool` to find code related to the issue.
2. Use `query_graph_tool` with `callers_of` and `callees_of` to trace call chains.
3. Use `get_flow` to see full execution paths through suspected areas.
4. Run `detect_changes_tool` to check if recent changes caused the issue.
5. Use `get_impact_radius_tool` on suspected files to see what else is affected.

### Tips

- Check both callers and callees to understand the full context.
- Look at affected flows to find the entry point that triggers the bug.
- Recent changes are the most common source of new issues.

## Token Efficiency Rules
- In the persistent coordination checkout, start with `get_minimal_context(task="<your task>")` when the graph is ready.
- In a linked/ephemeral worktree, do **not** cold-build a graph merely because the first call reports `missing_graph`, `not_ready`, empty/unmapped, or stale coverage. If baseline structural context is useful, point CRG at the persistent coordination root; then verify every implementation/review fact against the current worktree.
- If the graph is unusable after one cheap attempt, immediately use targeted symbol/path reads. Current worktree files and `git diff` are authoritative for branch-local changes.
- When the task packet provides a bounded `## Context Pack`, generate it once from the claimed worktree with `scripts/ai/pack-context.sh task ...` and use it instead of broad file dumping.
- Use `detail_level="minimal"` on graph calls. Escalate only when minimal is insufficient.
- Target: complete any review/debug/refactor task in ≤5 graph calls and ≤800 graph-output tokens.
