extends CharacterBody3D

signal health_mana_changed(health: float, mana: float)
signal player_damaged(amount: float, health_remaining: float)
signal player_defeated

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
var _defeat_reported := false


func _ready() -> void:
	add_to_group("player_controller")
	if _energy_system.has_signal("changed"):
		_energy_system.changed.connect(_on_energy_changed)
	_camera_pitch_radians = _camera_pivot.rotation.x
	_on_energy_changed(get_health(), get_mana())


func _physics_process(delta: float) -> void:
	if not is_alive():
		velocity = Vector3.ZERO
		return

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


func _input(event: InputEvent) -> void:
	if not is_alive():
		return

	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		orbit_camera(event.relative)
		get_viewport().set_input_as_handled()


func spend_mana(amount: float) -> float:
	return _energy_system.spend_mana(amount)


func drain_health(amount: float) -> bool:
	return _energy_system.drain_health(amount)


func restore_mana(delta: float) -> void:
	_energy_system.restore_mana(delta)


func take_damage(amount: float) -> bool:
	var was_alive := is_alive()
	var alive_after_hit: bool = _energy_system.apply_damage(amount)
	player_damaged.emit(amount, get_health())
	if was_alive and not alive_after_hit and not _defeat_reported:
		_defeat_reported = true
		player_defeated.emit()
	return alive_after_hit


func restore_to_full() -> void:
	_defeat_reported = false
	_energy_system.restore_full()


func reset_to_transform(respawn_transform: Transform3D) -> void:
	velocity = Vector3.ZERO
	PhysicsServer3D.body_set_state(get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, respawn_transform)
	global_transform = respawn_transform
	call_deferred("_apply_respawn_transform", respawn_transform)


func _apply_respawn_transform(respawn_transform: Transform3D) -> void:
	velocity = Vector3.ZERO
	PhysicsServer3D.body_set_state(get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, respawn_transform)
	global_transform = respawn_transform


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
	var camera: Camera3D = $CameraPivot/Camera3D
	var viewport := get_viewport()
	var target_screen_position: Vector2 = viewport.get_mouse_position()
	if target_screen_position == Vector2.ZERO:
		target_screen_position = viewport.get_visible_rect().size * 0.5

	var ray_origin: Vector3 = camera.project_ray_origin(target_screen_position)
	var ray_direction: Vector3 = camera.project_ray_normal(target_screen_position)
	var ground_plane := Plane(Vector3.UP, 0.0)
	var target_position: Variant = ground_plane.intersects_ray(ray_origin, ray_direction)
	if target_position is Vector3:
		return target_position

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
