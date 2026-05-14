Below is the hardened implementation spec for the encounter.

# CUSTODIAN Encounter Spec: The Bell-Kneeler

Internal continuity tag: `ash_bell`
Player-facing continuity name: **never shown**
Encounter name: **The Bell-Kneeler**
Primary motifs: Ninth Bell, white thread, black banners, Dry Fountain, Unarrived Saint, sealed west gate
Source alignment: this uses the Ash-Bell recurring near-continuity rules: repeated motifs, local contradictions, and no explicit “alternate universe” language.

---

# 1. Encounter Summary

The player discovers a buried basilica chamber beneath a ruined transit structure. At its center is an empty bell-frame, surrounded by white thread, black banners, ash, sealed archways, child-sized handprints, and a dry circular basin.

A kneeling drifter, the **Bell-Kneeler**, guards a bronze clapper from a bell that does not exist. They speak as if remembering a sacred disaster: the west gate was shut, the Ninth Bell rang, the Custodians obeyed, and Saint Orra — the Unarrived Saint — came too late.

The encounter starts as ambient narrative horror. If disturbed, it becomes a reality-bleed combat encounter where the room partially reverts to the Ash-Bell disaster state.

---

# 2. Scene Location

## Scene name

```txt
custodian/game/world/events/ash_bell/bell_kneeler_event.tscn
```

## Script paths

```txt
custodian/game/world/events/ash_bell/bell_kneeler_event.gd
custodian/game/world/events/ash_bell/bell_kneeler_npc.gd
custodian/game/world/events/ash_bell/ash_bell_bleed_controller.gd
custodian/game/world/events/ash_bell/ash_bell_event_state.gd
```

## Data paths

```txt
custodian/content/events/ash_bell/bell_kneeler_dialogue.json
custodian/content/events/ash_bell/bell_kneeler_event.json
custodian/content/items/lore/thread_of_the_unarrived.json
custodian/content/items/lore/bronze_clapper_without_bell.json
```

---

# 3. Map Layout

## Room footprint

Tile size: `32x32`
Recommended chamber size: `34 tiles wide x 26 tiles tall`
World pixel size: `1088 x 832`

The room should be mostly symmetrical, but broken enough to feel ancient and partially collapsed.

```txt
##################################################
#######......collapsed north ambulatory.....######
#####........................................#####
####.....BBBBBBBBB.....E.....BBBBBBBBB.......####
###......B.......B...........B.......B........###
###......B.......B...........B.......B........###
##.......B.......B.....K.....B.......B.........##
##.................TTTTTTTTT...................##
##.........A.......T.......T.......A...........##
##.................T...C...T...................##
##.........F.......T.......T.......F...........##
##.................TTTTTTTTT...................##
##.............................................##
##.....sealed arch.......D.......sealed arch....##
##.............................................##
###...........child handprints / ash............##
###............................................###
####.......entry stairs from south............####
##################################################
```

Legend:

```txt
E = Empty bell-frame
K = Bell-Kneeler
T = white thread ritual ring
C = bronze clapper / interactable item
B = black banners
A = sealed archways with phantom silhouettes during bleed
F = dry fountain/basin fragments
D = dialogue trigger threshold
# = walls/collapsed boundary
. = walkable ash-covered floor
```

---

# 4. Environmental Storytelling

## Required props

```txt
custodian/content/props/ash_bell/bell_frame_empty_96x128.png
custodian/content/props/ash_bell/bronze_clapper_32x32.png
custodian/content/props/ash_bell/black_banner_torn_32x64.png
custodian/content/props/ash_bell/white_thread_knot_16x16.png
custodian/content/props/ash_bell/white_thread_strand_32x8.png
custodian/content/props/ash_bell/dry_basin_fragment_64x32.png
custodian/content/props/ash_bell/sealed_arch_west_96x96.png
custodian/content/props/ash_bell/child_handprints_32x32.png
custodian/content/props/ash_bell/ash_pile_soft_32x32.png
custodian/content/props/ash_bell/black_water_crack_32x32.png
```

## Visual language

The chamber should communicate three things before the player speaks to anyone:

1. A bell was worshiped here.
2. Something happened to children/civilians.
3. The Custodians were involved in containment, not rescue.

Use black banners as military/funerary signals. Use white thread as a ritual marker. Use child handprints low on doors and basin walls. Do not write explanatory graffiti like “THE BELL WAS EVIL.” Keep it archaeological.

---

# 5. Bell-Kneeler Character Design

## Silhouette

A kneeling humanoid, thin and corpse-like, almost priestly but not clean. The body should read as devotional, not warrior-first.

## Outfit

- Funeral-black layered robe, torn at the hem.
- Heavy ash-gray mantle over shoulders.
- White thread wrapped around wrists, fingers, throat, and one ankle.
- Rusted bell fragments tied into the robe like charms.
- A broken black banner strip hanging from the waist.
- Face partially covered by a soot veil.
- Eyes dimly filled with pale ash glow.
- Hands gray-black from handling ash and bronze.
- Carries no obvious weapon at first.
- During combat, the bronze clapper becomes a hammer-like ritual weapon.

## Asset generation prompt

```txt
Create a top-down 3/4 pixel art humanoid NPC for CUSTODIAN: The Bell-Kneeler. A gaunt kneeling figure in funeral-black layered robes with an ash-gray mantle, white ritual thread wrapped around wrists/fingers/throat, small rusted bell fragments tied into the clothing, torn black banner cloth at the waist, soot veil over the face, pale ash-glowing eyes. Dark Souls / Elden Ring inspired, mournful religious horror, readable at 32–64 px scale, transparent background, strong silhouette, muted ash/black/bronze palette.
```

## Runtime sprites

```txt
custodian/content/sprites/npcs/ash_bell/bell_kneeler/idle_kneel_south.png
custodian/content/sprites/npcs/ash_bell/bell_kneeler/idle_kneel_east.png
custodian/content/sprites/npcs/ash_bell/bell_kneeler/rise_south.png
custodian/content/sprites/npcs/ash_bell/bell_kneeler/rise_east.png
custodian/content/sprites/npcs/ash_bell/bell_kneeler/walk_south.png
custodian/content/sprites/npcs/ash_bell/bell_kneeler/attack_clapper_south.png
custodian/content/sprites/npcs/ash_bell/bell_kneeler/cast_toll_south.png
custodian/content/sprites/npcs/ash_bell/bell_kneeler/death_unthreading.png
```

---

# 6. Dialogue

Avoid “this version,” “this time,” “timeline,” “alternate,” “continuity,” or “universe.”

## First approach

```txt
“Do not speak during the toll.”
```

Beat. No bell rings.

```txt
“The west gate was shut before the third ringing.”
```

```txt
“Mothers pressed their children beneath the banners.”
```

```txt
“The Custodians walked the walls with covered lanterns.”
```

```txt
“And still the ash came.”
```

## Second interaction

```txt
“Strange.”
```

```txt
“The Fountain should be near.”
```

```txt
“They laid the little ones around it in white thread.”
```

```txt
“So Saint Orra would know whom she had failed.”
```

## Third interaction

```txt
“The Saint came late.”
```

```txt
“That is why we loved her.”
```

```txt
“No savior should arrive before the wound is known.”
```

## Fourth interaction

```txt
“Bells do not wake the dead.”
```

```txt
“They teach the living to answer wrongly.”
```

## If player has high instability

```txt
“You have heard it.”
```

```txt
“Not with the ear.”
```

```txt
“With the part of you that obeys.”
```

## If attacked

```txt
“Ahh…”
```

```txt
“So fear found your hand.”
```

```txt
“Then let the Ninth be answered.”
```

Boss title:

```txt
Bell-Kneeler, Witness of the Unarrived
```

---

# 7. Encounter Mechanics

## Passive phase: Ritual Listening

Before aggression, the room applies subtle non-combat effects:

- Ambient bell pressure increases near the empty frame.
- Ash particles drift upward.
- Player footsteps briefly echo late.
- The bronze clapper can be inspected but not taken unless the NPC is gone or defeated.
- The Bell-Kneeler tracks the player only with their head.

## Bleed phase trigger

Triggered by:

```txt
player_attacks_npc == true
OR player_steals_clapper == true
OR player_uses_continuum_item_near_frame == true
OR custodian_instability >= HIGH and player_crosses_thread_ring == true
```

## Bleed phase effects

When triggered:

- Ash direction reverses from upward to downward.
- Distant bell toll starts.
- Dry basin fills with black water.
- Sealed archways show phantom civilians.
- White thread becomes collision hazard.
- Bell-Kneeler rises.
- The room locks until the phase ends.

## Combat gimmick

The Bell-Kneeler does not fight like a normal enemy. The chamber fights with them.

### Mechanic: Toll Count

The room tracks a `toll_count` from 0 to 9.

Every major Bell-Kneeler cast increments it.

At specific tolls:

```txt
1: ash visibility drops
3: sealed archway phantoms appear
5: thread snares activate
7: black water slows movement
9: Ninth Toll event triggers
```

### Ninth Toll

At toll 9:

- Player receives a short forced silence/audio dampening effect.
- All phantoms turn toward the player.
- Bell-Kneeler performs a large radial ash wave.
- If player is inside the thread ring, they are marked with `answered_wrongly`.

`answered_wrongly` should not simply be damage. Make it interesting:

```txt
answered_wrongly:
  duration: 18 seconds
  effect:
    - healing reduced
    - dodge afterimage lags behind
    - next opened door briefly shows wrong room overlay
    - nearby dead NPC murmurs one Ash-Bell line
```

This makes the event feel like contamination, not just a boss debuff.

---

# 8. Rewards

## If player does not attack and leaves

The player receives nothing immediately.

But later, another Ash-Bell drifter may say:

```txt
“You let the Witness keep her silence.
Kind, or cowardly. The Bell loves both.”
```

## If player defeats Bell-Kneeler

Drops:

```txt
Bronze Clapper Without a Bell
Thread of the Unarrived
Ash-Bell Memory Shard
```

## If player listens through all dialogue and does not attack

The Bell-Kneeler eventually disappears, leaving only:

```txt
Thread of the Unarrived
```

This should be the “gentler” outcome.

---

# 9. Item Text

## Thread of the Unarrived

```txt
A length of white funerary thread, brittle with pale ash.

Worn by those who waited beneath the black banners
for Saint Orra, the Unarrived.

The thread is tied not to preserve the body,
but to prove that one still belongs
to the proper grief.
```

## Bronze Clapper Without a Bell

```txt
A bronze clapper taken from no known bell.

No matching bell exists in any surviving civic inventory,
yet the metal is worn smooth by centuries of ringing.

When held near sealed doors,
nearby voices briefly remember being left outside.
```

## Ash-Bell Memory Shard

```txt
A pale shard of compacted ash.

Warm as breath.

Within it lingers a command half-obeyed:
Shut the gate.
Raise the banners.
Count only those who answer twice.
```

---

# 10. Godot Implementation

## Event state enum

```gdscript
# custodian/game/world/events/ash_bell/ash_bell_event_state.gd
extends Resource
class_name AshBellEventState

enum Phase {
	DORMANT,
	LISTENING,
	WARNED,
	BLEEDING,
	COMBAT,
	RESOLVED_MERCY,
	RESOLVED_DEFEATED
}

@export var phase: Phase = Phase.DORMANT
@export var toll_count: int = 0
@export var player_crossed_thread_ring: bool = false
@export var clapper_taken: bool = false
@export var npc_attacked: bool = false
@export var listened_fully: bool = false
@export var answered_wrongly_active: bool = false
```

## Main event controller

```gdscript
# custodian/game/world/events/ash_bell/bell_kneeler_event.gd
extends Node2D
class_name BellKneelerEvent

signal event_started
signal bleed_started
signal toll_changed(toll_count: int)
signal ninth_toll_triggered
signal event_resolved(resolution: String)

@export var event_state: AshBellEventState
@export var instability_threshold: int = 75
@export var toll_interval_seconds: float = 8.0
@export var ninth_toll_damage: int = 18

@onready var npc: BellKneelerNPC = $BellKneelerNPC
@onready var bleed_controller: AshBellBleedController = $AshBellBleedController
@onready var thread_ring_area: Area2D = $ThreadRingArea
@onready var clapper_area: Area2D = $BronzeClapperInteractable
@onready var room_lock: Node2D = $RoomLock
@onready var dialogue_anchor: Node2D = $DialogueAnchor

var _toll_timer: float = 0.0
var _combat_active: bool = false
var _player: Node = null

func _ready() -> void:
	if event_state == null:
		event_state = AshBellEventState.new()

	thread_ring_area.body_entered.connect(_on_thread_ring_entered)
	npc.attacked.connect(_on_npc_attacked)
	npc.dialogue_exhausted.connect(_on_dialogue_exhausted)
	clapper_area.body_entered.connect(_on_clapper_area_entered)

	bleed_controller.set_bleed_intensity(0.0)
	room_lock.visible = false
	event_state.phase = AshBellEventState.Phase.LISTENING
	event_started.emit()

func _process(delta: float) -> void:
	if not _combat_active:
		return

	_toll_timer += delta
	if _toll_timer >= toll_interval_seconds:
		_toll_timer = 0.0
		increment_toll()

func _on_thread_ring_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	_player = body
	event_state.player_crossed_thread_ring = true

	if _get_player_instability(body) >= instability_threshold:
		start_bleed("instability_crossed_thread")

func _on_npc_attacked() -> void:
	event_state.npc_attacked = true
	start_bleed("npc_attacked")

func _on_clapper_area_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	_player = body

	if event_state.phase == AshBellEventState.Phase.LISTENING:
		# Stealing the clapper before resolution is sacrilege.
		event_state.clapper_taken = true
		start_bleed("clapper_disturbed")

func _on_dialogue_exhausted() -> void:
	event_state.listened_fully = true

	# Mercy resolution: player listened and did not violate ritual.
	if not event_state.npc_attacked and not event_state.clapper_taken:
		resolve_mercy()

func start_bleed(reason: String) -> void:
	if event_state.phase == AshBellEventState.Phase.BLEEDING or event_state.phase == AshBellEventState.Phase.COMBAT:
		return

	event_state.phase = AshBellEventState.Phase.BLEEDING
	bleed_started.emit()

	room_lock.visible = true
	bleed_controller.begin_bleed(reason)
	npc.begin_combat(reason)

	await get_tree().create_timer(1.2).timeout

	event_state.phase = AshBellEventState.Phase.COMBAT
	_combat_active = true
	_toll_timer = 0.0

func increment_toll() -> void:
	event_state.toll_count = clamp(event_state.toll_count + 1, 0, 9)
	toll_changed.emit(event_state.toll_count)

	bleed_controller.apply_toll(event_state.toll_count)
	npc.on_toll(event_state.toll_count)

	if event_state.toll_count >= 9:
		trigger_ninth_toll()

func trigger_ninth_toll() -> void:
	ninth_toll_triggered.emit()
	bleed_controller.trigger_ninth_toll()

	if _player != null and _is_player_inside_thread_ring(_player):
		_apply_answered_wrongly(_player)

	event_state.toll_count = 0
	toll_changed.emit(event_state.toll_count)

func resolve_mercy() -> void:
	event_state.phase = AshBellEventState.Phase.RESOLVED_MERCY
	bleed_controller.fade_to_silence()
	npc.vanish_mercy()
	_spawn_reward("thread_of_the_unarrived")
	event_resolved.emit("mercy")

func resolve_defeated() -> void:
	event_state.phase = AshBellEventState.Phase.RESOLVED_DEFEATED
	_combat_active = false
	room_lock.visible = false
	bleed_controller.end_bleed()
	_spawn_reward("bronze_clapper_without_bell")
	_spawn_reward("thread_of_the_unarrived")
	_spawn_reward("ash_bell_memory_shard")
	event_resolved.emit("defeated")

func _apply_answered_wrongly(player: Node) -> void:
	event_state.answered_wrongly_active = true

	if player.has_method("apply_status_effect"):
		player.apply_status_effect({
			"id": "answered_wrongly",
			"duration": 18.0,
			"healing_multiplier": 0.65,
			"dodge_echo_lag": true,
			"continuity_murmur_chance": 0.25
		})

func _is_player_inside_thread_ring(player: Node) -> bool:
	return thread_ring_area.overlaps_body(player)

func _get_player_instability(player: Node) -> int:
	if player.has_method("get_custodian_instability"):
		return player.get_custodian_instability()
	return 0

func _spawn_reward(item_id: String) -> void:
	var reward_spawner := get_node_or_null("RewardSpawner")
	if reward_spawner != null and reward_spawner.has_method("spawn_item"):
		reward_spawner.spawn_item(item_id, npc.global_position + Vector2(0, 24))
```

## Bell-Kneeler NPC script

```gdscript
# custodian/game/world/events/ash_bell/bell_kneeler_npc.gd
extends CharacterBody2D
class_name BellKneelerNPC

signal attacked
signal dialogue_exhausted
signal defeated

@export var max_health: int = 140
@export var move_speed: float = 42.0
@export var clapper_attack_damage: int = 14
@export var ash_wave_damage: int = 10

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_area: Area2D = $AttackArea
@onready var dialogue_trigger: Area2D = $DialogueTrigger

var health: int
var combat_active: bool = false
var dialogue_index: int = 0
var target: Node2D = null

var dialogue_lines: Array[String] = [
	"Do not speak during the toll.",
	"The west gate was shut before the third ringing.",
	"Mothers pressed their children beneath the banners.",
	"The Custodians walked the walls with covered lanterns.",
	"And still the ash came.",
	"Strange.",
	"The Fountain should be near.",
	"They laid the little ones around it in white thread.",
	"So Saint Orra would know whom she had failed.",
	"The Saint came late.",
	"That is why we loved her.",
	"No savior should arrive before the wound is known.",
	"Bells do not wake the dead.",
	"They teach the living to answer wrongly."
]

func _ready() -> void:
	health = max_health
	anim.play("idle_kneel_south")
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	dialogue_trigger.body_entered.connect(_on_dialogue_body_entered)

func _physics_process(_delta: float) -> void:
	if not combat_active or target == null:
		return

	var to_target := target.global_position - global_position
	if to_target.length() > 48.0:
		velocity = to_target.normalized() * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func _on_dialogue_body_entered(body: Node) -> void:
	if combat_active:
		return
	if not body.is_in_group("player"):
		return

	speak_next_line()

func speak_next_line() -> void:
	if dialogue_index >= dialogue_lines.size():
		dialogue_exhausted.emit()
		return

	var line := dialogue_lines[dialogue_index]
	dialogue_index += 1

	var dialogue_ui := get_tree().get_first_node_in_group("dialogue_ui")
	if dialogue_ui != null and dialogue_ui.has_method("show_line"):
		dialogue_ui.show_line(line, self)

	if dialogue_index >= dialogue_lines.size():
		dialogue_exhausted.emit()

func begin_combat(reason: String) -> void:
	combat_active = true
	target = get_tree().get_first_node_in_group("player")
	anim.play("rise_south")

	await anim.animation_finished

	anim.play("walk_south")

func on_toll(toll_count: int) -> void:
	match toll_count:
		3:
			_cast_minor_ash()
		5:
			_cast_thread_snare()
		7:
			_cast_black_water_drag()
		9:
			_cast_ninth_toll()

func take_damage(amount: int) -> void:
	if not combat_active:
		attacked.emit()

	health -= amount

	if health <= 0:
		die()

func die() -> void:
	combat_active = false
	anim.play("death_unthreading")
	defeated.emit()
	queue_free()

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.has_method("get_damage"):
		take_damage(area.get_damage())

func _cast_minor_ash() -> void:
	anim.play("cast_toll_south")
	_spawn_event_projectile("ash_wave_minor")

func _cast_thread_snare() -> void:
	anim.play("cast_toll_south")
	_spawn_event_projectile("white_thread_snare")

func _cast_black_water_drag() -> void:
	anim.play("cast_toll_south")
	_spawn_event_projectile("black_water_drag")

func _cast_ninth_toll() -> void:
	anim.play("cast_toll_south")
	_spawn_event_projectile("ninth_toll_wave")

func _spawn_event_projectile(projectile_id: String) -> void:
	var spawner := get_node_or_null("../EventAttackSpawner")
	if spawner != null and spawner.has_method("spawn_attack"):
		spawner.spawn_attack(projectile_id, global_position, target)

func vanish_mercy() -> void:
	anim.play("death_unthreading")
	await anim.animation_finished
	queue_free()
```

## Bleed controller

```gdscript
# custodian/game/world/events/ash_bell/ash_bell_bleed_controller.gd
extends Node2D
class_name AshBellBleedController

@onready var ash_particles: GPUParticles2D = $AshParticles
@onready var black_water_tiles: Node2D = $BlackWaterTiles
@onready var phantom_arches: Node2D = $PhantomArches
@onready var thread_hazards: Node2D = $ThreadHazards
@onready var bell_audio: AudioStreamPlayer2D = $BellAudio
@onready var silence_bus_fx: Node = $SilenceBusFX

var bleed_intensity: float = 0.0

func _ready() -> void:
	black_water_tiles.visible = false
	phantom_arches.visible = false
	thread_hazards.visible = false
	set_bleed_intensity(0.0)

func begin_bleed(reason: String) -> void:
	set_bleed_intensity(0.35)
	_reverse_ash(false)
	bell_audio.play()

func apply_toll(toll_count: int) -> void:
	match toll_count:
		1:
			set_bleed_intensity(0.45)
			_reverse_ash(true)
		3:
			phantom_arches.visible = true
			set_bleed_intensity(0.55)
		5:
			thread_hazards.visible = true
			set_bleed_intensity(0.70)
		7:
			black_water_tiles.visible = true
			set_bleed_intensity(0.85)
		9:
			set_bleed_intensity(1.0)

func trigger_ninth_toll() -> void:
	if silence_bus_fx != null and silence_bus_fx.has_method("pulse_silence"):
		silence_bus_fx.pulse_silence(2.0)

	_flash_phantoms()

func end_bleed() -> void:
	set_bleed_intensity(0.0)
	bell_audio.stop()
	black_water_tiles.visible = false
	phantom_arches.visible = false
	thread_hazards.visible = false

func fade_to_silence() -> void:
	var tween := create_tween()
	tween.tween_method(set_bleed_intensity, bleed_intensity, 0.0, 2.5)
	await tween.finished
	bell_audio.stop()

func set_bleed_intensity(value: float) -> void:
	bleed_intensity = clamp(value, 0.0, 1.0)
	modulate.a = lerp(0.65, 1.0, bleed_intensity)

func _reverse_ash(downward: bool) -> void:
	if ash_particles == null:
		return

	var mat := ash_particles.process_material
	if mat == null:
		return

	if downward:
		mat.gravity = Vector3(0, 18, 0)
	else:
		mat.gravity = Vector3(0, -12, 0)

func _flash_phantoms() -> void:
	for child in phantom_arches.get_children():
		if child is CanvasItem:
			var tween := create_tween()
			child.modulate.a = 1.0
			tween.tween_property(child, "modulate:a", 0.15, 0.8)
```

---

# 11. Event JSON

```json
{
  "id": "ash_bell_bell_kneeler",
  "internal_continuity_tag": "ash_bell",
  "display_name": "The Bell-Kneeler",
  "spawn_rules": {
    "biomes": ["ruined_capital", "subterranean_basilica", "dead_transit"],
    "min_player_progress": 0.35,
    "requires_temporal_drifters_unlocked": true,
    "base_weight": 0.08,
    "instability_weight_bonus": {
      "threshold": 75,
      "bonus": 0.12
    }
  },
  "motifs": [
    "ninth_bell",
    "white_thread",
    "black_banners",
    "dry_fountain",
    "unarrived_saint",
    "sealed_west_gate"
  ],
  "forbidden_player_facing_terms": [
    "alternate universe",
    "timeline",
    "continuity",
    "this version",
    "this time"
  ],
  "resolutions": ["mercy", "defeated", "ignored"]
}
```

---

# 12. Why This Works

The encounter does not tell the player “this is another continuity.” It gives them:

- a bell-frame with no bell,
- a clapper with no source,
- a fountain that is absent but remembered,
- a saint who arrives too late,
- a gate that never existed here,
- and a Custodian order remembered as containment.

That is the exact flavor you want: the world does not explain the contradiction. It leaves the player standing in the gap.
