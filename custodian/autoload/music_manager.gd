extends Node
## MusicManager — autoload for background music.
##
## Plays the current zone's music playlist. For now, hardcoded to the
## two-track Return Causeway sequence until zone-specific routing is needed.

const DEFAULT_MUSIC_PATHS := [
	"res://content/audio/music/return_causeway/return_causeway_01.ogg",
	"res://content/audio/music/return_causeway/hall_still_answers.ogg",
]

var _player: AudioStreamPlayer = null
var _current_path: String = ""
var _playlist_paths: Array[String] = []
var _playlist_index: int = 0
var _one_shot_return_state: Dictionary = {}
var _music_transition_generation := 0
var _music_fade_tween: Tween


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless":
		return

	_ensure_player()
	play_playlist(DEFAULT_MUSIC_PATHS)


func _exit_tree() -> void:
	if _player == null:
		return

	_player.stop()
	_player.stream = null
	_player = null
	_current_path = ""
	_playlist_paths.clear()
	_playlist_index = 0


func _ensure_player() -> void:
	if _player != null:
		return
	_player = AudioStreamPlayer.new()
	_player.name = "MusicPlayer"
	_player.bus = "Master"
	_player.finished.connect(_on_player_finished)
	add_child(_player)


func play_track(path: String) -> void:
	if path.is_empty():
		return
	play_playlist([path])



# Eight Bells: scoped single-cue looping; normal sequential playlists stay non-looping.
func play_loop_track(path: String) -> void:
	if path.is_empty():
		return
	_cancel_one_shot_for_override()
	_ensure_player()
	if _current_path == path and _player.playing:
		var active_stream := _player.stream as AudioStreamOggVorbis
		if active_stream != null and active_stream.loop:
			return
	var loaded := load(path) as AudioStreamOggVorbis
	if loaded == null:
		push_warning("[MusicManager] Could not load loop: %s" % path)
		return
	var stream := loaded.duplicate(true) as AudioStreamOggVorbis
	stream.set_loop(true)
	stream.set_loop_offset(0.0)
	_player.stop()
	_player.stream = stream
	_playlist_paths = [path]
	_playlist_index = 0
	_player.play()
	_current_path = path


func play_one_shot_track(
	path: String,
	attenuation_db: float = -5.4,
	fade_seconds: float = 0.35
) -> void:
	if path.is_empty():
		return
	var loaded := load(path) as AudioStreamOggVorbis
	if loaded == null:
		push_warning("[MusicManager] Could not load one-shot: %s" % path)
		return
	_ensure_player()
	if _player == null:
		return
	_cancel_one_shot_for_override()
	var return_stream := _player.stream as AudioStreamOggVorbis
	_one_shot_return_state = {
		"path": _current_path,
		"paths": _playlist_paths.duplicate(),
		"index": _playlist_index,
		"volume_db": _player.volume_db,
		"loop": return_stream != null and return_stream.loop,
	}
	_playlist_paths.clear()
	_playlist_index = 0
	_music_transition_generation += 1
	var generation := _music_transition_generation
	await _fade_music_to(-60.0, fade_seconds, generation)
	if generation != _music_transition_generation or _one_shot_return_state.is_empty():
		return
	var stream := loaded.duplicate(true) as AudioStreamOggVorbis
	stream.set_loop(false)
	stream.set_loop_offset(0.0)
	_player.stop()
	_player.stream = stream
	_player.volume_db = -60.0
	_player.play()
	_current_path = path
	await _fade_music_to(float(_one_shot_return_state["volume_db"]) + attenuation_db,
		fade_seconds, generation)


func cancel_one_shot_and_restore() -> bool:
	if _one_shot_return_state.is_empty():
		return false
	_music_transition_generation += 1
	if _music_fade_tween != null and _music_fade_tween.is_running():
		_music_fade_tween.kill()
	if _player != null:
		_player.stop()
		_player.stream = null
	_restore_one_shot_return_state()
	return true


func _cancel_one_shot_for_override() -> void:
	if _one_shot_return_state.is_empty():
		return
	_music_transition_generation += 1
	if _music_fade_tween != null and _music_fade_tween.is_running():
		_music_fade_tween.kill()
	if _player != null:
		_player.volume_db = float(_one_shot_return_state["volume_db"])
		_player.stop()
		_player.stream = null
	_one_shot_return_state.clear()
	_current_path = ""


func _fade_music_to(target_db: float, duration: float, generation: int) -> void:
	if _player == null or duration <= 0.0:
		if _player != null:
			_player.volume_db = target_db
		return
	if _music_fade_tween != null and _music_fade_tween.is_running():
		_music_fade_tween.kill()
	_music_fade_tween = create_tween()
	_music_fade_tween.tween_property(_player, "volume_db", target_db, duration)
	await _music_fade_tween.finished
	if generation != _music_transition_generation:
		return


func _restore_one_shot_return_state(fade_in: bool = false) -> void:
	if _one_shot_return_state.is_empty():
		return
	var state := _one_shot_return_state
	_one_shot_return_state = {}
	_playlist_paths.clear()
	for path: Variant in state["paths"]:
		_playlist_paths.append(str(path))
	_playlist_index = int(state["index"])
	if _player == null:
		_current_path = ""
		return
	var target_volume_db := float(state["volume_db"])
	_player.volume_db = -60.0 if fade_in else target_volume_db
	if bool(state["loop"]):
		play_loop_track(str(state["path"]))
	elif not _playlist_paths.is_empty():
		_play_playlist_index()
	else:
		_player.stream = null
		_current_path = ""
	if fade_in and _player.playing:
		_music_transition_generation += 1
		_fade_music_to(target_volume_db, 0.35, _music_transition_generation)

func play_playlist(paths: Array, restart: bool = false) -> void:
	_cancel_one_shot_for_override()
	var normalized_paths: Array[String] = []
	for path_variant: Variant in paths:
		var path := str(path_variant)
		if not path.is_empty() and not normalized_paths.has(path):
			normalized_paths.append(path)
	if normalized_paths.is_empty():
		return

	_ensure_player()
	if not restart \
	and normalized_paths == _playlist_paths \
	and _player.playing:
		return
	_playlist_paths = normalized_paths
	_playlist_index = 0
	_play_playlist_index()


func _play_playlist_index() -> void:
	if _player == null or _playlist_paths.is_empty():
		return
	for attempt: int in range(_playlist_paths.size()):
		var index := (_playlist_index + attempt) % _playlist_paths.size()
		var path := _playlist_paths[index]
		var stream := load(path) as AudioStreamOggVorbis
		if stream == null:
			push_warning("[MusicManager] Could not load: %s" % path)
			continue
		stream.set_loop(false)
		stream.set_loop_offset(0.0)
		_playlist_index = index
		_player.stop()
		_player.stream = stream
		_player.play()
		_current_path = path
		return
	_player.stop()
	_player.stream = null
	_current_path = ""


func _on_player_finished() -> void:
	if not _one_shot_return_state.is_empty():
		_restore_one_shot_return_state(true)
		return
	if _playlist_paths.is_empty():
		return
	_playlist_index = (_playlist_index + 1) % _playlist_paths.size()
	_play_playlist_index()


func stop_track() -> void:
	_cancel_one_shot_for_override()
	if _player == null:
		return

	_player.stop()
	_player.stream = null
	_current_path = ""
	_playlist_paths.clear()
	_playlist_index = 0


func get_current_path() -> String:
	return _current_path


func get_playlist_paths() -> Array[String]:
	return _playlist_paths.duplicate()


func get_playlist_index() -> int:
	return _playlist_index


func set_volume_db(value: float) -> void:
	_ensure_player()
	_player.volume_db = value


func get_volume_db() -> float:
	return _player.volume_db if _player != null else 0.0
