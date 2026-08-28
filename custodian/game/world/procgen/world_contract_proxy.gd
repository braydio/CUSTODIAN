extends Node2D
class_name WorldContractProxy

signal contract_generated(contract: Dictionary)
signal contract_generation_failed(result: Dictionary)


func _ready() -> void:
	var bootstrap := _get_bootstrap()
	if bootstrap == null:
		push_error("[WorldContractProxy] WorldContractBootstrap autoload missing")
		return
	var ready_callback := Callable(self, "_on_contract_ready")
	var failure_callback := Callable(self, "_on_generation_failed")
	if not bootstrap.is_connected("contract_ready", ready_callback):
		bootstrap.connect("contract_ready", ready_callback)
	if not bootstrap.is_connected("generation_failed", failure_callback):
		bootstrap.connect("generation_failed", failure_callback)
	call_deferred("_publish_latest_state")
	if int(bootstrap.call("get_state")) == 0:
		# Compatibility for direct game.tscn/debug launches. Generation still
		# belongs to the persistent bootstrap and occurs only once.
		bootstrap.call_deferred("ensure_started")


func _exit_tree() -> void:
	var bootstrap := _get_bootstrap()
	if bootstrap == null:
		return
	var ready_callback := Callable(self, "_on_contract_ready")
	var failure_callback := Callable(self, "_on_generation_failed")
	if bootstrap.is_connected("contract_ready", ready_callback):
		bootstrap.disconnect("contract_ready", ready_callback)
	if bootstrap.is_connected("generation_failed", failure_callback):
		bootstrap.disconnect("generation_failed", failure_callback)


func get_latest_contract() -> Dictionary:
	var bootstrap := _get_bootstrap()
	return bootstrap.call("get_latest_contract") if bootstrap != null else {}


func get_latest_generation_failure() -> Dictionary:
	var bootstrap := _get_bootstrap()
	return (
		bootstrap.call("get_latest_generation_failure")
		if bootstrap != null
		else {}
	)


func _publish_latest_state() -> void:
	var bootstrap := _get_bootstrap()
	if bootstrap == null:
		return
	var latest := bootstrap.call("get_latest_contract") as Dictionary
	if not latest.is_empty():
		_on_contract_ready(latest)
		return
	var latest_failure := (
		bootstrap.call("get_latest_generation_failure") as Dictionary
	)
	if not latest_failure.is_empty():
		_on_generation_failed(latest_failure)


func _on_contract_ready(value: Dictionary) -> void:
	contract_generated.emit(value)


func _on_generation_failed(value: Dictionary) -> void:
	contract_generation_failed.emit(value)


func _get_bootstrap() -> Node:
	return get_node_or_null("/root/WorldContractBootstrap")
