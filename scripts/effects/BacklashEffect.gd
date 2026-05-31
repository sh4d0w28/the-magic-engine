extends Node3D

@export var duration_seconds: float = 0.6

var _elapsed_seconds := 0.0

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _base_scale: Vector3 = _mesh.scale


func _process(delta: float) -> void:
	_elapsed_seconds += delta
	var life_ratio: float = clampf(_elapsed_seconds / duration_seconds, 0.0, 1.0)
	var burst_scale: float = 1.0 + life_ratio * 1.4
	_mesh.scale = _base_scale * burst_scale
	rotation.y += delta * 9.0
	if _elapsed_seconds >= duration_seconds:
		queue_free()
