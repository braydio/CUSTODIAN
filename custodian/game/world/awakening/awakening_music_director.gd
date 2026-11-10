extends Node
## Awakening's scene-owned cue request adapter. Playback and decks remain in MusicManager.

const OWNER_PREFIX := "awakening_first_return_"
const CUES := {
	&"awakening_01_command_still_speaking": {
		"path": "res://content/audio/music/awakening/awakening_01_command_still_speaking.ogg",
		"context": &"awakening",
		"role": &"exploration",
		"loop": true,
		"gain_db": -2.5,
	}
}

@export_range(0.0, 2.0, 0.05) var arrival_fade_seconds := 0.35
@export_range(0.0, 3.0, 0.05) var departure_fade_seconds := 0.8

var _music_manager: Node
var _owner_id: StringName
var _has_music_claim := false
var _handoff_completed := false
var _cue_started := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_manager = get_node_or_null("/root/MusicManager")
	if _music_manager == null:
		push_warning("[AwakeningMusic] MusicManager is unavailable")
		return
	_owner_id = StringName(OWNER_PREFIX + str(get_instance_id()))
	_has_music_claim = _music_manager.begin_scoped_music(_owner_id)
	if not _has_music_claim:
		return
	_start_cue(&"awakening_01_command_still_speaking", arrival_fade_seconds)


func _start_cue(cue_id: StringName, fade_seconds: float) -> void:
	if _cue_started or not _has_music_claim or not CUES.has(cue_id):
		return
	var cue: Dictionary = CUES[cue_id]
	_cue_started = true
	_music_manager.play_scoped_track(
		_owner_id,
		str(cue["path"]),
		bool(cue["loop"]),
		fade_seconds,
		float(cue["gain_db"])
	)


func complete_hub_handoff() -> void:
	if _handoff_completed or not _has_music_claim:
		return
	_handoff_completed = true
	_has_music_claim = false
	_music_manager.release_scoped_music(_owner_id, departure_fade_seconds, false)


func _exit_tree() -> void:
	if _has_music_claim and _music_manager != null and is_instance_valid(_music_manager):
		_has_music_claim = false
		_music_manager.release_scoped_music(_owner_id)
