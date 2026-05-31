extends Control

signal input_submitted(text: String)

@onready var _health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var _mana_label: Label = $MarginContainer/VBoxContainer/ManaLabel
@onready var _score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var _status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var _controls_label: Label = $MarginContainer/VBoxContainer/ControlsLabel
@onready var _voice_power_label: Label = $MarginContainer/VBoxContainer/VoicePowerLabel
@onready var _combat_feed_label: Label = $MarginContainer/VBoxContainer/CombatFeedLabel
@onready var _input_line: LineEdit = $MarginContainer/VBoxContainer/InputLine
@onready var _aim_reticle: Control = $AimReticle


func _ready() -> void:
	_input_line.text_submitted.connect(_on_input_submitted)
	_input_line.hide()
	var player := get_tree().get_first_node_in_group("player_controller")
	if player != null and player.has_signal("health_mana_changed"):
		player.health_mana_changed.connect(set_health_and_mana)
		set_health_and_mana(player.get_health(), player.get_mana())
	_controls_label.modulate = Color(0.85, 0.9, 1.0, 0.9)
	_combat_feed_label.modulate = Color(1.0, 0.9, 0.7, 0.95)


func _process(_delta: float) -> void:
	_update_aim_reticle()


func set_health_and_mana(health: float, mana: float) -> void:
	_health_label.text = "Health: %.1f" % health
	_mana_label.text = "Mana: %.1f" % mana


func set_status(message: String) -> void:
	_status_label.text = "Status: %s" % message


func set_voice_power(voice_power: float) -> void:
	_voice_power_label.text = "Voice Power: %.2f" % voice_power


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
