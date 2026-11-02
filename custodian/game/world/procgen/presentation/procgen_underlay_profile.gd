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

@export_group("Depth Motion")
## Fraction of camera travel each layer lags behind (0 = locked to the camera,
## the pre-continuation behaviour). Displacement is bounded by parallax_max_px.
@export_range(0.0, 0.2, 0.005) var far_parallax := 0.0
@export_range(0.0, 0.2, 0.005) var middle_parallax := 0.0
@export_range(0.0, 0.2, 0.005) var near_parallax := 0.0
@export_range(0.0, 256.0, 1.0) var parallax_max_px := 0.0
## When true the backdrop scales the plates so supported viewport/zoom/parallax
## combinations can never expose unpainted canvas.
@export var guarantee_viewport_coverage := false

## Opaque tone painted behind FAR so transparent gaps in sparse plates never
## expose the engine clear colour. Alpha 0 (default) paints nothing.
@export var base_fill_color := Color(0.0, 0.0, 0.0, 0.0)

func has_depth_motion() -> bool:
	return parallax_max_px > 0.0 and (far_parallax > 0.0 or middle_parallax > 0.0 or near_parallax > 0.0)

func is_valid() -> bool:
	return not far_variants.is_empty() and not middle_variants.is_empty() and not near_variants.is_empty()

func validate_dimensions(expected := Vector2i(1536, 1024)) -> bool:
	if not is_valid(): return false
	for texture in far_variants + middle_variants + near_variants:
		if texture == null or texture.get_size() != Vector2(expected): return false
	return true
