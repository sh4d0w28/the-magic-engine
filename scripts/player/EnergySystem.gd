extends Node
class_name EnergySystem

signal changed(health: float, mana: float)

@export var health: float = 100.0
@export var max_health: float = 100.0
@export var mana: float = 100.0
@export var max_mana: float = 100.0
@export var mana_regen_per_second: float = 5.0


func _ready() -> void:
	health = clamp(health, 1.0, max_health)
	mana = clamp(mana, 0.0, max_mana)
	_emit_changed()


func _process(delta: float) -> void:
	if mana >= max_mana:
		return

	mana = min(max_mana, mana + mana_regen_per_second * delta)
	_emit_changed()


func spend_mana(amount: float) -> float:
	var mana_spent: float = minf(mana, maxf(amount, 0.0))
	mana -= mana_spent
	_emit_changed()
	return mana_spent


func drain_health(amount: float) -> bool:
	var requested_amount: float = maxf(amount, 0.0)
	if health - requested_amount < 1.0:
		return false

	health -= requested_amount
	_emit_changed()
	return true


func restore_mana(delta: float) -> void:
	mana = clamp(mana + delta, 0.0, max_mana)
	_emit_changed()


func heal(amount: float) -> void:
	health = clampf(health + maxf(amount, 0.0), 0.0, max_health)
	_emit_changed()


func apply_damage(amount: float) -> bool:
	var requested_amount: float = maxf(amount, 0.0)
	health = clampf(health - requested_amount, 0.0, max_health)
	_emit_changed()
	return is_alive()


func restore_full() -> void:
	health = max_health
	mana = max_mana
	_emit_changed()


func is_alive() -> bool:
	return health > 0.0


func pay_energy_cost(required_energy: float) -> Dictionary:
	var target_cost: float = maxf(required_energy, 0.0)
	var mana_spent: float = minf(mana, target_cost)
	var missing_energy: float = target_cost - mana_spent

	if missing_energy > 0.0 and health - missing_energy < 1.0:
		return {
			"success": false,
			"mana_spent": 0.0,
			"health_spent": 0.0,
			"missing_energy": missing_energy,
			"message": "Not enough mana or health to cast."
		}

	if mana_spent > 0.0:
		mana -= mana_spent

	var health_spent: float = 0.0
	if missing_energy > 0.0:
		health -= missing_energy
		health_spent = missing_energy

	_emit_changed()
	return {
		"success": true,
		"mana_spent": mana_spent,
		"health_spent": health_spent,
		"missing_energy": 0.0,
		"message": "Energy cost paid."
	}


func _emit_changed() -> void:
	changed.emit(health, mana)
