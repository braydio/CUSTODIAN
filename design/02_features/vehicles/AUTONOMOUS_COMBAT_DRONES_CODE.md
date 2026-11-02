# Autonomous Combat Drones Implementation Notes

Status: implemented-v3

## Runtime Additions

- `CombatDrone` is a `CharacterBody2D` allied actor with movement, targeting, firing, health, collision, and muzzle logic.
- `AlliedInfantryDroid` subclasses `CombatDrone`, replaces the placeholder `ColorRect` with `AnimatedSprite2D` playback, and displays a small fire/follow status label. It no longer owns raw input.
- `DroneManager` is scene-mounted under `GameRoot/World`, spawns two drones into `GameRoot/World/Allies`, and owns squad command input.
- `DroneCommandProfile` centralizes tactical mode constants, follow-distance bands, separation, free-roam patrol timing, and guard engage/return/leash ranges.
- `DroneTargeting` performs deterministic nearest-target selection against non-passive enemies around either a node anchor or explicit world position.
- `CombatDrone` composes `ActorAllegianceComponent` as `operator_allied`; `AlliedInfantryDroid` inherits the relationship while retaining the legacy ally/defense/turret projectile groups.
- `DroneTargeting` owns source-aware qualification: autonomous scans require a live, targetable hostile and exclude passive actors; an explicit `drone_command_target` order may select a passive neutral/hostile actor such as Shrumb, but never an allied, dead, or untargetable actor.
- `DroneManager`, `CombatDrone` order receipt/retention, target refresh, weapon update, and every projectile commit apply that qualification. A changed allegiance, targetability, death, freed instance, or target order cancels queued burst rounds before another shot.
- `DroneSquadState` tracks active/destroyed drone IDs, current tactical mode, squad fire discipline, current follow distance, and Operator/order-point anchor state.

## V2 Runtime Additions

- `drone_toggle_fire` defaults to `T` and toggles every live drone between `FIRE AT WILL` and `HOLD FIRE`.
- `drone_cycle_follow_distance` defaults to `G` and cycles `CLOSE -> FAR -> FREE_ROAM -> CLOSE`.
- `time_shift` moved from `T` to `Y` to avoid input-map drift.
- `DroneManager` propagates tactical mode, fire discipline, and follow distance to existing live drones and to future spawned drones.
- `CombatDrone.set_fire_at_will(false)` clears queued burst state immediately.
- `CombatDrone` resolves `CLOSE` and `FAR` as soft follow bands with Operator/drone separation instead of exact orbit offsets.
- `FREE_ROAM` periodically chooses deterministic local patrol goals around the Operator, pressures enemies inside `free_roam_engage_range`, and remains leashed by `free_roam_leash_range`.

## V3 Runtime Additions

- `drone_issue_guard_order` defaults to `J`; holding it while pressing primary/mouse-left stores the pointer world position as the squad order anchor.
- `drone_recall_order` defaults to `K` and restores the Operator anchor.
- `DroneManager` propagates guard placement/recall to live drones, applies active guard state to replacement drones, and owns the world-space guard marker.
- `CombatDrone._get_anchor_position()` is the single formation/retreat/intercept/patrol anchor resolver.
- `CLOSE`, `FAR`, and `FREE_ROAM` use the same movement contracts around either the Operator or guard point.
- Guard targeting uses `guard_order_engage_range`; exceeding `guard_order_return_range` clears targets and forces formation return, bounded by `guard_order_leash_range`.
- `AlliedInfantryDroid` status text reports `FOLLOW CLOSE/FAR/ROAM` or `GUARD CLOSE/FAR/ROAM`, followed by fire discipline.
- Operator primary fire is suppressed while the guard-order chord is held so a command click does not consume ammunition.
- During the guard-order chord, `DroneManager` resolves the nearest valid hostile under the pointer. The HUD reads this presentation state to place the command reticle over that hostile and tint it red. Clicking propagates the hostile as an explicit command target and anchors the squad at its position; an empty-ground click preserves ordinary guard placement.
- `CombatDrone` prioritizes the explicit command target without bypassing guard engage/return/leash constraints. Ground orders and recall clear it.
- `drone_id` is a manager-scoped squad slot label, not a save-stable creature identity. Destroyed slots remain in the squad summary and may be reused by a replacement.

## Integration

`custodian/scenes/game.tscn` references the animated allied infantry droid scene and manager script. The manager uses `../Operator` as its default anchor, defaults to two active droids, and owns the squad-wide fire, formation, guard-order, and recall actions.

## Validation

Run:

```bash
cd custodian
godot --headless --quit
godot --headless --script res://tools/validation/drone_follower_commands_smoke.gd
godot --headless --script res://tools/validation/main_scene_allied_droid_smoke.gd
godot --headless --script res://tools/validation/commanded_ally_targeting_contract_smoke.gd
rg "KEY_T|toggle_key|_toggle_combat_mode|set_input_as_handled" game/actors/allies game/systems/drone
```

The focused commanded-ally contract smoke is also registered as
`commanded_ally_targeting_contract` in `validation_manifest.json`.

Known deferred work remains in `design/02_features/vehicles/AUTONOMOUS_COMBAT_DRONES.md` and is summarized by `design/02_features/combat_feel/COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md`.
