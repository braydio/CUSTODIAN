extends CanvasLayer
class_name ProcgenGalleryControls

var _session: Node
var _presets: Dictionary = {}
var _seed_input: SpinBox
var _preset_select: OptionButton
var _status_label: Label
var _error_label: Label
var _same_seed_button: Button
var _reroll_button: Button
var _cancel_button: Button


func _ready() -> void:
	_build_ui()


func bind_session(session: Node, presets: Dictionary) -> void:
	_session = session
	_presets = presets.duplicate(true)
	_preset_select.clear()
	for preset_id in _presets:
		_preset_select.add_item(str(_presets[preset_id].get("label", preset_id)))
		_preset_select.set_item_metadata(_preset_select.item_count - 1, preset_id)
	if _preset_select.item_count > 0:
		_preset_select.select(0)
		_on_preset_selected(0)
	refresh_status(_session.call("get_session_status"))


func refresh_status(status: Dictionary) -> void:
	if not is_instance_valid(_status_label):
		return
	_status_label.text = "%s · seed %s · %s" % [status.get("state", "IDLE"), status.get("seed", "—"), status.get("preset_id", "no preset")]
	_error_label.text = str(status.get("error", ""))
	var busy := bool(status.get("busy", false))
	var active := bool(status.get("operator_in_arena", false))
	_seed_input.editable = not busy and not active
	_preset_select.disabled = busy or active
	_same_seed_button.disabled = busy or active or _presets.is_empty()
	_reroll_button.disabled = busy or active or _presets.is_empty()
	_cancel_button.disabled = not busy


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.name = "GenerationControlsPanel"
	panel.position = Vector2(16, 16)
	panel.custom_minimum_size = Vector2(410, 0)
	add_child(panel)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	var heading := Label.new()
	heading.text = "PROCGEN ARENA · GENERATION CONTROLS"
	layout.add_child(heading)
	_status_label = Label.new()
	_status_label.text = "IDLE"
	layout.add_child(_status_label)
	_preset_select = OptionButton.new()
	_preset_select.item_selected.connect(_on_preset_selected)
	layout.add_child(_preset_select)
	_seed_input = SpinBox.new()
	_seed_input.min_value = 0
	_seed_input.max_value = 2147483647
	_seed_input.step = 1
	_seed_input.value = 417203
	_seed_input.value_changed.connect(_on_seed_changed)
	layout.add_child(_seed_input)
	_same_seed_button = Button.new()
	_same_seed_button.text = "REGENERATE SAME SEED"
	_same_seed_button.pressed.connect(_on_regenerate_same_seed)
	layout.add_child(_same_seed_button)
	_reroll_button = Button.new()
	_reroll_button.text = "REROLL WITH THIS SEED"
	_reroll_button.pressed.connect(_on_reroll)
	layout.add_child(_reroll_button)
	_cancel_button = Button.new()
	_cancel_button.text = "CANCEL STAGING"
	_cancel_button.pressed.connect(_on_cancel)
	layout.add_child(_cancel_button)
	_error_label = Label.new()
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.modulate = Color("#ef9b82")
	layout.add_child(_error_label)


func _on_seed_changed(value: float) -> void:
	if is_instance_valid(_session):
		_session.call("set_seed", int(value))


func _on_preset_selected(index: int) -> void:
	if is_instance_valid(_session) and index >= 0 and index < _preset_select.item_count:
		_session.call("set_preset", str(_preset_select.get_item_metadata(index)))


func _on_regenerate_same_seed() -> void:
	if is_instance_valid(_session):
		_session.call("regenerate_same_seed")


func _on_reroll() -> void:
	if is_instance_valid(_session):
		_session.call("reroll_explicit_seed", int(_seed_input.value))


func _on_cancel() -> void:
	if is_instance_valid(_session):
		_session.call("cancel_generation")
