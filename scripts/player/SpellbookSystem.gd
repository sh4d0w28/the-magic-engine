extends Node
class_name SpellbookSystem

signal pages_changed(pages: Array[Dictionary])
signal selected_page_changed(page: Dictionary, index: int, total_count: int)

const DEFAULT_EFFECT_ID := "spark"

var _spell_definitions := preload("res://scripts/magic/SpellDefinitions.gd").new()
var _pages: Array[Dictionary] = []
var _selected_page_index := -1


func _ready() -> void:
	_emit_all()


func get_pages() -> Array[Dictionary]:
	return _pages.duplicate(true)


func get_page_count() -> int:
	return _pages.size()


func get_selected_page_index() -> int:
	return _selected_page_index


func get_selected_page() -> Dictionary:
	if _selected_page_index < 0 or _selected_page_index >= _pages.size():
		return {}
	return _pages[_selected_page_index].duplicate(true)


func get_available_effects() -> Array[Dictionary]:
	return _spell_definitions.get_available_spell_templates()


func create_page() -> Dictionary:
	var default_effect := _spell_definitions.get_spell_by_id(DEFAULT_EFFECT_ID)
	var page := {
		"title": "Untitled Research",
		"incantation": "",
		"effect_id": str(default_effect.get("id", DEFAULT_EFFECT_ID)),
		"diagram": str(default_effect.get("diagram", "none")),
		"notes": ""
	}
	_pages.append(page)
	_selected_page_index = _pages.size() - 1
	_emit_all()
	return get_selected_page()


func remove_selected_page() -> bool:
	if _selected_page_index < 0 or _selected_page_index >= _pages.size():
		return false

	_pages.remove_at(_selected_page_index)
	if _pages.is_empty():
		_selected_page_index = -1
	else:
		_selected_page_index = mini(_selected_page_index, _pages.size() - 1)
	_emit_all()
	return true


func select_next_page() -> Dictionary:
	if _pages.is_empty():
		return {}
	_selected_page_index = (_selected_page_index + 1) % _pages.size()
	_emit_selection_changed()
	return get_selected_page()


func select_previous_page() -> Dictionary:
	if _pages.is_empty():
		return {}
	_selected_page_index -= 1
	if _selected_page_index < 0:
		_selected_page_index = _pages.size() - 1
	_emit_selection_changed()
	return get_selected_page()


func update_selected_page_title(title: String) -> void:
	_update_selected_page_field("title", title)


func update_selected_page_incantation(raw_incantation: String) -> void:
	_update_selected_page_field("incantation", _spell_definitions.normalize_incantation(raw_incantation))


func update_selected_page_notes(notes: String) -> void:
	_update_selected_page_field("notes", notes)


func update_selected_page_effect(effect_id: String) -> void:
	if effect_id.is_empty():
		return
	var template: Dictionary = _spell_definitions.get_spell_by_id(effect_id)
	if template.is_empty():
		return
	_update_selected_page_field("effect_id", str(template.get("id", effect_id)), false)
	_update_selected_page_field("diagram", str(template.get("diagram", "none")), false)
	_emit_all()


func resolve_spell_definition(normalized_input: String) -> Dictionary:
	if normalized_input.is_empty():
		return {}

	for page in _pages:
		if str(page.get("incantation", "")) != normalized_input:
			continue
		var template: Dictionary = _spell_definitions.get_spell_by_id(str(page.get("effect_id", "")))
		if template.is_empty():
			return {}
		var spell_definition := template.duplicate(true)
		spell_definition["name"] = _build_page_spell_name(page, template)
		spell_definition["incantation"] = normalized_input
		spell_definition["diagram"] = str(page.get("diagram", template.get("diagram", "none")))
		spell_definition["notes"] = str(page.get("notes", ""))
		return spell_definition

	return {}


func _build_page_spell_name(page: Dictionary, template: Dictionary) -> String:
	var title: String = str(page.get("title", "")).strip_edges()
	if not title.is_empty():
		return title
	return "%s Draft" % str(template.get("name", "Spell"))


func _update_selected_page_field(field_name: String, value: Variant, emit_all: bool = true) -> void:
	if _selected_page_index < 0 or _selected_page_index >= _pages.size():
		return
	_pages[_selected_page_index][field_name] = value
	if emit_all:
		_emit_all()


func _emit_all() -> void:
	pages_changed.emit(get_pages())
	_emit_selection_changed()


func _emit_selection_changed() -> void:
	selected_page_changed.emit(get_selected_page(), _selected_page_index, _pages.size())
