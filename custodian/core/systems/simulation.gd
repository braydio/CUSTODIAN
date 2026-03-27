extends Node

var accumulator := 0.0
const FIXED_DT := 1.0 / 60.0

func _process(delta):
	accumulator += delta

	while accumulator >= FIXED_DT:
		simulation_step(FIXED_DT)
		accumulator -= FIXED_DT

func simulation_step(_dt):
	var gs = get_node("/root/GameState")
	if gs:
		gs.advance()
