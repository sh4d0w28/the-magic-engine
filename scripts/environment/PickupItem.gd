extends StaticBody3D
class_name PickupItem

@export var pickup_kind := "item"
@export var item_name := "Kindling"
@export var amount := 1
@export var lexeme_id := ""
@export var source_note := ""

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _label: Label3D = $Label3D

var _base_position := Vector3.ZERO
var _elapsed := 0.0
var _material: StandardMaterial3D


func _ready() -> void:
	add_to_group("pickup_item")
	_base_position = position
	var source_material: Material = _mesh.get_active_material(0)
	if source_material is StandardMaterial3D:
		_material = source_material.duplicate() as StandardMaterial3D
		_mesh.set_surface_override_material(0, _material)
	_update_visuals()


func _process(delta: float) -> void:
	_elapsed += delta
	position.y = _base_position.y + sin(_elapsed * 2.2) * 0.08
	rotation.y += delta * 0.9


func configure_item_pickup(next_item_name: String, next_amount: int = 1) -> void:
	pickup_kind = "item"
	item_name = next_item_name
	amount = max(next_amount, 1)
	if is_node_ready():
		_update_visuals()


func configure_lexeme_pickup(next_lexeme_id: String, next_source_note: String) -> void:
	pickup_kind = "lexeme"
	lexeme_id = next_lexeme_id
	source_note = next_source_note
	if is_node_ready():
		_update_visuals()


func collect_pickup(context: Dictionary) -> Dictionary:
	match pickup_kind:
		"item":
			var inventory_system: Node = context.get("inventory_system")
			if inventory_system == null or not inventory_system.has_method("add_item"):
				return {"success": false, "message": "No inventory available."}
			inventory_system.add_item(item_name, amount)
			queue_free()
			return {"success": true, "message": "Picked up %s x%d." % [item_name, amount]}
		"lexeme":
			var spellbook_system: Node = context.get("spellbook_system")
			if spellbook_system == null or not spellbook_system.has_method("discover_lexeme"):
				return {"success": false, "message": "No spellbook research system available."}
			var discovered: bool = spellbook_system.discover_lexeme(lexeme_id, source_note, 1.0, "Recovered from field notes.")
			if not discovered:
				return {"success": false, "message": "You already understand %s." % lexeme_id}
			queue_free()
			return {"success": true, "message": "Discovered the word %s." % lexeme_id}
	return {"success": false, "message": "Unknown pickup type."}


func _update_visuals() -> void:
	if _label != null:
		if pickup_kind == "lexeme":
			_label.text = "Lexeme: %s" % lexeme_id
		else:
			_label.text = "%s x%d" % [item_name, amount]
	if _material == null:
		return
	if pickup_kind == "lexeme":
		_material.albedo_color = Color(0.42, 0.78, 1.0, 1.0)
		return
	_material.albedo_color = _get_item_color(item_name)


func _get_item_color(target_item_name: String) -> Color:
	match target_item_name:
		"Kindling":
			return Color(0.72, 0.49, 0.28, 1.0)
		"Charcoal":
			return Color(0.2, 0.2, 0.24, 1.0)
		"Ash Pouch":
			return Color(0.78, 0.76, 0.7, 1.0)
		"Blank Page":
			return Color(0.95, 0.93, 0.85, 1.0)
		"Ink Vial":
			return Color(0.16, 0.38, 0.74, 1.0)
		_:
			return Color(0.62, 0.8, 0.46, 1.0)
