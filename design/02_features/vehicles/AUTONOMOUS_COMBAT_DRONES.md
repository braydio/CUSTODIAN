# Autonomous Combat Drones

Status: complete-v3
Runtime target: Godot 4.x
Feature owner: combat / allied automation

## Summary

Autonomous combat drones are fragile player-assist companions. V3 mounts a `DroneManager` in the active scene, spawns up to two allied droid companions near the Custodian, and supports an Operator or ordered guard-point anchor. The shared combat actor owns soft follow bands, local patrol/free-roam goals, guard-zone target acquisition and return rules, support bursts, HP, and destruction; the active main-scene presentation uses the animated allied infantry droid scene with squad-wide fire discipline, anchor, and follow-distance commands owned by `DroneManager`.

## Doctrine Rules

- Drones assist field combat; they do not replace the Custodian's positioning, target choice, repair decisions, or command authority.
- Drones do not route power, reveal hidden enemy data, pre-clear rooms, coordinate sectors, or pursue enemies outside the Custodian's local fight.
- Drones are disposable hardware: they have independent HP and do not respawn in V1.

## Runtime Files

- `custodian/game/actors/allies/combat_drone.gd`
- `custodian/game/actors/allies/combat_drone.tscn`
- `custodian/game/actors/allies/allied_infantry_droid.gd`
- `custodian/game/actors/allies/allied_infantry_droid.tscn`
- `custodian/game/actors/effects/drone_guard_order_marker.tscn`
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

## V3 Guard Anchor Orders

Anchor and formation are separate command axes:

- `FOLLOW`: the active anchor is the Operator.
- `GUARD`: the active anchor is a clicked world position.
- `CLOSE`, `FAR`, and `FREE_ROAM` remain the formation behavior around whichever anchor is active.
- Recall clears the ordered point and restores the Operator anchor without replacing fire discipline or follow-distance state.

Controls:

- Hold `drone_issue_guard_order` (`J`) and press primary/mouse-left to place or move the guard anchor.
- Press `drone_recall_order` (`K`) to clear the guard anchor.
- `G` continues to cycle close/far/free-roam around the active anchor.
- The Operator suppresses primary weapon fire while the guard-order chord is held.

Guard interpretation:

- `GUARD CLOSE`: hold close slot offsets around the ordered point.
- `GUARD FAR`: hold the wider perimeter band around the ordered point.
- `GUARD ROAM`: patrol deterministic local goals around the ordered point.
- Target selection is centered on the guard anchor.
- Enemies outside the guard engage range are ignored.
- Drones outside the guard return range clear targets and return to formation.
- Guard patrol is local defense, not independent room clearing or scouting.
- A small world-space ring/cross marker identifies the active guard point.

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
- Guard order engage range: `420`
- Guard order return range: `460`
- Guard order leash: `520`

## Deferred

- Full production allied-droid/mech audio and expanded directional animation coverage.
- Dedicated terminal command UI for drone modes.
- Fabricator/drone bay reserve deployment.
- Repair or redeploy during combat.
- Debug overlay.
- Richer line-of-sight and sensor-gated targeting.

## Next Agent Slice

Goal: add production command acknowledgement audio and optional command-path pulse without changing anchor or targeting authority.

Files:

- `custodian/game/systems/drone/drone_manager.gd`
- `custodian/game/actors/effects/drone_guard_order_marker.*`
- `custodian/game/actors/allies/allied_infantry_droid.gd`

Constraints:

- Keep `DroneManager` as the only raw input authority.
- Keep guard orders as an anchor override, not a new tactical-mode matrix.
- Do not expand guard patrol into autonomous scouting.

Acceptance:

- Guard and recall produce one concise acknowledgement.
- Feedback remains non-blocking and does not alter movement, targeting, or fire discipline.
