extends SceneTree

const DIRECTIONAL_FALLBACK := preload(
	"res://game/systems/presentation/directional_animation_fallback.gd"
)

var _failed := false


func _init() -> void:
	_run()


func _run() -> void:
	var north_south: Array[StringName] = [&"n", &"s"]
	_assert_equal(
		DIRECTIONAL_FALLBACK.vector_to_sector(Vector2(1.0, -1.0)),
		&"ne",
		"diagonal vectors should resolve to canonical sectors"
	)
	_assert_equal(
		DIRECTIONAL_FALLBACK.nearest_available_sector(&"n", north_south),
		&"n",
		"exact sectors should remain exact"
	)
	_assert_equal(
		DIRECTIONAL_FALLBACK.nearest_available_sector(&"ne", north_south),
		&"n",
		"northeast should resolve north with N/S coverage"
	)
	_assert_equal(
		DIRECTIONAL_FALLBACK.nearest_available_sector(&"e", north_south),
		&"s",
		"east ties should use deterministic south-first order"
	)
	_assert_equal(
		DIRECTIONAL_FALLBACK.nearest_available_sector(&"e", north_south, &"n"),
		&"n",
		"previous tied sector should stabilize east"
	)
	_assert_equal(
		DIRECTIONAL_FALLBACK.nearest_available_sector(&"w", north_south, &"s"),
		&"s",
		"previous tied sector should stabilize west"
	)
	_assert_equal(
		DIRECTIONAL_FALLBACK.nearest_available_sector(&"nw", [&"e", &"n", &"s", &"se", &"sw", &"w"]),
		&"n",
		"northwest should select nearest north"
	)
	_assert_equal(
		DIRECTIONAL_FALLBACK.nearest_available_sector(&"ne", []),
		&"",
		"empty availability should preserve caller fallback"
	)
	if _failed:
		push_error("directional_animation_fallback_smoke failed")
		quit(1)
		return
	print("[DirectionalAnimationFallbackSmoke] exact, diagonal, tie, previous, and empty resolution passed.")
	quit(0)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_failed = true
	push_error("%s (expected %s, got %s)" % [message, expected, actual])
