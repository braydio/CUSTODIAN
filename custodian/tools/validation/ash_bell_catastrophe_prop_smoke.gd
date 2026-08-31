extends SceneTree

const LOWER_QUARTER := "res://game/world/levels/authored/ash_bell/lower_quarter/lower_quarter.tscn"
const MANIFEST := "res://content/metadata/assets/meridian_civic_ruins_native.semantic.json"
const NativeProp := preload("res://game/world/levels/presentation/semantic_native_prop_2d.gd")
const EXPECTED_ZONES := {
	"arrival": 12,
	"direct_collapse": 22,
	"evacuation_arcade": 18,
	"lower_market": 22,
	"civic_basin": 8,
	"wrong_street": 4,
	"answers_court": 6,
	"station_approach": 10,
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(LOWER_QUARTER) as PackedScene
	_assert(packed != null, "Lower Quarter scene loads")
	var level := packed.instantiate()
	root.add_child(level)
	await process_frame
	var props_root := level.get_node("PropsRoot")
	var civic := props_root.get_node("NativeCivicPropRoot") as LowerQuarterNativePropLayer2D
	var catastrophe := props_root.get_node("NativeCatastrophePropRoot") as AshBellCatastrophePropLayer2D
	_assert(civic != null, "surviving civic layer remains distinct")
	_assert(catastrophe != null, "catastrophe layer exists")
	_assert(props_root.has_node("LaterPenitentAdditions"), "later Penitent additions remain distinct")
	_assert(civic.get_errors().is_empty(), "surviving civic layer has no errors")
	_assert(catastrophe.get_errors().is_empty(), "catastrophe layer has no errors")
	_assert(civic.get_debug_snapshot().size() == 104, "surviving civic placement count")
	var snapshot := catastrophe.get_debug_snapshot()
	_assert(snapshot.size() == 102, "catastrophe placement count")
	var zones: Dictionary = {}
	var seen_ids: Dictionary = {}
	for item: Dictionary in snapshot:
		var placement_id := String(item.get("placement_id", ""))
		_assert(not seen_ids.has(placement_id), "unique placement %s" % placement_id)
		seen_ids[placement_id] = true
		var zone := String(item.get("zone", ""))
		zones[zone] = int(zones.get(zone, 0)) + 1
		_assert(item.get("scale") == Vector2.ONE, "%s native scale" % placement_id)
		_assert(not bool(item.get("collision_enabled", true)), "%s collision disabled" % placement_id)
		_assert(not String(item.get("resolved_texture", "")).is_empty(), "%s texture resolves" % placement_id)
	_assert(zones == EXPECTED_ZONES, "runtime zone counts")
	_assert(not NativeProp.can_spawn_production(MANIFEST, &"meridian_ruins_debris", &"broken_wall_section"), "compound wall cannot spawn generically")
	_assert(not NativeProp.can_spawn_production(MANIFEST, &"meridian_ruins_debris", &"breached_wall_corner"), "compound corner cannot spawn generically")
	print("ash_bell_catastrophe_prop_smoke: PASS civic=104 catastrophe=102 history_layers=3")
	level.queue_free()
	await process_frame
	quit(0)


func _assert(condition: bool, label: String) -> void:
	if not condition:
		push_error("ash_bell_catastrophe_prop_smoke failed: %s" % label)
		quit(1)
