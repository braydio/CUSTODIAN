This file contains the Codex-ready implementation spec.

Grounding: active runtime is Godot under custodian/, new Godot specs belong in ./design/, and runtime changes should update design docs first. ￼ The existing doctrine also says automation is powerful but dumb, sector-scoped, and should not replace the Custodian’s tactical agency. ￼

# CUSTODIAN Feature Spec: Autonomous Combat Drones

Status: deprecated planning prompt; V1 authority moved
Runtime target: Godot 4.x
Feature owner: combat / allied automation
Primary goal: add player-assist combat drones that are effective, fragile, deterministic, and doctrine-compatible.

> Runtime V1 is complete. Use `design/02_features/vehicles/AUTONOMOUS_COMBAT_DRONES.md` for the durable feature authority and `design/02_features/combat_feel/COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md` for pending battery, repair, presentation, and redeployment integration. Paths below are retained as historical planning text and must not override those documents.

## 0. Codex Task

Implement autonomous combat drones that assist the Custodian in field combat.
Do not make them invincible.
Do not make them smarter than the player.
Do not let them replace Command Center authority, power routing, or sector autopilot.
Create/update:

- design/02_features/vehicles/AUTONOMOUS_COMBAT_DRONES.md
- - design/02_features/vehicles/AUTONOMOUS_COMBAT_DRONES_CODE.md
- - custodian/game/actors/allies/combat_drone.gd
- - custodian/game/actors/allies/combat_drone.tscn
- - custodian/game/systems/drone/drone_manager.gd
- - custodian/game/systems/drone/drone_command_profile.gd
- - custodian/game/systems/drone/drone_targeting.gd
- - custodian/game/systems/drone/drone_squad_state.gd
- - custodian/game/debug/drone_debug_overlay.gd, optional
- - update custodian/docs/ai_context/CURRENT_STATE.md
- - update custodian/docs/ai_context/FILE_INDEX.md if present
- Use placeholder visuals only unless production assets already exist.
- ## 1. Design Intent
- Autonomous combat drones are mobile auxiliary companions. They are closer to disposable doctrine hardware than pets.
- They should feel like:
- - a tactical force multiplier
- - a mobile second weapon system
- - an emergency stabilizer when the player is pressured
- - a fragile asset the player must not ignore
- They must not feel like:
- - a permanent win button
- - immortal turret satellites
- - independently competent squadmates
- - a replacement for the Custodian’s positioning, targeting, and repair decisions
- ## 2. Doctrine Constraints
- Existing design says:
- - the Custodian fights directly, repairs, deploys auxiliary defenses, triggers systems, and draws aggro
- - automation is reliable but dumb
- - autopilot is sector-scoped and has no prediction, no delayed activation, no target prioritization, no pursuit
- - Command Center gives superior tactical control
- - field play is intentionally lower-information and higher-risk
- Therefore drones may:
- - follow the Custodian
- - attack visible enemies near the Custodian
- - intercept enemies targeting the Custodian
- - briefly hold pressure while the player repairs or repositions
- - be commanded into simple modes
- Drones may not:
- - route power
- - globally coordinate sectors
- - reveal exact enemy data unless Command Center/sensor systems already allow it
- - independently solve objectives
- - pursue enemies across sectors without the Custodian
- - pre-clear rooms ahead of the player
- - survive endless focus fire
- ## 3. Runtime Behavior
- ### 3.1 Drone Squad Limits
- Default v1:
- - max active drones: 2
- - max reserve drones: 0 unless a drone bay/fabricator feature exists
- - each drone has independent HP
- - drones can be destroyed
- - destroyed drones do not respawn during combat unless explicitly repaired/redeployed later
- Recommended v1 tuning:
- - drone_hp = 45
- - drone_speed = 170
- - drone_acceleration = 850
- - drone_engage_range = 280
- - drone_weapon_range = 220
- - drone_damage = 8
- - drone_fire_cooldown = 0.55
- - drone_burst_size = 2
- - drone_burst_gap = 0.09
- - drone_retreat_hp_threshold = 0.28
- - drone_repair_rate_when_near_custodian = 0 only for v1
- - drone_collision_radius = 8
- Combat effectiveness target:
- - two drones together should roughly equal 70–90% of the Custodian’s sustained ranged pressure
- - drones should lose to concentrated enemy fire
- - drones should struggle against shielded, armored, or fast melee enemies unless the player supports them
- ### 3.2 Modes
- Implement four modes.
- #### FOLLOW
- Default mode.
- - Maintain orbit offsets around Custodian.
- - Attack enemies only if they are within drone_engage_range of Custodia4AI Assistant is to write this file to a persistent home in /design/ for tracking and reference.
