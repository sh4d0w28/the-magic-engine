extends Node

signal listening_started
signal recognition_completed(result: Dictionary)
signal recognition_failed(message: String)

@export var timeout_seconds: int = 5
@export var minimum_confidence: float = 0.55

var _worker_thread: Thread
var _is_listening := false


func _process(_delta: float) -> void:
	if _worker_thread != null and _is_listening and not _worker_thread.is_alive():
		var result: Dictionary = _worker_thread.wait_to_finish()
		_worker_thread = null
		_is_listening = false
		_emit_result(result)


func start_listening() -> bool:
	if _is_listening:
		return false

	if OS.get_name() != "Windows":
		recognition_failed.emit("Voice incantation is only wired for Windows right now.")
		return false

	_is_listening = true
	listening_started.emit()
	_worker_thread = Thread.new()
	var start_error := _worker_thread.start(_run_recognition_job)
	if start_error != OK:
		_worker_thread = null
		_is_listening = false
		recognition_failed.emit("Failed to start voice recognizer thread.")
		return false
	return true


func is_listening() -> bool:
	return _is_listening


func simulate_recognition(raw_input: String, normalized_input: String, confidence: float = 1.0) -> void:
	_emit_result({
		"success": true,
		"status": "recognized",
		"raw_text": raw_input,
		"normalized_input": normalized_input,
		"confidence": confidence,
		"error": ""
	})


func simulate_failure(message: String) -> void:
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
		recognition_failed.emit(str(result.get("error", "Voice recognition failed.")))
		return

	var confidence: float = float(result.get("confidence", 0.0))
	if confidence < minimum_confidence:
		recognition_failed.emit("Voice confidence too low (%.2f)." % confidence)
		return

	recognition_completed.emit(result)
