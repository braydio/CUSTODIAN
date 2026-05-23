# FAB PIPELINE V1

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-09
- Created: 2026-05-09
- Last updated: 2026-05-09

## Task

Start the resource and fabrication pipeline implementation from the active resource fabrication design docs, incorporating `design/RESOURCE_FAB_PIPELINE_ADD.md`.

## Outcome

CUSTODIAN should have a first runtime fabrication spine: resource accounting, recipe data, queued fabrication jobs, completed build-token inventory, and a lightweight terminal bridge. Harvesting and placement can attach to this spine in follow-up slices without changing the economic authority.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md`, `design/RESOURCE_FAB_PIPELINE_ADD.md`
- Active runtime/docs files: `custodian/project.godot`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: `design/04_research/resource_fabrication/*`, `python-sim/`

## Work Surface

- Files or folders expected to change: `custodian/autoload/`, `custodian/game/fabrication/`, `custodian/content/fabrication/`, `custodian/content/resources/`, `custodian/project.godot`, `design/features/implementation/`, active AI context docs
- Files or folders expected to be read but not changed: active resource fabrication design docs and existing autoload config
- Out-of-scope areas: resource-node harvesting scene placement, build placement mode, full fabricator UI, save/load, power scaling

## Constraints

- Determinism concerns: Ledger operations and job completion must be explicit and reproducible from game-time deltas.
- Simulation/UI boundary concerns: The pipeline owns resource/build-token state; UI/terminal layers should only query or request recipe starts.
- Asset requirements: None for this slice.
- Compatibility or migration concerns: Keep `InventoryManager` separate from fabrication resources in V1.
- Clarifying questions or assumptions: Treat `RESOURCE_FAB_PIPELINE_ADD.md` as a refinement that supersedes generic `timber/ore` naming with CUSTODIAN-flavored resource IDs and build-token outputs.

## Implementation Plan

1. Add resource and recipe JSON data.
2. Add `ResourceLedger`, `BuildInventory`, `FabJob`, `FabRecipeDatabase`, `FabPipeline`, and `FabricatorTerminal`.
3. Register autoloads for resource ledger, build inventory, and fab pipeline.
4. Add an implementation design note for the build-token-first V1 slice.
5. Validate new scripts and update AI context docs.

## Acceptance

- Runtime behavior: Starting an affordable recipe spends resources immediately, queues a job, and grants output build tokens or unlocks/resources on completion.
- Documentation: Current state, file index, and task packet describe the first fab pipeline slice.
- Path/reference validation: New runtime paths are indexed and load as `res://` resources.
- Manual validation: Optional debug calls through autoloads.
- Automated/headless validation: Godot script checks for new scripts and project load.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, add V1 implementation note under `design/features/implementation/`.

## Completion Notes

- Implemented: Added CUSTODIAN-flavored resource metadata, starter fabrication recipe JSON, `ResourceLedger`, `BuildInventory`, `FabJob`, `FabRecipeDatabase`, `FabPipeline`, `FabricatorTerminal`, autoload registrations, and a build-token-first implementation design note.
- Validated: Godot script checks for all new scripts, project headless load, and a temporary smoke test that grants resources, starts `barricade_light`, ticks the job past completion, and verifies a `barricade_light` build token.
- Deferred: Resource-node harvesting actors, build placement mode, full terminal/fabricator UI, save/load persistence, and power-aware fab scaling.

## Next Steps

- Next action: Add resource-node harvesting or a debug fabricator UI against the new autoloads.
- Best starting files: `custodian/autoload/fab_pipeline.gd`, `custodian/autoload/resource_ledger.gd`, `custodian/game/fabrication/fabricator_terminal.gd`
- Required context: Active resource fabrication system doc and `RESOURCE_FAB_PIPELINE_ADD.md`.
- Validation to run: Script checks for new harvesting/UI files plus a smoke test that confirms `ResourceLedger` totals and `BuildInventory` tokens change as expected.
- Blockers or open questions: None.
