# Fabrication Runtime Wiring

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-10
- Created: 2026-05-10
- Last updated: 2026-05-10

## Task

Restore the missing fabrication data files and bridge the live harvest resource IDs into the canonical fabrication economy so the existing `fab_*` DevConsole commands work against real resources.

## Outcome

`ResourceLedger` loads resource metadata, `FabPipeline` loads starter recipes, harvested flavor IDs like `blackwood` and `structural_alloy` resolve to the canonical fabrication resources, and the debug fabrication commands can start jobs from the current world state.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md`, `design/RESOURCE_FAB_PIPELINE_ADD.md`
- Active runtime/docs files: `custodian/autoload/resource_ledger.gd`, `custodian/autoload/fab_pipeline.gd`, `custodian/game/ui/hud/ui.gd`, `custodian/content/resources/`, `custodian/content/fabrication/`
- Historical reference only: older `python-sim/` fabrication notes

## Work Surface

- Files or folders expected to change: `custodian/autoload/resource_ledger.gd`, `custodian/content/resources/resource_defs.json`, `custodian/content/fabrication/fab_recipes.json`, AI context docs
- Files or folders expected to be read but not changed: `custodian/autoload/fab_pipeline.gd`, `custodian/game/ui/hud/ui.gd`, `custodian/game/resources/resource_node.gd`
- Out-of-scope areas: full fabricator UI, save/load, procedural resource placement, new buildables

## Constraints

- Determinism concerns: keep resource normalization and recipe payment explicit and reproducible
- Simulation/UI boundary concerns: the ledger owns totals; UI/debug commands only query or request starts
- Asset requirements: none
- Compatibility or migration concerns: preserve the live flavor resource IDs by aliasing them into the canonical fabrication economy
- Clarifying questions or assumptions: treat `blackwood` as `timber`, `structural_alloy` as `ore`, and `ruin_scrap` as `scrap` for V1

## Implementation Plan

1. Add the missing fabrication JSON files using the live runtime schema.
2. Normalize harvested flavor resource IDs inside `ResourceLedger`.
3. Validate the fabrication commands and update active context docs.

## Acceptance

- Runtime behavior: `fab_grant`, `fab_recipes`, and `fab_start` can operate with the current world resource nodes
- Documentation: active state and file index reflect the canonical fabrication data files
- Path/reference validation: the missing JSON paths exist and load without warnings
- Manual validation: `fab_status` shows resources and jobs after a grant/start cycle
- Automated/headless validation: Godot check/load passes without missing fab JSON warnings

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes
- Does `custodian/AGENTS.md` need an update? No
- Do any design docs need an update? Probably not for this narrow wiring slice

## Completion Notes

- Implemented: added `resource_defs.json` and `fab_recipes.json`, normalized live harvest flavor IDs in `ResourceLedger`, and confirmed the starter fabricator recipe can be granted and completed through the autoload runtime.
- Validated: `godot --headless --path . --check-only --quit`; temporary headless smoke script verified `fab_grant` resources, `fab_start barricade_light`, job completion, and build-token output.
- Deferred: full fabrication UI and save/load.

## Next Steps

- Next action: run fabrication commands against the new data files and confirm the alias mapping works
- Best starting files: `custodian/autoload/resource_ledger.gd`, `custodian/content/resources/resource_defs.json`, `custodian/content/fabrication/fab_recipes.json`
- Required context: active resource fabrication design docs
- Validation to run: `godot --headless --check-only --quit`, then `fab_status`/`fab_recipes`/`fab_grant`/`fab_start` smoke checks
- Blockers or open questions: none
