extends RefCounted
class_name MomentAudioCapture

var requested := false
var available := false
var error := ""
var output_path := ""

var _effect: AudioEffectRecord
var _bus_index := -1
var _effect_index := -1


func start(enabled: bool, absolute_output_path: String) -> void:
	requested = enabled
	output_path = absolute_output_path
	if not enabled:
		return
	_bus_index = AudioServer.get_bus_index("Master")
	if _bus_index < 0:
		error = "Master audio bus is unavailable"
		return
	_effect = AudioEffectRecord.new()
	_effect.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(_bus_index, _effect)
	_effect_index = AudioServer.get_bus_effect_count(_bus_index) - 1
	_effect.set_recording_active(true)


func finish() -> Dictionary:
	if not requested:
		return get_state()
	if _effect == null:
		return get_state()
	var recording := _effect.get_recording()
	_effect.set_recording_active(false)
	if _bus_index >= 0 and _effect_index >= 0:
		AudioServer.remove_bus_effect(_bus_index, _effect_index)
	if recording == null or recording.get_length() <= 0.0:
		error = "audio driver returned no recorded samples"
		return get_state()
	var save_path := output_path.trim_suffix(".wav")
	var save_error := recording.save_to_wav(save_path)
	if save_error != OK:
		error = "could not save review WAV: %s" % error_string(save_error)
		return get_state()
	available = FileAccess.file_exists(output_path)
	if not available:
		error = "recording completed but review WAV was not created"
	return get_state()


func get_state() -> Dictionary:
	return {
		"requested": requested,
		"available": available,
		"output_path": output_path if available else "",
		"error": error,
		"mix_rate_hz": AudioServer.get_mix_rate(),
	}
