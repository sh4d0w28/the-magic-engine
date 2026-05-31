extends Node

@onready var _hud: Control = $"../UI/HUD"
@onready var _debug_panel: PanelContainer = $"../UI/DebugPanel"
@onready var _spell_manager: Node = $"../SpellManager"


func _ready() -> void:
	_hud.input_submitted.connect(_on_input_submitted)
	_hud.set_status("Press Enter to type an incantation.")
	_debug_panel.set_message("Waiting for typed input.")


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
