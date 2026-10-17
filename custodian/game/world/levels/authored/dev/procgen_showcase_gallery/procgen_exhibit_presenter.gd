extends CanvasLayer
class_name ProcgenExhibitPresenter

const CATALOG := preload("res://game/world/levels/authored/dev/procgen_showcase_gallery/procgen_exhibit_catalog.gd")

var _entries: Array[Dictionary] = []
var _wing := "terrain"
var _selected_index := 0
var _wing_tabs: OptionButton
var _exhibits: ItemList
var _title: Label
var _detail: Label
var _readout: Label
var _preview: TextureRect


func _ready() -> void:
	var report: Dictionary = CATALOG.load_report()
	_entries = report.get("valid", [])
	_build_ui()
	if not report.get("failures", []).is_empty():
		_detail.text = "Catalog unavailable: " + "; ".join(report.failures)
		return
	_refresh_list()


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.name = "ExhibitCatalogPanel"
	panel.position = Vector2(16, 16)
	panel.custom_minimum_size = Vector2(390, 0)
	add_child(panel)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	var heading := Label.new()
	heading.text = "PROCGEN EXHIBITS · INSPECT ONLY"
	layout.add_child(heading)
	_wing_tabs = OptionButton.new()
	for wing in CATALOG.WINGS:
		_wing_tabs.add_item(wing.to_upper())
		_wing_tabs.set_item_metadata(_wing_tabs.item_count - 1, wing)
	_wing_tabs.item_selected.connect(_on_wing_selected)
	layout.add_child(_wing_tabs)
	_exhibits = ItemList.new()
	_exhibits.custom_minimum_size = Vector2(350, 100)
	_exhibits.item_selected.connect(_on_exhibit_selected)
	layout.add_child(_exhibits)
	_title = Label.new()
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_title)
	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_detail)
	_readout = Label.new()
	_readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_readout)
	_preview = TextureRect.new()
	_preview.custom_minimum_size = Vector2(320, 120)
	_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layout.add_child(_preview)


func _on_wing_selected(index: int) -> void:
	_wing = String(_wing_tabs.get_item_metadata(index))
	_selected_index = 0
	_refresh_list()


func _on_exhibit_selected(index: int) -> void:
	_selected_index = index
	_show_selected()


func _refresh_list() -> void:
	_exhibits.clear()
	var in_wing: Array[Dictionary] = []
	for entry in _entries:
		if entry.wing == _wing:
			in_wing.append(entry)
			_exhibits.add_item("%s · %s" % ["AVAILABLE" if entry.status == "available" else "N/A", entry.title])
	if in_wing.is_empty():
		_title.text = _wing.to_upper()
		_detail.text = "No validated catalog entry."
		_readout.text = ""
		_preview.texture = null
		return
	_selected_index = clampi(_selected_index, 0, in_wing.size() - 1)
	_exhibits.select(_selected_index)
	_show_entry(in_wing[_selected_index])


func _show_selected() -> void:
	var in_wing: Array[Dictionary] = []
	for entry in _entries:
		if entry.wing == _wing:
			in_wing.append(entry)
	if _selected_index >= 0 and _selected_index < in_wing.size():
		_show_entry(in_wing[_selected_index])


func _show_entry(entry: Dictionary) -> void:
	_title.text = String(entry.get("title", ""))
	_detail.text = String(entry.get("reason", entry.get("detail", "")))
	_readout.text = String(entry.get("readout", "Source: %s · %s" % [entry.get("source_authority_path", "N/A"), entry.get("source_authority_id", "N/A")]))
	_preview.texture = entry.get("texture", null)
