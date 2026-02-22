# Custodian Terminal UI

Browser terminal UI for the world-state backend.

## Modules

- `custodian-terminal/boot.js`: boot stream playback, audio sequencing, unlock handoff.
- `custodian-terminal/terminal.js`: input loop, command submit, transcript rendering, terminal QoL behavior.
- `custodian-terminal/sector-map.js`: snapshot-driven map/panel projection.
- `custodian-terminal/server.py`: static host + `/stream/boot` + `/command` + `/snapshot`.

## Runtime Behavior

- Input remains disabled during boot stream playback.
- On boot completion, command mode activates and backend command transport begins.
- Command submit uses `POST /command` and expects `{ok, text, lines}`.
- Snapshot projection refreshes after state-changing commands.

## Current Operator UX

- Command history: `ArrowUp` / `ArrowDown`.
- Input focus hint sequence and focus zone support.
- Tab completion for common commands (`Tab` and `Shift+Tab`).
- `Esc` clears the current input line.
- `Ctrl+L` clears terminal viewport locally.
- `NEW OUTPUT - JUMP` indicator appears when scrolled up and jumps back to latest output on click.
- Critical output styling includes bounded alert flicker bursts (not continuous).

## Contract Boundary

- Frontend is non-authoritative.
- Backend controls parsing, authority, simulation stepping, and all game state mutation.
