class_name SectorSimulationBinding
extends Node
@export var scene_identity := ""
var mapped_identity := ""
var runtime: WorldSimulationRuntime
func _ready() -> void:
	runtime = get_tree().get_first_node_in_group("world_simulation_runtime") as WorldSimulationRuntime; mapped_identity = WorldIdentityContract.map_scene_identity(scene_identity)
	if mapped_identity.is_empty(): push_warning("Unknown sector simulation binding: %s" % scene_identity); return
	if runtime != null: runtime.snapshot_updated.connect(_on_snapshot)
func _on_snapshot(_snapshot: SimulationSnapshot) -> void: pass
