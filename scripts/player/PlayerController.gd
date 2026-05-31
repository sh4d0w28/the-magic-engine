extends CharacterBody3D

signal health_mana_changed(health: float, mana: float)

@export var player_id: String = "player_1"
@export var movement_speed: float = 6.5
@export var acceleration: float = 18.0
@export var deceleration: float = 22.0
@export var mouse_sensitivity: float = 0.0045
@export var max_camera_pitch_degrees: float = 55.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var _energy_system: Node = $EnergySystem
@onready var _camera_pivot: Node3D = $CameraPivot

var _camera_pitch_radians := deg_to_rad(-25.0)


func _ready() -> void:
	add_to_group("player_controller")
	if _energy_system.has_signal("changed"):
		_energy_system.changed.connect(_on_energy_changed)
	_camera_pitch_radians = _camera_pivot.rotation.x
	_on_energy_changed(get_health(), get_mana())


func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_direction := _get_camera_relative_direction(input_vector)
	if move_direction != Vector3.ZERO:
		move_direction = move_direction.normalized()

	var desired_velocity := move_direction * movement_speed
	var move_lerp_weight := acceleration if move_direction != Vector3.ZERO else deceleration
	velocity.x = move_toward(velocity.x, desired_velocity.x, move_lerp_weight * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, move_lerp_weight * delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_MIDDLE) != 0:
		orbit_camera(event.relative)
		get_viewport().set_input_as_handled()


func spend_mana(amount: float) -> float:
	return _energy_system.spend_mana(amount)


func drain_health(amount: float) -> bool:
	return _energy_system.drain_health(amount)


func restore_mana(delta: float) -> void:
	_energy_system.restore_mana(delta)


func is_alive() -> bool:
	return _energy_system.is_alive()


func get_forward_direction() -> Vector3:
	var forward: Vector3 = -$CameraPivot/Camera3D.global_transform.basis.z
	return Vector3(forward.x, 0.0, forward.z).normalized()


func get_health() -> float:
	return _energy_system.health


func get_mana() -> float:
	return _energy_system.mana


func get_max_health() -> float:
	return _energy_system.max_health


func get_max_mana() -> float:
	return _energy_system.max_mana


func get_energy_system() -> Node:
	return _energy_system


func get_target_position() -> Vector3:
	return global_position + get_forward_direction() * 5.5


func _on_energy_changed(health: float, mana: float) -> void:
	health_mana_changed.emit(health, mana)


func orbit_camera(relative_motion: Vector2) -> void:
	rotation.y -= relative_motion.x * mouse_sensitivity
	_camera_pitch_radians = clampf(
		_camera_pitch_radians - relative_motion.y * mouse_sensitivity,
		deg_to_rad(-max_camera_pitch_degrees),
		deg_to_rad(15.0)
	)
	_camera_pivot.rotation.x = _camera_pitch_radians


func _get_camera_relative_direction(input_vector: Vector2) -> Vector3:
	var camera_forward: Vector3 = -$CameraPivot/Camera3D.global_transform.basis.z
	var camera_right: Vector3 = $CameraPivot/Camera3D.global_transform.basis.x
	camera_forward.y = 0.0
	camera_right.y = 0.0
	camera_forward = camera_forward.normalized()
	camera_right = camera_right.normalized()

	return camera_right * input_vector.x - camera_forward * input_vector.y
