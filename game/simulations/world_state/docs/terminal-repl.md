# World-State Terminal REPL

Deterministic command loop:

`BOOT -> COMMAND -> WAIT -> STATE CHANGES -> STATUS`

The world advances only on time-bearing commands.

## Transport Contract (UI Path)

- `POST /command` body: `{ "command": "<string>" }` (`{ "raw": "<string>" }` fallback).
- Optional idempotency key: `command_id`.
- Response: `{ ok, text, lines }`.
- `lines` includes `text` first, then detail lines.

## Core Commands

- `STATUS`, `STATUS FULL`
- `WAIT`
- `WAIT NX`
- `WAIT UNTIL <ASSAULT|APPROACH|REPAIR_DONE>`
- `HELP`, `HELP <TOPIC>`
- `RESET`, `REBOOT`

## Movement and Presence

- `DEPLOY <TARGET>`
- `MOVE <TARGET>`
- `RETURN`

Presence model:

- Command mode: strategic authority available.
- Field mode: strategic verbs requiring command authority are blocked.

## Systems and Policy

- `FOCUS <SECTOR>`
- `HARDEN`
- `REPAIR <STRUCTURE>`
- `REPAIR <STRUCTURE> FULL`
- `SCAVENGE`, `SCAVENGE NX`
- `SET <REPAIR|DEFENSE|SURVEILLANCE> <0-4>`
- `SET FAB <DEFENSE|DRONES|REPAIRS|ARCHIVE> <0-4>`
- `FORTIFY <SECTOR> <0-4>`
- `CONFIG DOCTRINE <NAME>`
- `ALLOCATE DEFENSE <SECTOR|GROUP> <PERCENT>`

## Fabrication and Tactical Commands

- `FAB ADD <ITEM>`
- `FAB QUEUE`
- `FAB CANCEL <ID>`
- `FAB PRIORITY <CATEGORY>`
- `REROUTE POWER <SECTOR>`
- `BOOST DEFENSE <SECTOR>`
- `DRONE DEPLOY <SECTOR>`
- `DEPLOY DRONE <SECTOR>`
- `LOCKDOWN <SECTOR>`
- `PRIORITIZE REPAIR <SECTOR>`

## WAIT Semantics

- `WAIT` and `WAIT NX` are wait units, not always single ticks.
- Default pacing: 5 ticks per wait unit.
- During active assault: 1 tick per wait unit.
- Tick pacing delay: 0.5 seconds between internal ticks.

Primary line:

- `TIME ADVANCED.`

Detail lines may include:

- fidelity transitions
- events/warnings
- assault/intercept signals
- repair/fabrication signals
- failure termination lines

Adjacent duplicate detail lines are suppressed.

## Failure Lockdown

Failure latches include command-center loss and archive-integrity loss.

While failed:

- only `RESET`/`REBOOT` accepted
- other commands return lockout line: `REBOOT REQUIRED. ONLY RESET OR REBOOT ACCEPTED.`

## Error Output

Unknown command response:

- `ok=false`
- `text="UNKNOWN COMMAND."`
- `lines=["UNKNOWN COMMAND.", "TYPE HELP FOR AVAILABLE COMMANDS."]`
