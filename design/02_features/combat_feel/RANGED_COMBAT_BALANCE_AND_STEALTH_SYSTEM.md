# RANGED COMBAT BALANCE AND STEALTH SYSTEM

Status: implemented V1; tuning in progress  
Owner: gameplay/combat + enemy behavior  
Runtime target: Godot 4 (`custodian/`)  
Authority brief: `design/COMBAT_BALANCE.md`

## Purpose

Keep ranged weapons strong in deliberate bursts without allowing unlimited screen-clearing. The runtime combines finite carried ammunition, range and accuracy pressure, per-weapon heat, positional gunshot noise, sight/hearing perception, loss-of-contact search, and hostile ambient camps. Ammo is strategic scarcity; heat is immediate firing pressure; noise creates world consequences.

## Implemented In This Pass

- Ammo is stored by canonical type (`kinetic_light`, `kinetic_heavy`, `energy_cell`, `shell`, `scrap_charge`) with the legacy `kinetic` alias normalized to `kinetic_light`.
- Reserve and loaded state are separate. Loaded ammo is keyed by weapon ID, so weapon swaps do not refill magazines. Legacy standard/heavy fields and HUD keys remain adapter outputs.
- The active baseline is 72 light and 16 heavy reserve capacity. The carbine starts with a 24-round magazine and 48 reserve; the P-9 uses a 10-round magazine and shares the capped light-ammo pool.
- Ammo caches use tunable type/amount ranges and clamp through `Operator.add_ammo_type`. Main-scene caches and supply drops are substantially smaller.
- Projectiles track distance, apply weapon-owned linear damage falloff, and expire at max range.
- Standing, walking, sprinting, and sneaking apply weapon-data spread multipliers. Heat further scales spread and recoil.
- Heat is runtime state keyed by weapon ID, never shared `.tres` state. Shots add heat; cooling waits for a delay; overheat locks firing, cools faster, and releases at no more than 70% heat.
- `NoiseEventBus` is a generic autoload. Gunshots emit one event per trigger pull, including muzzle-obstructed shots. Suppression scales radius but never makes a shot silent.
- Operator stealth snapshots include sneak, sprint, firing, dodge, velocity, visibility, and movement-noise state. Gunshots use events rather than the ambient snapshot.
- Existing enemy perception retains raycast LOS and now consumes noise events. Enemies investigate the event position rather than receiving permanent knowledge of the Operator.
- Existing enemy behavior now tracks last seen/heard positions, pursuit memory, deterministic search offsets, home position, camp ID, and a leash. Hard leash applies after LOS is broken.
- `AmbientEnemyCamp` supports authored activation-limited camps; `AmbientEnemySpawner` supports procgen/authored marker groups. The main test scene contains two hostile grunt camps outside wave spawning.
- `get_weapon_status()` exposes canonical ammo, heat, overheat, noise, suppression, range values, and whether a ranged magazine is currently active while retaining legacy keys.
- `get_weapon_status()` also exposes reload/overheat progress, warning and overheat thresholds, decay delay, effective heat-per-shot, shots-to-overheat, and weapon-independent heat bands. Discrete `weapon_feedback_event` transitions drive presentation without polling sticky failure state.
- The compact HUD preserves magazine/reserve counts and adds one priority-driven pressure row for heat, hot/critical, reload, dry, and vent recovery. A child `WeaponFeedbackPresenter` owns local-only dry/reload/heat audio, critical tint, and procedural barrel vent VFX; none of these cues emit `NoiseEventBus` events.
- Primary/two-handed ranged-ready uses a composition split instead of baked ranged locomotion requirements. While moving, the lower body may remain movement-owned on reusable `unarmed_{idle,walk,run}` clips only when its direction stays within 100 degrees of the aim-owned upper body. At stationary speed (`velocity.length_squared() <= 16.0`) or beyond that twist limit, the lower body resolves from the upper-body aim direction so a stopped Operator cannot retain a stale locomotion facing. The upper body owns the modular ranged animation clock; the weapon layer is normalized-frame-slaved to it, and muzzle FX is action/frame-owned. The legacy full-body ranged sprite only appears when the modular ranged upper/weapon stack is unavailable. Accepted primary ranged shots can still play modular upper/weapon/FX fire layers when matching clips exist, with projectile emission, ammo, heat, range/falloff, and noise authority unchanged.

### Modular ranged pose and clock contract

- `upper body`: authoritative aim direction and animation clock.
- `weapon`: uses the upper body's normalized frame position every presentation tick; it must not advance on an independent clock.
- `muzzle FX`: starts from the accepted fire event and follows the authored fire frame contract.
- `lower body`: independently follows movement only while actually moving and within the allowed torso/leg twist; otherwise it follows the upper body.
- Directional socket layout is absolute. Runtime layout must assign from authored base/socket data and may not accumulate offsets with `+=`.
- Leaving ranged-ready resets retained rotation, scale, and modulation, then recomputes the absolute socket layout.

## Phase Mapping

1. Ammo economy: typed reserve caps, persistent magazines, smaller pickups and drops.
2. Range/accuracy: max range, falloff, movement and heat spread.
3. Heat: per-weapon accumulation, delayed decay, overheat lockout.
4. Noise: generic event resource and autoload bus.
5. Stealth: stable Operator snapshot; no cover/light simulation yet.
6. Perception: ray LOS plus event hearing through the existing component.
7. Ambient placement: authored camps and marker-driven spawner bridge.
8. Noise integration: distance/threat response without global aggro.
9. Pursuit: last-known search, LOS loss, and return-home leash.
10. Status/feedback: canonical progress snapshot, debounced transition events, production compact pressure HUD, local audio, and procedural vent VFX.
11. Vehicle hook: contract documented below; runtime deferred.
12. Tuning: initial carbine, pistol, shotgun, sniper, and minigun data applied.
13. Validation: focused smoke plus headless parse/runtime checks.
14. Documentation: this spec and the active AI context are canonicalized to live paths.

## Runtime Files

- `custodian/game/actors/operator/operator.gd`
- `custodian/tools/validation/operator_primary_ranged_modular_fire_smoke.gd`
- `custodian/game/actors/operator/operator_weapon_definition.gd`
- `custodian/game/actors/operator/components/weapon_feedback_presenter.gd`
- `custodian/game/ui/hud/custodian_hud.gd`
- `custodian/game/vfx/weapons/weapon_overheat_vent_vfx.tscn`
- `custodian/game/actors/projectiles/bullet.gd`
- `custodian/content/weapons/weapon_schema.json`
- `custodian/content/weapons/data/*.json`
- `custodian/game/systems/stealth/noise_event.gd`
- `custodian/game/systems/stealth/noise_event_bus.gd`
- `custodian/game/actors/enemies/components/enemy_perception_component.gd`
- `custodian/game/actors/enemies/components/enemy_blackboard.gd`
- `custodian/game/actors/enemies/enemy_behavior_state_machine.gd`
- `custodian/game/systems/spawning/ambient_enemy_camp.gd`
- `custodian/game/systems/spawning/ambient_enemy_spawner.gd`
- `custodian/game/actors/items/ammo_cache.gd`
- `custodian/scenes/game.tscn`
- `custodian/tools/validation/combat_resource_feedback_smoke.gd`

The original brief's `custodian/assets/weapons/` path is stale. Live weapon data is under `custodian/content/weapons/`.

## Tuning Baseline

| Weapon | Magazine / reserve cap | Effective / max range | Heat per shot / decay | Noise radius |
|---|---:|---:|---:|---:|
| P-9 sidearm | 10 / 60 shared light pool | 110 / 220 | 8 / 34 | 260 |
| VX-3 carbine | 24 / 72 | 180 / 320 | 11 / 26 | 420 |
| Shotgun | 6 / 16 shells | 90 / 180 | 24 / 24 | 480 |
| Sniper | 5 / 12 heavy | 360 / 520 | 55 / 18 | 620 |
| Minigun | 72 / 96 light | 160 / 300 | 5 / 14 | 560 |

## Validation

- `env HOME=/tmp/custodian-godot-home godot --headless --script tools/validation/ranged_combat_balance_smoke.gd`
- `env HOME=/tmp/custodian-godot-home godot --headless --script tools/validation/combat_resource_feedback_smoke.gd`
- `env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/operator_primary_ranged_modular_fire_smoke.gd`
- `env HOME=/tmp/custodian-godot-home godot --headless --path . --editor --quit`
- The modular-primary smoke covers the south-move/east-aim stop regression and asserts upper/weapon normalized-frame agreement across 120 presentation ticks.
- Main-scene headless boot reaches generated-world initialization without new script parse/load or missing-animation errors; existing shutdown leak diagnostics remain non-fatal test-harness noise.
- Manual acceptance still required for feel: burst-to-overheat cadence, visible spread/recoil, camp investigation, corner LOS break/search/return, reload and sidearm switching, and melee/parry/dodge regression.

## Future: Vehicle-Mounted Weapon Firing

A future `VehicleWeaponDefinition` should own `weapon_id`, weapon data path, mount socket, fire arc, heat state, ammo source, noise radius, recoil/knockback, and occupant requirement. When an occupied vehicle owns an active weapon, primary fire routes to the vehicle before personal weapon logic. Vehicle ammo, heat, and noise belong to the mount; personal firing is disabled unless the vehicle explicitly supports firing ports. Vehicle weapons reuse `NoiseEventBus` and the heat schema, with a starting noise target of 700 px for light guns and 1000 px for heavy guns. No partial vehicle-fire hook is implemented in V1 because current occupant/input ownership does not expose a complete mount contract.

## Deferred

- Manual cue-mix/cadence review, bespoke P-9 reload/heat replacements, optional authored vent sprite strip, and optional pressure-state HUD icons
- Suppressor item/mod inventory
- Cover and lighting visibility modifiers
- Large-scale procedural enemy bases and streaming/pooling
- Advanced squad coordination and sector alarm networks
- Vehicle-mounted weapon firing

## Next Agent Slice

Goal: tune the completed feedback slice in play and replace shared V1 cues without changing its event/status contract.
Files: weapon feedback presenter, compact HUD, weapon JSON/audio, and optional vent/icon assets.
Constraints: do not move simulation authority into UI; retain deterministic search/spawn decisions; preserve canonical ammo adapters until all HUD consumers migrate.
Acceptance: manual scenario from `design/COMBAT_BALANCE.md` passes, feedback remains readable without held-input chatter, and no pre-existing combat controls or AI hearing behavior regress.
