extends SceneTree
var failures: Array[String] = []
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var hub:=HubState.new(1); var session:=CampaignSession.new(DefaultCampaignScenarioFactory.create_scenario(1)); session.start(); var outcome:=session.resolve_once(&"SUCCESS"); outcome.knowledge_delta={"K":2}; check(hub.apply_campaign_outcome(outcome).ok,"first apply failed"); check(not hub.apply_campaign_outcome(outcome).ok,"duplicate accepted"); check(hub.knowledge.K==2 and hub.history.entries.size()==1,"duplicate mutated hub"); check(session.resolve_once(&"FAILED") == null,"second resolution accepted"); var restored:=HubState.restore(hub.snapshot()); check(not restored.apply_campaign_outcome(outcome).ok,"dedup did not survive restore"); var other:=CampaignSession.new(DefaultCampaignScenarioFactory.create_scenario(2)); other.start(); check(restored.apply_campaign_outcome(other.resolve_once(&"SUCCESS")).ok,"separate campaign rejected"); finish()
func check(value: bool, message: String) -> void: if not value: failures.append(message)
func finish() -> void:
	if failures.is_empty():
		print("CAMPAIGN_OUTCOME_EXACTLY_ONCE_SMOKE: PASS")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)
