# Combat Sandbox Guide

## Purpose

The Phase 1 prototype has progressed beyond isolated milestone checks. The current playable focus is a single-scene combat sandbox that proves:

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
- typed and microphone spell entry with normalized incantations.

### Spells

- `RAK` -> Spark
- `RAK TOR` -> Fireball
- `RAK DUM` -> Bonfire

### Targets and Resources

- destructible target dummies,
- hostile ember enemies,
- visible dummy health bars and floating damage numbers,
- wood piles with visible depletion,
- bonfire sustain through nearby wood fuel.

### Debugging

- `F3` toggles hitbox overlays,
- debug panel shows parsed spell and energy math,
- acceptance runner validates the sandbox headlessly.

## Manual Playtest Checklist

1. Move around the arena and confirm camera-relative control feels correct.
2. Aim with the screen reticle and verify the ground marker tracks the cursor.
3. Press `M`, speak a fire incantation, and confirm it resolves to a valid spell.
4. Cast `RAK TOR` into a dummy and confirm direct impact, damage feedback, and destruction.
5. Cast `RAK TOR` between nearby dummies and confirm splash damage.
6. Let a hostile reach the player and confirm contact damage is applied.
7. Allow the player to be defeated and confirm the arena resets automatically.
8. Cast `RAK` near a dummy and near a wood pile to verify spark interactions.
9. Cast `RAK DUM` near wood and far from wood to verify bonfire sustain/extinction.
10. Toggle `F3` to inspect or hide collision debug overlays.

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
