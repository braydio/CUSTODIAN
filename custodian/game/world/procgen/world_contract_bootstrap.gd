extends Node
class_name WorldContractBootstrapService

signal generation_started(seed: int)
signal contract_ready(contract: Dictionary)
signal generation_failed(result: Dictionary)

enum State {
	IDLE,
	GENERATING,
	READY,
	FAILED,
	CLAIMED,
}

const CONTRACT_MAP_SCENE := preload(
	"res://game/world/procgen/custodian_contract_map.tscn"
)

var state: State = State.IDLE
var run_seed: int = 0
var contract: Dictionary = {}
var failure: Dictionary = {}
var prewarm_start_ms: int = 0
var prewarm_ready_ms: int = 0
var prewarm_duration_ms: int = 0
var prewarm_ready_before_terminal: bool = false
var transition_wait_ms: int = 0
var generation_started_scene: String = ""
var generation_count: int = 0

var _generator: Node = null
var _terminal_requested_ms: int = 0
var _generator_scene: PackedScene = CONTRACT_MAP_SCENE


func ensure_started(seed: int = 0) -> void:
	if state in [State.GENERATING, State.READY, State.CLAIMED]:
		return
	reset()
	run_seed = seed if seed != 0 else randi()
	if run_seed == 0:
		run_seed = 1
	_generator = _generator_scene.instantiate()
	_generator.name = "PrewarmedContractGenerator"
	if _generator is CanvasItem:
		(_generator as CanvasItem).visible = false
	_generator.set("auto_generate_on_ready", false)
	_generator.set("randomize_seed_on_ready", false)
	add_child(_generator)
	_generator.connect("contract_generated", Callable(self, "_on_generated"))
	_generator.connect(
		"contract_generation_failed",
		Callable(self, "_on_failed")
	)
	state = State.GENERATING
	prewarm_start_ms = Time.get_ticks_msec()
	var current_scene := get_tree().current_scene
	generation_started_scene = (
		String(current_scene.scene_file_path)
		if current_scene != null
		else ""
	)
	generation_count += 1
	generation_started.emit(run_seed)
	_generator.call("generate_contract", run_seed)


func get_latest_contract() -> Dictionary:
	return contract


func get_latest_generation_failure() -> Dictionary:
	return failure


func get_state() -> State:
	return state


func is_ready() -> bool:
	return state in [State.READY, State.CLAIMED]


func mark_terminal_requested() -> void:
	_terminal_requested_ms = Time.get_ticks_msec()
	prewarm_ready_before_terminal = is_ready()
	transition_wait_ms = 0


func mark_claimed() -> void:
	if state == State.READY:
		state = State.CLAIMED
	if _terminal_requested_ms > 0:
		transition_wait_ms = maxi(
			0,
			Time.get_ticks_msec() - _terminal_requested_ms
		)


func get_metrics() -> Dictionary:
	return {
		"prewarm_start_ms": prewarm_start_ms,
		"prewarm_ready_ms": prewarm_ready_ms,
		"prewarm_duration_ms": prewarm_duration_ms,
		"prewarm_ready_before_terminal": prewarm_ready_before_terminal,
		"transition_wait_ms": transition_wait_ms,
		"generation_started_scene": generation_started_scene,
		"generation_count": generation_count,
		"state": State.keys()[state],
		"run_seed": run_seed,
	}


func reset() -> void:
	contract = {}
	failure = {}
	state = State.IDLE
	run_seed = 0
	prewarm_start_ms = 0
	prewarm_ready_ms = 0
	prewarm_duration_ms = 0
	prewarm_ready_before_terminal = false
	transition_wait_ms = 0
	generation_started_scene = ""
	generation_count = 0
	_terminal_requested_ms = 0
	if _generator != null and is_instance_valid(_generator):
		var generated_callback := Callable(self, "_on_generated")
		var failed_callback := Callable(self, "_on_failed")
		if _generator.is_connected("contract_generated", generated_callback):
			_generator.disconnect("contract_generated", generated_callback)
		if _generator.is_connected("contract_generation_failed", failed_callback):
			_generator.disconnect("contract_generation_failed", failed_callback)
		if _generator.get_parent() == self:
			remove_child(_generator)
		_generator.queue_free()
	_generator = null


func set_generator_scene_for_testing(scene: PackedScene) -> void:
	if state != State.IDLE:
		push_error(
			"[WorldContractBootstrap] Generator override requires IDLE state"
		)
		return
	_generator_scene = scene if scene != null else CONTRACT_MAP_SCENE


func restore_generator_scene() -> void:
	if state == State.IDLE:
		_generator_scene = CONTRACT_MAP_SCENE


func _on_generated(value: Dictionary) -> void:
	if state != State.GENERATING:
		return
	contract = value
	failure = {}
	state = State.READY
	prewarm_ready_ms = Time.get_ticks_msec()
	prewarm_duration_ms = maxi(0, prewarm_ready_ms - prewarm_start_ms)
	if _terminal_requested_ms > 0:
		transition_wait_ms = maxi(0, prewarm_ready_ms - _terminal_requested_ms)
	contract_ready.emit(contract)


func _on_failed(value: Dictionary) -> void:
	if state != State.GENERATING:
		return
	contract = {}
	failure = value
	state = State.FAILED
	prewarm_ready_ms = Time.get_ticks_msec()
	prewarm_duration_ms = maxi(0, prewarm_ready_ms - prewarm_start_ms)
	if _terminal_requested_ms > 0:
		transition_wait_ms = maxi(0, prewarm_ready_ms - _terminal_requested_ms)
	generation_failed.emit(failure)
