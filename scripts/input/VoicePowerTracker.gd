extends Node
class_name VoicePowerTracker

signal voice_power_changed(voice_power: float)

var _held_seconds := 0.0
var _voice_power := 0.0
var _is_charging := false


func _process(delta: float) -> void:
	if Input.is_action_pressed("voice_charge"):
		_is_charging = true
		_held_seconds = min(_held_seconds + delta, 3.0)
		_set_voice_power(clampf(_held_seconds / 3.0, 0.0, 1.0))
	elif _is_charging:
		_is_charging = false
		_held_seconds = 0.0


func get_voice_power() -> float:
	return _voice_power


func is_charging() -> bool:
	return _is_charging


func consume_voice_power() -> float:
	var current_voice_power := _voice_power
	reset()
	return current_voice_power


func reset() -> void:
	_is_charging = false
	_held_seconds = 0.0
	_set_voice_power(0.0)


func _set_voice_power(value: float) -> void:
	if is_equal_approx(_voice_power, value):
		return

	_voice_power = value
	voice_power_changed.emit(_voice_power)
