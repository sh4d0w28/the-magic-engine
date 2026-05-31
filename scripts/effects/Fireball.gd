extends Node3D

var _direction := Vector3.FORWARD
var _speed := 12.0
var _max_range := 20.0
var _distance_travelled := 0.0


func configure(direction: Vector3, speed: float, max_range: float) -> void:
	_direction = direction.normalized()
	_speed = speed
	_max_range = max_range


func _process(delta: float) -> void:
	var movement := _direction * _speed * delta
	global_position += movement
	_distance_travelled += movement.length()
	if _distance_travelled >= _max_range:
		queue_free()
