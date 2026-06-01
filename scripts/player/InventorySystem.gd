extends Node
class_name InventorySystem

signal inventory_changed(items: Dictionary)
signal selected_item_changed(item_name: String)

@export var starter_items: Dictionary = {
	"Kindling": 3,
	"Charcoal": 2,
	"Ash Pouch": 1,
	"Blank Page": 3,
	"Ink Vial": 3
}

var _items: Dictionary = {}
var _selected_item_name := ""


func _ready() -> void:
	_items = starter_items.duplicate(true)
	_selected_item_name = _get_first_item_name()
	_emit_all()


func get_items() -> Dictionary:
	return _items.duplicate(true)


func get_selected_item_name() -> String:
	return _selected_item_name


func add_item(item_name: String, amount: int = 1) -> void:
	if item_name.is_empty() or amount <= 0:
		return

	_items[item_name] = int(_items.get(item_name, 0)) + amount
	if _selected_item_name.is_empty():
		_selected_item_name = item_name
	_emit_all()


func remove_item(item_name: String, amount: int = 1) -> bool:
	if not _items.has(item_name) or amount <= 0:
		return false

	var next_amount: int = int(_items.get(item_name, 0)) - amount
	if next_amount > 0:
		_items[item_name] = next_amount
	else:
		_items.erase(item_name)
		if _selected_item_name == item_name:
			_selected_item_name = _get_first_item_name()
	_emit_all()
	return true


func has_item(item_name: String, amount: int = 1) -> bool:
	return int(_items.get(item_name, 0)) >= amount


func select_next_item() -> String:
	return _select_relative_item(1)


func select_previous_item() -> String:
	return _select_relative_item(-1)


func use_selected_item(context: Dictionary) -> Dictionary:
	if _selected_item_name.is_empty():
		return {"success": false, "message": "No item selected."}

	var player: Node = context.get("player")
	var voice_power_tracker: Node = context.get("voice_power_tracker")
	match _selected_item_name:
		"Kindling":
			if remove_item("Kindling", 1):
				if player != null and player.has_method("restore_mana"):
					player.restore_mana(18.0)
				return {"success": true, "message": "Kindling burned for +18 mana."}
		"Ash Pouch":
			if remove_item("Ash Pouch", 1):
				if player != null and player.has_method("take_damage") and player.has_method("get_energy_system"):
					player.get_energy_system().heal(14.0)
				return {"success": true, "message": "Ash poultice restored 14 health."}
		"Charcoal":
			if remove_item("Charcoal", 1):
				if voice_power_tracker != null and voice_power_tracker.has_method("_set_voice_power"):
					var boosted_power: float = minf(1.0, voice_power_tracker.get_voice_power() + 0.35)
					voice_power_tracker._set_voice_power(boosted_power)
				return {"success": true, "message": "Charcoal primed your voice power."}
		"Blank Page":
			return {"success": false, "message": "Blank pages are used when authoring spells."}
		"Ink Vial":
			return {"success": false, "message": "Ink is used to write spellbook pages."}

	return {"success": false, "message": "That item has no use yet."}


func drop_selected_item() -> Dictionary:
	if _selected_item_name.is_empty():
		return {"success": false, "message": "No item selected."}

	var item_name := _selected_item_name
	if not remove_item(item_name, 1):
		return {"success": false, "message": "Unable to drop item."}

	return {
		"success": true,
		"item_name": item_name,
		"amount": 1,
		"message": "Dropped %s." % item_name
	}


func _select_relative_item(direction: int) -> String:
	var item_names := _get_sorted_item_names()
	if item_names.is_empty():
		_selected_item_name = ""
		_emit_selection()
		return ""

	var current_index := item_names.find(_selected_item_name)
	if current_index == -1:
		_selected_item_name = item_names[0]
		_emit_selection()
		return _selected_item_name

	var next_index := posmod(current_index + direction, item_names.size())
	_selected_item_name = item_names[next_index]
	_emit_selection()
	return _selected_item_name


func _get_sorted_item_names() -> Array[String]:
	var item_names: Array = _items.keys()
	item_names.sort()
	var sorted_names: Array[String] = []
	for item_name in item_names:
		sorted_names.append(str(item_name))
	return sorted_names


func _get_first_item_name() -> String:
	var sorted_names := _get_sorted_item_names()
	if sorted_names.is_empty():
		return ""
	return sorted_names[0]


func _emit_all() -> void:
	inventory_changed.emit(get_items())
	_emit_selection()


func _emit_selection() -> void:
	selected_item_changed.emit(_selected_item_name)
