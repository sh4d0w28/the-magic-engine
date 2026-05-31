extends Node3D

var _direction := Vector3.FORWARD
var _speed := 12.0
var _max_range := 20.0
var _distance_travelled := 0.0

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _base_scale: Vector3 = _mesh.scale


func configure(direction: Vector3, speed: float, max_range: float) -> void:
	_direction = direction.normalized()
	_speed = speed
	_max_range = max_range


func _process(delta: float) -> void:
	var movement := _direction * _speed * delta
	global_position += movement
	_distance_travelled += movement.length()
	rotation.y += delta * 7.0
	var travel_ratio: float = clampf(_distance_travelled / maxf(_max_range, 0.001), 0.0, 1.0)
	var pulse: float = 1.0 + sin(Time.get_ticks_msec() * 0.02) * 0.08
	_mesh.scale = _base_scale * pulse * (1.0 - travel_ratio * 0.15)
	if _distance_travelled >= _max_range:
		queue_free()
