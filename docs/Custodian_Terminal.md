# Custodian Terminal UI

Text-only terminal UI prototype for the custodian interface. The boot sequence remains in `custodian-terminal/boot.js`, while `custodian-terminal/terminal.js` owns command input, transcript rendering, and backend command submission. Input stays disabled through boot and tutorial feed, then unlocks when command mode is active.

## Behavior Notes

- Boot lines render with the existing type-in effect.
- The terminal module tracks a buffered history and appends command/response transcript lines.
- Tutorial feed introduces `STATUS`, `WAIT`, and `HELP` before input unlock.
- Prompt input posts to `POST /command` with `{raw}` and appends returned `lines`.
- Prompt interaction stays minimal by design and remains inside the terminal frame.
