class_name IntelDemoState
extends RefCounted

var tick: int = 0
var fidelity: int = IntelProjector.Fidelity.FULL

var _sectors: Array = []


func _init() -> void:
	reset()


func reset() -> void:
	tick = 0
	fidelity = IntelProjector.Fidelity.FULL
	_sectors = [
		{
			"id": "gatehouse",
			"name": "GATEHOUSE",
			"integrity": 100,
			"power": "ONLINE",
			"hostiles": 0,
			"activity": "IDLE",
			"objective": "IDLE",
			"eta": -1,
		},
		{
			"id": "storage",
			"name": "STORAGE",
			"integrity": 100,
			"power": "ONLINE",
			"hostiles": 0,
			"activity": "IDLE",
			"objective": "IDLE",
			"eta": -1,
		},
		{
			"id": "archive",
			"name": "ARCHIVE",
			"integrity": 100,
			"power": "ONLINE",
			"hostiles": 0,
			"activity": "IDLE",
			"objective": "IDLE",
			"eta": -1,
		},
		{
			"id": "relay",
			"name": "RELAY SPIRE",
			"integrity": 100,
			"power": "ONLINE",
			"hostiles": 0,
			"activity": "IDLE",
			"objective": "IDLE",
			"eta": -1,
		},
	]


func advance_step() -> void:
	tick += 1
	match tick:
		1:
			_set_sector("storage", {
				"hostiles": 1,
				"activity": "ENTRY DETECTED",
				"objective": "MOVING",
				"eta": 45,
			})
		2:
			_set_sector("storage", {
				"hostiles": 1,
				"activity": "CONTAINER BREACH",
				"objective": "STEALING",
				"eta": 28,
			})
		3:
			_set_sector("gatehouse", {
				"hostiles": 3,
				"activity": "ASSAULT FORMING",
				"objective": "ATTACKING",
				"eta": 35,
			})
			_set_sector("relay", {
				"integrity": 82,
				"power": "LOW",
			})
		4:
			_set_sector("archive", {
				"integrity": 64,
				"activity": "DATA LOSS RISK",
				"objective": "ATTACKING",
				"eta": 18,
			})
			_set_sector("relay", {
				"integrity": 55,
				"power": "LOW",
			})
		5:
			_set_sector("storage", {
				"hostiles": 1,
				"activity": "LOOT EXIT",
				"objective": "STEALING",
				"eta": 9,
			})
			_set_sector("gatehouse", {
				"hostiles": 5,
				"activity": "BREACH PRESSURE",
				"objective": "ATTACKING",
				"eta": 14,
			})
		6:
			_set_sector("relay", {
				"integrity": 32,
				"power": "OFFLINE",
				"activity": "COMMS COLLAPSE",
				"objective": "ATTACKING",
				"eta": 5,
			})
			fidelity = IntelProjector.Fidelity.FRAGMENTED
		7:
			_set_sector("archive", {
				"integrity": 29,
				"activity": "ARCHIVE BLEED",
				"objective": "ATTACKING",
				"eta": 6,
			})
			fidelity = IntelProjector.Fidelity.LOST
		_:
			_decay_loop()


func cycle_fidelity() -> void:
	fidelity = IntelProjector.next_fidelity(fidelity)


func damage_comms() -> void:
	fidelity = mini(fidelity + 1, IntelProjector.Fidelity.LOST)


func repair_comms() -> void:
	fidelity = maxi(fidelity - 1, IntelProjector.Fidelity.FULL)


func get_truth_sectors() -> Array:
	return _duplicate_sector_array(_sectors)


func get_projected_sectors() -> Array:
	return IntelProjector.project_all_sectors(get_truth_sectors(), fidelity)


func get_header_text() -> String:
	return "CUSTODIAN // INTEL DEMO | T: %03d | FIDELITY: %s" % [
		tick,
		IntelProjector.fidelity_label(fidelity),
	]


func _set_sector(id: String, patch: Dictionary) -> void:
	for sector in _sectors:
		if not (sector is Dictionary):
			continue
		var sector_data: Dictionary = sector as Dictionary
		if sector_data.get("id", "") == id:
			for key in patch.keys():
				sector_data[key] = patch[key]
			return


func _decay_loop() -> void:
	for sector in _sectors:
		if not (sector is Dictionary):
			continue
		var sector_data: Dictionary = sector as Dictionary
		if int(sector_data.get("hostiles", 0)) > 0:
			sector_data["eta"] = maxi(int(sector_data.get("eta", -1)) - 5, 0)
		if sector_data.get("id", "") == "relay" and int(sector_data.get("integrity", 100)) < 100:
			sector_data["integrity"] = maxi(int(sector_data.get("integrity", 100)) - 3, 0)


func _duplicate_sector_array(source: Array) -> Array:
	var result: Array = []
	for sector in source:
		if sector is Dictionary:
			var sector_data: Dictionary = sector as Dictionary
			result.append(sector_data.duplicate(true))
	return result
