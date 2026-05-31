extends Node3D

@export var fuel_amount: float = 5.0

@onready var _mesh: MeshInstance3D = $MeshInstance3D

var _material: StandardMaterial3D
var _ignite_flash_remaining := 0.0
var _max_fuel_amount := 0.0


func _ready() -> void:
	add_to_group("wood_pile")
	_max_fuel_amount = fuel_amount
	var source_material: Material = _mesh.get_active_material(0)
	if source_material is StandardMaterial3D:
		_material = source_material.duplicate() as StandardMaterial3D
		_mesh.set_surface_override_material(0, _material)
	_update_visual_state()


func _process(delta: float) -> void:
	if _ignite_flash_remaining <= 0.0:
		return

	_ignite_flash_remaining = maxf(_ignite_flash_remaining - delta, 0.0)
	if _material != null:
		_material.emission_enabled = true
		_material.emission = Color(1.0, 0.45, 0.15, 1.0)
		_material.emission_energy_multiplier = lerpf(0.0, 2.5, _ignite_flash_remaining / 0.25)


func has_fuel() -> bool:
	return fuel_amount > 0.0


func consume_fuel(amount: float) -> bool:
	if amount <= 0.0 or not has_fuel():
		return false

	fuel_amount = max(0.0, fuel_amount - amount)
	_ignite_flash_remaining = 0.25
	_update_visual_state()
	return true


func receive_spark_ignite() -> void:
	if has_fuel():
		consume_fuel(0.25)


func _update_visual_state() -> void:
	var fuel_ratio: float = float(fuel_amount) / float(maxf(_max_fuel_amount, 0.001))
	_mesh.scale = Vector3(0.7 + fuel_ratio * 0.3, 0.45 + fuel_ratio * 0.55, 0.65 + fuel_ratio * 0.35)
	if _material != null:
		_material.albedo_color = Color(0.25, 0.18, 0.11, 1.0).lerp(Color(0.46, 0.31, 0.17, 1.0), fuel_ratio)
