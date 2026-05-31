extends Node

@onready var _hud: Control = $"../UI/HUD"
@onready var _debug_panel: PanelContainer = $"../UI/DebugPanel"
@onready var _spell_manager: Node = $"../SpellManager"
@onready var _voice_power_tracker: Node = $VoicePowerTracker
@onready var _diagram_recognizer: Node = $DiagramRecognizer


func _ready() -> void:
	_hud.input_submitted.connect(_on_input_submitted)
	_voice_power_tracker.voice_power_changed.connect(_on_voice_power_changed)
	_diagram_recognizer.diagram_changed.connect(_on_diagram_changed)
	get_tree().set_meta("show_debug_hitboxes", false)
	call_deferred("_initialize_ui_state")


func _initialize_ui_state() -> void:
	_hud.set_status("Press Enter to type an incantation.")
	_debug_panel.set_message("Waiting for typed input.")
	_on_voice_power_changed(_voice_power_tracker.get_voice_power())
	_on_diagram_changed(_diagram_recognizer.get_diagram_result())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER and not _hud.is_input_open():
			_hud.open_input()
			_hud.set_status("Typing incantation...")
			_debug_panel.set_message("Input mode opened.")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and _hud.is_input_open():
			_hud.close_input()
			_hud.set_status("Input cancelled.")
			_debug_panel.set_message("Input cancelled.")
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("toggle_debug_hitboxes"):
			_toggle_debug_hitboxes()
			get_viewport().set_input_as_handled()


func normalize_input(raw_input: String) -> String:
	var words := raw_input.strip_edges().to_upper().split(" ", false)
	return " ".join(words)


func _on_input_submitted(raw_input: String) -> void:
	var normalized_input := normalize_input(raw_input)
	_hud.close_input()
	_debug_panel.set_submitted_input(raw_input, normalized_input)
	if normalized_input.is_empty():
		_hud.set_status("No incantation submitted.")
		_debug_panel.set_message("Submission was empty.")
		return

	_hud.set_status("Submitted: %s" % normalized_input)
	_debug_panel.set_message("Normalized typed input submitted.")
	if _spell_manager.has_method("submit_typed_incantation"):
		_spell_manager.submit_typed_incantation(raw_input, normalized_input)


func _on_voice_power_changed(voice_power: float) -> void:
	_hud.set_voice_power(voice_power)
	_debug_panel.set_voice_power(voice_power)


func _on_diagram_changed(diagram_result: Dictionary) -> void:
	_debug_panel.set_diagram_result(diagram_result)


func _toggle_debug_hitboxes() -> void:
	var show_debug_hitboxes: bool = not bool(get_tree().get_meta("show_debug_hitboxes", false))
	get_tree().set_meta("show_debug_hitboxes", show_debug_hitboxes)
	for node in get_tree().get_nodes_in_group("debug_hitbox_owner"):
		if node.has_method("set_debug_hitbox_visible"):
			node.set_debug_hitbox_visible(show_debug_hitboxes)
	_hud.set_status("Debug hitboxes: %s" % ("On" if show_debug_hitboxes else "Off"))
	_debug_panel.set_message("Debug hitboxes %s." % ("enabled" if show_debug_hitboxes else "disabled"))
