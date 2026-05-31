extends Node

var _spell_definitions := preload("res://scripts/magic/SpellDefinitions.gd").new()
var _magic_engine := preload("res://scripts/magic/MagicEngine.gd").new()
var _spark_scene := preload("res://scenes/effects/SparkEffect.tscn")
var _fireball_scene := preload("res://scenes/effects/Fireball.tscn")
var _bonfire_scene := preload("res://scenes/effects/Bonfire.tscn")
var _backlash_scene := preload("res://scenes/effects/BacklashEffect.tscn")

@onready var _player: CharacterBody3D = $"../Player"
@onready var _hud: Control = $"../UI/HUD"
@onready var _debug_panel: PanelContainer = $"../UI/DebugPanel"
@onready var _active_spells: Node3D = $ActiveSpells
@onready var _voice_power_tracker: Node = $"../InputController/VoicePowerTracker"


func _ready() -> void:
	_magic_engine.setup(_spell_definitions)


func submit_typed_incantation(raw_input: String, normalized_input: String) -> void:
	var request := {
		"caster": _player,
		"raw_input": raw_input,
		"normalized_input": normalized_input,
		"input_type": "typed",
		"voice_power": _voice_power_tracker.get_voice_power(),
		"diagram_type": "none",
		"diagram_accuracy": 0.0,
		"diagram_size": 0.0,
		"target_position": _player.get_target_position()
	}
	var result := _magic_engine.execute_request(request)
	_voice_power_tracker.consume_voice_power()
	_debug_panel.set_spell_result(result)
	_hud.set_status(str(result.get("message", "")))
	if result.get("success", false):
		_spawn_success_effect(result, request)
	elif str(result.get("message", "")).contains("Not enough mana or health"):
		_spawn_backlash(request)


func _spawn_success_effect(result: Dictionary, request: Dictionary) -> void:
	var spell_definition := _spell_definitions.get_spell_by_incantation(str(result.get("normalized_input", "")))
	match str(result.get("spell_id", "")):
		"spark":
			var spark = _spark_scene.instantiate()
			spark.global_position = request.get("target_position", _player.get_target_position())
			_active_spells.add_child(spark)
		"fireball":
			var fireball = _fireball_scene.instantiate()
			fireball.global_position = _player.global_position + Vector3.UP * 1.2 + _player.get_forward_direction() * 1.2
			fireball.configure(
				_player.get_forward_direction(),
				float(spell_definition.get("speed", 12.0)),
				float(spell_definition.get("range", 20.0))
			)
			_active_spells.add_child(fireball)
		"bonfire":
			var bonfire = _bonfire_scene.instantiate()
			bonfire.global_position = request.get("target_position", _player.get_target_position())
			bonfire.fuel_search_radius = float(spell_definition.get("fuel_search_radius", 3.0))
			bonfire.fuel_consume_interval_seconds = float(spell_definition.get("fuel_consume_interval_seconds", 5.0))
			bonfire.no_fuel_lifetime_seconds = float(spell_definition.get("no_fuel_lifetime_seconds", 3.0))
			_active_spells.add_child(bonfire)


func _spawn_backlash(request: Dictionary) -> void:
	var backlash = _backlash_scene.instantiate()
	backlash.global_position = request.get("target_position", _player.get_target_position())
	_active_spells.add_child(backlash)
