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
var _refresh_inspector_button: Button
var _inspector: Node
var _inspector_label: Label
var _inspector_layout: VBoxContainer
var _layer_buttons: Dictionary = {}


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


func bind_inspector(inspector: Node) -> void:
	_inspector = inspector
	for layer in ["terrain", "route", "playability", "sites", "vistas"]:
		var toggle := CheckButton.new()
		toggle.text = layer.to_upper()
		toggle.toggled.connect(_on_overlay_toggled.bind(layer))
		_layer_buttons[layer] = toggle
		_inspector_layout.add_child(toggle)
	if is_instance_valid(_inspector):
		refresh_inspector_snapshot(_inspector.call("get_snapshot"))


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


func refresh_inspector_snapshot(snapshot: Dictionary) -> void:
	if not is_instance_valid(_inspector_label):
		return
	if snapshot.is_empty():
		_inspector_label.text = "INSPECTOR · waiting for accepted world"
		return
	var counts: Dictionary = snapshot.get("counts", {})
	var provenance: Array = snapshot.get("exhibit_provenance", [])
	var provenance_ids: Array[String] = []
	for entry: Variant in provenance:
		if entry is Dictionary:
			provenance_ids.append(str(entry.get("exhibit_id", "")))
	var provenance_text := ", ".join(provenance_ids) if not provenance_ids.is_empty() else "unavailable"
	var spawn_text := "VALID" if bool(snapshot.get("spawn_valid", false)) and bool(snapshot.get("spawn_navigation_walkable", false)) else "UNAVAILABLE"
	_inspector_label.text = "INSPECTOR · %s · spawn %s\nfloor %d · walls %d · route %d · sites %d · component %d\nCATALOG MATCH: %s" % [
		str(snapshot.get("generation_fingerprint", "—")).substr(0, 12),
		spawn_text,
		int(counts.get("floor", 0)),
		int(counts.get("walls", 0)),
		int(counts.get("route", 0)),
		int(counts.get("sites", 0)),
		int(snapshot.get("playable_component_count", 0)),
		provenance_text,
	]


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.name = "GenerationControlsPanel"
	panel.position = Vector2(420, 16)
	panel.custom_minimum_size = Vector2(410, 0)
	add_child(panel)
	_inspector_layout = VBoxContainer.new()
	panel.add_child(_inspector_layout)
	var heading := Label.new()
	heading.text = "PROCGEN ARENA · GENERATION CONTROLS"
	_inspector_layout.add_child(heading)
	_status_label = Label.new()
	_status_label.text = "IDLE"
	_inspector_layout.add_child(_status_label)
	_preset_select = OptionButton.new()
	_preset_select.item_selected.connect(_on_preset_selected)
	_inspector_layout.add_child(_preset_select)
	_seed_input = SpinBox.new()
	_seed_input.min_value = 0
	_seed_input.max_value = 2147483647
	_seed_input.step = 1
	_seed_input.value = 417203
	_seed_input.value_changed.connect(_on_seed_changed)
	_inspector_layout.add_child(_seed_input)
	_same_seed_button = Button.new()
	_same_seed_button.text = "REGENERATE SAME SEED"
	_same_seed_button.pressed.connect(_on_regenerate_same_seed)
	_inspector_layout.add_child(_same_seed_button)
	_reroll_button = Button.new()
	_reroll_button.text = "REROLL WITH THIS SEED"
	_reroll_button.pressed.connect(_on_reroll)
	_inspector_layout.add_child(_reroll_button)
	_cancel_button = Button.new()
	_cancel_button.text = "CANCEL STAGING"
	_cancel_button.pressed.connect(_on_cancel)
	_inspector_layout.add_child(_cancel_button)
	_error_label = Label.new()
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.modulate = Color("#ef9b82")
	_inspector_layout.add_child(_error_label)
	_inspector_label = Label.new()
	_inspector_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inspector_label.text = "INSPECTOR · waiting for accepted world"
	_inspector_layout.add_child(_inspector_label)
	var overlay_heading := Label.new()
	overlay_heading.text = "READ-ONLY OVERLAYS"
	_inspector_layout.add_child(overlay_heading)
	_refresh_inspector_button = Button.new()
	_refresh_inspector_button.text = "REFRESH ACCEPTED SNAPSHOT"
	_refresh_inspector_button.pressed.connect(_on_refresh_inspector)
	_inspector_layout.add_child(_refresh_inspector_button)


func _on_overlay_toggled(enabled: bool, layer: String) -> void:
	if is_instance_valid(_inspector):
		_inspector.call("set_layer_enabled", layer, enabled)


func _on_refresh_inspector() -> void:
	if is_instance_valid(_inspector):
		_inspector.call("refresh_snapshot")


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
