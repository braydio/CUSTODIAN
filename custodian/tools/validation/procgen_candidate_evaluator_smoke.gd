extends SceneTree

const EVALUATOR_SCRIPT := preload("res://game/world/procgen/generation/candidate_evaluator.gd")


func _init() -> void:
	var evaluator: Variant = EVALUATOR_SCRIPT.new()
	var settings := {
		"pre_terrain_required_connectivity_min": 0.95,
		"terrain_rescue_reject_threshold": 200,
		"min_connected_room_ratio": 0.75,
		"require_compound_ingress_connectivity": true,
	}
	var passing := {
		"layout_valid": true,
		"candidate_valid": true,
		"connected_ratio": 1.0,
		"ingress_ratio": 1.0,
		"pre_terrain_connected_required_ratio": 1.0,
		"terrain_fallback": false,
		"terrain_connectivity": true,
		"terrain_rescue_carved": 0,
	}
	assert(evaluator.is_candidate_acceptable(passing, settings))
	assert(is_equal_approx(evaluator.score_candidate(passing, settings), 1.1))
	assert(not evaluator.is_candidate_acceptable({
		"layout_valid": true,
		"candidate_valid": false,
		"connected_ratio": 1.0,
		"ingress_ratio": 1.0,
	}, settings))
	var terrain_failure := passing.duplicate(true)
	terrain_failure["pre_terrain_connected_required_ratio"] = 0.22
	terrain_failure["terrain_rescue_carved"] = 5248
	assert(not evaluator.is_candidate_acceptable(terrain_failure, settings))
	assert(evaluator.is_terrain_failed_candidate(terrain_failure, settings))
	assert(is_equal_approx(evaluator.score_candidate(terrain_failure, settings), -0.9))
	assert(not evaluator.can_use_degraded_fallback({}, settings))
	var degraded := passing.duplicate(true)
	degraded["required_ingresses_valid"] = true
	degraded["terrain_rescue_carved"] = 201
	assert(evaluator.can_use_degraded_fallback(degraded, settings))
	assert(evaluator.is_better_fallback_candidate(0.4, false, 0.9, true))
	assert(not evaluator.is_better_fallback_candidate(0.8, true, 0.9, false))
	var missing: Dictionary = evaluator.evaluate_candidate(null, {}, settings)
	var missing_metrics: Dictionary = missing.get("metrics", {})
	assert(missing_metrics.get("rejection_reasons", []) == ["missing_map_instance"])
	assert(not missing.has("node") and not missing.has("map_instance") and not missing_metrics.has("map_instance"), "Evaluation result must remain data-only.")
	evaluator = null
	print("[ProcgenCandidateEvaluatorSmoke] ok")
	quit(0)
