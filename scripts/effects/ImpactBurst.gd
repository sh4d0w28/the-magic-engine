extends Node3D

@export var duration_seconds: float = 0.22

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _base_scale: Vector3 = _mesh.scale

var _elapsed_seconds := 0.0
var _material: StandardMaterial3D


func _ready() -> void:
	var source_material: Material = _mesh.get_active_material(0)
	if source_material is StandardMaterial3D:
		_material = source_material.duplicate() as StandardMaterial3D
		_mesh.set_surface_override_material(0, _material)


func _process(delta: float) -> void:
	_elapsed_seconds += delta
	var life_ratio: float = clampf(_elapsed_seconds / duration_seconds, 0.0, 1.0)
	_mesh.scale = _base_scale * (1.0 + life_ratio * 1.8)
	if _material != null:
		var color := _material.albedo_color
		color.a = 1.0 - life_ratio
		_material.albedo_color = color
		_material.emission_energy_multiplier = lerpf(3.0, 0.2, life_ratio)
	if _elapsed_seconds >= duration_seconds:
		queue_free()
