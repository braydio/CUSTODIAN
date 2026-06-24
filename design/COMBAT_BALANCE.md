I checked the live GitHub repo rather than relying only on the older Drive context, because your project note says GitHub may be fresher. The repo is available as braydio/CUSTODIAN on main . I also found a documentation drift issue: AGENTS.md says active Godot specs live under design/20_features/in_progress, but the current combat/weapon docs I found are under design/02_features/...; Codex should either normalize that or explicitly update AGENTS.md so future agents stop guessing paths . Current weapon runtime state is already partly data-driven: OperatorWeaponDefinition has stats, ammo, magazine, reload, range, recoil, etc. , WeaponDefinitionFactory loads those from JSON , and operator.gd already has stealth snapshot fields plus primitive firing noise values .

Here’s the Codex-ready implementation brief. Copy/paste this as the task.

CUSTODIAN — Ranged Combat Nerf, Heat, Ammo Economy, Noise/Stealth, Ambient Enemy Roadmap

Task Summary

Implement a cohesive ranged-combat rebalance pass for CUSTODIAN’s Godot runtime. Ranged combat is currently too dominant because ammo is too abundant, firing has no sustained-use penalty beyond cooldown/reload, ranged pressure does not meaningfully attract or alert enemies, and there are not enough ambient world enemies for gunfire noise to matter.

This implementation must make ranged combat strong but situational:

- Guns should win bursts, not entire encounters by default.
- Ammo should be finite and carried deliberately.
- Weapon heat should punish constant spam and reward controlled fire.
- Gunfire should create world noise that attracts nearby enemies.
- Sneaking should be meaningful once ambient enemies exist.
- Ambient enemies should exist outside wave spawns.
- Enemy perception should use line of sight, hearing, investigation, pursuit, and loss-of-contact behavior.
- Vehicle-mounted weapon firing should be documented as a future extension, not fully implemented in this pass unless the existing vehicle system already supports it cleanly.

Proceed through all phases in order. Do not stop after the first phase. Each phase depends on the prior phase, and the implementation should leave the project in a playable, debuggable state after the full run.

⸻

Current Runtime Facts To Respect

Use the active Godot runtime under:

custodian/

Important current files likely involved:

custodian/game/actors/operator/operator.gd
custodian/game/actors/operator/operator_weapon_definition.gd
custodian/game/systems/core/systems/weapon_definition_factory.gd
custodian/assets/weapons/data/\*.json
custodian/assets/weapons/registry.json
custodian/game/actors/projectiles/bullet.tscn
custodian/game/actors/projectiles/bullet.gd
custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/CONTEXT.md
custodian/docs/ai_context/FILE_INDEX.md
design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md
design/02_features/weapon_data/implementation.md

Search the repo first, because exact enemy/wave/procgen paths may have moved:

rg -n "class_name .\*Enemy|enemy|enemies|wave|spawner|spawn|perception|blackboard|stealth|noise|line_of_sight|sight|pursuit|bullet|projectile|ammo|ranged|weapon" custodian design

Suggested Repomix context collection before edits:

repomix \
 --include "AGENTS.md,design/**/_.md,custodian/docs/ai_context/_.md,custodian/game/actors/operator/operator.gd,custodian/game/actors/operator/operator_weapon_definition.gd,custodian/game/systems/core/systems/weapon_definition_factory.gd,custodian/assets/weapons/**/_.json,custodian/game/actors/\*\*/_.gd,custodian/game/systems/**/\*.gd,custodian/game/world/**/_.gd,custodian/tools/validation/\*\*/_.gd" \
 --output /tmp/custodian-ranged-nerf-context.md

If this repo’s Repomix CLI uses different flag names, adapt the command but collect the same file set.

⸻

Phase 0 — Documentation Drift And Source-Of-Truth Cleanup

Goal

Before changing runtime behavior, fix or explicitly document the mismatch between old path references and current repo layout.

Work

1. Inspect AGENTS.md.
2. Inspect current design docs under design/.
3. Confirm whether active feature docs live under:
   - design/20_features/in_progress/
   - design/02_features/
   - both
4. Update docs so future agents know the real current layout.

Required doc changes

Create or update a new feature spec:

design/02_features/combat_feel/RANGED_COMBAT_BALANCE_AND_STEALTH_SYSTEM.md

If the repo has standardized on another active docs folder, use that folder instead, but also update the AI context docs with the actual chosen location.

The doc must include:

- Status: in progress
- Runtime target: Godot 4, custodian/
- Purpose
- Current implementation summary
- Phase breakdown
- Runtime files touched
- Tuning constants
- Validation checklist
- Future vehicle-mounted weapon section

Also update:

custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/FILE_INDEX.md

Update CONTEXT.md too if architecture ownership changes.

Acceptance

- A future agent can tell where the ranged balance system lives.
- The doc does not point to dead custodian/entities/... paths if current files are under custodian/game/....
- The doc explicitly says vehicle-mounted weapons are deferred unless existing vehicle architecture makes a small hook obvious.

⸻

Phase 1 — Ammo Economy Baseline

Design Intent

Ammo should not “fall from the sky.” The player should carry limited ammunition, reload from reserve, and scavenge small caches that are valuable but not spam-feeding.

Do both forms of nerf:

1. Cap how much the player can carry.
2. Reduce and control how much ammo the game gives out.

This is better than only one approach. If only pickups are limited, a stocked player can still trivialize early combat. If only carry capacity is limited but pickups remain everywhere, the player just tops up constantly. The correct design is a small carried reserve plus scarcer pickups.

Runtime Model

Replace loose “standard/heavy ammo everywhere” thinking with an explicit carried ammo model:

Ammo Type:

- kinetic_light
- kinetic_heavy
- energy_cell
- shell
- scrap_charge

For this pass, do not overbuild every ammo type unless weapon data already supports it. Implement the framework with current weapons mapped into a small practical set.

Minimum required active types:

kinetic_light
kinetic_heavy

If current weapon JSON already uses "kinetic", support it as an alias for kinetic_light.

Carry Capacity

Add capacity per ammo type. Suggested starting values:

kinetic_light:
base_capacity: 72
max_capacity: 96
kinetic_heavy:
base_capacity: 12
max_capacity: 24
energy_cell:
base_capacity: 40
max_capacity: 80
shell:
base_capacity: 16
max_capacity: 32

For current gameplay, this means:

- Carbine magazine around 24–28.
- Reserve roughly 2–3 magazines, not 8–10.
- Heavy/sniper ammo should be scarce.

Do not start the player with 120–240 loose standard ammo unless that is a debug-only override.

Implementation Details

Operator weapon definition

Extend OperatorWeaponDefinition with carry/ammo tuning fields if not already present:

@export_group("Ammo Economy")
@export var ammo_type: String = "kinetic_light"
@export var magazine_size: int = 24
@export var reserve_ammo: int = 48
@export var max_reserve_ammo: int = 72
@export var ammo_per_shot: int = 1
@export var reload_style: String = "magazine"

Current file already has many of these fields. Keep backwards compatibility, but do not let old defaults silently create giant ammo pools.

Weapon JSON

Extend each ranged weapon JSON to support:

"ammo": {
"ammo_type": "kinetic_light",
"magazine_size": 24,
"starting_reserve": 48,
"max_reserve": 72,
"ammo_per_shot": 1,
"pickup_weight": 1.0,
"reload_style": "magazine"
}

If current JSON has:

"ammo": {
"ammo_type": "kinetic",
"capacity": 28,
"reserve": 112
}

then map it as:

ammo_type = kinetic_light
magazine_size = capacity or stats.magazine_size
starting_reserve = clamp(reserve, 0, max_reserve)
max_reserve = explicit max_reserve or weapon default

Operator ammo state

Current operator.gd has global fields like:

ammo_standard
ammo_heavy
ammo_standard_max
ammo_heavy_max
\_ammo_standard_loaded
\_ammo_heavy_loaded

Refactor carefully. Avoid breaking UI immediately. Use a small adapter layer:

var ammo_reserve_by_type: Dictionary = {}
var ammo_capacity_by_type: Dictionary = {}
var loaded_ammo_by_weapon_id: Dictionary = {}

Then keep current UI methods working by reading from the active weapon:

func \_get_current_loaded_ammo() -> int
func \_get_current_reserve_ammo() -> int
func \_get_current_magazine_size() -> int
func add_ammo(...)
func get_weapon_status() -> Dictionary

Do not scatter direct ammo_standard reads deeper into new code. Route through accessors.

Reload behavior

Reload should:

- Check active weapon ammo type.
- Check active weapon ammo_per_shot.
- Transfer from reserve into magazine.
- Clamp reserve to capacity.
- Preserve loaded ammo per weapon if possible.

Do not refill every weapon for free on weapon swap.

Pickup behavior

Find existing ammo pickup/resource cache code. Update it so ammo pickups are not default large refills.

Create a data-driven pickup model:

@export var ammo_type: String = "kinetic_light"
@export var amount_min: int = 4
@export var amount_max: int = 12
@export var guaranteed: bool = false
@export var debug_refill: bool = false

Default pickup sizes:

small kinetic_light cache: 6–12
large kinetic_light cache: 16–24
heavy cache: 2–4
debug cache: full refill, clearly named/debug-only

If the current game is spawning ammo from enemy deaths or waves, reduce it:

- Common enemies: no guaranteed ammo.
- Armed enemies: 20–35% chance of tiny ammo.
- Cache/locker/field terminal: controlled larger refill.
- Tutorial: one guaranteed cache only if needed.

Acceptance

- Firing consumes loaded ammo.
- Reloading consumes reserve ammo.
- Pickups clamp to max carry capacity.
- The player cannot exceed capacity.
- Existing weapon UI still shows loaded/reserve values.
- Existing sidearm works with the same ammo framework.
- Ammo scarcity is tunable through JSON/pickup resources, not hardcoded throughout operator.gd.

⸻

Phase 2 — Ranged Range And Accuracy Nerf

Design Intent

Ranged should not delete the screen. The player should have to manage distance, movement, recoil, line of sight, and weapon role.

Changes

Weapon profiles should own effective range, not just bullet speed and damage.

Extend weapon stats:

"stats": {
"range_px": 240,
"effective_range_px": 180,
"max_range_px": 320,
"damage_falloff_start_px": 160,
"damage_falloff_end_px": 320,
"min_falloff_damage_mult": 0.45
}

If projectile code currently does not know distance traveled, add it to bullet.gd:

var max_range_px: float = 320.0
var falloff_start_px: float = 180.0
var falloff_end_px: float = 320.0
var min_damage_multiplier: float = 0.45
var \_spawn_position: Vector2
var \_distance_traveled: float = 0.0

On hit:

func get_scaled_damage() -> float:
if falloff_end_px <= falloff_start_px:
return damage
var t := clampf((\_distance_traveled - falloff_start_px) / (falloff_end_px - falloff_start_px), 0.0, 1.0)
return damage \* lerpf(1.0, min_damage_multiplier, t)

On movement:

- Track distance traveled.
- Destroy bullet at max_range_px.

Suggested Initial Tuning

Pistol:
effective range: 120
max range: 220
falloff min: 0.45
Carbine:
effective range: 180
max range: 320
falloff min: 0.50
Shotgun:
effective range: 90
max range: 180
falloff min: 0.30
high spread
Sniper:
effective range: 360
max range: 520
falloff min: 0.70
huge heat per shot
low reserve ammo

Movement accuracy

Use existing movement/sneaking/sprinting state:

- Sneaking or standing still: best accuracy.
- Walking while ranged-ready: moderate penalty.
- Sprinting: cannot ranged-ready or has huge penalty.
- Panic shot: high spread.

Add/access fields:

"handling": {
"standing_spread_mult": 0.85,
"walking_spread_mult": 1.35,
"sprinting_spread_mult": 2.25,
"panic_spread_mult": 1.8,
"sneak_spread_mult": 0.75
}

Do not make shooting feel random at close range. Spread should punish reckless range abuse, not make basic aiming feel broken.

Acceptance

- Bullets expire at weapon max range.
- Damage falls off over distance.
- Current range_px is respected or migrated into the new fields.
- Movement affects spread.
- Existing projectile/muzzle/impact visuals still work.

⸻

Phase 3 — Weapon Heat / Overheat System

Design Intent

Heat makes firing bursty. The player should be able to dump a short controlled burst, but repeated sustained fire causes heat buildup, degraded handling, and eventual overheat lockout.

Heat is not ammo. Heat is moment-to-moment pressure. Ammo is strategic scarcity.

Runtime Model

Each ranged weapon tracks heat.

Add to OperatorWeaponDefinition:

@export_group("Heat")
@export var heat_enabled: bool = true
@export var heat_max: float = 100.0
@export var heat_per_shot: float = 12.0
@export var heat_decay_per_sec: float = 28.0
@export var heat_decay_delay_sec: float = 0.25
@export var overheat_threshold: float = 100.0
@export var overheat_lockout_sec: float = 1.35
@export var heat_spread_mult_at_max: float = 1.7
@export var heat_recoil_mult_at_max: float = 1.4
@export var heat_ui_warn_threshold: float = 70.0
@export var current_heat: float = 0.0
@export var heat_decay_delay_timer: float = 0.0
@export var overheat_timer: float = 0.0

If runtime state should not live in the resource because the resource may be shared, use dictionaries in operator.gd keyed by weapon ID:

var weapon_heat_by_id: Dictionary = {}
var weapon_heat_delay_by_id: Dictionary = {}
var weapon_overheat_by_id: Dictionary = {}

Prefer dictionary state if .tres resources are shared between actors.

Weapon JSON

Add:

"heat": {
"enabled": true,
"max": 100,
"per_shot": 12,
"decay_per_sec": 28,
"decay_delay_sec": 0.25,
"overheat_threshold": 100,
"overheat_lockout_sec": 1.35,
"spread_mult_at_max": 1.7,
"recoil_mult_at_max": 1.4
}

Suggested tuning:

Pistol:
heat_per_shot: 8
decay_per_sec: 34
overheat_lockout: 0.8
Carbine:
heat_per_shot: 11
decay_per_sec: 26
overheat_lockout: 1.2
SMG:
heat_per_shot: 7
decay_per_sec: 22
high fire rate means fast buildup
Shotgun:
heat_per_shot: 24
decay_per_sec: 24
overheat_lockout: 1.25
Sniper:
heat_per_shot: 55
decay_per_sec: 18
overheat_lockout: 1.8
Minigun:
heat_per_shot: 5
decay_per_sec: 14
spin-up later; not required now

Firing checks

Before firing:

if \_is_active_weapon_overheated():
\_play_dry_or_overheat_feedback()
return

On each successful shot request or shot emission, choose one and be consistent:

Preferred: apply heat when the shot is actually emitted, not when queued.

\_apply_heat_for_shot(active_weapon, ammo_per_shot)

If the muzzle is obstructed and the gun still fires into a wall, apply heat and consume ammo. That is correct.

Heat effects before overheat

As heat rises:

- Spread increases.
- Recoil increases.
- Optional fire cooldown increases slightly after 80 heat.

Formula:

var heat_ratio := clampf(current_heat / heat_max, 0.0, 1.0)
spread _= lerpf(1.0, heat_spread_mult_at_max, heat_ratio)
recoil _= lerpf(1.0, heat_recoil_mult_at_max, heat_ratio)

Do not reduce damage due to heat in V1. Damage falloff already handles range.

Cooling

In \_process(delta):

- Update cooldowns as now.
- Update active/all weapon heat.
- Heat decay starts only after heat_decay_delay_sec since last shot.
- Overheat timer counts down.
- During overheat, weapon cannot fire but should cool aggressively or immediately drop below threshold after lockout.

Suggested behavior:

If overheated:
cannot fire
timer counts down
heat decays at 1.5x normal
once timer ends, heat is clamped to 60–75% of max

This prevents instant re-overheat on one frame.

Mods future-proofing

Do not implement full weapon mods unless they already exist. Add future-ready multipliers:

@export var heat_per_shot_mult: float = 1.0
@export var heat_decay_mult: float = 1.0
@export var overheat_lockout_mult: float = 1.0

Then later mods can do:

cooling fins:
heat_decay_mult +25%
overcharged barrel:
damage +15%
heat_per_shot +20%
heat sink:
heat_max +20%
movement penalty +5%

UI/debug

Extend get_weapon_status() to include:

"heat": current_heat,
"heat_max": heat_max,
"heat_ratio": heat_ratio,
"overheated": overheated,
"overheat_remaining": timer

Existing UI can ignore these until updated, but the data must be available.

Optional simple debug print only when state changes:

WEAPON OVERHEATED: CARBINE
WEAPON COOLED: CARBINE

Do not spam per frame.

Acceptance

- Ranged weapons build heat per shot.
- Heat decays after a short delay.
- High heat worsens spread/recoil.
- Overheated weapons cannot fire for a short lockout.
- Different weapons can tune heat differently through JSON.
- Weapon status exposes heat fields for UI.
- Ammo and heat both apply; neither replaces the other.

⸻

Phase 4 — Noise Event System

Design Intent

Gunfire should matter in the world. A loud shot should alert enemies, pull patrols/camps toward investigation, and punish reckless ranged spam. Suppressed weapons should reduce this effect, not erase it entirely.

Do not hardwire enemies directly inside operator.gd. Create a general noise event system so future systems can emit noise too: gunfire, sprinting, explosions, metal doors, vehicle weapons, alarms, etc.

New System

Create:

custodian/game/systems/stealth/noise_event.gd
custodian/game/systems/stealth/noise_event_bus.gd

If the project has an existing global/system folder convention, follow it.

NoiseEvent resource/data

class_name NoiseEvent
extends RefCounted
var source: Node2D
var source_team: StringName = &"player"
var position: Vector2 = Vector2.ZERO
var radius_px: float = 0.0
var loudness: float = 1.0
var threat_value: float = 1.0
var kind: StringName = &"generic"
var timestamp_msec: int = 0
var suppressed: bool = false

NoiseEventBus node

class_name NoiseEventBus
extends Node
signal noise_emitted(event: NoiseEvent)
func emit_noise(event: NoiseEvent) -> void:
if event == null:
return
event.timestamp_msec = Time.get_ticks_msec()
noise_emitted.emit(event)

Register it in the scene tree in the same style as existing global systems. If no global autoload pattern exists, place under:

/root/GameRoot/World/NoiseEventBus

and make a safe resolver:

func \_get_noise_event_bus() -> Node:
return get_node_or_null("/root/GameRoot/World/NoiseEventBus")

Weapon noise fields

Extend weapon JSON:

"noise": {
"shot_radius_px": 360,
"shot_loudness": 1.0,
"suppressed": false,
"suppressed_radius_mult": 0.35,
"alert_threat_value": 1.0
}

Suggested tuning:

Unsuppressed pistol: 260
Unsuppressed carbine: 420
Shotgun: 480
Sniper: 620
Suppressed pistol: 90
Suppressed carbine: 160
Melee hit: 70–120
Sneak step: 10–18
Walk step: 35–45
Sprint: 100–120
Dodge: 120–150
Vehicle weapon: 700+

Operator integration

When a shot is emitted, call:

\_emit_weapon_noise(active_weapon, spawn_position)

Noise should emit even if the shot hits a wall immediately.

Do not emit one noise per projectile pellet for shotguns. Emit one weapon-shot noise event per trigger pull.

Extend the existing stealth snapshot logic:

Current snapshot can still expose ambient state, but gunshot alerting should use NoiseEventBus. Do not rely only on current_noise_radius_px, because enemies need a specific event position and kind.

Visual debug

Add a debug flag:

@export var debug_noise_events: bool = false

If enabled, either:

- print concise noise event lines, or
- draw a temporary radius circle if there is already a debug draw system.

Do not create permanent production UI.

Acceptance

- Gunfire emits a noise event with position/radius/kind.
- Suppressed weapons emit smaller noise.
- Noise does not require enemies to exist to function.
- System is generic enough for future vehicles/explosions.
- No direct tight coupling from operator to specific enemy scripts.

⸻

Phase 5 — Sneaking And Stealth State Formalization

Design Intent

The operator already has primitive sneaking fields. Formalize them so enemy perception can query reliable values.

Sneaking should reduce sound and visibility, but it should not make the player invisible. It should buy positioning and reduce detection range.

Operator stealth API

Add/standardize:

func get_stealth_snapshot() -> Dictionary:
return {
"is_sneaking": is_sneaking,
"noise_radius_px": current_noise_radius_px,
"visibility_mult": stealth_visibility_mult,
"global_position": global_position,
"velocity": velocity,
"is_sprinting": is_sprinting,
"is_firing": \_is_ranged_fire_animation_active(),
"is_dodging": \_dodge_active or \_dodge_recovery_active,
}

Current project already has a snapshot shape; extend it without breaking callers.

Movement noise baseline

Tune the snapshot values:

idle: 8–10 px
sneak: 16–20 px
walk: 45 px
sprint: 110 px
dodge: 130 px
melee attack: 90–120 px
ranged firing: do not rely on snapshot; use NoiseEventBus

Visibility multiplier baseline

idle: 0.90
sneak: 0.45
walk: 1.00
sprint: 1.25
ranged-ready: 1.05
firing: 1.40

If cover/light systems do not exist yet, do not invent them. Leave extension points:

var cover_visibility_mult := 1.0
var light_visibility_mult := 1.0

and multiply later.

Input

Keep current sneak input. If InputMap lacks "sneak", add it with a reasonable keyboard default only if the project already manages input maps in code. Otherwise document it.

Suggested controls:

Sneak: Alt or C
Controller: left stick partial tilt later, not required now

Acceptance

- Sneaking is queryable by enemies.
- Sneaking slows the player.
- Sneaking reduces visibility and movement noise.
- Gunfire overrides stealth by emitting noise events.
- No cover/light overbuild in this pass.

⸻

Phase 6 — Enemy Perception Component

Design Intent

Enemies should not always know where the player is. They should detect through sight and sound, investigate last known positions, pursue when confirmed, and lose the player if contact is broken.

This should be componentized so wave enemies and ambient enemies can share it.

Create/Find Perception Component

Search for existing enemy perception, blackboard, behavior profile, and state machine files. If they exist, extend them. If not, create:

custodian/game/actors/enemies/components/enemy_perception_component.gd
custodian/game/actors/enemies/components/enemy_blackboard.gd

If the repo uses a different enemy folder, match that convention.

Blackboard fields

class_name EnemyBlackboard
extends RefCounted
var target: Node2D = null
var target_visible: bool = false
var target_last_seen_position: Vector2 = Vector2.ZERO
var target_last_heard_position: Vector2 = Vector2.ZERO
var suspicion: float = 0.0
var alertness: float = 0.0
var investigation_position: Vector2 = Vector2.ZERO
var has_investigation_position: bool = false
var pursuit_timer: float = 0.0
var search_timer: float = 0.0
var home_position: Vector2 = Vector2.ZERO
var leash_radius_px: float = 640.0
var camp_id: StringName = &""

Perception config

@export var sight_radius_px: float = 280.0
@export var peripheral_sight_radius_px: float = 160.0
@export var field_of_view_degrees: float = 105.0
@export var hearing_mult: float = 1.0
@export var suspicion_gain_sight_per_sec: float = 1.6
@export var suspicion_gain_heard: float = 0.65
@export var suspicion_decay_per_sec: float = 0.35
@export var alert_threshold: float = 1.0
@export var pursuit_memory_sec: float = 3.5
@export var search_duration_sec: float = 4.0
@export var leash_radius_px: float = 700.0
@export var line_of_sight_collision_mask: int = 1

Line of sight

Implement direct ray LOS first. Do not implement expensive tile scanning yet.

func has_line_of_sight_to(target: Node2D) -> bool:
if target == null:
return false
var from := owner.global_position
var to := target.global_position
if from.distance_to(to) > sight_radius_px \* target_visibility_mult:
return false # Optional FOV check # Physics ray blocks on world/static bodies

Use physics raycasts against walls/static blockers. Exclude self and target.

Hearing

Subscribe enemies to NoiseEventBus.noise_emitted.

On event:

var dist := owner.global_position.distance_to(event.position)
var effective_radius := event.radius_px _ hearing_mult
if dist <= effective_radius:
blackboard.target_last_heard_position = event.position
blackboard.investigation_position = event.position
blackboard.has_investigation_position = true
blackboard.suspicion += event.threat_value _ (1.0 - dist / effective_radius)

If event is a gunshot:

- Enemy goes to investigation or alert quickly.
- If very close, enemy becomes immediately alerted.
- If suppressed and far, enemy investigates but may not immediately know exact target.

Detection states

Add or normalize enemy AI state names:

idle
patrol
investigate
alert
pursue
search
return_home

Minimum behavior:

idle/patrol:
if hears noise -> investigate
if sees player long enough -> pursue
investigate:
move to investigation position
if sees player -> pursue
if reaches point and does not see player -> search
pursue:
chase visible player
update last seen position while visible
if loses LOS -> search toward last seen position
search:
move around last known/last heard position for a short time
if sees/hears again -> pursue/investigate
if timer expires -> return_home
return_home:
go back to camp/home/patrol anchor

Better version of the “line of sight to nearby tile” idea

Do not scan every surrounding tile every frame. Use a last-known-position + search points approach.

When enemy loses line of sight:

1. Store target_last_seen_position.
2. Move to that position.
3. If no target, generate 2–4 deterministic search offsets around it.
4. Check LOS normally during movement.
5. If no reacquisition, return home.

This gives the behavior you wanted without expensive tile visibility propagation.

Search offsets should be deterministic or seeded, not random every frame:

var SEARCH_OFFSETS := [
Vector2(48, 0),
Vector2(-48, 0),
Vector2(0, 48),
Vector2(0, -48),
]

Acceptance

- Enemies can see the player through line of sight.
- Enemies hear gunshots/noise events.
- Enemies investigate noise positions.
- Enemies pursue when alerted.
- Enemies lose contact and search instead of knowing the player forever.
- Enemies return home/camp if they fail to reacquire.
- Detection respects sneaking via visibility multiplier.
- Detection respects leash radius.

⸻

Phase 7 — Ambient Enemy Camps And World Placement

Design Intent

Gunfire noise only matters if enemies exist in the world outside wave spawns. Add ambient enemy placements that can be authored or generated. Do not require full worldgen bases before the system works.

Implement a simple ambient enemy layer first, then make it worldgen-aware.

New system

Create:

custodian/game/systems/spawning/ambient_enemy_camp.gd
custodian/game/systems/spawning/ambient_enemy_spawner.gd

If existing wave spawning has a standard folder, use that.

AmbientEnemyCamp

class_name AmbientEnemyCamp
extends Node2D
@export var camp_id: StringName = &"camp"
@export var enemy_scene: PackedScene
@export var enemy_count_min: int = 2
@export var enemy_count_max: int = 4
@export var spawn_radius_px: float = 96.0
@export var leash_radius_px: float = 700.0
@export var initially_active: bool = true
@export var respawn_enabled: bool = false
@export var faction_id: StringName = &"hostile"
@export var behavior_profile_id: StringName = &"ambient_scavenger"

On ready:

- Spawn enemies around camp position.
- Assign blackboard home_position.
- Assign camp_id.
- Assign leash radius.
- Assign behavior profile if available.

Procedural placement bridge

Do not block this on full worldgen. Support two modes:

1. Authored scene camps placed manually.
2. Runtime-generated camps from spawn markers or procgen tags.

If procgen already marks regions/kinds, camps can spawn near:

ruin nodes
collapsed roadblocks
industrial platforms
outer causeway pockets
not inside safe hub zones
not immediately at player spawn

Minimum safe algorithm:

For each eligible spawn marker:
if distance to player_start < min_distance, skip
if distance to another camp < camp_spacing, skip
if terrain is walkable, place camp

Suggested values:

min distance from player start: 420 px
min camp spacing: 700 px
camp activation range: 1200 px
max active ambient enemies near player: 12

Performance

Do not spawn the entire world’s enemies if the map is large. Use activation radius:

camp dormant when far
camp active when player within activation range
camp deactivates only if no active pursuit and far enough

For now, if pooling/deactivation is too much, cap total ambient camps in the current test scene.

Enemy composition

Start simple:

ambient_scavenger_camp:
2 melee scavengers
1 weak ranged scavenger optional
ruin_watch_camp:
1 watcher
2 melee
iconoclast_cache_team:
2 armed low-ammo enemies

Do not require new art. Use existing enemy scenes/placeholders.

Acceptance

- There are enemies in the world outside wave spawns.
- Camps have home/leash positions.
- Enemies from camps can be pulled by gunfire noise.
- Enemies do not chase forever across the whole map.
- The system supports authored and generated placement.
- No full enemy-base worldgen dependency is required for the first usable slice.

⸻

Phase 8 — Noise-To-Enemy Alert Integration

Goal

Make ranged spam dangerous by connecting gunshot noise to ambient enemies and wave enemies.

Integration

Every enemy with perception should subscribe to noise events. On hearing gunfire:

If idle/patrol:
go investigate noise position
If already investigating:
update investigation if louder/closer/more threatening
If pursuing:
ignore distant unrelated noise unless no current target
If returning home:
investigate only if noise is within leash or high threat

Threat value by weapon

Add weapon noise threat:

"noise": {
"shot_radius_px": 420,
"shot_loudness": 1.0,
"alert_threat_value": 1.0
}

Use classes:

suppressed pistol: 0.35
pistol: 0.7
carbine: 1.0
shotgun: 1.15
sniper: 1.35
explosion: 2.0
vehicle gun: 2.5

Anti-cheese

- Suppressed does not mean silent.
- Repeated suppressed fire should build suspicion if enemies are close.
- Enemies should investigate the shot position, not magically path to the player forever.
- Enemies should not hear through the whole map unless weapon radius reaches them.
- Enemies should not all globally aggro unless the encounter explicitly has alarm logic.

Acceptance

- Firing a carbine near a camp pulls enemies to investigate.
- Firing repeatedly escalates investigation into pursuit if the player is seen.
- Suppressed/low-noise weapons reduce response radius.
- Enemies can lose the player and return to camp.
- Ranged combat now creates positional consequences.

⸻

Phase 9 — Enemy Pursuit, Leash, And Search Behavior

Goal

Prevent two bad extremes:

1. Enemies ignore gunfire and feel dead.
2. Enemies hear one shot and chase the player forever.

Rules

Each ambient enemy has:

home_position
leash_radius
last_seen_position
last_heard_position
pursuit_memory_timer
search_timer

Pursuit rules:

If target visible:
pursue directly
update last_seen_position
reset pursuit_memory_timer
If target not visible but pursuit_memory_timer > 0:
move to last_seen_position
decrement timer
If reaches last_seen_position and target not visible:
enter search
If search timer expires:
return_home
If outside leash radius and target not visible:
return_home
If outside leash radius but target visible:
continue briefly, but increase desire to break pursuit

For the first version, keep it simple:

Hard leash only applies after LOS is broken.

That prevents enemies from stopping in the player’s face just because they stepped over a radius.

Search

Search should use deterministic offsets. Do not require complex tile LOS propagation.

var search_points := [
last_seen_position,
last_seen_position + Vector2(48, 0),
last_seen_position + Vector2(-48, 0),
last_seen_position + Vector2(0, 48),
last_seen_position + Vector2(0, -48),
]

Enemy moves through 1–3 points, checking LOS normally.

Acceptance

- Enemy pursuit feels believable.
- Breaking LOS matters.
- Sneaking after breaking LOS helps.
- Enemies do not globally chase forever.
- Search behavior is deterministic enough for debugging.

⸻

Phase 10 — Ranged Balance UI / Debug Readouts

Goal

Make the new constraints visible enough that the player understands why a shot failed.

Weapon status dictionary

Extend get_weapon_status() to include:

"ammo_type"
"loaded_ammo"
"reserve_ammo"
"max_reserve_ammo"
"magazine_size"
"heat"
"heat_max"
"heat_ratio"
"overheated"
"overheat_remaining"
"noise_radius_px"
"suppressed"
"effective_range_px"
"max_range_px"

Keep old keys for compatibility:

"ammo_standard"
"ammo_heavy"
"ammo_standard_loaded"
"ammo_heavy_loaded"

but mark them internally as legacy.

Feedback requirements

When attempting to fire:

No loaded ammo but reserve exists:
start reload
No loaded ammo and no reserve:
dry click / no shot feedback
Overheated:
overheat feedback / no shot
Reloading:
no shot
Not ranged-ready:
no shot or panic shot only if current controls allow it

No new art required. Use print/debug first if UI is not ready.

Suggested debug messages:

DRY FIRE: NO AMMO
OVERHEATED: CARBINE
RELOADING

Do not spam; only on attempted action.

Optional UI

If weapon UI exists, add:

- Heat bar under ammo.
- Bar turns/warns above heat_ui_warn_threshold.
- Overheated state locks the bar until cooled.

If UI does not exist or is not straightforward, only expose status data and document UI TODO.

Acceptance

- Player/developer can inspect ammo/heat/noise through status.
- Failed shots have a readable reason.
- Existing UI does not crash if it ignores new fields.

⸻

Phase 11 — Vehicle-Mounted Weapon Future Hook

Design Intent

The player eventually needs to fire from inside vehicles when the vehicle has a weapon attached. This is related to ranged combat but should not block the current nerf pass.

Do not implement full vehicle combat unless there is already a clean vehicle actor, mount socket, and input ownership model.

Document Future Contract

Add a section to the new design doc:

## Future: Vehicle-Mounted Weapon Firing

Define:

VehicleWeaponDefinition:
weapon_id
weapon_data_path
mount_socket
fire_arc_degrees
heat model
ammo source
noise radius
recoil/knockback
occupant required

Input rule:

If operator is inside a vehicle and the vehicle owns an active weapon:
primary fire routes to vehicle weapon
weapon heat/noise/ammo are owned by the vehicle weapon
operator sidearm/primary weapon does not fire unless vehicle allows personal firing ports

Vehicle weapon noise should use the same NoiseEventBus.

Vehicle weapon heat should use the same heat schema.

Vehicle weapons should probably have much higher noise:

vehicle light gun: 700 px
vehicle heavy gun: 1000 px

Optional tiny hook

If vehicle code already exists and has occupant state, add only:

func can_fire_vehicle_weapon() -> bool
func request_vehicle_weapon_fire(aim_direction: Vector2) -> bool

and route operator fire to it before personal weapon fire.

If not clean, do not create fake vehicle architecture in this pass.

Acceptance

- Future vehicle weapons are documented.
- Existing ranged systems are designed to be reusable by vehicle weapons.
- No half-broken vehicle shooting is introduced.

⸻

Phase 12 — Tuning Defaults

Apply initial tuning so ranged is immediately less OP.

Global carry defaults

ammo_standard_max / kinetic_light max: 72
ammo_heavy_max / kinetic_heavy max: 16

Carbine MK1

"stats": {
"damage": 11,
"fire_rate_rps": 6.0,
"magazine_size": 24,
"reload_time_sec": 1.9,
"effective_range_px": 180,
"max_range_px": 320,
"damage_falloff_start_px": 170,
"damage_falloff_end_px": 320,
"min_falloff_damage_mult": 0.50,
"accuracy": 0.82,
"spread_deg": 2.8,
"recoil": 0.45,
"projectile_speed_px": 900,
"penetration": 1
},
"ammo": {
"ammo_type": "kinetic_light",
"starting_reserve": 48,
"max_reserve": 72,
"ammo_per_shot": 1,
"reload_style": "magazine"
},
"heat": {
"enabled": true,
"max": 100,
"per_shot": 11,
"decay_per_sec": 26,
"decay_delay_sec": 0.30,
"overheat_threshold": 100,
"overheat_lockout_sec": 1.25,
"spread_mult_at_max": 1.75,
"recoil_mult_at_max": 1.45
},
"noise": {
"shot_radius_px": 420,
"shot_loudness": 1.0,
"suppressed": false,
"suppressed_radius_mult": 0.35,
"alert_threat_value": 1.0
}

Pistol / sidearm

"stats": {
"damage": 8,
"fire_rate_rps": 3.5,
"magazine_size": 10,
"reload_time_sec": 1.4,
"effective_range_px": 110,
"max_range_px": 220,
"damage_falloff_start_px": 100,
"damage_falloff_end_px": 220,
"min_falloff_damage_mult": 0.45,
"spread_deg": 3.2,
"recoil": 0.35
},
"ammo": {
"ammo_type": "kinetic_light",
"starting_reserve": 30,
"max_reserve": 60,
"ammo_per_shot": 1
},
"heat": {
"enabled": true,
"max": 100,
"per_shot": 8,
"decay_per_sec": 34,
"decay_delay_sec": 0.20,
"overheat_lockout_sec": 0.85
},
"noise": {
"shot_radius_px": 260,
"alert_threat_value": 0.7
}

Sniper future/default

If sniper exists:

damage: high
fire_rate: very low
magazine: 3–5
reserve: 6–10
heat_per_shot: 55
decay_per_sec: 18
noise_radius: 620

The sniper should be a deliberate problem-solver, not a primary room clearer.

⸻

Phase 13 — Validation And Test Checklist

Required manual test scenario

Create or use a small test map with:

- Operator
- One carbine
- One sidearm
- One ammo cache
- One wall/obstruction
- One ambient enemy camp of 3 enemies
- One open sightline
- One corner to break LOS

Tests

Ammo

- Fire until magazine empty.
- Confirm reserve decreases on reload.
- Confirm reserve cannot exceed cap.
- Confirm small pickup adds only a small amount.
- Confirm pickup at cap gives 0 or partial gain.
- Confirm sidearm uses the same ammo framework.

Heat

- Fire short bursts: no overheat.
- Fire continuously: overheat occurs.
- Try firing while overheated: no shot.
- Wait: weapon cools and can fire again.
- Confirm high heat worsens spread/recoil.

Range

- Shoot close enemy: full damage.
- Shoot far enemy: reduced damage.
- Shoot past max range: projectile expires.

Noise

- Fire near camp: enemies investigate.
- Fire suppressed weapon if available: smaller response.
- Fire far from camp: no response.
- Fire repeatedly near camp: stronger response.

Stealth

- Sneak near enemy outside sightline: no instant detection.
- Walk near enemy: easier detection.
- Sprint near enemy: quick detection/noise.
- Break LOS while pursued: enemy searches then returns.

Ambient enemies

- Camp spawns enemies.
- Enemies have home/leash.
- Enemies do not pursue forever.
- Enemies can be attracted by noise.

Regression

- Melee still works.
- Parry/guard still works.
- Dodge still works.
- Reload still works.
- Weapon equip/sidearm fallback still works.
- Existing wave spawner still works.

Run commands

Use available project validation. At minimum:

cd custodian
godot --headless --check-only

If the project has validation scripts, run them too:

find tools -maxdepth 3 -type f | sort

Then run any relevant smoke scripts under:

custodian/tools/validation/

If godot --headless --check-only is not supported by the installed Godot version, run the closest available non-interactive parse/smoke check and document what happened.

⸻

Phase 14 — Final Documentation Update

After implementation, update:

design/02_features/combat_feel/RANGED_COMBAT_BALANCE_AND_STEALTH_SYSTEM.md
custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/FILE_INDEX.md

Add a clear “Implemented in this pass” section.

Also add a “Deferred” section:

Deferred:

- Full vehicle-mounted weapons
- Suppressor item/mod inventory
- Cover/light stealth modifiers
- Large-scale procedural enemy bases
- Advanced squad coordination
- Alarm network / sector-wide escalation

Final acceptance

The feature is complete when:

- Ranged combat is still useful but no longer free-spam dominant.
- Ammo reserve is capped and pickups are controlled.
- Heat forces burst firing.
- Gunfire emits noise events.
- Enemies can perceive sight and sound.
- Ambient enemies exist outside wave spawns.
- Enemy pursuit has LOS loss, search, and leash behavior.
- Vehicle firing is cleanly documented as a future extension.
- Active docs and AI context are updated.
- Any documentation drift discovered during implementation is called out in the final Codex summary.

The most important design call here is: do not choose between ammo caps and scarcer supply; do both. Ammo cap solves hoarding, scarce supply solves “infinite refill,” heat solves trigger spam, and noise/ambient enemies solves the tactical consequence problem.
