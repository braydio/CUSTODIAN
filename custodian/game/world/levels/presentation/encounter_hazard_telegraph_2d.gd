class_name EncounterHazardTelegraph2D
extends Node2D

enum State {
	SUPPRESSED,
	DORMANT,
	WARNING,
	ACTIVE,
}

@export var decal_path: NodePath
@export var warning_sprite_path: NodePath
@export var activation_sprite_path: NodePath

@onready var decal: Sprite2D = get_node_or_null(decal_path)
@onready var warning_sprite: AnimatedSprite2D = get_node_or_null(warning_sprite_path)
@onready var activation_sprite: AnimatedSprite2D = get_node_or_null(activation_sprite_path)

var _state: State = State.SUPPRESSED


func _ready() -> void:
	if activation_sprite != null and not activation_sprite.animation_finished.is_connected(
		_on_activation_finished
	):
		activation_sprite.animation_finished.connect(_on_activation_finished)
	_apply_state(false)


func set_presentation_state(next_state: State) -> void:
	if next_state == _state:
		return
	var entered_active := next_state == State.ACTIVE and _state != State.ACTIVE
	_state = next_state
	_apply_state(entered_active)


func get_presentation_state() -> State:
	return _state


func _apply_state(play_activation: bool) -> void:
	if decal != null:
		decal.visible = true
		match _state:
			State.SUPPRESSED:
				decal.modulate.a = 0.06
			State.DORMANT:
				decal.modulate.a = 0.18
			State.WARNING:
				decal.modulate.a = 0.48
			State.ACTIVE:
				decal.modulate.a = 0.75
	if warning_sprite != null:
		warning_sprite.visible = _state in [State.WARNING, State.ACTIVE]
		if warning_sprite.visible:
			if not warning_sprite.is_playing():
				warning_sprite.play(&"warning")
		else:
			warning_sprite.stop()
	if activation_sprite != null:
		if play_activation:
			activation_sprite.visible = true
			activation_sprite.play(&"activate")
		elif not activation_sprite.is_playing():
			activation_sprite.visible = false


func _on_activation_finished() -> void:
	if activation_sprite != null:
		activation_sprite.visible = false
