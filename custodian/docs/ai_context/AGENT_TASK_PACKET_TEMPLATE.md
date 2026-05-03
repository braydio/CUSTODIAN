# AGENT TASK PACKET TEMPLATE

Use this template before implementation, review, migration, or docs work when the task is more than a trivial one-line edit.

Copy this file into `custodian/docs/ai_context/task_packets/` and name the copy after the task, for example `VALIDATION_RECIPES.md`.

## Packet Status

- Status: draft
- Owner: agent
- Created:
- Last updated:

Status values:

- `draft` - scope is being shaped
- `ready` - implementation can begin
- `in_progress` - implementation is active
- `blocked` - waiting on user input, assets, tooling, or design authority
- `complete` - implementation, docs, and validation are done

## Task

What is being changed?

## Outcome

What should be true when this packet is complete?

## Authority

- Root routing:
- Local routing:
- Active design/spec docs:
- Active runtime/docs files:
- Historical reference only:

## Work Surface

- Files or folders expected to change:
- Files or folders expected to be read but not changed:
- Out-of-scope areas:

## Constraints

- Determinism concerns:
- Simulation/UI boundary concerns:
- Asset requirements:
- Compatibility or migration concerns:
- Clarifying questions or assumptions:

## Implementation Plan

1. 
2. 
3. 

## Acceptance

- Runtime behavior:
- Documentation:
- Path/reference validation:
- Manual validation:
- Automated/headless validation:

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update?
- Does `custodian/docs/ai_context/CONTEXT.md` need an update?
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update?
- Does `custodian/AGENTS.md` need an update?
- Do any design docs need an update?

## Completion Notes

- Implemented:
- Validated:
- Deferred:
