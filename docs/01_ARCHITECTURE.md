# Architecture Notes

## Main architectural rule

Separate calculation from visuals.

MagicEngine calculates what should happen. SpellManager spawns visible effects.

This makes future multiplayer easier because the server can reuse MagicEngine logic, while clients only render effects.

## Component flow

```text
InputController
  -> SpellManager
    -> MagicEngine
      -> SpellDefinitions
      -> EnergySystem
    -> spawn visual effect
    -> HUD / DebugPanel
```

## Why this separation matters

If spell logic is placed inside Fireball.gd or Bonfire.gd, future server validation becomes difficult.

Correct design:
- spell request is validated first,
- energy is consumed first,
- then visual effect is spawned.

## Recommended Godot autoloads

Avoid autoloads in Phase 1 unless necessary.

Allowed:
- DebugLogger as autoload later.

Not allowed in Phase 1:
- global magic state,
- global player singleton,
- hidden service locator.

Use exported NodePath references or scene wiring.
