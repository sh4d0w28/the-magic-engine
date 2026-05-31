extends Node3D

@onready var _ring: MeshInstance3D = $Ring
@onready var _core: MeshInstance3D = $Core

var _ring_material: StandardMaterial3D
var _core_material: StandardMaterial3D
var _player: Node
var _voice_power_tracker: Node
var _diagram_recognizer: Node


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player_controller")
	_voice_power_tracker = get_node_or_null("../../InputController/VoicePowerTracker")
	_diagram_recognizer = get_node_or_null("../../InputController/DiagramRecognizer")
	_ring_material = _duplicate_material(_ring)
	_core_material = _duplicate_material(_core)


func _process(delta: float) -> void:
	if _player == null:
		return

	var target_position: Vector3 = _player.get_target_position()
	global_position = Vector3(target_position.x, 0.06, target_position.z)
	rotation.y += delta * 0.9

	var voice_power: float = 0.0
	if _voice_power_tracker != null:
		voice_power = float(_voice_power_tracker.get_voice_power())

	var diagram_type := "none"
	if _diagram_recognizer != null:
		diagram_type = str(_diagram_recognizer.get_diagram_result().get("shape_type", "none"))

	_apply_visual_state(voice_power, diagram_type)


func _apply_visual_state(voice_power: float, diagram_type: String) -> void:
	var base_color := Color(0.31, 0.77, 1.0, 0.78)
	match diagram_type:
		"triangle":
			base_color = Color(1.0, 0.57, 0.18, 0.82)
		"circle":
			base_color = Color(0.45, 1.0, 0.68, 0.82)
		"circle_with_dot":
			base_color = Color(1.0, 0.36, 0.25, 0.85)

	var charge_scale: float = 1.0 + voice_power * 0.55
	var pulse: float = 1.0 + sin(Time.get_ticks_msec() * 0.01) * 0.06
	_ring.scale = Vector3(charge_scale * pulse, 1.0, charge_scale * pulse)
	_core.scale = Vector3.ONE * (0.9 + voice_power * 0.7)
	_core.position.y = 0.16 + voice_power * 0.22

	if _ring_material != null:
		_ring_material.albedo_color = base_color
		_ring_material.emission = base_color
		_ring_material.emission_energy_multiplier = 1.4 + voice_power * 1.8
	if _core_material != null:
		var core_color := base_color.lightened(0.28)
		_core_material.albedo_color = core_color
		_core_material.emission = core_color
		_core_material.emission_energy_multiplier = 1.9 + voice_power * 2.4


func _duplicate_material(mesh_instance: MeshInstance3D) -> StandardMaterial3D:
	var source_material: Material = mesh_instance.get_active_material(0)
	if source_material is StandardMaterial3D:
		var duplicated_material := source_material.duplicate() as StandardMaterial3D
		mesh_instance.set_surface_override_material(0, duplicated_material)
		return duplicated_material
	return null
