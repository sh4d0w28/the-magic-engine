extends Node3D

@export var fuel_search_radius: float = 3.0
@export var fuel_consume_interval_seconds: float = 5.0
@export var no_fuel_lifetime_seconds: float = 3.0

var _fuel_timer := 0.0
var _no_fuel_timer := 0.0


func _process(delta: float) -> void:
	# Fuel logic is added in Milestone 6. The placeholder remains visible for now.
	_fuel_timer += delta
