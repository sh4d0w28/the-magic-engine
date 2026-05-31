extends Node3D

@export var duration_seconds: float = 0.6

var _elapsed_seconds := 0.0


func _process(delta: float) -> void:
	_elapsed_seconds += delta
	scale += Vector3.ONE * delta
	if _elapsed_seconds >= duration_seconds:
		queue_free()
