extends Node3D

@export var duration_seconds: float = 1.0

var _elapsed_seconds := 0.0

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _base_scale: Vector3 = _mesh.scale


func _process(delta: float) -> void:
	_elapsed_seconds += delta
	position.y += delta * 0.35
	var life_ratio: float = clampf(_elapsed_seconds / duration_seconds, 0.0, 1.0)
	var pulse: float = 1.0 + sin(life_ratio * PI) * 0.35
	_mesh.scale = _base_scale * pulse * (1.0 - life_ratio * 0.25)
	if _elapsed_seconds >= duration_seconds:
		queue_free()
