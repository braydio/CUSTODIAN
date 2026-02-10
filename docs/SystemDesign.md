# System Design (Simulation First)

This project is not a wave-defense game. It is a pressure-based survival simulation. The design hinges on continuous time, uncertainty, and asymmetric information.

## Time Layers

The loop is defined by three overlapping time layers:

1. Ambient time: always running.
2. Assault time: high-intensity spikes.
3. Field time: player absence and risk transfer.

Battles do not have clean boundaries. Threat is continuous. Safety is inferred, not guaranteed.

## Five Core Systems

### A) Power as a Campaign Resource

Power is more than moment-to-moment energy. It is a victory requirement and a persistent bottleneck.

Two kinds of power:

- Operational power: moment-to-moment use (turrets, traps, barriers).
- Strategic power capacity: power cells/generators that determine how many systems can exist.

Strategic power is accumulated and protected, not spent.

### B) Field Power Cells (Forcing Recon)

Power cells:

- Exist in the world.
- Are procedurally placed after the tutorial.
- Must be repaired, extracted, and installed.
- Cannot be fabricated at base.

This keeps recon relevant in the late game.

### C) Ambient Threat (Always-On Pressure)

A hidden scalar that rises over time and faster when:

- You expand power.
- You complete recon runs.
- You defeat assaults decisively.

Ambient threat manifests as solo attackers, small groups, saboteurs, and environmental hazards. These are not assaults. They are the world pressing in.

### D) Major Assaults (Gated, Not Scripted)

Major assaults:

- Are triggered by a hidden assault timer.
- Start the moment you return from recon.
- Do not stop if you leave again.
- Lock down safe recon and consume resources.

Key rule: recon runs trigger assaults, and assaults gate recon runs.

### E) "Quiet Enough" State (Soft Feedback)

The player should only see qualitative state, not timers:

- "Tense"
- "Unstable"
- "Quiet enough"

This keeps uncertainty without unfairness.

## Terminal Boot-to-Operations Handoff

The terminal UI is the primary player-facing entry point once command transport is wired.

- Server boots and starts an SSE stream.
- Client renders scripted boot lines in order.
- Input remains locked during boot output.
- Input unlocks only after boot completion marker.
- After unlock, commands route to the authoritative world-state command endpoint.

Design intent:

- Keep boot deterministic and readable.
- Prevent operator input before system readiness.
- Make the world-state backend the source of truth for all command effects.

## Command Transport Contract

Transport between terminal UI and backend follows a strict boundary.

Request:

- Endpoint: `POST /command`
- Content-Type: `application/json`
- Body: `{ "raw": "<string>" }`

Response (terminal payload):

- `ok` (bool): command accepted and executed.
- `lines` (list[string]): ordered terminal lines (primary line first).

Contract rules:

- Backend owns parsing, authority checks, and simulation stepping.
- Frontend does not infer state changes from local echo.
- Output remains terse, operational, and ASCII-safe.
- Unknown or unauthorized commands return `ok=false` with actionable text.

Snapshot:

- Endpoint: `GET /snapshot`
- Returns read-only world-state projection for UI panels and map.

## Implementation Order (Do This First)

Do not add recon gameplay, ambient enemies, or real-time ticks yet. Build the clock and pressure model in text first.

### Step 1: Add a global GameState

Single source of truth:

```python
class GameState:
    def __init__(self):
        self.time = 0
        self.ambient_threat = 0.0
        self.assault_timer = None
        self.in_major_assault = False
        self.player_location = "COMMAND"
```

### Step 2: Advance time every tick

```python
def advance_time(state, delta=1):
    state.time += delta
    state.ambient_threat += 0.01 * delta
```

### Step 3: Implement ambient events only

```python
def maybe_trigger_ambient_event(state):
    if state.ambient_threat > 5 and random.random() < 0.1:
        print("Ambient event: lone scavenger enters the perimeter")
```

### Step 4: Add the hidden assault timer

```python
def maybe_start_assault_timer(state):
    if state.assault_timer is None:
        state.assault_timer = random.randint(30, 60)
```

```python
def tick_assault_timer(state):
    if state.assault_timer is not None:
        state.assault_timer -= 1
        if state.assault_timer <= 0:
            state.in_major_assault = True
```

Do not print the timer. Only print when the assault starts.

### Step 5: Gate recon with state, not UI

```python
def can_go_on_recon(state):
    return not state.in_major_assault and state.ambient_threat < THRESHOLD
```

## Why This Ordering Matters

If you implement time and pressure first:

- Ambient events stop feeling random.
- Assaults feel earned.
- Recon feels dangerous.
- Power acquisition feels meaningful.
- The base feels alive even in text.

## Phase 1 Terminal Contract

Phase 1 is a deterministic terminal interface. The contract is:

- One command in, one response out.
- No background ticking while the operator is in control.
- Command handlers return a structured result with success state and ordered lines.
- Commands are parsed with shell-style quoting for multi-word sector names.

The terminal loop owns input/output. Command handlers mutate the game state and
return a `CommandResult` payload for display.

### Authority Model

Authority is enforced at command dispatch:

- Phase 1 allows all commands.
- Authority gating is deferred until later phases.

## Validation Target

Run `python game/simulations/world_state/sandbox_world.py` and confirm:

- Quiet stretches.
- Sudden incidents.
- Assaults emerging naturally.
- Qualitative status messages only.

## World-State Command Endpoint

The world-state server exposes a simple POST endpoint for command execution.

Endpoint: `POST /command`

JSON request:

- `raw`: string input.

JSON response:

- `ok`: bool.
- `lines`: list of terminal lines.



## Data Structures, Information Rules, Post-Assault

### Locked Decisions

The following decisions are treated as intent, not suggestion:

* **Damage is structure-level**, not sector-level
* **Sectors are an aggregate view**, derived from their contained structures
* **Clean defenses are possible but rare**, and usually imply low-value threats
* **Autopilot repair exists but starts at zero effectiveness**
* **Time alone does not worsen damage**
* **Damage worsens only via actors** (enemies, ambient events)
* **Repairs are actions that consume time + resources**
* **Repairs can occur during assaults, but are physical and risky**
* **No permanent losses short of campaign failure**
* **Information fidelity applies to damage visibility**
* **“Post-assault” is a state, not a timer**
* **Player emotion target**: cost + urgency

Everything below assumes this.

---

## 1. Core Concept: Post-Assault Is Not a Phase

**Important lock:**

> There is no special “post-assault mode.”

Instead:

* Assault **ends**
* World continues
* Damage persists
* Pressure only resumes when the player leaves (expedition trigger later)

This avoids artificial pacing and fits your hub/campaign model.

---

## 2. Damage Model (Structure-Level)

## 2.1 Structure State Machine (Canonical)

Each structure (turret, trap, power relay, sensor, fabricator, etc.) exists in exactly one state:

```text
OPERATIONAL
DAMAGED
OFFLINE
DESTROYED
```

### State semantics

* **OPERATIONAL**

  * Full function
* **DAMAGED**

  * Reduced effectiveness
  * Slower response / lower output
* **OFFLINE**

  * Non-functional
  * Can be repaired
* **DESTROYED**

  * Exists physically but cannot function
  * Requires reconstruction (not repair)
  * Cannot auto-repair

This gives you a **repair gradient**, not a binary switch.

---

## 2.2 Sector State (Derived, Not Stored)

Sector state is computed from structures first, with existing sector
metrics as a fallback. Phase 1 rule:

- If a sector has any non-operational structure, its status is `DAMAGED`.
- If all structures are operational (or no structures exist yet), use the
  existing sector status label.

This keeps the sector view readable while routing damage through the
structure model.

---

## 3. Assault Outcomes → Damage Application

When an assault resolves, exactly **one outcome** is selected (already exists conceptually).

## 3.1 Outcome → Damage Rules

### A. Repelled Cleanly

* No structures move to a worse state
* Minor wear may exist internally but not modeled yet

### B. Repelled With Damage

* 1–N structures move:

  * OPERATIONAL → DAMAGED
  * DAMAGED → OFFLINE

### C. Partial Breach

* Structures in breached sectors may:

  * Move directly to OFFLINE or DESTROYED
* Increased chance of COMMS degradation

### D. Strategic Loss

* High-value structures targeted
* DESTROYED becomes likely

### E. Failure (COMMAND / ARCHIVE)

* Existing failure latch behavior applies

**Key rule:**
Damage is applied **once**, atomically, at assault resolution.
No hidden ticking afterward.

---

## 4. Autopilot Auto-Repair (Baseline)

Autopilot repair is **not implemented** in Phase 1. Treat effectiveness as
`0` until a later unlock exists. This avoids hidden healing and preserves
urgency.

---

## 5. Player Repair Actions (Phase 1)

## 5.1 Repair Verb

```text
REPAIR <STRUCTURE_ID>
```

Rules:

* Starts a timed repair task tracked in `active_repairs`.
* Progress advances on `WAIT` ticks.
* Reconstruction (`DESTROYED → OFFLINE`) is blocked during active assault.
* No location or resource gating yet.

---

## 5.2 Repair Transitions

| From      | To          | Allowed | Notes                     |
| --------- | ----------- | ------- | ------------------------- |
| DAMAGED   | OPERATIONAL | Yes     | Fast                      |
| OFFLINE   | DAMAGED     | Yes     | Slower                    |
| DESTROYED | OFFLINE     | Yes     | Costly, slow              |
| DESTROYED | OPERATIONAL | No      | Must pass through OFFLINE |

This enforces recovery cost without permanence.

---

## 6. Repairs During Assault

Repairs can be started during an active assault. Reconstruction
(`DESTROYED → OFFLINE`) is blocked while an assault is active.

---

## 7. Reconstruction Boundary

* **Repair** restores existing structures.
* **Reconstruction** (`DESTROYED → OFFLINE`) is allowed only when not under
  active assault.

---

## 8. Information Visibility (COMMS-Dependent)

Damage visibility follows **information degradation rules**.

## 8.1 Full COMMS

* Exact structure states visible
* Sector state accurate

## 8.2 Degraded COMMS

* Sector shows:

  * “ACTIVITY DETECTED”
  * “MULTIPLE FAILURES”
* Individual structure damage may be hidden

This makes post-assault triage meaningful.

---

## 9. When Is the World “Safe” Again?

Your clarification locks this cleanly:

* There is **no assault countdown**
* New major assaults are triggered by **expeditions**
* Therefore:

  * Player has time to repair
  * But repairing delays progress toward victory

This creates **strategic urgency**, not time pressure.

---

## 10. Player Experience Outcome (Validated)

After first assault, the player should see:

* Broken or degraded systems
* Reduced defensive capability
* Clear repair affordances
* No instant death spiral
* A strong “I need to fix this now” impulse

---
