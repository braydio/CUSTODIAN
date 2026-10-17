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

	# Arrival takes ownership, fades the prior zone to silence, and holds the
	# exploration bed until the reveal. A repeated reveal cannot restart it.
	manager.play_playlist([CAUSEWAY], true)
	var level := _make_level(level_scene)
	var director: ForlornRitualantMusicDirector = level.ritualant_music_director
	director._reveal_reached = false
	director._exploration_started = false
	director.arrival_fade_seconds = 0.22
	director.exploration_transition_seconds = 0.42
	director.begin_arrival()
	await _settle(0.10)
	_check(manager.get_scoped_owner() == director.debug_get_owner_id(), "Arrival did not claim scoped music")
	_check(manager.get_current_path() == CAUSEWAY, "Arrival interrupted source before its fade completed")
	await _settle(0.18)
	await _settle(0.08)
	_check(manager.get_current_path().is_empty(), "Arrival did not fade the prior playlist to silence")
	director._on_camera_profile_changed(&"DEEP_CAVERN", &"CHAPEL_APPROACH")
	_check(manager.get_current_path() == EXPLORATION, "Reveal did not select the exploration loop")
	await _settle(0.10)
	_check(_simultaneous_decks(manager) == 1, "Exploration entrance from silence started an unexpected second deck")
	director._on_camera_profile_changed(&"CHAPEL_APPROACH", &"CHAPEL_GAMEPLAY_RELEASE")
	await _settle(0.38)
	_check(manager.get_current_path() == EXPLORATION, "Repeated reveal restarted or replaced exploration")
	_check(_current_stream(manager) != null and _current_stream(manager).loop, "Exploration cue is not looping")
	_check(_music_player_count(manager) == 2, "MusicManager does not own exactly two crossfade decks")
	_check(not manager.begin_scoped_music(&"second_underground"), "A second scoped scene stole the active music lease")

	# Dialogue ducks are orthogonal to a destination cue switch and cannot abort it.
	var site: ForlornRitualantSite = level.ritualant_site
	var state := site.event_state
	state.ritualant_hostile = true
	director._dialogue_duck_active = true
	director._apply_ducks()
	state.set_resolution(AshBellEventState.Resolution.PROVOKED_RITUALANT)
	_check(manager.get_current_path() == COMBAT, "Committed hostility did not select combat")
	await _settle(0.2)
	_check(_simultaneous_decks(manager) == 2, "Dialogue duck cancelled or collapsed exploration-to-combat overlap")
	await _settle(0.4)
	_check(_current_stream(manager) != null and _current_stream(manager).loop, "Combat cue is not looping")
	_check(is_equal_approx(director.debug_get_active_duck_db(), director.dialogue_duck_db), "Dialogue duck did not remain independently applied")
	director._dialogue_duck_active = false
	director._apply_ducks()
	await _settle(0.2)

	# Violent resolution replaces combat once; completion leaves intentional quiet.
	director.hostile_transition_seconds = 0.18
	site.defile_site()
	_check(manager.get_current_path() == HOSTILE, "Fresh SITE_DEFILED did not select hostile one-shot")
	_check(_current_stream(manager) != null and not _current_stream(manager).loop, "Hostile cue is looping")
	director._on_resolution_changed(AshBellEventState.Resolution.PROVOKED_RITUALANT)
	_check(manager.get_current_path() == HOSTILE, "A later provocation signal replaced the committed terminal cue")
	await _settle(0.25)
	manager.call("_on_player_finished", manager.get_active_deck_index())
	await process_frame
	_check(manager.get_current_path().is_empty(), "Hostile one-shot completion restarted music instead of leaving quiet")
	level.queue_free()
	await _settle(0.4)
	_check(manager.get_current_path() == CAUSEWAY, "Scene teardown did not restore prior Causeway playlist")

	# Exiting during the arrival fade must not let its delayed completion request
	# exploration while the manager restores the prior zone.
	level = _make_level(level_scene)
	director = level.ritualant_music_director
	director.arrival_fade_seconds = 0.4
	director._reveal_reached = true
	director.begin_arrival()
	level.queue_free()
	await _settle(0.25)
	_check(manager.get_current_path() == CAUSEWAY, "Arrival completion resurrected music after scene teardown")

	# Explicit pin emits only after state/fountain commit, starts one-shot, then quiet.
	level = _make_level(level_scene)
	director = level.ritualant_music_director
	_prepare_reveal(director)
	director.exploration_transition_seconds = 0.15
	state = level.ritualant_site.event_state
	state.has_stilling_pin = true
	state.has_thread_knot = true
	state.mark_dialogue_seen(&"first_interaction")
	state.mark_dialogue_seen(&"ask_bell")
	state.mark_dialogue_seen(&"ask_thread")
	state.mark_dialogue_seen(&"ask_orra")
	state.set_resolution(AshBellEventState.Resolution.TOOK_STILLING_PIN)
	level.ritualant_site.set_stilling_pin()
	await _settle(0.2)
	_check(manager.get_current_path() == STILLING, "Successful Set Stilling Pin did not start Stilling Release")
	_check(_current_stream(manager) != null and not _current_stream(manager).loop, "Stilling Release is looping")
	_check(director._peaceful_cue_started, "Explicit Pin edge did not latch its one-shot")
	await _settle(0.55)
	manager.call("_on_player_finished", manager.get_active_deck_index())
	await process_frame
	_check(manager.get_current_path().is_empty(), "Stilling one-shot completion restarted exploration")
	level.queue_free()
	await _settle(0.4)

	# Third valid anchor starts Stilling; hostile survival instead fades to quiet.
	level = _make_level(level_scene)
	director = level.ritualant_music_director
	_prepare_reveal(director)
	director.exploration_transition_seconds = 0.12
	director.combat_transition_seconds = 0.12
	state = level.ritualant_site.event_state
	state.ritualant_hostile = true
	state.set_resolution(AshBellEventState.Resolution.PROVOKED_RITUALANT)
	for anchor_id: StringName in [&"west", &"north", &"east"]:
		level.ritualant_site._on_ritualant_attack_started()
		level.ritualant_site.resolve_thread_anchor(anchor_id)
	_check(manager.get_current_path() == STILLING, "Third ordered valid anchor did not start Stilling Release")
	level.queue_free()
	await _settle(0.4)

	level = _make_level(level_scene)
	director = level.ritualant_music_director
	_prepare_reveal(director)
	director.exploration_transition_seconds = 0.1
	director.combat_transition_seconds = 0.1
	director.terminal_quiet_seconds = 0.12
	state = level.ritualant_site.event_state
	state.ritualant_hostile = true
	state.set_resolution(AshBellEventState.Resolution.PROVOKED_RITUALANT)
	await _settle(0.15)
	state.set_resolution(AshBellEventState.Resolution.RITUALANT_DISSOLVED)
	await _settle(0.4)
	_check(manager.get_current_path().is_empty(), "Nonviolent survival did not resolve to quiet: path=%s mode=%s resolution=%s owner=%s" % [manager.get_current_path(), manager.get("_scoped_mode"), state.resolution, manager.get_scoped_owner()])
	level.queue_free()
	await _settle(0.4)

	# Saved terminal state never replays a fresh violent one-shot.
	level = _make_level(level_scene)
	var terminal_state := level.ritualant_site.event_state
	terminal_state.set_resolution(AshBellEventState.Resolution.SITE_DEFILED)
	var terminal_snapshot: Dictionary = level.ritualant_site.capture_encounter_state()
	level.queue_free()
	await _settle(0.15)
	level = _make_level(level_scene)
	director = level.ritualant_music_director
	director.arrival_fade_seconds = 0.0
	director.terminal_quiet_seconds = 0.0
	director.begin_arrival()
	_check(level.restore_route_state({"encounter": terminal_snapshot}), "Terminal route restore was rejected")
	_check(not director._hostile_cue_started, "Restored SITE_DEFILED replayed its hostile one-shot")
	_check(manager.get_current_path().is_empty(), "Restored terminal state did not remain quiet")
	level.queue_free()
	await _settle(0.15)

	# A successor global playlist preempts a pending scoped fade and stays owner.
	level = _make_level(level_scene)
	director = level.ritualant_music_director
	_prepare_reveal(director)
	director.exploration_transition_seconds = 0.4
	director.departure_fade_seconds = 0.1
	director.begin_departure()
	await _settle(0.12)
	_check(manager.get("_scoped_ducks").has(&"departure"), "Departure did not start its scoped fade")
	director.cancel_departure()
	await _settle(0.18)
	_check(not manager.get("_scoped_ducks").has(&"departure"), "Failed departure rollback did not restore the current music state")
	director._dialogue_duck_active = true
	director._apply_ducks()
	manager.play_playlist([SECOND_CAUSEWAY], true)
	await _settle(0.45)
	level.queue_free()
	await _settle(0.45)
	_check(manager.get_current_path() == SECOND_CAUSEWAY, "Underground teardown clobbered successor-zone music")
	_check(_music_player_count(manager) == 2, "Transitions created extra music players")
	manager.stop_track()
	if _errors.is_empty():
		print("[RitualantFourCueMusic] PASS: timed crossfades, arrival, reveal, independent ducks, outcomes, restore, ownership")
	_finish()


func _make_level(scene: PackedScene) -> ForlornRitualantUnderground:
	var instance := scene.instantiate() as ForlornRitualantUnderground
	root.add_child(instance)
	instance.camera_zone_director.set_process(false)
	instance.ritualant_music_director.set_process(false)
	instance.ritualant_music_director._reveal_reached = false
	instance.ritualant_music_director._exploration_started = false
	instance.ritualant_music_director.departure_fade_seconds = 0.1
	return instance


func _prepare_reveal(director: ForlornRitualantMusicDirector) -> void:
	director.arrival_fade_seconds = 0.0
	director.begin_arrival()
	director._on_camera_profile_changed(&"DEEP_CAVERN", &"CHAPEL_APPROACH")


func _current_stream(manager: Node) -> AudioStreamOggVorbis:
	var index: int = manager.get_active_deck_index()
	var player := manager.get_child(index) as AudioStreamPlayer if index < manager.get_child_count() else null
	return player.stream as AudioStreamOggVorbis if player != null else null


func _simultaneous_decks(manager: Node) -> int:
	var count := 0
	for child in manager.get_children():
		if child is AudioStreamPlayer and child.playing:
			count += 1
	return count


func _music_player_count(manager: Node) -> int:
	var count := 0
	for child in manager.get_children():
		if child is AudioStreamPlayer:
			count += 1
	return count


func _settle(seconds: float) -> void:
	await create_timer(seconds).timeout


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
		push_error("[RitualantFourCueMusic] " + message)


func _finish() -> void:
	if _errors.is_empty():
		quit(0)
	else:
		quit(1)
