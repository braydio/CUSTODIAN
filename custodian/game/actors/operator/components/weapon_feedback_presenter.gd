class_name WeaponFeedbackPresenter
extends Node2D

const VENT_VFX_SCENE := preload("res://game/vfx/weapons/weapon_overheat_vent_vfx.tscn")

@onready var dry_fire_player: AudioStreamPlayer2D = $DryFirePlayer
@onready var reload_player: AudioStreamPlayer2D = $ReloadPlayer
@onready var heat_player: AudioStreamPlayer2D = $HeatPlayer
@onready var shot_player: AudioStreamPlayer2D = $ShotPlayer

var _operator: Node = null
var _sprite_tween: Tween = null
var _missing_asset_warnings: Dictionary = {}


func _ready() -> void:
	_operator = get_parent()
	if _operator == null or not _operator.has_signal("weapon_feedback_event"):
		push_warning("[WeaponFeedbackPresenter] LOUD MISSING CONTRACT: parent Operator has no weapon_feedback_event signal; presentation disabled, gameplay continues.")
		return
	_operator.weapon_feedback_event.connect(_on_weapon_feedback_event)


func _on_weapon_feedback_event(event_id: StringName, snapshot: Dictionary) -> void:
	if not bool(snapshot.get("active_weapon", true)):
		return
	match event_id:
		&"fire":
			_play_snapshot_sound(shot_player, snapshot, &"fire", event_id)
		&"dry_fire":
			_play_snapshot_sound(dry_fire_player, snapshot, &"empty", event_id)
		&"reload_started":
			_play_snapshot_sound(reload_player, snapshot, &"reload_start", event_id)
		&"reload_completed":
			_play_snapshot_sound(reload_player, snapshot, &"reload_complete", event_id)
		&"heat_hot", &"heat_critical":
			_play_snapshot_sound(heat_player, snapshot, &"heat_warning", event_id)
			_flash_weapon(Color(1.0, 0.68, 0.24, 1.0), 0.16 if event_id == &"heat_critical" else 0.10)
		&"overheated":
			if not _play_snapshot_sound(heat_player, snapshot, &"overheat_start", event_id):
				_play_snapshot_sound(heat_player, snapshot, &"overheat_loop", event_id)
			_spawn_vent_vfx()
			_flash_weapon(Color(1.0, 0.22, 0.12, 1.0), 0.22)
		&"overheat_recovered":
			_play_snapshot_sound(heat_player, snapshot, &"overheat_recovered", event_id)
			_flash_weapon(Color(0.70, 1.0, 0.65, 1.0), 0.18)


func _play_snapshot_sound(player: AudioStreamPlayer2D, snapshot: Dictionary, sound_id: StringName, event_id: StringName) -> bool:
	var path := str(snapshot.get("sound_%s" % String(sound_id), "")).strip_edges()
	if path.is_empty():
		_warn_missing_once(
			StringName("unconfigured_%s_%s" % [String(snapshot.get("weapon_id", "unknown")), String(sound_id)]),
			"[WeaponFeedbackPresenter] LOUD MISSING ASSET: weapon '%s' has no '%s' sound for '%s'; feedback continues silently." % [snapshot.get("weapon_id", "unknown"), sound_id, event_id]
		)
		return false
	if not ResourceLoader.exists(path):
		_warn_missing_once(
			StringName("missing_%s" % path),
			"[WeaponFeedbackPresenter] LOUD MISSING ASSET: configured sound cannot be loaded: %s; feedback continues silently." % path
		)
		return false
	var stream := load(path) as AudioStream
	if stream == null:
		_warn_missing_once(StringName("invalid_%s" % path), "[WeaponFeedbackPresenter] LOUD INVALID ASSET: sound path is not AudioStream: %s; feedback continues silently." % path)
		return false
	player.stream = stream
	player.play()
	return true


func _spawn_vent_vfx() -> void:
	var barrel := _operator.get_node_or_null("PrimaryWeaponSocket/Barrel") if _operator != null else null
	if barrel == null:
		_warn_missing_once(&"missing_barrel", "[WeaponFeedbackPresenter] LOUD MISSING SOCKET: PrimaryWeaponSocket/Barrel unavailable; vent VFX skipped, gameplay continues.")
		return
	var vent := VENT_VFX_SCENE.instantiate()
	barrel.add_child(vent)


func _flash_weapon(color: Color, duration: float) -> void:
	var sprite := _operator.get_node_or_null("PrimaryWeaponSocket/PrimaryWeaponSprite") as CanvasItem if _operator != null else null
	if sprite == null:
		_warn_missing_once(&"missing_weapon_sprite", "[WeaponFeedbackPresenter] LOUD MISSING PRESENTATION NODE: PrimaryWeaponSprite unavailable; heat tint skipped.")
		return
	if _sprite_tween != null and _sprite_tween.is_valid():
		_sprite_tween.kill()
	sprite.modulate = color
	_sprite_tween = create_tween()
	_sprite_tween.tween_property(sprite, "modulate", Color.WHITE, maxf(0.01, duration))


func _warn_missing_once(key: StringName, message: String) -> void:
	if _missing_asset_warnings.has(key):
		return
	_missing_asset_warnings[key] = true
	push_warning(message)
