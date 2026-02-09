# ROADMAP — CUSTODIAN (Formalized)

## Purpose
The engine is the source of truth. The UI is a shell. This roadmap prioritizes deterministic, command-driven simulation and keeps UI replaceable.

## Prerequisites (Must Hold Before Phase 1)
- `python -m game --ui` launches without import errors.
- `python -m game --repl` accepts Phase 1 commands.
- `/command` responds with `{ok, lines}` and uses a persistent `GameState`.

If any prerequisite fails, fix it before proceeding.

---

## Phase 1 — Finish Wiring (Critical, Short)

### Goal
The terminal drives real state changes and all world changes occur only inside `step_world`.

### Tasks
1. Single `GameState` per process
   - No per-request state creation in the server.
   - No hidden reinitialization in command handlers.

2. Enforce invariant
   - World changes happen only in `step_world`.
   - Command handlers read state or call `step_world`, but do not mutate state directly.

3. Lock transport contract
   - Request: `{ raw: "<string>" }`
   - Response: `{ ok: boolean, lines: string[] }`

### Exit Criteria
- `python -m game --repl` and `python -m game --ui` behave the same for `STATUS`, `WAIT`, `WAIT 10X`, `HELP`.
- Every state change routes through `step_world`.

---

## Phase 2 — Assault Outcomes (High Impact, Medium)

### Goal
Assaults resolve into concrete consequences.

### Tasks
1. Define outcome set (choose one per assault)
   - Repelled Cleanly
   - Repelled With Damage
   - Partial Breach
   - Strategic Loss
   - COMMAND Breach (failure latch)

2. Apply outcomes in one place
   - Centralize effects in assault resolution.
   - No UI-side changes.

3. Output messaging
   - Use terse, operational messages as defined in the design notes.

### Exit Criteria
- Each assault ends with exactly one outcome.
- `STATUS` reflects outcome effects.

---

## Phase 3 — Pressure & Decay (Medium)

### Goal
State worsens over time even without assaults.

### Tasks
1. Threat escalation
   - Threat creeps on each `WAIT`.
   - Escalates faster with damage and unresolved assaults.

2. Sector decay
   - `DAMAGED` can drift to `COMPROMISED`.
   - `COMPROMISED` unlocks harsher events.

3. Status darkening
   - `STATUS` reflects the worsening state.

### Exit Criteria
- A prolonged `WAIT` sequence visibly degrades state.
- `STATUS` communicates escalation without extra UI logic.

---

## Phase 4 — Deterministic Tests (Short, Medium)

### Goal
Prevent feature rot with reproducible state sequences.

### Tasks
1. Seeded `GameState`
   - Ensure all randomness is driven by a seedable source.

2. Test sequences
   - Example: `WAIT` x3 leads to deterministic threat state.

### Exit Criteria
- At least one deterministic `WAIT` sequence test passes reliably.

---

## Phase 5 — UI-Agnostic Engine (Medium)

### Goal
Replace the UI without changing `game/` logic.

### Tasks
1. REPL parity
   - Any behavior that works in UI must work in REPL.

2. UI swap readiness
   - Keep `terminal.js` as a shell only.

### Exit Criteria
- A different UI can be added without modifying `game/`.

---

## Notes
- Keep code changes small and clear.
- Avoid new systems unless required by a phase.
- Respect the Phase 1 command set until later phases expand it.
