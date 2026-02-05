# CURRENT STATE — CUSTODIAN

## Code Status
- Terminal UI boot sequence implemented (JS). Tutorial feed runs before input unlock; local echo command input only.
- World-state simulation spine implemented (Python). Procedural events + assault timer active.
- Assault simulation prototype implemented (Python), standalone runner.
- Terminal webserver added for remote viewing (Flask + SSE boot stream).

## Implemented vs Stubbed
- Implemented: boot sequence rendering, telemetry stubs, world-state ticks, assault resolution.
- Stubbed: command transport wiring from terminal submit path to authoritative backend execution.

## Locked Decisions
- Terminal-first interface; operational, terse tone.
- World time advances by explicit command-driven ticks (no hidden background time in terminal mode).
- Command authority is location-based, not flag-based.

## Flexible Areas
- Command grammar details and error text phrasing.
- Webserver submit endpoint placement and request validation depth.
- Telemetry cadence and formatting (front-end only today).

## In Progress
- Documentation alignment for terminal-primary flow, boot handoff, and command transport contract.

## Next Tasks
1. Add command endpoint in the terminal webserver (POST) and wire JS submit to it.
2. Implement basic HELP / STATUS commands in Python with authoritative responses.
3. Replace local echo path with transport-backed `CommandResult` rendering.
