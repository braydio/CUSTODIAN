# EXPEDITION RESOURCE PLACEMENT STEP 1

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-26
- Created: 2026-05-26
- Last updated: 2026-05-26

## Task

Implement the first step of expedition-scale resource placement while the user creates the remaining production resource-node assets.

## Outcome

Generated contract maps include a deterministic, non-respawning, far-from-compound resource patch that uses the resource-specific `ResourceNode` presets without requiring a separate expedition travel UI yet.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/resource_collection/RESOURCE_COLLECTION_PLAN.md`, `design/02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md`
- Active runtime/docs files: `custodian/game/systems/core/systems/contract_world_loader.gd`, `custodian/game/resources/resource_node.gd`, `REQUIRED_ASSETS.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: `custodian/game/systems/core/systems/contract_world_loader.gd`, validation smoke, active docs/context, required asset trackers
- Files or folders expected to be read but not changed: existing sprite runtime sheets
- Out-of-scope areas: travel UI, separate expedition destination selection, respawn scheduling, enemy threat scaling, new art creation

## Constraints

- Determinism concerns: Placement must be stable from generated map data and exported knobs, not runtime random rolls.
- Simulation/UI boundary concerns: Placement instantiates existing `ResourceNode` interactables only; resource accounting remains inside `ResourceNode`/`ResourceLedger`.
- Asset requirements: Do not wire assets that do not exist; track missing power/fiber production strips.
- Compatibility or migration concerns: Existing tutorial resource node smoke must keep passing with blackwood/alloy/wreckage.
- Clarifying questions or assumptions: Treat step one as a far-field patch in the current contract map rather than a new world-map expedition system.

## Implementation Plan

1. Add missing power/fiber node-strip entries to both required asset trackers.
2. Add deterministic far-field resource patch placement in `ContractWorldLoader`.
3. Extend smoke validation and update design/context docs.

## Acceptance

- Runtime behavior: Generated contract maps still place tutorial nodes and also place a bounded expedition patch away from spawn/compound.
- Documentation: Active design/context describe the first expedition placement slice and deferred full expedition system.
- Path/reference validation: Required asset trackers stay identical.
- Manual validation: Not required for this headless placement slice.
- Automated/headless validation: Godot script checks and contract resource-node smoke pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes.

## Completion Notes

- Implemented: Added required asset tracker entries for missing power/fiber production node strips, added export-controlled far-field expedition resource placement in `ContractWorldLoader`, reused compatible resource-node presets for eight non-respawning generated nodes, filtered placement away from compound/road/parking/interior regions, and expanded the resource-node smoke test to verify tutorial plus expedition placement.
- Validated: `godot --headless --path custodian --check-only --script res://game/systems/core/systems/contract_world_loader.gd`; `godot --headless --path custodian --check-only --script res://tools/validation/contract_resource_node_smoke.gd`; `godot --headless --path custodian --script res://tools/validation/contract_resource_node_smoke.gd`; required asset tracker copies compared identical.
- Deferred: Separate expedition destination/travel UI, extraction loop, respawn/migration scheduling, encounter threat scaling, and direct power/fiber source nodes until the missing production strips exist.

## Next Steps

- Next action: Wire `power_node` and `moss_patch` presets after the missing production strips are supplied, then split far-field placement into named expedition destination profiles.
- Best starting files: `custodian/game/systems/core/systems/contract_world_loader.gd`, `custodian/tools/validation/contract_resource_node_smoke.gd`
- Required context: Existing tutorial node placement and procgen intent/intensity metadata.
- Validation to run: Godot script checks and resource-node smoke.
- Blockers or open questions: None.
