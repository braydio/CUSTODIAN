extends SceneTree

const TEXTURES := [
	"res://content/levels/awakening/05_dust_lung/awakening_dust_lung_underlay_1502x2048.png",
	"res://content/levels/awakening/04_05_connector/awakening_reliquary_dust_lung_connector_full_plate_underlay_1502x2048.png",
	"res://content/levels/awakening/04_locker_reliquary/awakening_locker_reliquary_underlay_1502x2048.png",
]
const EXPECTED_LAYER_BOUNDS := [
	Rect2i(0, 0, 870, 838),
	Rect2i(258, 672, 1042, 584),
	Rect2i(644, 1182, 858, 866),
]
const EXPECTED_RENDER_BOUNDS := Rect2i(65, 12, 511, 697)
const VIEW_SIZE := Vector2i(640, 720)
const RENDER_SCALE := 0.34

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = VIEW_SIZE
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	root.add_child(viewport)
	var composition := Node2D.new()
	composition.position = Vector2(VIEW_SIZE) * 0.5
	composition.scale = Vector2.ONE * RENDER_SCALE
	viewport.add_child(composition)
	for index in TEXTURES.size():
		var texture := load(TEXTURES[index]) as Texture2D
		if texture == null or texture.get_size() != Vector2(1502, 2048):
			_fail("registered layer %d did not load on the shared canvas" % index)
			continue
		var bounds := texture.get_image().get_used_rect()
		if bounds != EXPECTED_LAYER_BOUNDS[index]:
			_fail("registered layer %d alpha bounds drifted: %s" % [index, str(bounds)])
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.z_index = index
		composition.add_child(sprite)
	await process_frame
	await process_frame
	var rendered := viewport.get_texture().get_image()
	if rendered == null:
		push_error("awakening_registered_composition_render_smoke: renderer returned no image; run under a graphical renderer")
		quit(1)
		return
	var rendered_bounds := rendered.get_used_rect()
	if rendered_bounds.position.distance_to(EXPECTED_RENDER_BOUNDS.position) > 1.0 or rendered_bounds.end.distance_to(EXPECTED_RENDER_BOUNDS.end) > 1.5:
		_fail("compact renderer capture bounds drifted: %s, expected near %s" % [str(rendered_bounds), str(EXPECTED_RENDER_BOUNDS)])
	var capture_path := "/tmp/custodian_awakening_registered_composition.png"
	var save_error := rendered.save_png(capture_path)
	if save_error != OK:
		_fail("could not save compact renderer capture (%d)" % save_error)
	if _failures.is_empty():
		print("awakening_registered_composition_render_smoke: PASS bounds=%s capture=%s" % [str(rendered_bounds), capture_path])
		quit(0)
	else:
		for failure in _failures:
			push_error("awakening_registered_composition_render_smoke: " + failure)
		print("CUSTODIAN_TEST_RESULT_JSON:{\"failure_count\":%d,\"failures\":%s,\"passed\":false,\"schema\":\"custodian.headless_test.result.v1\",\"test\":\"awakening_registered_composition_render_smoke\"}" % [_failures.size(), JSON.stringify(_failures)])
		quit(1)


func _fail(message: String) -> void:
	_failures.append(message)
