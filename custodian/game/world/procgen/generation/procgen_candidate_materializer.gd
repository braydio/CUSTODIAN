extends RefCounted
class_name ProcgenCandidateMaterializer

## Owns the accepted-candidate handoff from semantic selection to one final
## runtime realization. Structural TileMaps already belong to the selected
## candidate; ProcGenTilemap applies the deferred final-only phases.

const SEMANTIC_ADAPTER_SCRIPT := preload(
	"res://game/world/procgen/generation/candidate_semantic_adapter.gd"
)
const SEMANTIC_SCHEMA := "custodian.procgen_candidate_semantic_model.v1"

var _semantic_adapter: Variant = SEMANTIC_ADAPTER_SCRIPT.new()


func materialize(candidate: Dictionary, map_instance: ProcGenTilemap) -> Dictionary:
	if map_instance == null:
		return _failure("missing_final_procgen_tilemap")

	var acceptance_mode := String(candidate.get("acceptance_mode", ""))
	if acceptance_mode != "accepted" and acceptance_mode != "degraded_fallback":
		return _failure("candidate_not_selected_for_materialization")

	var snapshot: Dictionary = candidate.get("semantic_snapshot", {})
	if String(snapshot.get("schema", "")) != SEMANTIC_SCHEMA:
		return _failure("unsupported_semantic_candidate_schema")
	var supplied_fingerprint := String(snapshot.get("fingerprint", ""))
	if supplied_fingerprint.is_empty() \
			or supplied_fingerprint != _semantic_adapter.fingerprint_snapshot(snapshot):
		return _failure("semantic_candidate_fingerprint_mismatch")

	var evaluation: Dictionary = candidate.get("evaluation", {})
	if acceptance_mode == "accepted" and not bool(evaluation.get("accepted", false)):
		return _failure("candidate_evaluation_did_not_accept")
	if acceptance_mode == "degraded_fallback" \
			and bool(evaluation.get("accepted", false)):
		return _failure("degraded_fallback_must_be_explicit")

	var result: Dictionary = map_instance.materialize_accepted_candidate(snapshot)
	if not bool(result.get("ok", false)):
		return result
	var report: Dictionary = result.get("report", {}).duplicate(true)
	report["acceptance_mode"] = acceptance_mode
	report["semantic_fingerprint"] = supplied_fingerprint
	return {
		"ok": true,
		"level_data": result.get("level_data", {}),
		"report": report,
	}


func _failure(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}
