# COMMAND CONTRACT — CUSTODIAN

## Status
- Implemented end-to-end for Phase 1 commands via `/command`.

## Transport
- Client: `custodian-terminal/terminal.js` (posts to `/command`).
- Server: `custodian-terminal/streaming-server.py` (holds persistent `GameState`).

## Request Shape (Current UI)
- Method: `POST`.
- Path: `/command`.
- Canonical JSON body field: `command` (string raw input).
- Backward-compatible fallback: `raw` (string) is accepted temporarily.

## Response Shape (Current)
- JSON body fields: `ok` (boolean), `text` (string primary line).
- Optional JSON body fields: `lines` (string[] ordered detail), `warnings` (string[] non-fatal warnings).

## Command Grammar (Current Python)
- Single-line commands, case-insensitive keyword first.
- Quoted args supported; flags use `--flag` or `--flag=value`.
- Examples: `STATUS`, `SECTORS`, `POWER`, `WAIT [ticks]`.
- Phase 1 design lock (historical): `STATUS`, `WAIT`, `HELP` only (see `docs/_ai_context/ARCHITECTURE.md`).

## Authority Rules (Current Python)
- Read commands permitted anywhere.
- Write commands require Command Center authority.
- Denied actions return `ok=false` with a one-line reason.

## Error Semantics (Current Python)
- Unknown command: `ok=false`, `text="Unknown command."`
- Invalid args: `ok=false` with a terse reason (e.g., ticks must be positive).

## Notes
- `WAIT` advances simulation by exactly one tick.
- `STATUS` never advances time.
