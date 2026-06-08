extends Node
## MusicManager — autoload for background music.
##
## Plays the current zone's music track. For now, hardcoded to the
## Return Causeway theme until zone-specific routing is needed.

const DEFAULT_MUSIC_PATH := "res://content/audio/music/return_causeway/return_causeway_01.ogg"

var _player: AudioStreamPlayer = null
var _current_path: String = ""


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_ensure_player()
	play_track(DEFAULT_MUSIC_PATH)


func _ensure_player() -> void:
	if _player != null:
		return
	_player = AudioStreamPlayer.new()
	_player.name = "MusicPlayer"
	_player.bus = "Master"
	add_child(_player)


func play_track(path: String) -> void:
	if path.is_empty():
		return
	if path == _current_path and _player.playing:
		return

	var stream := load(path) as AudioStreamOggVorbis
	if stream == null:
		push_warning("[MusicManager] Could not load: %s" % path)
		return

	stream.set_loop(true)
	stream.set_loop_offset(0.0)

	_player.stop()
	_player.stream = stream
	_player.play()
	_current_path = path


func stop_track() -> void:
	_player.stop()
	_current_path = ""


func set_volume_db(value: float) -> void:
	_player.volume_db = value


func get_volume_db() -> float:
	return _player.volume_db if _player != null else 0.0
