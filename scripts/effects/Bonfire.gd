extends Node3D

@export var fuel_search_radius: float = 3.0
@export var fuel_consume_interval_seconds: float = 5.0
@export var no_fuel_lifetime_seconds: float = 3.0

var _fuel_timer := 0.0
var _no_fuel_timer := 0.0


func _process(delta: float) -> void:
	var fuel_source := _find_nearby_fuel_source()
	if fuel_source == null:
		_no_fuel_timer += delta
		if _no_fuel_timer >= no_fuel_lifetime_seconds:
			queue_free()
		return

	_no_fuel_timer = 0.0
	_fuel_timer += delta
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
