extends RefCounted

const SpellIntentClass = preload("res://scripts/magic/SpellIntent.gd")
const ResolvedSpellOutcomeClass = preload("res://scripts/magic/ResolvedSpellOutcome.gd")

var _spell_definitions: RefCounted
var _lexeme_catalog := preload("res://scripts/magic/LexemeCatalog.gd").new()


func setup(spell_definitions: RefCounted) -> void:
	_spell_definitions = spell_definitions


func parse_tokens(request: Dictionary) -> RefCounted:
	var intent: RefCounted = SpellIntentClass.new()
	var raw_input: String = str(request.get("raw_input", ""))
	var normalized_input: String = str(request.get("normalized_input", ""))
	if normalized_input.is_empty():
		normalized_input = _spell_definitions.normalize_incantation(raw_input)
	for token in normalized_input.split(" ", false):
		intent.tokens.append(str(token))
	intent.diagram_bias = str(request.get("diagram_type", "none"))

	var discovered_lexeme_ids: Array[String] = request.get("discovered_lexeme_ids", [])
	var has_push_modifier := false
	var has_sustain_modifier := false

	for token in intent.tokens:
		var lexeme: Dictionary = _lexeme_catalog.get_lexeme_by_surface(token)
		if lexeme.is_empty():
			intent.unknown_tokens.append(token)
			intent.stability -= 0.18
			intent.warnings.append("Unknown token: %s" % token)
			continue

		var lexeme_id: String = str(lexeme.get("id", ""))
		if not discovered_lexeme_ids.has(lexeme_id):
			intent.locked_tokens.append(lexeme_id)
			intent.stability -= 0.25
			continue

		var semantic_tags: Dictionary = lexeme.get("semantic_tags", {})
		var next_element: String = str(semantic_tags.get("element", ""))
		if intent.element.is_empty() and not next_element.is_empty():
			intent.element = next_element

		var next_action: String = str(semantic_tags.get("action", ""))
		if intent.action.is_empty() and not next_action.is_empty():
			intent.action = next_action
		elif not next_action.is_empty() and next_action != intent.action and not intent.action.is_empty():
			intent.ambiguity_flags.append("action_conflict")
			intent.stability -= 0.2

		var next_motion_mode: String = str(semantic_tags.get("motion_mode", ""))
		if not next_motion_mode.is_empty():
			intent.motion_mode = next_motion_mode
			has_push_modifier = true

		var next_anchor_mode: String = str(semantic_tags.get("anchor_mode", ""))
		if not next_anchor_mode.is_empty():
			intent.anchor_mode = next_anchor_mode
			has_sustain_modifier = true

		var next_target_mode: String = str(semantic_tags.get("target_mode", ""))
		if not next_target_mode.is_empty():
			if intent.target_mode != "aimed" and next_target_mode != intent.target_mode:
				intent.ambiguity_flags.append("target_conflict")
				intent.stability -= 0.25
				intent.warnings.append("Conflicting target words used.")
			else:
				intent.target_mode = next_target_mode

		intent.cost_multiplier += float(lexeme.get("cost_delta", 0.0))
		intent.stability += float(lexeme.get("stability_delta", 0.0))
		intent.modifiers.append(lexeme_id)

	if intent.action == "force" and intent.target_mode.is_empty():
		intent.target_mode = "aimed"

	if has_push_modifier and has_sustain_modifier:
		intent.ambiguity_flags.append("sustain_push_mix")
		intent.stability -= 0.22
		intent.warnings.append("Sustain and push modifiers strain the spell structure.")

	intent.stability = clampf(intent.stability, 0.0, 1.0)
	return intent


func resolve_intent(intent: RefCounted, request: Dictionary) -> RefCounted:
	var outcome: RefCounted = ResolvedSpellOutcomeClass.new()
	outcome.stability = intent.stability
	outcome.target_mode = intent.target_mode
	outcome.warnings = intent.warnings.duplicate()

	if not intent.locked_tokens.is_empty():
		outcome.message = "Meaning not learned yet: %s." % ", ".join(intent.locked_tokens)
		return outcome

	if intent.action.is_empty():
		if not intent.unknown_tokens.is_empty():
			outcome.message = "No meaning found."
		else:
			outcome.message = "No resolvable action path found."
		return outcome

	if intent.action == "ignite":
		if intent.anchor_mode == "sustain":
			outcome.effect_id = "bonfire"
		elif intent.motion_mode == "push":
			outcome.effect_id = "fireball"
		else:
			outcome.effect_id = "spark"
	elif intent.action == "force":
		if intent.target_mode == "self":
			outcome.effect_id = "self_push"
		else:
			outcome.effect_id = "target_push"

	if outcome.effect_id.is_empty():
		outcome.message = "The phrase has intent, but no stable outcome yet."
		return outcome

	var spell_definition: Dictionary = _spell_definitions.get_spell_by_id(outcome.effect_id)
	var base_cost: float = float(spell_definition.get("base_cost", 0.0))
	var diagram_type: String = str(request.get("diagram_type", "none"))
	var diagram_accuracy: float = float(request.get("diagram_accuracy", 0.0))
	var diagram_size: float = float(request.get("diagram_size", 0.0))
	var voice_power: float = clampf(float(request.get("voice_power", 0.0)), 0.0, 1.0)

	outcome.stability = _apply_diagram_stability(outcome.stability, spell_definition, diagram_type, diagram_accuracy)
	outcome.power = clampf(1.0 + voice_power + diagram_size, 1.0, 3.0)
	outcome.cost = base_cost * maxf(intent.cost_multiplier, 0.25) * outcome.power

	if outcome.stability < 0.35:
		outcome.message = "Spell stability is too low."
		return outcome

	outcome.message = "%s resolved." % str(spell_definition.get("name", "Spell"))
	return outcome


func execute_request(request: Dictionary) -> Dictionary:
	var raw_input: String = str(request.get("raw_input", ""))
	var normalized_input: String = str(request.get("normalized_input", ""))
	if normalized_input.is_empty():
		normalized_input = _spell_definitions.normalize_incantation(raw_input)

	var intent: RefCounted = parse_tokens(request)
	var outcome: RefCounted = resolve_intent(intent, request)
	var result := _build_result_dictionary(normalized_input, intent, outcome)
	if outcome.effect_id.is_empty() or outcome.stability < 0.35:
		return result

	var caster: Node = request.get("caster")
	var payment_result: Dictionary = caster.get_energy_system().pay_energy_cost(outcome.cost)
	if not payment_result.get("success", false):
		result["success"] = false
		result["mana_spent"] = float(payment_result.get("mana_spent", 0.0))
		result["health_spent"] = float(payment_result.get("health_spent", 0.0))
		result["message"] = str(payment_result.get("message", "Not enough energy to cast."))
		return result

	result["success"] = true
	result["mana_spent"] = float(payment_result.get("mana_spent", 0.0))
	result["health_spent"] = float(payment_result.get("health_spent", 0.0))
	result["message"] = "%s cast successfully." % result.get("spell_name", "Spell")
	return result


func preview_request(request: Dictionary) -> Dictionary:
	var raw_input: String = str(request.get("raw_input", ""))
	var normalized_input: String = str(request.get("normalized_input", ""))
	if normalized_input.is_empty():
		normalized_input = _spell_definitions.normalize_incantation(raw_input)
	var intent: RefCounted = parse_tokens(request)
	var outcome: RefCounted = resolve_intent(intent, request)
	return _build_result_dictionary(normalized_input, intent, outcome)


func _build_result_dictionary(normalized_input: String, intent: RefCounted, outcome: RefCounted) -> Dictionary:
	var spell_definition: Dictionary = _spell_definitions.get_spell_by_id(outcome.effect_id)
	var result := {
		"success": false,
		"spell_id": outcome.effect_id,
		"spell_name": str(spell_definition.get("name", "")),
		"normalized_input": normalized_input,
		"final_power": outcome.power,
		"final_cost": outcome.cost,
		"stability": outcome.stability,
		"mana_spent": 0.0,
		"health_spent": 0.0,
		"message": outcome.message,
		"warnings": outcome.warnings.duplicate(),
		"tokens": intent.tokens.duplicate(),
		"unknown_tokens": intent.unknown_tokens.duplicate(),
		"locked_tokens": intent.locked_tokens.duplicate(),
		"ambiguity_flags": intent.ambiguity_flags.duplicate(),
		"target_mode": outcome.target_mode,
		"intent": intent.to_dictionary()
	}
	if spell_definition.is_empty():
		return result
	result["spell_name"] = str(spell_definition.get("name", ""))
	return result


func _apply_diagram_stability(current_stability: float, spell_definition: Dictionary, diagram_type: String, diagram_accuracy: float) -> float:
	if diagram_type.is_empty() or diagram_type == "none":
		return current_stability

	var required_diagram: String = str(spell_definition.get("diagram", ""))
	if required_diagram.is_empty():
		return current_stability

	var diagram_score := diagram_accuracy
	if diagram_type != required_diagram:
		diagram_score *= 0.25
	return clampf(current_stability * 0.7 + diagram_score * 0.3, 0.0, 1.0)
