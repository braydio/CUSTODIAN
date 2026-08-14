extends RefCounted
class_name SunderedKeepVistaContract

# Distances use generated route-centerline arc length in tile-cell units.
const INFLUENCE_START_FROM_GATE_CELLS := 52.0
const KEEP_DISCOVERY_FROM_GATE_CELLS := 44.0
const VISTA_APEX_FROM_GATE_CELLS := 36.0
const MOONLIGHT_FROM_GATE_CELLS := 32.0
const APEX_PLATEAU_END_FROM_GATE_CELLS := 28.0
const GAMEPLAY_RETURN_FROM_GATE_CELLS := 16.0

const S_INFLUENCE_START := 0.0
const S_KEEP_DISCOVERY := 8.0
const S_VISTA_BUILD := 12.0
const S_VISTA_APEX := 16.0
const S_MOONLIGHT := 20.0
const S_APEX_END := 24.0
const S_RETURN_1 := 28.0
const S_RETURN_2 := 32.0
const S_GAMEPLAY_RETURN := 36.0
const S_GATE := 52.0

const MAX_CAMERA_DISPLACEMENT_CELLS := 18.0
const GAMEPLAY_ZOOM := 0.90
const VISTA_APEX_ZOOM := 0.80

const CAMERA_WEIGHT_KEYS := [
	[0.0, 0.0], [4.0, 0.15], [8.0, 0.50], [12.0, 0.82],
	[16.0, 1.0], [20.0, 1.0], [24.0, 1.0], [28.0, 0.78],
	[32.0, 0.35], [36.0, 0.0],
]
const CAMERA_ZOOM_KEYS := [
	[0.0, 0.900], [4.0, 0.885], [8.0, 0.850], [12.0, 0.820],
	[16.0, 0.800], [20.0, 0.800], [24.0, 0.800], [28.0, 0.825],
	[32.0, 0.865], [36.0, 0.900],
]
const CAMERA_OFFSET_Y_KEYS := [
	[0.0, 0.0], [4.0, -16.0], [8.0, -48.0], [12.0, -78.0],
	[16.0, -96.0], [20.0, -96.0], [24.0, -96.0], [28.0, -72.0],
	[32.0, -36.0], [36.0, 0.0],
]

const RUINS_ALPHA_KEYS := [
	[0.0, 0.15], [8.0, 0.48], [12.0, 0.75], [16.0, 0.88],
	[20.0, 0.84], [24.0, 0.78], [28.0, 0.68], [32.0, 0.48],
	[36.0, 0.22],
]
const KEEP_ALPHA_KEYS := [
	[0.0, 0.02], [8.0, 0.12], [12.0, 0.35], [16.0, 0.58],
	[20.0, 0.74], [24.0, 0.80], [28.0, 0.74], [32.0, 0.58],
	[36.0, 0.34],
]
const SEAM_FOG_ALPHA_KEYS := [
	[0.0, 0.12], [8.0, 0.14], [12.0, 0.16], [16.0, 0.16],
	[20.0, 0.16], [24.0, 0.16], [28.0, 0.16], [32.0, 0.14],
	[36.0, 0.12],
]


static func sample_spatial_key_curve(keys: Array, s: float) -> float:
	if keys.is_empty():
		return 0.0
	if s <= float(keys[0][0]):
		return float(keys[0][1])
	for index in range(1, keys.size()):
		var right: Array = keys[index]
		if s == float(right[0]):
			return float(right[1])
		if s < float(right[0]):
			var left: Array = keys[index - 1]
			var t := (s - float(left[0])) / (float(right[0]) - float(left[0]))
			t = t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
			return lerpf(float(left[1]), float(right[1]), t)
	return float(keys[-1][1])
