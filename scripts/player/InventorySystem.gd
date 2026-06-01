extends Node
class_name InventorySystem

signal inventory_changed(items: Dictionary)

@export var starter_items: Dictionary = {
	"Kindling": 3,
	"Charcoal": 2,
	"Ash Pouch": 1
}

var _items: Dictionary = {}


func _ready() -> void:
	_items = starter_items.duplicate(true)
	_emit_changed()


func get_items() -> Dictionary:
	return _items.duplicate(true)


func add_item(item_name: String, amount: int = 1) -> void:
	if item_name.is_empty() or amount <= 0:
		return

	_items[item_name] = int(_items.get(item_name, 0)) + amount
	_emit_changed()


func remove_item(item_name: String, amount: int = 1) -> bool:
	if not _items.has(item_name) or amount <= 0:
		return false

	var next_amount: int = int(_items.get(item_name, 0)) - amount
	if next_amount > 0:
		_items[item_name] = next_amount
	else:
		_items.erase(item_name)
	_emit_changed()
	return true


func has_item(item_name: String, amount: int = 1) -> bool:
	return int(_items.get(item_name, 0)) >= amount


func _emit_changed() -> void:
	inventory_changed.emit(get_items())
