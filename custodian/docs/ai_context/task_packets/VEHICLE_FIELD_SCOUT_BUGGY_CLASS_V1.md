# VEHICLE FIELD SCOUT BUGGY CLASS V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vehicle-field-scout-buggy-class-v1`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-vehicle-runtime-lifecycle-hardening-v1`
- Locks: `vehicle-content, vehicle-runtime-scene`
- Kind: `implementation`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `superseded before implementation by the wreck-restoration design change; canonical work continues in vehicle-field-scout-buggy-class-v1-recovery-1`
- Reviewed main: `5020df4b88a2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Supersession note: The remote claim `agent/vehicle-field-scout-buggy-class-v1` subsequently produced donor commit `b3b40921f1fd08c6aff529cbe0b39953587bbb85`. The implementation is useful but was authored against this superseded pristine-spawn contract. Do not finish/land it as this workstream. Preserve the commit and summary as donor evidence, release the superseded workstream locks, then use the wreck-restoration foundation followed by `vehicle-field-scout-buggy-class-v1-recovery-1`.
- Goal: Turn the existing first vehicle registry entry into the concrete Custodian Field Scout Buggy Mk I class with semantic scene identity and data-owned durability while preserving established handling and pilotability.
- Completion boundary: Done when registry ID `custodian_ground_buggy_scout_light` resolves to a semantically named Field Scout scene, movement/durability/seat/footprint/hardpoint contracts are data-driven and validator-covered, the live game scene uses that class, no unnecessary class-specific GDScript behavior duplicates `PilotableVehicle`, and compatibility naming has an explicit disposition.
- Current measured state: The registry classifies the first vehicle as CUSTODIAN/GROUND/BUGGY/SCOUT/LIGHT/MK1 with WHEELED mobility, `ground_wheeled_light`, `utility_light`, one driver, 2x1 footprint, and runtime scene `res://game/actors/vehicles/light_buggy.tscn`. Max/current health are generic exports in `PilotableVehicle`, no durability profile is registry-owned, the scene carries an unbound constant HealthBar, and its visual kit is still `custodian_hover_buggy_light`.
- Evidence: `custodian/content/vehicles/vehicle_archetypes.json`; `vehicle_movement_profiles.json`; `vehicle_hardpoint_profiles.json`; `vehicle_loadouts.json`; `vehicle_visual_kits.json`; `vehicle_registry_schema.json`; `custodian/game/actors/vehicles/light_buggy.tscn`; `custodian/scenes/game.tscn`; `custodian/game/vehicles/vehicle_definition.gd`; `vehicle_registry.gd`; `design/02_features/vehicles/FIELD_SCOUT_BUGGY_MK1.md`.
- Task-specific authority: `design/02_features/vehicles/FIELD_SCOUT_BUGGY_MK1.md`; `design/02_features/vehicles/VEHICLES.md`; current registry/schema validation.
- Work surface: Vehicle content JSON/schema and `VehicleDefinition`; new semantic scene `custodian/game/actors/vehicles/field_scout_buggy_mk1.tscn`; live scene/registry consumers; only minimal shared runtime changes needed to consume durability/profile data.
- Change: Preserve stable registry ID but make display identity `Custodian Field Scout Buggy Mk I`. Add the smallest durability-profile data authority needed to own max health (profile `light_scout_utility`, max health 100) and have `PilotableVehicle` consume it without creating another health state. Preserve `ground_wheeled_light` exactly: max speed 175, acceleration 420, deceleration 520, turn response 10, reverse 0.45, offroad 0.78, road multiplier enabled. Create/migrate to `field_scout_buggy_mk1.tscn` with one driver seat, existing collision/exit semantics, `FrontLight` and `RearUtility`, and no baked weapon. Keep loadout `none`; do not activate data-only `light_scanner`. Remove or explicitly alias `light_buggy.tscn` according to remaining consumers. Temporary hover art may remain only as clearly named compatibility presentation until the Asset V2 successor lands.
- Preserve: Reviewed predecessor lifecycle; registry ID; current movement feel/terrain multiplier; 64 px interaction radius; 2x1 footprint; one driver/zero passengers; safe exit; procgen placement semantics; unarmed utility role.
- Non-goals: No boost, fuel, cargo inventory, scanner gameplay, passengers, weapons, collision damage, handling rebalance, production art creation, or vehicle-specific subclass unless live code proves genuine stateful behavior requiring one.
- Acceptance: Registry resolves the stable ID to the semantic Field Scout scene; display name is `Custodian Field Scout Buggy Mk I`; movement values match pre-migration exactly; max health comes from named durability profile into the single runtime health authority; scene exposes declared driver seat, footprint/collision, exit marker, and hardpoints; `game.tscn` instantiates the semantic class; no stale constant health presentation remains; no duplicate movement/occupancy authority appears; any retained `light_buggy` alias has a live consumer and exit condition.
- Validation: Run `res://tools/validation/validate_vehicle_registry.gd` and `res://tools/validation/vehicle_exit_clearance_smoke.gd` first, then the predecessor lifecycle regression. Extend/create focused registry/scene validation for class identity, durability, exact movement values, seat/hardpoint paths, and game-scene instantiation; record its exact path before closeout and register it in `validation_manifest.json`. Then changed-file closeout.
- Task overrides: `none`
- Deferred: Production wheeled artwork; Asset V2 family/generalized post-processing; scanner behavior; mounted combat; additional chassis classes.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh instruction: At claim time, re-read reviewed predecessor lifecycle public APIs and reconcile only mechanical names. If review materially changes the ownership/class boundary, stop rather than broadening this packet.

## Handoff

- Next workstream: `vehicle-wreck-restoration-foundation-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `User changed the acquisition contract: world-spawned vehicles must begin as wreckage and require restoration.`
- Next action: Preserve donor commit `b3b40921` and its summary, release this superseded workstream without landing it, execute wreck restoration, then claim the class recovery and selectively reapply compatible donor changes.
- Blockers or open questions: `The superseded branch now contains useful donor work, so release must preserve b3b40921/summary while freeing vehicle-content / vehicle-runtime-scene locks; do not spend time greening unrelated broad validation for a workstream that must not land.`
