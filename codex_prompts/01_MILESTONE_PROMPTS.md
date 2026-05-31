# Codex Milestone Prompts

## Milestone 1 prompt

Implement Milestone 1 from the attached specification.

Create a Godot 4 project structure with:
- Main scene,
- flat 3D ground,
- cube player using CharacterBody3D,
- WASD movement,
- third-person camera,
- empty HUD shell.

Do not implement magic yet.

Explain all created files.

## Milestone 2 prompt

Implement Milestone 2 only.

Add EnergySystem.gd to the player with:
- health,
- max_health,
- mana,
- max_mana,
- mana_regen_per_second,
- mana regeneration in _process,
- spend_mana,
- drain_health,
- pay_energy_cost.

Update HUD to show health and mana.

Do not implement spells yet.

## Milestone 3 prompt

Implement Milestone 3 only.

Add typed incantation input:
- Enter opens input mode.
- Player types text.
- Enter submits text.
- Escape cancels input.
- Normalize input to uppercase and collapsed spaces.
- Show submitted input in DebugPanel.

Do not cast spells yet.

## Milestone 4 prompt

Implement Milestone 4 only.

Add:
- SpellDefinitions.gd,
- MagicEngine.gd,
- SpellRequest dictionary,
- SpellResult dictionary,
- support for RAK, RAK TOR, RAK DUM,
- final_power calculation,
- final_cost calculation,
- mana and health payment through EnergySystem.

Do not spawn visual spell effects yet. Only print/debug SpellResult.

## Milestone 5 prompt

Implement Milestone 5 only.

Add visual effects:
- SparkEffect: small sphere removed after 1 second.
- Fireball: orange sphere projectile moving forward.
- Bonfire: stationary orange placeholder.

SpellManager should spawn these only after MagicEngine returns success.

## Milestone 6 prompt

Implement Milestone 6 only.

Add WoodPile and bonfire fuel logic:
- WoodPile has fuel_amount.
- Bonfire checks for nearby WoodPile within 3 meters.
- Bonfire consumes 1 fuel every 5 seconds.
- If no fuel exists, bonfire disappears after 3 seconds.

## Milestone 7 prompt

Implement Milestone 7 only.

Add VoicePowerTracker:
- holding V charges voice_power from 0 to 1 over 3 seconds,
- show voice_power in DebugPanel,
- MagicEngine uses voice_power to scale final_power and final_cost.

Do not implement real microphone speech recognition yet.

## Milestone 8 prompt

Implement Milestone 8 only.

Add diagram drawing:
- hold right mouse button to draw,
- store points,
- classify circle, triangle, circle_with_dot using simple heuristics,
- calculate diagram_size,
- calculate diagram_accuracy,
- MagicEngine uses diagram result for stability and power scaling.

Keep algorithm simple and debuggable.
