extends Node3D

@export var duration_seconds: float = 1.0
@export var interaction_radius: float = 1.1

var _elapsed_seconds := 0.0
var _interaction_applied := false

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _base_scale: Vector3 = _mesh.scale


func _process(delta: float) -> void:
	if not _interaction_applied:
		_apply_interactions()
		_interaction_applied = true
	_elapsed_seconds += delta
	position.y += delta * 0.35
	var life_ratio: float = clampf(_elapsed_seconds / duration_seconds, 0.0, 1.0)
	var pulse: float = 1.0 + sin(life_ratio * PI) * 0.35
	_mesh.scale = _base_scale * pulse * (1.0 - life_ratio * 0.25)
	if _elapsed_seconds >= duration_seconds:
		queue_free()


func _apply_interactions() -> void:
	for node in get_tree().get_nodes_in_group("target_dummy"):
		if node.global_position.distance_to(global_position) <= interaction_radius and node.has_method("receive_spark_hit"):
			node.receive_spark_hit()

	for node in get_tree().get_nodes_in_group("wood_pile"):
		if node.global_position.distance_to(global_position) <= interaction_radius and node.has_method("receive_spark_ignite"):
			node.receive_spark_ignite()
