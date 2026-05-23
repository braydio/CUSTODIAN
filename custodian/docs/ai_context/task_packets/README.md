# Agent Task Packets

Last updated: 2026-05-19

Task packets are short, task-scoped planning and handoff files for CUSTODIAN agents.

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

## Archive

Completed packets are moved to `archived/`. They are preserved for historical reference but are no longer active task surfaces.

## Active Packets

### In Progress

- `COGNITIVE_STATE_PHASE_B.md` — Wire cognitive state modifiers into game systems and fix debug panel bugs. Implementation done; awaiting Godot runtime validation of move speed, attack recovery, accuracy bonus, and crit bonus modifiers. Manual test: F12 toggles debug panel, cognitive items change player stats visually.
- `UI_GD_FIXES.md` — Fix 11 hard compile blockers, runtime bugs, and performance issues in `ui.gd`. 10 of 11 fixes verified in code; Fix #11 (minimap rebuild performance) deferred. Boot sequence and stub cleanup still need Godot runtime confirmation.

### Recently Complete (awaiting archive)

- `CHANGE_CONTROL_BUNDLE_SCRIPT.md` — Adds a change-control bundler that writes current git-changed files to `custodian/docs/change_control/<TASK_PACKET_NAME>.md` and copies the bundle to the clipboard when available.
- `GOTHIC_COMPOUND_LAYOUT_GRAMMAR.md` — Hardens gothic compound asset metadata, zoning, decal quotas, anchoring, footprint placement, and perimeter validation.
