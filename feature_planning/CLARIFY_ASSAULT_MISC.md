

# CODEX IMPLEMENTATION DIRECTIVE

## Assault Introspection, Ledger Instrumentation, and Spatial Assault Routing

You must read this entire document, identify the logical decision factors, and implement them in alignment with the current repository architecture.

Do not reinterpret scope.
Do not simplify.
Ensure compatibility with the existing world tick system, fidelity model, repair flow, and assault mechanics.

---

# OBJECTIVE

We need to answer:

> How do we determine what actually happened during a live run — without guessing from logs — and without turning the game into a debug console?

We require:

* Deterministic introspection
* Developer trace visibility
* Optional player exposure
* No immersion break
* Minimal architecture drift

The system must remain seed-reproducible and not alter gameplay logic.

---

# DESIGN LAYERS

We introduce three structured layers:

1. **Internal Assault Ledger (always active storage)**
2. **Developer Assault Trace Mode (toggleable visibility)**
3. **Optional Player After-Action Summary**

These are separate concerns.

---

# PLAYER VS DEV VISIBILITY

## Player SHOULD see:

* Which building was destroyed
* Immediate consequences
* Which sector was overrun
* Assault outcome
* Archive failure explicitly

## Player SHOULD NOT see:

* Raw threat numbers
* Target weighting
* Defensibility calculations
* Alertness scalars
* RNG rolls

## Developer SHOULD see:

* Full ledger entries
* Sector weight table
* Defense mitigation values
* Assault strength per tick
* Defensibility score
* Failure cause chain

---

# PART 1 — ASSAULT LEDGER SYSTEM

## File: `core/assault_ledger.py`

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

## Modify: `core/state.py`

Add to `GameState.__init__`:

```python
from .assault_ledger import AssaultLedger

self.assault_ledger = AssaultLedger()
self.assault_trace_enabled = False
self.failure_reason = None
```

---

## Modify: `core/assault.py`

Inside assault resolution, after target selection and defense mitigation:

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

## Failure Handling Adjustment

Replace:

```python
state.campaign_failed = True
```

With:

```python
if destroyed_building.class_type == "ARCHIVE_CORE":
    state.campaign_failed = True
    state.failure_reason = "ARCHIVE_DESTROYED"
```

Log this in ledger.

---

## Developer Commands

### File: `terminal/commands/debug.py`

```python
def cmd_assault_trace(state):
    state.assault_trace_enabled = not state.assault_trace_enabled
    return [f"ASSAULT TRACE = {state.assault_trace_enabled}"]

def cmd_assault_report(state):
    lines = []
    for record in state.assault_ledger.ticks[-20:]:
        lines.append(str(record))
    return lines
```

Register in processor under DEBUG context.

---

# PART 2 — ASSAULT ROUTING (REPLACES TIMER MODEL)

We eliminate timer-only assault spawning and introduce spatial routing.

---

## File: `core/config.py`

Add:

```python
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

---

## File: `core/assaults.py`

Add routing class:

```python
from uuid import uuid4
from collections import deque
from .config import WORLD_GRAPH, EDGE_TRAVEL_TICKS, MAX_ACTIVE_ASSAULTS_TUTORIAL

class AssaultApproach:
    def __init__(self, ingress, target):
        self.id = str(uuid4())
        self.ingress = ingress
        self.target = target
        self.route = compute_route(ingress, target)
        self.index = 0
        self.ticks_to_next = EDGE_TRAVEL_TICKS
        self.state = "APPROACHING"
```

---

### BFS Route

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

## Modify: `core/state.py`

Add:

```python
self.assaults = []
```

Remove legacy `assault_timer`.

---

## Modify: `core/assaults.py`

Add spawn logic:

```python
def maybe_spawn_assault(state):
    if len(state.assaults) >= MAX_ACTIVE_ASSAULTS_TUTORIAL:
        return

    if state.ambient_threat > 1.5:
        ingress = state.rng.choice(["INGRESS_N", "INGRESS_S"])
        target = choose_target_sector(state)
        state.assaults.append(AssaultApproach(ingress, target))
```

---

## Modify: `core/simulation.py`

Inside tick:

```python
advance_assaults(state)
maybe_spawn_assault(state)
```

---

## Add `advance_assaults`

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

## Warning Logic

```python
def maybe_warn(state):
    ci = getattr(state, "comms_integrity", 1.0)
    chance = 0.8 if ci > 0.5 else 0.4
    if state.rng.random() < chance:
        state.last_tick_events.append("[ALERT] HOSTILES APPROACHING.")
    else:
        state.last_tick_events.append("[SIGNAL INTERFERENCE DETECTED.]")
```

---

## Salvage

```python
def award_salvage(state, outcome):
    penetration = outcome.penetration

    if penetration == "light":
        state.materials += 1
    elif penetration == "medium":
        state.materials += 2
    elif penetration == "heavy":
        state.materials += 3
```

---

## STATUS ETA

Modify `terminal/commands/status.py`:

```python
for assault in state.assaults:
    remaining = len(assault.route) - assault.index
    eta = remaining * EDGE_TRAVEL_TICKS
    lines.append(f"THREAT: {assault.target} ETA~{eta}")
```

Hide in field mode.

---

# PART 3 — DEFENSE & MITIGATION LOGGING

In assault resolution:

```python
defense_value = compute_defense_output(state)
effective_strength = assault_strength - defense_value
```

Log both values in ledger when trace enabled.

---

# PART 4 — BROWNOUT INSTRUMENTATION

When brownout event triggers, log:

```python
if state.assault_trace_enabled:
    state.assault_ledger.ticks.append(
        AssaultTickRecord(
            tick=state.time,
            targeted_sector="POWER",
            target_weight=0,
            assault_strength=0,
            defense_mitigation=0,
            building_destroyed=None,
            failure_triggered=False
        )
    )
```

Also log actual power modifier delta.

---

# FINAL ROBUSTNESS CHECKLIST

After implementation:

* Assaults spawn at ingress
* Travel 2 ticks per edge
* Warn nondeterministically
* Reach target and resolve
* Salvage awarded
* ETA visible
* Archive destruction triggers campaign failure
* Defensibility used when Custodian downed
* Ledger records every decision
* `assault_trace` toggles instrumentation
* `assault_report` prints structured output
* No regression in repair or fidelity systems

---

# WHY THIS FITS THE CURRENT MODEL

* Uses existing tick loop
* Uses existing targeting
* Uses existing RNG seed
* Does not change game logic
* Adds structured introspection
* Replaces timer with graph routing cleanly
* Preserves tutorial cap of 1 active assault
* Maintains deterministic replay

---

# CONCLUSION

Without ledger instrumentation, you are debugging blind.

With this system:

* You can inspect every decision
* Replay via seed
* Validate mitigation
* Confirm failure chain
* Refine targeting safely
* Maintain immersion for players

---

If needed next:

* Defense mitigation formula tuning
* Nonlinear alertness growth
* Multi-objective assault staging
* Faction memory learning

This is now a hardened strategic infrastructure assault system aligned to your repo.
