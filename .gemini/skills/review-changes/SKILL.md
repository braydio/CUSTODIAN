---
name: review-changes
description: Perform a structured code review using change detection and impact
---

## Review Changes

Perform a thorough, risk-aware code review using the knowledge graph.

### Steps

1. Run `detect_changes_tool` to get risk-scored change analysis.
2. Run `get_affected_flows_tool` to find impacted execution paths.
3. For each high-risk function, run `query_graph_tool` with pattern="tests_for" to check test coverage.
4. Run `get_impact_radius_tool` to understand the blast radius.
5. For any untested changes, suggest specific test cases.

### Output Format

Provide findings grouped by risk level (high/medium/low) with:
- What changed and why it matters
- Test coverage status
- Suggested improvements
- Overall merge recommendation

## Token Efficiency Rules
- In the persistent coordination checkout, start with `get_minimal_context(task="<your task>")` when the graph is ready.
- In a linked/ephemeral worktree, do **not** cold-build a graph merely because the first call reports `missing_graph`, `not_ready`, empty/unmapped, or stale coverage. If baseline structural context is useful, point CRG at the persistent coordination root; then verify every implementation/review fact against the current worktree.
- If the graph is unusable after one cheap attempt, immediately use targeted symbol/path reads. Current worktree files and `git diff` are authoritative for branch-local changes.
- When the task packet provides a bounded `## Context Pack`, generate it once from the claimed worktree with `scripts/ai/pack-context.sh task ...` and use it instead of broad file dumping.
- Use `detail_level="minimal"` on graph calls. Escalate only when minimal is insufficient.
- Target: complete any review/debug/refactor task in ≤5 graph calls and ≤800 graph-output tokens.
