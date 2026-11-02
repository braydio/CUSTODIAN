extends Node2D

@export var review_skin: HumanoidCutoutRigSkin

@onready var enemy: CharacterBody2D = $EnemyHumanoidCutoutTest
@onready var gameplay_rig: HumanoidCutoutRig2D = (
	$EnemyHumanoidCutoutTest/HumanoidCutoutRig2D
)
@onready var closeup_rig: HumanoidCutoutRig2D = (
	$CloseupPreview/HumanoidCutoutRig2D
)
@onready var debug_toggle: CheckButton = (
	$UI/Panel/Margin/VBox/DebugOverlay
)


func _ready() -> void:
	if review_skin != null:
		gameplay_rig.set_skin(review_skin)
		closeup_rig.set_skin(review_skin)

	enemy.set_physics_process(false)

	_connect_buttons(
		"Directions",
		[&"n", &"s", &"e", &"w"],
		_set_direction
	)

	_connect_buttons(
		"States",
		[&"idle", &"run", &"attack_light", &"hit_react", &"death"],
		_play_state
	)

	debug_toggle.toggled.connect(_set_debug)

	_set_direction(&"s")
	_play_state(&"idle")


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_UP:
			_set_direction(&"n")
		KEY_DOWN:
			_set_direction(&"s")
		KEY_RIGHT:
			_set_direction(&"e")
		KEY_LEFT:
			_set_direction(&"w")
		KEY_1:
			_play_state(&"idle")
		KEY_2:
			_play_state(&"run")
		KEY_3:
			_play_state(&"attack_light")
		KEY_4:
			_play_state(&"hit_react")
		KEY_5:
			_play_state(&"death")
		KEY_D:
			debug_toggle.button_pressed = not debug_toggle.button_pressed


func _connect_buttons(
	group_name: String,
	values: Array[StringName],
	callback: Callable
) -> void:
	var row := (
		$UI/Panel/Margin/VBox.get_node(group_name)
		as HBoxContainer
	)

	for value in values:
		var button := row.get_node(String(value)) as Button
		button.pressed.connect(callback.bind(value))


func _set_direction(direction: StringName) -> void:
	gameplay_rig.set_direction_code(direction)
	closeup_rig.set_direction_code(direction)


func _play_state(state: StringName) -> void:
	gameplay_rig.reset_to_rest_pose()
	closeup_rig.reset_to_rest_pose()

	gameplay_rig.play_state(state, true)
	closeup_rig.play_state(state, true)


func _set_debug(enabled: bool) -> void:
	for rig: HumanoidCutoutRig2D in [gameplay_rig, closeup_rig]:
		rig.show_pivots = enabled
		rig.show_part_bounds = enabled
		rig.show_baseline = enabled
		rig.queue_redraw()
