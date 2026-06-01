# Combat Sandbox Guide

## Purpose

The Phase 1 prototype has progressed beyond isolated milestone checks. The current playable focus is a single-scene combat sandbox that proves:

- player-authored spell research pages,
- typed incantation flow,
- microphone voice incantation flow,
- fire spell targeting,
- direct hit and splash behavior,
- hostile chase and contact-damage pressure,
- player defeat and encounter reset,
- energy payment and health-overdraw rules,
- wood fuel interaction,
- dummy health/destruction feedback,
- debug visibility for collision troubleshooting.

## Sandbox Features

### Player

- camera-relative movement,
- mouse-orbit camera,
- HUD for health, mana, score, and combat feed,
- inventory use/drop and nearby pickups,
- typed and microphone spell entry with normalized incantations.

### Spells

- spell pages are authored by the player,
- each page stores a custom title, incantation, effect binding, and notes,
- authored incantations can map to `Spark`, `Fireball`, or `Bonfire`.

### Targets and Resources

- destructible target dummies,
- hostile ember enemies,
- visible dummy health bars and floating damage numbers,
- world pickups for page materials and fuel,
- wood piles with visible depletion,
- bonfire sustain through nearby wood fuel.

### Debugging

- `F3` toggles hitbox overlays,
- debug panel shows parsed spell and energy math,
- acceptance runner validates the sandbox headlessly.

## Manual Playtest Checklist

1. Move around the arena and confirm camera-relative control feels correct.
2. Aim with the screen reticle and verify the ground marker tracks the cursor.
3. Open the spellbook, create a page, and bind a custom incantation to a spell effect.
4. Press `M`, speak that authored incantation, and confirm it resolves to a valid spell.
5. Cast your authored fireball page into a dummy and confirm direct impact, damage feedback, and destruction.
6. Cast your authored fireball page between nearby dummies and confirm splash damage.
7. Let a hostile reach the player and confirm contact damage is applied.
8. Allow the player to be defeated and confirm the arena resets automatically.
9. Cast your authored spark page near a dummy and near a wood pile to verify spark interactions.
10. Cast your authored bonfire page near wood and far from wood to verify bonfire sustain/extinction.
11. Pick up, use, and drop items to confirm inventory-world interaction.
12. Toggle `F3` to inspect or hide collision debug overlays.

## Voice Backend Notes

- The current live microphone path is implemented through Windows `System.Speech` via `tools/recognize_incantation.ps1`.
- `scripts/input/VoiceIncantationRecognizer.gd` keeps the recognizer behind a single Godot node so a future cross-platform backend can replace it without changing the spell manager or HUD flow.

## Validation Commands

Project load:

```powershell
.\Godot_v4.6.3-stable_win64_console.exe --headless --path . --quit
```

Acceptance harness:

```powershell
.\Godot_v4.6.3-stable_win64_console.exe --headless --path . --script res://scripts/tests/AcceptanceRunner.gd
```
