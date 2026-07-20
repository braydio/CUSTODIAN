extends Node

signal recipes_loaded()
signal job_started(job_id: int, recipe_id: String)
signal job_progressed(job_id: int, recipe_id: String, progress: float)
signal job_completed(job_id: int, recipe_id: String, output_type: String, output_id: String, output_amount: int)
signal job_failed(recipe_id: String, reason: String)
signal unlock_completed(unlock_id: String)

const FabJobScript := preload("res://game/fabrication/fab_job.gd")

@export var recipes_path: String = "res://content/fabrication/fab_recipes.json"

var _recipes: Dictionary = {}
var _jobs: Array = []
var _next_job_id: int = 1
var _completed_unlocks: Dictionary = {}


func _ready() -> void:
	load_recipes()


func _process(delta: float) -> void:
	_tick_jobs(delta)


func load_recipes() -> void:
	_recipes = _load_json_dictionary(recipes_path)
	recipes_loaded.emit()


func get_all_recipes() -> Dictionary:
	var visible: Dictionary = {}
	for recipe_id in _recipes.keys():
		var recipe: Dictionary = (_recipes[recipe_id] as Dictionary).duplicate(true)
		recipe["locked"] = _is_recipe_locked(recipe)
		visible[recipe_id] = recipe
	return visible


func has_recipe(recipe_id: String) -> bool:
	return _recipes.has(recipe_id)


func get_recipe(recipe_id: String) -> Dictionary:
	return (_recipes.get(recipe_id, {}) as Dictionary).duplicate(true)


func get_jobs_snapshot() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for job in _jobs:
		if job != null and job.has_method("to_snapshot"):
			out.append(job.call("to_snapshot"))
	return out


func get_completed_unlocks() -> Dictionary:
	return _completed_unlocks.duplicate(true)


func can_start_recipe(recipe_id: String) -> bool:
	if not _recipes.has(recipe_id):
		return false
	var recipe: Dictionary = _recipes[recipe_id]
	if _is_recipe_locked(recipe):
		return false
	if not _can_accept_recipe_output(recipe):
		return false
	var ledger := _get_resource_ledger()
	if ledger == null:
		return false
	var cost: Dictionary = recipe.get("cost", {})
	return bool(ledger.call("can_pay", cost))


func try_start_recipe(recipe_id: String) -> bool:
	if not _recipes.has(recipe_id):
		job_failed.emit(recipe_id, "Unknown recipe")
		return false

	var ledger := _get_resource_ledger()
	if ledger == null:
		job_failed.emit(recipe_id, "ResourceLedger unavailable")
		return false

	var recipe: Dictionary = (_recipes[recipe_id] as Dictionary).duplicate(true)
	if _is_recipe_locked(recipe):
		job_failed.emit(recipe_id, "ARRN blueprint locked")
		return false
	if not _can_accept_recipe_output(recipe):
		job_failed.emit(recipe_id, "Output carry cap reached")
		return false
	var cost: Dictionary = recipe.get("cost", {})
	if not bool(ledger.call("can_pay", cost)):
		job_failed.emit(recipe_id, "Insufficient resources")
		return false
	if not bool(ledger.call("pay", cost)):
		job_failed.emit(recipe_id, "Payment failed")
		return false

	var job = FabJobScript.new(_next_job_id, recipe_id, recipe)
	_next_job_id += 1
	_jobs.append(job)
	job_started.emit(job.job_id, recipe_id)

	if job.duration <= 0.0:
		_complete_job(job)

	return true


func clear_jobs() -> void:
	_jobs.clear()


func debug_start_recipe_with_grant(recipe_id: String) -> bool:
	var ledger := _get_resource_ledger()
	if ledger != null and ledger.has_method("debug_grant"):
		ledger.call("debug_grant")
	return try_start_recipe(recipe_id)


func _tick_jobs(delta: float) -> void:
	if _jobs.is_empty():
		return
	var fabrication_rate := _get_fabrication_rate_multiplier()
	if fabrication_rate <= 0.0:
		return

	var completed_jobs: Array = []
	for job in _jobs:
		if job == null:
			continue
		var is_complete: bool = bool(job.call("tick", delta * fabrication_rate))
		job_progressed.emit(job.job_id, job.recipe_id, job.call("progress"))
		if is_complete:
			completed_jobs.append(job)

	for job in completed_jobs:
		_complete_job(job)


func _complete_job(job) -> void:
	if not _jobs.has(job):
		return
	_jobs.erase(job)

	var output_type := str(job.recipe.get("output_type", "build_token"))
	var output_id := str(job.recipe.get("output_id", job.recipe_id))
	var output_amount: int = maxi(1, int(job.recipe.get("output_amount", 1)))

	match output_type:
		"build_token":
			var build_inventory := _get_build_inventory()
			if build_inventory != null:
				build_inventory.call("add", output_id, output_amount)
			else:
				push_warning("[FabPipeline] BuildInventory unavailable for output: %s" % output_id)
		"unlock":
			_completed_unlocks[output_id] = int(_completed_unlocks.get(output_id, 0)) + output_amount
			unlock_completed.emit(output_id)
		"resource":
			var ledger := _get_resource_ledger()
			if ledger != null:
				ledger.call("add", output_id, output_amount)
			else:
				push_warning("[FabPipeline] ResourceLedger unavailable for output: %s" % output_id)
		"operator_consumable", "operator_field_patch":
			var operator := _get_operator()
			if output_id == "lattice_field_patch" and operator != null and operator.has_method("add_field_patches"):
				var gained := int(operator.call("add_field_patches", output_amount))
				if gained <= 0:
					push_warning("[FabPipeline] Operator could not accept consumable output: %s" % output_id)
			else:
				push_warning("[FabPipeline] Operator unavailable for consumable output: %s" % output_id)
		_:
			push_warning("[FabPipeline] Unknown fab output type: %s" % output_type)

	job_completed.emit(job.job_id, job.recipe_id, output_type, output_id, output_amount)


func _get_resource_ledger() -> Node:
	return get_node_or_null("/root/ResourceLedger")


func _get_build_inventory() -> Node:
	return get_node_or_null("/root/BuildInventory")


func _get_operator() -> Node:
	var tree := get_tree()
	if tree != null:
		var player := tree.get_first_node_in_group("player")
		if player != null:
			return player
	var game_root_operator := get_node_or_null("/root/GameRoot/World/Operator")
	if game_root_operator != null:
		return game_root_operator
	return get_node_or_null("/root/GameRoot/Operator")


func get_fabrication_rate_multiplier() -> float:
	return _get_fabrication_rate_multiplier()


func _get_fabrication_rate_multiplier() -> float:
	var registry := get_node_or_null("/root/InfrastructureRegistry")
	if registry == null or not registry.has_method("has_service"):
		return 1.0
	if not bool(registry.call("has_service", &"FABRICATION")):
		return 1.0
	return maxf(0.0, float(registry.call("get_service_output", &"FABRICATION")))


func _is_recipe_locked(recipe: Dictionary) -> bool:
	var benefit_id := str(recipe.get("requires_arrn_benefit", "")).strip_edges().to_lower()
	if benefit_id.is_empty():
		return false
	var arrn_manager := get_node_or_null("/root/ARRNManager")
	if arrn_manager == null or not arrn_manager.has_method("has_benefit"):
		return true
	return not bool(arrn_manager.call("has_benefit", benefit_id))


func _can_accept_recipe_output(recipe: Dictionary) -> bool:
	var output_type := str(recipe.get("output_type", "build_token"))
	if output_type != "operator_consumable" and output_type != "operator_field_patch":
		return true
	if str(recipe.get("output_id", "")) != "lattice_field_patch":
		return true
	var operator := _get_operator()
	if operator == null:
		return false
	if not operator.has_method("get_field_patch_status"):
		return false
	var status: Dictionary = operator.call("get_field_patch_status")
	return int(status.get("count", 0)) < int(status.get("max", 0))


func _load_json_dictionary(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		push_warning("[FabPipeline] Missing recipe file: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[FabPipeline] Could not open recipe file: %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return (parsed as Dictionary).duplicate(true)

	push_warning("[FabPipeline] Invalid recipe JSON: %s" % path)
	return {}
