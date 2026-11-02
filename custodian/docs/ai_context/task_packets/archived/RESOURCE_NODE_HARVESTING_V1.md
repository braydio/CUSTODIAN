# RESOURCE NODE HARVESTING V1

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-09
- Created: 2026-05-09
- Last updated: 2026-05-09

## Task

Attach a first harvestable resource-node slice to the new `ResourceLedger` fabrication spine.

## Outcome

The live game should have simple interactable resource nodes that can be depleted through the operator's existing `interactable` flow and deposit CUSTODIAN-flavored resources into `ResourceLedger`.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md`, `design/RESOURCE_FAB_PIPELINE_ADD.md`, `design/features/implementation/FAB_PIPELINE_SYSTEM.md`
- Active runtime/docs files: `custodian/game/actors/operator/operator.gd`, `custodian/autoload/resource_ledger.gd`, `custodian/scenes/game.tscn`
- Historical reference only: `design/04_research/resource_fabrication/*`, `python-sim/`

## Work Surface

- Files or folders expected to change: `custodian/game/resources/`, `custodian/scenes/game.tscn`, active AI context docs
- Files or folders expected to be read but not changed: operator interaction code, fabrication autoloads
- Out-of-scope areas: production resource art, procedural placement, placement mode, full fabricator UI

## Constraints

- Determinism concerns: Node yields should be explicit exported values with no random runtime roll in V1.
- Simulation/UI boundary concerns: Resource nodes mutate `ResourceLedger`; HUD only reads prompts through the existing operator path.
- Asset requirements: Use placeholder `Polygon2D` visuals; no production art invented.
- Compatibility or migration concerns: Reuse the existing `interactable` group to avoid a second input-routing system.
- Clarifying questions or assumptions: First test nodes can be hand-placed near the current start area.

## Implementation Plan

1. Add `ResourceNode` script and scene.
2. Configure node presets through scene-instance exported values.
3. Place a small set of test nodes near the starting area in `game.tscn`.
4. Validate scripts/project load and update docs.

## Acceptance

- Runtime behavior: Interacting with a node advances work progress, depletes at zero work, and adds configured primary/secondary yields to `ResourceLedger`.
- Documentation: Active context describes resource-node harvesting as live.
- Path/reference validation: New resource-node files are indexed.
- Manual validation: Headless project load.
- Automated/headless validation: Godot script checks for resource node and project load.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Update implementation note next steps.

## Completion Notes

- Implemented: Added `ResourceNode` script/scene, reused the existing operator `interactable` flow, and placed blackwood, structural alloy, and ruin-scrap test nodes near the starting area in `game.tscn`.
- Validated: `godot --headless --check-only --script res://game/resources/resource_node.gd`; `godot --headless --quit`; temporary smoke test confirmed primary and secondary yields deposit into `ResourceLedger` only after depletion.
- Deferred: Production art, procedural resource placement, dedicated harvest VFX/SFX, full fabricator UI, and build-token placement.

## Next Steps

- Next action: Add fabrication UI/debug commands or build-token placement.
- Best starting files: `custodian/autoload/fab_pipeline.gd`, `custodian/autoload/build_inventory.gd`, `custodian/game/ui/hud/ui.gd`, `custodian/game/systems/core/systems/turret_placement.gd`
- Required context: Existing operator `interactable` flow.
- Validation to run: Script checks for UI/placement files and a smoke test that spends resources, completes a job, then consumes a build token.
- Blockers or open questions: None.
