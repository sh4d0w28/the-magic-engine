extends Node

@onready var _hud: Control = $"../UI/HUD"
@onready var _debug_panel: PanelContainer = $"../UI/DebugPanel"
@onready var _spell_manager: Node = $"../SpellManager"
@onready var _voice_power_tracker: Node = $VoicePowerTracker
@onready var _voice_incantation_recognizer: Node = $VoiceIncantationRecognizer
@onready var _diagram_recognizer: Node = $DiagramRecognizer
@onready var _inventory_system: Node = $"../Player/InventorySystem"
@onready var _spellbook_system: Node = $"../Player/SpellbookSystem"

var _voice_mode_enabled := false


func _ready() -> void:
	_hud.input_submitted.connect(_on_input_submitted)
	_hud.spellbook_notes_changed.connect(_on_spellbook_notes_changed)
	_voice_power_tracker.voice_power_changed.connect(_on_voice_power_changed)
	_voice_incantation_recognizer.listening_started.connect(_on_voice_listening_started)
	_voice_incantation_recognizer.listening_stopped.connect(_on_voice_listening_stopped)
	_voice_incantation_recognizer.mic_level_changed.connect(_on_voice_mic_level_changed)
	_voice_incantation_recognizer.listen_time_changed.connect(_on_voice_listen_time_changed)
	_voice_incantation_recognizer.transcript_updated.connect(_on_voice_transcript_updated)
	_voice_incantation_recognizer.recognition_completed.connect(_on_voice_recognition_completed)
	_voice_incantation_recognizer.recognition_failed.connect(_on_voice_recognition_failed)
	_voice_incantation_recognizer.listen_timeout.connect(_on_voice_listen_timeout)
	_diagram_recognizer.diagram_changed.connect(_on_diagram_changed)
	_inventory_system.inventory_changed.connect(_on_inventory_changed)
	_spellbook_system.notes_changed.connect(_on_spellbook_notes_loaded)
	_spellbook_system.known_spells_changed.connect(_on_known_spells_changed)
	get_tree().set_meta("show_debug_hitboxes", false)
	call_deferred("_initialize_ui_state")


func _initialize_ui_state() -> void:
	_hud.set_status("Press Enter to type or M to speak an incantation.")
	_debug_panel.set_message("Waiting for typed input.")
	_hud.set_mic_mode_enabled(false)
	_hud.set_mic_listening(false)
	_hud.set_mic_level(0.0)
	_hud.set_voice_listen_window(0.0)
	_on_inventory_changed(_inventory_system.get_items())
	_on_spellbook_notes_loaded(_spellbook_system.get_notes())
	_on_known_spells_changed(_spellbook_system.get_known_spells())
	_on_voice_power_changed(_voice_power_tracker.get_voice_power())
	_on_diagram_changed(_diagram_recognizer.get_diagram_result())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER and not _hud.is_input_open():
			_hud.open_input()
			_hud.set_status("Typing incantation...")
			_debug_panel.set_message("Input mode opened.")
			if _voice_mode_enabled:
				_set_voice_mode_enabled(false)
				_debug_panel.set_message("Input mode opened. Voice mode disarmed.")
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("voice_incantation") and not _hud.is_input_open():
			_toggle_voice_mode()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("toggle_inventory"):
			_toggle_inventory_panel()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("toggle_spellbook"):
			_toggle_spellbook_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and _hud.is_input_open():
			_hud.close_input()
			_hud.set_status("Input cancelled.")
			_debug_panel.set_message("Input cancelled.")
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("toggle_debug_hitboxes"):
			_toggle_debug_hitboxes()
			get_viewport().set_input_as_handled()


func normalize_input(raw_input: String) -> String:
	var words := raw_input.strip_edges().to_upper().split(" ", false)
	return " ".join(words)


func _on_input_submitted(raw_input: String) -> void:
	var normalized_input := normalize_input(raw_input)
	if _hud.is_input_open():
		_hud.close_input()
	_submit_incantation(raw_input, normalized_input, "typed", "Normalized typed input submitted.")


func _on_voice_power_changed(voice_power: float) -> void:
	_hud.set_voice_power(voice_power)
	_debug_panel.set_voice_power(voice_power)


func _on_diagram_changed(diagram_result: Dictionary) -> void:
	_debug_panel.set_diagram_result(diagram_result)


func _on_inventory_changed(items: Dictionary) -> void:
	_hud.set_inventory_items(items)


func _on_known_spells_changed(spells: Array[Dictionary]) -> void:
	_hud.set_known_spells(spells)


func _on_spellbook_notes_loaded(notes: String) -> void:
	_hud.set_spellbook_notes(notes)


func _on_spellbook_notes_changed(notes: String) -> void:
	_spellbook_system.set_notes(notes)


func _toggle_debug_hitboxes() -> void:
	var show_debug_hitboxes: bool = not bool(get_tree().get_meta("show_debug_hitboxes", false))
	get_tree().set_meta("show_debug_hitboxes", show_debug_hitboxes)
	for node in get_tree().get_nodes_in_group("debug_hitbox_owner"):
		if node.has_method("set_debug_hitbox_visible"):
			node.set_debug_hitbox_visible(show_debug_hitboxes)
	_hud.set_status("Debug hitboxes: %s" % ("On" if show_debug_hitboxes else "Off"))
	_debug_panel.set_message("Debug hitboxes %s." % ("enabled" if show_debug_hitboxes else "disabled"))


func _on_voice_listening_started() -> void:
	_hud.set_status("Listening for voice incantation...")
	_hud.set_mic_listening(true)
	_debug_panel.set_message("Microphone listener started.")


func _on_voice_listening_stopped() -> void:
	_hud.set_mic_listening(false)
	_hud.set_mic_level(0.0)
	_hud.set_voice_listen_window(0.0)


func _on_voice_mic_level_changed(level: float) -> void:
	_hud.set_mic_level(level)


func _on_voice_listen_time_changed(seconds_remaining: float) -> void:
	_hud.set_voice_listen_window(seconds_remaining)


func _on_voice_transcript_updated(raw_text: String, normalized_input: String) -> void:
	_hud.set_last_voice_text(raw_text, normalized_input)


func _on_voice_recognition_completed(result: Dictionary) -> void:
	var raw_input: String = str(result.get("raw_text", ""))
	var normalized_input: String = normalize_input(str(result.get("normalized_input", raw_input)))
	_submit_incantation(raw_input, normalized_input, "voice", "Voice incantation recognized (conf %.2f)." % float(result.get("confidence", 0.0)))
	_queue_voice_rearm_if_needed()


func _on_voice_recognition_failed(message: String) -> void:
	_hud.set_status("Voice recognition failed.")
	_debug_panel.set_message(message)
	_queue_voice_rearm_if_needed()


func _on_voice_listen_timeout() -> void:
	if _voice_mode_enabled:
		_hud.set_status("Voice listen timed out. Rearming...")
		_debug_panel.set_message("Voice listen timed out. Rearming.")
	else:
		_hud.set_status("Voice listen timed out.")
		_debug_panel.set_message("Voice listen timed out.")


func _submit_incantation(raw_input: String, normalized_input: String, input_type: String, debug_message: String) -> void:
	_debug_panel.set_submitted_input(raw_input, normalized_input)
	if normalized_input.is_empty():
		_hud.set_status("No incantation submitted.")
		_debug_panel.set_message("Submission was empty.")
		return

	_hud.set_status("Submitted: %s" % normalized_input)
	_debug_panel.set_message(debug_message)
	if input_type == "voice" and _spell_manager.has_method("submit_voice_incantation"):
		_spell_manager.submit_voice_incantation(raw_input, normalized_input)
	elif _spell_manager.has_method("submit_typed_incantation"):
		_spell_manager.submit_typed_incantation(raw_input, normalized_input)


func _toggle_inventory_panel() -> void:
	if _hud.is_input_open():
		_hud.close_input()
	if _hud.is_spellbook_panel_open():
		_hud.close_spellbook_panel()
	var is_open: bool = _hud.toggle_inventory_panel()
	if is_open:
		if _voice_mode_enabled:
			_set_voice_mode_enabled(false)
		_hud.set_status("Inventory opened.")
		_debug_panel.set_message("Inventory panel opened.")
	else:
		_hud.set_status("Inventory closed.")
		_debug_panel.set_message("Inventory panel closed.")


func _toggle_spellbook_panel() -> void:
	if _hud.is_input_open():
		_hud.close_input()
	if _hud.is_inventory_panel_open():
		_hud.close_inventory_panel()
	var is_open: bool = _hud.toggle_spellbook_panel()
	if is_open:
		if _voice_mode_enabled:
			_set_voice_mode_enabled(false)
		_hud.set_status("Spellbook opened.")
		_debug_panel.set_message("Spellbook panel opened.")
	else:
		_hud.set_status("Spellbook closed.")
		_debug_panel.set_message("Spellbook panel closed.")


func _toggle_voice_mode() -> void:
	_set_voice_mode_enabled(not _voice_mode_enabled)
	if _voice_mode_enabled:
		_hud.set_status("Voice mode armed. Speak after each listen.")
		_debug_panel.set_message("Voice mode armed.")
		if not _voice_incantation_recognizer.is_listening():
			_voice_incantation_recognizer.start_listening()
	else:
		if _voice_incantation_recognizer.is_listening():
			_hud.set_status("Voice mode disarmed. Current listen will finish.")
			_debug_panel.set_message("Voice mode disarmed. Current listen will finish.")
		else:
			_hud.set_status("Voice mode off.")
			_debug_panel.set_message("Voice mode disarmed.")


func _set_voice_mode_enabled(is_enabled: bool) -> void:
	_voice_mode_enabled = is_enabled
	_hud.set_mic_mode_enabled(is_enabled)
	if not is_enabled:
		_hud.set_mic_level(0.0)
		_hud.set_voice_listen_window(0.0)


func _queue_voice_rearm_if_needed() -> void:
	if _voice_mode_enabled:
		call_deferred("_restart_voice_listening_if_armed")


func _restart_voice_listening_if_armed() -> void:
	if _voice_mode_enabled and not _hud.is_input_open() and not _voice_incantation_recognizer.is_listening():
		_voice_incantation_recognizer.start_listening()
