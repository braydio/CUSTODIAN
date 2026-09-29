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
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `none`
- Locks: `none`
- Kind: `implementation`
- Review: `none`
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

Dispatch defaults safely to `manual`; only explicitly marked `auto` packets
can be selected by `dispatch.py claim-next`. Priority is `P0` (highest) through
`P3` (lowest). Dependencies name workstream IDs that must have complete
archived packets on `origin/main`. Locks are comma-separated narrow ownership
IDs held for the duration of a published claim, or `none`.

### Review Metadata

For substantial implementation work, decide review intent when the packet is
created:

```text
- Kind: `implementation` | `review` | `correction`
- Review: `auto` | `manual` | `none`
- Review stage: `post-land`
- Review modes: comma-separated `code, architecture, runtime, visual,
  asset-pipeline, workflow`, or `none`
- Paired review workstream: `<id>` or `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
```

Safe defaults keep historical packets valid without this section: missing
`Kind` is `implementation`; missing `Review` is `none`; missing `Review stage`
defaults to `post-land` only when `Review` is `auto`; missing `Review cycle`
is `0`; missing `Max automatic review cycles` is `2`.

When `Review: auto` is selected, also create a paired review packet on `main`
using `AGENT_REVIEW_PACKET_TEMPLATE.md`, and set this packet's `Paired review
workstream` to its ID. `dispatch.py`'s review-pairing consistency guard
(`custodian/tools/agent/validate_review_pairing.py`) fails closed if the pair
is missing or malformed; see `task_packets/README.md` for the full paired
review and correction lifecycle.

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
