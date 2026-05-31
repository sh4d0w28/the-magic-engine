extends StaticBody3D

signal dummy_damaged(current_health: int, max_health: int)
signal dummy_destroyed(score_value: int)

@export var hit_flash_duration: float = 0.18
@export var max_health: int = 3
@export var destroy_delay_seconds: float = 0.35
@export var score_value: int = 1

@onready var _body_mesh: MeshInstance3D = $BodyMesh
@onready var _head_mesh: MeshInstance3D = $HeadMesh
@onready var _health_bar_pivot: Node3D = $HealthBarPivot
@onready var _health_bar_fill: MeshInstance3D = $HealthBarPivot/HealthBarFill
@onready var _debug_hitbox: MeshInstance3D = $DebugHitbox

var _body_material: StandardMaterial3D
var _head_material: StandardMaterial3D
var _hit_flash_remaining := 0.0
var _destroy_timer := -1.0
var hit_count := 0
var current_health := 0
var is_destroyed := false


func _ready() -> void:
	add_to_group("target_dummy")
	add_to_group("debug_hitbox_owner")
	_body_material = _duplicate_material(_body_mesh)
	_head_material = _duplicate_material(_head_mesh)
	current_health = max_health
	_update_health_visuals()
	set_debug_hitbox_visible(bool(get_tree().get_meta("show_debug_hitboxes", false)))


func _process(delta: float) -> void:
	if _health_bar_pivot != null:
		_health_bar_pivot.global_rotation = Vector3.ZERO

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
	_spawn_damage_number(amount)
	_hit_flash_remaining = hit_flash_duration
	if _body_material != null:
		_body_material.emission = body_color
	if _head_material != null:
		_head_material.emission = head_color
	_update_health_visuals()
	dummy_damaged.emit(current_health, max_health)
	if current_health == 0:
		_begin_destroy()


func _begin_destroy() -> void:
	is_destroyed = true
	_destroy_timer = destroy_delay_seconds
	collision_layer = 0
	collision_mask = 0
	dummy_destroyed.emit(score_value)


func _update_health_visuals() -> void:
	var health_ratio: float = float(current_health) / float(max(max_health, 1))
	var base_color := Color(1.0, 0.28, 0.18, 1.0).lerp(Color(0.45, 0.85, 0.35, 1.0), health_ratio)
	if _body_material != null:
		_body_material.albedo_color = base_color.darkened(0.1)
	if _head_material != null:
		_head_material.albedo_color = base_color.lightened(0.08)
	_body_mesh.scale = Vector3(1.0, 0.8 + health_ratio * 0.2, 1.0)
	_head_mesh.position.y = 1.75 + health_ratio * 0.25
	if _health_bar_fill != null:
		_health_bar_fill.scale.x = maxf(health_ratio, 0.001)
		_health_bar_fill.position.x = lerpf(-0.45, 0.0, health_ratio)
		var fill_material := _health_bar_fill.get_active_material(0)
		if fill_material is StandardMaterial3D:
			fill_material.albedo_color = Color(1.0, 0.25, 0.2, 0.95).lerp(Color(0.35, 0.95, 0.5, 0.95), health_ratio)


func _duplicate_material(mesh_instance: MeshInstance3D) -> StandardMaterial3D:
	var source_material: Material = mesh_instance.get_active_material(0)
	if source_material is StandardMaterial3D:
		var duplicated_material := source_material.duplicate() as StandardMaterial3D
		mesh_instance.set_surface_override_material(0, duplicated_material)
		return duplicated_material
	return null


func _spawn_damage_number(amount: int) -> void:
	var label := Label3D.new()
	label.text = "-%d" % amount
	label.font_size = 28
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 0.85, 0.35, 1.0)
	label.outline_modulate = Color(0.25, 0.12, 0.04, 1.0)
	label.outline_size = 6
	label.position = Vector3(randf_range(-0.15, 0.15), 2.5, randf_range(-0.15, 0.15))
	add_child(label)

	var tween := create_tween()
	tween.parallel().tween_property(label, "position:y", label.position.y + 0.8, 0.45)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.45)
	tween.finished.connect(label.queue_free)


func set_debug_hitbox_visible(is_visible: bool) -> void:
	if _debug_hitbox != null:
		_debug_hitbox.visible = is_visible
