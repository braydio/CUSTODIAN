extends Resource
class_name ItemResource

@export var item_id: String = ""
@export var display_name: String = "Unknown Item"
@export var description: String = ""
@export var icon: Texture2D
@export var stack_size: int = 1
@export var rarity: String = "common"  # common, uncommon, rare, epic, legendary
@export var stackable: bool = false
@export var metadata: Dictionary = {}
