# Autonomous Combat Drones Implementation Notes

Status: implemented-v1

## Runtime Additions

- `CombatDrone` is a `CharacterBody2D` allied actor with placeholder `ColorRect` visual, health bar, collision, and muzzle marker.
- `DroneManager` is scene-mounted under `GameRoot/World` and spawns two drones into `GameRoot/World/Allies`.
- `DroneCommandProfile` centralizes V1 tuning and mode constants.
- `DroneTargeting` performs deterministic nearest-target selection against non-passive enemies.
- `DroneSquadState` tracks active/destroyed drone IDs and current squad mode.

## Integration

`custodian/scenes/game.tscn` now references the drone scene and manager script. The manager uses `../Operator` as its anchor and defaults to two active drones.

## Validation

Run:

```bash
cd custodian
godot --headless --quit
```

Known deferred work remains in `design/02_features/vehicles/AUTONOMOUS_COMBAT_DRONES.md` and is summarized by `design/02_features/combat_feel/COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md`.
