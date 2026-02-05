# CURRENT STATE - CUSTODIAN

## Code Status
- Terminal UI boot sequence implemented and now unlocks live command input.
- World-state simulation spine implemented (Python). Procedural events + assault timer active.
- Command transport implemented end-to-end between terminal UI and world-state server.

## Implemented vs Stubbed
- Implemented: command transport contract (`raw` in, `{ok, lines}` out), command parsing/dispatch, HELP/STATUS/WAIT handlers, persistent server-owned `GameState`.
- Stubbed: command authority restrictions (reserved phrasing only, no enforcement in Phase 1).

## Locked Decisions
- Terminal-first interface with operational, terse output.
- World time advances only through `WAIT`.
- Phase 1 command set is fixed: `STATUS`, `WAIT`, `HELP`.
- Command response contract is fixed: `{ok, lines}`.

## Flexible Areas
- Future authority checks and location restrictions.
- Read-only map projection layer that mirrors command-visible state.

## In Progress
- None.
