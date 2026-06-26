# WORLD HISTORY SYSTEM

Status: in_progress
Owner: gameplay/systems
Runtime target: Godot 4 (`custodian/`)

## Goal

Capture durable, sector-scoped runtime events so the world can remember what happened there and later surface that memory through terminals, props, or post-run analysis.

## Runtime Contract

- `WorldHistory` is an autoload event journal.
- Entries are grouped by sector id.
- Each entry records time, kind, position, and optional data.
- The initial slice is in-memory only; save/load can follow later.

## Initial Slice

1. Add `WorldHistory` autoload.
2. Record:
   - player damage
   - player death
   - sector damage/repair
3. Add helper APIs for:
   - `record(...)`
   - `get_sector_history(...)`
   - `has_event(...)`
4. Mirror writes into `DevObservatory` as lightweight telemetry.

## Constraints

- Keep writes bounded and simple.
- Sector ownership remains with world nodes; this system is a journal, not a state owner.
- Avoid save/load coupling in the first pass.

## Acceptance

- World history records can be written from shared gameplay systems.
- Sector-scoped lookup works for the initial event categories.
- Telemetry can inspect recent history writes during play.
