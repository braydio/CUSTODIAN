# VEHICLE FIELD SCOUT BUGGY CLASS V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vehicle-field-scout-buggy-class-v1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-vehicle-runtime-lifecycle-hardening-v1`
- Locks: `vehicle-content, vehicle-runtime-scene`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-vehicle-field-scout-buggy-class-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new production vehicle class/data/scene integration`
- Reviewed main: `ad2868d66a`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Turn the existing first vehicle registry entry into the concrete Custodian Field Scout Buggy Mk I class with semantic scene identity and data-owned durability while preserving established handling and pilotability.
- Completion boundary: Done when registry ID `custodian_ground_buggy_scout_light` resolves to a semantically named Field Scout scene, movement/durability/seat/footprint/hardpoint contracts are data-driven and validator-covered, the live game scene uses that class, no unnecessary class-specific GDScript behavior duplicates `PilotableVehicle`, and compatibility naming has an explicit disposition.
- Current measured state: Registry ID `custodian_ground_buggy_scout_light` resolves to `Custodian Field Scout Buggy Mk I` in `field_scout_buggy_mk1.tscn`. `ground_wheeled_light` values are preserved; profile `light_scout_utility` owns 100 max health and feeds the shared `PilotableVehicle` health fields. The semantic scene is live in `game.tscn`, with the old constant health bar removed. Hover frames remain only through the explicitly temporary compatibility kit `custodian_field_scout_buggy_mk1_compat_hover`.
- Evidence: `custodian/content/vehicles/vehicle_archetypes.json`; `vehicle_movement_profiles.json`; `vehicle_hardpoint_profiles.json`; `vehicle_loadouts.json`; `vehicle_visual_kits.json`; `vehicle_registry_schema.json`; `custodian/game/actors/vehicles/field_scout_buggy_mk1.tscn`; `custodian/content/vehicles/vehicle_durability_profiles.json`; `custodian/scenes/game.tscn`; `custodian/game/vehicles/vehicle_definition.gd`; `vehicle_registry.gd`; `design/02_features/vehicles/FIELD_SCOUT_BUGGY_MK1.md`.
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
- Refresh planning chat: `not-recorded`
- Refresh instruction: At claim time, re-read reviewed predecessor lifecycle public APIs and reconcile only mechanical names. If review materially changes the ownership/class boundary, stop rather than broadening this packet.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `removed`
- Evidence: Registry validation, safe-exit smoke, predecessor lifecycle smoke, and `vehicle_field_scout_class_smoke.gd` passed. The focused smoke proves semantic ID/name/scene, shared durability profile application without resetting current health, exact seat/footprint/hardpoint contract, no orphan HealthBar, and live `game.tscn` instantiation. Changed-file validation covered all files but did not finish green: 22/27 selected checks passed, 3 failed, and 2 timed out. The vehicle-specific checks passed. Two unrelated failures were reproduced on baseline `origin/main`; the remaining failure and timeouts are unrelated scene smokes against the same live scene. Exact suite evidence and resolution status are in the closing summary.
- Outcome: `complete`
- Landed behavior: Stable registry ID and exact movement profile remain unchanged; the semantic Field Scout scene is production/live; 100 max health is profile-owned and consumed by the single `PilotableVehicle` state; one driver, 2x1 footprint, hardpoints, and unarmed loadout remain explicit.
- Legacy disposition: Removed `light_buggy.tscn` after migrating the only runtime consumer and world-origin contract. Hover art is preserved under a class-specific compatibility kit with an explicit Asset V2 exit.
- Focused coverage: `custodian/tools/validation/vehicle_field_scout_class_smoke.gd`, registered as `vehicle_field_scout_class`.
- Moment Forge: `run_moment.py --changed` selected no matching scenario; no vehicle class scenario currently exists.
- Deferred: Production wheeled artwork and generalized Asset V2 vehicle-family support remain with the Asset V2 successor; scanner behavior, combat loadout, and handling changes remain out of scope.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `The fresh checkout had no generated Godot class/import cache, so the first direct script attempt could not resolve project class_name types. A one-time editor import resolved it; all subsequent focused checks passed.`
- Root cause / contributing factors: `The new worktree did not yet have its ignored Godot import/class cache.`
- Prevention / pipeline improvement: `Use the validation runner's import-aware path or perform the one-time editor import before direct Godot scripts in fresh worktrees.`
- Tooling / docs drift discovered: `none`
- Follow-up: `vehicle-field-scout-buggy-asset-v2`
- What worked: `The class smoke exercises registry data, runtime health profile consumption, scene composition, and live game-scene binding in one deterministic proof.`

## Handoff

- Next workstream: `review-vehicle-field-scout-buggy-class-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Summary backlink: `n/a`
- Refresh reason: `none`
- Next action: Finish normally so paired review can prove the first concrete class.
- Blockers or open questions: `none`
