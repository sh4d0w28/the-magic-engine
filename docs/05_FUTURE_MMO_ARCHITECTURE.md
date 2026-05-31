# Future MMO Architecture

This is not implemented in Phase 1.

## Future client-server flow

```text
Godot Client
  -> sends SpellRequest
Go Server
  -> validates player state
  -> validates incantation
  -> validates energy cost
  -> updates world state
  -> broadcasts SpellResult
Godot Clients
  -> render effects
```

## Future backend services

- Auth service
- World simulation service
- Spell validation service
- Research/discovery service
- Persistence service

## Storage

PostgreSQL:
- accounts,
- characters,
- discoveries,
- known words,
- guild research.

Redis/KeyDB:
- online players,
- active world state,
- temporary spell effects.
