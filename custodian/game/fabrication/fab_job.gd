extends RefCounted
class_name FabJob

var job_id: int = 0
var recipe_id: String = ""
var recipe: Dictionary = {}
var elapsed: float = 0.0
var duration: float = 0.0
var completed: bool = false


func _init(p_job_id: int = 0, p_recipe_id: String = "", p_recipe: Dictionary = {}) -> void:
	job_id = p_job_id
	recipe_id = p_recipe_id
	recipe = p_recipe.duplicate(true)
	duration = maxf(0.0, float(recipe.get("build_seconds", 0.0)))


func tick(delta: float) -> bool:
	if completed:
		return true

	elapsed += maxf(0.0, delta)
	if elapsed >= duration:
		completed = true

	return completed


func progress() -> float:
	if duration <= 0.0:
		return 1.0
	return clampf(elapsed / duration, 0.0, 1.0)


func to_snapshot() -> Dictionary:
	return {
		"job_id": job_id,
		"recipe_id": recipe_id,
		"elapsed": elapsed,
		"duration": duration,
		"progress": progress(),
		"completed": completed,
	}
