class_name SimulationClock
extends RefCounted

const SIMULATION_HZ := 60
const FIXED_DT := 1.0 / float(SIMULATION_HZ)

var accumulator := 0.0
var tick := 0
var paused := false

func advance(real_delta: float, step: Callable) -> int:
	if paused:
		return 0
	accumulator += maxf(0.0, real_delta)
	var steps := 0
	while accumulator >= FIXED_DT:
		step.call()
		accumulator -= FIXED_DT
		tick += 1
		steps += 1
	return steps
