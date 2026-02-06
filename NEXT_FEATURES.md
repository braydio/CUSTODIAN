
Here’s the **step-by-step overview** to get `STATUS` (and the whole terminal loop) “in motion” end-to-end, without getting sucked into map/UI scope yet. The map can come after the loop exists.

---

## Step-by-step to get `STATUS` working end-to-end

### 1) Pick the single runtime “truth”

* Decide **one Python process** owns `GameState` for the session.
* It must persist between commands (not recreated per request).

Deliverable: a long-lived `GameState` instance in the server process.

---

### 2) Define the command transport contract (tiny)

Request:

* `raw`: string (the command line)

Response:

* `ok`: boolean
* `lines`: array of strings (each a terminal line)

Deliverable: one JSON shape used everywhere.

---

### 3) Implement the minimal command pipeline (Python)

Pipeline order:

1. **Parse** raw input → `{verb, args}`
2. **Authorize** (Phase 1: `STATUS` always allowed)
3. **Dispatch** verb → handler
4. **Return** `{ok, lines}`

Deliverable: `process_command(state, raw) -> Result`.

---

### 4) Implement `STATUS` handler (Python)

* Produces exactly the locked output format:

  * TIME
  * THREAT bucket
  * ASSAULT status (NONE/PENDING/ACTIVE)
  * SECTORS list with one-word state per sector

Deliverable: `cmd_status(state) -> list[str]`

---

### 5) Add a “tick driver” command (even if stubbed)

Even if we don’t fully design `WAIT` yet, you need a way to advance:

* `WAIT` increments time by 1 tick and runs the world step:

  * `advance_time`
  * `maybe_trigger_event`
  * assault timer / assault resolve (Phase 1 rules)

Deliverable: `cmd_wait(state) -> list[str]` (can be minimal output)

This makes the system *move*.

---

### 6) Wire the backend HTTP endpoint

* `POST /command`
* Body: `{ raw: "STATUS" }`
* Response: `{ ok, lines }`

Deliverable: one endpoint that calls `process_command`.

---

### 7) Update the terminal UI to accept input after boot

In your JS boot flow (`enterCommandMode()` already exists) :

* Add an input line UX (simple):

  * capture keystrokes
  * maintain a current line buffer
  * on Enter: send to backend
* Disable input until boot completes (you already do this conceptually)

Deliverable: you can type `status` and see a response appended.

---

### 8) Terminal rendering rules (don’t overbuild)

When response arrives:

* Print the user’s command line first (e.g., `> STATUS`)
* Then print each returned line on its own line
* Keep the terminal scroll pinned to bottom

Deliverable: consistent transcript-style output.

---

### 9) Manual validation loop (your first “playable”)

Do this as your acceptance test:

1. Load terminal page
2. Boot finishes → “COMMAND INTERFACE ACTIVE”
3. Type `STATUS`
4. See correct formatted output
5. Type `WAIT`
6. Type `STATUS` again
7. Confirm TIME increased + state changes can occur

Deliverable: “I can play the sim via commands.”

---

### 10) Only after this: introduce the map UI

Once commands work, the map becomes *a projection*:

* Map UI reads the same state as terminal commands
* It never becomes the authority

But don’t touch it until Step 9 passes.

---

## What “in motion” means (definition)

You’re “in motion” when:

* There’s a persistent `GameState`
* Commands mutate or read it
* `WAIT` advances it deterministically
* UI is just input/output

That’s the minimal playable spine.

---

CONTINUED:

---

# Phase 1 Terminal Design — FINAL LOCK

Scope:

> **A deterministic, command-driven world-state loop playable entirely through the terminal.**

No UI maps yet. No combat control. No optimization layer.

---

## 1. Core Loop (the spine)

**Loop invariant (non-negotiable):**

```
BOOT → COMMAND → WAIT → STATE CHANGES → STATUS → …
```

* The world **does not move** unless the player issues `WAIT`.
* All simulation happens **inside the `WAIT` handler**.
* All visibility happens via **commands**.

This is the contract the entire game builds on.

---

## 2. Command Set (Phase 1 only)

### Implement exactly these commands:

| Command  | Type  | Purpose                   |
| -------- | ----- | ------------------------- |
| `STATUS` | Read  | Situational awareness     |
| `WAIT`   | Write | Advance time by one tick  |
| `HELP`   | Read  | Remind player what exists |

No others. No aliases yet.

---

## 3. `STATUS` (locked, restated for completeness)

### Output format

```
TIME: <int>
THREAT: <LOW | ELEVATED | HIGH | CRITICAL>
ASSAULT: <NONE | PENDING | ACTIVE>

SECTORS:
- <Sector Name>: <STABLE | ALERT | DAMAGED | COMPROMISED>
```

### Notes

* All caps
* ASCII only
* No numbers except TIME
* No recommendations
* No hidden info in Phase 1

`STATUS` **never advances time**.

---

## 4. `WAIT` — final design

### Purpose

Advance the simulation **by exactly one tick**.

### What happens during `WAIT` (in order)

1. Advance time (`+1`)
2. Apply passive decay and effects
3. Possibly trigger **one** ambient event
4. Update assault timer **or** resolve assault (if active)
5. Produce **minimal output**

---

### `WAIT` output format (locked)

`WAIT` outputs **only what changed or matters**.

Possible outputs (examples):

#### Case A — nothing notable

```
TIME ADVANCED.
```

#### Case B — ambient event occurred

```
TIME ADVANCED.
[EVENT] Sensor jamming detected in Radar / Control Tower.
```

#### Case C — assault timer warning

```
TIME ADVANCED.
[WARNING] Hostile coordination detected.
```

#### Case D — assault begins

```
TIME ADVANCED.
=== MAJOR ASSAULT BEGINS ===
```

#### Case E — assault resolves

```
TIME ADVANCED.
=== ASSAULT REPULSED ===
```

### Rules

* `WAIT` **never prints a full status dump**
* `WAIT` may print **multiple lines**, but only if meaningful
* No “tick numbers”
* No probabilities
* No verbose narration

The player is expected to use `STATUS` after `WAIT`.

---

## 5. `HELP` — minimal by design

### Output (exact)

```
AVAILABLE COMMANDS:
- STATUS   View current situation
- WAIT     Advance time
- HELP     Show this list
```

That’s it. No lore. No tutorials.

---

## 6. Error handling (important)

### Unknown command

```
UNKNOWN COMMAND.
TYPE HELP FOR AVAILABLE COMMANDS.
```

### Command not allowed (future-proofing)

(Not used yet, but reserve phrasing.)

```
COMMAND DENIED.
COMMAND CENTER REQUIRED.
```

Do **not** implement authority checks yet, but lock the language now.

---

## 7. Authority model (Phase 1)

* All commands are allowed
* No location restrictions yet
* No deception, fog, or misreporting

This keeps Phase 1 about **reading the system**, not fighting it.

---

## 8. Map UI (explicitly deferred, but shaped)

Design assumption (locked for later):

* The map will be a **projection** of:

  * sector names
  * sector states
* It will **never** advance time
* It will **never** replace the terminal

Everything the map shows must be derivable from `STATUS`.

This prevents future UI power creep.

---

## 9. Acceptance criteria (definition of “done”)

Phase 1 is complete when:

1. Boot finishes
2. Player can type `STATUS`
3. Player can type `WAIT`
4. World state changes only via `WAIT`
5. `STATUS` reflects those changes
6. No crashes, no background ticking

If all six are true, the game is *playable*.

---

## 10. Final design freeze

From here on:

* We **do not** revisit formats
* We **do not** add commands
* We **do not** tweak wording casually

Next step is **implementation**, not ideation.

---

## Implementation order (so you don’t stall)

1. Python command processor
2. `STATUS` handler
3. `WAIT` handler
4. HTTP endpoint
5. JS input capture + rendering

Perfect. Here is the **clean, minimal file-addition layout** for Phase 1.
No refactors, no renames — just **new files + clear responsibilities**.

---

# Phase 1 — File Additions (Names & Responsibilities)

This assumes:

* Your existing world simulation code stays intact
* You add a **thin command layer** on top of it
* Terminal UI stays dumb

---

## Backend (Python)

### 1. `game/simulations/world_state/terminal/`

**Purpose:**
All command-related logic lives here.
Nothing in this folder should know about HTTP, JS, or UI.

```
game/simulations/world_state/terminal/
├── __init__.py
├── processor.py
├── parser.py
├── result.py
└── commands/
    ├── __init__.py
    ├── status.py
    ├── wait.py
    └── help.py
```

---

### 1.1 `terminal/parser.py`

**Responsibility:**

* Convert raw input string → structured command

**Owns:**

* Uppercasing verb
* Splitting args
* No validation beyond syntax

**Does NOT:**

* Touch game state
* Enforce authority
* Execute commands

---

### 1.2 `terminal/result.py`

**Responsibility:**

* Define the standard command response object

Example fields:

* `ok: bool`
* `lines: list[str]`

This is the **contract boundary** between backend and frontend.

---

### 1.3 `terminal/processor.py`

**Responsibility:**

* Orchestrate command execution

**Flow:**

1. Receive raw command string
2. Call parser
3. Dispatch to command handler
4. Return `CommandResult`

This file is where:

* Unknown commands are rejected
* (Later) authority checks will live

---

### 1.4 `terminal/commands/status.py`

**Responsibility:**

* Implement the `STATUS` command

**Owns:**

* Mapping internal state → discrete labels
* Formatting output exactly per design

**Does NOT:**

* Advance time
* Trigger events

---

### 1.5 `terminal/commands/wait.py`

**Responsibility:**

* Implement the `WAIT` command

**Owns:**

* Advancing time by exactly one tick
* Calling:

  * `advance_time`
  * `maybe_trigger_event`
  * assault timer logic
* Returning **only meaningful output**

---

### 1.6 `terminal/commands/help.py`

**Responsibility:**

* Return static help text

No logic. No state.

---

## Backend server (bridge only)

### 2. `custodian-terminal/command_api.py`

**Responsibility:**

* HTTP boundary between JS and Python simulation

**Owns:**

* `/command` endpoint
* Accepting `{ raw: string }`
* Returning `{ ok, lines }`

**Does NOT:**

* Parse commands
* Mutate state directly
* Format output

It just calls `processor.process_command(...)`.

---

### 3. Modify (not add): `custodian-terminal/server.py`

**Change only:**

* Import `command_api`
* Register the endpoint

No other responsibilities added.

---

## Frontend (JS)

### 4. `custodian-terminal/input.js`

**Responsibility:**

* Capture keyboard input
* Maintain current input buffer
* Submit on Enter
* Handle backspace, clear, etc.

**Does NOT:**

* Format responses
* Know command semantics

---

### 5. `custodian-terminal/render.js`

**Responsibility:**

* Append text to terminal
* Render:

  * user input (`> STATUS`)
  * backend response lines
* Scroll management

---

### 6. Modify (not add): `boot.js`

**Change only:**

* After `enterCommandMode()`:

  * Enable input
  * Hook input → command API
  * Pipe response → renderer

Boot logic stays isolated.

---

## Shared state (critical, but no new file yet)

### 7. World state ownership

**Decision (locked):**

* `GameState` instance lives in the server process
* Created once at server start
* Passed into command processor

No per-request state creation.

---

## Summary Table

| Area      | File                    | Purpose                   |
| --------- | ----------------------- | ------------------------- |
| Commands  | `terminal/processor.py` | Central command router    |
| Parsing   | `terminal/parser.py`    | Raw → structured command  |
| Output    | `terminal/result.py`    | Command response contract |
| STATUS    | `commands/status.py`    | Read-only state summary   |
| WAIT      | `commands/wait.py`      | Advance simulation        |
| HELP      | `commands/help.py`      | Static help               |
| API       | `command_api.py`        | HTTP bridge               |
| UI Input  | `input.js`              | Keyboard handling         |
| UI Output | `render.js`             | Terminal rendering        |

---

## Why this layout works

* **No circular dependencies**
* UI never touches game logic
* Simulation never knows about HTTP
* Commands are isolated and testable
* Future authority rules drop cleanly into `processor.py`

---
