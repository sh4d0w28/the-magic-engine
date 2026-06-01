extends Node

signal listening_started
signal listening_stopped
signal mic_level_changed(level: float)
signal listen_time_changed(seconds_remaining: float)
signal transcript_updated(raw_text: String, normalized_input: String)
signal transcript_partial(raw_text: String, normalized_input: String, tokens: Array[String])
signal transcript_final(raw_text: String, normalized_input: String, tokens: Array[String])
signal recognition_completed(result: Dictionary)
signal recognition_failed(message: String)
signal listen_timeout
signal backend_state_changed(state: String)

@export var timeout_seconds: int = 5
@export var minimum_confidence: float = 0.55
@export var backend_url := "ws://127.0.0.1:8765"
@export var auto_launch_backend := true

var _websocket := WebSocketPeer.new()
var _is_listening := false
var _testing_mode := false
var _listen_elapsed_seconds := 0.0
var _active_vocabulary := {
	"discovered_ids": [],
	"surface_forms": [],
	"aliases": {}
}
var _last_backend_state := "disconnected"
var _pending_partial := ""


func _process(delta: float) -> void:
	if _testing_mode:
		if _is_listening:
			_listen_elapsed_seconds += delta
			listen_time_changed.emit(maxf(float(timeout_seconds) - _listen_elapsed_seconds, 0.0))
		return

	_poll_backend()
	if _is_listening:
		_listen_elapsed_seconds += delta
		var seconds_remaining: float = maxf(float(timeout_seconds) - _listen_elapsed_seconds, 0.0)
		listen_time_changed.emit(seconds_remaining)
		if seconds_remaining <= 0.0:
			_finish_with_failure("Timed out waiting for microphone input.", true)


func start_listening() -> bool:
	if _is_listening:
		return false

	_is_listening = true
	_listen_elapsed_seconds = 0.0
	_pending_partial = ""
	listen_time_changed.emit(float(timeout_seconds))
	listening_started.emit()

	if _testing_mode:
		return true

	_connect_backend_if_needed()
	if _websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		_finish_with_failure("Voice backend unavailable.", false)
		return false

	_send_backend_message({
		"type": "configure_session",
		"language": "en-US",
		"phrase_timeout_ms": timeout_seconds * 1000,
		"active_surface_forms": _active_vocabulary.get("surface_forms", []),
		"active_aliases": _active_vocabulary.get("aliases", {}),
		"expected_words": _active_vocabulary.get("discovered_ids", [])
	})
	_send_backend_message({"type": "start_listening"})
	return true


func stop_listening() -> void:
	if not _is_listening:
		return
	_is_listening = false
	_listen_elapsed_seconds = 0.0
	if not _testing_mode and _websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_send_backend_message({"type": "stop_listening"})
	listening_stopped.emit()
	mic_level_changed.emit(0.0)
	listen_time_changed.emit(0.0)


func is_listening() -> bool:
	return _is_listening


func set_testing_mode(is_enabled: bool) -> void:
	_testing_mode = is_enabled


func set_active_vocabulary(vocabulary_payload: Dictionary) -> void:
	_active_vocabulary = vocabulary_payload.duplicate(true)
	if _testing_mode:
		return
	if _websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_send_backend_message({
			"type": "configure_session",
			"language": "en-US",
			"phrase_timeout_ms": timeout_seconds * 1000,
			"active_surface_forms": _active_vocabulary.get("surface_forms", []),
			"active_aliases": _active_vocabulary.get("aliases", {}),
			"expected_words": _active_vocabulary.get("discovered_ids", [])
		})


func simulate_partial(raw_input: String, normalized_input: String) -> void:
	var tokens: Array[String] = []
	for token in normalized_input.split(" ", false):
		tokens.append(str(token))
	transcript_partial.emit(raw_input, normalized_input, tokens)


func simulate_recognition(raw_input: String, normalized_input: String, confidence: float = 1.0) -> void:
	var tokens: Array[String] = []
	for token in normalized_input.split(" ", false):
		tokens.append(str(token))
	transcript_partial.emit(raw_input, normalized_input, tokens)
	transcript_final.emit(raw_input, normalized_input, tokens)
	transcript_updated.emit(raw_input, normalized_input)
	_is_listening = false
	_listen_elapsed_seconds = 0.0
	listening_stopped.emit()
	mic_level_changed.emit(0.0)
	listen_time_changed.emit(0.0)
	recognition_completed.emit({
		"raw_text": raw_input,
		"normalized_input": normalized_input,
		"tokens": tokens,
		"confidence": confidence,
		"success": true
	})


func simulate_failure(message: String) -> void:
	_finish_with_failure(message, false)


func _connect_backend_if_needed() -> void:
	if _websocket.get_ready_state() == WebSocketPeer.STATE_OPEN or _websocket.get_ready_state() == WebSocketPeer.STATE_CONNECTING:
		return
	if auto_launch_backend:
		_try_launch_backend()
	var connect_error := _websocket.connect_to_url(backend_url)
	if connect_error != OK:
		_emit_backend_state("connect_failed")


func _poll_backend() -> void:
	if _websocket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		return
	_websocket.poll()
	match _websocket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if _last_backend_state != "ready":
				_emit_backend_state("ready")
			while _websocket.get_available_packet_count() > 0:
				var packet: PackedByteArray = _websocket.get_packet()
				var parsed: Variant = JSON.parse_string(packet.get_string_from_utf8())
				if typeof(parsed) != TYPE_DICTIONARY:
					continue
				_handle_backend_message(parsed)
		WebSocketPeer.STATE_CONNECTING:
			if _last_backend_state != "connecting":
				_emit_backend_state("connecting")
		WebSocketPeer.STATE_CLOSING:
			if _last_backend_state != "closing":
				_emit_backend_state("closing")


func _handle_backend_message(message: Dictionary) -> void:
	match str(message.get("type", "")):
		"ready":
			_emit_backend_state("ready")
		"level":
			mic_level_changed.emit(float(message.get("level", 0.0)))
		"partial":
			var raw_text: String = str(message.get("raw_text", ""))
			var normalized_input: String = str(message.get("normalized_text", ""))
			var tokens: Array[String] = []
			for token in message.get("tokens", []):
				tokens.append(str(token))
			_pending_partial = raw_text
			transcript_partial.emit(raw_text, normalized_input, tokens)
		"final":
			var raw_text: String = str(message.get("raw_text", ""))
			var normalized_input: String = str(message.get("normalized_text", ""))
			var tokens: Array[String] = []
			for token in message.get("tokens", []):
				tokens.append(str(token))
			var confidence: float = float(message.get("confidence", 1.0))
			transcript_final.emit(raw_text, normalized_input, tokens)
			transcript_updated.emit(raw_text, normalized_input)
			if confidence < minimum_confidence:
				_finish_with_failure("Voice confidence too low (%.2f)." % confidence, false)
				return
			_is_listening = false
			_listen_elapsed_seconds = 0.0
			listening_stopped.emit()
			mic_level_changed.emit(0.0)
			listen_time_changed.emit(0.0)
			recognition_completed.emit({
				"raw_text": raw_text,
				"normalized_input": normalized_input,
				"tokens": tokens,
				"confidence": confidence,
				"success": true
			})
		"error":
			_finish_with_failure(str(message.get("message", "Voice backend error.")), false)


func _finish_with_failure(message: String, timed_out: bool) -> void:
	_is_listening = false
	_listen_elapsed_seconds = 0.0
	if timed_out:
		listen_timeout.emit()
	listening_stopped.emit()
	mic_level_changed.emit(0.0)
	listen_time_changed.emit(0.0)
	recognition_failed.emit(message)


func _send_backend_message(message: Dictionary) -> void:
	if _websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	_websocket.send_text(JSON.stringify(message))


func _emit_backend_state(state: String) -> void:
	_last_backend_state = state
	backend_state_changed.emit(state)


func _try_launch_backend() -> void:
	var script_path := ProjectSettings.globalize_path("res://tools/voice_stt_sidecar.py")
	var candidate_commands := [
		["python", script_path],
		["python3", script_path],
		["py", script_path]
	]
	for candidate in candidate_commands:
		var output: Array = []
		var command: String = candidate[0]
		var arguments: Array[String] = []
		for index in range(1, candidate.size()):
			arguments.append(str(candidate[index]))
		var exit_code := OS.create_process(command, arguments)
		if exit_code > 0:
			_emit_backend_state("launching")
			return
