extends RefCounted
class_name SpellIntent

var tokens: Array[String] = []
var unknown_tokens: Array[String] = []
var locked_tokens: Array[String] = []
var element := ""
var action := ""
var target_mode := "aimed"
var motion_mode := ""
var anchor_mode := ""
var modifiers: Array[String] = []
var diagram_bias := "none"
var stability := 1.0
var cost_multiplier := 1.0
var ambiguity_flags: Array[String] = []
var warnings: Array[String] = []


func to_dictionary() -> Dictionary:
	return {
		"tokens": tokens.duplicate(),
		"unknown_tokens": unknown_tokens.duplicate(),
		"locked_tokens": locked_tokens.duplicate(),
		"element": element,
		"action": action,
		"target_mode": target_mode,
		"motion_mode": motion_mode,
		"anchor_mode": anchor_mode,
		"modifiers": modifiers.duplicate(),
		"diagram_bias": diagram_bias,
		"stability": stability,
		"cost_multiplier": cost_multiplier,
		"ambiguity_flags": ambiguity_flags.duplicate(),
		"warnings": warnings.duplicate()
	}
