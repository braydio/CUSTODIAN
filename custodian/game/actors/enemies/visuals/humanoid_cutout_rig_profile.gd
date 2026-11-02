@tool
extends Resource
class_name HumanoidCutoutRigProfile

const DEFAULT_DRAW_ORDER := {
	"cape": -50,
	"back_attachment": -45,
	"upper_arm_back": -40,
	"forearm_back": -39,
	"hand_back": -38,
	"thigh_back": -30,
	"shin_back": -29,
	"foot_back": -28,
	"pelvis": 0,
	"torso": 10,
	"head": 20,
	"thigh_front": 30,
	"shin_front": 31,
	"foot_front": 32,
	"upper_arm_front": 40,
	"forearm_front": 41,
	"hand_front": 42,
	"weapon": 50,
	"front_attachment": 60,
	"reserved": 70,
}

@export_group("Canvas")
@export var frame_size: Vector2i = Vector2i(96, 96)
@export var frame_center: Vector2 = Vector2(48, 48)
@export var ground_y: float = 82.0
@export var visual_offset: Vector2 = Vector2.ZERO

@export_group("Core Anchors")
@export var pelvis_anchor: Vector2 = Vector2(48, 58)
@export var torso_anchor: Vector2 = Vector2(48, 48)
@export var head_anchor: Vector2 = Vector2(48, 31)

@export_group("Arm Anchors")
@export var far_shoulder_anchor: Vector2 = Vector2(42, 43)
@export var far_elbow_anchor: Vector2 = Vector2(38, 54)
@export var far_wrist_anchor: Vector2 = Vector2(39, 64)
@export var near_shoulder_anchor: Vector2 = Vector2(54, 43)
@export var near_elbow_anchor: Vector2 = Vector2(59, 54)
@export var near_wrist_anchor: Vector2 = Vector2(58, 64)

@export_group("Leg Anchors")
@export var far_hip_anchor: Vector2 = Vector2(44, 59)
@export var far_knee_anchor: Vector2 = Vector2(42, 69)
@export var far_ankle_anchor: Vector2 = Vector2(42, 79)
@export var near_hip_anchor: Vector2 = Vector2(52, 59)
@export var near_knee_anchor: Vector2 = Vector2(54, 69)
@export var near_ankle_anchor: Vector2 = Vector2(54, 79)

@export_group("Equipment Anchors")
@export var weapon_anchor: Vector2 = Vector2(58, 61)
@export var weapon_grip_anchor: Vector2 = Vector2(58, 61)
@export var weapon_tip_anchor: Vector2 = Vector2(72, 48)
@export var cape_anchor: Vector2 = Vector2(48, 40)
@export var back_attachment_anchor: Vector2 = Vector2(43, 45)
@export var front_attachment_anchor: Vector2 = Vector2(54, 48)

@export_group("Direction Draw Orders")
@export var south_draw_order: Dictionary = DEFAULT_DRAW_ORDER.duplicate(true)
@export var north_draw_order: Dictionary = DEFAULT_DRAW_ORDER.duplicate(true)
@export var east_draw_order: Dictionary = DEFAULT_DRAW_ORDER.duplicate(true)
@export var west_draw_order: Dictionary = DEFAULT_DRAW_ORDER.duplicate(true)

@export_group("Direction Overrides")
## Direction keys are n/e/s/w. Values are dictionaries keyed by pivot semantic
## name (for example "head" or "near_shoulder") with Vector2 coordinates.
@export var per_direction_pivot_overrides: Dictionary = {}
## Direction keys are n/e/s/w. Values are Vector2 offsets applied to the full
## 96x96 atlas coordinate system.
@export var per_direction_atlas_offsets: Dictionary = {}


func get_draw_order(direction: StringName) -> Dictionary:
	match direction:
		&"n":
			return north_draw_order
		&"e":
			return east_draw_order
		&"w":
			return west_draw_order
		_:
			return south_draw_order


func get_pivot(direction: StringName, pivot_name: StringName, fallback: Vector2) -> Vector2:
	var overrides: Variant = per_direction_pivot_overrides.get(String(direction), {})
	if overrides is Dictionary:
		var value: Variant = (overrides as Dictionary).get(String(pivot_name), fallback)
		if value is Vector2:
			return value as Vector2
	return fallback


func get_atlas_offset(direction: StringName) -> Vector2:
	var value: Variant = per_direction_atlas_offsets.get(String(direction), Vector2.ZERO)
	return value as Vector2 if value is Vector2 else Vector2.ZERO
