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
@onready var _diagram_recognizer: Node = $"../InputController/DiagramRecognizer"

var _score := 0


func _ready() -> void:
	_magic_engine.setup(_spell_definitions)
	call_deferred("_initialize_combat_feedback")


func _initialize_combat_feedback() -> void:
	get_tree().node_added.connect(_on_node_added)
	for node in get_tree().get_nodes_in_group("target_dummy"):
		_connect_target_dummy(node)
	_hud.set_score(_score)


func submit_typed_incantation(raw_input: String, normalized_input: String) -> void:
	var diagram_result: Dictionary = _diagram_recognizer.get_diagram_result()
	var request := {
		"caster": _player,
		"raw_input": raw_input,
		"normalized_input": normalized_input,
		"input_type": "typed",
		"voice_power": _voice_power_tracker.get_voice_power(),
		"diagram_type": diagram_result.get("shape_type", "none"),
		"diagram_accuracy": diagram_result.get("accuracy", 0.0),
		"diagram_size": diagram_result.get("size", 0.0),
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
	var spell_definition: Dictionary = _spell_definitions.get_spell_by_incantation(str(result.get("normalized_input", "")))
	match str(result.get("spell_id", "")):
		"spark":
			var spark = _spark_scene.instantiate()
			_active_spells.add_child(spark)
			spark.global_position = request.get("target_position", _player.get_target_position()) + Vector3.UP * 0.35
		"fireball":
			var fireball = _fireball_scene.instantiate()
			_active_spells.add_child(fireball)
			var target_position: Vector3 = request.get("target_position", _player.get_target_position())
			var launch_origin := _player.global_position + Vector3.UP * 1.3
			var fireball_direction := (target_position - launch_origin)
			fireball_direction.y = 0.0
			if fireball_direction == Vector3.ZERO:
				fireball_direction = _player.get_forward_direction()
			fireball_direction = fireball_direction.normalized()
			fireball.global_position = launch_origin + fireball_direction * 1.6
			fireball.configure(
				fireball_direction,
				float(spell_definition.get("speed", 12.0)),
				float(spell_definition.get("range", 20.0))
			)
			fireball.set_splash_radius(1.8)
		"bonfire":
			var bonfire = _bonfire_scene.instantiate()
			bonfire.fuel_search_radius = float(spell_definition.get("fuel_search_radius", 3.0))
			bonfire.fuel_consume_interval_seconds = float(spell_definition.get("fuel_consume_interval_seconds", 5.0))
			bonfire.no_fuel_lifetime_seconds = float(spell_definition.get("no_fuel_lifetime_seconds", 3.0))
			_active_spells.add_child(bonfire)
			bonfire.global_position = request.get("target_position", _player.get_target_position()) + Vector3.UP * 0.1


func _spawn_backlash(request: Dictionary) -> void:
	var backlash = _backlash_scene.instantiate()
	_active_spells.add_child(backlash)
	backlash.global_position = request.get("target_position", _player.get_target_position())


func _on_node_added(node: Node) -> void:
	if node.has_signal("dummy_damaged") or node.has_signal("dummy_destroyed"):
		_connect_target_dummy(node)


func _connect_target_dummy(node: Node) -> void:
	if node.has_signal("dummy_damaged") and not node.dummy_damaged.is_connected(_on_dummy_damaged):
		node.dummy_damaged.connect(_on_dummy_damaged)
	if node.has_signal("dummy_destroyed") and not node.dummy_destroyed.is_connected(_on_dummy_destroyed):
		node.dummy_destroyed.connect(_on_dummy_destroyed)


func _on_dummy_damaged(current_health: int, max_health: int) -> void:
	_hud.set_combat_feed("Dummy hit: %d/%d health remaining" % [current_health, max_health])


func _on_dummy_destroyed(score_value: int) -> void:
	_score += score_value
	_hud.set_score(_score)
	_hud.set_combat_feed("Dummy destroyed. Score +%d" % score_value)
