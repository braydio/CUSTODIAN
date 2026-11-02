extends Node
class_name ItemFactory

const SHRUMB_DROPS_PATH = "res://content/items/shrumb_drops/shrumb_drops.json"
const ICON_PATH = "res://content/ui/inventory/icons/icon_%s.png"

static func load_all_items() -> Array:
	var file = FileAccess.open(SHRUMB_DROPS_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to load: " + SHRUMB_DROPS_PATH)
		return []
	
	var json_text: String = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		push_error("Failed to parse JSON")
		return []
	
	var data: Dictionary = json.data
	var items: Array = data.get("items", [])
	var resources: Array = []
	
	for item_data in items:
		var resource = create_item_from_dict(item_data)
		if resource:
			resources.append(resource)
	
	return resources

static func create_item_from_dict(data: Dictionary) -> ItemResource:
	var item = ItemResource.new()
	item.item_id = data.get("item_id", "")
	item.display_name = data.get("display_name", "Unknown")
	item.description = data.get("description", "")
	item.stack_size = data.get("stack_size", 1)
	item.rarity = data.get("rarity", "common")
	item.stackable = item.stack_size > 1
	
	# Load icon
	var icon_path = ICON_PATH % item.item_id
	var texture = load(icon_path)
	if texture:
		item.icon = texture
	else:
		item.icon = load("res://content/ui/inventory/icons/icon_placeholder.png")
	
	return item
