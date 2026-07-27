@tool
extends Resource
class_name HumanoidCutoutRigSkin

@export var skin_id: StringName = &""
@export var south_atlas: Texture2D
@export var north_atlas: Texture2D
@export var east_atlas: Texture2D
@export var west_atlas: Texture2D
@export var profile: HumanoidCutoutRigProfile
@export var default_modulate: Color = Color.WHITE
@export var enable_east_to_west_mirroring: bool = true


func get_atlas(direction: StringName) -> Texture2D:
	match direction:
		&"n":
			return north_atlas
		&"e":
			return east_atlas
		&"w":
			if west_atlas != null:
				return west_atlas
			if enable_east_to_west_mirroring:
				return east_atlas
			return null
		_:
			return south_atlas


func has_required_atlases() -> bool:
	return south_atlas != null and north_atlas != null and east_atlas != null


func uses_mirrored_west() -> bool:
	return west_atlas == null and enable_east_to_west_mirroring and east_atlas != null
