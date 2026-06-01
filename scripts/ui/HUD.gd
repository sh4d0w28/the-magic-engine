extends Control

signal input_submitted(text: String)
signal spellbook_title_changed(title: String)
signal spellbook_incantation_changed(incantation: String)
signal spellbook_effect_changed(effect_id: String)
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
@onready var _combat_feed_label: Label = $MarginContainer/VBoxContainer/CombatFeedLabel
@onready var _input_line: LineEdit = $MarginContainer/VBoxContainer/InputLine
@onready var _inventory_panel: PanelContainer = $InventoryPanel
@onready var _inventory_items_label: Label = $InventoryPanel/MarginContainer/VBoxContainer/InventoryItemsLabel
@onready var _inventory_hint_label: Label = $InventoryPanel/MarginContainer/VBoxContainer/InventoryHintLabel
@onready var _spellbook_panel: PanelContainer = $SpellbookPanel
@onready var _page_status_label: Label = $SpellbookPanel/MarginContainer/VBoxContainer/PageStatusLabel
@onready var _page_hint_label: Label = $SpellbookPanel/MarginContainer/VBoxContainer/PageHintLabel
@onready var _title_edit: LineEdit = $SpellbookPanel/MarginContainer/VBoxContainer/TitleEdit
@onready var _incantation_edit: LineEdit = $SpellbookPanel/MarginContainer/VBoxContainer/IncantationEdit
@onready var _effect_option_button: OptionButton = $SpellbookPanel/MarginContainer/VBoxContainer/EffectOptionButton
@onready var _diagram_hint_label: Label = $SpellbookPanel/MarginContainer/VBoxContainer/DiagramHintLabel
@onready var _notes_edit: TextEdit = $SpellbookPanel/MarginContainer/VBoxContainer/NotesEdit
@onready var _aim_reticle: Control = $AimReticle

var _mic_mode_enabled := false
var _mic_is_listening := false
var _selected_inventory_item_name := ""
var _spell_effects: Array[Dictionary] = []
var _suppress_spellbook_signals := false


func _ready() -> void:
	_input_line.text_submitted.connect(_on_input_submitted)
	_title_edit.text_changed.connect(_on_spellbook_title_changed)
	_incantation_edit.text_changed.connect(_on_spellbook_incantation_changed)
	_effect_option_button.item_selected.connect(_on_spellbook_effect_selected)
	_notes_edit.text_changed.connect(_on_spellbook_notes_text_changed)
	_input_line.hide()
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


func set_spellbook_effects(spell_effects: Array[Dictionary]) -> void:
	_spell_effects = spell_effects.duplicate(true)
	_suppress_spellbook_signals = true
	_effect_option_button.clear()
	for effect in _spell_effects:
		_effect_option_button.add_item(str(effect.get("name", "Spell")))
	_suppress_spellbook_signals = false


func set_spellbook_page(page: Dictionary, index: int, total_count: int) -> void:
	_suppress_spellbook_signals = true
	if total_count <= 0 or page.is_empty():
		_page_status_label.text = "No pages yet. Press N while the spellbook is open to author a page."
		_title_edit.text = ""
		_incantation_edit.text = ""
		_notes_edit.text = ""
		_diagram_hint_label.text = "Required diagram: -"
		_title_edit.editable = false
		_incantation_edit.editable = false
		_effect_option_button.disabled = true
		_notes_edit.editable = false
		_suppress_spellbook_signals = false
		return

	_page_status_label.text = "Page %d/%d" % [index + 1, total_count]
	_title_edit.editable = true
	_incantation_edit.editable = true
	_effect_option_button.disabled = false
	_notes_edit.editable = true
	_title_edit.text = str(page.get("title", ""))
	_incantation_edit.text = str(page.get("incantation", ""))
	_notes_edit.text = str(page.get("notes", ""))
	var effect_id: String = str(page.get("effect_id", ""))
	var diagram_name: String = str(page.get("diagram", "none"))
	_select_effect_option(effect_id)
	_diagram_hint_label.text = "Required diagram: %s" % diagram_name
	_suppress_spellbook_signals = false


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
		_incantation_edit.release_focus()
		_notes_edit.release_focus()
	return _spellbook_panel.visible


func close_spellbook_panel() -> void:
	_spellbook_panel.hide()
	_title_edit.release_focus()
	_incantation_edit.release_focus()
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


func _on_spellbook_incantation_changed(new_text: String) -> void:
	if _suppress_spellbook_signals:
		return
	spellbook_incantation_changed.emit(new_text)


func _on_spellbook_effect_selected(selected_index: int) -> void:
	if _suppress_spellbook_signals:
		return
	if selected_index < 0 or selected_index >= _spell_effects.size():
		return
	var effect: Dictionary = _spell_effects[selected_index]
	spellbook_effect_changed.emit(str(effect.get("id", "")))


func _on_spellbook_notes_text_changed() -> void:
	if _suppress_spellbook_signals:
		return
	spellbook_notes_changed.emit(_notes_edit.text)


func _update_aim_reticle() -> void:
	if not _aim_reticle.visible:
		return

	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	_aim_reticle.position = mouse_position


func _update_mic_status_label() -> void:
	var state_text := "Off"
	if _mic_is_listening:
		state_text = "Listening..."
	elif _mic_mode_enabled:
		state_text = "Armed"
	_mic_status_label.text = "Mic: %s" % state_text


func _select_effect_option(effect_id: String) -> void:
	for index in range(_spell_effects.size()):
		if str(_spell_effects[index].get("id", "")) == effect_id:
			_effect_option_button.select(index)
			return
	if _spell_effects.is_empty():
		return
	_effect_option_button.select(0)
