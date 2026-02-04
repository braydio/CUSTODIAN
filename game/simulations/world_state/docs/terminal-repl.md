# World-State Terminal (Phase 1)

Phase 1 adds a deterministic terminal loop for manual control. There is no background ticking; the operator advances time explicitly.

## Entry Point

From repo root:

```bash
WORLD_STATE_MODE=repl python game/simulations/world_state/sandbox_world.py
```

Use `WORLD_STATE_MODE=sim` to run the legacy autonomous loop.

## Commands

- `help`: show all commands and usage.
- `status`: show time, threat, and assault status.
- `contacts`: show known contact summaries.
- `profile`: show the hostile profile summary.
- `sectors`: list all sectors.
- `sector <name>`: inspect a single sector (use quotes for multi-word names).
- `go <sector>`: move operator presence to a sector.
- `wait [ticks]`: advance the simulation by the specified ticks.

## Notes

- Phase 1 uses manual advancement only. `wait` steps the full world simulation each tick, including ambient events and assaults.
- Sector matching resolves exact names first, then unique prefixes, then unique contains matches.
