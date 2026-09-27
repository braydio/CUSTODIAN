extends "res://game/world/interactions/world_readout_interactable.gd"
class_name AwakeningPlaqueInteractable

## Awakening keeps its scene-facing class name while sharing the generic
## read-only HUD interaction contract.
@export var prompt_body := ""
