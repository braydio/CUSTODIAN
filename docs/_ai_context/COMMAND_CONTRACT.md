# COMMAND CONTRACT - CUSTODIAN

## Status
- Locked for Phase 1 and implemented end-to-end.

## Transport
- Client: `custodian-terminal/terminal.js`.
- Server: `game/simulations/world_state/server.py`.

## Request Shape
- Method: `POST`
- Path: `/command`
- JSON body:
  - `raw`: string (raw user command line)

## Response Shape
- JSON body:
  - `ok`: boolean
  - `lines`: string[]

## Command Grammar
- Single-line commands.
- Command verb is case-insensitive.
- Phase 1 command set:
  - `STATUS`
  - `WAIT`
  - `HELP`

## Locked Error Semantics
- Unknown command:
  - `ok=false`
  - `lines=["UNKNOWN COMMAND.", "TYPE HELP FOR AVAILABLE COMMANDS."]`

- Reserved phrasing for future authority denial:
  - `COMMAND DENIED.`
  - `COMMAND CENTER REQUIRED.`

## Locked HELP Output
- `AVAILABLE COMMANDS:`
- `- STATUS   View current situation`
- `- WAIT     Advance time`
- `- HELP     Show this list`

## Notes
- `WAIT` advances simulation by exactly one tick.
- `STATUS` never advances time.
