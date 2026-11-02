extends SceneTree

const FIELD := preload("res://game/world/procgen/biomes/biome_field.gd")

func _init() -> void:
	var floor := {}
	for y in 64:
		for x in 64: floor[Vector2i(x,y)] = true
	var terrain := {"terrain_type_by_cell":{},"height_by_cell":{}}
	var a: Dictionary = FIELD.new().build(floor,terrain,4421,{})
	var b: Dictionary = FIELD.new().build(floor,terrain,4421,{})
	_require(a.biome_id_by_cell == b.biome_id_by_cell,"same seed changed biome field")
	_require(a.biome_id_by_cell.size() == floor.size(),"biome coverage mismatch")
	var valid := {&"scrubland":true,&"woodland":true,&"wetland":true,&"rocky_upland":true}
	for cell in a.biome_id_by_cell:
		_require(floor.has(cell) and valid.has(a.biome_id_by_cell[cell]),"invalid biome cell")
	var count_sum := 0
	for count in (a.counts as Dictionary).values(): count_sum += int(count)
	_require(count_sum == floor.size(),"biome counts mismatch")
	var wet: Dictionary = FIELD.new().build(floor,terrain,4421,{"biome_moisture_bias":0.25})
	var dry: Dictionary = FIELD.new().build(floor,terrain,4421,{"biome_moisture_bias":-0.25})
	var wet_count := int(wet.counts.get(&"wetland",0)) + int(wet.counts.get(&"woodland",0))
	var dry_count := int(dry.counts.get(&"wetland",0)) + int(dry.counts.get(&"woodland",0))
	_require(wet_count > dry_count,"wet climate did not increase wet biomes")
	var rock_types := {}
	for cell in floor: rock_types[cell] = 5
	var rocky: Dictionary = FIELD.new().build(floor,{"terrain_type_by_cell":rock_types},9,{})
	_require(int(rocky.counts.get(&"rocky_upland",0)) == floor.size(),"rock terrain was not forced upland")
	print("biome_field_smoke: PASS cells=%d wet=%d dry=%d" % [floor.size(),wet_count,dry_count]); quit(0)

func _require(condition: bool, message: String) -> void:
	if condition: return
	push_error("biome_field_smoke: " + message); quit(1)
