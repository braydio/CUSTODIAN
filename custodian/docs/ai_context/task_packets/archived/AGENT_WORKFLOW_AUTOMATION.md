# AGENT WORKFLOW AUTOMATION — TASK PACKET

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-03 workflow-docs pass
- Created: 2026-05-03
- Last updated: 2026-05-03

Status values:

- `draft` - scope is being shaped
- `ready` - implementation can begin
- `in_progress` - implementation is active
- `blocked` - waiting on user input, assets, tooling, or design authority
- `complete` - implementation, docs, and validation are done

Ownership rules:

- Reuse an existing packet only when its task scope matches the current task.
- Create a new packet when the current task has a different scope.
- Do not edit another agent's in-progress packet unless the user asks or that packet is explicitly the active task surface.
- Update `Last updated` on every packet edit.

## Task

Add `Next Steps` handoff requirements to task packets and define the most effective automation/scripts to add for the agent workflow.

## Outcome

Future agents have a required handoff section in task packets, clear packet ownership/scoping rules, and a prioritized automation backlog for validation, stale-path detection, task-packet checks, prompt checks, and Git safety.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active docs: `custodian/docs/ai_context/`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`
  - `custodian/docs/ai_context/task_packets/README.md`
  - `custodian/docs/ai_context/task_packets/AGENT_WORKFLOW_AUTOMATION.md`
  - `custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/AGENTS.md`
- Files or folders expected to be read but not changed:
  - existing task packets not scoped to this task
  - `custodian/docs/ai_context/VALIDATION_RECIPES.md`
- Out-of-scope areas:
  - runtime gameplay code
  - another agent's in-progress task packet
  - implementing automation scripts in this pass

## Constraints

- Determinism concerns: none; docs-only workflow change.
- Simulation/UI boundary concerns: none; docs-only workflow change.
- Asset requirements: none.
- Compatibility or migration concerns: do not overwrite another agent's active packet.
- Clarifying questions or assumptions: use task scope plus `Agent/session` instead of trying to invent a global agent identity registry.

## Implementation Plan

1. Add `Next Steps` and ownership rules to the task packet template.
2. Update task packet README with reuse/create rules and timestamp requirements.
3. Add a prioritized automation backlog document.
4. Index the new packet and automation backlog in the active AI context.
5. Validate references and stale path patterns.

## Acceptance

- Runtime behavior: unchanged.
- Documentation: packet template requires `Next Steps`, packet README defines scope/ownership, and automation backlog is discoverable.
- Path/reference validation: referenced docs exist.
- Manual validation: read the docs and confirm the handoff rules are clear.
- Automated/headless validation: not required for docs-only changes.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? Yes.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: task packet `Next Steps`, ownership/scoping rules, timestamp guidance, and automation backlog.
- Validated: checked files and stale references with RTK-backed searches.
- Deferred: script implementation is intentionally broken down in the automation backlog.

## Next Steps

- Next action: implement `tools/agent/check_ai_context.py` as the first lightweight validator.
- Best starting files: `custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md`, `custodian/docs/ai_context/VALIDATION_RECIPES.md`, `custodian/docs/ai_context/task_packets/README.md`.
- Required context: `custodian/AGENTS.md` and `custodian/docs/ai_context/FILE_INDEX.md`.
- Validation to run: `python3 tools/agent/check_ai_context.py` once implemented, plus `rtk grep` stale-path checks.
- Blockers or open questions: decide whether agent workflow scripts should live under repository-root `tools/agent/` or `custodian/tools/agent/`.
