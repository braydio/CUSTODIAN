class_name OperatorDeathCampaignBinding
extends Node
## R1 adapter: campaign authority seals the outcome before transitional Game Over.
const DEATH_REASON := "Custodian eliminated after a fatal strike"
var _handled := false
var death_context: Dictionary = {}

func _ready() -> void:
	get_parent().operator_down.connect(consume_operator_down)

func consume_operator_down(context: Dictionary) -> void:
	if _handled:
		return
	# Latch before resolution signals: listeners may reenter this adapter.
	_handled = true
	death_context = context.duplicate(true)
	var runtime := get_tree().get_first_node_in_group("world_simulation_runtime") as WorldSimulationRuntime
	if runtime != null and runtime.session != null and runtime.session.started and not runtime.session.is_resolved():
		runtime.resolve_campaign(&"FAILURE", DEATH_REASON)
	# No session is fabricated for authored/legacy worlds. R2 replaces this fallback.
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.trigger_game_over(DEATH_REASON)
