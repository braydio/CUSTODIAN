# Autonomous Combat Drones

Status: complete-v1
Runtime target: Godot 4.x
Feature owner: combat / allied automation

## Summary

Autonomous combat drones are fragile player-assist companions. V1 mounts a `DroneManager` in the active scene and spawns up to two allied droid companions near the Custodian. The shared combat actor owns follow/orbit, local target acquisition, support bursts, HP, and destruction; the active main-scene presentation uses the animated allied infantry droid scene with `T` fire-at-will / hold-fire toggling.

## Doctrine Rules

- Drones assist field combat; they do not replace the Custodian's positioning, target choice, repair decisions, or command authority.
- Drones do not route power, reveal hidden enemy data, pre-clear rooms, coordinate sectors, or pursue enemies outside the Custodian's local fight.
- Drones are disposable hardware: they have independent HP and do not respawn in V1.

## Runtime Files

- `custodian/game/actors/allies/combat_drone.gd`
- `custodian/game/actors/allies/combat_drone.tscn`
- `custodian/game/actors/allies/allied_infantry_droid.gd`
- `custodian/game/actors/allies/allied_infantry_droid.tscn`
- `custodian/game/systems/drone/drone_manager.gd`
- `custodian/game/systems/drone/drone_command_profile.gd`
- `custodian/game/systems/drone/drone_targeting.gd`
- `custodian/game/systems/drone/drone_squad_state.gd`
- `custodian/scenes/game.tscn`

## V1 Modes

- `FOLLOW`: default orbit around the Custodian, attacks enemies near the Custodian.
- `HOLD`: stays near its current hold point but leashes back if the Custodian moves too far away.
- `INTERCEPT`: moves toward a standoff point between the Custodian and the nearest local enemy.
- `RECALL`: returns close to the Custodian and stops attacking.

## V1 Tuning

- Max active drones: `2`
- HP: `45`
- Speed: `170`
- Acceleration: `850`
- Engage range: `280`
- Weapon range: `220`
- Damage: `8`
- Fire cooldown: `0.55`
- Burst size: `2`
- Burst gap: `0.09`
- Retreat threshold: `28%`
- Collision radius: `8`

## Deferred

- Full production allied-droid/mech audio and expanded directional animation coverage.
- Dedicated terminal command UI for drone modes.
- Fabricator/drone bay reserve deployment.
- Repair or redeploy during combat.
- Debug overlay.
- Richer line-of-sight and sensor-gated targeting.
