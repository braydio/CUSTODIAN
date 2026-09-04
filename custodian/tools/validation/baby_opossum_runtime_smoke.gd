extends SceneTree

const SCENE := preload("res://game/actors/ambient/baby_opossum/baby_opossum.tscn")

func _init() -> void:
	var opossum := SCENE.instantiate()
	if opossum == null:
		_fail("scene did not instantiate")
		return
	root.add_child(opossum)
	await process_frame
	if not opossum.has_method("play_action") or not opossum.has_method("take_damage"):
		_fail("ambient actor API missing")
		return
	var result: Dictionary = opossum.take_damage(999.0)
	if float(result.get("applied_damage", -1.0)) != 0.0 or bool(result.get("lethal", true)):
		_fail("opossum accepted damage")
		return
	if not opossum.play_action(&"idle") and not opossum.play_action(&"waddle"):
		# With zero installed PNGs this is expected: the behavior must continue.
		if opossum.play_action(&"missing_action"):
			_fail("missing action did not fail softly")
			return
	opossum.receive_treat()
	if int(opossum.get("trust_points")) != 1:
		_fail("treat did not advance trust")
	var capabilities: Dictionary = opossum.get_animation_capabilities()
	if capabilities == null:
		_fail("capability diagnostics missing")
		return
	opossum.reject_melee()
	opossum.reject_projectile()
	await process_frame
	print("baby_opossum_runtime_smoke: PASS capabilities=%d" % capabilities.size())
	quit(0)

func _fail(message: String) -> void:
	push_error("baby_opossum_runtime_smoke: " + message)
	quit(1)
