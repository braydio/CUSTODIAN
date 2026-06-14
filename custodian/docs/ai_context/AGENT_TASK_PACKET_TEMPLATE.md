# AGENT TASK PACKET TEMPLATE

Template last updated: 2026-06-12

Task packets are optional risk-control and handoff records. Use the lightest level that preserves useful context:

- Skip: narrow, low-risk, single-session work with obvious acceptance and no meaningful handoff risk.
- Compact: ordinary non-trivial work where scope, constraints, acceptance, or deferred work should survive the current session.
- Full: multi-session work; architecture or ownership changes; migrations; high-risk runtime or asset-pipeline work; substantial handoffs.

Do not create or expand a packet merely because several files change.

Copy this file into `custodian/docs/ai_context/task_packets/` only when a packet adds value. Delete unused optional sections from the copy.

# [TASK NAME]

- Status: `draft`
- Authority:
- Goal:
- Files:
- Constraints:
- Acceptance:
- Completed:
- Deferred:

Status values: `draft`, `ready`, `in_progress`, `blocked`, `complete`.

## Full Packet Expansion

Add only the sections needed for higher-risk or multi-session work.

### Ownership And Timing

- Owner:
- Agent/session:
- Created:
- Last updated:

### Work Surface

- Read:
- Change:
- Out of scope:

### Plan

1.
2.
3.

### Drift Review

- Primary authority:
- `CURRENT_STATE.md`:
- `CONTEXT.md`:
- `FILE_INDEX.md`:
- Local routing/readmes:

### Handoff

- Next action:
- Best starting files:
- Validation to run:
- Blockers or open questions:
