# VALIDATION RECIPES TASK PACKET

## Packet Status

- Status: complete
- Owner: agent
- Created: 2026-05-03
- Last updated: 2026-05-03

## Task

Add a canonical validation recipes document for Godot/runtime/docs/asset-pipeline validation, repair the related agent prompt templates, and wire the agent workflow docs into the active context pack.

## Outcome

Agents can quickly find expected validation commands, choose the right validation level for common work types, discover reusable prompt templates, and avoid stale paths or unsafe commit/staging guidance.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/`
- Active runtime/docs files: `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/CONTEXT.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/docs/ai_context/VALIDATION_RECIPES.md`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/CONTEXT.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
  - `custodian/docs/ai_context/prompts/`
  - `custodian/AGENTS.md`
  - `AGENTS.md`
- Files or folders expected to be read but not changed:
  - `custodian/project.godot`
  - `custodian/tools/pipelines/`
  - `tools/tiles/`
  - `design/`
- Out-of-scope areas:
  - Runtime gameplay behavior
  - Godot scene edits
  - New test harness implementation
  - Asset regeneration
  - Git commits or broad staging actions

## Constraints

- Determinism concerns: validation docs must call out deterministic fixed-step simulation checks for runtime/gameplay changes.
- Simulation/UI boundary concerns: validation recipes should remind agents to verify that UI/rendering changes do not become hidden simulation authority.
- Asset requirements: no new production art is needed.
- Compatibility or migration concerns: preserve root-to-local routing and do not reclassify legacy Python files as active authority.
- Clarifying questions or assumptions: assume validation recipes are documentation-only guidance until a future task adds scripts or automated harnesses.

## Implementation Plan

1. Create `custodian/docs/ai_context/VALIDATION_RECIPES.md` with command recipes and selection guidance.
2. Add or update prompt-template index material and fix stale prompt paths.
3. Link the recipes and prompts from `custodian/AGENTS.md`, `AGENTS.md`, `CONTEXT.md`, and `FILE_INDEX.md`.
4. Update `CURRENT_STATE.md` to record the new agent workflow artifacts.
5. Validate paths and references with `rg`/shell reads.

## Acceptance

- Runtime behavior: unchanged.
- Documentation: validation recipes and prompt templates are discoverable from root routing, local routing, and the AI context pack.
- Path/reference validation: all referenced paths exist or are explicitly identified as future commands/examples.
- Manual validation: read the new docs and verify the recipe selection rules are clear.
- Automated/headless validation: not required for this doc-only packet.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? Yes.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? Yes.
- Do any design docs need an update? No runtime/design behavior changes are expected.

## Completion Notes

- Implemented: added `custodian/docs/ai_context/VALIDATION_RECIPES.md`, prompt index, runtime review prompt, stale prompt path fixes, safer git prompt rules, agent work modes, `Next Agent Slice` guidance, and routing/index updates.
- Validated: checked referenced prompt paths, validation docs, task packet links, and stale path patterns with RTK-backed shell reads/searches.
- Deferred: no automated Godot validation was run because this packet only changed documentation and agent workflow guidance.

## Next Steps

- Next action: consider adding lightweight validation scripts from `custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md`.
- Best starting files: `custodian/docs/ai_context/VALIDATION_RECIPES.md`, `custodian/docs/ai_context/prompts/`, `custodian/docs/ai_context/task_packets/`.
- Required context: read `custodian/AGENTS.md` and `custodian/docs/ai_context/FILE_INDEX.md`.
- Validation to run: stale-path search plus any new script dry-run.
- Blockers or open questions: none for this completed packet.
