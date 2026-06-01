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
	var pickups: Node = world.get_node("Environment/Pickups")
	var voice_power_tracker: Node = input_controller.get_node("VoicePowerTracker")
	var voice_incantation_recognizer: Node = input_controller.get_node("VoiceIncantationRecognizer")
	var diagram_recognizer: Node = input_controller.get_node("DiagramRecognizer")
	voice_incantation_recognizer.set_testing_mode(true)

	_assert(main != null, "Main scene instantiates")
	_assert(player != null, "Player exists")
	_assert(ground != null, "Ground exists")
	_assert(camera != null, "Camera exists")
	_assert(camera.get_parent() == player.get_node("CameraPivot"), "Camera follows player via player hierarchy")

	var start_position: Vector3 = player.global_position
	Input.action_press("move_forward")
	for _index in range(8):
		player._physics_process(0.016)
	Input.action_release("move_forward")
	_assert(player.global_position.distance_to(start_position) > 0.01, "WASD movement moves player")

	_assert(is_equal_approx(player.get_health(), 100.0), "Health starts at 100")
	_assert(is_equal_approx(player.get_mana(), 100.0), "Mana starts at 100")
	_assert(inventory_system.get_items().has("Blank Page"), "Inventory starts with authoring materials")
	_assert(spellbook_system.get_discovered_lexemes().is_empty(), "Spellbook starts with zero discovered words")
	_assert(spellbook_system.get_formula_page_count() == 0, "Spellbook starts with zero formula pages")

	var preview_before: Dictionary = spell_manager.preview_incantation("RAK", "RAK")
	_assert(str(preview_before.get("message", "")).contains("Meaning not learned yet"), "Undiscovered real word fails as locked meaning")
	var unknown_preview: Dictionary = spell_manager.preview_incantation("XYZ", "XYZ")
	_assert(str(unknown_preview.get("message", "")).contains("No meaning found"), "Unknown token fails as no meaning found")

	var rak_pickup: Node3D = _find_pickup_by_lexeme(pickups, "RAK")
	player.global_position = rak_pickup.global_position + Vector3(0.0, 0.75, 0.0)
	input_controller._pickup_nearest_item()
	await process_frame
	_assert(spellbook_system.has_discovered_lexeme("RAK"), "Picking up primer discovers RAK")
	_assert(hud.get_node("SpellbookPanel/MarginContainer/VBoxContainer/KnownWordsLabel").text.contains("RAK"), "Known words UI updates after discovery")

	input_controller._toggle_spellbook_panel()
	await process_frame
	var blank_pages_before: int = int(inventory_system.get_items().get("Blank Page", 0))
	var ink_before: int = int(inventory_system.get_items().get("Ink Vial", 0))
	input_controller._create_spellbook_page()
	await process_frame
	_assert(spellbook_system.get_formula_page_count() == 1, "Formula page can be authored")
	_assert(int(inventory_system.get_items().get("Blank Page", 0)) == blank_pages_before - 1, "Authoring consumes blank page")
	_assert(int(inventory_system.get_items().get("Ink Vial", 0)) == ink_before - 1, "Authoring consumes ink")
	var title_edit: LineEdit = hud.get_node("SpellbookPanel/MarginContainer/VBoxContainer/TitleEdit")
	var formula_edit: LineEdit = hud.get_node("SpellbookPanel/MarginContainer/VBoxContainer/IncantationEdit")
	var diagram_button: OptionButton = hud.get_node("SpellbookPanel/MarginContainer/VBoxContainer/EffectOptionButton")
	var notes_edit: TextEdit = hud.get_node("SpellbookPanel/MarginContainer/VBoxContainer/NotesEdit")
	title_edit.text = "Starter Spark"
	hud._on_spellbook_title_changed(title_edit.text)
	formula_edit.text = "RAK"
	hud._on_spellbook_formula_changed(formula_edit.text)
	diagram_button.select(1)
	hud._on_spellbook_diagram_selected(1)
	notes_edit.text = "The simplest ignition mark."
	hud._on_spellbook_notes_text_changed()
	await process_frame
	var selected_page: Dictionary = spellbook_system.get_selected_formula_page()
	_assert(selected_page.get("title", "") == "Starter Spark", "Formula page stores title")
	_assert(selected_page.get("token_sequence", []) == ["RAK"], "Formula page stores token sequence")
	_assert(selected_page.get("preferred_diagram", "") == "circle", "Formula page stores preferred diagram")
	_assert(hud.get_node("SpellbookPanel/MarginContainer/VBoxContainer/FormulaPredictionLabel").text.contains("Spark"), "Formula page shows predicted outcome")
	input_controller._toggle_spellbook_panel()
	await process_frame

	spell_manager.submit_typed_incantation("RAK", "RAK")
	await process_frame
	_assert(active_spells.get_child_count() == 1 and active_spells.get_child(0).name == "SparkEffect", "Known single-word incantation casts Spark")
	for child in active_spells.get_children():
		child.queue_free()
	await process_frame

	var tor_pickup: Node3D = _find_pickup_by_lexeme(pickups, "TOR")
	player.global_position = tor_pickup.global_position + Vector3(0.0, 0.75, 0.0)
	input_controller._pickup_nearest_item()
	await process_frame
	_assert(spellbook_system.has_discovered_lexeme("TOR"), "Picking up research note discovers TOR")
	var fireball_preview: Dictionary = spell_manager.preview_incantation("RAK TOR", "RAK TOR")
	_assert(str(fireball_preview.get("spell_id", "")) == "fireball", "RAK TOR resolves to Fireball")

	spellbook_system.discover_lexeme("SEV", "acceptance")
	spellbook_system.discover_lexeme("KAR", "acceptance")
	await process_frame
	var self_push_preview: Dictionary = spell_manager.preview_incantation("TOR SEV", "TOR SEV")
	_assert(str(self_push_preview.get("spell_id", "")) == "self_push", "TOR SEV resolves to self push")
	var player_velocity_before_push: Vector3 = player.velocity
	spell_manager.submit_typed_incantation("TOR SEV", "TOR SEV")
	await process_frame
	_assert(player.velocity.length() > player_velocity_before_push.length(), "Self push changes player velocity")
	for child in active_spells.get_children():
		child.queue_free()
	await process_frame

	var target_dummy: StaticBody3D = target_dummies.get_child(0)
	var dummy_position_before_push: Vector3 = target_dummy.global_position
	player.global_position = Vector3(dummy_position_before_push.x, player.global_position.y, dummy_position_before_push.z + 3.5)
	spell_manager.submit_typed_incantation("TOR KAR", "TOR KAR")
	await process_frame
	var target_push_feedback := false
	for child in active_spells.get_children():
		if child.name == "ImpactBurst":
			target_push_feedback = true
			break
	_assert(target_dummy.global_position.distance_to(dummy_position_before_push) > 0.05 or target_push_feedback, "Target push resolves against a nearby target")
	for child in active_spells.get_children():
		child.queue_free()
	await process_frame

	var dum_pickup: Node3D = _find_pickup_by_lexeme(pickups, "DUM")
	player.global_position = dum_pickup.global_position + Vector3(0.0, 0.75, 0.0)
	input_controller._pickup_nearest_item()
	await process_frame
	_assert(spellbook_system.has_discovered_lexeme("DUM"), "Picking up research note discovers DUM")
	var unstable_preview: Dictionary = spell_manager.preview_incantation("RAK TOR DUM", "RAK TOR DUM")
	_assert(float(unstable_preview.get("stability", 0.0)) < float(fireball_preview.get("stability", 1.0)), "Contradictory phrase lowers stability")

	spell_manager.submit_typed_incantation("RAK TOR", "RAK TOR")
	await process_frame
	_assert(active_spells.get_child_count() >= 1 and active_spells.get_child(0).name == "Fireball", "Known two-word incantation casts Fireball")
	active_spells.get_child(0).queue_free()
	await process_frame
	spell_manager.submit_typed_incantation("RAK DUM", "RAK DUM")
	await process_frame
	_assert(active_spells.get_child_count() >= 1 and active_spells.get_child(0).name == "Bonfire", "Known sustain incantation casts Bonfire")
	active_spells.get_child(0).queue_free()
	await process_frame

	input_controller._toggle_voice_mode()
	await process_frame
	_assert(hud.get_node("MarginContainer/VBoxContainer/MicStatusLabel").text.contains("Listening") or hud.get_node("MarginContainer/VBoxContainer/MicStatusLabel").text.contains("Armed"), "Voice mode arms recognizer")
	voice_incantation_recognizer.simulate_partial("rak tor", "RAK TOR")
	await process_frame
	_assert(hud.get_node("MarginContainer/VBoxContainer/LiveTranscriptLabel").text.contains("RAK"), "Live partial transcript appears while speaking")
	_assert(hud.get_node("MarginContainer/VBoxContainer/LivePredictionLabel").text.contains("Fireball"), "Live voice prediction updates during partial transcript")
	voice_incantation_recognizer.simulate_recognition("rak tor", "RAK TOR", 0.88)
	await process_frame
	_assert(hud.get_node("MarginContainer/VBoxContainer/LastVoiceLabel").text.contains("RAK TOR"), "Final voice transcript persists after recognition")
	_assert(hud.get_node("MarginContainer/VBoxContainer/LiveTranscriptLabel").text.contains("-"), "Live transcript clears after recognition")
	for child in active_spells.get_children():
		child.queue_free()
	await process_frame
	input_controller._toggle_voice_mode()
	await process_frame

	var pickup_inventory_before: int = int(inventory_system.get_items().get("Kindling", 0))
	var kindling_pickup: Node3D = _find_item_pickup(pickups, "Kindling")
	player.global_position = kindling_pickup.global_position + Vector3(0.0, 0.75, 0.0)
	input_controller._pickup_nearest_item()
	await process_frame
	_assert(int(inventory_system.get_items().get("Kindling", 0)) > pickup_inventory_before, "Item pickup adds to inventory")
	input_controller._toggle_inventory_panel()
	await process_frame
	while inventory_system.get_selected_item_name() != "Kindling":
		inventory_system.select_next_item()
	energy_system.mana = 60.0
	var mana_before_kindling: float = player.get_mana()
	input_controller._use_selected_inventory_item()
	await process_frame
	_assert(player.get_mana() > mana_before_kindling, "Using kindling restores mana")
	while inventory_system.get_selected_item_name() != "Blank Page":
		inventory_system.select_next_item()
	var dropped_pickups_before: int = pickups.get_child_count()
	input_controller._drop_selected_inventory_item()
	await process_frame
	_assert(pickups.get_child_count() == dropped_pickups_before + 1, "Dropping item spawns pickup in world")
	input_controller._toggle_inventory_panel()
	await process_frame

	_assert(wood_piles.get_child_count() >= 1, "Wood piles exist")
	var wood_before: float = wood_piles.get_child(0).fuel_amount
	var bonfire_scene: PackedScene = load("res://scenes/effects/Bonfire.tscn")
	var bonfire_near: Node3D = bonfire_scene.instantiate()
	active_spells.add_child(bonfire_near)
	bonfire_near.global_position = wood_piles.get_child(0).global_position + Vector3(1.0, 0.0, 0.0)
	for _index in range(6):
		bonfire_near._process(1.0)
	_assert(is_instance_valid(bonfire_near), "Bonfire near wood stays alive")
	_assert(wood_piles.get_child(0).fuel_amount < wood_before, "Bonfire consumes wood")
	bonfire_near.queue_free()
	await process_frame

	var hostile_enemy: CharacterBody3D = hostiles.get_child(0)
	var hostile_start_distance: float = hostile_enemy.global_position.distance_to(player.global_position)
	for _index in range(20):
		hostile_enemy._physics_process(0.1)
	var hostile_end_distance: float = hostile_enemy.global_position.distance_to(player.global_position)
	_assert(hostile_end_distance < hostile_start_distance, "Hostile enemy moves toward player")

	main.reset_encounter()
	await process_frame
	await process_frame
	var refreshed_hostile: CharacterBody3D = hostiles.get_child(0)
	player.restore_to_full()
	var player_health_before_hit: float = player.get_health()
	refreshed_hostile.force_attack_player()
	await process_frame
	_assert(player.get_health() < player_health_before_hit, "Hostile enemy damages player on contact")

	var voice_before: float = voice_power_tracker.get_voice_power()
	Input.action_press("voice_charge")
	voice_power_tracker._process(1.5)
	Input.action_release("voice_charge")
	voice_power_tracker._process(0.1)
	_assert(voice_power_tracker.get_voice_power() > voice_before, "Holding V increases voice power")

	var draw_start := InputEventMouseButton.new()
	draw_start.button_index = MOUSE_BUTTON_RIGHT
	draw_start.pressed = true
	draw_start.position = Vector2.ZERO
	diagram_recognizer._input(draw_start)
	for point in [Vector2(50, 0), Vector2(25, 45), Vector2(0, 0)]:
		var move_event := InputEventMouseMotion.new()
		move_event.position = point
		diagram_recognizer._input(move_event)
	var draw_end := InputEventMouseButton.new()
	draw_end.button_index = MOUSE_BUTTON_RIGHT
	draw_end.pressed = false
	draw_end.position = Vector2.ZERO
	diagram_recognizer._input(draw_end)
	_assert(str(diagram_recognizer.get_diagram_result().get("shape_type", "")) == "triangle", "Triangle diagram is still detected")

	print("Acceptance runner passed.")


func _find_pickup_by_lexeme(pickups: Node, lexeme_id: String) -> Node3D:
	for pickup in pickups.get_children():
		if str(pickup.get("pickup_kind")) == "lexeme" and str(pickup.get("lexeme_id")) == lexeme_id:
			return pickup
	return null


func _find_item_pickup(pickups: Node, item_name: String) -> Node3D:
	for pickup in pickups.get_children():
		if str(pickup.get("pickup_kind")) == "item" and str(pickup.get("item_name")) == item_name:
			return pickup
	return null
