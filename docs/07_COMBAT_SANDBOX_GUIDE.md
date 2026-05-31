# Combat Sandbox Guide

## Purpose

The Phase 1 prototype has progressed beyond isolated milestone checks. The current playable focus is a single-scene combat sandbox that proves:

- typed incantation flow,
- fire spell targeting,
- direct hit and splash behavior,
- energy payment and health-overdraw rules,
- wood fuel interaction,
- dummy health/destruction feedback,
- debug visibility for collision troubleshooting.

## Sandbox Features

### Player

- camera-relative movement,
- mouse-orbit camera,
- HUD for health, mana, score, and combat feed,
- typed spell entry with normalized incantations.

### Spells

- `RAK` -> Spark
- `RAK TOR` -> Fireball
- `RAK DUM` -> Bonfire

### Targets and Resources

- destructible target dummies,
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
3. Cast `RAK TOR` into a dummy and confirm direct impact, damage feedback, and destruction.
4. Cast `RAK TOR` between nearby dummies and confirm splash damage.
5. Cast `RAK` near a dummy and near a wood pile to verify spark interactions.
6. Cast `RAK DUM` near wood and far from wood to verify bonfire sustain/extinction.
7. Toggle `F3` to inspect or hide collision debug overlays.

## Validation Commands

Project load:

```powershell
.\Godot_v4.6.3-stable_win64_console.exe --headless --path . --quit
```

Acceptance harness:

```powershell
.\Godot_v4.6.3-stable_win64_console.exe --headless --path . --script res://scripts/tests/AcceptanceRunner.gd
```
