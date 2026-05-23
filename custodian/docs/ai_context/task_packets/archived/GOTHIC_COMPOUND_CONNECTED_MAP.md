# Gothic Compound Connected Map

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex CLI 2026-05-19
- Created: 2026-05-19
- Last updated: 2026-05-19

## Task

Create a connected gothic compound map that can be traveled to from the generated main map, using the gothic compound docs/assets as runtime authority.

## Outcome

- A gothic compound destination exists under the live `World`.
- A main-map gate lets the operator travel into the gothic compound.
- A return gate lets the operator travel back to the main map.
- The destination uses the documented command keep, machine house, open gate, control console, bell/fountain/obelisk, roads, walls, and resource-node art roles.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `custodian/content/procgen/special_rooms/gothic_compound/classification.md`
- Active runtime/docs files: `custodian/game/systems/core/systems/contract_world_loader.gd`, `custodian/scenes/game.tscn`, `custodian/game/world/camera.gd`
- Historical reference only: legacy Python-era map generation notes

## Work Surface

- Files or folders expected to change:
  - `custodian/game/world/procgen/gothic_compound/`
  - `custodian/game/world/gothic_compound/`
  - `custodian/game/systems/core/systems/contract_world_loader.gd`
  - `custodian/game/world/camera.gd`
  - `design/features/implementation/GOTHIC_COMPOUND_PROCGEN.md`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
- Files or folders expected to be read but not changed:
  - `custodian/content/procgen/special_rooms/gothic_compound/`
  - `custodian/game/world/procgen/`
- Out-of-scope areas:
  - full procedural compound room assembly
  - save/load persistence for visited submaps
  - new production art

## Constraints

- Determinism concerns: placement should be derived from contract map data and fixed local authored layout, not random runtime state.
- Simulation/UI boundary concerns: travel should stay in world/runtime scripts, not HUD logic.
- Asset requirements: use existing gothic compound PNGs; do not invent new art.
- Compatibility or migration concerns: preserve current procgen main-map generation and portal-ring behavior.
- Clarifying questions or assumptions: assume "connected map" can be a first authored submap in the same world, reached by an interactable gate, with broader map streaming/save work deferred.

## Implementation Plan

1. Add gothic compound map and travel gate scripts using existing `interactable` conventions.
2. Instantiate/place the connected map after contract generation and place the main-map gate near compound ingress.
3. Add camera bounds support for non-procgen connected maps and update context docs.

## Acceptance

- Runtime behavior:
  - A gothic compound map is created after contract generation.
  - Interacting with the main gate moves the operator to the compound map.
  - Interacting with the return gate moves the operator back to the main map.
- Documentation:
  - Current state and file index mention the connected gothic compound slice.
- Path/reference validation:
  - New script/resource paths resolve in Godot.
- Manual validation:
  - Travel path can be tested in the live game with the existing interact key.
- Automated/headless validation:
  - Godot check-only/headless load should pass without script parse errors.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: Added an authored gothic compound connected map, main-map entry gate, compound return gate, contract-world placement wiring, camera bounds support for authored connected maps, and a reusable constraint-first gothic compound blueprint generator with asset registry/config/result/validator/Sprite2D adapter modules.
- Validated: `godot --headless --path custodian --check-only --script` passed for gothic compound procgen modules, `gothic_compound_travel_gate.gd`, `gothic_compound_map.gd`, `contract_world_loader.gd`, and `camera.gd`; `godot --headless --path custodian --quit` loaded the project successfully with only pre-existing exit leak warnings.
- Deferred: Main tactical-map TileMapLayer adapter integration, full procedural gothic room assembly, save/load persistence for visited submaps, encounter composition, minimap specialization, and hands-on live travel testing.

## Next Steps

- Next action: live-play the gate interaction path and tune placement/art scale if needed.
- Best starting files: `custodian/game/systems/core/systems/contract_world_loader.gd`, `custodian/game/world/camera.gd`
- Required context: gothic compound classification docs and existing interactable contract.
- Validation to run: `godot --headless --path custodian --check-only --script <changed scripts>` and `godot --headless --path custodian --quit`.
- Blockers or open questions: none.
