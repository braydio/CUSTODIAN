# CUSTODIAN Agent Summary Home

This directory is the permanent Git-tracked home for task and workstream
closeout summaries. The repository root is **not** a summary destination.

## New workstreams

Write one durable summary to:

```text
custodian/docs/ai_context/agent_summaries/<workstream-id>/AGENT_SUMMARY.md
```

Use the canonical lowercase kebab-case workstream ID for the directory.
The file's contents must include:

- `Workstream: <workstream-id>`
- `Agent: Claude`, `Agent: Codex`, or the actual agent implementation
- `Authoring chat: <exact URL>` when recorded on the task packet
- scoped implementation/validation, failures and process feedback
- the next action and unresolved gates

Update the same workstream summary across task turns. Commit it alongside the
work; do not put it in untracked scratch space or write a root-level
`*_CLAUDE_SUMMARY.md` regardless of the agent's identity.

## Historical summaries

Files stored directly in this directory with names such as
`<TASK>_CLAUDE_SUMMARY.md`, `<TASK>_CODEX_SUMMARY.md`, and
`<TASK>_SUMMARY.md` were moved from the project root *without changing
their Git blob contents*. These historical names reflect their original
provenance, not a requirement for all agents to call themselves Claude.

Historical source-scope attestations may pin the former root paths at
specific **historical revisions**. Do not rewrite immutable historical evidence
to follow this move. The active summary reader and workstream closeout accept
both new and legacy names during transition, but newly authored summaries
must use the workstream-scoped `AGENT_SUMMARY.md` path.

All asset- or review-dependent evidence stays with its existing owner and
is not replaced by this summary.
