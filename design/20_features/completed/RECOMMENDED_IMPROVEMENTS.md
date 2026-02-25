
Below is a **structured implementation spec** aligned to your repo layout (`game/simulations/world_state/...`, terminal server, etc.).

I will cover:

1. Priority 1 (Robustness) — exact code placement + diffs
2. Priority 2 (Modularity) — extraction plan with safe ordering
3. Priority 3 (Accessibility) — concrete UI file changes
4. Priority 4 (Engagement) — deterministic telemetry design
5. Test expansion — concrete test file names and assertions

No fluff.

---

# 🔴 PRIORITY 1 — ROBUSTNESS

---

## 1. Deterministic Simulation Seeds

### Goal

* Reproducible bug reports
* Replayable sessions

---

## Files To Modify

### 1️⃣ `core/state.py`

Add seed field:

```python
import random

class GameState:
    def __init__(self, seed: int | None = None):
        self.seed = seed if seed is not None else random.randrange(0, 2**32)
        self.rng = random.Random(self.seed)
```

Replace all `random.` usage in simulation with:

```python
state.rng.<method>()
```

Do NOT use global random.

---

### 2️⃣ `server/startup.py` (or wherever state is created)

Add optional seed param:

```python
seed = payload.get("seed")  # from session bootstrap
state = GameState(seed=seed)
```

---

### 3️⃣ `STATUS` FULL fidelity only

In `terminal/commands/status.py`:

```python
if state.fidelity == "FULL":
    lines.append(f"SEED: {state.seed}")
```

Never display seed below FULL.

---

## 2. Command Idempotency Guards

### Goal

Duplicate POST should not duplicate command.

---

## Files

### 1️⃣ `server/command_handler.py`

Modify handler:

```python
# short-lived replay cache
COMMAND_CACHE = {}  # command_id -> result

def handle_command(payload):
    cmd_id = payload.get("command_id")
    if cmd_id and cmd_id in COMMAND_CACHE:
        return COMMAND_CACHE[cmd_id]

    result = process_command(payload)

    if cmd_id:
        COMMAND_CACHE[cmd_id] = result

    return result
```

Add eviction (simple time-based or size cap 100 entries).

---

## 3. Repair/Task Invariant Validator

Centralize validation.

---

### New File:

`core/invariants.py`

```python
def validate_state_invariants(state):
    # at most one active task
    if state.active_task and state.active_repair:
        raise AssertionError("Task and repair active simultaneously.")

    # field_action reflects reality
    if state.active_repair and state.field_action != "REPAIRING":
        raise AssertionError("field_action mismatch.")

    # command mode implies location COMMAND
    if state.player_mode == "COMMAND" and state.player_location != "COMMAND":
        raise AssertionError("COMMAND mode but not in COMMAND sector.")
```

---

### Wire into `step_world(...)`

At end of tick:

```python
validate_state_invariants(state)
```

Also call inside command processor after command mutation.

---

## 4. Snapshot Versioning

---

### Modify snapshot builder

In `state.snapshot()`:

```python
return {
    "snapshot_version": 2,
    ...
}
```

---

### Add Migration Layer

New file:
`core/snapshot_migration.py`

```python
def migrate_snapshot(snapshot: dict) -> dict:
    version = snapshot.get("snapshot_version", 1)

    if version == 1:
        snapshot["player_mode"] = "COMMAND"
        snapshot["snapshot_version"] = 2

    return snapshot
```

Call this during load.

---

## 5. Endpoint Parity

---

### Create shared serializer module

New file:
`server/contracts.py`

```python
def serialize_response(lines: list[str]):
    return {
        "ok": True,
        "text": "\n".join(lines),
        "lines": lines,
    }
```

Both simulation server and UI server must import this.

Remove duplicate serializers.

---

# 🟠 PRIORITY 2 — MODULARITY

---

## 1. Authority Extraction

New file:

`terminal/authority.py`

```python
POLICY = {
    "COMMAND": {"REPAIR", "DEPLOY", "WAIT", "SCAVENGE"},
    "FIELD": {"MOVE", "LOCAL_REPAIR", "RETURN"},
}

def is_allowed(state, command):
    allowed = POLICY.get(state.player_mode, set())
    return command in allowed
```

Processor now calls:

```python
if not is_allowed(state, cmd):
    return ["COMMAND NOT AVAILABLE IN CURRENT MODE."]
```

Remove gating logic from handlers.

---

## 2. Presence Extraction

New file:

`core/presence.py`

```python
def start_move_task(state, destination):
    state.active_task = {
        "type": "MOVE",
        "destination": destination,
        "progress": 0,
    }

def tick_presence(state):
    if not state.active_task:
        return

    if state.active_task["type"] == "MOVE":
        state.active_task["progress"] += 1
        if state.active_task["progress"] >= 3:
            state.player_location = state.active_task["destination"]
            state.active_task = None
```

Remove movement logic from WAIT helper.

---

## 3. Typed Task Dataclasses

Replace loose dicts.

New file:

`core/tasks.py`

```python
from dataclasses import dataclass

@dataclass
class MoveTask:
    destination: str
    progress: int = 0

@dataclass
class RepairTask:
    structure_id: str
    ticks_remaining: int
```

Replace `state.active_task` and `state.active_repair` with typed objects.

---

## 4. Location Registry

New file:

`core/location_registry.py`

```python
class LocationRegistry:
    def __init__(self):
        self._aliases = {}

    def register(self, canonical, aliases):
        for alias in aliases:
            self._aliases[alias.upper()] = canonical

    def normalize(self, name):
        return self._aliases.get(name.upper(), name.upper())
```

All commands must call:

```python
dest = registry.normalize(user_input)
```

---

## 5. Message Catalog

New file:

`terminal/messages.py`

```python
MESSAGES = {
    "REPAIR_STARTED": "[MAINTENANCE INITIATED] {target}",
    "FIDELITY_UP": "[EVENT] SIGNAL CLARITY RESTORED",
}
```

Handlers now format from catalog instead of inline strings.

---

# 🟡 PRIORITY 3 — ACCESSIBILITY

UI layer changes only.

---

## 1. Reduced Motion

In CSS:

```css
@media (prefers-reduced-motion: reduce) {
  .flash {
    animation: none;
  }
}
```

---

## 2. Screen Reader Output

Wrap terminal output in:

```html
<div aria-live="polite" id="terminal-output"></div>
```

Append short summary line:

```js
ariaLive.textContent = "Command executed.";
```

---

## 3. Contrast Improvements

Adjust warning class:

```css
.warning {
  color: #ff3b3b;
}
```

Test with WCAG AA contrast.

---

## 4. Keyboard History

Add JS:

```js
let history = [];
let index = -1;

input.addEventListener("keydown", (e) => {
  if (e.key === "ArrowUp") {
    index = Math.max(0, index - 1);
    input.value = history[index];
  }
});
```

---

## 5. Offline Banner

Add fetch failure counter:

```js
if (failures > 3) {
  showOfflineBanner();
}
```

---

# 🟢 PRIORITY 4 — ENGAGEMENT

---

## 1. Post-Action Telemetry

Modify WAIT/SCAVENGE/REPAIR handlers:

Append one factual delta:

```python
delta = compute_damage_delta(prev_state, state)
lines.append(f"[DELTA] DAMAGE SHIFT: {delta}")
```

No strategy hints.

---

## 2. Transit Ambient Tags

In `presence.py`, when entering node:

```python
if state.fidelity == "FULL":
    state.last_tick_events.append("[EVENT] POWER HUM DETECTED")
```

Lower fidelity randomizes tag clarity.

---

## 3. Milestones

New file:

`core/milestones.py`

```python
def check_milestones(state):
    if state.stats["field_repairs"] == 1:
        state.log.append("FIRST FIELD REPAIR COMPLETE")
```

Call inside tick.

---

## 4. Persistent Logbook

Maintain:

```python
state.operator_log: list[str]
```

Append major events there.

Expose via `/snapshot`.

---

## 5. Sector Role Glyphs

Map static mapping:

```python
SECTOR_GLYPHS = {
    "COMMAND": "CM",
    "POWER": "PW",
}
```

Expose in snapshot.

UI renders glyph overlay.

---

# 🧪 TEST EXPANSION

Create new files:

```
tests/test_presence_flow.py
tests/test_snapshot_contract.py
tests/test_endpoint_contract.py
tests/test_travel_graph_properties.py
```

Example property-based test:

```python
def test_no_unreachable_nodes(graph):
    for node in graph.nodes:
        assert graph.reachable("COMMAND", node)
```

---

# 🔒 Final Notes

You now have:

* Deterministic seeds
* Idempotent commands
* Invariant enforcement
* Versioned snapshots
* Modular presence system
* Authority isolation
* Accessibility compliance
* Engagement telemetry
* Test hardening


