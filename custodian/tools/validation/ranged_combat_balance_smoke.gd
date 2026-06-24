extends SceneTree

const BulletScript = preload("res://game/actors/projectiles/bullet.gd")
const NoiseEventScript = preload("res://game/systems/stealth/noise_event.gd")
const NoiseBusScript = preload("res://game/systems/stealth/noise_event_bus.gd")

var _failures: Array[String] = []
var _heard_event := false


func _init() -> void:
	_validate_weapon_data("res://content/weapons/data/carbine_mk1.json", 24, 72, 420.0)
	_validate_weapon_data("res://content/weapons/data/pistol_mk1.json", 10, 60, 260.0)
	_validate_bullet_falloff()
	_validate_noise_bus()
	if _failures.is_empty():
		print("RANGED_COMBAT_BALANCE_SMOKE: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _validate_weapon_data(path: String, expected_magazine: int, expected_reserve_cap: int, expected_noise: float) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_failures.append("Cannot open %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_failures.append("Invalid JSON: %s" % path)
		return
	var data := parsed as Dictionary
	var ammo := data.get("ammo", {}) as Dictionary
	var heat := data.get("heat", {}) as Dictionary
	var noise := data.get("noise", {}) as Dictionary
	var stats := data.get("stats", {}) as Dictionary
	_expect(int(ammo.get("magazine_size", 0)) == expected_magazine, "%s magazine mismatch" % path)
	_expect(int(ammo.get("max_reserve", 0)) == expected_reserve_cap, "%s reserve cap mismatch" % path)
	_expect(bool(heat.get("enabled", false)) and float(heat.get("per_shot", 0.0)) > 0.0, "%s heat disabled" % path)
	_expect(is_equal_approx(float(noise.get("shot_radius_px", 0.0)), expected_noise), "%s noise mismatch" % path)
	_expect(float(stats.get("max_range_px", 0.0)) > float(stats.get("effective_range_px", 0.0)), "%s range band invalid" % path)


func _validate_bullet_falloff() -> void:
	var bullet := BulletScript.new()
	bullet.damage = 10.0
	bullet.falloff_start_px = 100.0
	bullet.falloff_end_px = 200.0
	bullet.min_damage_multiplier = 0.5
	bullet.set("_distance_traveled", 50.0)
	_expect(is_equal_approx(bullet.get_scaled_damage(), 10.0), "Bullet close damage changed")
	bullet.set("_distance_traveled", 200.0)
	_expect(is_equal_approx(bullet.get_scaled_damage(), 5.0), "Bullet falloff damage mismatch")
	bullet.free()


func _validate_noise_bus() -> void:
	var bus := NoiseBusScript.new()
	bus.noise_emitted.connect(func(_event: Variant) -> void: _heard_event = true)
	var event: RefCounted = NoiseEventScript.create(null, Vector2(10, 20), 420.0, &"gunshot", 1.0, 1.0, false, &"player")
	bus.emit_noise(event)
	_expect(_heard_event, "Noise bus did not emit")
	_expect(int(event.get("timestamp_msec")) > 0, "Noise event timestamp not assigned")
	bus.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
