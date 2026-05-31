# Magic Engine Rules

## Spell execution pipeline

1. Normalize raw input.
2. Match spell definition.
3. Read voice power.
4. Read diagram result.
5. Calculate stability.
6. Check success threshold.
7. Calculate final power.
8. Calculate final cost.
9. Spend mana/health.
10. Return SpellResult.
11. Spawn effect only after success.

## Failure types

### Unknown incantation

Cause: phrase is not in SpellDefinitions.

Result:
- no energy spent,
- debug message: Unknown incantation.

### Low stability

Cause: weak incantation or mismatched diagram.

Result:
- no full spell,
- optional small failed spark,
- no major energy spent in Phase 1.

### Not enough energy

Cause: mana and health cannot pay cost.

Result:
- spell fails,
- health does not go below 1,
- spawn BacklashEffect.

## Energy conservation examples

Fireball:
- mana -> heat and projectile motion.

Bonfire:
- mana -> ignition,
- wood -> sustained fire.

Spark:
- mana -> tiny heat burst.
