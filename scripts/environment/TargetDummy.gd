extends StaticBody3D

@export var hit_flash_duration: float = 0.18

@onready var _body_mesh: MeshInstance3D = $BodyMesh
@onready var _head_mesh: MeshInstance3D = $HeadMesh

var _body_material: StandardMaterial3D
var _head_material: StandardMaterial3D
var _hit_flash_remaining := 0.0
var hit_count := 0


func _ready() -> void:
	add_to_group("target_dummy")
	_body_material = _duplicate_material(_body_mesh)
	_head_material = _duplicate_material(_head_mesh)


func _process(delta: float) -> void:
	if _hit_flash_remaining <= 0.0:
		return

	_hit_flash_remaining = maxf(_hit_flash_remaining - delta, 0.0)
	var flash_ratio: float = _hit_flash_remaining / hit_flash_duration
	var flash_strength: float = lerpf(0.0, 3.4, flash_ratio)
	if _body_material != null:
		_body_material.emission_energy_multiplier = flash_strength
	if _head_material != null:
		_head_material.emission_energy_multiplier = flash_strength


func receive_fire_hit(_impact_position: Vector3) -> void:
	hit_count += 1
	_hit_flash_remaining = hit_flash_duration
	if _body_material != null:
		_body_material.emission = Color(1.0, 0.45, 0.16, 1.0)
	if _head_material != null:
		_head_material.emission = Color(1.0, 0.55, 0.2, 1.0)


func _duplicate_material(mesh_instance: MeshInstance3D) -> StandardMaterial3D:
	var source_material: Material = mesh_instance.get_active_material(0)
	if source_material is StandardMaterial3D:
		var duplicated_material := source_material.duplicate() as StandardMaterial3D
		mesh_instance.set_surface_override_material(0, duplicated_material)
		return duplicated_material
	return null
