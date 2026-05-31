extends Node3D

@export var encounter_reset_delay_seconds: float = 1.25

var _hostile_enemy_scene := preload("res://scenes/environment/HostileEnemy.tscn")

@onready var _player: CharacterBody3D = $Player
@onready var _hud: Control = $UI/HUD
@onready var _debug_panel: PanelContainer = $UI/DebugPanel
@onready var _active_spells: Node3D = $SpellManager/ActiveSpells
@onready var _hostiles: Node3D = $World/Environment/Hostiles

var _player_spawn_transform: Transform3D
var _hostile_spawn_transforms: Array[Transform3D] = []
var _reset_timer := -1.0


func _ready() -> void:
	_player_spawn_transform = _player.transform
	for hostile in _hostiles.get_children():
		_hostile_spawn_transforms.append(hostile.transform)
		_connect_hostile(hostile)
	if _player.has_signal("player_defeated"):
		_player.player_defeated.connect(_on_player_defeated)


func _process(delta: float) -> void:
	if _reset_timer < 0.0:
		return

	_reset_timer -= delta
	if _reset_timer <= 0.0:
		reset_encounter()


func reset_encounter() -> void:
	_reset_timer = -1.0
	for child in _active_spells.get_children():
		child.queue_free()
	for hostile in _hostiles.get_children():
		hostile.queue_free()

	if _hud.has_method("is_input_open") and _hud.is_input_open():
		_hud.close_input()

	_player.reset_to_transform(_player_spawn_transform)
	_player.restore_to_full()
	_respawn_hostiles()
	_hud.set_status("Encounter reset. Press Enter to type an incantation.")
	_hud.set_combat_feed("Arena reset.")
	_debug_panel.set_message("Encounter reset after player defeat.")


func _on_player_defeated() -> void:
	if _reset_timer >= 0.0:
		return

	_reset_timer = encounter_reset_delay_seconds
	_hud.set_status("You were defeated. Resetting encounter...")
	_hud.set_combat_feed("Player defeated. Arena reset incoming.")
	_debug_panel.set_message("Player health reached zero.")


func _respawn_hostiles() -> void:
	for spawn_transform in _hostile_spawn_transforms:
		var hostile = _hostile_enemy_scene.instantiate()
		_hostiles.add_child(hostile)
		hostile.transform = spawn_transform
		_connect_hostile(hostile)


func _connect_hostile(hostile: Node) -> void:
	if hostile.has_signal("player_contact_damage") and not hostile.player_contact_damage.is_connected(_on_player_contact_damage):
		hostile.player_contact_damage.connect(_on_player_contact_damage)


func _on_player_contact_damage(amount: float) -> void:
	_hud.set_combat_feed("Hostile hit player for %.0f" % amount)
