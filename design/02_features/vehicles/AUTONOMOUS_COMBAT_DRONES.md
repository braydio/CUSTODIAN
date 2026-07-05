# Autonomous Combat Drones

Status: complete-v2
Runtime target: Godot 4.x
Feature owner: combat / allied automation

## Summary

Autonomous combat drones are fragile player-assist companions. V2 mounts a `DroneManager` in the active scene and spawns up to two allied droid companions near the Custodian. The shared combat actor owns soft follow bands, local patrol/free-roam goals, local target acquisition, support bursts, HP, and destruction; the active main-scene presentation uses the animated allied infantry droid scene with squad-wide fire discipline and follow-distance commands owned by `DroneManager`.

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
- `custodian/project.godot`
- `custodian/tools/validation/drone_follower_commands_smoke.gd`

## V1 Tactical Modes

- `FOLLOW`: default orbit around the Custodian, attacks enemies near the Custodian.
- `HOLD`: stays near its current hold point but leashes back if the Custodian moves too far away.
- `INTERCEPT`: moves toward a standoff point between the Custodian and the nearest local enemy.
- `RECALL`: returns close to the Custodian and stops attacking.

## V2 Follower Commands

`DroneManager` is the only runtime input authority for squad follower commands. Individual droid instances must not poll raw keys or mark input handled.

- `drone_toggle_fire` defaults to `T`: toggles every live drone between `FIRE AT WILL` and `HOLD FIRE`.
- `drone_cycle_follow_distance` defaults to `G`: cycles every live drone through `CLOSE`, `FAR`, and `FREE_ROAM`.
- `time_shift` moved from `T` to `Y` so drone fire discipline has an explicit InputMap action and no raw key bypass.
- Newly spawned drones inherit the current squad fire discipline and follow distance.
- Hold fire clears queued bursts immediately through `CombatDrone.set_fire_at_will(false)`.

Follow distances are movement contracts, not exact orbit offsets:

- `CLOSE`: bodyguard escort band near the Operator, with player separation so drones do not stand inside the Operator's feet.
- `FAR`: backline/support band that trails or stands off visibly farther than `CLOSE`.
- `FREE_ROAM`: local patrol around the Operator. The drone periodically selects deterministic roam goals within the Operator leash, pressures local enemies, and returns to the leash if separated. It is not independent scouting.

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
- Close follow preferred radius: `72`
- Close follow band: `56-118`
- Far follow preferred radius: `190`
- Far follow band: `145-285`
- Player separation radius: `54`
- Drone separation radius: `36`
- Free-roam patrol band: `180-380`
- Free-roam repath window: `1.2-2.4s`
- Free-roam leash: `520`
- Free-roam engage range: `420`

## Deferred

- Full production allied-droid/mech audio and expanded directional animation coverage.
- Dedicated terminal command UI for drone modes.
- Fabricator/drone bay reserve deployment.
- Repair or redeploy during combat.
- Debug overlay.
- Richer line-of-sight and sensor-gated targeting.
