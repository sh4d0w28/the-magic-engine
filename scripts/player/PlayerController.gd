extends CharacterBody3D

signal health_mana_changed(health: float, mana: float)

@export var player_id: String = "player_1"
@export var movement_speed: float = 6.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var _energy_system: Node = $EnergySystem


func _ready() -> void:
	add_to_group("player_controller")
	if _energy_system.has_signal("changed"):
		_energy_system.changed.connect(_on_energy_changed)
	_on_energy_changed(get_health(), get_mana())


func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

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


func spend_mana(amount: float) -> float:
	return _energy_system.spend_mana(amount)


func drain_health(amount: float) -> bool:
	return _energy_system.drain_health(amount)


func restore_mana(delta: float) -> void:
	_energy_system.restore_mana(delta)


func is_alive() -> bool:
	return _energy_system.is_alive()


func get_forward_direction() -> Vector3:
	var forward := -global_transform.basis.z
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
	return global_position + get_forward_direction() * 4.0


func _on_energy_changed(health: float, mana: float) -> void:
	health_mana_changed.emit(health, mana)
