extends "res://game/world/interactions/world_readout_interactable.gd"
class_name AwakeningPlaqueInteractable

## Awakening keeps its scene-facing class name while sharing the generic
## read-only HUD interaction contract.
@export var prompt_body := ""


func get_interaction_prompt_body() -> String:
	return prompt_body if not prompt_body.is_empty() else super.get_interaction_prompt_body()
