extends Node2D

func get_runtime_world() -> Node2D:
	return get_node_or_null("World") as Node2D


func get_runtime_level() -> Node:
	return get_node_or_null("World/Level")
