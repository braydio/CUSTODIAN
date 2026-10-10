class_name HubCampaignSelectionAuthority
extends Node

const DEFAULT_FIRST_SCENARIO_SEED := 1
const SCENARIO_FACTORY := preload(
	"res://game/state/run/default_campaign_scenario_factory.gd"
)
const BOOTSTRAP_PATH := NodePath("/root/WorldContractBootstrap")
const BOOTSTRAP_STATE_NAMES := {
	0: "IDLE",
	1: "GENERATING",
	2: "READY",
	3: "FAILED",
	4: "CLAIMED",
}

var hub_state: HubState
var _bootstrap: Node
var _provisional_scenario: CampaignScenario


func _ready() -> void:
	if hub_state == null:
		hub_state = HubState.new(DEFAULT_FIRST_SCENARIO_SEED)
	_bootstrap = get_node_or_null(BOOTSTRAP_PATH)
	_provisional_scenario = hub_state.get_accepted_scenario()
	if _provisional_scenario == null:
		var seed := hub_state.seed if hub_state.seed != 0 else DEFAULT_FIRST_SCENARIO_SEED
		_provisional_scenario = SCENARIO_FACTORY.create_scenario(seed)


func accept_first_contract() -> Dictionary:
	if hub_state == null:
		return {"ok": false, "code": "HUB_STATE_UNAVAILABLE"}
	if hub_state.get_accepted_scenario() != null:
		return _already_accepted_result()
	if _bootstrap == null or not _bootstrap.has_method("ensure_started"):
		return {"ok": false, "code": "CONTRACT_BOOTSTRAP_UNAVAILABLE"}
	if not _bootstrap.has_method("get_state") or int(_bootstrap.call("get_state")) != 0:
		return {
			"ok": false,
			"code": "CONTRACT_BOOTSTRAP_NOT_IDLE",
			"state": get_preparation_state(),
		}
	if _provisional_scenario == null or _provisional_scenario.seed == 0:
		return {"ok": false, "code": "PROVISIONAL_SCENARIO_INVALID"}

	var acceptance := hub_state.accept_campaign_scenario(_provisional_scenario)
	if not bool(acceptance.get("ok", false)):
		return acceptance

	var initial_generation_count := int(_bootstrap.get("generation_count"))
	_bootstrap.call("ensure_started", _provisional_scenario.seed)
	var started_seed := int(_bootstrap.get("run_seed"))
	var generation_count := int(_bootstrap.get("generation_count"))
	if started_seed != _provisional_scenario.seed \
			or generation_count != initial_generation_count + 1:
		return {
			"ok": false,
			"code": "PREWARM_START_MISMATCH",
			"accepted_seed": _provisional_scenario.seed,
			"bootstrap_seed": started_seed,
			"generation_count": generation_count,
		}

	return {
		"ok": true,
		"code": "CONTRACT_ACCEPTED",
		"scenario": _provisional_scenario,
		"scenario_id": _provisional_scenario.scenario_id,
		"seed": _provisional_scenario.seed,
		"generation_state": get_preparation_state(),
	}


func retry_failed_preparation() -> Dictionary:
	var scenario := get_accepted_scenario()
	if scenario == null:
		return {"ok": false, "code": "SCENARIO_NOT_ACCEPTED"}
	if _bootstrap == null or not _bootstrap.has_method("ensure_started"):
		return {"ok": false, "code": "CONTRACT_BOOTSTRAP_UNAVAILABLE"}
	if get_preparation_state() != "FAILED":
		return {"ok": false, "code": "PREPARATION_NOT_FAILED", "state": get_preparation_state()}
	var previous_generation_count := int(_bootstrap.get("generation_count"))
	_bootstrap.call("ensure_started", scenario.seed)
	if int(_bootstrap.get("run_seed")) != scenario.seed \
			or int(_bootstrap.get("generation_count")) != previous_generation_count + 1:
		return {
			"ok": false,
			"code": "PREPARATION_RETRY_MISMATCH",
			"accepted_seed": scenario.seed,
			"bootstrap_seed": int(_bootstrap.get("run_seed")),
			"generation_count": int(_bootstrap.get("generation_count")),
		}
	return {
		"ok": true,
		"code": "PREPARATION_RETRY_STARTED",
		"seed": scenario.seed,
		"generation_count": int(_bootstrap.get("generation_count")),
	}


func request_campaign_deployment() -> Dictionary:
	var scenario := get_accepted_scenario()
	if scenario == null:
		return {"ok": false, "code": "SCENARIO_NOT_ACCEPTED"}
	if _bootstrap == null or not _bootstrap.has_method("is_ready"):
		return {"ok": false, "code": "CONTRACT_BOOTSTRAP_UNAVAILABLE"}
	if not bool(_bootstrap.call("is_ready")) \
			or get_preparation_state() != "READY" \
			or int(_bootstrap.get("run_seed")) != scenario.seed:
		return {
			"ok": false,
			"code": "PREPARATION_NOT_READY",
			"state": get_preparation_state(),
			"accepted_seed": scenario.seed,
			"bootstrap_seed": int(_bootstrap.get("run_seed")),
		}
	var transition_manager := get_node_or_null("/root/WorldTransitionManager")
	if transition_manager == null or not transition_manager.has_method("request_hub_to_campaign"):
		return {"ok": false, "code": "CAMPAIGN_TRANSITION_UNAVAILABLE"}
	if _bootstrap.has_method("mark_deployment_requested"):
		_bootstrap.call("mark_deployment_requested")
	var accepted := bool(transition_manager.call("request_hub_to_campaign", scenario))
	if not accepted:
		return {
			"ok": false,
			"code": "CAMPAIGN_TRANSITION_REJECTED",
			"reason": str(transition_manager.get("last_rejection_code")),
		}
	return {
		"ok": true,
		"code": "CAMPAIGN_DEPLOYMENT_REQUESTED",
		"scenario_id": scenario.scenario_id,
		"seed": scenario.seed,
		"request_id": str(transition_manager.call("get_active_request_id")),
	}


func get_accepted_scenario() -> CampaignScenario:
	return hub_state.get_accepted_scenario() if hub_state != null else null


func get_preparation_state() -> String:
	if _bootstrap == null or not _bootstrap.has_method("get_state"):
		return "UNAVAILABLE"
	return str(BOOTSTRAP_STATE_NAMES.get(int(_bootstrap.call("get_state")), "UNKNOWN"))


func get_preparation_snapshot() -> Dictionary:
	var scenario := get_accepted_scenario()
	return {
		"accepted_scenario": scenario,
		"accepted_scenario_id": scenario.scenario_id if scenario != null else "",
		"accepted_seed": scenario.seed if scenario != null else 0,
		"generation_state": get_preparation_state(),
		"generation_count": int(_bootstrap.get("generation_count")) if _bootstrap != null else 0,
		"ready": bool(_bootstrap.call("is_ready")) if _bootstrap != null and _bootstrap.has_method("is_ready") else false,
		"failure": _bootstrap.call("get_latest_generation_failure") if _bootstrap != null and _bootstrap.has_method("get_latest_generation_failure") else {},
	}


func get_dais_interaction_prompt() -> String:
	var scenario := get_accepted_scenario()
	if scenario == null:
		if _provisional_scenario == null:
			return "CONTRACT SELECTION UNAVAILABLE"
		return "ACCEPT CONTRACT: %s" % _provisional_scenario.title.to_upper()
	return "CONTRACT ACCEPTED • PREWARM %s" % get_preparation_state()


func _already_accepted_result() -> Dictionary:
	var scenario := get_accepted_scenario()
	return {
		"ok": false,
		"code": "SCENARIO_ALREADY_ACCEPTED",
		"scenario": scenario,
		"scenario_id": scenario.scenario_id if scenario != null else "",
		"seed": scenario.seed if scenario != null else 0,
		"generation_state": get_preparation_state(),
	}
