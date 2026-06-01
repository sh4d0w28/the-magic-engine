extends RefCounted
class_name ResolvedSpellOutcome

var effect_id := ""
var target_mode := "aimed"
var power := 0.0
var cost := 0.0
var stability := 0.0
var message := ""
var warnings: Array[String] = []


func to_dictionary() -> Dictionary:
	return {
		"effect_id": effect_id,
		"target_mode": target_mode,
		"power": power,
		"cost": cost,
		"stability": stability,
		"message": message,
		"warnings": warnings.duplicate()
	}
