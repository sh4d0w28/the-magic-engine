extends Control

signal input_submitted(text: String)

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
@onready var _aim_reticle: Control = $AimReticle

var _mic_mode_enabled := false
var _mic_is_listening := false


func _ready() -> void:
	_input_line.text_submitted.connect(_on_input_submitted)
	_input_line.hide()
	var player := get_tree().get_first_node_in_group("player_controller")
	if player != null and player.has_signal("health_mana_changed"):
		player.health_mana_changed.connect(set_health_and_mana)
		set_health_and_mana(player.get_health(), player.get_mana())
	_controls_label.modulate = Color(0.85, 0.9, 1.0, 0.9)
	_combat_feed_label.modulate = Color(1.0, 0.9, 0.7, 0.95)
	_controls_label.text = "Move: WASD  Camera: Hold LMB + Mouse  Type: Enter  Speak: M  Voice Power: Hold V  Diagram: Hold RMB  Debug: F3"


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
