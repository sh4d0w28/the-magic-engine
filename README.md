# The Magic Engine

This repository contains the design package and the in-repo implementation for the first Godot 4 prototype of The Magic Engine.

The current state is a playable local combat sandbox in Godot 4.6.3:
- camera-relative movement with mouse orbit,
- player-authored spellbook pages,
- typed fire incantations resolved from authored pages,
- microphone voice incantations,
- simulated voice power,
- simple diagram recognition,
- inventory use/drop with world pickups,
- target dummies with health, destruction, score, and combat feedback,
- hostile enemies that chase and pressure the player,
- player defeat and automatic encounter reset,
- bonfire fuel gameplay with visible wood depletion,
- optional collision debug overlays.

## Workflow

Work milestone by milestone.

1. Read [docs/04_IMPLEMENTATION_PLAN.md](docs/04_IMPLEMENTATION_PLAN.md).
2. Build only the current milestone.
3. Verify the acceptance checklist before continuing.
4. Commit each milestone separately.

## Repository contents

- `docs/` - technical spec, architecture notes, scene layout, implementation plan.
- `checklists/` - milestone acceptance criteria.
- `codex_prompts/` - original implementation prompts.
- `schemas/` - spell request and result examples.
- `scripts/tests/AcceptanceRunner.gd` - headless regression harness for the current sandbox.

## Prototype scope

Use Godot 4 with GDScript.

Phase 1 is a small local prototype:
- cube player on a flat 3D plane,
- typed incantations,
- simulated voice power,
- simple diagram recognition,
- fire-only magic,
- three spells: Spark, Fireball, Bonfire.

## Current Controls

- `WASD` - move
- Hold `LMB` + move mouse - orbit camera
- `Enter` - open/submit typed incantation
- `M` - listen for a microphone incantation
- `E` - pick up a nearby item
- `I` - open inventory
- `B` - open spellbook
- `Escape` - cancel typed incantation
- Hold `V` - charge voice power
- Hold `RMB` - draw diagram
- `F3` - toggle hitbox debug visuals

## Current Sandbox Loop

1. Move around the arena.
2. Aim using the mouse reticle and ground target marker.
3. Open the spellbook with `B`, author your own spell pages, and bind incantations to the available fire effects.
4. Hit target dummies to test direct hits, splash, and destruction.
5. Kite hostile enemies and verify contact damage plus reset flow on defeat.
6. Use inventory items, pick up world materials, and drop items back into the arena.
7. Use bonfires and sparks near wood to test fuel behavior.

## Voice Notes

- The current microphone backend uses Windows `System.Speech`.
- The Godot-side recognizer wrapper is backend-shaped, so a cross-platform speech engine can replace it later without changing the spell flow.

## Validation

Project load check:

```powershell
.\Godot_v4.6.3-stable_win64_console.exe --headless --path . --quit
```

Full sandbox acceptance harness:

```powershell
.\Godot_v4.6.3-stable_win64_console.exe --headless --path . --script res://scripts/tests/AcceptanceRunner.gd
```
