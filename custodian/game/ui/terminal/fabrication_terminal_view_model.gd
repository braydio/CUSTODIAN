extends RefCounted
class_name FabricationTerminalViewModel

const CATEGORY_PRIORITY := {
	"defense": 0,
	"structure": 1,
	"support": 2,
	"consumable": 3,
	"power": 4,
	"sensor": 5,
	"archive": 6,
	"utility": 7,
}

const CATEGORY_PURPOSE := {
	"defense": "Automated perimeter defense.",
	"structure": "Field fortification and chokepoint control.",
	"support": "Field repair, sealing, and sustainment.",
	"consumable": "Carried emergency consumables.",
	"power": "Power routing, stability, and backup systems.",
	"sensor": "Detection, relay, and situational awareness.",
	"archive": "Blueprint decoding and archive support.",
	"utility": "General-purpose fabrication support.",
}

const RECIPE_PURPOSE := {
	"barricade_light": "Quick field barricade for lane denial and choke control.",
	"turret_basic": "Automated perimeter defense.",
	"power_bank_patch": "Stabilizes power routing and backup systems.",
	"sensor_pylon_basic": "Basic detection and relay coverage.",
	"archive_sensor_pylon": "Archive-grade relay for recovered blueprint context.",
	"field_sealant_patch": "Seals breaches and stabilizes damaged structures.",
	"lattice_field_patch": "Fabricates one carried emergency repair patch for Operator survival.",
}

const READY_BUILD_ACTIONABLE := {
	"barricade_light": true,
	"turret_basic": true,
}


func build(ui: Node, selected_work_order_id: String = "") -> Dictionary:
	var ledger := _get_node(ui, "/root/ResourceLedger")
	var build_inventory := _get_node(ui, "/root/BuildInventory")
	var fab_pipeline := _get_node(ui, "/root/FabPipeline")
	if ledger == null or build_inventory == null or fab_pipeline == null:
		return _build_offline_view()

	var resources := _call_dictionary(ledger, "get_snapshot")
	var resource_defs := _call_dictionary(ledger, "get_resource_defs")
	var build_tokens := _call_dictionary(build_inventory, "get_snapshot")
	var jobs := _call_array(fab_pipeline, "get_jobs_snapshot")
	var recipes := _call_dictionary(fab_pipeline, "get_all_recipes")
	var completed_unlocks := _call_dictionary(fab_pipeline, "get_completed_unlocks")

	var work_orders := _build_work_orders(ui, recipes, resources, resource_defs, build_tokens, jobs)
	var selected_work_order := _resolve_selected_work_order(work_orders, selected_work_order_id)
	var ready_builds := _build_ready_builds(recipes, build_tokens, resource_defs)
	var in_progress := _build_in_progress_jobs(recipes, jobs, resource_defs)
	var ready_build_counts := _count_ready_build_states(ready_builds)

	if selected_work_order.is_empty() and not work_orders.is_empty():
		selected_work_order = work_orders[0]
		selected_work_order["is_selected"] = true

	var next_action := _build_next_action(selected_work_order, ready_builds, ready_build_counts)

	return {
		"status": {
			"fabricator_state": "ONLINE",
			"queue_summary": "%d in progress" % jobs.size(),
			"ready_build_summary": "%d ready / %d deployable" % [ready_build_counts.get("total", 0), ready_build_counts.get("deployable", 0)],
			"next_action": next_action,
			"first_fabrication_hint": _build_first_fabrication_hint(jobs, build_tokens, completed_unlocks, recipes),
		},
		"work_orders": work_orders,
		"selected_work_order": selected_work_order,
		"in_progress": in_progress,
		"ready_builds": ready_builds,
		"command_help": [
			"FAB START <work_order_id>",
			"FAB QUEUE",
			"FAB CANCEL <slot>",
			"BUILD PLACE <ready_build_id>",
		],
	}


func _build_offline_view() -> Dictionary:
	return {
		"status": {
			"fabricator_state": "OFFLINE",
			"queue_summary": "unavailable",
			"ready_build_summary": "unavailable",
			"next_action": "Check the fabrication autoloads or terminal wiring.",
			"first_fabrication_hint": "",
		},
		"work_orders": [],
		"selected_work_order": {},
		"in_progress": [],
		"ready_builds": [],
		"command_help": [
			"FAB START <work_order_id>",
			"FAB QUEUE",
			"FAB CANCEL <slot>",
			"BUILD PLACE <ready_build_id>",
		],
	}


func get_work_order_display_name(recipe_id: String, recipe: Dictionary) -> String:
	var label := str(recipe.get("label", "")).strip_edges()
	if not label.is_empty():
		return label
	return _titleize(recipe_id)


func get_work_order_purpose(recipe_id: String, recipe: Dictionary) -> String:
	var specific := str(RECIPE_PURPOSE.get(recipe_id, "")).strip_edges()
	if not specific.is_empty():
		return specific
	return _get_purpose_for_recipe(recipe)


func _build_work_orders(ui: Node, recipes: Dictionary, resources: Dictionary, resource_defs: Dictionary, build_tokens: Dictionary, jobs: Array) -> Array[Dictionary]:
	var job_counts := _count_jobs_by_recipe(jobs)
	var rows: Array[Dictionary] = []
	for recipe_id_variant in recipes.keys():
		var recipe_id := str(recipe_id_variant)
		var recipe := (recipes[recipe_id_variant] as Dictionary).duplicate(true)
		recipe["id"] = recipe_id
		var output_type := str(recipe.get("output_type", "build_token"))
		var output_id := str(recipe.get("output_id", recipe_id))
		var category := str(recipe.get("category", "")).to_lower()
		var display_name := get_work_order_display_name(recipe_id, recipe)
		var state := _resolve_work_order_state(ui, recipe, resources, job_counts)
		var ready_build_count := int(build_tokens.get(output_id, 0)) if output_type == "build_token" else 0
		var deployable := _is_ready_build_deployable(recipe_id, recipe)
		rows.append({
			"id": recipe_id,
			"display_name": display_name,
			"state": state,
			"category": category,
			"purpose": get_work_order_purpose(recipe_id, recipe),
			"cost_text": _format_cost_text(recipe.get("cost", {}), resource_defs),
			"have_text": _format_have_text(recipe.get("cost", {}), resources, resource_defs),
			"missing_text": _format_missing_text(recipe.get("cost", {}), resources, resource_defs),
			"cost_rows": _build_cost_rows(recipe.get("cost", {}), resources, resource_defs),
			"build_text": _format_build_text(recipe_id, recipe, display_name, ready_build_count, deployable),
			"result_text": _format_result_text(recipe_id, recipe, display_name, ready_build_count, deployable),
			"action_text": _format_action_text(recipe_id, recipe, state, ready_build_count, deployable),
			"output_id": output_id,
			"output_type": output_type,
			"ready_build_count": ready_build_count,
			"deployable": deployable,
			"job_count": int(job_counts.get(recipe_id, 0)),
			"sort_rank": _work_order_sort_rank(state, ready_build_count, deployable),
			"is_selected": false,
		})

	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var rank_a := int(a.get("sort_rank", 99))
		var rank_b := int(b.get("sort_rank", 99))
		if rank_a != rank_b:
			return rank_a < rank_b
		var category_rank_a := int(CATEGORY_PRIORITY.get(str(a.get("category", "")), 99))
		var category_rank_b := int(CATEGORY_PRIORITY.get(str(b.get("category", "")), 99))
		if category_rank_a != category_rank_b:
			return category_rank_a < category_rank_b
		if bool(a.get("is_selected", false)) != bool(b.get("is_selected", false)):
			return bool(a.get("is_selected", false))
		return str(a.get("display_name", "")) < str(b.get("display_name", ""))
	)
	return rows


func _build_cost_rows(cost: Variant, resources: Dictionary, resource_defs: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if not (cost is Dictionary):
		return rows
	for resource_id_variant in (cost as Dictionary).keys():
		var resource_id := str(resource_id_variant)
		var need := int((cost as Dictionary)[resource_id_variant])
		var have := int(resources.get(resource_id, 0))
		rows.append({
			"id": resource_id,
			"label": _resolve_label(resource_id, resource_defs),
			"need": need,
			"have": have,
			"missing": maxi(need - have, 0),
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("label", "")) < str(b.get("label", ""))
	)
	return rows


func _build_ready_builds(recipes: Dictionary, build_tokens: Dictionary, resource_defs: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for token_id_variant in build_tokens.keys():
		var token_id := str(token_id_variant)
		var count := int(build_tokens[token_id_variant])
		if count <= 0:
			continue
		var recipe := _find_recipe_for_output(recipes, token_id)
		var display_name := _titleize(token_id)
		if not recipe.is_empty():
			display_name = get_work_order_display_name(str(recipe.get("id", token_id)), recipe)
		var deployable := _is_ready_build_deployable(token_id, recipe)
		rows.append({
			"id": token_id,
			"display_name": display_name,
			"count": count,
			"action_text": _get_ready_build_action_text(token_id, deployable),
			"deployment_state": "DEPLOYABLE" if deployable else "STORED",
			"resource_label": _resolve_label(token_id, resource_defs),
			"deployable": deployable,
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var deployable_a := bool(a.get("deployable", false))
		var deployable_b := bool(b.get("deployable", false))
		if deployable_a != deployable_b:
			return deployable_a
		var category_key_a := _get_recipe_category_key_for_ready_build(str(a.get("id", "")))
		var category_key_b := _get_recipe_category_key_for_ready_build(str(b.get("id", "")))
		var category_rank_a := int(CATEGORY_PRIORITY.get(category_key_a, 99))
		var category_rank_b := int(CATEGORY_PRIORITY.get(category_key_b, 99))
		if category_rank_a != category_rank_b:
			return category_rank_a < category_rank_b
		var count_a := int(a.get("count", 0))
		var count_b := int(b.get("count", 0))
		if count_a != count_b:
			return count_a > count_b
		return str(a.get("display_name", "")) < str(b.get("display_name", ""))
	)
	return rows


func _build_in_progress_jobs(recipes: Dictionary, jobs: Array, resource_defs: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for job_variant in jobs:
		if not (job_variant is Dictionary):
			continue
		var job := job_variant as Dictionary
		var recipe_id := str(job.get("recipe_id", ""))
		var recipe := _find_recipe_by_id(recipes, recipe_id)
		var display_name := _titleize(recipe_id)
		if not recipe.is_empty():
			display_name = get_work_order_display_name(recipe_id, recipe)
		var progress := float(job.get("progress", 0.0))
		var duration := maxf(0.0, float(job.get("duration", 0.0)))
		var elapsed := maxf(0.0, float(job.get("elapsed", 0.0)))
		rows.append({
			"id": recipe_id,
			"display_name": display_name,
			"job_id": int(job.get("job_id", 0)),
			"progress_text": "%d%%" % int(round(progress * 100.0)),
			"timing_text": "%.1fs / %.1fs" % [elapsed, duration],
			"action_text": "FAB QUEUE",
			"resource_label": _resolve_label(recipe_id, resource_defs),
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("job_id", 0)) < int(b.get("job_id", 0))
	)
	return rows


func _resolve_selected_work_order(work_orders: Array[Dictionary], selected_work_order_id: String) -> Dictionary:
	if not selected_work_order_id.strip_edges().is_empty():
		for row in work_orders:
			if str(row.get("id", "")) == selected_work_order_id:
				row["is_selected"] = true
				return row
	return _pick_default_work_order(work_orders)


func _pick_default_work_order(work_orders: Array[Dictionary]) -> Dictionary:
	for state in ["READY", "IN PROGRESS", "MISSING MATERIALS", "LOCKED"]:
		for row in work_orders:
			if str(row.get("state", "")) == state:
				if state == "READY" and int(row.get("ready_build_count", 0)) <= 0:
					continue
				row["is_selected"] = true
				return row
	return {}


func _build_next_action(selected_work_order: Dictionary, ready_builds: Array[Dictionary], ready_build_counts: Dictionary) -> String:
	if not ready_builds.is_empty() and int(ready_build_counts.get("deployable", 0)) > 0:
		var ready_build := _pick_deployable_ready_build(ready_builds)
		if not ready_build.is_empty():
			return "Place completed %s with %s." % [
				str(ready_build.get("display_name", "Ready Build")),
				str(ready_build.get("action_text", "BUILD PLACE <ready_build_id>")),
			]

	if selected_work_order.is_empty():
		if not ready_builds.is_empty():
			return "Review the stored ready builds or start a deployable work order."
		return "Start a new work order from the list."

	var state := str(selected_work_order.get("state", ""))
	var display_name := str(selected_work_order.get("display_name", "Work Order"))
	var action_text := str(selected_work_order.get("action_text", ""))
	match state:
		"READY":
			if bool(selected_work_order.get("deployable", false)) and action_text.begins_with("BUILD PLACE "):
				return "Place completed %s with %s." % [display_name, action_text]
			if int(selected_work_order.get("ready_build_count", 0)) > 0:
				return "Stored ready build: %s. Open READY BUILDS for details." % display_name
			return "Start %s with %s." % [display_name, action_text]
		"IN PROGRESS":
			return "Wait for %s to complete or open FAB QUEUE." % display_name
		"MISSING MATERIALS":
			return "Gather missing materials for %s." % display_name
		"CARRIED MAX":
			return "%s carry cap reached. Use a patch before fabricating another." % display_name
		"LOCKED":
			return "Unlock %s before starting it." % display_name
		_:
			return "Review %s in the work-order list." % display_name


func _build_first_fabrication_hint(jobs: Array, build_tokens: Dictionary, completed_unlocks: Dictionary, recipes: Dictionary) -> String:
	if not jobs.is_empty() or not build_tokens.is_empty() or not completed_unlocks.is_empty():
		return ""
	var recipe := _find_recipe_for_output(recipes, "turret_basic")
	if recipe.is_empty():
		return ""
	var display_name := get_work_order_display_name(str(recipe.get("id", "turret_basic")), recipe)
	return "First Fabrication: Start %s. It creates a Ready Build. Leave the terminal, choose placement mode, and place it near a defended lane." % display_name.to_upper()


func _count_ready_build_states(ready_builds: Array[Dictionary]) -> Dictionary:
	var counts := {
		"total": 0,
		"deployable": 0,
		"stored": 0,
	}
	for ready_build in ready_builds:
		counts["total"] = int(counts["total"]) + int(ready_build.get("count", 0))
		if bool(ready_build.get("deployable", false)):
			counts["deployable"] = int(counts["deployable"]) + int(ready_build.get("count", 0))
		else:
			counts["stored"] = int(counts["stored"]) + int(ready_build.get("count", 0))
	return counts


func _pick_deployable_ready_build(ready_builds: Array[Dictionary]) -> Dictionary:
	for ready_build in ready_builds:
		if bool(ready_build.get("deployable", false)):
			return ready_build
	return {}


func _is_ready_build_deployable(recipe_id: String, _recipe: Dictionary) -> bool:
	if bool(READY_BUILD_ACTIONABLE.get(recipe_id, false)):
		return true
	return false


func _get_ready_build_action_text(token_id: String, deployable: bool) -> String:
	if deployable:
		return "BUILD PLACE %s" % token_id
	return "STORED READY BUILD"


func _get_recipe_category_key_for_ready_build(token_id: String) -> String:
	match token_id:
		"turret_basic":
			return "defense"
		"barricade_light":
			return "structure"
		"field_sealant_patch":
			return "support"
		"power_bank_patch":
			return "power"
		"sensor_pylon_basic":
			return "sensor"
		"archive_sensor_pylon":
			return "archive"
		_:
			return "utility"


func _resolve_work_order_state(ui: Node, recipe: Dictionary, resources: Dictionary, job_counts: Dictionary) -> String:
	if int(job_counts.get(str(recipe.get("id", "")), 0)) > 0:
		return "IN PROGRESS"
	if _is_recipe_locked(ui, recipe):
		return "LOCKED"
	if _is_operator_field_patch_recipe(recipe) and _is_operator_field_patch_full(ui):
		return "CARRIED MAX"
	if _can_pay_recipe(recipe, resources):
		return "READY"
	return "MISSING MATERIALS"


func _work_order_sort_rank(state: String, ready_build_count: int, deployable: bool) -> int:
	match state:
		"READY":
			if ready_build_count > 0 and deployable:
				return 0
			if ready_build_count > 0:
				return 1
			return 2
		"IN PROGRESS":
			return 3
		"MISSING MATERIALS":
			return 4
		"CARRIED MAX":
			return 5
		"LOCKED":
			return 6
		_:
			return 7


func _format_build_text(_recipe_id: String, recipe: Dictionary, display_name: String, ready_build_count: int, _deployable: bool) -> String:
	var output_type := str(recipe.get("output_type", "build_token"))
	if output_type == "build_token":
		if ready_build_count > 0:
			return "Creates Ready Build: %s x%d" % [display_name, ready_build_count]
		return "Creates Ready Build: %s" % display_name
	if output_type == "unlock":
		return "Unlocks: %s" % display_name
	if output_type == "operator_consumable" or output_type == "operator_field_patch":
		return "Adds carried consumable: %s" % display_name
	return "Produces: %s" % display_name


func _format_result_text(_recipe_id: String, recipe: Dictionary, display_name: String, ready_build_count: int, _deployable: bool) -> String:
	var output_type := str(recipe.get("output_type", "build_token"))
	var output_id := str(recipe.get("output_id", ""))
	if output_type == "build_token":
		if ready_build_count > 0:
			return "Ready Build: %s x%d" % [display_name, ready_build_count]
		return "Ready Build: %s" % display_name
	if output_type == "unlock":
		return "Unlocks: %s" % display_name
	if output_type == "operator_consumable" or output_type == "operator_field_patch":
		return "Consumable restock: %s" % display_name
	if not output_id.is_empty():
		return "Produces: %s" % output_id
	return "Produces: %s" % display_name


func _format_action_text(recipe_id: String, recipe: Dictionary, state: String, ready_build_count: int, deployable: bool) -> String:
	if state == "LOCKED":
		return "Unlock required"
	if state == "CARRIED MAX":
		return "CARRY CAP REACHED"
	var output_type := str(recipe.get("output_type", "build_token"))
	if output_type == "build_token" and ready_build_count > 0 and deployable:
		return "BUILD PLACE %s" % str(recipe.get("output_id", recipe_id))
	if output_type == "build_token" and ready_build_count > 0:
		return "STORED READY BUILD"
	return "FAB START %s" % recipe_id


func _format_cost_text(cost: Variant, resource_defs: Dictionary) -> String:
	if not (cost is Dictionary):
		return "FREE"
	var parts: Array[String] = []
	for resource_id_variant in (cost as Dictionary).keys():
		var resource_id := str(resource_id_variant)
		var amount := int((cost as Dictionary)[resource_id_variant])
		parts.append("%s %d" % [_resolve_label(resource_id, resource_defs), amount])
	return " / ".join(parts) if not parts.is_empty() else "FREE"


func _format_have_text(cost: Variant, resources: Dictionary, resource_defs: Dictionary) -> String:
	if not (cost is Dictionary):
		return "You have: none"
	var parts: Array[String] = []
	for resource_id_variant in (cost as Dictionary).keys():
		var resource_id := str(resource_id_variant)
		var amount := int(resources.get(resource_id, 0))
		parts.append("%s %d" % [_resolve_label(resource_id, resource_defs), amount])
	return "You have: %s" % (" / ".join(parts) if not parts.is_empty() else "none")


func _format_missing_text(cost: Variant, resources: Dictionary, resource_defs: Dictionary) -> String:
	if not (cost is Dictionary):
		return ""
	var parts: Array[String] = []
	for resource_id_variant in (cost as Dictionary).keys():
		var resource_id := str(resource_id_variant)
		var required := int((cost as Dictionary)[resource_id_variant])
		var owned := int(resources.get(resource_id, 0))
		if owned >= required:
			continue
		parts.append("%s x%d" % [_resolve_label(resource_id, resource_defs), required - owned])
	return "Missing Materials: %s" % (" / ".join(parts) if not parts.is_empty() else "none")


func _get_purpose_for_recipe(recipe: Dictionary) -> String:
	var category := str(recipe.get("category", "")).to_lower()
	return str(CATEGORY_PURPOSE.get(category, "Fabrication support output."))


func _count_jobs_by_recipe(jobs: Array) -> Dictionary:
	var counts: Dictionary = {}
	for job_variant in jobs:
		if not (job_variant is Dictionary):
			continue
		var recipe_id := str((job_variant as Dictionary).get("recipe_id", ""))
		if recipe_id.is_empty():
			continue
		counts[recipe_id] = int(counts.get(recipe_id, 0)) + 1
	return counts


func _find_recipe_by_id(recipes: Dictionary, recipe_id: String) -> Dictionary:
	for recipe_id_variant in recipes.keys():
		var candidate_id := str(recipe_id_variant)
		if candidate_id != recipe_id:
			continue
		var recipe: Dictionary = recipes[recipe_id_variant]
		var copy := recipe.duplicate(true)
		copy["id"] = candidate_id
		return copy
	return {}


func _find_recipe_for_output(recipes: Dictionary, output_id: String) -> Dictionary:
	for recipe_id_variant in recipes.keys():
		var recipe: Dictionary = recipes[recipe_id_variant]
		if str(recipe.get("output_id", recipe_id_variant)) == output_id:
			var copy := recipe.duplicate(true)
			copy["id"] = str(recipe_id_variant)
			return copy
	return {}


func _is_recipe_locked(ui: Node, recipe: Dictionary) -> bool:
	var benefit_id := str(recipe.get("requires_arrn_benefit", "")).strip_edges().to_lower()
	if benefit_id.is_empty():
		return false
	var arrn_manager := _get_node(ui, "/root/ARRNManager")
	if arrn_manager == null or not arrn_manager.has_method("has_benefit"):
		return true
	return not bool(arrn_manager.call("has_benefit", benefit_id))


func _can_pay_recipe(recipe: Dictionary, resources: Dictionary) -> bool:
	var cost: Variant = recipe.get("cost", {})
	if not (cost is Dictionary):
		return true
	for resource_id_variant in (cost as Dictionary).keys():
		var resource_id := str(resource_id_variant)
		var required := int((cost as Dictionary)[resource_id_variant])
		if int(resources.get(resource_id, 0)) < required:
			return false
	return true


func _is_operator_field_patch_recipe(recipe: Dictionary) -> bool:
	var output_type := str(recipe.get("output_type", ""))
	return (output_type == "operator_consumable" or output_type == "operator_field_patch") \
			and str(recipe.get("output_id", "")) == "lattice_field_patch"


func _is_operator_field_patch_full(ui: Node) -> bool:
	var operator := _get_operator(ui)
	if operator == null or not operator.has_method("get_field_patch_status"):
		return true
	var status: Dictionary = operator.call("get_field_patch_status")
	return int(status.get("count", 0)) >= int(status.get("max", 0))


func _get_operator(ui: Node) -> Node:
	if ui != null:
		var tree := ui.get_tree()
		if tree != null:
			var player := tree.get_first_node_in_group("player")
			if player != null:
				return player
		var game_root_operator := ui.get_node_or_null("/root/GameRoot/World/Operator")
		if game_root_operator != null:
			return game_root_operator
		return ui.get_node_or_null("/root/GameRoot/Operator")
	return null


func _resolve_label(resource_id: String, resource_defs: Dictionary) -> String:
	if resource_defs.has(resource_id):
		var resource_def: Variant = resource_defs[resource_id]
		if resource_def is Dictionary:
			var label := str((resource_def as Dictionary).get("label", "")).strip_edges()
			if not label.is_empty():
				return label
	return _titleize(resource_id)


func _describe_build_token(display_name: String) -> String:
	var lowered := display_name.to_lower()
	if lowered.contains("turret"):
		return "turret"
	if lowered.contains("repair"):
		return "repair kit"
	if lowered.contains("sensor"):
		return "sensor kit"
	return lowered


func _titleize(value: String) -> String:
	var trimmed := value.strip_edges()
	if trimmed.is_empty():
		return value
	return trimmed.replace("_", " ").capitalize()


func _get_node(ui: Node, path: String) -> Node:
	if ui == null:
		return null
	return ui.get_node_or_null(path)


func _call_dictionary(node: Node, method_name: String) -> Dictionary:
	if node == null or not node.has_method(method_name):
		return {}
	var result: Variant = node.call(method_name)
	return result if result is Dictionary else {}


func _call_array(node: Node, method_name: String) -> Array:
	if node == null or not node.has_method(method_name):
		return []
	var result: Variant = node.call(method_name)
	return result if result is Array else []
