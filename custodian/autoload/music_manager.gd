extends Node
## MusicManager — autoload for background music.
##
## Plays the current zone's music playlist. For now, hardcoded to the
## two-track Return Causeway sequence plus exclusive owner-scoped music claims.

signal scoped_track_finished(owner_id: StringName, path: String)

const DEFAULT_MUSIC_PATHS := [
	"res://content/audio/music/return_causeway/return_causeway_01.ogg",
	"res://content/audio/music/return_causeway/hall_still_answers.ogg",
]

var _player: AudioStreamPlayer = null
var _current_path: String = ""
var _playlist_paths: Array[String] = []
var _playlist_index: int = 0
var _scoped_owner: StringName = &""
var _scoped_snapshot: Dictionary = {}
var _scoped_mode: StringName = &""
var _scoped_path := ""
var _scoped_base_volume_db := 0.0
var _scoped_ducks: Dictionary = {}
var _transition_tween: Tween
var _transition_generation := 0


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

	var replacing_scoped_claim := not _scoped_owner.is_empty()
	# A new global playlist is a successor-zone authority claim. It must never
	# later be overwritten by an older scoped level restoring its snapshot.
	_cancel_transition()
	_scoped_owner = &""
	_scoped_snapshot.clear()
	_scoped_mode = &""
	_scoped_path = ""
	_scoped_ducks.clear()

	_ensure_player()
	if not replacing_scoped_claim \
	and not restart \
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
		var source := load(path) as AudioStreamOggVorbis
		var stream := source.duplicate(true) as AudioStreamOggVorbis if source != null else null
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
	if not _scoped_owner.is_empty():
		if _scoped_mode == &"one_shot":
			var owner_id := _scoped_owner
			var finished_path := _scoped_path
			_scoped_mode = &"silent"
			_scoped_path = ""
			if _player != null:
				_player.stop()
				_player.stream = null
			_current_path = ""
			scoped_track_finished.emit(owner_id, finished_path)
		return
	if _playlist_paths.is_empty():
		return
	_playlist_index = (_playlist_index + 1) % _playlist_paths.size()
	_play_playlist_index()


func stop_track() -> void:
	_cancel_transition()
	_scoped_owner = &""
	_scoped_snapshot.clear()
	_scoped_mode = &""
	_scoped_path = ""
	_scoped_ducks.clear()
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
	if not _scoped_owner.is_empty():
		_scoped_base_volume_db = value
		_apply_scoped_volume(0.0)
	else:
		_player.volume_db = value


func get_volume_db() -> float:
	return _player.volume_db if _player != null else 0.0


func begin_scoped_music(owner_id: StringName) -> bool:
	if owner_id.is_empty():
		return false
	if _scoped_owner == owner_id:
		return true
	# Scoped scenes cannot silently steal another scene's lease. A successor
	# zone takes authority through play_playlist(), which explicitly releases it.
	if not _scoped_owner.is_empty():
		return false
	_cancel_transition()
	_scoped_snapshot = {
		"paths": _playlist_paths.duplicate(),
		"index": _playlist_index,
		"path": _current_path,
		"playing": _player != null and _player.playing,
		"position": _player.get_playback_position() if _player != null else 0.0,
		"volume_db": _player.volume_db if _player != null else 0.0,
	}
	_scoped_owner = owner_id
	_scoped_mode = &"claimed"
	_scoped_path = ""
	_scoped_base_volume_db = _player.volume_db if _player != null else 0.0
	_scoped_ducks.clear()
	return true


func play_scoped_track(
	owner_id: StringName,
	path: String,
	loop: bool,
	fade_seconds: float = 0.45,
	volume_db: float = 0.0
) -> void:
	if owner_id.is_empty() or owner_id != _scoped_owner or path.is_empty():
		return
	var source := load(path) as AudioStreamOggVorbis
	if source == null:
		push_warning("[MusicManager] Could not load scoped cue: %s" % path)
		return
	var stream := source.duplicate(true) as AudioStreamOggVorbis
	if stream == null:
		return
	stream.set_loop(loop)
	stream.set_loop_offset(0.0)
	var ticket := _begin_transition()
	if _player != null and _player.playing and fade_seconds > 0.0:
		await _fade_player(-60.0, fade_seconds, ticket)
	if ticket != _transition_generation or owner_id != _scoped_owner:
		return
	_ensure_player()
	_player.stop()
	_player.stream = stream
	_scoped_path = path
	_current_path = path
	_scoped_mode = &"loop" if loop else &"one_shot"
	_scoped_base_volume_db = volume_db
	_player.volume_db = -60.0 if fade_seconds > 0.0 else _effective_scoped_volume()
	_player.play()
	if fade_seconds > 0.0:
		await _fade_player(_effective_scoped_volume(), fade_seconds, ticket)


func set_scoped_duck(
	owner_id: StringName,
	duck_id: StringName,
	active: bool,
	amount_db: float = -6.0,
	fade_seconds: float = 0.12
) -> void:
	if owner_id.is_empty() or owner_id != _scoped_owner or duck_id.is_empty():
		return
	if active:
		_scoped_ducks[duck_id] = minf(0.0, amount_db)
	else:
		_scoped_ducks.erase(duck_id)
	_apply_scoped_volume(fade_seconds)


func stop_scoped_music(owner_id: StringName, fade_seconds: float = 0.35) -> void:
	if owner_id.is_empty() or owner_id != _scoped_owner:
		return
	var ticket := _begin_transition()
	_scoped_mode = &"silent"
	_scoped_path = ""
	_scoped_ducks.clear()
	if _player == null:
		return
	if _player.playing and fade_seconds > 0.0:
		await _fade_player(-60.0, fade_seconds, ticket)
	if ticket != _transition_generation or owner_id != _scoped_owner:
		return
	_player.stop()
	_player.stream = null
	_current_path = ""


func release_scoped_music(owner_id: StringName, fade_seconds: float = 0.35) -> void:
	if owner_id.is_empty() or owner_id != _scoped_owner:
		return
	var snapshot := _scoped_snapshot.duplicate(true)
	var ticket := _begin_transition()
	_scoped_ducks.clear()
	if _player != null and _player.playing and fade_seconds > 0.0:
		await _fade_player(-60.0, fade_seconds, ticket)
	if ticket != _transition_generation or owner_id != _scoped_owner:
		return
	_scoped_owner = &""
	_scoped_mode = &""
	_scoped_path = ""
	_scoped_snapshot.clear()
	if _player == null:
		return
	var paths: Array[String] = []
	for value: Variant in snapshot.get("paths", []):
		paths.append(str(value))
	_playlist_paths = paths
	_playlist_index = int(snapshot.get("index", 0))
	var path := str(snapshot.get("path", ""))
	if not bool(snapshot.get("playing", false)) or path.is_empty():
		_player.stop()
		_player.stream = null
		_current_path = ""
		return
	var source := load(path) as AudioStreamOggVorbis
	var stream := source.duplicate(true) as AudioStreamOggVorbis if source != null else null
	if stream == null:
		_player.stop()
		_player.stream = null
		_current_path = ""
		return
	stream.set_loop(false)
	stream.set_loop_offset(0.0)
	_player.stop()
	_player.stream = stream
	_player.volume_db = -60.0 if fade_seconds > 0.0 else float(snapshot.get("volume_db", 0.0))
	_player.play(maxf(0.0, float(snapshot.get("position", 0.0))))
	_current_path = path
	if fade_seconds > 0.0:
		var restore_ticket := _begin_transition()
		await _fade_player(float(snapshot.get("volume_db", 0.0)), fade_seconds, restore_ticket)


func get_scoped_owner() -> StringName:
	return _scoped_owner


func _apply_scoped_volume(fade_seconds: float) -> void:
	if _player == null or _scoped_owner.is_empty():
		return
	var ticket := _begin_transition()
	if fade_seconds <= 0.0:
		_player.volume_db = _effective_scoped_volume()
		return
	_fade_player(_effective_scoped_volume(), fade_seconds, ticket)


func _effective_scoped_volume() -> float:
	var duck_db := 0.0
	for value: Variant in _scoped_ducks.values():
		duck_db = minf(duck_db, float(value))
	return clampf(_scoped_base_volume_db + duck_db, -60.0, 0.0)


func _begin_transition() -> int:
	_cancel_transition()
	_transition_generation += 1
	return _transition_generation


func _cancel_transition() -> void:
	_transition_generation += 1
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_tween = null


func _fade_player(target_db: float, seconds: float, ticket: int) -> void:
	if _player == null or ticket != _transition_generation:
		return
	var tween := create_tween()
	_transition_tween = tween
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_player, "volume_db", target_db, maxf(0.01, seconds))
	await tween.finished
	if ticket == _transition_generation and _transition_tween == tween:
		_transition_tween = null
