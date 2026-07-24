extends SceneTree

const INGEST_RUNTIME := preload(
	"res://tools/pipelines/ingest_runtime.gd"
)


func _init() -> void:
	var errors: Array[String] = []
	_check_direction_paths(errors)
	_check_output_expansion(errors)
	_check_frame_flip(errors)

	if errors.is_empty():
		print("[SpriteDirectionalMirrorPipelineSmoke] PASS")
		quit(0)
		return

	for error in errors:
		push_error("[SpriteDirectionalMirrorPipelineSmoke] %s" % error)
	quit(1)


func _check_direction_paths(errors: Array[String]) -> void:
	var cases := {
		(
			"operator/runtime/body/melee/"
			+ "operator__body__melee__fast_01__e__5f__96.png"
		): (
			"operator/runtime/body/melee/"
			+ "operator__body__melee__fast_01__w__5f__96.png"
		),
		(
			"enemies/enemy_savage/runtime/body/locomotion/"
			+ "enemy_savage__body__locomotion__run_01__ne__8f__96.png"
		): (
			"enemies/enemy_savage/runtime/body/locomotion/"
			+ "enemy_savage__body__locomotion__run_01__nw__8f__96.png"
		),
		(
			"custodian/runtime/body/"
			+ "custodian__body__locomotion__walk__se__6f__128.png"
		): (
			"custodian/runtime/body/"
			+ "custodian__body__locomotion__walk__sw__6f__128.png"
		),
		"allies/combat_droid/runtime/body/combat_droid__idle__w.png": (
			"allies/combat_droid/runtime/body/combat_droid__idle__e.png"
		),
	}
	for source_path in cases:
		var actual := INGEST_RUNTIME._mirrored_output_path(source_path)
		var expected := str(cases[source_path])
		if actual != expected:
			errors.append(
				"mirror path expected %s, got %s" % [expected, actual]
			)

	for non_mirrored_path in [
		"effects/runtime/hit_spark__fx__impact__default__omni__4f__64.png",
		"operator/runtime/body/operator__body__locomotion__idle__n__5f__96.png",
		"operator/runtime/body/operator__body__locomotion__idle__s__5f__96.png",
	]:
		if not INGEST_RUNTIME._mirrored_output_path(
			non_mirrored_path
		).is_empty():
			errors.append(
				"non-horizontal direction unexpectedly mirrored: %s"
				% non_mirrored_path
			)


func _check_output_expansion(errors: Array[String]) -> void:
	var east_path := (
		"operator/runtime/body/melee/"
		+ "operator__body__melee__fast_01__e__5f__96.png"
	)
	var west_path := east_path.replace("__e__5f__", "__w__5f__")
	var outputs := [{
		"path": east_path,
		"layout": "horizontal_strip",
		"select": {
			"type": "range",
			"start": 0,
			"count": 5,
		},
		"transform": {
			"canvas": [96, 96],
			"offset": [2, 3],
		},
	}]
	var expanded := INGEST_RUNTIME._expand_output_specs(
		outputs,
		true
	)
	if expanded.size() != 2:
		errors.append("default expansion did not add exactly one mirror")
	else:
		var mirrored := expanded[1] as Dictionary
		if str(mirrored.get("path", "")) != west_path:
			errors.append("expanded output used the wrong mirrored path")
		if not bool(mirrored.get("_auto_mirror_horizontal", false)):
			errors.append("expanded output is missing its frame-flip marker")
		if mirrored.get("select", {}) != outputs[0]["select"]:
			errors.append("expanded output did not preserve frame selection")
		if mirrored.get("transform", {}) != outputs[0]["transform"]:
			errors.append("expanded output did not preserve transforms")

	var explicit_pair := INGEST_RUNTIME._expand_output_specs(
		[
			outputs[0],
			{
				"path": west_path,
				"layout": "horizontal_strip",
			},
		],
		true
	)
	if explicit_pair.size() != 2:
		errors.append("authored counterpart was duplicated by auto-mirroring")

	var separate_manifest_pair := INGEST_RUNTIME._expand_output_specs(
		outputs,
		true,
		{west_path: true}
	)
	if separate_manifest_pair.size() != 1:
		errors.append(
			"counterpart declared by another batch manifest was duplicated"
		)

	var opted_out := INGEST_RUNTIME._expand_output_specs(
		outputs,
		false
	)
	if opted_out.size() != 1:
		errors.append("no-mirror opt-out still generated a counterpart")


func _check_frame_flip(errors: Array[String]) -> void:
	var frame := Image.create_empty(
		3,
		1,
		false,
		Image.FORMAT_RGBA8
	)
	var red := Color(1.0, 0.0, 0.0, 1.0)
	var green := Color(0.0, 1.0, 0.0, 1.0)
	var blue := Color(0.0, 0.0, 1.0, 1.0)
	frame.set_pixel(0, 0, red)
	frame.set_pixel(1, 0, green)
	frame.set_pixel(2, 0, blue)

	INGEST_RUNTIME._mirror_frame_horizontal(frame)
	if frame.get_pixel(0, 0) != blue:
		errors.append("horizontal mirror did not move the last pixel first")
	if frame.get_pixel(1, 0) != green:
		errors.append("horizontal mirror changed the center pixel")
	if frame.get_pixel(2, 0) != red:
		errors.append("horizontal mirror did not move the first pixel last")
