extends Node3D

@export var duration_seconds: float = 4.0

@onready var _mesh: MeshInstance3D = $MeshInstance3D

var _material: StandardMaterial3D
var _elapsed_seconds := 0.0


func _ready() -> void:
	var source_material: Material = _mesh.get_active_material(0)
	if source_material is StandardMaterial3D:
		_material = source_material.duplicate() as StandardMaterial3D
		_mesh.set_surface_override_material(0, _material)


func _process(delta: float) -> void:
	_elapsed_seconds += delta
	if _material != null:
		var life_ratio: float = clampf(_elapsed_seconds / duration_seconds, 0.0, 1.0)
		var color := _material.albedo_color
		color.a = lerpf(0.75, 0.0, life_ratio)
		_material.albedo_color = color
	if _elapsed_seconds >= duration_seconds:
		queue_free()
