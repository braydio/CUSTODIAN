---
applyTo: '**'
description: >-
  Use code-review-graph MCP tools for token-efficient
  codebase exploration and code review.
---

<!-- code-review-graph MCP tools -->
## MCP Tools: code-review-graph

Use code-review-graph as an **opportunistic structural accelerator**, not as a
cold-start prerequisite for every ephemeral worktree.

### CUSTODIAN worktree policy

- The persistent coordination checkout is the maintained/shared CRG baseline.
  In a linked agent worktree, derive it with:
  `COORD_ROOT="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"`.
- A linked/ephemeral worktree does **not** need its own graph by default. Do not
  run `build_or_update_graph` or a full `code-review-graph update` merely
  because the first graph call reports `missing_graph`, `not_ready`, an empty
  graph, stale coverage, or no mapped symbols.
- From a linked worktree, CRG may point at `$COORD_ROOT` for baseline
  architecture, callers/dependents, and likely-test orientation. Treat that as
  a hint only. Confirm every symbol/path used for implementation or review
  against the **current worktree** and use the worktree diff as change truth.
- Never use the coordination-root graph as proof of branch-local changes that
  are not present in that checkout.
- Build/maintain a worktree-local graph only when the task explicitly benefits
  from it; opt in with `CRG_HOOK_WORKTREES=1`.
- If one cheap graph attempt is unusable, fall back immediately to targeted
  symbol/path reads. Do not spend task time repairing CRG ceremony.

### Task-scoped Repomix context

For broad multi-file tasks, a packet may provide a bounded `## Context Pack`
with repo-relative Repomix include globs. Generate it **from the claimed
worktree**, not the persistent coordination checkout:

```bash
scripts/ai/pack-context.sh task "<comma-separated include globs>" "<workstream-id>"
```

The output is ignored under `.ai/task-context/`. Generate it once at task
start (and again only after a material scope change). It is a navigation/context
snapshot, never repository authority; exact live files and `git diff` remain
truth.

### When the graph is usable

- **Exploring code**: `semantic_search_nodes_tool` or `query_graph_tool`
- **Understanding impact**: `get_impact_radius_tool`
- **Code review**: `detect_changes_tool` + `get_review_context_tool`
- **Finding relationships**: `query_graph_tool` with callers_of/callees_of/imports_of/tests_for
- **Architecture questions**: `get_architecture_overview_tool` + `list_communities_tool`

Keep graph calls narrow and token-efficient. Prefer `detail_level="minimal"`
and escalate only when needed.
