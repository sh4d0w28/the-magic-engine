extends StaticBody3D

@export var hit_flash_duration: float = 0.18
@export var max_health: int = 3
@export var destroy_delay_seconds: float = 0.35

@onready var _body_mesh: MeshInstance3D = $BodyMesh
@onready var _head_mesh: MeshInstance3D = $HeadMesh

var _body_material: StandardMaterial3D
var _head_material: StandardMaterial3D
var _hit_flash_remaining := 0.0
var _destroy_timer := -1.0
var hit_count := 0
var current_health := 0
var is_destroyed := false


func _ready() -> void:
	add_to_group("target_dummy")
	_body_material = _duplicate_material(_body_mesh)
	_head_material = _duplicate_material(_head_mesh)
	current_health = max_health


func _process(delta: float) -> void:
	if _destroy_timer >= 0.0:
		_destroy_timer -= delta
		scale = scale.lerp(Vector3(0.2, 0.05, 0.2), minf(delta * 10.0, 1.0))
		position.y = lerpf(position.y, -0.4, minf(delta * 8.0, 1.0))
		if _destroy_timer <= 0.0:
			queue_free()
		return

	if _hit_flash_remaining <= 0.0:
		return

	_hit_flash_remaining = maxf(_hit_flash_remaining - delta, 0.0)
	var flash_ratio: float = _hit_flash_remaining / hit_flash_duration
	var flash_strength: float = lerpf(0.0, 3.4, flash_ratio)
	if _body_material != null:
		_body_material.emission_energy_multiplier = flash_strength
	if _head_material != null:
		_head_material.emission_energy_multiplier = flash_strength


func receive_fire_hit(_impact_position: Vector3) -> void:
	hit_count += 1
	_apply_damage(1, Color(1.0, 0.45, 0.16, 1.0), Color(1.0, 0.55, 0.2, 1.0))


func receive_spark_hit() -> void:
	hit_count += 1
	_apply_damage(1, Color(1.0, 0.8, 0.3, 1.0), Color(1.0, 0.9, 0.45, 1.0))


func _apply_damage(amount: int, body_color: Color, head_color: Color) -> void:
	if is_destroyed:
		return

	current_health = max(current_health - amount, 0)
	_hit_flash_remaining = hit_flash_duration
	if _body_material != null:
		_body_material.emission = body_color
	if _head_material != null:
		_head_material.emission = head_color
	if current_health == 0:
		_begin_destroy()


func _begin_destroy() -> void:
	is_destroyed = true
	_destroy_timer = destroy_delay_seconds
	collision_layer = 0
	collision_mask = 0


func _duplicate_material(mesh_instance: MeshInstance3D) -> StandardMaterial3D:
	var source_material: Material = mesh_instance.get_active_material(0)
	if source_material is StandardMaterial3D:
		var duplicated_material := source_material.duplicate() as StandardMaterial3D
		mesh_instance.set_surface_override_material(0, duplicated_material)
		return duplicated_material
	return null
