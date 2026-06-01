extends Control

signal input_submitted(text: String)
signal spellbook_title_changed(title: String)
signal spellbook_formula_changed(formula_text: String)
signal spellbook_diagram_changed(preferred_diagram: String)
signal spellbook_notes_changed(notes: String)

@onready var _health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var _mana_label: Label = $MarginContainer/VBoxContainer/ManaLabel
@onready var _score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var _status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var _controls_label: Label = $MarginContainer/VBoxContainer/ControlsLabel
@onready var _voice_power_label: Label = $MarginContainer/VBoxContainer/VoicePowerLabel
@onready var _mic_status_label: Label = $MarginContainer/VBoxContainer/MicStatusLabel
@onready var _mic_level_bar: ProgressBar = $MarginContainer/VBoxContainer/MicLevelBar
@onready var _voice_window_label: Label = $MarginContainer/VBoxContainer/VoiceWindowLabel
@onready var _last_voice_label: Label = $MarginContainer/VBoxContainer/LastVoiceLabel
@onready var _live_transcript_label: Label = $MarginContainer/VBoxContainer/LiveTranscriptLabel
@onready var _live_prediction_label: Label = $MarginContainer/VBoxContainer/LivePredictionLabel
@onready var _combat_feed_label: Label = $MarginContainer/VBoxContainer/CombatFeedLabel
@onready var _input_line: LineEdit = $MarginContainer/VBoxContainer/InputLine
@onready var _inventory_panel: PanelContainer = $InventoryPanel
@onready var _inventory_items_label: Label = $InventoryPanel/MarginContainer/VBoxContainer/InventoryItemsLabel
@onready var _inventory_hint_label: Label = $InventoryPanel/MarginContainer/VBoxContainer/InventoryHintLabel
@onready var _spellbook_panel: PanelContainer = $SpellbookPanel
@onready var _page_status_label: Label = $SpellbookPanel/MarginContainer/VBoxContainer/PageStatusLabel
@onready var _page_hint_label: Label = $SpellbookPanel/MarginContainer/VBoxContainer/PageHintLabel
@onready var _known_words_label: Label = $SpellbookPanel/MarginContainer/VBoxContainer/KnownWordsLabel
@onready var _title_edit: LineEdit = $SpellbookPanel/MarginContainer/VBoxContainer/TitleEdit
@onready var _formula_edit: LineEdit = $SpellbookPanel/MarginContainer/VBoxContainer/IncantationEdit
@onready var _diagram_option_button: OptionButton = $SpellbookPanel/MarginContainer/VBoxContainer/EffectOptionButton
@onready var _formula_prediction_label: Label = $SpellbookPanel/MarginContainer/VBoxContainer/FormulaPredictionLabel
@onready var _diagram_hint_label: Label = $SpellbookPanel/MarginContainer/VBoxContainer/DiagramHintLabel
@onready var _notes_edit: TextEdit = $SpellbookPanel/MarginContainer/VBoxContainer/NotesEdit
@onready var _aim_reticle: Control = $AimReticle

var _mic_mode_enabled := false
var _mic_is_listening := false
var _selected_inventory_item_name := ""
var _suppress_spellbook_signals := false


func _ready() -> void:
	_input_line.text_submitted.connect(_on_input_submitted)
	_title_edit.text_changed.connect(_on_spellbook_title_changed)
	_formula_edit.text_changed.connect(_on_spellbook_formula_changed)
	_diagram_option_button.item_selected.connect(_on_spellbook_diagram_selected)
	_notes_edit.text_changed.connect(_on_spellbook_notes_text_changed)
	_input_line.hide()
	_setup_diagram_options()
	var player := get_tree().get_first_node_in_group("player_controller")
	if player != null and player.has_signal("health_mana_changed"):
		player.health_mana_changed.connect(set_health_and_mana)
		set_health_and_mana(player.get_health(), player.get_mana())
	_controls_label.modulate = Color(0.85, 0.9, 1.0, 0.9)
	_combat_feed_label.modulate = Color(1.0, 0.9, 0.7, 0.95)
	_inventory_hint_label.modulate = Color(0.86, 0.9, 0.98, 0.86)
	_page_hint_label.modulate = Color(0.86, 0.9, 0.98, 0.86)
	_controls_label.text = "Move: WASD  Camera: Hold LMB + Mouse  Type: Enter  Speak: M  Pick Up: E  Inventory: I  Spellbook: B  Voice Power: Hold V  Diagram: Hold RMB  Debug: F3"


func _process(_delta: float) -> void:
	_update_aim_reticle()


func set_health_and_mana(health: float, mana: float) -> void:
	_health_label.text = "Health: %.1f" % health
	_mana_label.text = "Mana: %.1f" % mana


func set_status(message: String) -> void:
	_status_label.text = "Status: %s" % message


func set_voice_power(voice_power: float) -> void:
	_voice_power_label.text = "Voice Power: %.2f" % voice_power


func set_mic_listening(is_listening: bool) -> void:
	_mic_is_listening = is_listening
	_update_mic_status_label()


func set_mic_mode_enabled(is_enabled: bool) -> void:
	_mic_mode_enabled = is_enabled
	_update_mic_status_label()


func set_mic_level(level: float) -> void:
	_mic_level_bar.value = clampf(level, 0.0, 1.0)


func set_voice_listen_window(seconds_remaining: float) -> void:
	if seconds_remaining <= 0.0:
		_voice_window_label.text = "Voice Window: -"
		return
	_voice_window_label.text = "Voice Window: %.1fs" % seconds_remaining


func set_last_voice_text(raw_text: String, normalized_input: String) -> void:
	if raw_text.is_empty():
		_last_voice_label.text = "Last Voice: -"
		return
	_last_voice_label.text = "Last Voice: %s -> %s" % [raw_text, normalized_input]


func set_live_voice_partial(raw_text: String, normalized_input: String, token_states: Array) -> void:
	if raw_text.is_empty():
		_live_transcript_label.text = "Live Voice: -"
		return
	var token_labels: Array[String] = []
	for token_state in token_states:
		var token_label := "%s[%s]" % [str(token_state.get("token", "")), str(token_state.get("state", "known"))]
		token_labels.append(token_label)
	_live_transcript_label.text = "Live Voice: %s -> %s | %s" % [raw_text, normalized_input, " ".join(token_labels)]


func set_live_voice_prediction(result: Dictionary) -> void:
	if result.is_empty():
		_live_prediction_label.text = "Voice Prediction: -"
		return
	_live_prediction_label.text = "Voice Prediction: %s | stab %.2f | cost %.2f" % [
		str(result.get("spell_name", result.get("spell_id", "-"))),
		float(result.get("stability", 0.0)),
		float(result.get("final_cost", 0.0))
	]


func set_score(score: int) -> void:
	_score_label.text = "Score: %d" % score


func set_combat_feed(message: String) -> void:
	_combat_feed_label.text = "Combat: %s" % message


func set_inventory_items(items: Dictionary, selected_item_name: String = "") -> void:
	_selected_inventory_item_name = selected_item_name
	if items.is_empty():
		_inventory_items_label.text = "No items."
		return

	var lines: Array[String] = []
	var item_names: Array = items.keys()
	item_names.sort()
	for item_name in item_names:
		var prefix := "> " if str(item_name) == _selected_inventory_item_name else "  "
		lines.append("%s%s x%d" % [prefix, item_name, int(items[item_name])])
	_inventory_items_label.text = "\n".join(lines)


func set_inventory_selection(selected_item_name: String, items: Dictionary) -> void:
	set_inventory_items(items, selected_item_name)


func set_known_words(lexemes: Array[Dictionary]) -> void:
	if lexemes.is_empty():
		_known_words_label.text = "Known words: none"
		return
	var lines: Array[String] = []
	for lexeme in lexemes:
		var meaning_bits: Array[String] = []
		var semantic_tags: Dictionary = lexeme.get("semantic_tags", {})
		for key in ["element", "action", "target_mode", "motion_mode", "anchor_mode"]:
			var semantic_value: String = str(semantic_tags.get(key, ""))
			if not semantic_value.is_empty():
				meaning_bits.append("%s=%s" % [key, semantic_value])
		lines.append("%s | %s" % [str(lexeme.get("id", "")), ", ".join(meaning_bits)])
	_known_words_label.text = "Known words:\n%s" % "\n".join(lines)


func set_formula_page(page: Dictionary, index: int, total_count: int) -> void:
	_suppress_spellbook_signals = true
	if total_count <= 0 or page.is_empty():
		_page_status_label.text = "No formula pages yet. Press N while the spellbook is open to author a page."
		_title_edit.text = ""
		_formula_edit.text = ""
		_notes_edit.text = ""
		_formula_prediction_label.text = "Predicted outcome: -"
		_diagram_hint_label.text = "Required diagram: -"
		_title_edit.editable = false
		_formula_edit.editable = false
		_diagram_option_button.disabled = true
		_notes_edit.editable = false
		_suppress_spellbook_signals = false
		return

	_page_status_label.text = "Formula Page %d/%d" % [index + 1, total_count]
	_title_edit.editable = true
	_formula_edit.editable = true
	_diagram_option_button.disabled = false
	_notes_edit.editable = true
	_title_edit.text = str(page.get("title", ""))
	_formula_edit.text = " ".join(page.get("token_sequence", []))
	_notes_edit.text = str(page.get("notes", ""))
	var preferred_diagram: String = str(page.get("preferred_diagram", "none"))
	_select_diagram_option(preferred_diagram)
	_formula_prediction_label.text = "Predicted outcome: %s | stability %.2f" % [
		str(page.get("last_result", "-")),
		float(page.get("last_stability", 0.0))
	]
	_diagram_hint_label.text = "Required diagram: %s" % preferred_diagram
	_suppress_spellbook_signals = false


func set_formula_prediction(result: Dictionary) -> void:
	if result.is_empty():
		_formula_prediction_label.text = "Predicted outcome: -"
		return
	_formula_prediction_label.text = "Predicted outcome: %s | stability %.2f | cost %.2f" % [
		str(result.get("spell_name", result.get("spell_id", "-"))),
		float(result.get("stability", 0.0)),
		float(result.get("final_cost", 0.0))
	]


func toggle_inventory_panel() -> bool:
	_inventory_panel.visible = not _inventory_panel.visible
	return _inventory_panel.visible


func close_inventory_panel() -> void:
	_inventory_panel.hide()


func is_inventory_panel_open() -> bool:
	return _inventory_panel.visible


func toggle_spellbook_panel() -> bool:
	_spellbook_panel.visible = not _spellbook_panel.visible
	if _spellbook_panel.visible:
		if _title_edit.editable:
			_title_edit.grab_focus()
	else:
		_title_edit.release_focus()
		_formula_edit.release_focus()
		_notes_edit.release_focus()
	return _spellbook_panel.visible


func close_spellbook_panel() -> void:
	_spellbook_panel.hide()
	_title_edit.release_focus()
	_formula_edit.release_focus()
	_notes_edit.release_focus()


func is_spellbook_panel_open() -> bool:
	return _spellbook_panel.visible


func open_input() -> void:
	_input_line.show()
	_input_line.grab_focus()
	_input_line.clear()
	_aim_reticle.hide()


func close_input() -> void:
	_input_line.hide()
	_input_line.release_focus()
	_aim_reticle.show()


func is_input_open() -> bool:
	return _input_line.visible


func get_current_input() -> String:
	return _input_line.text


func _on_input_submitted(text: String) -> void:
	input_submitted.emit(text)


func _on_spellbook_title_changed(new_text: String) -> void:
	if _suppress_spellbook_signals:
		return
	spellbook_title_changed.emit(new_text)


func _on_spellbook_formula_changed(new_text: String) -> void:
	if _suppress_spellbook_signals:
		return
	spellbook_formula_changed.emit(new_text)


func _on_spellbook_diagram_selected(selected_index: int) -> void:
	if _suppress_spellbook_signals:
		return
	var preferred_diagram := str(_diagram_option_button.get_item_metadata(selected_index))
	spellbook_diagram_changed.emit(preferred_diagram)


func _on_spellbook_notes_text_changed() -> void:
	if _suppress_spellbook_signals:
		return
	spellbook_notes_changed.emit(_notes_edit.text)


func _update_aim_reticle() -> void:
	if not _aim_reticle.visible:
		return
	_aim_reticle.position = get_viewport().get_mouse_position()


func _update_mic_status_label() -> void:
	var state_text := "Off"
	if _mic_is_listening:
		state_text = "Listening..."
	elif _mic_mode_enabled:
		state_text = "Armed"
	_mic_status_label.text = "Mic: %s" % state_text


func _setup_diagram_options() -> void:
	_diagram_option_button.clear()
	for diagram_name in ["none", "circle", "triangle", "circle_with_dot"]:
		_diagram_option_button.add_item(diagram_name.capitalize())
		_diagram_option_button.set_item_metadata(_diagram_option_button.item_count - 1, diagram_name)


func _select_diagram_option(diagram_name: String) -> void:
	for index in range(_diagram_option_button.item_count):
		if str(_diagram_option_button.get_item_metadata(index)) == diagram_name:
			_diagram_option_button.select(index)
			return
	_diagram_option_button.select(0)
