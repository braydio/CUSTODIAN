CODEX: You should read this document, identify the logical decision factors and how best these would be implemented currently. Ensure all below specs are aligned with the current repo and implement them.

> How do we determine what actually happened during a live run — without guessing from logs — and without turning the game into a debug console?

You want:

* Deterministic introspection
* Developer trace visibility
* Optional player exposure
* No immersion break
* Minimal architecture drift

Let’s design this cleanly and implementable inside your current model.

---

# 🔴 PROBLEM REFRAME

Right now, when something catastrophic happens:

```
[ASSAULT] CRITICAL SYSTEM LOST. NO REPLACEMENT AVAILABLE.
```

You don’t have a structured explanation for:

* Which building was destroyed?
* Which calculation crossed threshold?
* Whether defense was applied?
* Whether defensibility was computed?
* What assault strength was?
* Why ARCHIVE was targeted?
* Why DEFENSE did not mitigate?
* Whether brownout had mechanical effect?

You need two layers:

1. **Internal Combat Ledger (always running)**
2. **Developer Assault Trace Mode (toggleable)**
3. Optional: **Player-Visible After-Action Summary**

These are separate concerns.

---

# 🧠 DESIGN DECISION

## What should be player-exposed?

### Player SHOULD see:

* Which building was destroyed
* What immediate consequence occurred
* Which sector was overrun
* Assault outcome

### Player SHOULD NOT see:

* Raw threat numbers
* Internal weighting
* Defensibility calculation
* Alertness values
* RNG rolls

### Developer SHOULD see:

* Full ledger
* Sector target weights
* Defense mitigation values
* Assault strength
* Defensibility score
* Failure cause chain

---

# 🟡 SOLUTION: ASSAULT LEDGER SYSTEM

We add a structured internal assault ledger that records every decision.

This does not change gameplay.

It makes it inspectable.

---

# 🏗 IMPLEMENTATION PLAN

---

# 1️⃣ Add Assault Ledger Object

Create new file:

```
game/simulations/world_state/core/assault_ledger.py
```

---

### Define Ledger

```python
from dataclasses import dataclass, field

@dataclass
class AssaultTickRecord:
    tick: int
    targeted_sector: str
    target_weight: float
    assault_strength: float
    defense_mitigation: float
    building_destroyed: str | None = None
    failure_triggered: bool = False

@dataclass
class AssaultLedger:
    active: bool = False
    ticks: list[AssaultTickRecord] = field(default_factory=list)
```

---

# 2️⃣ Attach Ledger to GameState

Modify:

```
core/state.py
```

Add:

```python
self.assault_ledger = AssaultLedger()
```

Add config flag:

```python
self.assault_trace_enabled = False
```

---

# 3️⃣ Record Assault Calculations Per Tick

Modify assault resolution file:

```
core/assault.py
```

Where targeting and damage are applied:

Add:

```python
if state.assault_trace_enabled:
    record = AssaultTickRecord(
        tick=state.time,
        targeted_sector=sector.id,
        target_weight=target_weight,
        assault_strength=current_assault_strength,
        defense_mitigation=defense_value,
        building_destroyed=destroyed_building_id,
        failure_triggered=state.campaign_failed
    )
    state.assault_ledger.ticks.append(record)
```

---

# 4️⃣ Add Dev Command: `assault_trace`

File:

```
terminal/commands/debug.py
```

Add:

```python
def cmd_assault_trace(state):
    state.assault_trace_enabled = not state.assault_trace_enabled
    return [f"ASSAULT TRACE = {state.assault_trace_enabled}"]
```

Register in processor under DEBUG mode only.

---

# 5️⃣ Add Dev Command: `assault_report`

```python
def cmd_assault_report(state):
    lines = []
    for record in state.assault_ledger.ticks[-10:]:
        lines.append(str(record))
    return lines
```

This prints structured recent ticks.

---

# 🟢 OPTIONAL: Player-Visible After Action Summary

After assault ends (not during):

Add:

```python
def generate_after_action_summary(state):
    last_records = state.assault_ledger.ticks
    destroyed = [r.building_destroyed for r in last_records if r.building_destroyed]

    lines = []
    lines.append("AFTER ACTION SUMMARY:")
    for d in destroyed:
        lines.append(f"- {d} DESTROYED")

    return lines
```

Surface only after assault ends.

---

# 🟣 Modify Failure Resolution

In:

```
core/assault.py
```

Replace direct:

```python
state.campaign_failed = True
```

With:

```python
if destroyed_building.class_type == "ARCHIVE_CORE":
    state.campaign_failed = True
    failure_reason = "ARCHIVE_DESTROYED"
```

Store failure reason:

```python
state.failure_reason = failure_reason
```

Log it in ledger.

---

# 🧩 How This Fits Current Model

You already have:

* Structured tick system
* Fidelity system
* Repair tick
* Assault tick
* Targeting function
* Debug prints

This fits cleanly because:

* It does not alter simulation
* It wraps decision points
* It records deterministic state
* It respects seed reproducibility

Zero architectural drift.

---

# 🔎 Now Let's Address Your Earlier Criticisms Properly

---

## Criticism 1 — Defense Not Mitigating

Add explicit mitigation logging.

Inside assault resolution:

```python
defense_value = compute_defense_output(state)
effective_strength = assault_strength - defense_value
```

Log both values in ledger.

Now you can see if defense was applied.

---

## Criticism 2 — Archive Target Lock

Log target weight per sector before selection:

Add:

```python
if state.assault_trace_enabled:
    state.last_target_weights = {
        s.id: compute_target_weight(state, s)
        for s in state.sectors
    }
```

Expose via `assault_report`.

---

## Criticism 3 — Brownout Was Narrative Only?

Instrument:

When brownout event triggers:

Log actual power modifier change in ledger.

---

# 🔐 Final Answer to Your Core Question

> Does this need to be player-exposed or hidden?

Answer:

* Internal calculation visibility → Hidden
* Assault report summary → Player optional
* Failure reason → Player visible
* Full ledger → Dev only

---

# 📦 Exact Files To Modify

| File                       | Change                                              |
| -------------------------- | --------------------------------------------------- |
| core/state.py              | Add AssaultLedger + flags                           |
| core/assault.py            | Insert logging at targeting + destruction + failure |
| core/targeting.py          | Optional weight logging                             |
| terminal/commands/debug.py | Add assault_trace + assault_report                  |
| terminal/processor.py      | Register debug commands                             |

---

# 🧠 Why This Is Necessary

You are transitioning into:

* Deterministic simulation
* Strategic interaction
* Layered targeting
* Autonomous mitigation

Without ledger instrumentation:

You are debugging blind.

With it:

* You can inspect every decision.
* You can replay via seed.
* You can refine weighting safely.
* You can confirm defense effectiveness.
* You can confirm failure chain.

---

If you want next:

I can now:

* Spec defense mitigation formula tuning
* Or spec nonlinear alertness growth
* Or refactor assault from linear escalation to staged objective capture
* Or design memory-based enemy learning

You’re at the correct depth now.





BELOW THIS LINE IS LIKELY ALREADY LIVE IN THE CURRENT CODE. Codex MAY STOP HERE.
---

# ASSAULT Misc Design (To be turned into Live-Aligned Implementation Spec by Codex)

Below is a **complete, repo-aware patch plan** based on:

* The current live codebase (timer-based assaults still active) (Codex to validate and fix as needed)
* Existing player traversal + materials + repair systems
* Locked decisions:

  * N/S ingress
  * 2 ticks per edge
  * WAIT = 5 ticks
  * Target based on threat + profile
  * Salvage enabled
  * Cap starts at 1 (tutorial)
  * Nondeterministic warnings

---

# OVERVIEW: WHAT THIS PATCH SET DOES

It:

1. Adds spatial assault routing
2. Replaces timer-driven assault spawning
3. Introduces AssaultApproach entity
4. Moves assaults per tick via graph
5. Integrates salvage
6. Hooks ETA into STATUS
7. Preserves existing tactical resolution
8. Leaves repair + field systems intact

---

# PATCH PLAN — ORDERED IMPLEMENTATION

Apply in this order.

---

# STEP 1 — Extend Config for Enemy Graph

### File: `core/config.py`

You already have player `TRAVEL_GRAPH`.
We will extend it to be canonical for both player and enemy.

Add:

```python
# ------------------------------
# ENEMY ASSAULT ROUTING
# ------------------------------

INGRESS_N = "INGRESS_N"
INGRESS_S = "INGRESS_S"

WORLD_GRAPH = {
    INGRESS_N: ["T_NORTH"],
    INGRESS_S: ["T_SOUTH"],

    "T_NORTH": [INGRESS_N, "COMMAND"],
    "T_SOUTH": [INGRESS_S, "COMMAND"],

    "COMMAND": ["T_NORTH", "T_SOUTH", "POWER", "FABRICATION"],

    "POWER": ["COMMAND"],
    "FABRICATION": ["COMMAND"],
    "DEFENSE GRID": ["T_SOUTH"],
    "ARCHIVE": ["T_NORTH"],
}

EDGE_TRAVEL_TICKS = 2

MAX_ACTIVE_ASSAULTS_TUTORIAL = 1
```

⚠ Important:

* Use actual sector names from `SECTOR_DEFS`
* Ensure names match exactly

---

# STEP 2 — Add AssaultApproach Entity

### File: `core/assaults.py`

Add at top:

```python
from uuid import uuid4
from collections import deque
from .config import WORLD_GRAPH, EDGE_TRAVEL_TICKS, MAX_ACTIVE_ASSAULTS_TUTORIAL
```

Add class:

```python
class AssaultApproach:
    def __init__(self, ingress, target):
        self.id = str(uuid4())
        self.ingress = ingress
        self.target = target
        self.route = compute_route(ingress, target)
        self.index = 0
        self.ticks_to_next = EDGE_TRAVEL_TICKS
        self.state = "APPROACHING"  # APPROACHING, ENGAGED
```

---

# STEP 3 — Add BFS Routing

Same file:

```python
def compute_route(start, goal):
    visited = set()
    queue = deque([[start]])

    while queue:
        path = queue.popleft()
        node = path[-1]

        if node == goal:
            return path

        if node not in visited:
            visited.add(node)
            for neighbor in WORLD_GRAPH.get(node, []):
                queue.append(path + [neighbor])

    return []
```

---

# STEP 4 — Modify GameState

### File: `core/state.py`

Add:

```python
self.assaults = []
self.materials = 0
```

Remove:

```python
self.assault_timer
```

Do NOT remove immediately from code usage yet. That comes next.

---

# STEP 5 — Replace Timer-Based Spawn

### File: `core/assaults.py`

Remove:

* `tick_assault_timer`
* `start_assault` timer triggers

Add:

```python
def maybe_spawn_assault(state):
    if len(state.assaults) >= MAX_ACTIVE_ASSAULTS_TUTORIAL:
        return

    if state.ambient_threat > 1.5:
        ingress = random.choice(["INGRESS_N", "INGRESS_S"])
        target = choose_target_sector(state)  # reuse existing logic
        assault = AssaultApproach(ingress, target)
        state.assaults.append(assault)
```

---

# STEP 6 — Assault Advancement per Tick

### File: `core/simulation.py`

Inside tick loop (after time advances):

```python
advance_assaults(state)
maybe_spawn_assault(state)
```

---

# STEP 7 — Implement advance_assaults

### File: `core/assaults.py`

Add:

```python
def advance_assaults(state):
    resolved = []

    for assault in state.assaults:
        if assault.state != "APPROACHING":
            continue

        assault.ticks_to_next -= 1

        if assault.ticks_to_next <= 0:
            assault.index += 1

            if assault.index >= len(assault.route) - 1:
                assault.state = "ENGAGED"
            else:
                assault.ticks_to_next = EDGE_TRAVEL_TICKS

        current_node = assault.route[assault.index]

        if current_node in {"T_NORTH", "T_SOUTH"}:
            maybe_warn(state)

    for assault in state.assaults:
        if assault.state == "ENGAGED":
            outcome = resolve_tactical_assault(state, assault.target)
            award_salvage(state, outcome)
            resolved.append(assault)

    for a in resolved:
        state.assaults.remove(a)
```

---

# STEP 8 — Warning Logic

Add:

```python
def maybe_warn(state):
    ci = getattr(state, "comms_integrity", 1.0)
    chance = 0.8 if ci > 0.5 else 0.4
    if random.random() < chance:
        print("[ALERT] HOSTILES APPROACHING.")
    else:
        print("[SIGNAL INTERFERENCE DETECTED.]")
```

---

# STEP 9 — Salvage Integration

### File: `core/assaults.py`

Add:

```python
def award_salvage(state, outcome):
    penetration = outcome.penetration

    if penetration == "none":
        return
    elif penetration == "light":
        state.materials += 1
    elif penetration == "medium":
        state.materials += 2
    elif penetration == "heavy":
        state.materials += 3
```

Ensure this matches your outcome enum.

---

# STEP 10 — STATUS Update

### File: `terminal/commands/status.py`

Inside COMMAND-mode branch:

```python
for assault in state.assaults:
    remaining = len(assault.route) - assault.index
    eta = remaining * EDGE_TRAVEL_TICKS
    lines.append(f"THREAT: {assault.target} ETA~{eta}")
```

Hide or obfuscate in field mode.

---

# STEP 11 — Remove Timer Everywhere

Search for:

```
assault_timer
tick_assault_timer
warning_window
```

Remove or stub out safely.

This is critical.

---

# FINAL STATE AFTER PATCH

You will have:

* Spatial assault routing
* Transit nodes used by enemies
* Assault cap enforced
* Salvage economy integrated
* ETA visible in command
* Warnings nondeterministic
* WAIT (5 ticks) interacts cleanly with 2-tick edges
* No regression to tactical combat

---

# ROBUSTNESS CHECKLIST

After implementation:

* Assault spawns at ingress
* Moves 2 ticks per edge
* Reaches perimeter
* Engages tactical resolution
* Salvage awarded
* Materials visible
* Multiple assaults prevented in tutorial
* STATUS displays ETA
* No crash when no route found

