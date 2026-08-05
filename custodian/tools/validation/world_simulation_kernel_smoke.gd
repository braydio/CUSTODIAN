extends SceneTree

const WORLD_STATE_PATH := "res://game/state/world/world_simulation_state.gd"
const KERNEL_PATH := "res://game/systems/simulation/simulation_kernel.gd"
const CLOCK_PATH := "res://game/systems/simulation/simulation_clock.gd"
const SNAPSHOT_PATH := "res://game/state/world/simulation_snapshot.gd"
const HUB_PATH := "res://game/state/persistent/hub_state.gd"
const SESSION_PATH := "res://game/state/run/campaign_session.gd"

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var world_script: Script = load(WORLD_STATE_PATH)
	var kernel_script: Script = load(KERNEL_PATH)
	var clock_script: Script = load(CLOCK_PATH)
	var snapshot_script: Script = load(SNAPSHOT_PATH)
	var hub_script: Script = load(HUB_PATH)
	var session_script: Script = load(SESSION_PATH)
	var hub = hub_script.new(1337)
	var session = session_script.new()
	_assert(session.get("world") != null, "campaign session did not create transient world state")
	var outcome = session.to_outcome("ABANDONED", "smoke")
	hub.apply_campaign_outcome(outcome)
	_assert((hub.snapshot().get("campaign_history", []) as Array).size() == 1, "campaign outcome did not enter persistent history")
	var first = kernel_script.new(world_script.new(1337))
	var second = kernel_script.new(world_script.new(1337))
	for kernel in [first, second]:
		kernel.queue("set_policy", {"repair_intensity": 3, "defense_readiness": 2, "fabrication_allocation": 1})
		kernel.queue("damage_structure", {"structure_id": "COMMAND_CORE", "amount": 7, "source": "smoke"})
	for index in range(120):
		first.step_once()
		second.step_once()
	_assert(first.state.fingerprint() == second.state.fingerprint(), "same seed and command stream diverged")
	_assert(first.state.tick == 120 and second.state.tick == 120, "kernel tick did not advance deterministically")
	_assert(first.state.structures["COMMAND_CORE"].hp == 93, "typed damage command did not mutate state")
	_assert(first.state.logistics_pressure >= 0.0, "logistics pressure became invalid")
	_assert(first.state.events.size() > 0, "kernel did not emit state events")

	var paused_clock = clock_script.new()
	paused_clock.paused = true
	var steps: int = paused_clock.advance(1.0, func() -> void: pass)
	_assert(steps == 0, "paused clock advanced simulation")
	_assert(paused_clock.accumulator == 0.0, "paused clock accumulated presentation time")
	paused_clock.paused = false
	steps = paused_clock.advance(float(clock_script.get("FIXED_DT")) * 2.0, func() -> void: pass)
	_assert(steps == 2, "clock did not resume with fixed steps")

	var snapshot = snapshot_script.new(first.get("state"))
	_assert(snapshot.tick == first.state.tick, "snapshot tick mismatch")
	_assert(snapshot.fingerprint == first.state.fingerprint(), "snapshot fingerprint mismatch")
	_assert((snapshot.to_dict().get("state", {}) as Dictionary).get("snapshot_version", 0) == int(world_script.get("SNAPSHOT_VERSION")), "snapshot schema version missing")

	if failures.is_empty():
		print("WORLD_SIMULATION_KERNEL_SMOKE: PASS")
		quit(0)
		return
	for failure in failures:
		push_error("[WorldSimulationKernelSmoke] %s" % failure)
	quit(1)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
