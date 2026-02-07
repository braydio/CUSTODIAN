# World-State Terminal REPL (Phase 1)

Phase 1 is a deterministic command loop:

`BOOT -> COMMAND -> WAIT -> STATE CHANGES -> STATUS`

The world advances only when the operator runs `WAIT`.

## Transport Contract (UI Path)

- Terminal UI submits commands to `POST /command` as JSON `{ "command": "<string>" }`.
- Backend still accepts legacy `{ "raw": "<string>" }` fallback.
- Backend returns JSON with `ok`, `text`, optional `lines`, optional `warnings`.
- `text` is the primary line; `lines` append ordered detail for terminal display.
- Backend-owned `GameState` is authoritative for command results.

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
  - Additional lines are emitted only for meaningful changes (`[EVENT]`, `[WARNING]`, assault begin/end markers, or failure lines).

- `HELP`
  - Prints available command list.

- `RESET` / `REBOOT`
  - Reinitialize the in-process world state.
  - Primarily used for recovery after failure lockout.

## Error Output

Unknown command response:

- `UNKNOWN COMMAND.`
- `TYPE HELP FOR AVAILABLE COMMANDS.`

## Failure Lockdown

- Command Center breach places the session in failure mode.
- Breach criteria: Command Center damage reaches configured threshold (`COMMAND_CENTER_BREACH_DAMAGE`).
- `WAIT` returns explicit final lines when breach occurs:
  - `COMMAND CENTER BREACHED.`
  - `SESSION TERMINATED.`
- While failed, normal commands are locked.
- Only `RESET` or `REBOOT` are accepted until session reset.
- Recovery response is:
  - `SYSTEM REBOOTED.`
  - `SESSION READY.`
