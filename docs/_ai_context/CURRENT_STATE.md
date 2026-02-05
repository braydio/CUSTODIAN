# CURRENT STATE — CUSTODIAN

## Code Status
- Terminal UI boot sequence implemented (JS). Tutorial feed runs before input unlock; local echo command input only.
- World-state simulation spine implemented (Python). Procedural events + assault timer active.
- Assault simulation prototype implemented (Python), standalone runner.
- Terminal webserver added for remote viewing (Flask + SSE boot stream).

## Implemented vs Stubbed
- Implemented: boot sequence rendering, telemetry stubs, world-state ticks, assault resolution.
- Stubbed: command transport (UI to backend), command parsing, authoritative command handling.

## Locked Decisions
- Terminal-first interface; operational, terse tone.
- World time advances by explicit ticks (no hidden background time in the world sim).
- Command authority is location-based, not flag-based.

## Flexible Areas
- Command grammar and response schema (not finalized).
- Webserver transport endpoints for command input (not built yet).
- Telemetry cadence and formatting (front-end only today).

## In Progress
- None.

## Next Tasks
1. Add command endpoint in the terminal webserver (POST) and wire JS submit to it.
2. Define command grammar + response schema in COMMAND_CONTRACT.md.
3. Implement basic HELP / STATUS commands in Python with authoritative responses.
