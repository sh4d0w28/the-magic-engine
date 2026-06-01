extends Node

var _spell_definitions := preload("res://scripts/magic/SpellDefinitions.gd").new()
var _magic_engine := preload("res://scripts/magic/MagicEngine.gd").new()
var _spark_scene := preload("res://scenes/effects/SparkEffect.tscn")
var _fireball_scene := preload("res://scenes/effects/Fireball.tscn")
var _bonfire_scene := preload("res://scenes/effects/Bonfire.tscn")
var _backlash_scene := preload("res://scenes/effects/BacklashEffect.tscn")
var _impact_burst_scene := preload("res://scenes/effects/ImpactBurst.tscn")

@onready var _player: CharacterBody3D = $"../Player"
@onready var _hud: Control = $"../UI/HUD"
@onready var _debug_panel: PanelContainer = $"../UI/DebugPanel"
@onready var _active_spells: Node3D = $ActiveSpells
@onready var _voice_power_tracker: Node = $"../InputController/VoicePowerTracker"
@onready var _diagram_recognizer: Node = $"../InputController/DiagramRecognizer"
@onready var _spellbook_system: Node = $"../Player/SpellbookSystem"

var _score := 0


func _ready() -> void:
	_magic_engine.setup(_spell_definitions)
	call_deferred("_initialize_combat_feedback")


func _initialize_combat_feedback() -> void:
	get_tree().node_added.connect(_on_node_added)
	for node in get_tree().get_nodes_in_group("target_dummy"):
		_connect_target_dummy(node)
	for node in get_tree().get_nodes_in_group("hostile_enemy"):
		_connect_hostile_enemy(node)
	_hud.set_score(_score)


func build_cast_request(raw_input: String, normalized_input: String, input_type: String = "typed") -> Dictionary:
	var diagram_result: Dictionary = _diagram_recognizer.get_diagram_result()
	var vocabulary_payload: Dictionary = _spellbook_system.build_active_vocabulary_payload()
	return {
		"caster": _player,
		"raw_input": raw_input,
		"normalized_input": normalized_input,
		"input_type": input_type,
		"voice_power": _voice_power_tracker.get_voice_power(),
		"diagram_type": diagram_result.get("shape_type", "none"),
		"diagram_accuracy": diagram_result.get("accuracy", 0.0),
		"diagram_size": diagram_result.get("size", 0.0),
		"target_position": _player.get_target_position(),
		"discovered_lexeme_ids": vocabulary_payload.get("discovered_ids", [])
	}


func preview_incantation(raw_input: String, normalized_input: String) -> Dictionary:
	var request: Dictionary = build_cast_request(raw_input, normalized_input, "preview")
	return _magic_engine.preview_request(request)


func submit_incantation(raw_input: String, normalized_input: String, input_type: String = "typed") -> void:
	var request: Dictionary = build_cast_request(raw_input, normalized_input, input_type)
	var result := _magic_engine.execute_request(request)
	_voice_power_tracker.consume_voice_power()
	_debug_panel.set_spell_result(result)
	_hud.set_status(str(result.get("message", "")))
	if result.get("success", false):
		_spawn_success_effect(result, request)
	elif str(result.get("message", "")).contains("Not enough mana or health"):
		_spawn_backlash(request)


func submit_typed_incantation(raw_input: String, normalized_input: String) -> void:
	submit_incantation(raw_input, normalized_input, "typed")


func submit_voice_incantation(raw_input: String, normalized_input: String) -> void:
	submit_incantation(raw_input, normalized_input, "voice")


func _spawn_success_effect(result: Dictionary, request: Dictionary) -> void:
	var spell_definition: Dictionary = _spell_definitions.get_spell_by_id(str(result.get("spell_id", "")))
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
			var fireball_direction := target_position - launch_origin
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
		"self_push":
			var push_strength: float = float(spell_definition.get("push_strength", 9.0)) * float(result.get("final_power", 1.0))
			_player.apply_force_push(_player.get_forward_direction(), push_strength)
			_spawn_push_feedback(_player.global_position + Vector3.UP * 0.8)
		"target_push":
			var target = _find_push_target(request.get("target_position", _player.get_target_position()), float(spell_definition.get("range", 9.0)))
			if target != null and target.has_method("receive_force_push"):
				var push_direction: Vector3 = target.global_position - _player.global_position
				target.receive_force_push(push_direction, float(spell_definition.get("push_strength", 8.0)) * float(result.get("final_power", 1.0)))
				_spawn_push_feedback(target.global_position + Vector3.UP * 0.9)
			else:
				_hud.set_status("Target push resolved, but no valid target was in range.")


func _spawn_backlash(request: Dictionary) -> void:
	var backlash = _backlash_scene.instantiate()
	_active_spells.add_child(backlash)
	backlash.global_position = request.get("target_position", _player.get_target_position())


func _spawn_push_feedback(world_position: Vector3) -> void:
	var burst = _impact_burst_scene.instantiate()
	_active_spells.add_child(burst)
	burst.global_position = world_position


func _find_push_target(target_position: Vector3, max_range: float) -> Node3D:
	var best_target: Node3D = null
	var best_distance := INF
	for group_name in ["target_dummy", "hostile_enemy"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if not node is Node3D:
				continue
			var distance_to_target: float = node.global_position.distance_to(target_position)
			if distance_to_target > max_range or distance_to_target >= best_distance:
				continue
			best_distance = distance_to_target
			best_target = node
	if best_target != null:
		return best_target

	for group_name in ["target_dummy", "hostile_enemy"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if not node is Node3D:
				continue
			var distance_to_player: float = node.global_position.distance_to(_player.global_position)
			if distance_to_player > max_range or distance_to_player >= best_distance:
				continue
			best_distance = distance_to_player
			best_target = node
	return best_target


func _on_node_added(node: Node) -> void:
	if node.has_signal("dummy_damaged") or node.has_signal("dummy_destroyed"):
		_connect_target_dummy(node)
	if node.has_signal("enemy_damaged") or node.has_signal("enemy_destroyed"):
		_connect_hostile_enemy(node)


func _connect_target_dummy(node: Node) -> void:
	if node.has_signal("dummy_damaged") and not node.dummy_damaged.is_connected(_on_dummy_damaged):
		node.dummy_damaged.connect(_on_dummy_damaged)
	if node.has_signal("dummy_destroyed") and not node.dummy_destroyed.is_connected(_on_dummy_destroyed):
		node.dummy_destroyed.connect(_on_dummy_destroyed)


func _connect_hostile_enemy(node: Node) -> void:
	if node.has_signal("enemy_damaged") and not node.enemy_damaged.is_connected(_on_enemy_damaged):
		node.enemy_damaged.connect(_on_enemy_damaged)
	if node.has_signal("enemy_destroyed") and not node.enemy_destroyed.is_connected(_on_enemy_destroyed):
		node.enemy_destroyed.connect(_on_enemy_destroyed)


func _on_dummy_damaged(current_health: int, max_health: int) -> void:
	_hud.set_combat_feed("Dummy hit: %d/%d health remaining" % [current_health, max_health])


func _on_dummy_destroyed(score_value: int) -> void:
	_score += score_value
	_hud.set_score(_score)
	_hud.set_combat_feed("Dummy destroyed. Score +%d" % score_value)


func _on_enemy_damaged(current_health: int, max_health: int) -> void:
	_hud.set_combat_feed("Hostile hit: %d/%d health remaining" % [current_health, max_health])


func _on_enemy_destroyed(score_value: int) -> void:
	_score += score_value
	_hud.set_score(_score)
	_hud.set_combat_feed("Hostile destroyed. Score +%d" % score_value)
