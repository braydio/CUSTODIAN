# Custodian Terminal UI

Text-only terminal UI prototype for the custodian interface. The boot sequence runs from `custodian-terminal/boot.js`, while `custodian-terminal/terminal.js` owns command input, transcript rendering, and backend command submission. Input stays disabled through boot and the system log, then unlocks when command mode is active.

## Behavior Notes

- Boot lines render with a type-in effect plus audio cues (hum + relay + beep + alert + power_cycle), then a system log prints before command mode.
- The terminal module tracks a buffered history and appends command/response transcript lines.
- System log introduces `STATUS`, `WAIT`, `WAIT 10X`, `FOCUS`, `HARDEN`, and `HELP` before input unlock.
- Prompt input posts to `POST /command` with `{raw}` and appends returned `lines` (served by `custodian-terminal/server.py`).
- Sector map UI is a read-only projection fetched from `GET /snapshot` after state-changing commands (`WAIT`, `RESET`, `REBOOT`).
- System panel mirrors snapshot metadata (time, threat, assault, posture, archive losses) without replacing `STATUS`.
- Prompt interaction stays minimal by design and remains inside the terminal frame.
