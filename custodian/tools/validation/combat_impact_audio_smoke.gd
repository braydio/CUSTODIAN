extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const COMBAT_CONSTANTS := preload(
	"res://game/systems/combat/combat_constants.gd"
)
const CAUSEWAY_MUSIC_PATHS := [
	"res://content/audio/music/return_causeway/return_causeway_01.ogg",
	"res://content/audio/music/return_causeway/hall_still_answers.ogg",
]
const REQUIRED_AUDIO_PATHS := [
	"res://content/audio/sfx/combat/melee_swing_fast_01-1.wav",
	"res://content/audio/sfx/combat/swing_fast_02.wav",
	"res://content/audio/sfx/combat/swing_fast_03.wav",
	"res://content/audio/sfx/combat/hit_light_body_01.wav",
	"res://content/audio/sfx/combat/hit_medium_body_01.wav",
	"res://content/audio/sfx/combat/hit_robot_metal_01.wav",
	"res://content/audio/sfx/combat/hit_scorched_01.wav",
	"res://content/audio/sfx/combat/hit_hallway_reverb_01.wav",
	"res://content/audio/sfx/combat/shrumb_hit_01.wav",
	"res://content/audio/sfx/combat/shrumb_hit_02.wav",
	CAUSEWAY_MUSIC_PATHS[0],
	CAUSEWAY_MUSIC_PATHS[1],
]
const PROFILE_SCENES := {
	"res://game/actors/enemies/ambient_shrumb.tscn": &"shrumb",
	"res://game/actors/enemies/fast_drone.tscn": &"robot_metal",
	"res://game/actors/enemies/heavy_drone.tscn": &"robot_metal",
	"res://game/actors/enemies/enemy_marine.tscn": &"robot_metal",
	"res://game/actors/enemies/enemy_savage.tscn": &"scorched",
}

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for path: String in REQUIRED_AUDIO_PATHS:
		_assert(ResourceLoader.exists(path), "Missing audio resource: %s" % path)
		var stream := load(path) as AudioStream
		_assert(stream != null, "Audio resource did not load: %s" % path)
	for source_path: String in [
		"res://autoload/music_manager.gd",
		"res://game/world/sundered_keep/return_causeway/return_causeway_layout.gd",
	]:
		var source := FileAccess.get_file_as_string(source_path)
		for music_path: String in CAUSEWAY_MUSIC_PATHS:
			_assert(
				source.contains(music_path),
				"Causeway track %s is not wired in %s"
					% [music_path, source_path]
			)

	var music_manager := root.get_node_or_null("MusicManager")
	_assert(
		music_manager != null
			and music_manager.has_method("play_playlist"),
		"MusicManager does not expose playlist playback"
	)
	if music_manager != null and music_manager.has_method("play_playlist"):
		music_manager.call("play_playlist", CAUSEWAY_MUSIC_PATHS, true)
		_assert(
			music_manager.call("get_playlist_paths") == CAUSEWAY_MUSIC_PATHS,
			"MusicManager did not retain the ordered Causeway playlist"
		)
		_assert(
			music_manager.call("get_current_path") == CAUSEWAY_MUSIC_PATHS[0],
			"Causeway playlist did not start with return_causeway_01"
		)
		music_manager.call("_on_player_finished")
		_assert(
			music_manager.call("get_current_path") == CAUSEWAY_MUSIC_PATHS[1],
			"Causeway playlist did not advance to hall_still_answers"
		)

	for scene_path: String in PROFILE_SCENES:
		var scene_source := FileAccess.get_file_as_string(scene_path)
		_assert(
			scene_source.contains(
				'melee_impact_audio_profile = &"%s"'
				% String(PROFILE_SCENES[scene_path])
			),
			"Unexpected impact profile for %s" % scene_path
		)
	var keep_source := FileAccess.get_file_as_string(
		"res://game/world/sundered_keep/sundered_keep_map.gd"
	)
	_assert(
		keep_source.contains(
			'marine.set("melee_impact_audio_profile", &"hallway_reverb")'
		),
		"Great Hall Marine does not select the hallway-reverb render"
	)

	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame
	var body_target := _ProfileTarget.new(&"body")
	var shrumb_target := _ProfileTarget.new(&"shrumb")
	var swing_paths := [
		"melee_swing_fast_01-1.wav",
		"swing_fast_02.wav",
		"swing_fast_03.wav",
	]
	for step in range(swing_paths.size()):
		var swing := operator.call(
			"_select_melee_fast_swing_sound",
			step
		) as AudioStream
		_assert(
			swing != null
				and swing.resource_path.ends_with(swing_paths[step]),
			"Fast melee chain step %d did not resolve %s"
				% [step, swing_paths[step]]
		)
	var swing_player := operator.call(
		"_play_melee_fast_swing_sfx",
		1
	) as AudioStreamPlayer2D
	_assert(
		swing_player != null
			and swing_player.name == "MeleeSwingAudio"
			and swing_player.max_distance == 520.0,
		"Fast melee swing did not create the positional audio player"
	)
	var light := operator.call(
		"_select_melee_impact_sound",
		body_target,
		COMBAT_CONSTANTS.HitStrength.LIGHT
	) as AudioStream
	var heavy := operator.call(
		"_select_melee_impact_sound",
		body_target,
		COMBAT_CONSTANTS.HitStrength.HEAVY
	) as AudioStream
	var shrumb_first := operator.call(
		"_select_melee_impact_sound",
		shrumb_target,
		COMBAT_CONSTANTS.HitStrength.LIGHT
	) as AudioStream
	var shrumb_second := operator.call(
		"_select_melee_impact_sound",
		shrumb_target,
		COMBAT_CONSTANTS.HitStrength.LIGHT
	) as AudioStream
	_assert(
		light != null and light.resource_path.ends_with("hit_light_body_01.wav"),
		"LIGHT body contact did not resolve the light-body render"
	)
	_assert(
		heavy != null and heavy.resource_path.ends_with("hit_medium_body_01.wav"),
		"HEAVY body contact did not resolve the medium-body render"
	)
	_assert(
		shrumb_first != null
			and shrumb_second != null
			and shrumb_first.resource_path != shrumb_second.resource_path,
		"Shrumb authored variants did not round-robin"
	)

	operator.free()
	if _errors.is_empty():
		print("[CombatImpactAudioSmoke] PASS")
		quit(0)
		return
	for error: String in _errors:
		push_error("[CombatImpactAudioSmoke] %s" % error)
	quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


class _ProfileTarget:
	extends Node

	var profile: StringName


	func _init(value: StringName) -> void:
		profile = value


	func get_melee_impact_audio_profile(_hit_strength: int) -> StringName:
		return profile
