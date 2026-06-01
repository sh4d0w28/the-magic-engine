extends Node
class_name SpellbookSystem

signal notes_changed(notes: String)
signal known_spells_changed(spells: Array[Dictionary])

var _spell_definitions := preload("res://scripts/magic/SpellDefinitions.gd").new()
var _notes := ""
var _known_spells: Array[Dictionary] = []


func _ready() -> void:
	_load_known_spells()
	_emit_all()


func get_notes() -> String:
	return _notes


func set_notes(value: String) -> void:
	_notes = value
	notes_changed.emit(_notes)


func get_known_spells() -> Array[Dictionary]:
	return _known_spells.duplicate(true)


func _load_known_spells() -> void:
	_known_spells.clear()
	for incantation in ["RAK", "RAK TOR", "RAK DUM"]:
		var definition: Dictionary = _spell_definitions.get_spell_by_incantation(incantation)
		if definition.is_empty():
			continue
		_known_spells.append({
			"name": str(definition.get("name", "")),
			"incantation": str(definition.get("incantation", "")),
			"diagram": str(definition.get("diagram", "none"))
		})


func _emit_all() -> void:
	known_spells_changed.emit(get_known_spells())
	notes_changed.emit(_notes)
