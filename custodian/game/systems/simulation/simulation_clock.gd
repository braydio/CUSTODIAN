class_name SimulationClock
extends RefCounted
const SIMULATION_HZ := 60
const FIXED_DT := 1.0 / float(SIMULATION_HZ)
const MAX_CATCH_UP_STEPS := 8
var accumulator := 0.0
var fixed_tick := 0
var paused := false
var dropped_steps := 0

func advance(presentation_delta: float, step: Callable) -> int:
	if paused: return 0
	accumulator += maxf(0.0, presentation_delta)
	var steps := 0
	while accumulator + 0.000000001 >= FIXED_DT and steps < MAX_CATCH_UP_STEPS:
		step.call(); accumulator -= FIXED_DT; fixed_tick += 1; steps += 1
	if accumulator >= FIXED_DT:
		var excess := int(floor(accumulator / FIXED_DT)); dropped_steps += excess; accumulator -= excess * FIXED_DT
	return steps
