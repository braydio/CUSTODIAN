# RESOURCE NODE SPRITE WIRING

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-26
- Created: 2026-05-26
- Last updated: 2026-05-26

## Task

Wire the available per-resource harvesting-node sprite sheets under `custodian/content/sprites/props/harvesting_nodes/` into the live `ResourceNode` runtime.

## Outcome

Resource nodes use resource-specific idle/depleted sprite strips whenever compatible runtime sheets exist, and generated tutorial nodes no longer fall back to placeholder polygons for alloy and wreckage.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md`, `design/03_content/RESOURCE_COLLECTION_ASSET_SPEC.md`
- Active runtime/docs files: `custodian/game/resources/resource_node.gd`, `custodian/game/systems/core/systems/contract_world_loader.gd`, `custodian/content/sprites/props/harvesting_nodes/`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: `custodian/game/resources/`, `custodian/game/systems/core/systems/contract_world_loader.gd`, active resource/fabrication docs, AI context indexes
- Files or folders expected to be read but not changed: sprite PNG/import assets
- Out-of-scope areas: new production art, procedural expedition placement, operator harvest animations

## Constraints

- Determinism concerns: Sprite selection must be data/path based, not random.
- Simulation/UI boundary concerns: Visual defaults must not change resource ledger accounting.
- Asset requirements: Only wire compatible 96x96 runtime node strips that already exist.
- Compatibility or migration concerns: Keep existing generated node kinds (`alloy_vein`, `machine_wreckage`) stable for smoke tests and callers.
- Clarifying questions or assumptions: Treat the user's `harvest_nodes` path as the existing `harvesting_nodes` runtime folder.

## Implementation Plan

1. Add default sprite path resolution for compatible resource/node kinds in `ResourceNode`.
2. Add missing tutorial preset sprite paths for alloy and wreckage.
3. Update design/context docs and validation coverage.

## Acceptance

- Runtime behavior: Resource nodes configured as compatible kinds build `AnimatedSprite2D` frames from their specific idle/depleted sheets.
- Documentation: Active design and AI context mention per-resource node sprite support.
- Path/reference validation: All wired sprite paths exist.
- Manual validation: Not required beyond headless smoke for this non-interactive asset wiring slice.
- Automated/headless validation: Script checks for `resource_node.gd` and generated tutorial resource nodes.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes.

## Completion Notes

- Implemented: Added default per-kind sprite path resolution in `ResourceNode`, wired generated alloy/wreckage tutorial nodes to their resource-specific strips, added compatible rare-resource presets, and expanded the resource-node smoke test to verify generated and default sprite playback frames.
- Validated: `godot --headless --path custodian --check-only --script res://game/resources/resource_node.gd`; `godot --headless --path custodian --check-only --script res://game/systems/core/systems/contract_world_loader.gd`; `godot --headless --path custodian --check-only --script res://tools/validation/contract_resource_node_smoke.gd`; `godot --headless --path custodian --script res://tools/validation/contract_resource_node_smoke.gd`.
- Deferred: `power_components_*`, `fiber_moss`, and flat concept/resource PNGs remain unwired until compatible 96px idle/depleted node strips exist.

## Next Steps

- Next action: Add matching production strips for power/fiber source nodes or start expedition-scale placement when design is ready.
- Best starting files: `custodian/game/resources/resource_node.gd`, `custodian/game/systems/core/systems/contract_world_loader.gd`
- Required context: Existing generated resource-node placement and compatible runtime PNG strips.
- Validation to run: Godot script checks and contract resource node smoke test.
- Blockers or open questions: None.
