extends Node3D

@export var fuel_amount: float = 5.0


func _ready() -> void:
	add_to_group("wood_pile")


func has_fuel() -> bool:
	return fuel_amount > 0.0


func consume_fuel(amount: float) -> bool:
	if amount <= 0.0 or not has_fuel():
		return false

	fuel_amount = max(0.0, fuel_amount - amount)
	return true
