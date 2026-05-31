extends RefCounted

var _spell_definitions: RefCounted


func setup(spell_definitions: RefCounted) -> void:
	_spell_definitions = spell_definitions


func execute_request(request: Dictionary) -> Dictionary:
	var raw_input: String = str(request.get("raw_input", ""))
	var normalized_input: String = str(request.get("normalized_input", ""))
	if normalized_input.is_empty():
		normalized_input = _spell_definitions.normalize_incantation(raw_input)

	var spell_definition := _spell_definitions.get_spell_by_incantation(normalized_input)
	if spell_definition.is_empty():
		return {
			"success": false,
			"spell_id": "",
			"spell_name": "",
			"normalized_input": normalized_input,
			"final_power": 0.0,
			"final_cost": 0.0,
			"stability": 0.0,
			"mana_spent": 0.0,
			"health_spent": 0.0,
			"message": "Unknown incantation."
		}

	var diagram_type: String = str(request.get("diagram_type", ""))
	var diagram_accuracy: float = float(request.get("diagram_accuracy", 0.0))
	var diagram_size: float = float(request.get("diagram_size", 0.0))
	var voice_power: float = clamp(float(request.get("voice_power", 0.0)), 0.0, 1.0)

	var incantation_score := 1.0
	var stability := _calculate_stability(spell_definition, incantation_score, diagram_type, diagram_accuracy)
	var final_power := clamp(1.0 + voice_power + diagram_size, 1.0, 3.0)
	var final_cost := float(spell_definition.get("base_cost", 0.0)) * final_power

	if stability < 0.5:
		return {
			"success": false,
			"spell_id": spell_definition.get("id", ""),
			"spell_name": spell_definition.get("name", ""),
			"normalized_input": normalized_input,
			"final_power": final_power,
			"final_cost": final_cost,
			"stability": stability,
			"mana_spent": 0.0,
			"health_spent": 0.0,
			"message": "Spell stability is too low."
		}

	var caster: Node = request.get("caster")
	var payment_result := caster.get_energy_system().pay_energy_cost(final_cost)
	if not payment_result.get("success", false):
		return {
			"success": false,
			"spell_id": spell_definition.get("id", ""),
			"spell_name": spell_definition.get("name", ""),
			"normalized_input": normalized_input,
			"final_power": final_power,
			"final_cost": final_cost,
			"stability": stability,
			"mana_spent": float(payment_result.get("mana_spent", 0.0)),
			"health_spent": float(payment_result.get("health_spent", 0.0)),
			"message": str(payment_result.get("message", "Not enough energy to cast."))
		}

	return {
		"success": true,
		"spell_id": spell_definition.get("id", ""),
		"spell_name": spell_definition.get("name", ""),
		"normalized_input": normalized_input,
		"final_power": final_power,
		"final_cost": final_cost,
		"stability": stability,
		"mana_spent": float(payment_result.get("mana_spent", 0.0)),
		"health_spent": float(payment_result.get("health_spent", 0.0)),
		"message": "%s cast successfully." % spell_definition.get("name", "Spell")
	}


func _calculate_stability(spell_definition: Dictionary, incantation_score: float, diagram_type: String, diagram_accuracy: float) -> float:
	if diagram_type.is_empty() or diagram_type == "none":
		return incantation_score

	var required_diagram: String = str(spell_definition.get("diagram", ""))
	var diagram_score := diagram_accuracy
	if diagram_type != required_diagram:
		diagram_score *= 0.25

	return incantation_score * 0.7 + diagram_score * 0.3
