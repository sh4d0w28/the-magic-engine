extends Node

signal listening_started
signal listening_stopped
signal mic_level_changed(level: float)
signal transcript_updated(raw_text: String, normalized_input: String)
signal recognition_completed(result: Dictionary)
signal recognition_failed(message: String)

@export var timeout_seconds: int = 5
@export var minimum_confidence: float = 0.55

const _MIC_BUS_NAME := "MicMonitor"

var _worker_thread: Thread
var _is_listening := false
var _testing_mode := false
var _mic_player: AudioStreamPlayer
var _capture_effect: AudioEffectCapture


func _ready() -> void:
	_setup_mic_monitor()


func _process(_delta: float) -> void:
	if _is_listening and not _testing_mode:
		mic_level_changed.emit(_consume_mic_level())
	if _worker_thread != null and _is_listening and not _worker_thread.is_alive():
		var result: Dictionary = _worker_thread.wait_to_finish()
		_worker_thread = null
		_is_listening = false
		_stop_mic_monitor()
		_emit_result(result)


func start_listening() -> bool:
	if _is_listening:
		return false

	if OS.get_name() != "Windows":
		recognition_failed.emit("Voice incantation is only wired for Windows right now.")
		return false

	_is_listening = true
	_start_mic_monitor()
	listening_started.emit()
	if _testing_mode:
		return true
	_worker_thread = Thread.new()
	var start_error := _worker_thread.start(_run_recognition_job)
	if start_error != OK:
		_worker_thread = null
		_is_listening = false
		_stop_mic_monitor()
		recognition_failed.emit("Failed to start voice recognizer thread.")
		return false
	return true


func is_listening() -> bool:
	return _is_listening


func set_testing_mode(is_enabled: bool) -> void:
	_testing_mode = is_enabled


func simulate_recognition(raw_input: String, normalized_input: String, confidence: float = 1.0) -> void:
	_is_listening = false
	_stop_mic_monitor()
	_emit_result({
		"success": true,
		"status": "recognized",
		"raw_text": raw_input,
		"normalized_input": normalized_input,
		"confidence": confidence,
		"error": ""
	})


func simulate_failure(message: String) -> void:
	_is_listening = false
	_stop_mic_monitor()
	_emit_result({
		"success": false,
		"status": "error",
		"raw_text": "",
		"normalized_input": "",
		"confidence": 0.0,
		"error": message
	})


func _run_recognition_job() -> Dictionary:
	var script_path := ProjectSettings.globalize_path("res://tools/recognize_incantation.ps1")
	var output: Array = []
	var arguments := [
		"-NoProfile",
		"-ExecutionPolicy",
		"Bypass",
		"-File",
		script_path,
		"-TimeoutSeconds",
		str(timeout_seconds)
	]
	var exit_code := OS.execute("powershell.exe", arguments, output, true)
	var stdout_text := ""
	if not output.is_empty():
		stdout_text = "\n".join(output).strip_edges()

	if stdout_text.is_empty():
		return {
			"success": false,
			"status": "error",
			"raw_text": "",
			"normalized_input": "",
			"confidence": 0.0,
			"error": "Voice recognizer returned no output (exit %d)." % exit_code
		}

	var parsed: Variant = JSON.parse_string(stdout_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {
			"success": false,
			"status": "error",
			"raw_text": "",
			"normalized_input": "",
			"confidence": 0.0,
			"error": "Voice recognizer returned invalid JSON."
		}

	var result: Dictionary = parsed
	if exit_code != 0 and bool(result.get("success", false)):
		result["success"] = false
		result["error"] = "Voice recognizer exited with code %d." % exit_code
	return result


func _emit_result(result: Dictionary) -> void:
	if not bool(result.get("success", false)):
		listening_stopped.emit()
		mic_level_changed.emit(0.0)
		recognition_failed.emit(str(result.get("error", "Voice recognition failed.")))
		return

	var confidence: float = float(result.get("confidence", 0.0))
	if confidence < minimum_confidence:
		listening_stopped.emit()
		mic_level_changed.emit(0.0)
		recognition_failed.emit("Voice confidence too low (%.2f)." % confidence)
		return

	transcript_updated.emit(
		str(result.get("raw_text", "")),
		str(result.get("normalized_input", ""))
	)
	listening_stopped.emit()
	mic_level_changed.emit(0.0)
	recognition_completed.emit(result)


func _setup_mic_monitor() -> void:
	if AudioServer.get_bus_index(_MIC_BUS_NAME) == -1:
		AudioServer.add_bus()
		var bus_index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, _MIC_BUS_NAME)
		AudioServer.add_bus_effect(bus_index, AudioEffectCapture.new(), 0)

	var monitor_bus_index := AudioServer.get_bus_index(_MIC_BUS_NAME)
	var effect := AudioServer.get_bus_effect(monitor_bus_index, 0)
	if effect is AudioEffectCapture:
		_capture_effect = effect

	_mic_player = AudioStreamPlayer.new()
	_mic_player.name = "VoiceMicMonitor"
	_mic_player.stream = AudioStreamMicrophone.new()
	_mic_player.bus = _MIC_BUS_NAME
	_mic_player.volume_db = -80.0
	add_child(_mic_player)


func _start_mic_monitor() -> void:
	if _capture_effect != null:
		_capture_effect.clear_buffer()
	if _mic_player != null and not _mic_player.playing:
		_mic_player.play()


func _stop_mic_monitor() -> void:
	if _mic_player != null and _mic_player.playing:
		_mic_player.stop()
	if _capture_effect != null:
		_capture_effect.clear_buffer()


func _consume_mic_level() -> float:
	if _capture_effect == null:
		return 0.0

	var frames_available := _capture_effect.get_frames_available()
	if frames_available <= 0:
		return 0.0

	var sample_count := mini(frames_available, 2048)
	var buffer: PackedVector2Array = _capture_effect.get_buffer(sample_count)
	if buffer.is_empty():
		return 0.0

	var peak := 0.0
	for sample in buffer:
		peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
	return clampf(peak, 0.0, 1.0)
