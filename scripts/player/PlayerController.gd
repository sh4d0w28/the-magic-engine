extends CharacterBody3D

@export var movement_speed: float = 6.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta: float) -> void:
	var input_vector := Vector2.ZERO

	if Input.is_physical_key_pressed(KEY_A):
		input_vector.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_vector.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		input_vector.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_vector.y += 1.0

	var move_direction := Vector3(input_vector.x, 0.0, input_vector.y)
	if move_direction != Vector3.ZERO:
		move_direction = move_direction.normalized()

	velocity.x = move_direction.x * movement_speed
	velocity.z = move_direction.z * movement_speed

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()
