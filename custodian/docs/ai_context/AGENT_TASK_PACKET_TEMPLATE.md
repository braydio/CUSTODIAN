# AGENT TASK PACKET TEMPLATE

Repository defaults are inherited from `custodian/AGENTS.md` and the root
`AGENTS.md`; do not duplicate them here. Packets capture task-specific scope and
acceptance only.

Use the smallest coherent completion boundary. Skip a packet for narrow,
low-risk work. Sequential migration steps may share one packet and acceptance
gate; independent commits within that boundary are fine. Do not split work into
review-dependent micro-packets when it shares an architectural acceptance gate.
Add sections only when they preserve task-specific information needed for
high-risk or multi-session work.

Copy this file into `custodian/docs/ai_context/task_packets/` only when a packet
adds value. Delete unused optional sections from the copy.

# [TASK NAME]

- Workstream: `<lowercase-kebab-id>`
- Status: `draft`
- Goal:
- Current measured state:
- Task-specific authority:
- Change:
- Preserve:
- Non-goals:
- Acceptance:
- Task overrides: `none` or list each as `TASK OVERRIDE: ...`
- Deferred:

Status values: `draft`, `ready`, `in_progress`, `blocked`, `complete`.

## Full Packet Expansion

Add only sections that preserve useful task-specific information.

### Ownership And Timing

- Owner:
- Agent/session:
- Created:
- Last updated:

### Work Surface

- Files/systems to change:
- Related consumers or tests:

### Plan

1.
2.
3.

### Handoff

- Next action:
- Best starting files:
- Blockers or open questions:
