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


func play_playlist(paths: Array, restart: bool = false) -> void:
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
	if _playlist_paths.is_empty():
		return
	_playlist_index = (_playlist_index + 1) % _playlist_paths.size()
	_play_playlist_index()


func stop_track() -> void:
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
