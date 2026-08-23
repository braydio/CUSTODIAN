class_name ProcgenUnderlayProfile
extends Resource

@export var profile_id: StringName = &""
@export_group("Far")
@export var far_variants: Array[Texture2D] = []
@export_range(0.0, 1.0, 0.01) var far_alpha := 0.30
@export_group("Middle")
@export var middle_variants: Array[Texture2D] = []
@export_range(0.0, 1.0, 0.01) var middle_alpha := 0.90
@export_group("Near")
@export var near_variants: Array[Texture2D] = []
@export_range(0.0, 1.0, 0.01) var near_alpha := 0.48

func is_valid() -> bool:
	return not far_variants.is_empty() and not middle_variants.is_empty() and not near_variants.is_empty()

func validate_dimensions(expected := Vector2i(1536, 1024)) -> bool:
	if not is_valid(): return false
	for texture in far_variants + middle_variants + near_variants:
		if texture == null or texture.get_size() != Vector2(expected): return false
	return true
