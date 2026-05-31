# Magic Engine - Master Technical Design Document

## 1. Project Vision

This game prototype tests a "magic engine": a simulation layer where magical effects are produced by rules, not by hard-coded skill buttons.

The core idea is simple:

> Magic cannot create energy from nothing. Magic can only transform, move, store, shape, or release energy.

The first prototype is intentionally small. The world is a flat 3D plane. The player is a cube. The only magical energy type is fire. The player can cast up to three spells. The goal is not to create a finished game, but to prove the core feeling of rule-based magic.

The player should feel like they are operating a magical language, not clicking a normal RPG ability button.

## 2. Product Goals

The prototype must answer these questions:

1. Does a rule-based magic system feel interesting when the player uses incantations?
2. Does energy conservation make spells feel more believable?
3. Does health-drain overdrawing create meaningful risk?
4. Does environmental fuel make persistent fire effects understandable?
5. Can diagrams and voice power make spell casting feel expressive?

## 3. Non-Goals for Phase 1

Phase 1 must not attempt to implement:
- MMO networking,
- real account system,
- procedural magic language,
- large world,
- combat balancing,
- many elements,
- inventory,
- crafting,
- persistence,
- advanced microphone recognition,
- realistic fire simulation.

These are future features. The first phase must stay small and debuggable.

## 4. Technology Decision

Use Godot 4 with GDScript.

Reasons:
- simple 3D prototype setup,
- readable scripting language,
- fast iteration,
- low boilerplate,
- good for Codex-generated code,
- easy scene composition,
- future multiplayer support is possible.

No backend is required in Phase 1.

## 5. Core Magic Laws

### Law 1: Energy cannot be created

A spell cannot create fire, motion, or heat for free. It must consume energy from somewhere.

### Law 2: Mana is stored transformable energy

Mana is not "free magic." It is a battery. Spells spend mana to produce effects.

### Law 3: Health can be used as emergency energy

If mana is insufficient, the spell may draw missing energy from health. In Phase 1, health cannot be reduced below 1 by spell casting. If the spell would reduce health below 1, the spell fails and produces a simple backlash visual.

### Law 4: Persistent effects need sustaining fuel

A fire effect that lasts over time needs a fuel source. For Phase 1, bonfires need wood. If a bonfire has no nearby wood, it goes out after a short grace period.

### Law 5: Language defines intent

Incantation words define what the caster wants the magic engine to do.

For Phase 1:
- RAK = Fire
- TOR = Project / Move
- DUM = Hold / Stay

### Law 6: Geometry shapes behavior

Diagrams are not decoration. They modify spell behavior:
- circle = contain / ignite,
- triangle = project / direct,
- circle with dot = hold / sustain.

### Law 7: Stronger input costs more

Longer voice casting or larger diagrams increase spell power. Higher power increases energy cost.

## 6. Phase 1 Gameplay Loop

1. Player moves around as a cube.
2. Player chooses target direction or target position.
3. Player enters an incantation.
4. Optional: player holds voice-power key to increase power.
5. Optional: player draws a diagram.
6. Magic engine parses input.
7. Magic engine calculates spell stability.
8. Magic engine calculates energy cost.
9. Energy system spends mana and possibly health.
10. Spell effect appears if successful.
11. Debug HUD shows all calculations.

## 7. World Design

The world contains:
- one flat plane,
- one cube player,
- several wood piles,
- simple light,
- simple camera,
- spell effects container,
- HUD,
- debug panel.

The initial scene should be small and clear. No terrain, no enemies, no NPCs.

## 8. Player Entity

The player is a cube with simple movement.

### Required fields

```text
player_id: String
health: float = 100
max_health: float = 100
mana: float = 100
max_mana: float = 100
mana_regen_per_second: float = 5
movement_speed: float = 6
```

### Required methods

```text
spend_mana(amount) -> float
drain_health(amount) -> bool
restore_mana(delta) -> void
is_alive() -> bool
get_forward_direction() -> Vector3
```

## 9. Energy System

All energy spending must go through `EnergySystem.gd`.

### Payment order

1. Spend mana.
2. If mana is insufficient, calculate missing amount.
3. Try to drain health for the missing amount.
4. If health would drop below 1, fail the cast.
5. Return exact spend result.

### Energy payment result

```text
success: bool
mana_spent: float
health_spent: float
missing_energy: float
message: String
```

### Example

Required energy: 50  
Current mana: 30  
Current health: 100  

Result:
- mana spent = 30
- health spent = 20
- success = true

## 10. Magic Language

The first version uses exact phrase matching.

### Vocabulary

| Word | Meaning |
|---|---|
| RAK | Fire |
| TOR | Project / Move |
| DUM | Hold / Stay |

### Valid Phase 1 phrases

| Incantation | Spell |
|---|---|
| RAK | Spark |
| RAK TOR | Fireball |
| RAK DUM | Bonfire |

### Parser rules

- Trim whitespace.
- Convert to uppercase.
- Collapse multiple spaces.
- Match exact phrases.
- Unknown phrase returns failure.

## 11. Diagram System

Drawing is optional at first but required as a planned module.

### Supported shapes

| Shape | Meaning | Spell |
|---|---|---|
| Circle | Contain / ignite | Spark |
| Triangle | Project | Fireball |
| Circle with dot | Sustain | Bonfire |

### Diagram result model

```text
shape_type: String
accuracy: float
size: float
point_count: int
```

### Simplified classification logic

1. Store drawn points.
2. Calculate bounding box.
3. Calculate normalized size.
4. Estimate whether path is closed.
5. Estimate corner count.
6. Classify:
   - closed, low corner count, rounded path -> circle,
   - closed, about 3 corners -> triangle,
   - circle plus central dot/click -> circle_with_dot.

Codex should implement simple heuristics first. Do not implement complex ML-based recognition.

## 12. Voice Power System

Real speech recognition is deferred.

Phase 1 implements voice power simulation:
- hold `V` to charge voice power,
- power grows from 0 to 1 over 3 seconds,
- release or cast uses current voice power,
- this value scales spell power and cost.

### Formula

```text
voice_power = clamp(held_seconds / 3.0, 0.0, 1.0)
```

Future versions may add:
- microphone volume,
- pitch,
- speech-to-text,
- pronunciation accuracy.

## 13. Spell Power and Cost

### Final power

```text
final_power = 1.0 + voice_power + diagram_size
final_power = clamp(final_power, 1.0, 3.0)
```

### Final cost

```text
final_cost = base_cost * final_power
```

### Stability

```text
stability = incantation_score * 0.7 + diagram_score * 0.3
```

If no diagram is provided:

```text
stability = incantation_score
```

### Success threshold

```text
stability >= 0.5
```

## 14. Spell Definitions

### Spell 1: Spark

Purpose: basic ignition test.

```text
id: spark
name: Spark
incantation: RAK
diagram: circle
base_cost: 5
duration: 1 second
```

Effect:
- spawn small orange sphere at target,
- remove after 1 second,
- does not need fuel.

### Spell 2: Fireball

Purpose: projectile test.

```text
id: fireball
name: Fireball
incantation: RAK TOR
diagram: triangle
base_cost: 25
speed: 12
range: 20
```

Effect:
- spawn orange sphere in front of player,
- move forward,
- disappear after range or collision,
- no damage required in Phase 1.

### Spell 3: Bonfire

Purpose: fuel and persistence test.

```text
id: bonfire
name: Bonfire
incantation: RAK DUM
diagram: circle_with_dot
base_cost: 15
fuel_search_radius: 3
fuel_consume_interval: 5 seconds
no_fuel_lifetime: 3 seconds
```

Effect:
- spawn bonfire at target,
- consume nearby wood fuel,
- if no fuel, disappear after 3 seconds.

## 15. Spell Request Model

Use a dictionary or typed GDScript class.

```gdscript
var request = {
    "caster": player,
    "raw_input": "RAK TOR",
    "input_type": "typed",
    "voice_power": 0.5,
    "diagram_type": "triangle",
    "diagram_accuracy": 0.8,
    "diagram_size": 0.6,
    "target_position": target_position
}
```

## 16. Spell Result Model

```gdscript
var result = {
    "success": true,
    "spell_id": "fireball",
    "spell_name": "Fireball",
    "final_power": 2.1,
    "final_cost": 52.5,
    "stability": 0.94,
    "mana_spent": 40.0,
    "health_spent": 12.5,
    "message": "Fireball cast successfully."
}
```

## 17. Godot Scene Tree

Recommended root:

```text
Main.tscn
  Main (Node3D)
    World (Node3D)
      Ground (StaticBody3D)
      Environment (Node3D)
        WoodPiles (Node3D)
    Player (CharacterBody3D)
      MeshInstance3D
      CollisionShape3D
      CameraPivot (Node3D)
        Camera3D
    SpellManager (Node)
      ActiveSpells (Node3D)
    InputController (Node)
    UI (CanvasLayer)
      HUD
      DebugPanel
```

## 18. Folder Structure

```text
res://
  scenes/
    Main.tscn
    Player.tscn
    effects/
      SparkEffect.tscn
      Fireball.tscn
      Bonfire.tscn
      BacklashEffect.tscn
    environment/
      WoodPile.tscn
    ui/
      HUD.tscn
  scripts/
    player/
      PlayerController.gd
      EnergySystem.gd
    magic/
      MagicEngine.gd
      SpellDefinitions.gd
      SpellManager.gd
      SpellRequest.gd
      SpellResult.gd
    input/
      InputController.gd
      VoicePowerTracker.gd
      DiagramRecognizer.gd
    effects/
      SparkEffect.gd
      Fireball.gd
      Bonfire.gd
      BacklashEffect.gd
    environment/
      WoodPile.gd
    ui/
      HUD.gd
      DebugPanel.gd
  data/
    spells.json
  debug/
    DebugLogger.gd
```

## 19. Module Responsibilities

### PlayerController.gd

Handles:
- WASD movement,
- facing direction,
- camera follow,
- forwarding cast target.

Must not contain spell logic.

### EnergySystem.gd

Handles:
- health,
- mana,
- regeneration,
- spend mana,
- drain health,
- return energy payment result.

### MagicEngine.gd

Handles:
- parse incantation,
- find spell definition,
- calculate stability,
- calculate final power,
- calculate cost,
- ask EnergySystem to pay,
- return SpellResult.

MagicEngine must not spawn visual effects.

### SpellManager.gd

Handles:
- receive SpellResult,
- spawn Spark, Fireball, Bonfire, Backlash,
- update HUD/debug output.

### InputController.gd

Handles:
- typed incantation input,
- cast trigger,
- passing request to SpellManager.

### VoicePowerTracker.gd

Handles:
- V key hold time,
- normalized voice power.

### DiagramRecognizer.gd

Handles:
- drawing points,
- shape classification,
- size calculation.

### HUD.gd

Handles:
- health/mana display,
- input text,
- last spell message.

### DebugPanel.gd

Shows:
- raw input,
- parsed spell,
- stability,
- final power,
- final cost,
- mana spent,
- health spent.

## 20. Coding Standards for Codex

Codex must follow these rules:

1. Implement one milestone at a time.
2. Do not create unnecessary abstractions.
3. Use small scripts.
4. Use descriptive variable names.
5. Keep all calculations explicit.
6. Avoid global mutable state.
7. Do not implement future MMO features in Phase 1.
8. Every spell cast must be debuggable.
9. Prefer dictionaries for simple request/result models unless typed classes are clearer.
10. When changing an existing file, explain exactly what changed.

## 21. Milestone Plan

### Milestone 1 - Basic 3D World

Deliver:
- Main scene,
- flat ground,
- cube player,
- WASD movement,
- camera,
- basic HUD shell.

Acceptance:
- player moves on plane,
- camera follows,
- no spell system yet.

### Milestone 2 - Energy System

Deliver:
- EnergySystem,
- health/mana values,
- mana regeneration,
- HUD updates.

Acceptance:
- mana regenerates,
- health/mana visible,
- debug print works.

### Milestone 3 - Typed Incantation Input

Deliver:
- input box or simple text input mode,
- submit phrase to SpellManager,
- normalize text.

Acceptance:
- Enter opens input,
- player types RAK / RAK TOR / RAK DUM,
- submitted phrase appears in debug panel.

### Milestone 4 - Magic Engine Core

Deliver:
- SpellDefinitions,
- MagicEngine,
- SpellRequest,
- SpellResult,
- cost calculation,
- mana/health payment.

Acceptance:
- valid phrase creates success result,
- invalid phrase fails,
- insufficient mana drains health,
- insufficient health fails.

### Milestone 5 - Spell Effects

Deliver:
- Spark visual,
- Fireball projectile,
- Bonfire placeholder.

Acceptance:
- RAK spawns spark,
- RAK TOR launches projectile,
- RAK DUM spawns bonfire.

### Milestone 6 - Wood Fuel

Deliver:
- WoodPile entity,
- Bonfire searches fuel,
- fuel consumption over time,
- no-fuel extinction.

Acceptance:
- bonfire near wood continues,
- bonfire away from wood dies after 3 seconds,
- wood fuel amount decreases.

### Milestone 7 - Voice Power Simulation

Deliver:
- hold V to charge,
- voice_power from 0 to 1,
- cost and power scale.

Acceptance:
- holding V longer increases final_power,
- higher final_power increases cost.

### Milestone 8 - Diagram Prototype

Deliver:
- mouse drawing,
- classify circle/triangle/circle-with-dot,
- diagram_size and accuracy,
- stability modifier.

Acceptance:
- triangle improves Fireball stability,
- circle improves Spark stability,
- wrong diagram lowers stability.

## 22. Test Cases

### Parser tests

```text
"rak" -> RAK -> Spark
" RAK   TOR " -> RAK TOR -> Fireball
"rak dum" -> RAK DUM -> Bonfire
"RAK XYZ" -> unknown
```

### Energy tests

```text
mana=100, cost=25 -> mana=75, health unchanged
mana=10, cost=25 -> mana=0, health -= 15
mana=0, health=10, cost=25 -> fail, health remains 10 or minimum 1
```

### Bonfire tests

```text
Bonfire with nearby wood -> consumes fuel and remains
Bonfire without wood -> expires after 3 seconds
Wood fuel reaches 0 -> bonfire expires after grace period
```

## 23. Future MMO Direction

The prototype should be written so future networking is possible, but networking must not be implemented now.

Future architecture:
- Godot client,
- Go authoritative simulation server,
- PostgreSQL for accounts and discoveries,
- Redis/KeyDB for active world state,
- server validates all spell casts,
- client sends spell requests,
- server returns spell results,
- anti-cheat through server-side energy validation.

## 24. Future Research Gameplay

Later, players should not be given all spell recipes. They discover language meanings by experimentation.

Possible future mechanics:
- procedural language per server,
- ruins with partial inscriptions,
- research notebooks,
- guild-shared discoveries,
- magical patents,
- public spell libraries.

## 25. Future Infrastructure Magic

Later, magic should support:
- mana generators,
- fire-powered furnaces,
- waterwheel-to-mana converters,
- mana crystals,
- defensive barriers,
- city shields,
- magical logistics.

## 26. Final Instruction to Codex

Do not build everything at once.

Start with Milestone 1. After Milestone 1 works, continue to Milestone 2. Keep code readable, explicit, and easy for a human developer to understand.
