# Custodian Terminal UI

Text-only terminal UI prototype for the custodian interface. The boot sequence remains in `custodian-terminal/boot.js`, while `custodian-terminal/terminal.js` owns the command prompt, output buffer, and echo responses. Input stays disabled through boot, a scripted tutorial feed, and is enabled once the command interface goes active.

## Behavior Notes

- Boot lines render with the existing type-in effect.
- The terminal module tracks a buffered history and appends command echoes.
- A short tutorial feed introduces STATUS, SECTORS, POWER, and WAIT before input unlock.
- Prompt input is minimal by design and stays within the terminal frame.
