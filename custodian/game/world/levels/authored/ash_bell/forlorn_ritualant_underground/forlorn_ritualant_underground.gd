extends AuthoredLevel2D
class_name ForlornRitualantUnderground

const BOUNDARY_SEGMENTS := [
	[Vector2(-544.0, -416.0), Vector2(544.0, -416.0)],
	[Vector2(-544.0, -416.0), Vector2(-544.0, 416.0)],
	[Vector2(544.0, -416.0), Vector2(544.0, 416.0)],
	[Vector2(-544.0, 416.0), Vector2(-96.0, 416.0)],
	[Vector2(96.0, 416.0), Vector2(544.0, 416.0)],
]

const AUTHORING_MARKERS := {
	"descent_landing": {
		"node_name": "Spawn_DescentLanding",
		"label": "LOWER DESCENT LANDING",
		"kind": "spawn",
		"position": Vector2(0.0, 224.0),
	},
	"return_world": {
		"node_name": "Exit_ReturnWorld",
		"label": "ASCEND TO SURFACE",
		"kind": "level_exit",
		"position": Vector2(0.0, 404.0),
	},
	"encounter_origin": {
		"node_name": "ForlornRitualantSite",
		"label": "RITUALANT ENCOUNTER ORIGIN",
		"kind": "encounter",
		"position": Vector2(0.0, 0.0),
	},
}


func get_boundary_segments() -> Array:
	return BOUNDARY_SEGMENTS


func get_authoring_markers() -> Dictionary:
	return AUTHORING_MARKERS
