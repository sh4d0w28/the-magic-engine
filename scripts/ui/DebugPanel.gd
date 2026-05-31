extends PanelContainer

@onready var _raw_input_label: Label = $MarginContainer/VBoxContainer/RawInputLabel
@onready var _normalized_input_label: Label = $MarginContainer/VBoxContainer/NormalizedInputLabel
@onready var _spell_label: Label = $MarginContainer/VBoxContainer/SpellLabel
@onready var _stability_label: Label = $MarginContainer/VBoxContainer/StabilityLabel
@onready var _power_label: Label = $MarginContainer/VBoxContainer/PowerLabel
@onready var _cost_label: Label = $MarginContainer/VBoxContainer/CostLabel
@onready var _energy_label: Label = $MarginContainer/VBoxContainer/EnergyLabel
@onready var _voice_power_label: Label = $MarginContainer/VBoxContainer/VoicePowerLabel
@onready var _diagram_label: Label = $MarginContainer/VBoxContainer/DiagramLabel
@onready var _message_label: Label = $MarginContainer/VBoxContainer/MessageLabel


func set_submitted_input(raw_input: String, normalized_input: String) -> void:
	_raw_input_label.text = "Raw Input: %s" % raw_input
	_normalized_input_label.text = "Normalized: %s" % normalized_input


func set_spell_result(result: Dictionary) -> void:
	_spell_label.text = "Spell: %s" % result.get("spell_name", "-")
	_stability_label.text = "Stability: %.2f" % float(result.get("stability", 0.0))
	_power_label.text = "Final Power: %.2f" % float(result.get("final_power", 0.0))
	_cost_label.text = "Final Cost: %.2f" % float(result.get("final_cost", 0.0))
	_energy_label.text = "Energy: Mana %.1f / Health %.1f" % [
		float(result.get("mana_spent", 0.0)),
		float(result.get("health_spent", 0.0))
	]
	_message_label.text = "Message: %s" % result.get("message", "")


func set_voice_power(voice_power: float) -> void:
	_voice_power_label.text = "Voice Power: %.2f" % voice_power


func set_diagram_result(diagram_result: Dictionary) -> void:
	_diagram_label.text = "Diagram: %s (acc %.2f, size %.2f)" % [
		diagram_result.get("shape_type", "none"),
		float(diagram_result.get("accuracy", 0.0)),
		float(diagram_result.get("size", 0.0))
	]


func set_message(message: String) -> void:
	_message_label.text = "Message: %s" % message
