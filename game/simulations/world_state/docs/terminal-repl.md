# World-State Terminal REPL (Phase 1)

Phase 1 is a deterministic command loop:

`BOOT -> COMMAND -> WAIT -> STATE CHANGES -> STATUS`

The world advances only when the operator runs `WAIT`.

## Commands

- `STATUS`
  - Prints:
    - `TIME`
    - `THREAT` bucket (`LOW`, `ELEVATED`, `HIGH`, `CRITICAL`)
    - `ASSAULT` (`NONE`, `PENDING`, `ACTIVE`)
    - sector list with one-word state (`STABLE`, `ALERT`, `DAMAGED`, `COMPROMISED`)
  - Does not advance time.

- `WAIT`
  - Advances the simulation by exactly one tick.
  - Output starts with `TIME ADVANCED.`
  - Additional lines are only emitted for meaningful changes (`[EVENT]`, `[WARNING]`, assault begin/end markers).

- `HELP`
  - Prints the locked command list.

## Error Output

Unknown command response:

- `UNKNOWN COMMAND.`
- `TYPE HELP FOR AVAILABLE COMMANDS.`


## Failure Lockdown

- Command Center breach now places the session in failure mode.
- Breach criteria: Command Center damage reaches the configured threshold (`COMMAND_CENTER_BREACH_DAMAGE`).
- `WAIT` returns explicit final lines when breach occurs:
  - `COMMAND CENTER BREACHED.`
  - `SESSION TERMINATED.`
- While failed, normal commands are locked.
- Only `RESET` or `REBOOT` are accepted to start a fresh session in-process.
