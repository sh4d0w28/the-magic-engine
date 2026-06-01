extends Node
class_name SpellbookSystem

signal lexicon_changed(discovered_lexemes: Array[Dictionary])
signal formula_pages_changed(formula_pages: Array[Dictionary])
signal selected_formula_page_changed(page: Dictionary, index: int, total_count: int)

var _lexeme_catalog := preload("res://scripts/magic/LexemeCatalog.gd").new()
var _discovered_lexemes: Dictionary = {}
var _formula_pages: Array[Dictionary] = []
var _selected_formula_page_index := -1


func _ready() -> void:
	_emit_all()


func get_discovered_lexemes() -> Array[Dictionary]:
	var lexemes: Array[Dictionary] = []
	for lexeme_id in _discovered_lexemes.keys():
		var discovered_entry: Dictionary = _discovered_lexemes[lexeme_id]
		var lexeme_definition: Dictionary = _lexeme_catalog.get_lexeme_by_id(str(lexeme_id))
		var merged_entry := lexeme_definition.duplicate(true)
		merged_entry["discovered"] = true
		merged_entry["confidence"] = float(discovered_entry.get("confidence", 1.0))
		merged_entry["source"] = str(discovered_entry.get("source", ""))
		merged_entry["notes"] = str(discovered_entry.get("notes", ""))
		lexemes.append(merged_entry)
	lexemes.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return str(left.get("id", "")) < str(right.get("id", ""))
	)
	return lexemes


func get_discovered_lexeme_ids() -> Array[String]:
	var ids: Array[String] = []
	for lexeme_id in _discovered_lexemes.keys():
		ids.append(str(lexeme_id))
	ids.sort()
	return ids


func discover_lexeme(lexeme_id: String, source: String, confidence: float = 1.0, notes: String = "") -> bool:
	var lexeme_definition: Dictionary = _lexeme_catalog.get_lexeme_by_id(lexeme_id)
	if lexeme_definition.is_empty():
		return false
	if _discovered_lexemes.has(lexeme_id):
		return false

	_discovered_lexemes[lexeme_id] = {
		"confidence": confidence,
		"source": source,
		"notes": notes
	}
	_emit_all()
	return true


func has_discovered_lexeme(lexeme_id: String) -> bool:
	return _discovered_lexemes.has(lexeme_id)


func get_formula_pages() -> Array[Dictionary]:
	return _formula_pages.duplicate(true)


func get_formula_page_count() -> int:
	return _formula_pages.size()


func get_selected_formula_page_index() -> int:
	return _selected_formula_page_index


func get_selected_formula_page() -> Dictionary:
	if _selected_formula_page_index < 0 or _selected_formula_page_index >= _formula_pages.size():
		return {}
	return _formula_pages[_selected_formula_page_index].duplicate(true)


func create_formula_page() -> Dictionary:
	var page := {
		"title": "Untitled Formula",
		"token_sequence": [],
		"notes": "",
		"preferred_diagram": "none",
		"last_result": "",
		"last_stability": 0.0
	}
	_formula_pages.append(page)
	_selected_formula_page_index = _formula_pages.size() - 1
	_emit_all()
	return get_selected_formula_page()


func select_next_formula_page() -> Dictionary:
	if _formula_pages.is_empty():
		return {}
	_selected_formula_page_index = (_selected_formula_page_index + 1) % _formula_pages.size()
	_emit_selection_changed()
	return get_selected_formula_page()


func select_previous_formula_page() -> Dictionary:
	if _formula_pages.is_empty():
		return {}
	_selected_formula_page_index -= 1
	if _selected_formula_page_index < 0:
		_selected_formula_page_index = _formula_pages.size() - 1
	_emit_selection_changed()
	return get_selected_formula_page()


func update_selected_formula_page_title(title: String) -> void:
	_update_selected_page_field("title", title)


func update_selected_formula_page_tokens(raw_text: String) -> void:
	_update_selected_page_field("token_sequence", _normalize_to_tokens(raw_text))


func update_selected_formula_page_notes(notes: String) -> void:
	_update_selected_page_field("notes", notes)


func update_selected_formula_page_preferred_diagram(preferred_diagram: String) -> void:
	_update_selected_page_field("preferred_diagram", preferred_diagram)


func update_selected_formula_page_preview(last_result: String, last_stability: float) -> void:
	if _selected_formula_page_index < 0 or _selected_formula_page_index >= _formula_pages.size():
		return
	_formula_pages[_selected_formula_page_index]["last_result"] = last_result
	_formula_pages[_selected_formula_page_index]["last_stability"] = last_stability
	_emit_all()


func get_selected_formula_text() -> String:
	var page: Dictionary = get_selected_formula_page()
	return " ".join(page.get("token_sequence", []))


func build_active_vocabulary_payload() -> Dictionary:
	var discovered_ids: Array[String] = get_discovered_lexeme_ids()
	return {
		"discovered_ids": discovered_ids,
		"surface_forms": _lexeme_catalog.get_surface_forms_for_ids(discovered_ids),
		"aliases": _lexeme_catalog.get_alias_map_for_ids(discovered_ids)
	}


func _normalize_to_tokens(raw_text: String) -> Array[String]:
	var normalized_text: String = " ".join(raw_text.strip_edges().to_upper().split(" ", false))
	var tokens: Array[String] = []
	for token in normalized_text.split(" ", false):
		tokens.append(token)
	return tokens


func _update_selected_page_field(field_name: String, value: Variant) -> void:
	if _selected_formula_page_index < 0 or _selected_formula_page_index >= _formula_pages.size():
		return
	_formula_pages[_selected_formula_page_index][field_name] = value
	_emit_all()


func _emit_all() -> void:
	lexicon_changed.emit(get_discovered_lexemes())
	formula_pages_changed.emit(get_formula_pages())
	_emit_selection_changed()


func _emit_selection_changed() -> void:
	selected_formula_page_changed.emit(get_selected_formula_page(), _selected_formula_page_index, _formula_pages.size())
