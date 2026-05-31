extends Node3D

@export var duration_seconds: float = 1.0

var _elapsed_seconds := 0.0


func _process(delta: float) -> void:
	_elapsed_seconds += delta
	position.y += delta * 0.2
	if _elapsed_seconds >= duration_seconds:
		queue_free()
