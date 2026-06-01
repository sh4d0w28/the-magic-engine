extends Node

var _pickup_scene := preload("res://scenes/environment/PickupItem.tscn")
var _lexeme_catalog := preload("res://scripts/magic/LexemeCatalog.gd").new()

@onready var _hud: Control = $"../UI/HUD"
@onready var _debug_panel: PanelContainer = $"../UI/DebugPanel"
@onready var _spell_manager: Node = $"../SpellManager"
@onready var _voice_power_tracker: Node = $VoicePowerTracker
@onready var _voice_incantation_recognizer: Node = $VoiceIncantationRecognizer
@onready var _diagram_recognizer: Node = $DiagramRecognizer
@onready var _player: CharacterBody3D = $"../Player"
@onready var _inventory_system: Node = $"../Player/InventorySystem"
@onready var _spellbook_system: Node = $"../Player/SpellbookSystem"
@onready var _pickup_container: Node3D = $"../World/Environment/Pickups"

var _voice_mode_enabled := false
var _is_refreshing_spellbook_preview := false


func _ready() -> void:
	_hud.input_submitted.connect(_on_input_submitted)
	_hud.spellbook_title_changed.connect(_on_spellbook_title_changed)
	_hud.spellbook_formula_changed.connect(_on_spellbook_formula_changed)
	_hud.spellbook_diagram_changed.connect(_on_spellbook_diagram_changed)
	_hud.spellbook_notes_changed.connect(_on_spellbook_notes_changed)
	_voice_power_tracker.voice_power_changed.connect(_on_voice_power_changed)
	_voice_incantation_recognizer.listening_started.connect(_on_voice_listening_started)
	_voice_incantation_recognizer.listening_stopped.connect(_on_voice_listening_stopped)
	_voice_incantation_recognizer.mic_level_changed.connect(_on_voice_mic_level_changed)
	_voice_incantation_recognizer.listen_time_changed.connect(_on_voice_listen_time_changed)
	_voice_incantation_recognizer.transcript_updated.connect(_on_voice_transcript_updated)
	_voice_incantation_recognizer.transcript_partial.connect(_on_voice_transcript_partial)
	_voice_incantation_recognizer.transcript_final.connect(_on_voice_transcript_final)
	_voice_incantation_recognizer.recognition_completed.connect(_on_voice_recognition_completed)
	_voice_incantation_recognizer.recognition_failed.connect(_on_voice_recognition_failed)
	_voice_incantation_recognizer.listen_timeout.connect(_on_voice_listen_timeout)
	_voice_incantation_recognizer.backend_state_changed.connect(_on_voice_backend_state_changed)
	_diagram_recognizer.diagram_changed.connect(_on_diagram_changed)
	_inventory_system.inventory_changed.connect(_on_inventory_changed)
	_inventory_system.selected_item_changed.connect(_on_inventory_selection_changed)
	_spellbook_system.lexicon_changed.connect(_on_lexicon_changed)
	_spellbook_system.formula_pages_changed.connect(_on_formula_pages_changed)
	_spellbook_system.selected_formula_page_changed.connect(_on_selected_formula_page_changed)
	get_tree().set_meta("show_debug_hitboxes", false)
	call_deferred("_initialize_ui_state")


func _initialize_ui_state() -> void:
	_hud.set_status("Press Enter to type or M to speak an incantation.")
	_debug_panel.set_message("Waiting for incantation input.")
	_hud.set_mic_mode_enabled(false)
	_hud.set_mic_listening(false)
	_hud.set_mic_level(0.0)
	_hud.set_voice_listen_window(0.0)
	_on_inventory_changed(_inventory_system.get_items())
	_on_inventory_selection_changed(_inventory_system.get_selected_item_name())
	_on_lexicon_changed(_spellbook_system.get_discovered_lexemes())
	_on_selected_formula_page_changed(
		_spellbook_system.get_selected_formula_page(),
		_spellbook_system.get_selected_formula_page_index(),
		_spellbook_system.get_formula_page_count()
	)
	_on_voice_power_changed(_voice_power_tracker.get_voice_power())
	_on_diagram_changed(_diagram_recognizer.get_diagram_result())


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	if event.keycode == KEY_ENTER and not _hud.is_input_open():
		_hud.open_input()
		_hud.set_status("Typing incantation...")
		_debug_panel.set_message("Input mode opened.")
		if _voice_mode_enabled:
			_set_voice_mode_enabled(false)
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_ESCAPE and _hud.is_input_open():
		_hud.close_input()
		_hud.set_status("Input cancelled.")
		_debug_panel.set_message("Input cancelled.")
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("voice_incantation") and not _hud.is_input_open():
		_toggle_voice_mode()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("pickup_item") and not _hud.is_input_open():
		_pickup_nearest_item()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("toggle_inventory"):
		_toggle_inventory_panel()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("toggle_spellbook"):
		_toggle_spellbook_panel()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("toggle_debug_hitboxes"):
		_toggle_debug_hitboxes()
		get_viewport().set_input_as_handled()
		return

	if _hud.is_inventory_panel_open():
		if event.is_action_pressed("inventory_next_item"):
			_inventory_system.select_next_item()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("inventory_previous_item"):
			_inventory_system.select_previous_item()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("inventory_use_item"):
			_use_selected_inventory_item()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("inventory_drop_item"):
			_drop_selected_inventory_item()
			get_viewport().set_input_as_handled()
			return

	if _hud.is_spellbook_panel_open():
		if event.is_action_pressed("spellbook_new_page"):
			_create_spellbook_page()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("spellbook_next_page"):
			_spellbook_system.select_next_formula_page()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("spellbook_previous_page"):
			_spellbook_system.select_previous_formula_page()
			get_viewport().set_input_as_handled()
			return


func normalize_input(raw_input: String) -> String:
	var words := raw_input.strip_edges().to_upper().split(" ", false)
	return " ".join(words)


func _on_input_submitted(raw_input: String) -> void:
	var normalized_input := normalize_input(raw_input)
	if _hud.is_input_open():
		_hud.close_input()
	_submit_incantation(raw_input, normalized_input, "typed", "Typed incantation submitted.")


func _on_voice_power_changed(voice_power: float) -> void:
	_hud.set_voice_power(voice_power)
	_debug_panel.set_voice_power(voice_power)


func _on_diagram_changed(diagram_result: Dictionary) -> void:
	_debug_panel.set_diagram_result(diagram_result)
	_refresh_spellbook_preview()


func _on_inventory_changed(items: Dictionary) -> void:
	_hud.set_inventory_items(items, _inventory_system.get_selected_item_name())


func _on_inventory_selection_changed(item_name: String) -> void:
	_hud.set_inventory_selection(item_name, _inventory_system.get_items())


func _on_lexicon_changed(lexemes: Array[Dictionary]) -> void:
	_hud.set_known_words(lexemes)
	_voice_incantation_recognizer.set_active_vocabulary(_spellbook_system.build_active_vocabulary_payload())
	_refresh_spellbook_preview()


func _on_formula_pages_changed(_pages: Array[Dictionary]) -> void:
	pass


func _on_selected_formula_page_changed(page: Dictionary, index: int, total_count: int) -> void:
	_hud.set_formula_page(page, index, total_count)
	if not _is_refreshing_spellbook_preview:
		_refresh_spellbook_preview()


func _on_spellbook_title_changed(title: String) -> void:
	_spellbook_system.update_selected_formula_page_title(title)


func _on_spellbook_formula_changed(formula_text: String) -> void:
	_spellbook_system.update_selected_formula_page_tokens(formula_text)
	_refresh_spellbook_preview()


func _on_spellbook_diagram_changed(preferred_diagram: String) -> void:
	_spellbook_system.update_selected_formula_page_preferred_diagram(preferred_diagram)
	_refresh_spellbook_preview()


func _on_spellbook_notes_changed(notes: String) -> void:
	_spellbook_system.update_selected_formula_page_notes(notes)


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
	_debug_panel.set_message("Voice backend listening.")


func _on_voice_listening_stopped() -> void:
	_hud.set_mic_listening(false)
	_hud.set_mic_level(0.0)
	_hud.set_voice_listen_window(0.0)
	_hud.set_live_voice_partial("", "", [])
	_hud.set_live_voice_prediction({})


func _on_voice_mic_level_changed(level: float) -> void:
	_hud.set_mic_level(level)


func _on_voice_listen_time_changed(seconds_remaining: float) -> void:
	_hud.set_voice_listen_window(seconds_remaining)


func _on_voice_transcript_updated(raw_text: String, normalized_input: String) -> void:
	_hud.set_last_voice_text(raw_text, normalized_input)


func _on_voice_transcript_partial(raw_text: String, normalized_input: String, tokens: Array[String]) -> void:
	var token_states: Array[Dictionary] = _build_token_states(tokens)
	_hud.set_live_voice_partial(raw_text, normalized_input, token_states)
	_hud.set_live_voice_prediction(_spell_manager.preview_incantation(raw_text, normalized_input))


func _on_voice_transcript_final(raw_text: String, normalized_input: String, _tokens: Array[String]) -> void:
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


func _on_voice_backend_state_changed(state: String) -> void:
	_debug_panel.set_backend_state(state)
	_debug_panel.set_message("Voice backend: %s" % state)


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
	else:
		_hud.set_status("Inventory closed.")


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
		_refresh_spellbook_preview()
	else:
		_hud.set_status("Spellbook closed.")


func _toggle_voice_mode() -> void:
	_set_voice_mode_enabled(not _voice_mode_enabled)
	if _voice_mode_enabled:
		_hud.set_status("Voice mode armed. Speak into the microphone.")
		if not _voice_incantation_recognizer.is_listening():
			_voice_incantation_recognizer.start_listening()
	else:
		if _voice_incantation_recognizer.is_listening():
			_voice_incantation_recognizer.stop_listening()
		_hud.set_status("Voice mode off.")


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


func _pickup_nearest_item() -> void:
	var nearest_pickup: Node = null
	var nearest_distance := INF
	for pickup in get_tree().get_nodes_in_group("pickup_item"):
		var pickup_distance: float = pickup.global_position.distance_to(_player.global_position)
		if pickup_distance > 2.4:
			continue
		if pickup_distance < nearest_distance:
			nearest_distance = pickup_distance
			nearest_pickup = pickup

	if nearest_pickup == null:
		_hud.set_status("No pickup nearby.")
		_debug_panel.set_message("Pickup search found nothing nearby.")
		return

	var result: Dictionary = nearest_pickup.collect_pickup({
		"inventory_system": _inventory_system,
		"spellbook_system": _spellbook_system
	})
	_hud.set_status(str(result.get("message", "Pickup collected.")))
	_debug_panel.set_message(str(result.get("message", "Pickup collected.")))


func _use_selected_inventory_item() -> void:
	var result: Dictionary = _inventory_system.use_selected_item({
		"player": _player,
		"voice_power_tracker": _voice_power_tracker
	})
	_hud.set_status(str(result.get("message", "Unable to use item.")))
	_debug_panel.set_message(str(result.get("message", "Inventory use attempted.")))


func _drop_selected_inventory_item() -> void:
	var result: Dictionary = _inventory_system.drop_selected_item()
	if not result.get("success", false):
		_hud.set_status(str(result.get("message", "Unable to drop item.")))
		return

	var pickup := _pickup_scene.instantiate()
	_pickup_container.add_child(pickup)
	var drop_position: Vector3 = _player.global_position + _player.get_forward_direction() * 1.6
	drop_position.y = 0.3
	pickup.global_position = drop_position
	pickup.configure_item_pickup(str(result.get("item_name", "")), int(result.get("amount", 1)))
	_hud.set_status(str(result.get("message", "Item dropped.")))


func _create_spellbook_page() -> void:
	if not _inventory_system.has_item("Blank Page") or not _inventory_system.has_item("Ink Vial"):
		_hud.set_status("Need a Blank Page and Ink Vial to author a formula.")
		return

	_inventory_system.remove_item("Blank Page", 1)
	_inventory_system.remove_item("Ink Vial", 1)
	_spellbook_system.create_formula_page()
	_hud.set_status("New formula page authored.")
	_refresh_spellbook_preview()


func _refresh_spellbook_preview() -> void:
	if _is_refreshing_spellbook_preview:
		return
	_is_refreshing_spellbook_preview = true
	var page: Dictionary = _spellbook_system.get_selected_formula_page()
	if page.is_empty():
		_hud.set_formula_prediction({})
		_is_refreshing_spellbook_preview = false
		return
	var normalized_input := " ".join(page.get("token_sequence", []))
	var preview_result: Dictionary = _spell_manager.preview_incantation(normalized_input, normalized_input)
	_hud.set_formula_prediction(preview_result)
	_spellbook_system.update_selected_formula_page_preview(
		str(preview_result.get("spell_name", preview_result.get("message", "-"))),
		float(preview_result.get("stability", 0.0))
	)
	_is_refreshing_spellbook_preview = false


func _build_token_states(tokens: Array[String]) -> Array[Dictionary]:
	var token_states: Array[Dictionary] = []
	for token in tokens:
		var lexeme: Dictionary = _lexeme_catalog.get_lexeme_by_surface(token)
		var state := "known"
		if lexeme.is_empty():
			state = "unknown"
		elif not _spellbook_system.has_discovered_lexeme(str(lexeme.get("id", ""))):
			state = "locked"
		token_states.append({
			"token": token,
			"state": state
		})
	return token_states
