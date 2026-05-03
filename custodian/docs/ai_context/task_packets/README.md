# Agent Task Packets

Task packets are short, task-scoped planning and handoff files for CUSTODIAN agents.

Use a packet when work affects runtime behavior, architecture, validation workflow, asset workflow, documentation routing, or more than one file. For a trivial one-line edit, a packet is optional unless the user asks for one.

## Workflow

1. Copy `../AGENT_TASK_PACKET_TEMPLATE.md` into this folder.
2. Rename it after the task in uppercase snake case, for example `VALIDATION_RECIPES.md`.
3. Fill the task, outcome, authority, work surface, constraints, plan, and acceptance sections before implementation starts.
4. Keep the packet current if scope, blockers, validation, or documentation requirements change.
5. Mark it `complete` only after implementation, docs updates, and feasible validation are done.

## Current Packets

- `VALIDATION_RECIPES.md` - implementation packet for adding canonical validation recipes to the active AI context pack.
