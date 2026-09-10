extends SceneTree

## Presentation contract for the Custodian Designation Locker in The First Return.
##
## Verifies the locker draws from the `awakening_designation_locker` Asset V2
## family rather than the retired field-retention locker: it rests closed, the
## authorization strip carries all eight 128×160 frames at 10 FPS, the locker
## settles on `open_loaded`, the P-9 is granted exactly once, and the fixture
## ends on `empty` with re-interaction unable to duplicate the sidearm.

const SCENE := preload("res://scenes/awakening_first_return.tscn")
const Layout := preload("res://game/world/awakening/awakening_layout.gd")

const ART_ROOT := "res://content/sprites/environment/props/awakening/awakening_designation_locker/runtime/body"
const EXPECTED_ART := {
	"closed": ART_ROOT + "/awakening_designation_locker__body__state__closed__omni__1f__128x160.png",
	"authorize_open": ART_ROOT + "/awakening_designation_locker__body__interaction__authorize_open__omni__8f__128x160.png",
	"open_loaded": ART_ROOT + "/awakening_designation_locker__body__state__open_loaded__omni__1f__128x160.png",
	"empty": ART_ROOT + "/awakening_designation_locker__body__state__empty__omni__1f__128x160.png",
}

const RETIRED_ART_DIR := "res://content/sprites/props/storage/field_retention_locker"
const FRAME_SIZE := Vector2i(128, 160)

## Geometry calibration contract. The 128x160 faceplate is a wall-integrated
## relief, so the physical body is a shallow base projection, not the art canvas.
const ANCHOR := Vector2(832, -1952)
const COLLIDER_SIZE := Vector2(112, 32)
const COLLIDER_OFFSET := Vector2(0, 64)
const FOOTPRINT_CENTER := Vector2(832, -1888)
const SPRITE_VISUAL_OFFSET := Vector2(72, 0)

var _failures: Array[String] = []


func _init() -> void:
	_check_runtime_art()

	var awakening := SCENE.instantiate()
	root.add_child(awakening)
	await physics_frame
	await process_frame

	var locker := awakening.get_node_or_null(
		"World/AwakeningZones/Zone04_LockerReliquary/SidearmLocker"
	)
	if locker == null:
		_fail("SidearmLocker is not instanced in the Locker Reliquary")
		_report()
		return

	if locker.position != ANCHOR:
		_fail("SidearmLocker drifted from the authored coordinate: %s" % str(locker.position))
	if locker.global_position != ANCHOR:
		_fail("SidearmLocker global anchor drifted: %s" % str(locker.global_position))

	_check_collider(locker)
	_check_layout_footprint()

	var sprite := locker.get_node_or_null("LockerSprite") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		_fail("locker built no AnimatedSprite2D from the designation-locker family")
		_report()
		return

	_check_frames(sprite.sprite_frames)
	_check_closed_rest(locker, sprite)
	await _check_authorization(locker, awakening, sprite)
	_report()


## The physical body is a shallow one-tile wall projection at the locker base,
## deliberately narrower and much shallower than the 128x160 art canvas.
func _check_collider(locker: Node) -> void:
	var shape_node := locker.get_node_or_null("Body/CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		_fail("SidearmLocker has no Body/CollisionShape2D")
		return
	if shape_node.position != COLLIDER_OFFSET:
		_fail("collider local offset is %s, expected %s" % [
			str(shape_node.position), str(COLLIDER_OFFSET),
		])
	var rectangle := shape_node.shape as RectangleShape2D
	if rectangle == null:
		_fail("collider is not a RectangleShape2D")
		return
	if rectangle.size != COLLIDER_SIZE:
		_fail("collider size is %s, expected %s" % [str(rectangle.size), str(COLLIDER_SIZE)])
	if rectangle.size == Vector2(FRAME_SIZE):
		_fail("collider must not be the full art canvas")
	if shape_node.global_position != FOOTPRINT_CENTER:
		_fail("collider world center is %s, expected %s" % [
			str(shape_node.global_position), str(FOOTPRINT_CENTER),
		])


## The layout entry exists so the geometry validator accounts for the prop; it
## must agree with the .tscn collider it stands in for.
func _check_layout_footprint() -> void:
	var piece: Dictionary = {}
	for candidate in Layout.set_pieces_for(&"zone04_locker_reliquary"):
		if String(candidate.get("id", "")) == "p9_locker":
			piece = candidate
			break
	if piece.is_empty():
		_fail("no p9_locker set piece in zone04_locker_reliquary")
		return
	if Vector2(piece.get("position", Vector2.ZERO)) != FOOTPRINT_CENTER:
		_fail("layout p9_locker footprint center is %s, expected %s" % [
			str(piece.get("position")), str(FOOTPRINT_CENTER),
		])
	if Vector2(piece.get("size", Vector2.ZERO)) != COLLIDER_SIZE:
		_fail("layout p9_locker footprint size is %s, expected %s" % [
			str(piece.get("size")), str(COLLIDER_SIZE),
		])
	if not bool(piece.get("prop", false)):
		_fail("layout p9_locker must stay prop = true")
	if Layout.set_piece_rect(piece) != Rect2(FOOTPRINT_CENTER - COLLIDER_SIZE * 0.5, COLLIDER_SIZE):
		_fail("layout p9_locker rect resolved unexpectedly: %s" % str(Layout.set_piece_rect(piece)))

	var marker: Dictionary = {}
	for candidate in Layout.markers_for(&"zone04_locker_reliquary"):
		if String(candidate.get("id", "")) == "p9_locker":
			marker = candidate
			break
	if marker.is_empty():
		_fail("no p9_locker interactable marker in zone04_locker_reliquary")
		return
	if Vector2(marker.get("position", Vector2.ZERO)) != ANCHOR:
		_fail("layout p9_locker interaction anchor is %s, expected %s" % [
			str(marker.get("position")), str(ANCHOR),
		])


## Every state resolves to a canonical Asset V2 runtime output.
func _check_runtime_art() -> void:
	for state in EXPECTED_ART:
		var path: String = EXPECTED_ART[state]
		if not ResourceLoader.exists(path):
			_fail("canonical runtime art missing for '%s': %s" % [state, path])
			continue
		var texture := load(path) as Texture2D
		if texture == null:
			_fail("'%s' did not import as a texture" % state)
			continue
		var expected_width := FRAME_SIZE.x * (8 if state == "authorize_open" else 1)
		if texture.get_size() != Vector2(expected_width, FRAME_SIZE.y):
			_fail("'%s' is %s, expected %dx%d" % [
				state, str(texture.get_size()), expected_width, FRAME_SIZE.y,
			])


func _check_frames(frames: SpriteFrames) -> void:
	for state in ["closed", "authorize_open", "open_loaded", "empty"]:
		if not frames.has_animation(state):
			_fail("SpriteFrames is missing the '%s' animation" % state)

	if not frames.has_animation("authorize_open"):
		return

	var frame_count := frames.get_frame_count("authorize_open")
	if frame_count != 8:
		_fail("authorize_open has %d frames, expected 8" % frame_count)
	if not is_equal_approx(frames.get_animation_speed("authorize_open"), 10.0):
		_fail("authorize_open runs at %s FPS, expected 10" % str(
			frames.get_animation_speed("authorize_open")
		))
	if frames.get_animation_loop("authorize_open"):
		_fail("authorize_open must be one-shot, not looping")

	# Each frame is a distinct 128×160 window onto the strip.
	var seen_origins := {}
	for index in frame_count:
		var texture := frames.get_frame_texture("authorize_open", index)
		var atlas := texture as AtlasTexture
		if atlas == null:
			_fail("authorize_open frame %d is not a strip region" % index)
			continue
		if atlas.region.size != Vector2(FRAME_SIZE):
			_fail("authorize_open frame %d is %s, expected %s" % [
				index, str(atlas.region.size), str(Vector2(FRAME_SIZE)),
			])
		seen_origins[atlas.region.position] = true
	if seen_origins.size() != frame_count:
		_fail("authorize_open reuses strip regions: %d unique of %d frames" % [
			seen_origins.size(), frame_count,
		])

	# The still states must be their own plates, not slices of the strip.
	for state in ["closed", "open_loaded", "empty"]:
		if not frames.has_animation(state):
			continue
		if frames.get_frame_count(state) != 1:
			_fail("'%s' should be a single frame" % state)
			continue
		if frames.get_frame_texture(state, 0) is AtlasTexture:
			_fail("'%s' is sliced from the strip instead of using its own plate" % state)

	# Nothing may still draw from the retired field-retention locker.
	for state in frames.get_animation_names():
		for index in frames.get_frame_count(state):
			var texture := frames.get_frame_texture(state, index)
			var atlas := texture as AtlasTexture
			var source: Texture2D = atlas.atlas if atlas != null else texture
			if source == null:
				continue
			if source.resource_path.begins_with(RETIRED_ART_DIR):
				_fail("'%s' frame %d still draws from the retired locker art" % [state, index])


func _check_closed_rest(locker: Node, sprite: AnimatedSprite2D) -> void:
	if sprite.animation != &"closed":
		_fail("locker does not rest closed, shows '%s'" % str(sprite.animation))
	if sprite.is_playing():
		_fail("closed locker should not be animating")
	if int(locker.get("_state")) != 0:
		_fail("locker did not start in the CLOSED state")

	# Wall alignment is a pixel offset on the sprite; it must not leak into the
	# node transform, the interaction anchor, or the interaction radius.
	if sprite.offset != SPRITE_VISUAL_OFFSET:
		_fail("sprite visual offset is %s, expected %s" % [
			str(sprite.offset), str(SPRITE_VISUAL_OFFSET),
		])
	if sprite.position != Vector2.ZERO:
		_fail("sprite alignment must use offset, not a child transform: %s" % str(sprite.position))
	if Vector2(locker.call("get_interaction_position")) != ANCHOR:
		_fail("interaction position is %s, expected %s" % [
			str(locker.call("get_interaction_position")), str(ANCHOR),
		])
	if not is_equal_approx(float(locker.call("get_interaction_distance")), 84.0):
		_fail("interaction distance changed: %s" % str(locker.call("get_interaction_distance")))


func _check_authorization(locker: Node, awakening: Node, sprite: AnimatedSprite2D) -> void:
	var operator := awakening.get_node("World/Operator") as Node2D
	operator.global_position = locker.position + Vector2(-64, 0)
	await physics_frame

	locker.interact(operator)
	await process_frame
	if sprite.animation != &"authorize_open":
		_fail("interacting did not start the authorization animation")

	var reached_open := false
	for i in 300:
		await process_frame
		if int(locker.get("_state")) == 1:
			reached_open = true
			break
	if not reached_open:
		_fail("locker never settled into the open state")
		return

	if sprite.animation != &"open_loaded":
		_fail("locker shows '%s' after authorizing, expected open_loaded" % str(sprite.animation))
	if bool(awakening.get("p9_recovered")):
		_fail("the P-9 was granted before the player took it")

	locker.interact(operator)
	for i in 60:
		await process_frame
		if bool(awakening.get("p9_recovered")): break
	if not bool(awakening.get("p9_recovered")):
		_fail("taking the sidearm did not advance progression")

	if sprite.animation != &"empty":
		_fail("locker shows '%s' after pickup, expected empty" % str(sprite.animation))
	if int(locker.get("_state")) != 2:
		_fail("locker did not enter the EMPTY state after pickup")
	if locker.is_in_group("interactable"):
		_fail("an emptied locker should leave the interactable group")

	var granted := _sidearm_count()
	# Re-interaction must not hand out a second P-9.
	locker.interact(operator)
	await process_frame
	locker.interact(operator)
	await process_frame
	if _sidearm_count() != granted:
		_fail("re-interacting duplicated the P-9: %d → %d" % [granted, _sidearm_count()])
	if sprite.animation != &"empty":
		_fail("re-interaction changed the emptied locker's presentation")


func _sidearm_count() -> int:
	var inventory := root.get_node_or_null("InventoryManager")
	if inventory == null or not inventory.has_method("get_count"):
		return -1
	return int(inventory.call("get_count", &"p9_sidearm"))


func _fail(message: String) -> void:
	_failures.append(message)
	push_error("awakening_designation_locker_presentation_smoke: " + message)


func _report() -> void:
	var passed := _failures.is_empty()
	print("CUSTODIAN_TEST_RESULT_JSON:" + JSON.stringify({
		"schema": "custodian.headless_test.result.v1",
		"test": "awakening_designation_locker_presentation_smoke",
		"passed": passed,
		"failure_count": _failures.size(),
		"failures": _failures,
	}))
	if passed:
		print("awakening_designation_locker_presentation_smoke: PASS")
		quit(0)
		return
	print("awakening_designation_locker_presentation_smoke: FAIL (%d)" % _failures.size())
	for message in _failures: print("  - %s" % message)
	quit(1)
