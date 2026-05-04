# Agent Task Packets

Last updated: 2026-05-04

Task packets are short, task-scoped planning and handoff files for CUSTODIAN agents.

Use a packet when work affects runtime behavior, architecture, validation workflow, asset workflow, documentation routing, or more than one file. For a trivial one-line edit, a packet is optional unless the user asks for one.

## Workflow

1. Copy `../AGENT_TASK_PACKET_TEMPLATE.md` into this folder.
2. Rename it after the task in uppercase snake case, for example `VALIDATION_RECIPES.md`.
3. Fill the task, outcome, authority, work surface, constraints, plan, and acceptance sections before implementation starts.
4. Keep the packet current if scope, blockers, validation, next steps, or documentation requirements change.
5. Before handoff, blocked status, or completion, update `Next Steps` with the next action, best starting files, required context, validation to run, and blockers/open questions.
6. Mark it `complete` only after implementation, docs updates, feasible validation, completion notes, and next-step notes are done.

## Ownership

- Reuse a packet only when it is scoped to the current task.
- Create a new packet for a different task, even if related files overlap.
- Do not update another agent's in-progress packet unless the user asks or that packet is explicitly the active task surface.
- Set `Agent/session` in new packets with a stable handle, such as `Codex 2026-05-03T11:xx`.
- Update `Last updated` whenever a packet changes.

## Current Packets

- `AGENT_WORKFLOW_AUTOMATION.md` - completed packet for task-packet next steps, ownership rules, and automation backlog.
- `VALIDATION_RECIPES.md` - completed implementation packet for canonical validation recipes and prompt-template cleanup.
- `COGNITIVE_STATE_PHASE_B.md` - in-progress runtime packet for cognitive modifier integration and debug panel validation.
- `PROCGEN_WALL_PASSAGE_VISIBILITY.md` - completed packet for making generated passage wall tiles visible on normal procgen wall runs.
- `PROCGEN_WALL_TOP_SOURCE_PREPROCESSING.md` - completed packet for adding `--top-source` preprocessing support to the wall atlas builder.
