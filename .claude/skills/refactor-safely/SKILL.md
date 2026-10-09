---
name: refactor-safely
description: Plan and execute safe refactoring using dependency analysis
---

## Refactor Safely

Use the knowledge graph to plan and execute refactoring with confidence.

### Steps

1. Use `refactor_tool` with mode="suggest" for community-driven refactoring suggestions.
2. Use `refactor_tool` with mode="dead_code" to find unreferenced code.
3. For renames, use `refactor_tool` with mode="rename" to preview all affected locations.
4. Use `apply_refactor_tool` with the refactor_id to apply renames.
5. After changes, run `detect_changes_tool` to verify the refactoring impact.

### Safety Checks

- Always preview before applying (rename mode gives you an edit list).
- Check `get_impact_radius_tool` before major refactors.
- Use `get_affected_flows_tool` to ensure no critical paths are broken.
- Run `find_large_functions` to identify decomposition targets.

## Token Efficiency Rules
- In the persistent coordination checkout, start with `get_minimal_context(task="<your task>")` when the graph is ready.
- In a linked/ephemeral worktree, do **not** cold-build a graph merely because the first call reports `missing_graph`, `not_ready`, empty/unmapped, or stale coverage. If baseline structural context is useful, point CRG at the persistent coordination root; then verify every implementation/review fact against the current worktree.
- If the graph is unusable after one cheap attempt, immediately use targeted symbol/path reads. Current worktree files and `git diff` are authoritative for branch-local changes.
- When the task packet provides a bounded `## Context Pack`, generate it once from the claimed worktree with `scripts/ai/pack-context.sh task ...` and use it instead of broad file dumping.
- Use `detail_level="minimal"` on graph calls. Escalate only when minimal is insufficient.
- Target: complete any review/debug/refactor task in ≤5 graph calls and ≤800 graph-output tokens.
