# World-State Terminal REPL (Phase 1)

Phase 1 is a deterministic command loop:

`BOOT -> COMMAND -> WAIT -> STATE CHANGES -> STATUS`

The world advances only when the operator runs `WAIT` or `WAIT 10X`.

## Transport Contract (UI Path)

- Terminal UI submits commands to `POST /command` as JSON `{ "raw": "<string>" }`.
- Backend returns JSON with `ok` and `lines`.
- `lines` are ordered for terminal display (primary line first).
- Backend-owned `GameState` is authoritative for command results.

## Commands

- `STATUS`
  - Prints:
    - `TIME`
    - `THREAT` bucket (`LOW`, `ELEVATED`, `HIGH`, `CRITICAL`)
    - `ASSAULT` (`NONE`, `PENDING`, `ACTIVE`)
    - optional `SYSTEM POSTURE` (`HARDENED` or `FOCUSED (<SECTOR>)`)
    - optional `ARCHIVE LOSSES` (`<count>/<limit>`)
    - sector list with one-word state (`STABLE`, `ALERT`, `DAMAGED`, `COMPROMISED`)
  - Does not advance time.

- `WAIT`
  - Advances the simulation by exactly one tick.
  - Output starts with `TIME ADVANCED.`
  - Additional lines are emitted for meaningful changes (`[EVENT]`, `[WARNING]`, assault begin/end markers, or failure lines).
  - If no event/assault transition occurred, one terse `[PRESSURE]` line is emitted to preserve situational awareness.
- `WAIT 10X`
  - Advances the simulation by ten ticks.
  - Output starts with `TIME ADVANCED x10.`
  - Detail lines summarize events, warnings, assault transitions, and failure termination lines seen during the burst.
- `FOCUS <SECTOR_ID>`
  - Sets the focused sector by ID (for example `FOCUS POWER`).
  - Focus persists until changed or an assault resolves.
  - Does not advance time.
- `HARDEN`
  - Hardens systems to compress assault damage into fewer sectors.
  - Clears any active focus and resets after an assault resolves.
  - Does not advance time.

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

- COMMAND breach places the session in failure mode.
- Breach criteria: COMMAND damage reaches configured threshold (`COMMAND_CENTER_BREACH_DAMAGE`).
- `WAIT` returns explicit final lines when breach occurs:
  - `COMMAND CENTER LOST`
  - `SESSION TERMINATED.`
- ARCHIVE loss also places the session in failure mode once the loss limit is reached.
- Failure reason for ARCHIVE loss:
  - `ARCHIVAL INTEGRITY LOST`
- While failed, normal commands are locked.
- Only `RESET` or `REBOOT` are accepted until session reset.
- Recovery response is:
  - `SYSTEM REBOOTED.`
  - `SESSION READY.`
