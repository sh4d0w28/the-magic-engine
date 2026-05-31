# The Magic Engine

This repository contains the design package and the in-repo implementation for the first Godot 4 prototype of The Magic Engine.

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

## Prototype scope

Use Godot 4 with GDScript.

Phase 1 is a small local prototype:
- cube player on a flat 3D plane,
- typed incantations,
- simulated voice power,
- simple diagram recognition,
- fire-only magic,
- three spells: Spark, Fireball, Bonfire.
