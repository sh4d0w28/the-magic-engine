extends StaticBody3D
class_name PickupItem

@export var item_name := "Kindling"
@export var amount := 1

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


func configure_pickup(next_item_name: String, next_amount: int = 1) -> void:
	item_name = next_item_name
	amount = max(next_amount, 1)
	if is_node_ready():
		_update_visuals()


func collect_to(inventory_system: Node) -> bool:
	if inventory_system == null or not inventory_system.has_method("add_item"):
		return false
	inventory_system.add_item(item_name, amount)
	queue_free()
	return true


func _update_visuals() -> void:
	if _label != null:
		_label.text = "%s x%d" % [item_name, amount]
	if _material == null:
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
