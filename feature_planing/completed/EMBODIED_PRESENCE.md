No diffs yet — this is the final design pass before code.

---

# PHASE A — EMBODIED PRESENCE (REVISED DESIGN)

This revision incorporates **physical repair constraints**, **travel buffer sectors**, and **future downed-state compatibility** without adding combat yet.

---

## 0. Design Throughline (Reaffirmed)

> **The Command Center is powerful but slow.
> The Field is fast but blind and dangerous.
> Some things can only be fixed by a human being standing there.**

Everything below serves that.

---

## 1. Player Presence State Machine (Unchanged Core)

### 1.1 Canonical Player State

```
(player_mode, player_location)
```

* `player_mode ∈ {COMMAND, FIELD}`
* `player_location ∈ {COMMAND_CENTER | SECTOR_ID | TRANSIT_NODE}`

No new flags.
No exceptions.

---

## 2. Structure Repair Authority (Key Change)

### 2.1 Repair Classes (Locked)

Structures now fall into **two repair authority classes**:

| Structure State | Remote Repair (Command) | Local Repair (Field) |
| --------------- | ----------------------- | -------------------- |
| DAMAGED         | ✅ Yes (slow)            | ✅ Yes (fast)         |
| OFFLINE         | ❌ No                    | ✅ Yes                |
| DESTROYED       | ❌ No                    | ✅ Yes                |
| OPERATIONAL     | ❌                       | ❌                    |

This is **excellent design**. It creates:

* a reason to leave command
* a reason to delay repairs
* escalating pressure

---

### 2.2 Remote Repairs (Command Mode)

* Allowed only for `DAMAGED` structures
* Consume:

  * more ticks
  * more resources
* Are less efficient
* Represent automation / drones / jury-rigged systems

Remote repair is **never sufficient for collapse recovery**.

---

### 2.3 Local Repairs (Field Mode)

* Required for:

  * OFFLINE → DAMAGED
  * DESTROYED → OFFLINE
* Faster
* Riskier
* Block player actions

This becomes the **spine of on-foot gameplay**.

---

## 3. FIELD MODE Action States (Clarified)

While in FIELD MODE, the player is in exactly one:

* **IDLE**
* **MOVING**
* **REPAIRING**
* **DOWNED** *(future, not Phase A)*

### Phase A Lock:

* `DOWNED` exists conceptually but is unreachable
* No code paths yet

This avoids future refactors.

---

## 4. Tick Costs (Revised & Locked)

### 4.1 Travel Costs

| Action                                | Cost    |
| ------------------------------------- | ------- |
| DEPLOY (COMMAND → first transit node) | 2 ticks |
| MOVE (node → node)                    | 1 tick  |
| MOVE (node → sector)                  | 1 tick  |
| RETURN (sector → COMMAND_CENTER)      | 2 ticks |

---

### 4.2 Repair Costs (Revised)

| Repair                | Mode       | Cost    |
| --------------------- | ---------- | ------- |
| DAMAGED → OPERATIONAL | COMMAND    | 4 ticks |
| DAMAGED → OPERATIONAL | FIELD      | 2 ticks |
| OFFLINE → DAMAGED     | FIELD only | 4 ticks |
| DESTROYED → OFFLINE   | FIELD only | 6 ticks |

This makes:

* remote repair viable but inefficient
* field repair urgent and meaningful

---

## 5. Travel Graph with Transit / Buffer Sectors (New)

This is a **very strong idea** and fits both enemies and player.

### 5.1 Concept

Add **TRANSIT SECTORS**:

* corridors
* access tunnels
* maintenance ways
* exterior approaches

They serve as:

* buffers for enemy movement
* travel space for the player
* places where bad things can happen later

---

### 5.2 Phase A Graph (Canonical)

```
        ARCHIVE
           |
        [TRANSIT]
           |
POWER — COMMAND — FAB
           |
        [TRANSIT]
           |
        DEFENSE
```

Formalized:

```python
TRAVEL_GRAPH = {
    "COMMAND": ["T_NORTH", "T_SOUTH"],
    "T_NORTH": ["COMMAND", "ARCHIVE"],
    "T_SOUTH": ["COMMAND", "DEFENSE"],
    "POWER": ["COMMAND"],
    "FAB": ["COMMAND"],
    "ARCHIVE": ["T_NORTH"],
    "DEFENSE": ["T_SOUTH"],
}
```

Rules:

* Transit nodes are real locations
* They take time to cross
* They can later host:

  * ambushes
  * environmental hazards
  * partial information leaks

This is future-proof and **excellent**.

---

## 6. Command Surface (Revised)

### 6.1 COMMAND MODE

Allowed:

* All strategic commands
* Remote repair (DAMAGED only)
* Fabrication (later)

---

### 6.2 FIELD MODE

Allowed:

* `MOVE <NODE|SECTOR>`
* `REPAIR <STRUCTURE>`
* `WAIT`
* `RETURN`
* `STATUS` (local)

Denied:

* posture changes
* remote repairs
* fabrication
* recon

Denial message remains canonical.

---

## 7. Information Degradation (Reinforced)

### FIELD MODE STATUS shows:

* Current location (sector or transit)
* Local structure states
* Current task progress

### FIELD MODE STATUS hides:

* global threat
* assault timers
* other sectors
* enemy counts

This keeps command valuable.

---

## 8. Assault Interaction & Downed State (Future-Compatible)

### 8.1 Phase A Behavior

If an assault begins while the player is in FIELD MODE:

* Player receives a **delayed warning**
* Player cannot influence command-level responses
* Repairs continue unless interrupted by future systems

---

### 8.2 Future: Player Downed (Not Implemented Yet)

Design lock now (important):

> If the player is **downed during an assault**,
> **they do not die**,
> and the system must finish the assault **without them**.

Implications:

* Autopilot must be sufficient (even if bad)
* Player absence becomes a real failure amplifier
* No “reload last checkpoint” gameplay

We **do not implement this yet**, but we **design for it now**.

---

## 9. Failure Safety (Updated)

Phase A still guarantees:

* no permanent loss
* no player death
* no softlocks

But it introduces:

* missed repairs
* degraded systems
* worse assault outcomes

Pressure, not punishment.

---

## 10. Updated Phase A Exit Criteria

Phase A is complete when:

1. Some repairs are impossible without physical presence
2. Remote repair feels inferior but tempting
3. Travel takes time and creates commitment
4. Transit nodes exist and matter
5. Being away during an assault feels dangerous
6. The Command Center is still the strategic heart
7. The game no longer feels like a text sim

---

## Where we are now

This design is **coherent, scoped, and code-ready**.

Nothing here contradicts:

* your authority model
* your terminal-first spine
* your assault architecture
* your future combat plans

---

## Next step (choose one)

1. **Proceed to exact diffs** (GameState, config, commands, STATUS, tests)
2. Define **remote vs local repair UX wording**
3. Design **enemy movement through transit nodes**
4. Lock **assault warning delays when player is in field**


# Two parts, exactly as requested:

1. **Exact diffs** to implement Phase A (FIELD MODE, travel graph, local vs remote repair)
2. **Remote vs local repair wording** (operator-facing, contract-safe)

I’ll keep diffs tight and scoped to your repo conventions.

---

# PART 1 — EXACT DIFFS (PHASE A)

> Scope covered:
>
> * player_mode + player_location
> * travel graph + tick costs
> * DEPLOY / MOVE / RETURN
> * FIELD vs COMMAND authority
> * local vs remote repair rules
> * STATUS branching (command vs field)
> * no combat, no downed logic (but future-safe)

---

## 1) Core config: travel graph + tick costs

### `game/simulations/world_state/core/config.py`

```diff
+ # =========================
+ # FIELD MODE / TRAVEL
+ # =========================
+
+ PLAYER_MODE_COMMAND = "COMMAND"
+ PLAYER_MODE_FIELD = "FIELD"
+
+ COMMAND_CENTER = "COMMAND"
+
+ # Transit nodes act as buffers for player/enemy movement
+ TRANSIT_NODES = {"T_NORTH", "T_SOUTH"}
+
+ TRAVEL_GRAPH = {
+     "COMMAND": ["T_NORTH", "T_SOUTH"],
+     "T_NORTH": ["COMMAND", "ARCHIVE"],
+     "T_SOUTH": ["COMMAND", "DEFENSE"],
+     "ARCHIVE": ["T_NORTH"],
+     "DEFENSE": ["T_SOUTH"],
+     "POWER": ["COMMAND"],
+     "FAB": ["COMMAND"],
+ }
+
+ DEPLOY_TICKS = 2
+ MOVE_TICKS = 1
+ RETURN_TICKS = 2
+
+ # =========================
+ # REPAIR COSTS
+ # =========================
+
+ REMOTE_REPAIR_TICKS = {
+     "DAMAGED": 4,
+ }
+
+ LOCAL_REPAIR_TICKS = {
+     "DAMAGED": 2,
+     "OFFLINE": 4,
+     "DESTROYED": 6,
+ }
```

---

## 2) GameState: player presence + active task

### `game/simulations/world_state/core/state.py`

```diff
@@
     def __init__(self):
         ...
+        # Player presence
+        self.player_mode = PLAYER_MODE_COMMAND
+        self.player_location = COMMAND_CENTER
+
+        # Field task (movement / repair)
+        self.active_task = None  # dict or None
```

Add helpers (near bottom of file):

```diff
+    def in_command(self) -> bool:
+        return self.player_mode == PLAYER_MODE_COMMAND
+
+    def in_field(self) -> bool:
+        return self.player_mode == PLAYER_MODE_FIELD
```

---

## 3) Field task ticking (movement + repair)

### `game/simulations/world_state/core/simulation.py`

Locate your tick loop (inside `step_world` or equivalent) and add:

```diff
+    # Advance field task if present
+    if state.active_task:
+        state.active_task["ticks"] -= 1
+
+        if state.active_task["ticks"] <= 0:
+            task = state.active_task
+
+            if task["type"] == "MOVE":
+                state.player_location = task["target"]
+
+            elif task["type"] == "REPAIR":
+                structure = state.structures[task["structure_id"]]
+                structure.advance_repair()
+
+            state.active_task = None
```

This keeps **all progression time-based**, not command-based.

---

## 4) DEPLOY / MOVE / RETURN commands

### New file: `game/simulations/world_state/terminal/commands/deploy.py`

```python
from game.simulations.world_state.core.config import (
    PLAYER_MODE_FIELD, COMMAND_CENTER,
    DEPLOY_TICKS, TRAVEL_GRAPH,
)

def cmd_deploy(state, sector_id):
    if state.in_major_assault:
        return ["DEPLOYMENT BLOCKED. ASSAULT ACTIVE."]

    if state.player_mode != "COMMAND":
        return ["ALREADY DEPLOYED."]

    if sector_id not in TRAVEL_GRAPH[COMMAND_CENTER]:
        return ["INVALID DEPLOYMENT TARGET."]

    state.player_mode = PLAYER_MODE_FIELD
    state.active_task = {
        "type": "MOVE",
        "target": sector_id,
        "ticks": DEPLOY_TICKS,
    }
    return [f"DEPLOYING TO {sector_id}."]
```

---

### New file: `terminal/commands/move.py`

```python
from game.simulations.world_state.core.config import MOVE_TICKS, TRAVEL_GRAPH

def cmd_move(state, target):
    if not state.in_field():
        return ["COMMAND CENTER REQUIRED."]

    if state.active_task:
        return ["ACTION IN PROGRESS."]

    here = state.player_location
    if target not in TRAVEL_GRAPH.get(here, []):
        return ["INVALID ROUTE."]

    state.active_task = {
        "type": "MOVE",
        "target": target,
        "ticks": MOVE_TICKS,
    }
    return [f"MOVING TO {target}."]
```

---

### New file: `terminal/commands/return_cmd.py`

```python
from game.simulations.world_state.core.config import (
    PLAYER_MODE_COMMAND, COMMAND_CENTER, RETURN_TICKS
)

def cmd_return(state):
    if not state.in_field():
        return ["ALREADY IN COMMAND."]

    if state.active_task:
        return ["ACTION IN PROGRESS."]

    state.active_task = {
        "type": "MOVE",
        "target": COMMAND_CENTER,
        "ticks": RETURN_TICKS,
    }
    state.player_mode = PLAYER_MODE_COMMAND
    return ["RETURNING TO COMMAND CENTER."]
```

---

## 5) Repair rules: local vs remote

### `game/simulations/world_state/core/structures.py`

Add helper:

```diff
+    def advance_repair(self):
+        if self.state == StructureState.DESTROYED:
+            self.state = StructureState.OFFLINE
+        elif self.state == StructureState.OFFLINE:
+            self.state = StructureState.DAMAGED
+        elif self.state == StructureState.DAMAGED:
+            self.state = StructureState.OPERATIONAL
```

---

### `terminal/commands/repair.py`

```python
from game.simulations.world_state.core.config import (
    LOCAL_REPAIR_TICKS, REMOTE_REPAIR_TICKS
)

def cmd_repair(state, structure_id):
    structure = state.structures.get(structure_id)
    if not structure:
        return ["UNKNOWN STRUCTURE."]

    if state.active_task:
        return ["ACTION IN PROGRESS."]

    # Local (field) repair
    if state.in_field():
        if structure.sector != state.player_location:
            return ["STRUCTURE NOT IN SECTOR."]
        ticks = LOCAL_REPAIR_TICKS.get(structure.state.value)
        if ticks is None:
            return ["NO REPAIR REQUIRED."]
        state.active_task = {
            "type": "REPAIR",
            "structure_id": structure_id,
            "ticks": ticks,
        }
        return [f"MANUAL REPAIR STARTED: {structure.name}."]

    # Remote (command) repair
    if structure.state.value not in REMOTE_REPAIR_TICKS:
        return ["REMOTE REPAIR NOT POSSIBLE."]

    ticks = REMOTE_REPAIR_TICKS[structure.state.value]
    state.active_task = {
        "type": "REPAIR",
        "structure_id": structure_id,
        "ticks": ticks,
    }
    return [f"REMOTE REPAIR QUEUED: {structure.name}."]
```

---

## 6) Processor wiring

### `terminal/processor.py`

Add imports + handlers:

```diff
+ from game.simulations.world_state.terminal.commands.deploy import cmd_deploy
+ from game.simulations.world_state.terminal.commands.move import cmd_move
+ from game.simulations.world_state.terminal.commands.return_cmd import cmd_return
+ from game.simulations.world_state.terminal.commands.repair import cmd_repair
```

```diff
 COMMAND_HANDLERS.update({
+    "DEPLOY": lambda s, a=None: cmd_deploy(s, a),
+    "MOVE": lambda s, a=None: cmd_move(s, a),
+    "RETURN": lambda s: cmd_return(s),
+    "REPAIR": lambda s, a=None: cmd_repair(s, a),
 })
```

---

## 7) STATUS branching (command vs field)

### `terminal/commands/status.py`

At top of `cmd_status`:

```diff
+    if state.in_field():
+        lines = [
+            f"LOCATION: {state.player_location}",
+        ]
+        if state.active_task:
+            lines.append(
+                f"TASK: {state.active_task['type']} "
+                f"({state.active_task['ticks']} TICKS REMAINING)"
+            )
+        return lines
```

Command mode STATUS remains unchanged.

---

# PART 2 — REMOTE vs LOCAL REPAIR WORDING

This is **operator-facing**, terse, and fits your contract tone.

---

## Local (Field) Repair

**Start**

```
MANUAL REPAIR STARTED: POWER RELAY.
```

**Blocked**

```
STRUCTURE NOT IN SECTOR.
```

**Completion (implicit via STATUS)**

```
TASK COMPLETE.
```

---

## Remote (Command) Repair

**Allowed**

```
REMOTE REPAIR QUEUED: SENSOR ARRAY.
```

**Disallowed**

```
REMOTE REPAIR NOT POSSIBLE.
PHYSICAL INTERVENTION REQUIRED.
```

(Second line optional but strongly recommended for clarity.)

---

## When ACTION already running

```
ACTION IN PROGRESS.
```

This message is reused everywhere — good consistency.

---

## Why this wording works

* No narrative fluff
* No promises
* No recommendations
* Always implies tradeoff
* Reinforces physical presence as valuable

---

## Next logical steps (after you review)

Once you confirm these diffs align with your intent, the **next clean slices** are:


