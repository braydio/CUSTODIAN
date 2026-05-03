# VALIDATION RECIPES TASK PACKET

## Packet Status

- Status: ready
- Owner: agent
- Created: 2026-05-03
- Last updated: 2026-05-03

## Task

Add a canonical validation recipes document for Godot/runtime/docs/asset-pipeline validation and wire it into the active agent context.

## Outcome

Agents can quickly find the expected validation commands and choose the right validation level for doc-only changes, Godot runtime changes, scene/load checks, sprite pipeline work, asset/path changes, and docs-drift reviews.

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

## Constraints

- Determinism concerns: validation docs must call out deterministic fixed-step simulation checks for runtime/gameplay changes.
- Simulation/UI boundary concerns: validation recipes should remind agents to verify that UI/rendering changes do not become hidden simulation authority.
- Asset requirements: no new production art is needed.
- Compatibility or migration concerns: preserve root-to-local routing and do not reclassify legacy Python files as active authority.
- Clarifying questions or assumptions: assume validation recipes are documentation-only guidance until a future task adds scripts or automated harnesses.

## Implementation Plan

1. Create `custodian/docs/ai_context/VALIDATION_RECIPES.md` with command recipes and selection guidance.
2. Link the recipes from `custodian/AGENTS.md`, `AGENTS.md`, `CONTEXT.md`, and `FILE_INDEX.md`.
3. Update `CURRENT_STATE.md` to record the new agent workflow artifact.
4. Validate paths and references with `rg`/shell reads.

## Acceptance

- Runtime behavior: unchanged.
- Documentation: validation recipes are discoverable from root routing, local routing, and the AI context pack.
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

- Implemented:
- Validated:
- Deferred:
