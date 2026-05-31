extends Node

var _spell_definitions := preload("res://scripts/magic/SpellDefinitions.gd").new()
var _magic_engine := preload("res://scripts/magic/MagicEngine.gd").new()

@onready var _player: CharacterBody3D = $"../Player"
@onready var _hud: Control = $"../UI/HUD"
@onready var _debug_panel: PanelContainer = $"../UI/DebugPanel"


func _ready() -> void:
	_magic_engine.setup(_spell_definitions)


func submit_typed_incantation(raw_input: String, normalized_input: String) -> void:
	var request := {
		"caster": _player,
		"raw_input": raw_input,
		"normalized_input": normalized_input,
		"input_type": "typed",
		"voice_power": 0.0,
		"diagram_type": "none",
		"diagram_accuracy": 0.0,
		"diagram_size": 0.0,
		"target_position": _player.get_target_position()
	}
	var result := _magic_engine.execute_request(request)
	_debug_panel.set_spell_result(result)
	_hud.set_status(str(result.get("message", "")))
