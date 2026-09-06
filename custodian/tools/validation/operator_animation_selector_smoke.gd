extends SceneTree

const Selector := preload("res://game/actors/operator/animations/operator_animation_selector.gd")


func _init() -> void:
	var frames := SpriteFrames.new()
	var pixel := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	var texture := ImageTexture.create_from_image(pixel)
	for name in [
		"unarmed/attack/fast_01/e/full_body", "unarmed/attack/fast_01/n/full_body",
		"unarmed/attack/fast_01/s/full_body", "unarmed/attack/burst_01/omni/fx",
		"unarmed/attack/burst_01/s/fx", "unarmed/attack/empty_01/s/fx",
		"weapon/vigil/melee_1h_dagger/attack/fast_01/s/weapon",
	]:
		frames.add_animation(name)
		frames.add_frame(name, texture)
	frames.add_animation("unarmed/attack/fast_01/w/full_body") # An empty clip is unavailable.
	var selector := Selector.new(frames)
	var events: Array[Dictionary] = []
	selector.operator_animation_south_fallback.connect(func(details: Dictionary): events.append(details))
	assert(selector.resolve(&"unarmed", &"attack", &"fast_01", Vector2.RIGHT, &"full_body") == &"unarmed/attack/fast_01/e/full_body")
	assert(selector.resolve(&"unarmed", &"attack", &"fast_01", Vector2.UP, &"full_body") == &"unarmed/attack/fast_01/n/full_body")
	assert(selector.resolve(&"unarmed", &"attack", &"fast_01", Vector2.LEFT, &"full_body") == &"unarmed/attack/fast_01/s/full_body")
	assert(events.size() == 1 and events[0].requested_direction == &"w")
	assert(selector.south_fallback_count == 1)
	assert(selector.resolve_omni(&"unarmed", &"attack", &"burst_01", &"fx") == &"unarmed/attack/burst_01/omni/fx")
	# The following deliberately log missing-animation errors; empty results are required.
	assert(selector.resolve(&"unarmed", &"attack", &"missing_01", Vector2.LEFT, &"full_body").is_empty())
	assert(selector.resolve_omni(&"unarmed", &"attack", &"empty_01", &"fx").is_empty())
	assert(selector.resolve(&"unarmed", &"defense", &"fast_01", Vector2.LEFT, &"full_body").is_empty())
	assert(selector.resolve(&"unarmed", &"attack", &"fast_01", Vector2.LEFT, &"upper_body").is_empty())
	assert(selector.resolve(&"melee_1h", &"attack", &"fast_01", Vector2.LEFT, &"full_body").is_empty())
	assert(selector.resolve(&"melee_1h_dagger", &"attack", &"fast_01", Vector2.DOWN, &"weapon", &"vigil") == &"weapon/vigil/melee_1h_dagger/attack/fast_01/s/weapon")
	assert(selector.resolve(&"melee_1h_dagger", &"attack", &"fast_01", Vector2.DOWN, &"weapon", &"cleaver").is_empty())
	assert(selector.south_fallback_count == 1, "Missing/OMNI identities must not count as SOUTH substitutions")
	for index in Selector.SECTORS.size():
		var sector: StringName = Selector.SECTORS[index]
		assert(Selector.vector_to_sector(Selector.sector_direction(sector)) == sector)
	print("operator_animation_selector_smoke: PASS (six expected missing-animation errors)")
	quit(0)
