extends RefCounted
class_name LexemeCatalog

var _lexemes_by_id: Dictionary = {}
var _lexeme_ids_by_surface: Dictionary = {}


func _init() -> void:
	_load_fallback_lexemes()


func get_lexeme_by_id(lexeme_id: String) -> Dictionary:
	return _lexemes_by_id.get(lexeme_id, {}).duplicate(true)


func get_lexeme_by_surface(surface_form: String) -> Dictionary:
	var normalized_surface: String = normalize_surface_form(surface_form)
	var lexeme_id: String = str(_lexeme_ids_by_surface.get(normalized_surface, ""))
	if lexeme_id.is_empty():
		return {}
	return get_lexeme_by_id(lexeme_id)


func get_all_lexemes() -> Array[Dictionary]:
	var lexemes: Array[Dictionary] = []
	for lexeme in _lexemes_by_id.values():
		lexemes.append((lexeme as Dictionary).duplicate(true))
	lexemes.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return str(left.get("id", "")) < str(right.get("id", ""))
	)
	return lexemes


func get_surface_forms_for_ids(lexeme_ids: Array[String]) -> Array[String]:
	var forms: Array[String] = []
	for lexeme_id in lexeme_ids:
		var lexeme: Dictionary = get_lexeme_by_id(lexeme_id)
		for surface_form in lexeme.get("surface_forms", []):
			var normalized_surface: String = normalize_surface_form(str(surface_form))
			if not forms.has(normalized_surface):
				forms.append(normalized_surface)
	return forms


func get_alias_map_for_ids(lexeme_ids: Array[String]) -> Dictionary:
	var alias_map: Dictionary = {}
	for lexeme_id in lexeme_ids:
		var lexeme: Dictionary = get_lexeme_by_id(lexeme_id)
		for alias in lexeme.get("surface_forms", []):
			alias_map[normalize_surface_form(str(alias))] = str(lexeme.get("id", ""))
		for alias in lexeme.get("pronunciation_hints", []):
			alias_map[normalize_surface_form(str(alias))] = str(lexeme.get("id", ""))
	return alias_map


func normalize_surface_form(raw_surface_form: String) -> String:
	return " ".join(raw_surface_form.strip_edges().to_upper().split(" ", false))


func _load_fallback_lexemes() -> void:
	for lexeme in [
		{
			"id": "RAK",
			"surface_forms": ["RAK"],
			"kind": "element",
			"semantic_tags": {
				"element": "fire",
				"action": "ignite"
			},
			"can_cast_alone": true,
			"cost_delta": 0.0,
			"stability_delta": 0.0,
			"requires_any": [],
			"conflicts_with": [],
			"pronunciation_hints": ["RACK", "ROCK", "RAG", "WRECK"]
		},
		{
			"id": "TOR",
			"surface_forms": ["TOR"],
			"kind": "action",
			"semantic_tags": {
				"action": "force",
				"motion_mode": "push"
			},
			"can_cast_alone": true,
			"cost_delta": 0.3,
			"stability_delta": 0.0,
			"requires_any": [],
			"conflicts_with": [],
			"pronunciation_hints": ["TORE", "TOUR", "DOOR"]
		},
		{
			"id": "DUM",
			"surface_forms": ["DUM"],
			"kind": "anchor",
			"semantic_tags": {
				"anchor_mode": "sustain"
			},
			"can_cast_alone": false,
			"cost_delta": 0.15,
			"stability_delta": -0.05,
			"requires_any": ["RAK", "TOR"],
			"conflicts_with": [],
			"pronunciation_hints": ["DUMB", "DOOM"]
		},
		{
			"id": "SEV",
			"surface_forms": ["SEV"],
			"kind": "target",
			"semantic_tags": {
				"target_mode": "self"
			},
			"can_cast_alone": false,
			"cost_delta": 0.1,
			"stability_delta": 0.0,
			"requires_any": ["TOR"],
			"conflicts_with": ["KAR"],
			"pronunciation_hints": ["SAVE", "SEF", "SELF"]
		},
		{
			"id": "KAR",
			"surface_forms": ["KAR"],
			"kind": "target",
			"semantic_tags": {
				"target_mode": "aimed"
			},
			"can_cast_alone": false,
			"cost_delta": 0.1,
			"stability_delta": 0.0,
			"requires_any": ["TOR"],
			"conflicts_with": ["SEV"],
			"pronunciation_hints": ["CAR", "KAHR", "TARGET"]
		}
	]:
		var lexeme_id: String = str(lexeme.get("id", ""))
		_lexemes_by_id[lexeme_id] = lexeme
		for surface_form in lexeme.get("surface_forms", []):
			_lexeme_ids_by_surface[normalize_surface_form(str(surface_form))] = lexeme_id
		for pronunciation_hint in lexeme.get("pronunciation_hints", []):
			_lexeme_ids_by_surface[normalize_surface_form(str(pronunciation_hint))] = lexeme_id
