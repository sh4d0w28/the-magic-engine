extends RefCounted

const SPELL_DATA_PATH := "res://data/spells.json"

var _spell_definitions: Dictionary = {}
var _spell_definitions_by_id: Dictionary = {}


func _init() -> void:
	_load_spell_definitions()


func get_spell_by_incantation(incantation: String) -> Dictionary:
	return _spell_definitions.get(incantation, {}).duplicate(true)


func get_spell_by_id(spell_id: String) -> Dictionary:
	return _spell_definitions_by_id.get(spell_id, {}).duplicate(true)


func get_available_spell_templates() -> Array[Dictionary]:
	var templates: Array[Dictionary] = []
	for spell_definition in _spell_definitions_by_id.values():
		templates.append((spell_definition as Dictionary).duplicate(true))
	templates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return str(left.get("name", "")) < str(right.get("name", ""))
	)
	return templates


func has_incantation(incantation: String) -> bool:
	return _spell_definitions.has(incantation)


func normalize_incantation(raw_input: String) -> String:
	var words := raw_input.strip_edges().to_upper().split(" ", false)
	return " ".join(words)


func _load_spell_definitions() -> void:
	var file := FileAccess.open(SPELL_DATA_PATH, FileAccess.READ)
	if file == null:
		_use_fallback_definitions()
		return

	var parsed_json: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed_json) != TYPE_DICTIONARY:
		_use_fallback_definitions()
		return

	for spell_definition in parsed_json.get("spells", []):
		var incantation: String = str(spell_definition.get("incantation", ""))
		var spell_id: String = str(spell_definition.get("id", ""))
		if incantation.is_empty():
			continue
		_spell_definitions[incantation] = spell_definition
		if not spell_id.is_empty():
			_spell_definitions_by_id[spell_id] = spell_definition


func _use_fallback_definitions() -> void:
	for spell_definition in [
		{"id": "spark", "name": "Spark", "incantation": "RAK", "diagram": "circle", "base_cost": 5.0, "duration_seconds": 1.0},
		{"id": "fireball", "name": "Fireball", "incantation": "RAK TOR", "diagram": "triangle", "base_cost": 25.0, "speed": 12.0, "range": 20.0},
		{"id": "bonfire", "name": "Bonfire", "incantation": "RAK DUM", "diagram": "circle_with_dot", "base_cost": 15.0, "fuel_search_radius": 3.0, "fuel_consume_interval_seconds": 5.0, "no_fuel_lifetime_seconds": 3.0}
	]:
		_spell_definitions[spell_definition["incantation"]] = spell_definition
		_spell_definitions_by_id[spell_definition["id"]] = spell_definition
