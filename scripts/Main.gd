extends Node3D

@export var encounter_reset_delay_seconds: float = 1.25

var _hostile_enemy_scene := preload("res://scenes/environment/HostileEnemy.tscn")
var _pickup_scene := preload("res://scenes/environment/PickupItem.tscn")

@onready var _player: CharacterBody3D = $Player
@onready var _hud: Control = $UI/HUD
@onready var _debug_panel: PanelContainer = $UI/DebugPanel
@onready var _active_spells: Node3D = $SpellManager/ActiveSpells
@onready var _hostiles: Node3D = $World/Environment/Hostiles
@onready var _pickups: Node3D = $World/Environment/Pickups

var _player_spawn_position := Vector3.ZERO
var _player_spawn_basis := Basis.IDENTITY
var _hostile_spawn_transforms: Array[Transform3D] = []
var _pickup_spawn_data: Array[Dictionary] = []
var _reset_timer := -1.0


func _ready() -> void:
	_player_spawn_position = _player.global_position
	_player_spawn_basis = _player.global_basis
	for hostile in _hostiles.get_children():
		_hostile_spawn_transforms.append(hostile.transform)
		_connect_hostile(hostile)
	for pickup in _pickups.get_children():
		_pickup_spawn_data.append({
			"transform": pickup.transform,
			"pickup_kind": str(pickup.get("pickup_kind")),
			"item_name": str(pickup.get("item_name")),
			"amount": int(pickup.get("amount")),
			"lexeme_id": str(pickup.get("lexeme_id")),
			"source_note": str(pickup.get("source_note"))
		})
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
	for pickup in _pickups.get_children():
		pickup.queue_free()

	if _hud.has_method("is_input_open") and _hud.is_input_open():
		_hud.close_input()

	_player.reset_to_transform(Transform3D(_player_spawn_basis, _player_spawn_position))
	_player.restore_to_full()
	_player.set_physics_interpolation_mode(Node.PHYSICS_INTERPOLATION_MODE_OFF)
	_respawn_hostiles()
	_respawn_pickups()
	_hud.set_status("Encounter reset. Press Enter to type an incantation.")
	_hud.set_combat_feed("Arena reset.")
	_debug_panel.set_message("Encounter reset after player defeat.")
	_player.call_deferred("set_physics_interpolation_mode", Node.PHYSICS_INTERPOLATION_MODE_INHERIT)


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


func _respawn_pickups() -> void:
	for pickup_data in _pickup_spawn_data:
		var pickup = _pickup_scene.instantiate()
		_pickups.add_child(pickup)
		pickup.transform = pickup_data.get("transform", Transform3D.IDENTITY)
		if str(pickup_data.get("pickup_kind", "item")) == "lexeme":
			pickup.configure_lexeme_pickup(str(pickup_data.get("lexeme_id", "")), str(pickup_data.get("source_note", "")))
		else:
			pickup.configure_item_pickup(str(pickup_data.get("item_name", "")), int(pickup_data.get("amount", 1)))


func _on_player_contact_damage(amount: float) -> void:
	_hud.set_combat_feed("Hostile hit player for %.0f" % amount)
