extends SceneTree

const LEVEL_PATH := "res://game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_underground.tscn"
const EXPLORATION := "res://content/audio/music/ash_bell/forlorn_ritualant_the_ninth_was_never_cast_loop_v2.ogg"
const COMBAT := "res://content/audio/music/ash_bell/forlorn_ritualant_the_ninth_answers_nothing_combat_loop_v2.ogg"
const STILLING := "res://content/audio/music/ash_bell/forlorn_ritualant_stilling_release_v1.ogg"
const HOSTILE := "res://content/audio/music/ash_bell/forlorn_ritualant_the_ninth_was_taken_hostile_resolution_v1.ogg"
const CAUSEWAY := "res://content/audio/music/return_causeway/return_causeway_01.ogg"
const SECOND_CAUSEWAY := "res://content/audio/music/return_causeway/hall_still_answers.ogg"

var _errors: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var manager := root.get_node_or_null("MusicManager")
	_check(manager != null, "MusicManager autoload is missing")
	if manager == null:
		_finish()
		return
	for cue in [EXPLORATION, COMBAT, STILLING, HOSTILE]:
		_check(load(cue) is AudioStreamOggVorbis, "Audio resource failed to import: %s" % cue)
	if not _errors.is_empty():
		_finish()
		return

	var level_scene := load(LEVEL_PATH) as PackedScene
	_check(level_scene != null, "Authored Underground scene failed to load")
	if level_scene == null:
		_finish()
		return

	var prior_paths: Array[String] = [CAUSEWAY, SECOND_CAUSEWAY]
	manager.play_playlist(prior_paths, true)
	_check(manager.get_current_path() == CAUSEWAY, "Could not seed existing Causeway playlist")

	var level := _make_level(level_scene)
	var director: ForlornRitualantMusicDirector = level.ritualant_music_director
	director._on_camera_profile_changed(&"DEEP_CAVERN", &"CHAPEL_APPROACH")
	_check(manager.get_current_path() == EXPLORATION, "Chapel reveal did not start exploration cue")
	_check(_current_stream(manager) != null and _current_stream(manager).loop, "Exploration cue is not looping")
	_check(_music_player_count(manager) == 1, "Underground created a duplicate music player")
	_check(not manager.begin_scoped_music(&"second_underground"), "A second scoped scene stole the active music lease")

	var site: ForlornRitualantSite = level.ritualant_site
	var state := site.event_state
	state.has_stilling_pin = true
	state.has_thread_knot = true
	state.mark_dialogue_seen(&"first_interaction")
	state.mark_dialogue_seen(&"ask_bell")
	state.mark_dialogue_seen(&"ask_thread")
	state.mark_dialogue_seen(&"ask_orra")
	state.set_resolution(AshBellEventState.Resolution.TOOK_STILLING_PIN)
	site.set_stilling_pin()
	await process_frame
	_check(manager.get_current_path() == STILLING, "Explicit Set Stilling Pin did not start Stilling Release")
	_check(_current_stream(manager) != null and not _current_stream(manager).loop, "Stilling Release is looping")
	_check(director._peaceful_cue_started, "Explicit Pin edge did not latch the peaceful cue exactly once")
	manager.call("_on_player_finished")
	await process_frame
	_check(manager.get_current_path() == EXPLORATION, "Completed peaceful one-shot did not return to the exploration bed")
	level.queue_free()
	await process_frame
	_check(manager.get_current_path() == CAUSEWAY, "Underground exit did not restore prior Causeway track")
	_check(manager.get_playlist_paths() == prior_paths, "Underground exit changed the prior playlist")

	level = _make_level(level_scene)
	director = level.ritualant_music_director
	director.transition_seconds = 0.0
	director._on_camera_profile_changed(&"DEEP_CAVERN", &"CHAPEL_APPROACH")
	state = level.ritualant_site.event_state
	state.ritualant_hostile = true
	state.set_resolution(AshBellEventState.Resolution.PROVOKED_RITUALANT)
	_check(manager.get_current_path() == COMBAT, "Committed hostility did not select the combat loop")
	_check(_current_stream(manager) != null and _current_stream(manager).loop, "Combat cue is not looping")
	level.ritualant_site.forlorn_ritualant.ninth_answer_started.emit()
	await create_timer(0.12).timeout
	_check(is_equal_approx(manager.get_volume_db(), director.ninth_answer_duck_db), "Ninth Answer did not apply its scoped music duck")
	level.ritualant_site.defile_site()
	_check(manager.get_current_path() == HOSTILE, "Fresh SITE_DEFILED did not select the hostile one-shot")
	_check(_current_stream(manager) != null and not _current_stream(manager).loop, "Hostile resolution cue is looping")
	manager.call("_on_player_finished")
	await process_frame
	_check(manager.get_current_path() == EXPLORATION, "Hostile one-shot completion did not select the non-combat aftermath bed")
	level.queue_free()
	await process_frame
	_check(manager.get_current_path() == CAUSEWAY, "Hostile route exit did not restore previous music")

	# The alternative peaceful route keys its one-shot to the third real anchor,
	# before the longer stabilization choreography reaches terminal completion.
	level = _make_level(level_scene)
	director = level.ritualant_music_director
	director.transition_seconds = 0.0
	state = level.ritualant_site.event_state
	state.ritualant_hostile = true
	state.set_resolution(AshBellEventState.Resolution.PROVOKED_RITUALANT)
	site = level.ritualant_site
	for anchor_id: StringName in [&"west", &"north", &"east"]:
		site._on_ritualant_attack_started()
		site.resolve_thread_anchor(anchor_id)
	_check(manager.get_current_path() == STILLING, "Final WEST/NORTH/EAST anchor did not start Stilling Release")
	_check(director._peaceful_cue_started, "Final anchor did not latch the peaceful one-shot")
	level.queue_free()
	await process_frame
	_check(manager.get_current_path() == CAUSEWAY, "Anchor-route exit did not restore previous music")

	level = _make_level(level_scene)
	director = level.ritualant_music_director
	director.transition_seconds = 0.0
	var pre_reveal_snapshot := level.ritualant_site.capture_encounter_state()
	_check(level.restore_route_state({"encounter": pre_reveal_snapshot}), "Pre-reveal route restore was rejected")
	_check(manager.get_current_path() == CAUSEWAY, "Pre-reveal restore started exploration music before the authored reveal")
	level.queue_free()
	await process_frame

	level = _make_level(level_scene)
	director = level.ritualant_music_director
	director.transition_seconds = 0.0
	level.ritualant_site.event_state.set_resolution(AshBellEventState.Resolution.SITE_DEFILED)
	var terminal_snapshot := level.ritualant_site.capture_encounter_state()
	level.queue_free()
	await process_frame
	level = _make_level(level_scene)
	_check(level.restore_route_state({"encounter": terminal_snapshot}), "Terminal route restore was rejected")
	director = level.ritualant_music_director
	_check(not director._hostile_cue_started, "Restored SITE_DEFILED replayed its hostile one-shot")
	_check(manager.get_current_path() == CAUSEWAY, "Restored terminal state seized historical scene music")
	level.queue_free()
	await process_frame

	# A successor zone cancels an in-flight scene fade and remains authoritative
	# after teardown; the old completion coroutine must not seize the player.
	level = _make_level(level_scene)
	director = level.ritualant_music_director
	director.transition_seconds = 0.35
	director._on_camera_profile_changed(&"DEEP_CAVERN", &"CHAPEL_APPROACH")
	manager.play_playlist([SECOND_CAUSEWAY], true)
	await create_timer(0.4).timeout
	level.queue_free()
	await process_frame
	_check(manager.get_current_path() == SECOND_CAUSEWAY, "Underground teardown clobbered successor-zone music")
	_check(_music_player_count(manager) == 1, "Music transitions created duplicate players")
	manager.stop_track()
	if _errors.is_empty():
		print("[RitualantFourCueMusic] PASS: four assets, reveal, combat, explicit Pin, restore, one-shots, ducks, ownership")
	_finish()


func _make_level(scene: PackedScene) -> ForlornRitualantUnderground:
	var instance := scene.instantiate() as ForlornRitualantUnderground
	root.add_child(instance)
	instance.ritualant_music_director.transition_seconds = 0.0
	return instance


func _current_stream(manager: Node) -> AudioStreamOggVorbis:
	var player := manager.get_node_or_null("MusicPlayer") as AudioStreamPlayer
	return player.stream as AudioStreamOggVorbis if player != null else null


func _music_player_count(manager: Node) -> int:
	var count := 0
	for child in manager.get_children():
		if child is AudioStreamPlayer:
			count += 1
	return count


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
		push_error("[RitualantFourCueMusic] " + message)


func _finish() -> void:
	if _errors.is_empty():
		quit(0)
	else:
		quit(1)
