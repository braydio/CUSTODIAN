extends SceneTree

const SCENE_PATH := "res://scenes/awakening_first_return.tscn"
const CUE_PATH := "res://content/audio/music/awakening/awakening_01_command_still_speaking.ogg"
const CAUSEWAY := "res://content/audio/music/return_causeway/return_causeway_01.ogg"
const SECOND_CAUSEWAY := "res://content/audio/music/return_causeway/hall_still_answers.ogg"
const CUE_ID: StringName = &"awakening_01_command_still_speaking"

var _errors: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var manager := root.get_node_or_null("MusicManager")
	_check(manager != null, "MusicManager autoload is missing")
	var stream := load(CUE_PATH) as AudioStreamOggVorbis
	_check(stream != null, "Approved runtime OGG did not load as AudioStreamOggVorbis")
	if stream != null:
		_check(absf(stream.get_length() - 120.0) < 0.15, "Runtime cue duration differs from 120 seconds")
	if manager == null or stream == null:
		_finish()
		return

	manager.play_playlist([CAUSEWAY], true)
	var packed := load(SCENE_PATH) as PackedScene
	_check(packed != null, "Production Awakening scene did not load")
	if packed == null:
		_finish()
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var director := scene.get_node_or_null("AwakeningMusicDirector")
	_check(director != null, "Production Awakening scene has no music director")
	_check(not manager.get_scoped_owner().is_empty(), "Awakening did not acquire scoped music")
	_check(manager.get_current_path() == CUE_PATH, "Awakening did not start the approved cue")
	var active_player := manager.call("_active_player") as AudioStreamPlayer
	_check(active_player != null and active_player.stream is AudioStreamOggVorbis and (active_player.stream as AudioStreamOggVorbis).loop, "MusicManager did not configure the active cue to loop")
	_check(_player_count(manager) == 2, "MusicManager is not using exactly its existing two decks")
	if director != null:
		var owner_id: StringName = manager.get_scoped_owner()
		var cue: Dictionary = director.CUES[CUE_ID]
		_check(cue.get("context") == &"awakening" and cue.get("role") == &"exploration", "Cue catalog metadata is incomplete")
		_check(is_equal_approx(float(cue.get("gain_db", 0.0)), -2.5), "Runtime cue gain is not the initial -2.5 dB")
		director.call("_start_cue", CUE_ID, 0.0)
		_check(manager.get_scoped_owner() == owner_id and manager.get_current_path() == CUE_PATH, "Repeated cue request restarted or replaced the track")
		for zone_id in [&"zone02_ambulatory", &"zone03_attestation", &"zone04_locker_reliquary", &"zone05_dust_lung", &"zone06_undergate", &"zone07_gate_of_dust", &"zone08_custodian_approach", &"zone09_chapel_late_service", &"zone10_road_south_reach"]:
			scene.call("_enter_zone", zone_id)
		_check(manager.get_current_path() == CUE_PATH, "Traversing sections 01–10 replaced the Awakening score")
		scene.call("_on_console_acknowledged", null)
		_check(manager.get_current_path() == CUE_PATH, "Console acknowledgement restarted the Awakening score")
		scene.call("restore_after_handoff_failure")
		_check(manager.get_scoped_owner() == owner_id and manager.get_current_path() == CUE_PATH, "Failed handoff changed Awakening music ownership")
		scene.call("complete_hub_handoff")
		_check(manager.get_scoped_owner() == owner_id, "Successful handoff released ownership before its fade")
		await create_timer(0.95).timeout
		_check(manager.get_scoped_owner().is_empty(), "Successful Hub handoff left Awakening's scoped lease active")
		_check(manager.get_current_path().is_empty(), "Successful Hub handoff restored the previous Return Causeway playlist")

	# A successor global claim during a pending fade invalidates stale completion.
	manager.play_playlist([CAUSEWAY], true)
	var successor_owner: StringName = &"awakening_music_smoke_successor"
	_check(manager.begin_scoped_music(successor_owner), "Could not claim successor lease for stale-fade check")
	manager.play_scoped_track(successor_owner, CUE_PATH, true, 0.0, -2.5)
	manager.release_scoped_music(successor_owner, 0.8, false)
	var pending_release_ticket := int(manager.get("_cue_transition_generation"))
	manager.release_scoped_music(successor_owner, 0.8, false)
	_check(int(manager.get("_cue_transition_generation")) == pending_release_ticket, "Repeated release restarted its fade")
	manager.play_playlist([SECOND_CAUSEWAY], true)
	await create_timer(0.95).timeout
	_check(manager.get_scoped_owner().is_empty(), "Stale release callback revived an obsolete owner")
	_check(manager.get_current_path() == SECOND_CAUSEWAY, "Stale release callback replaced a successor playlist")
	var scoped_successor_owner: StringName = &"awakening_music_smoke_scoped_successor"
	_check(manager.begin_scoped_music(scoped_successor_owner), "Could not claim scoped successor after playlist takeover")
	manager.play_scoped_track(scoped_successor_owner, SECOND_CAUSEWAY, true, 0.0)
	await create_timer(0.95).timeout
	_check(manager.get_scoped_owner() == scoped_successor_owner, "Stale Awakening teardown cleared a successor scoped owner")
	_check(manager.get_current_path() == SECOND_CAUSEWAY, "Stale Awakening teardown replaced a successor scoped cue")
	manager.release_scoped_music(scoped_successor_owner, 0.0)

	# Default release continues to restore its snapshot for existing consumers.
	manager.play_playlist([CAUSEWAY], true)
	var legacy_owner: StringName = &"awakening_music_smoke_default_restore"
	_check(manager.begin_scoped_music(legacy_owner), "Could not claim default-restore regression lease")
	manager.play_scoped_track(legacy_owner, CUE_PATH, true, 0.0, -2.5)
	manager.release_scoped_music(legacy_owner, 0.0)
	_check(manager.get_scoped_owner().is_empty(), "Default scoped release did not relinquish ownership")
	_check(manager.get_current_path() == CAUSEWAY, "Default scoped release no longer restores the prior playlist")
	var ordinary_scene := packed.instantiate()
	root.add_child(ordinary_scene)
	await process_frame
	_check(manager.get_current_path() == CUE_PATH, "Second Awakening entry did not claim its cue")
	ordinary_scene.free()
	await create_timer(0.45).timeout
	_check(manager.get_current_path() == CAUSEWAY, "Ordinary Awakening teardown did not restore its prior playlist")

	scene.free()
	_finish()


func _player_count(manager: Node) -> int:
	var count := 0
	for child in manager.get_children():
		if child is AudioStreamPlayer:
			count += 1
	return count


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_errors.append(message)
	push_error("awakening_music_smoke: " + message)


func _finish() -> void:
	var passed := _errors.is_empty()
	print("CUSTODIAN_TEST_RESULT_JSON:" + JSON.stringify({
		"schema": "custodian.headless_test.result.v1",
		"test": "awakening_music_smoke",
		"passed": passed,
		"failure_count": _errors.size(),
		"failures": _errors,
	}))
	if passed:
		print("awakening_music_smoke: PASS")
		quit(0)
		return
	print("awakening_music_smoke: FAIL (%d)" % _errors.size())
	quit(1)
