extends Control

signal input_submitted(text: String)

@onready var _health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var _mana_label: Label = $MarginContainer/VBoxContainer/ManaLabel
@onready var _status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var _voice_power_label: Label = $MarginContainer/VBoxContainer/VoicePowerLabel
@onready var _input_line: LineEdit = $MarginContainer/VBoxContainer/InputLine


func _ready() -> void:
	_input_line.text_submitted.connect(_on_input_submitted)
	_input_line.hide()
	var player := get_tree().get_first_node_in_group("player_controller")
	if player != null and player.has_signal("health_mana_changed"):
		player.health_mana_changed.connect(set_health_and_mana)
		set_health_and_mana(player.get_health(), player.get_mana())


func set_health_and_mana(health: float, mana: float) -> void:
	_health_label.text = "Health: %.1f" % health
	_mana_label.text = "Mana: %.1f" % mana


func set_status(message: String) -> void:
	_status_label.text = "Status: %s" % message


func set_voice_power(voice_power: float) -> void:
	_voice_power_label.text = "Voice Power: %.2f" % voice_power


func open_input() -> void:
	_input_line.show()
	_input_line.grab_focus()
	_input_line.clear()


func close_input() -> void:
	_input_line.hide()
	_input_line.release_focus()


func is_input_open() -> bool:
	return _input_line.visible


func get_current_input() -> String:
	return _input_line.text


func _on_input_submitted(text: String) -> void:
	input_submitted.emit(text)
