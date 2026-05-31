extends Node3D

var _direction := Vector3.FORWARD
var _speed := 12.0
var _max_range := 20.0
var _distance_travelled := 0.0

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _base_scale: Vector3 = _mesh.scale
@onready var _debug_direct_hit: MeshInstance3D = $DebugDirectHit
@onready var _debug_splash_radius: MeshInstance3D = $DebugSplashRadius

var _impact_scene := preload("res://scenes/effects/ImpactBurst.tscn")
var _scorch_scene := preload("res://scenes/effects/ScorchMark.tscn")
var _splash_radius := 1.8
var _direct_hit_radius := 0.38


func configure(direction: Vector3, speed: float, max_range: float) -> void:
	_direction = direction.normalized()
	_speed = speed
	_max_range = max_range
	_update_debug_radius()


func set_splash_radius(value: float) -> void:
	_splash_radius = value
	_update_debug_radius()


func _process(delta: float) -> void:
	var movement := _direction * _speed * delta
	var next_position: Vector3 = global_position + movement
	var hit_result: Dictionary = _find_collision(next_position)
	if not hit_result.is_empty():
		_handle_collision(hit_result)
		return

	global_position = next_position
	_distance_travelled += movement.length()
	rotation.y += delta * 7.0
	var travel_ratio: float = clampf(_distance_travelled / maxf(_max_range, 0.001), 0.0, 1.0)
	var pulse: float = 1.0 + sin(Time.get_ticks_msec() * 0.02) * 0.08
	_mesh.scale = _base_scale * pulse * (1.0 - travel_ratio * 0.15)
	if _distance_travelled >= _max_range:
		queue_free()


func _ready() -> void:
	add_to_group("debug_hitbox_owner")
	set_debug_hitbox_visible(bool(get_tree().get_meta("show_debug_hitboxes", false)))


func _find_collision(sample_position: Vector3) -> Dictionary:
	var collision_sphere := SphereShape3D.new()
	collision_sphere.radius = _direct_hit_radius

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision_sphere
	query.transform = Transform3D(Basis.IDENTITY, sample_position)
	query.exclude = [self]
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var space_state := get_world_3d().direct_space_state
	var results: Array[Dictionary] = space_state.intersect_shape(query, 8)
	for result in results:
		var collider: Object = result.get("collider")
		if collider != null and collider.has_method("receive_fire_hit"):
			return {
				"collider": collider,
				"position": sample_position
			}

	return {}


func _handle_collision(hit_result: Dictionary) -> void:
	var collider: Object = hit_result.get("collider")
	var impact_position: Vector3 = hit_result.get("position", global_position)
	if collider != null and collider.has_method("receive_fire_hit"):
		collider.receive_fire_hit(impact_position)

	_apply_splash_damage(impact_position, collider)

	var impact: Node3D = _impact_scene.instantiate()
	get_parent().add_child(impact)
	impact.global_position = impact_position + Vector3.UP * 0.25
	var scorch: Node3D = _scorch_scene.instantiate()
	get_parent().add_child(scorch)
	scorch.global_position = Vector3(impact_position.x, 0.02, impact_position.z)
	queue_free()


func _apply_splash_damage(impact_position: Vector3, direct_collider: Object) -> void:
	for node in get_tree().get_nodes_in_group("target_dummy"):
		if node == direct_collider or not node.has_method("receive_fire_hit"):
			continue
		var splash_offset: Vector3 = node.global_position - impact_position
		splash_offset.y = 0.0
		if splash_offset.length() <= _splash_radius:
			node.receive_fire_hit(impact_position)


func _update_debug_radius() -> void:
	if _debug_splash_radius != null:
		var radius_scale := maxf(_splash_radius / 1.8, 0.001)
		_debug_splash_radius.scale = Vector3.ONE * radius_scale


func set_debug_hitbox_visible(is_visible: bool) -> void:
	if _debug_direct_hit != null:
		_debug_direct_hit.visible = is_visible
	if _debug_splash_radius != null:
		_debug_splash_radius.visible = is_visible
