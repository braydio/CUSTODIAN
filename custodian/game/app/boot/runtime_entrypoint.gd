extends Node

const StartupMode = preload("res://game/app/boot/startup_mode.gd")

const MODE_SCENES := {
	"awakening": "res://scenes/awakening_first_return.tscn",
	"twin-solaria": "res://scenes/twin_solaria_playtest.tscn",
	"contract-sandbox": "res://scenes/game.tscn",
}

@export var start_on_ready := true


func _ready() -> void:
	if start_on_ready:
		call_deferred("start", OS.get_cmdline_user_args())


func start(args: PackedStringArray = PackedStringArray()) -> void:
	var decision := StartupMode.parse_args(args) as Dictionary
	var warning := String(decision.get("warning", ""))
	if not warning.is_empty():
		push_warning("[RuntimeEntrypoint] %s" % warning)

	var mode := String(decision.get("mode", "awakening"))
	var target := scene_for_mode(mode)
	if not ResourceLoader.exists(target, "PackedScene"):
		push_error("[RuntimeEntrypoint] Startup scene is missing: %s" % target)
		return

	if mode == "contract-sandbox":
		var bootstrap := _get_contract_bootstrap()
		if bootstrap == null:
			push_error("[RuntimeEntrypoint] WorldContractBootstrap autoload is missing")
			return
		var seed: Variant = decision.get("seed")
		if seed == null:
			bootstrap.call("ensure_started")
		else:
			bootstrap.call("ensure_started", int(seed))
	elif mode == "awakening":
		var transition_manager := get_node_or_null("/root/WorldTransitionManager")
		if transition_manager != null:
			transition_manager.call("arm_for_startup_awakening")

	var error := _change_scene_to_file(target)
	if error != OK:
		push_error("[RuntimeEntrypoint] Could not load startup scene %s (error %d)" % [target, error])


static func scene_for_mode(mode: String) -> String:
	return String(MODE_SCENES.get(mode, MODE_SCENES["awakening"]))


func _change_scene_to_file(target: String) -> Error:
	return get_tree().change_scene_to_file(target)


func _get_contract_bootstrap() -> Node:
	return get_node_or_null("/root/WorldContractBootstrap")
