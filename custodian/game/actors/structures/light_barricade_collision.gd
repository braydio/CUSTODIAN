extends StaticBody2D


func take_damage(amount: float) -> void:
	var barricade := get_parent()
	if barricade != null and barricade.has_method("take_damage"):
		barricade.call("take_damage", amount)


func receive_projectile_hit(amount: float, attacker_team: String = "neutral") -> Dictionary:
	var barricade := get_parent()
	if barricade != null and barricade.has_method("receive_projectile_hit"):
		var result: Variant = barricade.call("receive_projectile_hit", amount, attacker_team)
		if result is Dictionary:
			return result
	return {
		"blocked": true,
		"applied_damage": 0.0,
	}


func is_dead() -> bool:
	var barricade := get_parent()
	return barricade == null or (barricade.has_method("is_dead") and bool(barricade.call("is_dead")))
