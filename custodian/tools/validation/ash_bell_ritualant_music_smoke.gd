extends SceneTree

const MUSIC_PATH := "res://content/audio/music/ash_bell/forlorn_ritualant_the_ninth_was_never_cast_loop_v1.ogg"
const STILLING_RELEASE_PATH := "res://content/audio/music/ash_bell/forlorn_ritualant_stilling_release_v1.ogg"
const CAUSEWAY_PATH := "res://content/audio/music/return_causeway/return_causeway_01.ogg"
const SECOND_CAUSEWAY_PATH := "res://content/audio/music/return_causeway/hall_still_answers.ogg"
const UNDERGROUND_SCENE := "res://game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_underground.tscn"

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var manager := root.get_node_or_null("MusicManager")
	if manager == null:
		_fail("MusicManager autoload not found")
		return
	var score := load(MUSIC_PATH) as AudioStreamOggVorbis
	if score == null or abs(score.get_length() - 185.80627) > 0.05:
		_fail("Ritualant exploration score missing, corrupt, or wrong loop length")
		return
	var stilling_release := load(STILLING_RELEASE_PATH) as AudioStreamOggVorbis
	if stilling_release == null or abs(stilling_release.get_length() - 38.709646) > 0.05:
		_fail("Stilling Release score missing, corrupt, or wrong one-shot length")
		return
	if stilling_release.loop:
		_fail("Stilling Release source resource must remain non-looping")
		return

	var prior_paths: Array[String] = [CAUSEWAY_PATH, SECOND_CAUSEWAY_PATH]
	manager.play_playlist(prior_paths, true)
	if manager.get_current_path() != CAUSEWAY_PATH:
		_fail("Could not seed existing Causeway music")
		return
	var packed := load(UNDERGROUND_SCENE) as PackedScene
	if packed == null:
		_fail("Cannot load authored Ritualant Underground")
		return
	var level := packed.instantiate()
	root.add_child(level)
	await process_frame
	var player := manager.get_node_or_null("MusicPlayer") as AudioStreamPlayer
	if player == null \
			or player.bus != &"Master" \
			or manager.get_current_path() != MUSIC_PATH \
			or _music_player_count(manager) != 1:
		_fail("Underground did not select Eight Bells")
		return
	var stream := player.stream as AudioStreamOggVorbis
	if stream == null or not stream.loop:
		_fail("Eight Bells exploration stream is not set to loop")
		return

	level.ritualant_site.encounter_completed.emit(AshBellEventState.Resolution.SITE_STABILIZED)
	await create_timer(0.8).timeout
	if manager.get_current_path() != STILLING_RELEASE_PATH:
		_fail("Fresh peaceful completion did not start Stilling Release")
		return
	player = manager.get_node_or_null("MusicPlayer") as AudioStreamPlayer
	stream = player.stream as AudioStreamOggVorbis if player != null else null
	if stream == null or stream.loop:
		_fail("Stilling Release playback stream must be non-looping")
		return
	if abs(manager.get_volume_db() - (-5.4)) > 0.05:
		_fail("Stilling Release playback did not apply the approved -5.4 dB gain")
		return
	manager.call("_on_player_finished")
	await process_frame
	if manager.get_current_path() != MUSIC_PATH:
		_fail("Stilling Release completion did not restore the exploration score")
		return
	stream = player.stream as AudioStreamOggVorbis if player != null else null
	if stream == null or not stream.loop:
		_fail("Restored exploration score did not retain its loop policy")
		return
	await create_timer(0.4).timeout
	if abs(manager.get_volume_db()) > 0.05:
		_fail("Restoring the exploration score did not restore its previous volume")
		return

	level.set("_stilling_release_started", false)
	level.set("_restoring_route_state", true)
	level.ritualant_site.encounter_completed.emit(AshBellEventState.Resolution.SITE_STABILIZED)
	level.set("_restoring_route_state", false)
	if manager.get_current_path() != MUSIC_PATH:
		_fail("Restoring an already-resolved route replayed Stilling Release")
		return
	level.ritualant_site.encounter_completed.emit(AshBellEventState.Resolution.SITE_DEFILED)
	if manager.get_current_path() != MUSIC_PATH:
		_fail("A hostile resolution incorrectly replaced the exploration score")
		return
	root.remove_child(level)
	level.free()
	await process_frame
	if manager.get_current_path() != CAUSEWAY_PATH or manager.get_playlist_paths() != prior_paths:
		_fail("Leaving Underground did not restore the previous playlist")
		return
	player = manager.get_node_or_null("MusicPlayer") as AudioStreamPlayer
	stream = player.stream as AudioStreamOggVorbis if player != null else null
	if stream == null or stream.loop:
		_fail("Restored Causeway music should remain non-looping")
		return

	level = packed.instantiate()
	root.add_child(level)
	await process_frame
	if manager.get_current_path() != MUSIC_PATH or _music_player_count(manager) != 1:
		_fail("Re-entering Underground duplicated playback or missed Eight Bells")
		return
	level.ritualant_site.encounter_completed.emit(AshBellEventState.Resolution.SITE_STABILIZED)
	await create_timer(0.8).timeout
	if manager.get_current_path() != STILLING_RELEASE_PATH:
		_fail("Fresh completion did not start Stilling Release on re-entry")
		return
	root.remove_child(level)
	level.free()
	await process_frame
	if manager.get_current_path() != CAUSEWAY_PATH:
		_fail("Exiting during Stilling Release did not restore the prior zone playlist")
		return

	level = packed.instantiate()
	root.add_child(level)
	await process_frame
	level.ritualant_site.encounter_completed.emit(AshBellEventState.Resolution.SITE_STABILIZED)
	await create_timer(0.8).timeout
	manager.play_playlist([SECOND_CAUSEWAY_PATH], true)
	root.remove_child(level)
	level.free()
	await process_frame
	if manager.get_current_path() != SECOND_CAUSEWAY_PATH:
		_fail("Underground exit overrode music after another zone took authority")
		return
	if _music_player_count(manager) != 1:
		_fail("Music authority changes created duplicate audio players")
		return
	print("[AshBellMusic] PASS: loop, fresh one-shot, restore/hostile gates, -5.4 dB, exit and authority handoff")
	manager.stop_track()
	quit(0)


func _music_player_count(manager: Node) -> int:
	var count := 0
	for child in manager.get_children():
		if child is AudioStreamPlayer:
			count += 1
	return count

func _fail(message: String) -> void:
	push_error("[AshBellMusic] " + message)
	quit(1)
