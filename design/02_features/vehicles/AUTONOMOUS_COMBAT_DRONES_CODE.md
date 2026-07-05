# Autonomous Combat Drones Implementation Notes

Status: implemented-v2

## Runtime Additions

- `CombatDrone` is a `CharacterBody2D` allied actor with movement, targeting, firing, health, collision, and muzzle logic.
- `AlliedInfantryDroid` subclasses `CombatDrone`, replaces the placeholder `ColorRect` with `AnimatedSprite2D` playback, and displays a small fire/follow status label. It no longer owns raw input.
- `DroneManager` is scene-mounted under `GameRoot/World`, spawns two drones into `GameRoot/World/Allies`, and owns squad command input.
- `DroneCommandProfile` centralizes V1 tuning, tactical mode constants, V2 follow-distance band tuning, separation, and free-roam patrol timing.
- `DroneTargeting` performs deterministic nearest-target selection against non-passive enemies with an optional range override for free roam.
- `DroneSquadState` tracks active/destroyed drone IDs, current tactical mode, squad fire discipline, and current follow distance.

## V2 Runtime Additions

- `drone_toggle_fire` defaults to `T` and toggles every live drone between `FIRE AT WILL` and `HOLD FIRE`.
- `drone_cycle_follow_distance` defaults to `G` and cycles `CLOSE -> FAR -> FREE_ROAM -> CLOSE`.
- `time_shift` moved from `T` to `Y` to avoid input-map drift.
- `DroneManager` propagates tactical mode, fire discipline, and follow distance to existing live drones and to future spawned drones.
- `CombatDrone.set_fire_at_will(false)` clears queued burst state immediately.
- `CombatDrone` resolves `CLOSE` and `FAR` as soft follow bands with Operator/drone separation instead of exact orbit offsets.
- `FREE_ROAM` periodically chooses deterministic local patrol goals around the Operator, pressures enemies inside `free_roam_engage_range`, and remains leashed by `free_roam_leash_range`.

## Integration

`custodian/scenes/game.tscn` references the animated allied infantry droid scene and manager script. The manager uses `../Operator` as its anchor, defaults to two active droids, and owns the squad-wide follower command actions.

## Validation

Run:

```bash
cd custodian
godot --headless --quit
godot --headless --script res://tools/validation/drone_follower_commands_smoke.gd
godot --headless --script res://tools/validation/main_scene_allied_droid_smoke.gd
rg "KEY_T|toggle_key|_toggle_combat_mode|set_input_as_handled" game/actors/allies game/systems/drone
```

Known deferred work remains in `design/02_features/vehicles/AUTONOMOUS_COMBAT_DRONES.md` and is summarized by `design/02_features/combat_feel/COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md`.
