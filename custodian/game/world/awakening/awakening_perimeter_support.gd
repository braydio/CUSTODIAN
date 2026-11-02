extends Node2D
class_name AwakeningPerimeterSupport

## Optional, presentation-only support for the existing Awakening room plates.
## Missing Asset V2 outputs are deliberately not loaded and never replace the
## neutral AwakeningVoidBackdrop.

const STATE_SIZES := {
	"structural_support": Vector2i(512, 512),
	"distant_structures": Vector2i(1024, 512),
	"edge_transition": Vector2i(256, 256),
}

const ZONE_FAMILIES := {
	1: {"family": "awakening_creche_perimeter_support", "owner": "awakening_creche", "zone": "01_creche"},
	2: {"family": "awakening_ambulatory_perimeter_support", "owner": "awakening_ambulatory", "zone": "02_ambulatory"},
	3: {"family": "awakening_attestation_perimeter_support", "owner": "awakening_attestation", "zone": "03_attestation"},
	4: {"family": "awakening_locker_reliquary_perimeter_support", "owner": "awakening_locker_reliquary", "zone": "04_locker_reliquary"},
	6: {"family": "awakening_undergate_perimeter_support", "owner": "awakening_undergate", "zone": "06_undergate"},
	7: {"family": "awakening_gate_of_dust_perimeter_support", "owner": "awakening_gate_of_dust", "zone": "07_gate_of_dust"},
	8: {"family": "awakening_approach_perimeter_support", "owner": "awakening_approach", "zone": "08_approach"},
	9: {"family": "awakening_late_service_perimeter_support", "owner": "awakening_late_service", "zone": "09_late_service"},
	10: {"family": "awakening_road_south_reach_perimeter_support", "owner": "awakening_road_south_reach", "zone": "10_road_south_reach"},
}

const SUPPORT_LAYER_Z := -1
const STATE_ORDER := ["structural_support", "distant_structures", "edge_transition"]
const RUNTIME_STATE_PATHS := [
	"res://content/levels/awakening/perimeter_support/01_creche/awakening_creche_structural_support_512x512.png",
	"res://content/levels/awakening/perimeter_support/01_creche/awakening_creche_distant_structures_1024x512.png",
	"res://content/levels/awakening/perimeter_support/01_creche/awakening_creche_edge_transition_256x256.png",
	"res://content/levels/awakening/perimeter_support/02_ambulatory/awakening_ambulatory_structural_support_512x512.png",
	"res://content/levels/awakening/perimeter_support/02_ambulatory/awakening_ambulatory_distant_structures_1024x512.png",
	"res://content/levels/awakening/perimeter_support/02_ambulatory/awakening_ambulatory_edge_transition_256x256.png",
	"res://content/levels/awakening/perimeter_support/03_attestation/awakening_attestation_structural_support_512x512.png",
	"res://content/levels/awakening/perimeter_support/03_attestation/awakening_attestation_distant_structures_1024x512.png",
	"res://content/levels/awakening/perimeter_support/03_attestation/awakening_attestation_edge_transition_256x256.png",
	"res://content/levels/awakening/perimeter_support/04_locker_reliquary/awakening_locker_reliquary_structural_support_512x512.png",
	"res://content/levels/awakening/perimeter_support/04_locker_reliquary/awakening_locker_reliquary_distant_structures_1024x512.png",
	"res://content/levels/awakening/perimeter_support/04_locker_reliquary/awakening_locker_reliquary_edge_transition_256x256.png",
	"res://content/levels/awakening/perimeter_support/06_undergate/awakening_undergate_structural_support_512x512.png",
	"res://content/levels/awakening/perimeter_support/06_undergate/awakening_undergate_distant_structures_1024x512.png",
	"res://content/levels/awakening/perimeter_support/06_undergate/awakening_undergate_edge_transition_256x256.png",
	"res://content/levels/awakening/perimeter_support/07_gate_of_dust/awakening_gate_of_dust_structural_support_512x512.png",
	"res://content/levels/awakening/perimeter_support/07_gate_of_dust/awakening_gate_of_dust_distant_structures_1024x512.png",
	"res://content/levels/awakening/perimeter_support/07_gate_of_dust/awakening_gate_of_dust_edge_transition_256x256.png",
	"res://content/levels/awakening/perimeter_support/08_approach/awakening_approach_structural_support_512x512.png",
	"res://content/levels/awakening/perimeter_support/08_approach/awakening_approach_distant_structures_1024x512.png",
	"res://content/levels/awakening/perimeter_support/08_approach/awakening_approach_edge_transition_256x256.png",
	"res://content/levels/awakening/perimeter_support/09_late_service/awakening_late_service_structural_support_512x512.png",
	"res://content/levels/awakening/perimeter_support/09_late_service/awakening_late_service_distant_structures_1024x512.png",
	"res://content/levels/awakening/perimeter_support/09_late_service/awakening_late_service_edge_transition_256x256.png",
	"res://content/levels/awakening/perimeter_support/10_road_south_reach/awakening_road_south_reach_structural_support_512x512.png",
	"res://content/levels/awakening/perimeter_support/10_road_south_reach/awakening_road_south_reach_distant_structures_1024x512.png",
	"res://content/levels/awakening/perimeter_support/10_road_south_reach/awakening_road_south_reach_edge_transition_256x256.png",
]

var placement_plan: Array[Dictionary] = []
var loaded_state_count := 0


func configure(layout_script: Script) -> void:
	z_index = SUPPORT_LAYER_Z
	placement_plan = build_placement_plan(layout_script.ZONES)
	_load_available_states()


static func build_placement_plan(zones: Array) -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	for zone_variant: Variant in zones:
		var zone := zone_variant as Dictionary
		var index := int(zone.get("index", 0))
		if not ZONE_FAMILIES.has(index):
			continue # Zone 05 is owned by Dust Lung V2, never generic perimeter.
		var envelope: Rect2 = zone["envelope"]
		var support_rect := envelope.grow(64.0)
		var center := support_rect.get_center()
		var family := String(ZONE_FAMILIES[index]["family"])
		var owner := String(ZONE_FAMILIES[index]["owner"])
		var zone_folder := String(ZONE_FAMILIES[index]["zone"])
		var positions := {
			"structural_support": center,
			"distant_structures": center + Vector2(-384.0, -256.0),
			"edge_transition": center + Vector2(-160.0, -160.0),
		}
		for state in STATE_ORDER:
			var size: Vector2i = STATE_SIZES[state]
			var filename := "%s_%s_%dx%d.png" % [owner, state, size.x, size.y]
			var resource_path := "res://content/levels/awakening/perimeter_support/%s/%s" % [zone_folder, filename]
			if not RUNTIME_STATE_PATHS.has(resource_path):
				continue
			plan.append({
				"zone_index": index,
				"zone_id": String(zone["id"]),
				"family": family,
				"state": state,
				"frame_size": STATE_SIZES[state],
				"resource_path": resource_path,
				"support_bounds": support_rect,
				"position": positions[state],
				"z_index": SUPPORT_LAYER_Z,
				"collision_free": true,
			})
	return plan


func _load_available_states() -> void:
	loaded_state_count = 0
	for item in placement_plan:
		var size := item["frame_size"] as Vector2i
		var path := String(item["resource_path"])
		if not ResourceLoader.exists(path):
			continue
		var texture := load(path) as Texture2D
		if texture == null or Vector2i(texture.get_size()) != size:
			continue
		var sprite := Sprite2D.new()
		sprite.name = "%s_%s" % [item["family"], item["state"]]
		sprite.texture = texture
		sprite.position = item["position"]
		sprite.z_index = SUPPORT_LAYER_Z
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
		loaded_state_count += 1


func get_debug_state() -> Dictionary:
	return {
		"planned_state_count": placement_plan.size(),
		"loaded_state_count": loaded_state_count,
		"zone_family_count": ZONE_FAMILIES.size(),
		"zone05_registered": false,
		"collision_free": true,
		"placements": placement_plan.duplicate(true),
	}
