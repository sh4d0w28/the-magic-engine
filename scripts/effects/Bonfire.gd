extends Node3D

@export var fuel_search_radius: float = 3.0
@export var fuel_consume_interval_seconds: float = 5.0
@export var no_fuel_lifetime_seconds: float = 3.0

var _fuel_timer := 0.0
var _no_fuel_timer := 0.0

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _base_scale: Vector3 = _mesh.scale

var _material: StandardMaterial3D


func _process(delta: float) -> void:
	var fuel_source := _find_nearby_fuel_source()
	if fuel_source == null:
		_no_fuel_timer += delta
		_update_visuals(false)
		if _no_fuel_timer >= no_fuel_lifetime_seconds:
			queue_free()
		return

	_no_fuel_timer = 0.0
	_fuel_timer += delta
	_update_visuals(true)
	if _fuel_timer >= fuel_consume_interval_seconds:
		_fuel_timer = 0.0
		if not fuel_source.consume_fuel(1.0):
			_no_fuel_timer = no_fuel_lifetime_seconds


func _find_nearby_fuel_source() -> Node3D:
	var nearby_fuel_source: Node3D = null
	var shortest_distance := fuel_search_radius
	for node in get_tree().get_nodes_in_group("wood_pile"):
		if not node.has_method("has_fuel") or not node.has_fuel():
			continue

		var distance := global_position.distance_to(node.global_position)
		if distance <= shortest_distance:
			shortest_distance = distance
			nearby_fuel_source = node

	return nearby_fuel_source


func _ready() -> void:
	var source_material: Material = _mesh.get_active_material(0)
	if source_material is StandardMaterial3D:
		_material = source_material.duplicate() as StandardMaterial3D
		_mesh.set_surface_override_material(0, _material)


func _update_visuals(has_fuel: bool) -> void:
	var flicker: float = 1.0 + sin(Time.get_ticks_msec() * 0.015) * 0.08
	if has_fuel:
		_mesh.scale = _base_scale * Vector3(1.0, flicker, 1.0)
		if _material != null:
			_material.emission_energy_multiplier = 2.1 + absf(sin(Time.get_ticks_msec() * 0.01)) * 0.8
	else:
		var grace_ratio: float = clampf(_no_fuel_timer / maxf(no_fuel_lifetime_seconds, 0.001), 0.0, 1.0)
		_mesh.scale = _base_scale * lerp(1.0, 0.55, grace_ratio)
		if _material != null:
			_material.emission_energy_multiplier = lerp(1.6, 0.2, grace_ratio)
