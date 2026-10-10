extends SceneTree

const PORT_SCRIPT := preload("res://game/world/hub/hub_continuity_port_interaction.gd")

class FakeAuthority extends Node:
	var state := "GENERATING"
	var retry_count := 0
	var deploy_count := 0
	func get_preparation_state() -> String: return state
	func retry_failed_preparation() -> Dictionary:
		retry_count += 1
		return {"ok": true, "code": "PREPARATION_RETRY_STARTED"}
	func request_campaign_deployment() -> Dictionary:
		deploy_count += 1
		return {"ok": true, "code": "CAMPAIGN_DEPLOYMENT_REQUESTED"}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var map := Node2D.new()
	map.name = "ProductionHubMap"
	root.add_child(map)
	var authority := FakeAuthority.new()
	root.add_child(authority)
	var port := Node2D.new()
	port.set_script(PORT_SCRIPT)
	port.call("configure", authority, map)
	map.add_child(port)
	await process_frame
	assert(port.is_in_group("interactable"))
	assert(port.call("get_interaction_prompt") == "CONTRACT PREPARING • HOLD POSITION")
	assert((port.call("interact", null) as Dictionary).get("code") == "PREPARATION_PENDING")
	assert(authority.retry_count == 0 and authority.deploy_count == 0)
	authority.state = "FAILED"
	assert(port.call("get_interaction_prompt") == "RETRY CONTRACT PREPARATION")
	assert((port.call("interact", null) as Dictionary).get("code") == "PREPARATION_RETRY_STARTED")
	assert(authority.retry_count == 1 and authority.deploy_count == 0)
	authority.state = "READY"
	assert(port.call("get_interaction_prompt") == "DEPLOY THROUGH CONTINUITY PORT")
	assert((port.call("interact", null) as Dictionary).get("code") == "CAMPAIGN_DEPLOYMENT_REQUESTED")
	assert(authority.deploy_count == 1)
	map.queue_free()
	authority.queue_free()
	await process_frame
	print("hub_continuity_port_smoke: PASS")
	quit(0)
