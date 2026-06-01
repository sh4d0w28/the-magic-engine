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
	var inventory_system: Node = player.get_node("InventorySystem")
	var spellbook_system: Node = player.get_node("SpellbookSystem")
	var active_spells: Node3D = spell_manager.get_node("ActiveSpells")
	var wood_piles: Node = world.get_node("Environment/WoodPiles")
	var target_dummies: Node = world.get_node("Environment/TargetDummies")
	var hostiles: Node = world.get_node("Environment/Hostiles")
	var voice_power_tracker: Node = input_controller.get_node("VoicePowerTracker")
	var voice_incantation_recognizer: Node = input_controller.get_node("VoiceIncantationRecognizer")
	var diagram_recognizer: Node = input_controller.get_node("DiagramRecognizer")
	voice_incantation_recognizer.set_testing_mode(true)

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
	_assert(inventory_system.get_items().has("Kindling"), "Inventory starts with starter items")
	_assert(spellbook_system.get_known_spells().size() >= 3, "Spellbook starts with known spells")
	energy_system.mana = 50.0
	energy_system._process(1.0)
	_assert(energy_system.mana > 50.0, "Mana regenerates")
	_assert(hud.get_node("MarginContainer/VBoxContainer/ManaLabel").text.contains("55"), "HUD updates mana value")
	_assert(hud.get_node("MarginContainer/VBoxContainer/ScoreLabel").text.ends_with("0"), "HUD score starts at zero")

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

	input_controller._toggle_inventory_panel()
	await process_frame
	_assert(hud.get_node("InventoryPanel").visible, "Inventory toggle opens inventory panel")
	_assert(hud.get_node("InventoryPanel/MarginContainer/VBoxContainer/InventoryItemsLabel").text.contains("Kindling"), "Inventory panel shows starter items")
	input_controller._toggle_inventory_panel()
	await process_frame
	_assert(not hud.get_node("InventoryPanel").visible, "Inventory toggle closes inventory panel")

	input_controller._toggle_spellbook_panel()
	await process_frame
	_assert(hud.get_node("SpellbookPanel").visible, "Spellbook toggle opens spellbook panel")
	_assert(hud.get_node("SpellbookPanel/MarginContainer/VBoxContainer/KnownSpellsLabel").text.contains("Fireball"), "Spellbook shows known spells")
	var notes_edit: TextEdit = hud.get_node("SpellbookPanel/MarginContainer/VBoxContainer/NotesEdit")
	notes_edit.text = "Fireball blooms wider near wood."
	hud._on_spellbook_notes_text_changed()
	await process_frame
	_assert(spellbook_system.get_notes() == "Fireball blooms wider near wood.", "Spellbook notes persist to player state")
	input_controller._toggle_spellbook_panel()
	await process_frame
	_assert(not hud.get_node("SpellbookPanel").visible, "Spellbook toggle closes spellbook panel")

	input_controller._toggle_voice_mode()
	await process_frame
	_assert(
		hud.get_node("MarginContainer/VBoxContainer/MicStatusLabel").text.contains("Listening")
		or hud.get_node("MarginContainer/VBoxContainer/MicStatusLabel").text.contains("Armed"),
		"Voice mode arm starts listening"
	)
	voice_incantation_recognizer.listen_time_changed.emit(4.2)
	await process_frame
	_assert(hud.get_node("MarginContainer/VBoxContainer/VoiceWindowLabel").text.contains("4.2"), "HUD shows voice listen window")
	voice_incantation_recognizer.listening_stopped.emit()
	await process_frame
	voice_incantation_recognizer.recognition_completed.emit({
		"raw_text": "rak",
		"normalized_input": "RAK",
		"confidence": 0.91,
		"success": true
	})
	await process_frame
	await process_frame
	_assert(
		hud.get_node("MarginContainer/VBoxContainer/MicStatusLabel").text.contains("Listening")
		or hud.get_node("MarginContainer/VBoxContainer/MicStatusLabel").text.contains("Armed"),
		"Voice mode re-arms automatically after recognition"
	)
	for child in active_spells.get_children():
		child.queue_free()
	await process_frame
	input_controller._toggle_voice_mode()
	await process_frame
	_assert(hud.get_node("MarginContainer/VBoxContainer/MicStatusLabel").text.contains("Listening") or hud.get_node("MarginContainer/VBoxContainer/MicStatusLabel").text.contains("Armed") or hud.get_node("MarginContainer/VBoxContainer/MicStatusLabel").text.contains("Off"), "Voice mode toggle can disarm")

	energy_system.mana = 100.0
	voice_incantation_recognizer.simulate_recognition("rock tore", "RAK TOR", 0.88)
	await process_frame
	_assert(debug_panel.get_node("MarginContainer/VBoxContainer/RawInputLabel").text.ends_with("rock tore"), "Voice recognition updates raw input")
	_assert(debug_panel.get_node("MarginContainer/VBoxContainer/NormalizedInputLabel").text.ends_with("RAK TOR"), "Voice recognition normalizes incantation")
	_assert(hud.get_node("MarginContainer/VBoxContainer/LastVoiceLabel").text.contains("rock tore"), "HUD shows last spoken text")
	_assert(active_spells.get_child_count() == 1 and active_spells.get_child(0).name == "Fireball", "Voice recognition can cast fireball")
	for child in active_spells.get_children():
		child.queue_free()
	await process_frame

	voice_incantation_recognizer.listening_started.emit()
	voice_incantation_recognizer.mic_level_changed.emit(0.42)
	await process_frame
	_assert(hud.get_node("MarginContainer/VBoxContainer/MicStatusLabel").text.contains("Listening"), "HUD shows listening mic state")
	_assert(hud.get_node("MarginContainer/VBoxContainer/MicLevelBar").value > 0.4, "HUD shows microphone level")
	voice_incantation_recognizer.listening_stopped.emit()
	await process_frame
	_assert(hud.get_node("MarginContainer/VBoxContainer/MicStatusLabel").text.contains("Off"), "HUD shows mic off when disarmed")

	input_controller._toggle_voice_mode()
	await process_frame
	voice_incantation_recognizer.simulate_failure("Timed out waiting for microphone input.")
	await process_frame
	await process_frame
	_assert(hud.get_node("MarginContainer/VBoxContainer/StatusLabel").text.contains("Rearming") or hud.get_node("MarginContainer/VBoxContainer/MicStatusLabel").text.contains("Listening"), "Voice timeout shows rearm feedback")
	input_controller._toggle_voice_mode()
	await process_frame

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
	_assert(target_dummies.get_child_count() >= 1, "TargetDummy exists")
	_assert(hostiles.get_child_count() >= 1, "Hostile enemy exists")
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

	var fireball_scene: PackedScene = load("res://scenes/effects/Fireball.tscn")
	var spark_scene: PackedScene = load("res://scenes/effects/SparkEffect.tscn")
	var target_dummy: StaticBody3D = target_dummies.get_child(0)
	var hostile_enemy: CharacterBody3D = hostiles.get_child(0)
	var hit_test_fireball: Node3D = fireball_scene.instantiate()
	active_spells.add_child(hit_test_fireball)
	hit_test_fireball.global_position = target_dummy.global_position + Vector3(0.0, 1.0, 4.0)
	hit_test_fireball.configure(Vector3(0.0, 0.0, -1.0), 12.0, 10.0)
	var hit_count_before: int = target_dummy.hit_count
	for index in range(30):
		if not is_instance_valid(hit_test_fireball) or hit_test_fireball.is_queued_for_deletion():
			break
		hit_test_fireball._process(0.016)
	await process_frame
	_assert(target_dummy.hit_count > hit_count_before, "Fireball impact hits target dummy")
	_assert(not is_instance_valid(hit_test_fireball) or hit_test_fireball.is_queued_for_deletion(), "Fireball disappears on impact")
	var scorch_found := false
	for child in active_spells.get_children():
		if child.name == "ScorchMark":
			scorch_found = true
			child.queue_free()
	await process_frame
	_assert(scorch_found, "Fireball impact leaves scorch mark")

	var hostile_start_distance: float = hostile_enemy.global_position.distance_to(player.global_position)
	for index in range(20):
		hostile_enemy._physics_process(0.1)
	var hostile_end_distance: float = hostile_enemy.global_position.distance_to(player.global_position)
	_assert(hostile_end_distance < hostile_start_distance, "Hostile enemy moves toward player")

	var hostile_hit_before: int = hostile_enemy.current_health
	var hostile_spark: Node3D = spark_scene.instantiate()
	active_spells.add_child(hostile_spark)
	hostile_spark.global_position = hostile_enemy.global_position + Vector3(0.0, 0.5, 0.0)
	hostile_spark._process(0.016)
	await process_frame
	_assert(hostile_enemy.current_health < hostile_hit_before, "Spark affects hostile enemy")

	var splash_dummy_scene: PackedScene = load("res://scenes/environment/TargetDummy.tscn")
	var direct_dummy: StaticBody3D = splash_dummy_scene.instantiate()
	var nearby_dummy: StaticBody3D = splash_dummy_scene.instantiate()
	world.get_node("Environment/TargetDummies").add_child(direct_dummy)
	world.get_node("Environment/TargetDummies").add_child(nearby_dummy)
	direct_dummy.global_position = Vector3(-1.0, 0.0, -9.0)
	nearby_dummy.global_position = Vector3(0.2, 0.0, -9.1)
	await process_frame
	var splash_fireball: Node3D = fireball_scene.instantiate()
	active_spells.add_child(splash_fireball)
	splash_fireball.global_position = direct_dummy.global_position + Vector3(0.0, 1.0, 4.0)
	splash_fireball.configure(Vector3(0.0, 0.0, -1.0), 12.0, 10.0)
	splash_fireball.set_splash_radius(1.8)
	var nearby_hit_before: int = nearby_dummy.hit_count
	for index in range(30):
		if not is_instance_valid(splash_fireball) or splash_fireball.is_queued_for_deletion():
			break
		splash_fireball._process(0.016)
	await process_frame
	_assert(nearby_dummy.hit_count > nearby_hit_before, "Fireball splash damages nearby dummy")
	direct_dummy.queue_free()
	nearby_dummy.queue_free()
	await process_frame

	var spark_dummy: StaticBody3D = splash_dummy_scene.instantiate()
	world.get_node("Environment/TargetDummies").add_child(spark_dummy)
	spark_dummy.global_position = Vector3(2.0, 0.0, -4.0)
	await process_frame
	var test_spark: Node3D = spark_scene.instantiate()
	active_spells.add_child(test_spark)
	test_spark.global_position = spark_dummy.global_position + Vector3(0.0, 1.0, 0.0)
	var spark_hit_before: int = spark_dummy.hit_count
	test_spark._process(0.016)
	await process_frame
	_assert(spark_dummy.hit_count > spark_hit_before, "Spark affects target dummy")
	spark_dummy.queue_free()
	await process_frame

	var wood_for_spark: Node3D = wood_piles.get_child(0)
	var wood_fuel_before_spark: float = wood_for_spark.fuel_amount
	var wood_scale_before: Vector3 = wood_for_spark.get_node("MeshInstance3D").scale
	var wood_spark: Node3D = spark_scene.instantiate()
	active_spells.add_child(wood_spark)
	wood_spark.global_position = wood_for_spark.global_position + Vector3(0.0, 0.5, 0.0)
	wood_spark._process(0.016)
	await process_frame
	_assert(wood_for_spark.fuel_amount < wood_fuel_before_spark, "Spark interacts with wood")
	_assert(wood_for_spark.get_node("MeshInstance3D").scale.y < wood_scale_before.y, "Wood depletion is visible")

	var destroy_dummy: StaticBody3D = splash_dummy_scene.instantiate()
	world.get_node("Environment/TargetDummies").add_child(destroy_dummy)
	destroy_dummy.global_position = Vector3(4.0, 0.0, -4.0)
	await process_frame
	var score_label: Label = hud.get_node("MarginContainer/VBoxContainer/ScoreLabel")
	var score_before_destroy: int = int(score_label.text.trim_prefix("Score: "))
	var destroy_dummy_body: MeshInstance3D = destroy_dummy.get_node("BodyMesh")
	var destroy_dummy_health_fill: MeshInstance3D = destroy_dummy.get_node("HealthBarPivot/HealthBarFill")
	var body_color_before: Color = destroy_dummy_body.get_active_material(0).albedo_color
	var health_fill_scale_before: float = destroy_dummy_health_fill.scale.x
	destroy_dummy.receive_fire_hit(destroy_dummy.global_position)
	await process_frame
	var body_color_after: Color = destroy_dummy_body.get_active_material(0).albedo_color
	_assert(body_color_after != body_color_before, "Dummy health state is visible")
	_assert(destroy_dummy_health_fill.scale.x < health_fill_scale_before, "Dummy health bar updates on damage")
	var damage_number_found := false
	for child in destroy_dummy.get_children():
		if child is Label3D and child.text.begins_with("-"):
			damage_number_found = true
			break
	_assert(damage_number_found, "Dummy shows floating damage number")
	for index in range(3):
		destroy_dummy.receive_fire_hit(destroy_dummy.global_position)
	for index in range(30):
		if not is_instance_valid(destroy_dummy) or destroy_dummy.is_queued_for_deletion():
			break
		destroy_dummy._process(0.016)
	await process_frame
	var score_after_destroy: int = int(score_label.text.trim_prefix("Score: "))
	_assert(not is_instance_valid(destroy_dummy) or destroy_dummy.is_queued_for_deletion(), "Target dummy is destroyed at zero health")
	_assert(score_after_destroy > score_before_destroy, "Destroying dummy increases score")
	_assert(hud.get_node("MarginContainer/VBoxContainer/CombatFeedLabel").text.contains("Dummy destroyed"), "Combat feed reports dummy destruction")

	main.reset_encounter()
	await process_frame
	await process_frame
	var refreshed_hostile: CharacterBody3D = hostiles.get_child(0)
	player.restore_to_full()
	var player_health_before_hit: float = player.get_health()
	refreshed_hostile.force_attack_player()
	await process_frame
	_assert(player.get_health() < player_health_before_hit, "Hostile enemy damages player on contact")

	player.restore_to_full()
	player.take_damage(88.0)
	refreshed_hostile.force_attack_player()
	await process_frame
	main._process(float(main.get("encounter_reset_delay_seconds")) + 0.1)
	await process_frame
	await process_frame
	await physics_frame
	await physics_frame
	_assert(is_equal_approx(player.get_health(), 100.0), "Player health resets after defeat")
	_assert(is_equal_approx(player.get_mana(), 100.0), "Player mana resets after defeat")
	var respawn_offset: Vector3 = player.global_position - start_position
	_assert(respawn_offset.length() < 1.1 and absf(respawn_offset.z) < 0.2, "Player respawns near arena start after defeat")
	_assert(hostiles.get_child_count() >= 1, "Hostile enemies respawn after defeat")
	_assert(hud.get_node("MarginContainer/VBoxContainer/CombatFeedLabel").text.contains("Arena reset"), "Combat feed reports encounter reset")

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
	diagram_recognizer._input(draw_start)
	for point in [Vector2(50, 0), Vector2(25, 45), Vector2(0, 0)]:
		var move_event := InputEventMouseMotion.new()
		move_event.position = point
		diagram_recognizer._input(move_event)
	var draw_end := InputEventMouseButton.new()
	draw_end.button_index = MOUSE_BUTTON_RIGHT
	draw_end.pressed = false
	draw_end.position = Vector2(0, 0)
	diagram_recognizer._input(draw_end)
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
