extends CharacterBody3D

signal enemy_damaged(current_health: int, max_health: int)
signal enemy_destroyed(score_value: int)
signal player_contact_damage(amount: float)

@export var move_speed: float = 3.8
@export var acceleration: float = 10.0
@export var engagement_range: float = 16.0
@export var attack_range: float = 1.45
@export var attack_damage: float = 12.0
@export var attack_cooldown_seconds: float = 1.0
@export var hit_flash_duration: float = 0.16
@export var max_health: int = 2
@export var destroy_delay_seconds: float = 0.25
@export var score_value: int = 2

@onready var _body_mesh: MeshInstance3D = $BodyMesh
@onready var _head_mesh: MeshInstance3D = $HeadMesh
@onready var _health_bar_pivot: Node3D = $HealthBarPivot
@onready var _health_bar_fill: MeshInstance3D = $HealthBarPivot/HealthBarFill
@onready var _debug_hitbox: MeshInstance3D = $DebugHitbox

var _body_material: StandardMaterial3D
var _head_material: StandardMaterial3D
var _attack_cooldown_remaining := 0.0
var _hit_flash_remaining := 0.0
var _destroy_timer := -1.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _player: CharacterBody3D
var current_health := 0
var is_destroyed := false


func _ready() -> void:
	add_to_group("hostile_enemy")
	add_to_group("debug_hitbox_owner")
	_body_material = _duplicate_material(_body_mesh)
	_head_material = _duplicate_material(_head_mesh)
	_player = _resolve_player()
	current_health = max_health
	_update_health_visuals()
	set_debug_hitbox_visible(bool(get_tree().get_meta("show_debug_hitboxes", false)))


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = _resolve_player()

	if _destroy_timer >= 0.0:
		_destroy_timer -= delta
		scale = scale.lerp(Vector3(0.2, 0.1, 0.2), minf(delta * 12.0, 1.0))
		position.y = lerpf(position.y, -0.25, minf(delta * 8.0, 1.0))
		if _destroy_timer <= 0.0:
			queue_free()
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	if is_destroyed or _player == null or not _player.is_alive():
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		move_and_slide()
		return

	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)

	var flat_offset := _player.global_position - global_position
	flat_offset.y = 0.0
	var desired_velocity := Vector3.ZERO

	if flat_offset.length() <= engagement_range:
		if flat_offset.length() > attack_range:
			desired_velocity = flat_offset.normalized() * move_speed
		elif _attack_cooldown_remaining <= 0.0:
			_attack_player()

	velocity.x = move_toward(velocity.x, desired_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, acceleration * delta)
	move_and_slide()

	var look_velocity := Vector3(velocity.x, 0.0, velocity.z)
	if look_velocity.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(-look_velocity.x, -look_velocity.z), minf(delta * 8.0, 1.0))


func _process(delta: float) -> void:
	if _health_bar_pivot != null:
		_health_bar_pivot.global_rotation = Vector3.ZERO

	if _hit_flash_remaining <= 0.0 or is_destroyed:
		return

	_hit_flash_remaining = maxf(_hit_flash_remaining - delta, 0.0)
	var flash_ratio: float = _hit_flash_remaining / hit_flash_duration
	var flash_strength: float = lerpf(0.0, 2.8, flash_ratio)
	if _body_material != null:
		_body_material.emission_energy_multiplier = flash_strength
	if _head_material != null:
		_head_material.emission_energy_multiplier = flash_strength


func receive_fire_hit(_impact_position: Vector3) -> void:
	_apply_damage(1, Color(1.0, 0.36, 0.16, 1.0), Color(1.0, 0.58, 0.2, 1.0))


func receive_spark_hit() -> void:
	_apply_damage(1, Color(1.0, 0.82, 0.35, 1.0), Color(1.0, 0.92, 0.48, 1.0))


func force_attack_player() -> void:
	if _player == null or not is_instance_valid(_player):
		_player = _resolve_player()
	if is_destroyed or _player == null or not _player.is_alive():
		return
	_attack_player()


func _attack_player() -> void:
	_attack_cooldown_remaining = attack_cooldown_seconds
	_hit_flash_remaining = hit_flash_duration * 0.65
	if _body_material != null:
		_body_material.emission = Color(1.0, 0.18, 0.1, 1.0)
	if _head_material != null:
		_head_material.emission = Color(1.0, 0.4, 0.12, 1.0)
	player_contact_damage.emit(attack_damage)
	if _player.has_method("take_damage"):
		_player.take_damage(attack_damage)


func _apply_damage(amount: int, body_color: Color, head_color: Color) -> void:
	if is_destroyed:
		return

	current_health = max(current_health - amount, 0)
	_spawn_damage_number(amount)
	_hit_flash_remaining = hit_flash_duration
	if _body_material != null:
		_body_material.emission = body_color
	if _head_material != null:
		_head_material.emission = head_color
	_update_health_visuals()
	enemy_damaged.emit(current_health, max_health)
	if current_health == 0:
		_begin_destroy()


func _begin_destroy() -> void:
	is_destroyed = true
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	_destroy_timer = destroy_delay_seconds
	enemy_destroyed.emit(score_value)


func _update_health_visuals() -> void:
	var health_ratio: float = float(current_health) / float(max(max_health, 1))
	var base_color := Color(1.0, 0.26, 0.18, 1.0).lerp(Color(0.92, 0.95, 0.36, 1.0), health_ratio)
	if _body_material != null:
		_body_material.albedo_color = base_color.darkened(0.08)
	if _head_material != null:
		_head_material.albedo_color = base_color.lightened(0.05)
	_body_mesh.scale = Vector3(1.0, 0.7 + health_ratio * 0.25, 1.0)
	_head_mesh.position.y = 1.42 + health_ratio * 0.18
	if _health_bar_fill != null:
		_health_bar_fill.scale.x = maxf(health_ratio, 0.001)
		_health_bar_fill.position.x = lerpf(-0.45, 0.0, health_ratio)
		var fill_material := _health_bar_fill.get_active_material(0)
		if fill_material is StandardMaterial3D:
			fill_material.albedo_color = Color(1.0, 0.3, 0.2, 0.95).lerp(Color(1.0, 0.85, 0.28, 0.95), health_ratio)


func _duplicate_material(mesh_instance: MeshInstance3D) -> StandardMaterial3D:
	var source_material: Material = mesh_instance.get_active_material(0)
	if source_material is StandardMaterial3D:
		var duplicated_material := source_material.duplicate() as StandardMaterial3D
		mesh_instance.set_surface_override_material(0, duplicated_material)
		return duplicated_material
	return null


func _resolve_player() -> CharacterBody3D:
	return get_tree().get_first_node_in_group("player_controller") as CharacterBody3D


func _spawn_damage_number(amount: int) -> void:
	var label := Label3D.new()
	label.text = "-%d" % amount
	label.font_size = 26
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 0.78, 0.22, 1.0)
	label.outline_modulate = Color(0.28, 0.08, 0.02, 1.0)
	label.outline_size = 5
	label.position = Vector3(randf_range(-0.12, 0.12), 2.1, randf_range(-0.12, 0.12))
	add_child(label)

	var tween := create_tween()
	tween.parallel().tween_property(label, "position:y", label.position.y + 0.7, 0.4)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.4)
	tween.finished.connect(label.queue_free)


func set_debug_hitbox_visible(is_visible: bool) -> void:
	if _debug_hitbox != null:
		_debug_hitbox.visible = is_visible
