extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	await _run()
	quit(_failures.size())


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return

	_failures.append(message)
	push_error("FAIL: %s" % message)


func _run() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	_assert(main_scene != null, "Main scene resource loads")
	if main_scene == null:
		return

	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var player: CharacterBody3D = main.get_node("Player")
	var world: Node3D = main.get_node("World")
	var ground: Node = world.get_node("Ground")
	var camera: Camera3D = player.get_node("CameraPivot/Camera3D")
	var hud: Control = main.get_node("UI/HUD")
	var debug_panel: Control = main.get_node("UI/DebugPanel")
	var input_controller: Node = main.get_node("InputController")
	var spell_manager: Node = main.get_node("SpellManager")
	var energy_system: Node = player.get_node("EnergySystem")
	var active_spells: Node3D = spell_manager.get_node("ActiveSpells")
	var wood_piles: Node = world.get_node("Environment/WoodPiles")
	var voice_power_tracker: Node = input_controller.get_node("VoicePowerTracker")
	var diagram_recognizer: Node = input_controller.get_node("DiagramRecognizer")

	_assert(main != null, "Main scene instantiates")
	_assert(player != null, "Player cube exists")
	_assert(ground != null, "Ground exists")
	_assert(camera != null, "Camera exists")
	_assert(camera.get_parent() == player.get_node("CameraPivot"), "Camera follows player via player hierarchy")

	var start_position: Vector3 = player.global_position
	Input.action_press("move_forward")
	for index in range(8):
		player._physics_process(0.016)
	var move_distance: float = player.global_position.distance_to(start_position)
	_assert(move_distance > 0.01, "WASD movement moves player")
	Input.action_release("move_forward")

	_assert(is_equal_approx(player.get_health(), 100.0), "Health starts at 100")
	_assert(is_equal_approx(player.get_mana(), 100.0), "Mana starts at 100")
	energy_system.mana = 50.0
	energy_system._process(1.0)
	_assert(energy_system.mana > 50.0, "Mana regenerates")
	_assert(hud.get_node("MarginContainer/VBoxContainer/ManaLabel").text.contains("55"), "HUD updates mana value")

	var open_event := InputEventKey.new()
	open_event.pressed = true
	open_event.keycode = KEY_ENTER
	input_controller._unhandled_input(open_event)
	_assert(hud.is_input_open(), "Enter opens input mode")
	var input_line: LineEdit = hud.get_node("MarginContainer/VBoxContainer/InputLine")
	input_line.text = "rak   tor"
	_assert(input_line.text == "rak   tor", "Text can be typed")

	hud._on_input_submitted(input_line.text)
	await process_frame
	_assert(not hud.is_input_open(), "Enter submits phrase")
	_assert(debug_panel.get_node("MarginContainer/VBoxContainer/NormalizedInputLabel").text.ends_with("RAK TOR"), "Debug panel shows normalized phrase")
	for child in active_spells.get_children():
		child.queue_free()
	await process_frame

	input_controller._unhandled_input(open_event)
	var escape_event := InputEventKey.new()
	escape_event.pressed = true
	escape_event.keycode = KEY_ESCAPE
	input_controller._unhandled_input(escape_event)
	_assert(not hud.is_input_open(), "Escape cancels input")

	# Milestone 4 and 5
	energy_system.mana = 100.0
	energy_system.health = 100.0
	spell_manager.submit_typed_incantation("RAK", "RAK")
	await process_frame
	_assert(active_spells.get_child_count() == 1, "RAK maps to Spark")
	_assert(active_spells.get_child(0).name == "SparkEffect", "Spark visual appears")
	for index in range(80):
		active_spells.get_child(0)._process(0.016)
	await process_frame
	_assert(active_spells.get_child_count() == 0, "Spark visual disappears")

	spell_manager.submit_typed_incantation("RAK TOR", "RAK TOR")
	await process_frame
	_assert(active_spells.get_child_count() == 1, "RAK TOR maps to Fireball")
	var fireball: Node3D = active_spells.get_child(0)
	var fireball_start: Vector3 = fireball.global_position
	fireball._process(0.5)
	_assert(fireball.global_position.distance_to(fireball_start) > 0.1, "Fireball moves forward")
	fireball.queue_free()
	await process_frame

	spell_manager.submit_typed_incantation("RAK DUM", "RAK DUM")
	await process_frame
	_assert(active_spells.get_child_count() == 1, "RAK DUM maps to Bonfire")
	_assert(active_spells.get_child(0).name == "Bonfire", "Bonfire appears")
	active_spells.get_child(0).queue_free()
	await process_frame

	var debug_message_before: String = debug_panel.get_node("MarginContainer/VBoxContainer/MessageLabel").text
	spell_manager.submit_typed_incantation("RAK XYZ", "RAK XYZ")
	await process_frame
	var debug_message_after: String = debug_panel.get_node("MarginContainer/VBoxContainer/MessageLabel").text
	_assert(debug_message_after != debug_message_before and debug_message_after.contains("Unknown incantation"), "Unknown phrase fails")

	energy_system.mana = 10.0
	energy_system.health = 100.0
	spell_manager.submit_typed_incantation("RAK TOR", "RAK TOR")
	await process_frame
	_assert(energy_system.mana < 10.0, "Mana is spent")
	_assert(energy_system.health < 100.0, "Health is drained if mana is insufficient")
	for child in active_spells.get_children():
		child.queue_free()
	await process_frame

	energy_system.mana = 0.0
	energy_system.health = 10.0
	spell_manager.submit_typed_incantation("RAK TOR", "RAK TOR")
	await process_frame
	_assert(debug_panel.get_node("MarginContainer/VBoxContainer/MessageLabel").text.contains("Not enough mana or health"), "Spell fails if health cannot pay")
	for child in active_spells.get_children():
		child.queue_free()
	await process_frame

	_assert(wood_piles.get_child_count() >= 1, "WoodPile exists")
	var wood_before: float = wood_piles.get_child(0).fuel_amount
	var bonfire_scene: PackedScene = load("res://scenes/effects/Bonfire.tscn")
	var bonfire_near: Node3D = bonfire_scene.instantiate()
	active_spells.add_child(bonfire_near)
	bonfire_near.global_position = wood_piles.get_child(0).global_position + Vector3(1.0, 0.0, 0.0)
	for index in range(6):
		bonfire_near._process(1.0)
	_assert(is_instance_valid(bonfire_near), "Bonfire near wood stays alive")
	_assert(wood_piles.get_child(0).fuel_amount < wood_before, "Bonfire consumes wood")
	bonfire_near.queue_free()
	await process_frame

	var bonfire_far: Node3D = bonfire_scene.instantiate()
	active_spells.add_child(bonfire_far)
	bonfire_far.global_position = Vector3(100.0, 0.0, 100.0)
	for index in range(4):
		bonfire_far._process(1.0)
	_assert(not is_instance_valid(bonfire_far) or bonfire_far.is_queued_for_deletion(), "Bonfire without wood dies after 3 seconds")
	await process_frame

	var voice_before: float = voice_power_tracker.get_voice_power()
	Input.action_press("voice_charge")
	voice_power_tracker._process(1.5)
	Input.action_release("voice_charge")
	voice_power_tracker._process(0.1)
	_assert(voice_power_tracker.get_voice_power() > voice_before, "Holding V increases voice_power")

	voice_power_tracker.reset()
	voice_power_tracker._set_voice_power(1.0)
	energy_system.mana = 100.0
	spell_manager.submit_typed_incantation("RAK", "RAK")
	await process_frame
	var cost_with_voice: String = debug_panel.get_node("MarginContainer/VBoxContainer/CostLabel").text
	var power_with_voice: String = debug_panel.get_node("MarginContainer/VBoxContainer/PowerLabel").text
	for child in active_spells.get_children():
		child.queue_free()
	await process_frame
	voice_power_tracker.reset()
	energy_system.mana = 100.0
	spell_manager.submit_typed_incantation("RAK", "RAK")
	await process_frame
	var cost_without_voice: String = debug_panel.get_node("MarginContainer/VBoxContainer/CostLabel").text
	_assert(cost_with_voice != cost_without_voice, "voice_power affects final_cost")
	_assert(power_with_voice != debug_panel.get_node("MarginContainer/VBoxContainer/PowerLabel").text, "voice_power affects final_power")
	for child in active_spells.get_children():
		child.queue_free()
	await process_frame

	var draw_start := InputEventMouseButton.new()
	draw_start.button_index = MOUSE_BUTTON_RIGHT
	draw_start.pressed = true
	draw_start.position = Vector2(0, 0)
	diagram_recognizer._unhandled_input(draw_start)
	for point in [Vector2(50, 0), Vector2(25, 45), Vector2(0, 0)]:
		var move_event := InputEventMouseMotion.new()
		move_event.position = point
		diagram_recognizer._unhandled_input(move_event)
	var draw_end := InputEventMouseButton.new()
	draw_end.button_index = MOUSE_BUTTON_RIGHT
	draw_end.pressed = false
	draw_end.position = Vector2(0, 0)
	diagram_recognizer._unhandled_input(draw_end)
	var triangle_result: Dictionary = diagram_recognizer.get_diagram_result()
	_assert(triangle_result.get("point_count", 0) >= 3, "Drawing records points")
	_assert(triangle_result.get("shape_type", "") == "triangle", "Triangle is detected")
	_assert(float(triangle_result.get("size", 0.0)) > 0.0, "Diagram size affects power")

	diagram_recognizer._start_drawing(Vector2(100, 100))
	for point in [
		Vector2(125, 95),
		Vector2(140, 110),
		Vector2(140, 130),
		Vector2(125, 145),
		Vector2(105, 145),
		Vector2(90, 130),
		Vector2(90, 110),
		Vector2(105, 95),
		Vector2(100, 100)
	]:
		diagram_recognizer._points.append(point)
	diagram_recognizer._finish_drawing()
	var circle_result: Dictionary = diagram_recognizer.get_diagram_result()
	_assert(circle_result.get("shape_type", "") == "circle", "Circle is detected")

	voice_power_tracker.reset()
	energy_system.mana = 100.0
	diagram_recognizer._last_result = {"shape_type": "triangle", "accuracy": 1.0, "size": 0.5, "point_count": 4}
	spell_manager.submit_typed_incantation("RAK", "RAK")
	await process_frame
	var wrong_shape_stability_text: String = debug_panel.get_node("MarginContainer/VBoxContainer/StabilityLabel").text
	_assert(wrong_shape_stability_text.contains("0."), "Wrong diagram reduces stability")

	main.queue_free()
	await process_frame

	if _failures.is_empty():
		print("Acceptance runner passed.")
	else:
		print("Acceptance runner failures: %s" % _failures.size())
		for failure in _failures:
			print(" - %s" % failure)
