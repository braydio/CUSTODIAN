# VEHICLE REGISTRY IMPLEMENTATION

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-29
- Created: 2026-05-29
- Last updated: 2026-05-29

## Task

Implement the clear production-ready slices from `design/02_features/vehicles/VEHICLES.md`: vehicle registry data, registry/runtime classes, first pilotable vehicle scene hookup, player input routing, camera target switching, validation script, and AI context updates.

## Outcome

The first production vehicle can be defined by registry ID, validated, spawned through a resolver, entered/exited with Interact, and driven through `PlayerController` while preserving existing runtime compatibility.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/vehicles/VEHICLES.md`
- Active runtime/docs files: `custodian/game/systems/core/player_controller.gd`, `custodian/game/actors/vehicles/light_buggy.tscn`, `custodian/game/world/camera.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: `python-sim/`, superseded vehicle docs listed by the vehicle spec

## Work Surface

- Files or folders expected to change: `custodian/game/vehicles/`, `custodian/content/vehicles/`, `custodian/game/systems/core/player_controller.gd`, `custodian/game/world/camera.gd`, `custodian/game/actors/vehicles/light_buggy.tscn`, `custodian/tools/validate_vehicle_registry.gd`, active AI context docs
- Files or folders expected to be read but not changed: existing operator, procgen surface multiplier, contract vehicle positioning, project input map
- Out-of-scope areas: weapons/hardpoint behavior beyond no-op data validation, production firing/damage/destruction animation assets, unsupported vehicle domains beyond registry validation and spawn refusal

## Constraints

- Determinism concerns: vehicle movement must stay physics-step driven and data-backed.
- Simulation/UI boundary concerns: `PlayerController` owns input intent; vehicles own movement response.
- Asset requirements: reuse existing hover buggy runtime frames; do not invent new production art.
- Compatibility or migration concerns: preserve existing `vehicle` group and `VehicleBase`-style method names where practical.
- Clarifying questions or assumptions: use `custodian_ground_buggy_scout_light` as the first production ID and point it at the existing hover buggy scene.

## Implementation Plan

1. Add vehicle content JSON and registry/runtime scripts.
2. Add/convert pilotable vehicle scene support and route current buggy through the new base.
3. Update player controller and camera follow target switching.
4. Add registry validation script and run feasible headless checks.
5. Update AI context docs and mark this packet complete.

## Acceptance

- Runtime behavior: registry loads, first vehicle validates/spawns, operator enters/exits and control switches.
- Documentation: active AI context documents index the new vehicle system.
- Path/reference validation: all new `res://` paths exist.
- Manual validation: deferred unless Godot editor/play is required after headless validation.
- Automated/headless validation: run vehicle registry validator and Godot headless import/boot where feasible.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No unless workflow/guardrails change.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Only if implementation constraints diverge from `VEHICLES.md`.

## Completion Notes

- Implemented: vehicle JSON registry content, `VehicleDefinition`, `VehicleRegistry`, `VehicleSpawnResolver`, `VehicleInputAdapter`, `PilotableVehicle`, `VehicleSeat`, debug overlay, base pilotable scene, current `LightBuggy` conversion, `PlayerController` routing, camera follow-target switching, registry validator, AI context docs, and design-doc status update.
- Validated: `godot --headless --path . --script res://tools/validate_vehicle_registry.gd`; `godot --headless --import --quit` filtered for new vehicle parse/errors; `godot --headless --quit`.
- Deferred: manual in-editor enter/drive/exit feel check; production firing, damage, and destruction vehicle animations remain tracked as art-incomplete.

## Next Steps

- Next action: run a manual gameplay pass for enter/drive/exit feel and tune movement profile values if needed.
- Best starting files: `custodian/content/vehicles/vehicle_archetypes.json`, `custodian/game/vehicles/pilotable_vehicle.gd`, `custodian/game/systems/core/player_controller.gd`, `custodian/game/actors/vehicles/light_buggy.tscn`
- Required context: existing operator interaction, camera follow, procgen surface multiplier.
- Validation to run: `cd custodian && godot --headless --path . --script res://tools/validate_vehicle_registry.gd`; `cd custodian && godot --headless --import --quit`; `cd custodian && godot --headless --quit`
- Blockers or open questions: none for the registry-backed first pass.
