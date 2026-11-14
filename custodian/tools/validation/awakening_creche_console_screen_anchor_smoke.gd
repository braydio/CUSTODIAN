extends SceneTree

const SCENE := preload("res://scenes/awakening_first_return.tscn")
const SCREEN_PIXEL_ROI := Rect2i(572, 493, 27, 18)

var _failures: Array[String] = []


func _init() -> void:
	var awakening := SCENE.instantiate()
	root.add_child(awakening)
	await physics_frame
	await process_frame
	var set_pieces := awakening.get_node("World/AwakeningZones/Zone01_Creche/SetPieces") as Node2D
	var body := set_pieces.get_node_or_null("CrecheConsoleBody") as Node2D
	var anchor := body.get_node_or_null("ScreenAnchor") as Node2D if body != null else null
	var fx := anchor.get_node_or_null("CrecheConsoleActivation") as AnimatedSprite2D if anchor != null else null
	var underlay := awakening.get_node("World/AwakeningZones/Zone01_Creche/ArtUnderlay/Underlay") as Sprite2D
	if body == null or anchor == null or fx == null:
		_fail("baked console body, screen anchor, or activation effect is missing")
		_report()
		return
	if body.get_meta("visible_body_source", "") != "awakening_creche_underlay_960x704.png":
		_fail("visible console body is not explicitly owned by the native underlay")
	if underlay == null or underlay.texture.get_size() != Vector2(960, 704):
		_fail("native console underlay identity or dimensions changed")
	if body.position != Vector2(105, 118) or anchor.position != Vector2.ZERO:
		_fail("screen anchor drifted from measured native-underlay coordinates")
	# The underlay sprite is centered at (0,-32), so its pixel origin maps
	# to world (-480,-384). Verify the anchor projects into the inspected
	# 27x18 pixel screen window (x=572..598, y=493..510).
	var underlay_pixel := body.global_position + Vector2(480, 384)
	if not SCREEN_PIXEL_ROI.has_point(Vector2i(underlay_pixel)):
		_fail("screen anchor projects outside the measured underlay pixel ROI: %s" % str(underlay_pixel))
	if fx.get_parent() != anchor or fx.position != Vector2.ZERO or fx.scale != Vector2.ONE * 0.13:
		_fail("activation effect is not screen-local at its measured scale")
	if Vector2(128, 128) * fx.scale.x > Vector2(SCREEN_PIXEL_ROI.size):
		_fail("activation frame canvas exceeds the measured screen pixel ROI")
	if fx.visible or fx.is_playing() or fx.z_index <= 0:
		_fail("activation effect is visible, playing, or behind the console screen")
	if fx.sprite_frames.get_frame_count(&"activate") != 8 or fx.sprite_frames.get_animation_speed(&"activate") != 8.0:
		_fail("activation animation frame/FPS contract changed")
	var marker := Vector2(112, 144)
	if fx.global_position.distance_to(marker) < 16.0:
		_fail("screen effect is still at the floor interaction marker")
	# Negative control: deliberately reproduce the old floor attachment and make
	# sure the structural screen-local assertion rejects it.
	var original_position := fx.position
	var original_parent := fx.get_parent()
	fx.reparent(set_pieces)
	fx.position = marker
	if _is_screen_bound(fx):
		_fail("negative floor-anchor control passed the screen-local assertion")
	fx.reparent(original_parent)
	fx.position = original_position
	var console := awakening.get_node("World/AwakeningZones/Zone01_Creche/Interactables/CrecheConsole")
	console.interact(awakening.get_node("World/Operator"))
	if not fx.visible or not fx.is_playing():
		_fail("first console interaction did not play the screen effect")
	var observed_frames := {fx.frame: true}
	for _tick in 34:
		await create_timer(0.04).timeout
		if fx.visible:
			observed_frames[fx.frame] = true
	for frame_index in 8:
		if not observed_frames.has(frame_index):
			_fail("activation playback skipped frame %d" % frame_index)
	await create_timer(1.1).timeout
	if fx.visible or fx.is_playing():
		_fail("one-shot screen effect did not hide on completion")
	console.interact(awakening.get_node("World/Operator"))
	await process_frame
	if fx.visible or fx.is_playing():
		_fail("repeat console readout replayed the activation effect")
	awakening.call("reset_progression")
	if fx.visible or fx.is_playing():
		_fail("progression reset did not clear the activation effect")
	console.interact(awakening.get_node("World/Operator"))
	if not fx.visible or not fx.is_playing():
		_fail("first acknowledgement after reset did not replay the screen effect")
	_report()


func _is_screen_bound(fx: AnimatedSprite2D) -> bool:
	var anchor := fx.get_parent() as Node2D
	return anchor != null and anchor.name == "ScreenAnchor" and anchor.get_parent() is Node2D and (anchor.get_parent() as Node2D).name == "CrecheConsoleBody"


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("AWAKENING_CRECHE_CONSOLE_SCREEN_ANCHOR_SMOKE: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)
