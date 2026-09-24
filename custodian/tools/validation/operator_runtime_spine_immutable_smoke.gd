extends SceneTree
## The canonical Operator SpriteFrames is a built, immutable runtime database.
##
## Before C2b.1, equipping a melee weapon called `_install_weapon_body_frames()`,
## which copied that weapon's `body_frames_resource` animations **into** the
## shared `operator_runtime_frames.tres` object. An equipped Vigil dagger really
## did add `vigil_dagger_fast_03_right` to the canonical database at runtime.
##
## That is why the earlier attempt to delete the compatibility tail of
## `_play_melee_anim_resolved()` failed: every static argument for those probes
## being unreachable was true of the resource on disk and false of the object in
## memory. A snapshot test is the only thing that can tell those two apart, so
## this is that test.
##
## Equipping, unequipping and cycling weapons may change which identity a renderer
## selects. It may not change the database those identities live in.
##
## Authority: design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const RUNTIME_FRAMES := preload(
	"res://content/sprites/operator/runtime/operator_runtime_frames.tres"
)
const DAGGER_DEFINITION := preload(
	"res://game/actors/operator/vigil_pattern_dagger_definition.tres"
)
const CLEAVER_DEFINITION := preload(
	"res://game/actors/operator/sword_cleaver_definition.tres"
)

## Renderers that must share the one canonical database rather than own a copy.
const CANONICAL_RENDERERS := [
	"animated_sprite",
	"melee_weapon_overlay_sprite",
	"melee_fx_overlay_sprite",
	"modular_lower_body_sprite",
	"modular_upper_body_sprite",
	"modular_sidearm_sprite",
	"modular_upper_fx_sprite",
	"dodge_fx_back_sprite",
]

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	_errors.append(message)
	push_error("[OperatorRuntimeSpineImmutableSmoke] %s" % message)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


## A structural fingerprint of the whole database.
##
## Name set, per-animation frame count, fps, loop and every frame duration, plus
## the frame's texture identity. A mutation that adds, removes, retimes or
## repoints any animation changes this string.
func _snapshot(frames: SpriteFrames) -> String:
	var names := frames.get_animation_names()
	names.sort()
	var parts: PackedStringArray = []
	for name_variant: Variant in names:
		var animation := StringName(name_variant)
		var frame_count := frames.get_frame_count(animation)
		var row := "%s|n=%d|fps=%.4f|loop=%s" % [
			animation, frame_count,
			frames.get_animation_speed(animation),
			str(frames.get_animation_loop(animation)),
		]
		for index in range(frame_count):
			var texture := frames.get_frame_texture(animation, index)
			var provenance := "null"
			if texture is AtlasTexture:
				var atlas := texture as AtlasTexture
				var source: String = atlas.atlas.resource_path if atlas.atlas != null else "null"
				provenance = "%s@%s" % [source, atlas.region]
			elif texture != null:
				provenance = texture.resource_path
			row += "|f%d=%.4f:%s" % [
				index, frames.get_frame_duration(animation, index), provenance
			]
		parts.append(row)
	return "\n".join(parts)


func _run() -> void:
	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame
	operator.set_process(false)
	operator.set_physics_process(false)

	# Every presentation renderer must BE the canonical database, not a copy of
	# it. A duplicate would satisfy every has_animation() check while quietly
	# restoring the private per-actor database this slice removed.
	for property: String in CANONICAL_RENDERERS:
		var sprite := operator.get(property) as AnimatedSprite2D
		if sprite == null:
			continue
		_check(
			sprite.sprite_frames == RUNTIME_FRAMES,
			"%s must bind the canonical runtime frames, got %s"
				% [property, sprite.sprite_frames]
		)

	var baseline := _snapshot(RUNTIME_FRAMES)
	var baseline_count := RUNTIME_FRAMES.get_animation_names().size()
	_check(baseline_count > 0, "the canonical database is empty; the snapshot proves nothing")

	# The cycle the old mutation ran on: each of these used to install a
	# different weapon's SpriteFrames into the shared object.
	var cycle := [
		["Vigil", DAGGER_DEFINITION],
		["unarmed", null],
		["Sword-Cleaver", CLEAVER_DEFINITION],
		["Vigil", DAGGER_DEFINITION],
	]
	for step: Array in cycle:
		var label := String(step[0])
		var definition = step[1]
		if definition == null:
			operator.set("using_unarmed", true)
			operator.call("_apply_unarmed_selection")
		else:
			operator.set("using_unarmed", false)
			operator.set("primary_weapon_equipped", true)
			operator.set("melee_weapon_definition", definition)
			operator.call("_rebuild_armed_weapon_list")
			var armed: Array = operator.get("armed_weapons")
			var index := armed.find(definition)
			if index >= 0:
				operator.call("_apply_armed_selection", index)
		operator.call("_refresh_primary_weapon_state")
		await process_frame

		_check(
			RUNTIME_FRAMES.get_animation_names().size() == baseline_count,
			"equipping %s changed the canonical animation count: %d -> %d"
				% [label, baseline_count, RUNTIME_FRAMES.get_animation_names().size()]
		)
		var current := _snapshot(RUNTIME_FRAMES)
		if current != baseline:
			_fail("equipping %s mutated the canonical runtime database" % label)
			_report_first_difference(baseline, current)
			baseline = current

	# A negative control. The snapshot must actually be able to see a mutation,
	# or its silence above means nothing.
	_check(
		_snapshot_detects_mutation(),
		"the snapshot cannot detect a mutation, so this test is vacuous"
	)

	operator.queue_free()
	await process_frame
	if not _errors.is_empty():
		push_error("operator_runtime_spine_immutable_smoke: FAIL (%d)" % _errors.size())
		quit(1)
		return
	print("operator_runtime_spine_immutable_smoke: PASS")
	quit(0)


func _report_first_difference(before: String, after: String) -> void:
	var a := before.split("\n")
	var b := after.split("\n")
	for index in range(maxi(a.size(), b.size())):
		var left := a[index] if index < a.size() else "<absent>"
		var right := b[index] if index < b.size() else "<absent>"
		if left != right:
			push_error("   first difference:\n     before: %s\n     after:  %s" % [left, right])
			return


## Prove the fingerprint is sensitive, on a throwaway copy of the database.
func _snapshot_detects_mutation() -> bool:
	var scratch := RUNTIME_FRAMES.duplicate(true) as SpriteFrames
	if scratch == null:
		return false
	var before := _snapshot(scratch)
	scratch.add_animation(&"synthetic/mutation/probe")
	return _snapshot(scratch) != before
