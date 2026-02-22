=== ASSAULT_INSTANCES_WORLD_TRAVEL.md ===
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

### Key takeaways from general game design practice

* A spatial graph with weighted nodes/edges is the classic foundation for AI movement and strike paths in strategy games (pathfinding via BFS/A*/similar) — even simple grid or node graphs guide unit progression toward objectives. ([Reddit][1])

* Economies in strategy/simulation games are meant to meaningfully gate player actions (e.g., repairs, expansions) so that decisions have cost and opportunity impact rather than trivial mechanical overhead. ([Wayward Strategy][2])

* Enemy movement models that present *advance warnings* and *progressive approach behavior* give players strategic tension, even without detailed combat systems. ([Reddit][3])

These insights validate that our planned system — with spatial enemy traversal and resource gating — is *not only coherent but in line with common design patterns.*

---

# FULL SYSTEM DESIGN (LOCKED)

This design spec defines:

1. **Enemy Spatial Traversal System**
2. **Enemy Lifecycle & States**
3. **World Graph Geometry**
4. **Assault Trigger & Engagement Logic**
5. **Resource Salvage**
6. **Integration Points with Current Codebase**

It is **implementation ready**, and nothing should change without coordinated diffs.

---

## 1) World Geometry Model (Graph)

Your world becomes a **graph of named nodes**:

```
INGRESS_N
       \
     T_NORTH
         |
      COMMAND ---- FAB
         |
     T_SOUTH
        /
DEFENSE
```

### Node types

| Node        | Type    | Meaning                           |
| ----------- | ------- | --------------------------------- |
| `INGRESS_N` | Ingress | Starting point for north assaults |
| `T_NORTH`   | Transit | Buffer node                       |
| `COMMAND`   | Hub     | Strategic center                  |
| `FAB`       | Sector  | Auxiliary sector                  |
| `T_SOUTH`   | Transit | Buffer node                       |
| `DEFENSE`   | Sector  | Defensive sector                  |

### Config structure

This is implemented as:

```python
WORLD_GRAPH = {
    "INGRESS_N": ["T_NORTH"],
    "T_NORTH": ["INGRESS_N", "COMMAND"],
    "COMMAND": ["T_NORTH", "FAB", "T_SOUTH"],
    "FAB": ["COMMAND"],
    "T_SOUTH": ["COMMAND", "DEFENSE"],
    "DEFENSE": ["T_SOUTH"],
}
```

Edges are **bidirectional**.

---

## 2) Enemy Unit (AssaultApproach) Lifecycle

Each assault is now a **moving entity** with its own state:

```python
class AssaultApproach:
    id: str
    route: list[str]        # Ordered nodes from ingress → target
    index: int              # Current position in route
    ticks_to_next: int      # Time until reaching next node
    state: Enum(ENV_ROUTE, NEAR_TARGET, ENGAGED, RESOLVED)
```

States:

* **ENV_ROUTE** — moving between nodes
* **NEAR_TARGET** — arrived at perimeter node (e.g., next is target)
* **ENGAGED** — assault resolution started
* **RESOLVED** — assault finished

---

## 3) Pathfinding & Routing

Routing is computed on spawn:

* Use **BFS** over `WORLD_GRAPH` (weights = 1 per edge)
* Compute shortest path from an ingress node to target sector
* Set assault route accordingly

Example:

```
INGRESS_N → T_NORTH → COMMAND
```

---

## 4) Movement per Tick (when Assault Exists)

Each tick:

1. For each assault in `ENV_ROUTE`:

   * Decrement `ticks_to_next`
   * If reaches zero:

     * `index += 1`
     * If `index == len(route) - 1`:
       `state = NEAR_TARGET`
     * Else: set `ticks_to_next = 1` for next edge

2. When in `NEAR_TARGET`:

   * Move to `ENGAGED`
   * Spawn tactical assault (your existing resolution code)

---

## 5) Assault Initiation & Warning

When an assault is created:

* Pick ingress (`INGRESS_N` for N/S case)
* Compute route
* Set initial `ticks_to_next` to 1

Warning strategy:

* If assault passes through a transit node adjacent to command (`T_NORTH`, `T_SOUTH`), broadcast:

  ```
  HOSTILES APPROACHING NEARBY
  ```

* If assault arrives at node adjacent to command, broadcast:

  ```
  HOSTILES AT PERIMETER
  ```

These are textual, not UI events.

---

## 6) Engagement & Resolution

When an assault transitions to `ENGAGED`:

* Call existing `start_assault()` / tactical resolution
* After resolution, set `state = RESOLVED`
* Award salvage (materials)

---

## 7) Salvage & Resource Economy

### Materials gain

On assault resolution **before damage application**:

```
if cleaned (no damage): materials += 0
if damage incurred: materials += 1
if partial breach: materials += 2
if strategic loss: materials += 3
```

These values are locked for now.

### Materials sink (repairs)

Costs should be enforced up front:

```
remote DAMAGED → OPERATIONAL: 2 materials
field DAMAGED → OPERATIONAL: 1
field OFFLINE → DAMAGED: 2
field DESTROYED → OFFLINE (rebuild): 4
```

---

## 8) Integration With Current Architecture

### Replace

```
state.assault_timer
tick_assault_timer()
```

with:

* A list of `AssaultApproach` objects in `state`.

Tick loop becomes:

```
for assault in state.assaults:
    advance_assault_route(assault)
    if assault.state == ENGAGED:
        resolve_tactical_assault(...)
        award_salvage(...)
```

Remove global timers.

---

## 9) Interfaces to Add/Update

| System          | Change                                      |
| --------------- | ------------------------------------------- |
| state           | Replace timer with assault list             |
| simulation tick | Route advancement                           |
| assaults        | `AssaultApproach` logic                     |
| terminal/status | Show nearest threat and ETA if COMMS permit |
| economy         | Salvage awarding                            |
| repair          | Materials gating + front/back enforcement   |

---

## 10) Failure & Edge Cases

* If player is on foot far from target, they may miss warnings
* Assaults must complete even if player is downed (future state)
* If multiple assaults exist, they can overlap routes

This makes the system relatable to RTS-style paths without combat micro. It gives you **pressure, spatiality, and meaningful warnings**. ([Reddit][3])

---

# QUESTIONS TO LOCK BEFORE DIFFS

Answer these with simple values, then I’ll generate exact diffs:

1. **Target selection model:**
   Should assaults route to the **nearest single strategic sector**, or can they target multiple goals (e.g., **COMMAND or FAB or DEFENSE**) based on threat level?

2. **Global assault cap:**
   How many assaults can be in transit simultaneously? (default candidates: `1`, `2`, `unlimited`)

3. **Warning visibility:**

   * If COMMS are degraded, should warnings show:

     * A) Still visible with text
     * B) Partially obfuscated (garbled text)
     * C) Not shown until at perimeter

4. **Route travel cost per edge:**
   Do you prefer:

   * `1 tick per edge` (fast, snappy)
   * `2 ticks per edge` (slower, more warning time)


## ANSWERS / DEFINITIONS
* 🎯 Targeting: threat-level + enemy profile driven
* 🧠 Assault cap: campaign-scaled (start = 1 in tutorial)
* 📡 Warning visibility: A + B (nondeterministic)
* 🐢 Travel speed: **2 ticks per edge**
* ⏳ WAIT = 5 ticks per command (correct in current codebase)

Now I’ll give you the **exact diff implementation plan**, in clean commit-order sequence so Codex can implement safely.

---

# 🚧 IMPLEMENTATION PLAN

(Spatial Assault Traversal + Salvage + Materials Integration)

This replaces timer-based assault spawning with graph-based traversal.

---

# PHASE 1 — WORLD GRAPH + CONFIG

### File: `core/config.py`

### Add:

```python
# =========================
# WORLD GEOMETRY
# =========================

WORLD_GRAPH = {
    "INGRESS_N": ["T_NORTH"],
    "INGRESS_S": ["T_SOUTH"],
    "T_NORTH": ["INGRESS_N", "COMMAND"],
    "T_SOUTH": ["INGRESS_S", "COMMAND"],
    "COMMAND": ["T_NORTH", "T_SOUTH", "FAB", "POWER"],
    "FAB": ["COMMAND"],
    "POWER": ["COMMAND"],
    "DEFENSE": ["T_SOUTH"],
}

EDGE_TRAVEL_TICKS = 2

MAX_ACTIVE_ASSAULTS_TUTORIAL = 1
```

No logic yet — just geometry.

---

# PHASE 2 — NEW ASSAULT ENTITY

### File: `core/assaults.py`

### Add class:

```python
class AssaultApproach:
    def __init__(self, assault_id, ingress, target, route):
        self.id = assault_id
        self.ingress = ingress
        self.target = target
        self.route = route
        self.index = 0
        self.ticks_to_next = EDGE_TRAVEL_TICKS
        self.state = "APPROACHING"  # APPROACHING, ENGAGED, RESOLVED
```

---

# PHASE 3 — PATH ROUTING (BFS)

Still inside `core/assaults.py`

Add:

```python
def compute_route(start, goal):
    from collections import deque
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
                new_path = list(path)
                new_path.append(neighbor)
                queue.append(new_path)
    return None
```

---

# PHASE 4 — Replace Assault Timer With Active Assault List

### File: `core/state.py`

### Remove:

```
self.assault_timer
```

### Add:

```python
self.assaults = []
self.materials = 0
```

---

# PHASE 5 — Spawn Assaults Spatially

### File: `core/assaults.py`

Replace logic in `tick_assault_timer()` and `start_assault()` with:

```python
def maybe_spawn_assault(state):
    if len(state.assaults) >= MAX_ACTIVE_ASSAULTS_TUTORIAL:
        return

    # Spawn probability logic can reuse old timer thresholds
    if state.ambient_threat > 1.5:
        ingress = random.choice(["INGRESS_N", "INGRESS_S"])
        target = choose_target_sector(state)
        route = compute_route(ingress, target)

        assault = AssaultApproach(
            assault_id=str(uuid4()),
            ingress=ingress,
            target=target,
            route=route
        )
        state.assaults.append(assault)
```

---

# PHASE 6 — Per-Tick Assault Movement

### File: `core/simulation.py`

(inside your main tick loop)

Add:

```python
for assault in list(state.assaults):
    if assault.state != "APPROACHING":
        continue

    assault.ticks_to_next -= 1

    if assault.ticks_to_next <= 0:
        assault.index += 1

        if assault.index >= len(assault.route) - 1:
            assault.state = "ENGAGED"
        else:
            assault.ticks_to_next = EDGE_TRAVEL_TICKS
```

---

# PHASE 7 — Trigger Tactical Assault When ENGAGED

In same loop:

```python
if assault.state == "ENGAGED":
    outcome = resolve_tactical_assault(state, assault.target)
    award_salvage(state, outcome)
    state.assaults.remove(assault)
```

---

# PHASE 8 — Salvage Implementation

### File: `core/assaults.py`

Add:

```python
def award_salvage(state, outcome):
    if outcome == "CLEAN":
        return
    elif outcome == "DAMAGE":
        state.materials += 1
    elif outcome == "BREACH":
        state.materials += 2
    elif outcome == "STRATEGIC_LOSS":
        state.materials += 3
```

Hook into actual outcome enum instead of string once verified.

---

# PHASE 9 — Repair Material Gating

### File: `terminal/commands/repair.py`

Before starting repair:

```python
cost = get_material_cost(structure, state.player_mode)

if state.materials < cost:
    return ["INSUFFICIENT MATERIALS."]

state.materials -= cost
```

---

# PHASE 10 — Warning Logic (Nondeterministic A/B)

### File: `core/simulation.py`

Inside assault movement:

```python
if assault.route[assault.index] in {"T_NORTH", "T_SOUTH"}:
    if random.random() < comms_warning_chance(state):
        print("[ALERT] HOSTILES APPROACHING.")
    else:
        print("[SIGNAL NOISE DETECTED.]")
```

Where:

```python
def comms_warning_chance(state):
    return 0.8 if state.comms_integrity > 0.5 else 0.4
```

---

# PHASE 11 — STATUS Enhancement

### File: `terminal/commands/status.py`

If in COMMAND mode and comms sufficient:

Show nearest assault:

```python
for assault in state.assaults:
    remaining_edges = len(assault.route) - assault.index
    eta = remaining_edges * EDGE_TRAVEL_TICKS
    lines.append(f"HOSTILE APPROACH: {assault.target} ETA {eta}")
```

Hide or obfuscate in FIELD mode.

---

# What This Replaces

| Old System      | New System          |
| --------------- | ------------------- |
| assault_timer   | active assault list |
| immediate spawn | ingress-based route |
| warning window  | spatial approach    |
| binary trigger  | progressive advance |

---

# What Remains Untouched

* Tactical resolution logic
* Structure degradation logic
* Field movement system
* Repair task progression
* WAIT command behavior (still 5 ticks)

# Strategic Note

Once this lands:

* Assaults become spatial
* Transit nodes become meaningful
* Field mode becomes dangerous
* Economy ties into spatial defense

---



=== ASSAULT_MISC_DESIGN.md ===
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




=== ASSAULT-RESOURCE-LINK.md ===
# ASSAULT-RESOURCE-LINK (Implementation-Ready)

This document replaces the older draft assumptions with a design that fits the current world-state codebase.

## Implementation Status

- Phase A is now implemented in the live codebase (`core/assaults.py`) with deterministic transit interception, ammo spend, and bounded threat-budget mitigation before engagement.
- Phase B and Phase C remain design-stage follow-ons.

## Goal

Link assault outcomes to operator resource decisions before, during, and after engagement without adding UI-heavy systems.

Desired loop:

`Allocate/Fabricate -> Intercept/Assault -> Damage/Salvage -> Repair/Rebuild -> Repeat`

## Reality Check (Current Code)

Implemented now:
- Structure lifecycle exists (`OPERATIONAL`, `DAMAGED`, `OFFLINE`, `DESTROYED`).
- Materials economy exists (`state.materials`) and is used by repair/scavenge.
- Assault approaches are spatial (`INGRESS_N`/`INGRESS_S` over `WORLD_GRAPH`).
- Tactical assaults are multi-tick and consume `turret_ammo_stock` each assault tick.
- Repair drones, fabrication queue, and stock outputs exist (`REPAIR_DRONE`, `TURRET_AMMO`, inventory tiers).
- Defense doctrine/allocation and fortification levels already influence assault pressure.

Not implemented now:
- Player-placed structures at transit nodes.
- Transit-node-specific pre-engagement interception effects.
- A direct operator command that spends materials to modify inbound approaches.

## Design Constraints

- No new rendering/UI requirements.
- Keep world mutation in simulation tick paths (`step_world` and assault/approach helpers).
- Reuse existing resources (`materials`, `turret_ammo_stock`, `repair_drone_stock`, fortification, policies).
- Preserve deterministic behavior for seeded runs/tests.

## Recommended Live Phase

## Phase A: Transit Interception (No New UI)

Add a deterministic pre-engagement interception layer while assaults traverse `T_NORTH`/`T_SOUTH`.

### Mechanics

1. Interception trigger:
- In `core/assaults.py::advance_assaults`, when an approach is on a transit node, run interception once per node pass.

2. Resource gate:
- Interception requires `state.turret_ammo_stock >= 1`.
- If ammo is available, spend 1 ammo.
- If ammo is not available, no interception mitigation is applied.

3. Mitigation effect:
- Store approach-local mitigation on `AssaultApproach` (new field, e.g. `threat_mult` default `1.0`).
- Apply a bounded reduction (example: multiply by `0.9`) per successful intercept.
- Scale intercept strength by existing fortification/readiness signals (small bonus only).

4. Engagement handoff:
- When approach reaches target and `_start_assault` is called from `advance_assaults`, convert mitigation to assault `threat_budget` scaling.
- Clamp to safe bounds (example floor `0.7`, ceiling `1.0`) to avoid nullifying assaults.

5. Operator feedback:
- Append concise line to `state.last_assault_lines` when intercept fires, e.g. `[INTERCEPT] T_NORTH DELAYED HOSTILES`.
- Keep output fidelity-gated via existing WAIT rendering behavior.

### Why this phase first

- Uses existing assault movement model.
- Uses existing resource stocks.
- Requires no new command surface to be useful.
- Creates immediate link between fabrication/defense prep and assault severity.

## Phase B: Explicit Material Spend (Command-Level)

After Phase A stabilizes, add an operator command to spend materials on lane prep.

Command:
- `FORTIFY T_NORTH <0-4>` or a dedicated command (recommended: keep existing `FORTIFY` and extend accepted targets).

Behavior:
- Transit fortification level contributes to interception multiplier in Phase A.
- Uses existing fortification semantics and policy load tradeoffs.

## Phase C: Salvage Coupling

Refine salvage to reflect resource burn and intercept effectiveness.

Adjustments:
- Keep current penetration-based salvage baseline.
- Add a small modifier from interception success and ammo spent (bounded, deterministic).
- Do not add RNG-heavy reward spikes.

## Required Code Touchpoints

Primary:
- `game/simulations/world_state/core/assaults.py`
  - `AssaultApproach` state extension.
  - `advance_assaults` interception hook.
  - `_start_assault` threat-budget scaling from approach mitigation.

Secondary:
- `game/simulations/world_state/core/state.py`
  - Optional tracking counters for post-action reporting (intercepts triggered, ammo spent pre-engagement).

Presentation:
- `game/simulations/world_state/terminal/commands/wait.py`
  - Reuse existing assault line surfacing; only add formatting if needed.
- `game/simulations/world_state/terminal/commands/status.py`
  - Optional concise indicator (example: `INTERCEPT: READY/DEPLETED`).

## Test Plan (Must Add)

1. `advance_assaults` spends ammo and applies mitigation at transit nodes.
2. No ammo means no mitigation.
3. Mitigation affects resulting assault threat budget at engagement.
4. Bounds hold (mitigation cannot reduce below configured floor).
5. WAIT output includes interception signal line when triggered.
6. Determinism check with fixed seed.

## Non-Goals (for this feature)

- No turret placement UI.
- No projectile simulation.
- No free-form build grid.
- No new combat subsystem.

## Decision

Implement Phase A first. It is directly compatible with the current architecture and creates immediate, understandable resource-to-assault coupling with minimal risk.



=== CLARIFY_ASSAULT_MISC.md ===


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



=== CODEX-FEATURE-RECOMMEND.md ===
# CODEX-FEATURE-RECOMMEND

## Feature Name
Adaptive Relay Recovery Network (ARRN)

## Purpose
Add a high-value, reconstruction-aligned system that deepens the current loop:
- Command authority vs field presence
- Materials scarcity
- Transit risk
- Knowledge preservation as campaign identity

This feature adds meaningful choices without introducing combat complexity.

## Core Idea
Deploy and restore ancient relay nodes across transit and peripheral sectors to recover fragmented operational knowledge.

Recovered knowledge grants:
- repair efficiency bonuses
- clearer degraded information under COMMS stress
- fabrication unlock prerequisites (future)

The system makes expeditions and field presence strategically important even when materials are sufficient.

## Design Goals
1. Reinforce reconstruction fantasy over extermination.
2. Add long-term progression through knowledge, not raw stats.
3. Keep terminal-first authority and terse outputs.
4. Integrate with existing WAIT/STATUS/REPAIR/SCAVENGE loops.
5. Preserve operational ambiguity at low fidelity.

## High-Level Loop Integration
1. Detect relay opportunity through events or STATUS hint.
2. DEPLOY and MOVE through transit network.
3. Perform local relay stabilization (timed field task).
4. RETURN to command.
5. Run `SYNC` command at command center to decode relay packet.
6. Apply one bounded benefit to campaign state.

## New Commands (Phase B)
1. `SCAN RELAYS`
- Command-only.
- Lists known relay nodes and signal confidence.

2. `STABILIZE RELAY <ID>`
- Field-only, local-sector-only.
- Timed action; interrupted by movement.

3. `SYNC`
- Command-only.
- Converts stabilized packets into one knowledge unlock.

## Data Model Additions
In `GameState`:
- `relay_nodes: dict[id -> RelayNodeState]`
- `relay_packets_pending: int`
- `knowledge_index: dict[tag -> level]`
- `last_sync_time: int`

`RelayNodeState` fields:
- `sector`
- `status` (`UNKNOWN`, `LOCATED`, `UNSTABLE`, `STABLE`, `DORMANT`)
- `stability_ticks_required`
- `risk_profile`

## Authority Rules
- Command mode: scan and sync only.
- Field mode: stabilize only when in same sector.
- No recommendation text; only factual outcomes.

## Information Degradation Alignment
- COMMS fidelity affects certainty of relay state readout.
- FULL: exact node state and ticks.
- DEGRADED: approximate stability phrases.
- FRAGMENTED: `SIGNAL IRREGULAR` style output.
- LOST: relay reporting unavailable except local field context.

## Reward Model
Knowledge rewards are non-linear and bounded.

Examples:
- `MAINTENANCE_ARCHIVE_I`: remote damaged repair cost -1 minimum floor 1.
- `SIGNAL_RECONSTRUCTION_I`: improve DEGRADED STATUS fidelity for one section.
- `FAB_BLUEPRINTS_I`: prerequisite flag for future fabrication production.

No direct combat buff numbers in this phase.

## Failure/Pressure Behavior
- Failing to stabilize does not hard fail campaign.
- Delay increases opportunity cost and future assault pressure indirectly.
- Relay nodes can decay from `STABLE` to `DORMANT` if ignored for long windows.

## Implementation Plan
1. Add relay state schema and snapshot projection.
2. Add command handlers: `SCAN RELAYS`, `STABILIZE RELAY`, `SYNC`.
3. Add timed relay task integration with existing task tick loop.
4. Add STATUS section `RELAY NETWORK` with fidelity gating.
5. Add tests for authority, locality, and fidelity output behavior.
6. Add minimal UI read-only panel row for relay network state.

## Milestones
1. M1: Data-only scaffolding + STATUS exposure.
2. M2: Field stabilization task with movement constraints.
3. M3: Sync pipeline and first knowledge unlocks.
4. M4: Degradation-aware messaging and balancing pass.

## Why This Adds Value Now
- Extends current systems instead of bypassing them.
- Gives field mode strategic purpose beyond emergency repairs.
- Creates campaign continuity through knowledge recovery.
- Preserves terminal clarity and operational tone.

## Future-Compatible Extensions
- Relay-assisted expedition routing.
- Sector-specific doctrine fragments.
- Narrative logs unlocked by archive/relay intersections.
- Hub-level strategic upgrades driven by recovered knowledge quality.



=== DEV-MODE.md ===

w is a **complete, cohesive debug tooling design** tailored to the current `main` branch of `braydio/CUSTODIAN`, based on the live implementations of:
 
 * `game/simulations/world_state/core/assaults.py`
*  * `game/simulations/world_state/terminal/processor.py`
*   
*    This design **does not modify combat math** and **does not fork resolution paths**.
*     It injects state at clean seams already present.
*      
*       ---
*        
*         # OBJECTIVE
*          
*           Add a fully deterministic, reproducible, non-invasive **DEV TOOLING LAYER** with:
*            
*             * Forced assault injection
*              * Manual timer control
*               * Multi-tick advancement
*                * Deterministic seed reproducibility
*                 * State mutation utilities
*                  * Structured assault tracing
*                   
*                    No hacks. No alternate code paths. No duplicated logic.
*                     
*                      ---
*                       
*                        # DESIGN PRINCIPLES
*                         
*                          1. Dev mode toggles only injection privileges.
*                           2. Assault resolution remains exclusively in:
*                            
*                                * `start_assault`
*                                    * `resolve_assault`
*                                     3. No math branches based on dev flag.
*                                      4. All dev commands routed through terminal processor.
*                                       5. All world invariants preserved (`validate_state_invariants` remains untouched).
*                                        
*                                         ---
*                                          
*                                           # PHASE 1 — CORE DEV MODE FLAG
*                                            
*                                             ## Modify: `game/simulations/world_state/core/state.py`
*                                              
*                                               Add:
*                                                
*                                                 ```python
*                                                  class GameState:
*                                                       def __init__(...):
*                                                                ...
*                                                                         self.dev_mode: bool = False
*                                                                                  self.dev_trace: bool = False
*                                                                                   ```
*                                                                                    
*                                                                                     No behavior changes yet.
*                                                                                      
*                                                                                       ---
*                                                                                        
*                                                                                         # PHASE 2 — CLI FLAG SUPPORT
*                                                                                          
*                                                                                           Modify entry point (`game/__main__.py` or run.py equivalent).
*                                                                                            
*                                                                                             Add:
*                                                                                              
*                                                                                               ```python
*                                                                                                parser.add_argument("--dev", action="store_true")
*                                                                                                 parser.add_argument("--seed", type=int)
*                                                                                                  ```
*                                                                                                   
*                                                                                                    After state creation:
*                                                                                                     
*                                                                                                      ```python
*                                                                                                       if args.seed is not None:
*                                                                                                            state.rng.seed(args.seed)
*                                                                                                             
*                                                                                                              if args.dev:
*                                                                                                                   state.dev_mode = True
*                                                                                                                    ```
*                                                                                                                     
*                                                                                                                      This ensures:
*                                                                                                                       
*                                                                                                                        * Deterministic assault reproduction
*                                                                                                                         * Debug commands gated cleanly
*                                                                                                                          
*                                                                                                                           ---
*                                                                                                                            
*                                                                                                                             # PHASE 3 — DEBUG COMMAND ROUTING
*                                                                                                                              
*                                                                                                                               Modify:
*                                                                                                                                
*                                                                                                                                 `game/simulations/world_state/terminal/processor.py`
*                                                                                                                                  
*                                                                                                                                   ## Add import:
*                                                                                                                                    
*                                                                                                                                     ```python
*                                                                                                                                      from game.simulations.world_state.core.assaults import (
*                                                                                                                                           start_assault,
*                                                                                                                                                resolve_assault,
*                                                                                                                                                 )
*                                                                                                                                                  ```
*                                                                                                                                                   
*                                                                                                                                                    ## Add DEBUG command block before normal handlers:
*                                                                                                                                                     
*                                                                                                                                                      Inside `process_command()` — before final handler resolution — insert:
*                                                                                                                                                       
*                                                                                                                                                        ```python
*                                                                                                                                                         if parsed.verb == "DEBUG":
*                                                                                                                                                              if not state.dev_mode:
*                                                                                                                                                                       return _finalize_result(
*                                                                                                                                                                                    state,
*                                                                                                                                                                                                 CommandResult(ok=False, text="DEV MODE DISABLED.")
*                                                                                                                                                                                                          )
*                                                                                                                                                                                                           
*                                                                                                                                                                                                                return _finalize_result(
*                                                                                                                                                                                                                         state,
*                                                                                                                                                                                                                                  _handle_debug_command(state, parsed.args),
*                                                                                                                                                                                                                                           "DEBUG",
*                                                                                                                                                                                                                                                )
*                                                                                                                                                                                                                                                 ```
*                                                                                                                                                                                                                                                  
*                                                                                                                                                                                                                                                   ---
*                                                                                                                                                                                                                                                    
*                                                                                                                                                                                                                                                     # PHASE 4 — DEBUG COMMAND HANDLER
*                                                                                                                                                                                                                                                      
*                                                                                                                                                                                                                                                       Add below processor:
*                                                                                                                                                                                                                                                        
*                                                                                                                                                                                                                                                         ```python
*                                                                                                                                                                                                                                                          def _handle_debug_command(state: GameState, args: list[str]) -> CommandResult:
*                                                                                                                                                                                                                                                               if not args:
*                                                                                                                                                                                                                                                                        return CommandResult(ok=False, text="DEBUG REQUIRES SUBCOMMAND.")
*                                                                                                                                                                                                                                                                         
*                                                                                                                                                                                                                                                                              sub = args[0].upper()
*                                                                                                                                                                                                                                                                               
*                                                                                                                                                                                                                                                                                    if sub == "ASSAULT":
*                                                                                                                                                                                                                                                                                             return _debug_force_assault(state)
*                                                                                                                                                                                                                                                                                              
*                                                                                                                                                                                                                                                                                                   if sub == "TICK":
*                                                                                                                                                                                                                                                                                                            return _debug_advance_ticks(state, args[1:])
*                                                                                                                                                                                                                                                                                                             
*                                                                                                                                                                                                                                                                                                                  if sub == "TIMER":
*                                                                                                                                                                                                                                                                                                                           return _debug_set_assault_timer(state, args[1:])
*                                                                                                                                                                                                                                                                                                                            
*                                                                                                                                                                                                                                                                                                                                 if sub == "POWER":
*                                                                                                                                                                                                                                                                                                                                          return _debug_set_power(state, args[1:])
*                                                                                                                                                                                                                                                                                                                                           
*                                                                                                                                                                                                                                                                                                                                                if sub == "DAMAGE":
*                                                                                                                                                                                                                                                                                                                                                         return _debug_set_damage(state, args[1:])
*                                                                                                                                                                                                                                                                                                                                                          
*                                                                                                                                                                                                                                                                                                                                                               if sub == "TRACE":
*                                                                                                                                                                                                                                                                                                                                                                        state.dev_trace = not state.dev_trace
*                                                                                                                                                                                                                                                                                                                                                                                 return CommandResult(ok=True, text=f"ASSAULT TRACE = {state.dev_trace}")
*                                                                                                                                                                                                                                                                                                                                                                                  
*                                                                                                                                                                                                                                                                                                                                                                                       return CommandResult(ok=False, text="UNKNOWN DEBUG SUBCOMMAND.")
*                                                                                                                                                                                                                                                                                                                                                                                        ```
*                                                                                                                                                                                                                                                                                                                                                                                         
*                                                                                                                                                                                                                                                                                                                                                                                          ---
*                                                                                                                                                                                                                                                                                                                                                                                           
*                                                                                                                                                                                                                                                                                                                                                                                            # PHASE 5 — FORCE ASSAULT (Clean Injection)
*                                                                                                                                                                                                                                                                                                                                                                                             
*                                                                                                                                                                                                                                                                                                                                                                                              Because `start_assault(state)` already exists and performs:
*                                                                                                                                                                                                                                                                                                                                                                                               
*                                                                                                                                                                                                                                                                                                                                                                                                * state.in_major_assault = True
*                                                                                                                                                                                                                                                                                                                                                                                                 * state.current_assault assignment
*                                                                                                                                                                                                                                                                                                                                                                                                  * print banner
*                                                                                                                                                                                                                                                                                                                                                                                                   
*                                                                                                                                                                                                                                                                                                                                                                                                    We reuse it.
*                                                                                                                                                                                                                                                                                                                                                                                                     
*                                                                                                                                                                                                                                                                                                                                                                                                      ```python
*                                                                                                                                                                                                                                                                                                                                                                                                       def _debug_force_assault(state: GameState) -> CommandResult:
*                                                                                                                                                                                                                                                                                                                                                                                                            if state.in_major_assault:
*                                                                                                                                                                                                                                                                                                                                                                                                                     return CommandResult(ok=False, text="ASSAULT ALREADY ACTIVE.")
*                                                                                                                                                                                                                                                                                                                                                                                                                      
*                                                                                                                                                                                                                                                                                                                                                                                                                           start_assault(state)
*                                                                                                                                                                                                                                                                                                                                                                                                                                return CommandResult(ok=True, text="ASSAULT FORCED.")
*                                                                                                                                                                                                                                                                                                                                                                                                                                 ```
*                                                                                                                                                                                                                                                                                                                                                                                                                                  
*                                                                                                                                                                                                                                                                                                                                                                                                                                   No duplication.
*                                                                                                                                                                                                                                                                                                                                                                                                                                    No bypass of official assault pipeline.
*                                                                                                                                                                                                                                                                                                                                                                                                                                     
*                                                                                                                                                                                                                                                                                                                                                                                                                                      ---
*                                                                                                                                                                                                                                                                                                                                                                                                                                       
*                                                                                                                                                                                                                                                                                                                                                                                                                                        # PHASE 6 — MANUAL TICK ADVANCEMENT
*                                                                                                                                                                                                                                                                                                                                                                                                                                         
*                                                                                                                                                                                                                                                                                                                                                                                                                                          We must not call internal tactical bridge directly.
*                                                                                                                                                                                                                                                                                                                                                                                                                                           
*                                                                                                                                                                                                                                                                                                                                                                                                                                            Instead, use existing wait tick logic.
*                                                                                                                                                                                                                                                                                                                                                                                                                                             
*                                                                                                                                                                                                                                                                                                                                                                                                                                              Find existing:
*                                                                                                                                                                                                                                                                                                                                                                                                                                               
*                                                                                                                                                                                                                                                                                                                                                                                                                                                ```
*                                                                                                                                                                                                                                                                                                                                                                                                                                                 cmd_wait_ticks(state, ticks)
*                                                                                                                                                                                                                                                                                                                                                                                                                                                  ```
*                                                                                                                                                                                                                                                                                                                                                                                                                                                   
*                                                                                                                                                                                                                                                                                                                                                                                                                                                    We reuse it.
*                                                                                                                                                                                                                                                                                                                                                                                                                                                     
*                                                                                                                                                                                                                                                                                                                                                                                                                                                      ```python
*                                                                                                                                                                                                                                                                                                                                                                                                                                                       def _debug_advance_ticks(state: GameState, args: list[str]) -> CommandResult:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                            if not args or not args[0].isdigit():
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                     return CommandResult(ok=False, text="DEBUG TICK <N> REQUIRED.")
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                           count = int(args[0])
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                if count <= 0:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         return CommandResult(ok=False, text="TICK COUNT MUST BE > 0.")
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               for _ in range(count):
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        cmd_wait_ticks(state, 1)
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              return CommandResult(ok=True, text=f"ADVANCED {count} TICKS.")
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ```
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 This ensures:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   * All invariant checks preserved
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    * Assault timer decrements naturally
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     * Assault resolution triggers normally
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ---
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         # PHASE 7 — ASSAULT TIMER CONTROL
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           Assault timer currently managed by:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             * `maybe_start_assault_timer`
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              * `tick_assault_timer`
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                We only override value.
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ```python
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   def _debug_set_assault_timer(state: GameState, args: list[str]) -> CommandResult:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        if not args or not args[0].isdigit():
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 return CommandResult(ok=False, text="DEBUG TIMER <VALUE> REQUIRED.")
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       state.assault_timer = int(args[0])
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            return CommandResult(ok=True, text=f"ASSAULT TIMER SET TO {state.assault_timer}")
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ```
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ---
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 # PHASE 8 — DIRECT POWER INJECTION
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   Structures/sectors already have `.power`.
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ```python
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      def _debug_set_power(state: GameState, args: list[str]) -> CommandResult:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           if len(args) != 2:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    return CommandResult(ok=False, text="DEBUG POWER <SECTOR> <VALUE>")
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          sector_id = args[0].upper()
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               try:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        value = float(args[1])
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             except ValueError:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      return CommandResult(ok=False, text="INVALID POWER VALUE.")
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            sector = state.sectors.get(sector_id)
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 if not sector:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          return CommandResult(ok=False, text="UNKNOWN SECTOR.")
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                sector.power = value
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     return CommandResult(ok=True, text=f"{sector_id} POWER SET TO {value}")
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ```
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        No scaling changes.
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         Assault math reads power normally.
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ---
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             # PHASE 9 — DAMAGE INJECTION
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ```python
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                def _debug_set_damage(state: GameState, args: list[str]) -> CommandResult:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     if len(args) != 2:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              return CommandResult(ok=False, text="DEBUG DAMAGE <SECTOR> <VALUE>")
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    sector_id = args[0].upper()
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         try:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  value = float(args[1])
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       except ValueError:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                return CommandResult(ok=False, text="INVALID DAMAGE VALUE.")
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      sector = state.sectors.get(sector_id)
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           if not sector:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    return CommandResult(ok=False, text="UNKNOWN SECTOR.")
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          sector.damage = value
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               return CommandResult(ok=True, text=f"{sector_id} DAMAGE SET TO {value}")
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ```
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ---
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    # PHASE 10 — STRUCTURED ASSAULT TRACE
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      Inside `resolve_assault()` in `assaults.py`, locate:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ```python
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         def on_tick(sectors, tick):
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ```
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            Insert at top:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ```python
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               if state.dev_trace:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    print({
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             "tick": assault.elapsed_ticks,
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      "active_sectors": [s.name for s in sectors if s.has_hostiles()],
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               "ambient_threat": state.ambient_threat,
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        "alertness": {s.name: s.alertness for s in assault.target_sectors},
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             })
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ```
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                This prints structured combat telemetry without altering logic.
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ---
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    # PHASE 11 — FULL DEV COMMAND SET
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      Final debug grammar:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ```
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         DEBUG ASSAULT
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          DEBUG TICK <N>
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           DEBUG TIMER <VALUE>
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            DEBUG POWER <SECTOR> <FLOAT>
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             DEBUG DAMAGE <SECTOR> <FLOAT>
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              DEBUG TRACE
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ```
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 All gated behind `--dev`.
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ---
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     # PHASE 12 — DETERMINISTIC ASSAULT REPRODUCTION
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       Example reproducible test:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ```
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          python -m game --dev --seed 1337
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            DEBUG DAMAGE GATEWAY 1.0
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             DEBUG TIMER 1
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              WAIT
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ```
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 This guarantees:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   * Same target selection
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    * Same RNG resolution
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     * Same tick behavior
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ---
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         # WHAT THIS ENABLES
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           You can now test:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             * Assault start conditions
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              * Low-power defense vs high-power
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               * Partial vs severe penetration paths
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                * Repair regression behavior
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 * Focused sector weighting
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  * Hardened assault selection
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   * Ambient threat scaling
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     All without waiting for natural triggers.
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ---
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         # WHAT THIS DOES NOT DO
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           * No alternate assault math
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            * No bypass of resolve_assault
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             * No conditional combat logic
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              * No state forks
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               * No mock simulation paths
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 Everything flows through canonical functions.
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ---
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     # RESULT
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       You now have:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         * Deterministic reproduction
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          * Live injection tools
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           * Multi-tick advancement
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            * Sector mutation tools
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             * Combat telemetry
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              * Clean architecture preservation
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                This is production-grade dev tooling.
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  If you want next:
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    * Convert WAIT into real-time combat ticks
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     * Add live doctrine control during assault
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      * Add automated balance logging to CSV
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       * Or build a headless assault stress harness
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         Tell me which layer you want to weaponize next.
*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          



=== INFRASTRUCTURE.md ===
This details a full **between-assault infrastructure layer spec**, written as real documentation, aligned to the repo, with an actionable Codex implementation plan.

Below is the complete documentation draft + implementation plan.

This is designed to be saved as:

```
docs/INFRASTRUCTURE_POLICY_LAYER.md
```

and then executed by Codex step-by-step.

---

# INFRASTRUCTURE POLICY LAYER

## Between-Assault Strategic Systems Specification

---

# 1. PURPOSE

This document defines the **Infrastructure Policy Layer**, a strategic control system that governs:

- Repair behavior
- Defense readiness
- Surveillance intensity
- Fabrication allocation
- Sector fortification posture
- Power load balancing

The goal is to:

- Transform between-assault pacing into colony/factory-style strategic optimization
- Eliminate vague policy labels (e.g. “CONSERVATIVE”, “HARDENED”)
- Replace hidden enum modes with explicit tradeoffs
- Preserve terminal-first UX
- Avoid numeric overload or spreadsheet feel
- Maintain deterministic simulation and seed reproducibility

This system does not replace assaults.
It makes assaults a stress test of infrastructure decisions.

---

# 2. DESIGN PRINCIPLES

## 2.1 No Blind Policies

Every adjustable system must show:

- What increases
- What decreases
- What it costs

No vague adjectives without consequences.

---

## 2.2 Textual Sliders, Not Raw Numbers

Policies are represented as discrete bands:

```
0 – 4 integer scale
```

Rendered as:

```
▮▮▯▯▯ (2/5)
```

With clear effect description.

No decimals shown to player.

---

## 2.3 Tradeoffs Are Mandatory

Increasing one dimension must impact another:

- Defense ↔ Power
- Repair ↔ Materials
- Surveillance ↔ Brownout Risk
- Fabrication ↔ Defense Load

---

# 3. CORE POLICY SYSTEMS

The Infrastructure Policy Layer introduces five global sliders.

Each slider is 0–4.

---

# 3.1 Repair Intensity

Controls autonomous and queued repair behavior.

### Effects

| Level | Effect Summary                            |
| ----- | ----------------------------------------- |
| 0     | Slow repair, minimal material usage       |
| 2     | Balanced repair rate                      |
| 4     | Rapid repair, high material + power drain |

### Internal Mapping

```python
REPAIR_SPEED = [0.5, 0.75, 1.0, 1.4, 1.8]
REPAIR_MATERIAL_MULT = [0.5, 0.75, 1.0, 1.5, 1.7]
REPAIR_POWER_MULT = [0.8, 0.9, 1.0, 1.2, 1.4]
```

---

# 3.2 Defense Readiness

Controls turret cycling, patrol drones, response intensity.

### Effects

| Level | Effect Summary                    |
| ----- | --------------------------------- |
| 0     | Minimal readiness, low power draw |
| 2     | Standard                          |
| 4     | Rapid response, high power + wear |

### Internal Mapping

```python
DEFENSE_MULT = [0.6, 0.8, 1.0, 1.3, 1.6]
DEFENSE_POWER_DRAW = [0.7, 0.85, 1.0, 1.25, 1.5]
WEAR_RATE = [0.5, 0.75, 1.0, 1.3, 1.6]
```

---

# 3.3 Surveillance Coverage

Controls detection speed and fidelity strength.

### Effects

| Level | Effect Summary                            |
| ----- | ----------------------------------------- |
| 0     | Delayed intrusion alerts                  |
| 2     | Normal detection                          |
| 4     | Near-immediate detection, high power load |

```python
DETECTION_SPEED = [0.6, 0.8, 1.0, 1.3, 1.6]
FIDELITY_BUFFER = [0.5, 0.75, 1.0, 1.2, 1.5]
SURVEILLANCE_POWER = [0.6, 0.8, 1.0, 1.3, 1.6]
```

---

# 3.4 Fabrication Allocation

Controls queue throughput.

Fabrication uses weighted distribution:

```
DEFENSE
DRONES
REPAIRS
ARCHIVE HARDENING
```

Each category receives 0–4 allocation.

Throughput proportional to allocation weight.

---

# 3.5 Sector Fortification (Per-Sector)

Each sector has independent fortification level 0–4.

### Effects

- Structural resistance multiplier
- Increased power demand
- Reduced fabrication throughput in that sector

```python
FORTIFICATION_MULT = [1.0, 1.1, 1.25, 1.5, 1.8]
FORTIFICATION_POWER = [0, 0.05, 0.1, 0.15, 0.25]
```

---

# 4. RENDERING SYSTEM

Add:

```
core/policies.py
```

---

## Policy Dataclass

```python
from dataclasses import dataclass

@dataclass
class PolicyState:
    repair_intensity: int = 2
    defense_readiness: int = 2
    surveillance_coverage: int = 2
```

Attach to GameState:

```python
self.policies = PolicyState()
```

---

## Render Helper

```python
def render_slider(level: int) -> str:
    filled = "▮" * level
    empty = "▯" * (5 - level)
    return f"{filled}{empty} ({level}/5)"
```

---

## STATUS Integration

Modify:

```
terminal/commands/status.py
```

Add section:

```
POLICY STATE

REPAIR INTENSITY
▮▮▮▯▯
+ Moderate repair speed
- Moderate material drain

DEFENSE READINESS
▮▮▮▮▯
+ Strong response
- Increased power load
```

Descriptions are derived from lookup tables.

---

# 5. FABRICATION QUEUE SYSTEM

Create:

```
core/fabrication.py
```

---

## FabricationTask

```python
@dataclass
class FabricationTask:
    name: str
    ticks_remaining: int
    material_cost: int
    category: str
```

GameState:

```python
self.fabrication_queue: list[FabricationTask] = []
```

---

## Tick Processing

In world tick:

```python
def tick_fabrication(state):
    if not state.fabrication_queue:
        return

    allocation_weight = state.fab_allocation[current_task.category]
    speed_mult = 0.5 + (allocation_weight * 0.25)

    current_task.ticks_remaining -= speed_mult
```

Power consumption increases based on throughput.

---

# 6. POWER LOAD SYSTEM

Add:

```
core/power_load.py
```

Compute system load each tick:

```python
def compute_power_load(state):
    base = 1.0
    base += DEFENSE_POWER_DRAW[state.policies.defense_readiness]
    base += SURVEILLANCE_POWER[state.policies.surveillance_coverage]
    base += REPAIR_POWER_MULT[state.policies.repair_intensity]
    base += sum(FORTIFICATION_POWER[level] for level in state.sector_fort_levels.values())

    state.power_load = base
```

Brownout chance tied to power_load.

---

# 7. WEAR & PASSIVE DEGRADATION

In world tick:

```python
def apply_wear(state):
    wear_factor = WEAR_RATE[state.policies.defense_readiness]
    for sector in state.sectors:
        sector.integrity -= 0.01 * wear_factor
```

Clamped at minimum.

This forces maintenance.

---

# 8. PLAYER COMMANDS

Add:

```
set repair 0-4
set defense 0-4
set surveillance 0-4
fortify <sector> 0-4
```

Implement in:

```
terminal/commands/policy.py
```

Example:

```python
def cmd_set_repair(state, level):
    state.policies.repair_intensity = int(level)
    return ["REPAIR INTENSITY UPDATED."]
```

---

# 9. AFTER-ACTION SUMMARY INTEGRATION

After assault:

- Display destroyed buildings
- Display policy load state
- Show delta effects

---

# 10. IMPLEMENTATION PLAN (ORDERED)

Codex must implement in this order:

1. Create `core/policies.py`
2. Attach PolicyState to GameState
3. Implement render_slider
4. Integrate policy section into STATUS
5. Create fabrication system + queue
6. Add fabrication tick to world loop
7. Add power_load module
8. Integrate power load into brownout logic
9. Add passive wear system
10. Add policy command handlers
11. Update docs:

- `docs/INFRASTRUCTURE_POLICY_LAYER.md`
- Update `docs/CURRENT_STATE.md`
- Update `_ai_context` if necessary

12. Add tests:

- Policy state mutation
- Fabrication speed scaling
- Power load increasing with policy levels
- Wear scaling

---

# 11. ARCHITECTURAL FIT

This integrates cleanly because:

- Uses existing tick loop
- Uses existing state object
- Respects deterministic seed
- Does not alter assault logic
- Expands between-assault pacing
- No UI creep beyond terminal rendering

---

# 12. RESULTING GAME LOOP

Between assaults:

- Allocate fabrication bandwidth
- Adjust repair intensity
- Tune defense readiness
- Balance surveillance
- Fortify key sectors
- Monitor system load
- Manage degradation

Assault hits.

Infrastructure decisions determine outcome.

Recovery phase begins.

---

# 13. STRATEGIC IDENTITY

This is not:

- RimWorld
- Factorio
- Tower defense

It is:

> Infrastructure resilience command simulation under asymmetric hostile pressure.

---

# NEXT STEP

Once implemented:

We can introduce:

- Enemy memory adapting to your policy bias
- Logistics throughput caps
- Multi-stage assault objectives
- Autonomous drone intelligence routing

---

This completes the Infrastructure Policy Layer specification and Codex implementation plan.



=== INFRASTRUCTURE_POLICY_LAYER-FINAL.md ===

```
docs/INFRASTRUCTURE_POLICY_LAYER.md
```

and then executed by Codex step-by-step.

---

# INFRASTRUCTURE POLICY LAYER

## Between-Assault Strategic Systems Specification

---

# 1. PURPOSE

This document defines the **Infrastructure Policy Layer**, a strategic control system that governs:

* Repair behavior
* Defense readiness
* Surveillance intensity
* Fabrication allocation
* Sector fortification posture
* Power load balancing

The goal is to:

* Transform between-assault pacing into colony/factory-style strategic optimization
* Eliminate vague policy labels (e.g. “CONSERVATIVE”, “HARDENED”)
* Replace hidden enum modes with explicit tradeoffs
* Preserve terminal-first UX
* Avoid numeric overload or spreadsheet feel
* Maintain deterministic simulation and seed reproducibility

This system does not replace assaults.
It makes assaults a stress test of infrastructure decisions.

---

# 2. DESIGN PRINCIPLES

## 2.1 No Blind Policies

Every adjustable system must show:

* What increases
* What decreases
* What it costs

No vague adjectives without consequences.

---

## 2.2 Textual Sliders, Not Raw Numbers

Policies are represented as discrete bands:

```
0 – 4 integer scale
```

Rendered as:

```
▮▮▯▯▯ (2/5)
```

With clear effect description.

No decimals shown to player.

---

## 2.3 Tradeoffs Are Mandatory

Increasing one dimension must impact another:

* Defense ↔ Power
* Repair ↔ Materials
* Surveillance ↔ Brownout Risk
* Fabrication ↔ Defense Load

---

# 3. CORE POLICY SYSTEMS

The Infrastructure Policy Layer introduces five global sliders.

Each slider is 0–4.

---

# 3.1 Repair Intensity

Controls autonomous and queued repair behavior.

### Effects

| Level | Effect Summary                            |
| ----- | ----------------------------------------- |
| 0     | Slow repair, minimal material usage       |
| 2     | Balanced repair rate                      |
| 4     | Rapid repair, high material + power drain |

### Internal Mapping

```python
REPAIR_SPEED = [0.5, 0.75, 1.0, 1.4, 1.8]
REPAIR_MATERIAL_MULT = [0.5, 0.75, 1.0, 1.5, 1.7]
REPAIR_POWER_MULT = [0.8, 0.9, 1.0, 1.2, 1.4]
```

---

# 3.2 Defense Readiness

Controls turret cycling, patrol drones, response intensity.

### Effects

| Level | Effect Summary                    |
| ----- | --------------------------------- |
| 0     | Minimal readiness, low power draw |
| 2     | Standard                          |
| 4     | Rapid response, high power + wear |

### Internal Mapping

```python
DEFENSE_MULT = [0.6, 0.8, 1.0, 1.3, 1.6]
DEFENSE_POWER_DRAW = [0.7, 0.85, 1.0, 1.25, 1.5]
WEAR_RATE = [0.5, 0.75, 1.0, 1.3, 1.6]
```

---

# 3.3 Surveillance Coverage

Controls detection speed and fidelity strength.

### Effects

| Level | Effect Summary                            |
| ----- | ----------------------------------------- |
| 0     | Delayed intrusion alerts                  |
| 2     | Normal detection                          |
| 4     | Near-immediate detection, high power load |

```python
DETECTION_SPEED = [0.6, 0.8, 1.0, 1.3, 1.6]
FIDELITY_BUFFER = [0.5, 0.75, 1.0, 1.2, 1.5]
SURVEILLANCE_POWER = [0.6, 0.8, 1.0, 1.3, 1.6]
```

---

# 3.4 Fabrication Allocation

Controls queue throughput.

Fabrication uses weighted distribution:

```
DEFENSE
DRONES
REPAIRS
ARCHIVE HARDENING
```

Each category receives 0–4 allocation.

Throughput proportional to allocation weight.

---

# 3.5 Sector Fortification (Per-Sector)

Each sector has independent fortification level 0–4.

### Effects

* Structural resistance multiplier
* Increased power demand
* Reduced fabrication throughput in that sector

```python
FORTIFICATION_MULT = [1.0, 1.1, 1.25, 1.5, 1.8]
FORTIFICATION_POWER = [0, 0.05, 0.1, 0.15, 0.25]
```

---

# 4. RENDERING SYSTEM

Add:

```
core/policies.py
```

---

## Policy Dataclass

```python
from dataclasses import dataclass

@dataclass
class PolicyState:
    repair_intensity: int = 2
    defense_readiness: int = 2
    surveillance_coverage: int = 2
```

Attach to GameState:

```python
self.policies = PolicyState()
```

---

## Render Helper

```python
def render_slider(level: int) -> str:
    filled = "▮" * level
    empty = "▯" * (5 - level)
    return f"{filled}{empty} ({level}/5)"
```

---

## STATUS Integration

Modify:

```
terminal/commands/status.py
```

Add section:

```
POLICY STATE

REPAIR INTENSITY
▮▮▮▯▯
+ Moderate repair speed
- Moderate material drain

DEFENSE READINESS
▮▮▮▮▯
+ Strong response
- Increased power load
```

Descriptions are derived from lookup tables.

---

# 5. FABRICATION QUEUE SYSTEM

Create:

```
core/fabrication.py
```

---

## FabricationTask

```python
@dataclass
class FabricationTask:
    name: str
    ticks_remaining: int
    material_cost: int
    category: str
```

GameState:

```python
self.fabrication_queue: list[FabricationTask] = []
```

---

## Tick Processing

In world tick:

```python
def tick_fabrication(state):
    if not state.fabrication_queue:
        return

    allocation_weight = state.fab_allocation[current_task.category]
    speed_mult = 0.5 + (allocation_weight * 0.25)

    current_task.ticks_remaining -= speed_mult
```

Power consumption increases based on throughput.

---

# 6. POWER LOAD SYSTEM

Add:

```
core/power_load.py
```

Compute system load each tick:

```python
def compute_power_load(state):
    base = 1.0
    base += DEFENSE_POWER_DRAW[state.policies.defense_readiness]
    base += SURVEILLANCE_POWER[state.policies.surveillance_coverage]
    base += REPAIR_POWER_MULT[state.policies.repair_intensity]
    base += sum(FORTIFICATION_POWER[level] for level in state.sector_fort_levels.values())

    state.power_load = base
```

Brownout chance tied to power_load.

---

# 7. WEAR & PASSIVE DEGRADATION

In world tick:

```python
def apply_wear(state):
    wear_factor = WEAR_RATE[state.policies.defense_readiness]
    for sector in state.sectors:
        sector.integrity -= 0.01 * wear_factor
```

Clamped at minimum.

This forces maintenance.

---

# 8. PLAYER COMMANDS

Add:

```
set repair 0-4
set defense 0-4
set surveillance 0-4
fortify <sector> 0-4
```

Implement in:

```
terminal/commands/policy.py
```

Example:

```python
def cmd_set_repair(state, level):
    state.policies.repair_intensity = int(level)
    return ["REPAIR INTENSITY UPDATED."]
```

---

# 9. AFTER-ACTION SUMMARY INTEGRATION

After assault:

* Display destroyed buildings
* Display policy load state
* Show delta effects

---

# 10. IMPLEMENTATION PLAN (ORDERED)

Codex must implement in this order:

1. Create `core/policies.py`
2. Attach PolicyState to GameState
3. Implement render_slider
4. Integrate policy section into STATUS
5. Create fabrication system + queue
6. Add fabrication tick to world loop
7. Add power_load module
8. Integrate power load into brownout logic
9. Add passive wear system
10. Add policy command handlers
11. Update docs:

* `docs/INFRASTRUCTURE_POLICY_LAYER.md`
* Update `docs/CURRENT_STATE.md`
* Update `_ai_context` if necessary

12. Add tests:

* Policy state mutation
* Fabrication speed scaling
* Power load increasing with policy levels
* Wear scaling

---

# 11. ARCHITECTURAL FIT

This integrates cleanly because:

* Uses existing tick loop
* Uses existing state object
* Respects deterministic seed
* Does not alter assault logic
* Expands between-assault pacing
* No UI creep beyond terminal rendering

---

# 12. RESULTING GAME LOOP

Between assaults:

* Allocate fabrication bandwidth
* Adjust repair intensity
* Tune defense readiness
* Balance surveillance
* Fortify key sectors
* Monitor system load
* Manage degradation

Assault hits.

Infrastructure decisions determine outcome.

Recovery phase begins.

---

# 13. STRATEGIC IDENTITY

This is not:

* RimWorld
* Factorio
* Tower defense

It is:

> Infrastructure resilience command simulation under asymmetric hostile pressure.

---

# NEXT STEP

Once implemented:

We can introduce:

* Enemy memory adapting to your policy bias
* Logistics throughput caps
* Multi-stage assault objectives
* Autonomous drone intelligence routing

---




=== INFRASTRUCTURE_POLICY_LAYER.md ===
This details a full **between-assault infrastructure layer spec**, written as real documentation, aligned to the repo, with an actionable Codex implementation plan.

Below is the complete documentation draft + implementation plan.

This is designed to be saved as:

```
docs/INFRASTRUCTURE_POLICY_LAYER.md
```

and then executed by Codex step-by-step.

---

# INFRASTRUCTURE POLICY LAYER

## Between-Assault Strategic Systems Specification

---

# 1. PURPOSE

This document defines the **Infrastructure Policy Layer**, a strategic control system that governs:

* Repair behavior
* Defense readiness
* Surveillance intensity
* Fabrication allocation
* Sector fortification posture
* Power load balancing

The goal is to:

* Transform between-assault pacing into colony/factory-style strategic optimization
* Eliminate vague policy labels (e.g. “CONSERVATIVE”, “HARDENED”)
* Replace hidden enum modes with explicit tradeoffs
* Preserve terminal-first UX
* Avoid numeric overload or spreadsheet feel
* Maintain deterministic simulation and seed reproducibility

This system does not replace assaults.
It makes assaults a stress test of infrastructure decisions.

---

# 2. DESIGN PRINCIPLES

## 2.1 No Blind Policies

Every adjustable system must show:

* What increases
* What decreases
* What it costs

No vague adjectives without consequences.

---

## 2.2 Textual Sliders, Not Raw Numbers

Policies are represented as discrete bands:

```
0 – 4 integer scale
```

Rendered as:

```
▮▮▯▯▯ (2/5)
```

With clear effect description.

No decimals shown to player.

---

## 2.3 Tradeoffs Are Mandatory

Increasing one dimension must impact another:

* Defense ↔ Power
* Repair ↔ Materials
* Surveillance ↔ Brownout Risk
* Fabrication ↔ Defense Load

---

# 3. CORE POLICY SYSTEMS

The Infrastructure Policy Layer introduces five global sliders.

Each slider is 0–4.

---

# 3.1 Repair Intensity

Controls autonomous and queued repair behavior.

### Effects

| Level | Effect Summary                            |
| ----- | ----------------------------------------- |
| 0     | Slow repair, minimal material usage       |
| 2     | Balanced repair rate                      |
| 4     | Rapid repair, high material + power drain |

### Internal Mapping

```python
REPAIR_SPEED = [0.5, 0.75, 1.0, 1.4, 1.8]
REPAIR_MATERIAL_MULT = [0.5, 0.75, 1.0, 1.5, 1.7]
REPAIR_POWER_MULT = [0.8, 0.9, 1.0, 1.2, 1.4]
```

---

# 3.2 Defense Readiness

Controls turret cycling, patrol drones, response intensity.

### Effects

| Level | Effect Summary                    |
| ----- | --------------------------------- |
| 0     | Minimal readiness, low power draw |
| 2     | Standard                          |
| 4     | Rapid response, high power + wear |

### Internal Mapping

```python
DEFENSE_MULT = [0.6, 0.8, 1.0, 1.3, 1.6]
DEFENSE_POWER_DRAW = [0.7, 0.85, 1.0, 1.25, 1.5]
WEAR_RATE = [0.5, 0.75, 1.0, 1.3, 1.6]
```

---

# 3.3 Surveillance Coverage

Controls detection speed and fidelity strength.

### Effects

| Level | Effect Summary                            |
| ----- | ----------------------------------------- |
| 0     | Delayed intrusion alerts                  |
| 2     | Normal detection                          |
| 4     | Near-immediate detection, high power load |

```python
DETECTION_SPEED = [0.6, 0.8, 1.0, 1.3, 1.6]
FIDELITY_BUFFER = [0.5, 0.75, 1.0, 1.2, 1.5]
SURVEILLANCE_POWER = [0.6, 0.8, 1.0, 1.3, 1.6]
```

---

# 3.4 Fabrication Allocation

Controls queue throughput.

Fabrication uses weighted distribution:

```
DEFENSE
DRONES
REPAIRS
ARCHIVE HARDENING
```

Each category receives 0–4 allocation.

Throughput proportional to allocation weight.

---

# 3.5 Sector Fortification (Per-Sector)

Each sector has independent fortification level 0–4.

### Effects

* Structural resistance multiplier
* Increased power demand
* Reduced fabrication throughput in that sector

```python
FORTIFICATION_MULT = [1.0, 1.1, 1.25, 1.5, 1.8]
FORTIFICATION_POWER = [0, 0.05, 0.1, 0.15, 0.25]
```

---

# 4. RENDERING SYSTEM

Add:

```
core/policies.py
```

---

## Policy Dataclass

```python
from dataclasses import dataclass

@dataclass
class PolicyState:
    repair_intensity: int = 2
    defense_readiness: int = 2
    surveillance_coverage: int = 2
```

Attach to GameState:

```python
self.policies = PolicyState()
```

---

## Render Helper

```python
def render_slider(level: int) -> str:
    filled = "▮" * level
    empty = "▯" * (5 - level)
    return f"{filled}{empty} ({level}/5)"
```

---

## STATUS Integration

Modify:

```
terminal/commands/status.py
```

Add section:

```
POLICY STATE

REPAIR INTENSITY
▮▮▮▯▯
+ Moderate repair speed
- Moderate material drain

DEFENSE READINESS
▮▮▮▮▯
+ Strong response
- Increased power load
```

Descriptions are derived from lookup tables.

---

# 5. FABRICATION QUEUE SYSTEM

Create:

```
core/fabrication.py
```

---

## FabricationTask

```python
@dataclass
class FabricationTask:
    name: str
    ticks_remaining: int
    material_cost: int
    category: str
```

GameState:

```python
self.fabrication_queue: list[FabricationTask] = []
```

---

## Tick Processing

In world tick:

```python
def tick_fabrication(state):
    if not state.fabrication_queue:
        return

    allocation_weight = state.fab_allocation[current_task.category]
    speed_mult = 0.5 + (allocation_weight * 0.25)

    current_task.ticks_remaining -= speed_mult
```

Power consumption increases based on throughput.

---

# 6. POWER LOAD SYSTEM

Add:

```
core/power_load.py
```

Compute system load each tick:

```python
def compute_power_load(state):
    base = 1.0
    base += DEFENSE_POWER_DRAW[state.policies.defense_readiness]
    base += SURVEILLANCE_POWER[state.policies.surveillance_coverage]
    base += REPAIR_POWER_MULT[state.policies.repair_intensity]
    base += sum(FORTIFICATION_POWER[level] for level in state.sector_fort_levels.values())

    state.power_load = base
```

Brownout chance tied to power_load.

---

# 7. WEAR & PASSIVE DEGRADATION

In world tick:

```python
def apply_wear(state):
    wear_factor = WEAR_RATE[state.policies.defense_readiness]
    for sector in state.sectors:
        sector.integrity -= 0.01 * wear_factor
```

Clamped at minimum.

This forces maintenance.

---

# 8. PLAYER COMMANDS

Add:

```
set repair 0-4
set defense 0-4
set surveillance 0-4
fortify <sector> 0-4
```

Implement in:

```
terminal/commands/policy.py
```

Example:

```python
def cmd_set_repair(state, level):
    state.policies.repair_intensity = int(level)
    return ["REPAIR INTENSITY UPDATED."]
```

---

# 9. AFTER-ACTION SUMMARY INTEGRATION

After assault:

* Display destroyed buildings
* Display policy load state
* Show delta effects

---

# 10. IMPLEMENTATION PLAN (ORDERED)

Codex must implement in this order:

1. Create `core/policies.py`
2. Attach PolicyState to GameState
3. Implement render_slider
4. Integrate policy section into STATUS
5. Create fabrication system + queue
6. Add fabrication tick to world loop
7. Add power_load module
8. Integrate power load into brownout logic
9. Add passive wear system
10. Add policy command handlers
11. Update docs:

* `docs/INFRASTRUCTURE_POLICY_LAYER.md`
* Update `docs/CURRENT_STATE.md`
* Update `_ai_context` if necessary

12. Add tests:

* Policy state mutation
* Fabrication speed scaling
* Power load increasing with policy levels
* Wear scaling

---

# 11. ARCHITECTURAL FIT

This integrates cleanly because:

* Uses existing tick loop
* Uses existing state object
* Respects deterministic seed
* Does not alter assault logic
* Expands between-assault pacing
* No UI creep beyond terminal rendering

---

# 12. RESULTING GAME LOOP

Between assaults:

* Allocate fabrication bandwidth
* Adjust repair intensity
* Tune defense readiness
* Balance surveillance
* Fortify key sectors
* Monitor system load
* Manage degradation

Assault hits.

Infrastructure decisions determine outcome.

Recovery phase begins.

---

# 13. STRATEGIC IDENTITY

This is not:

* RimWorld
* Factorio
* Tower defense

It is:

> Infrastructure resilience command simulation under asymmetric hostile pressure.

---

# NEXT STEP

Once implemented:

We can introduce:

* Enemy memory adapting to your policy bias
* Logistics throughput caps
* Multi-stage assault objectives
* Autonomous drone intelligence routing

---

This completes the Infrastructure Policy Layer specification and Codex implementation plan.



=== INFRASTRUCTURE_POLICY_LAYER_NEXT_STEPS.md ===
# Infrastructure Policy Layer: Recommended Next Steps

## Purpose
This document proposes the next implementation stage after `feature_planning/INFRASTRUCTURE_POLICY_LAYER-FINAL.md`.
It is scoped to current live systems in:
- `game/simulations/world_state/core/policies.py`
- `game/simulations/world_state/core/fabrication.py`
- `game/simulations/world_state/core/power_load.py`
- `game/simulations/world_state/core/wear.py`
- `game/simulations/world_state/terminal/commands/policy.py`
- `game/simulations/world_state/terminal/commands/status.py`

## Current Baseline
Implemented now:
- Policy sliders and command surface (`SET`, `SET FAB`, `FORTIFY`)
- Policy-aware STATUS block
- Fabrication queue tick processing
- Power-load computation and brownout pressure linkage
- Passive wear tied to defense readiness
- Fortification impact on incoming assault pressure
- After-action policy load summary line

Main remaining gap:
- Fabrication queue is internally ticked but not fully operator-driven as a strategic production loop.

## Recommended Next Step 1: Fabrication Command Surface
### Goal
Make fabrication queue a first-class operator loop.

### Add Commands
- `FAB QUEUE` (view queue + throughput estimate)
- `FAB ADD <CATEGORY> <TASK> <TICKS> <COST>`
- `FAB CANCEL <INDEX>`

### Files
- Add `game/simulations/world_state/terminal/commands/fabrication.py`
- Wire in `game/simulations/world_state/terminal/processor.py`
- Export in `game/simulations/world_state/terminal/commands/__init__.py`
- Add command lines to `game/simulations/world_state/terminal/commands/help.py`

### Rules
- Validate category against `FAB_CATEGORIES`
- Material reservation on add, refund policy on cancel (e.g., 50%)
- Keep deterministic ordering and single-tick progression

### Tests
- New: `game/simulations/world_state/tests/test_fabrication_commands.py`
- Cover add/list/cancel, invalid args, and progression with policy allocation changes

## Recommended Next Step 2: Policy Delta in After-Action
### Goal
Satisfy "delta effects" with meaningful, compact post-assault feedback.

### Add Data Capture
Record assault-start snapshot fields:
- power load
- policy levels
- readiness
- top 3 sector damage values

### Output
Extend after-action summary in `game/simulations/world_state/core/assaults.py`:
- `POLICY LOAD DELTA: <before> -> <after>`
- `READINESS DELTA: <before> -> <after>`
- `MOST DEGRADED: <SECTOR...>`

### Files
- `game/simulations/world_state/core/state.py` (snapshot buffer)
- `game/simulations/world_state/core/assaults.py` (summary generation)

### Tests
- Extend `game/simulations/world_state/tests/test_assault_misc_design.py`

## Recommended Next Step 3: Surveillance Coverage Hooks
### Goal
Make surveillance policy affect more than status semantics.

### Integrations
- Approach warning lead time and certainty tied to `surveillance_coverage`
- Fidelity downgrade pressure scaled by low surveillance policy

### Files
- `game/simulations/world_state/core/assaults.py`
- `game/simulations/world_state/terminal/commands/wait.py`
- `game/simulations/world_state/core/power.py`

### Tests
- Add/extend warning timing and fidelity transition tests

## Recommended Next Step 4: Logistics Throughput Caps
### Goal
Prevent infinite high-policy operation without economic planning.

### Mechanic
- Introduce per-tick logistics budget derived from power load and fabrication state
- High policy settings consume budget faster
- Deficits create temporary policy penalties and repair/fab slowdowns

### Files
- New: `game/simulations/world_state/core/logistics.py`
- Integrate in `game/simulations/world_state/core/simulation.py`
- Surface in `game/simulations/world_state/terminal/commands/status.py`

### Tests
- New: `game/simulations/world_state/tests/test_logistics.py`

## Recommended Next Step 5: Policy Presets (Operator QoL)
### Goal
Reduce command friction while preserving explicit tradeoffs.

### Add Commands
- `POLICY PRESET <SIEGE|RECOVERY|LOW_POWER|BALANCED>`
- `POLICY SHOW`

### Files
- Extend `game/simulations/world_state/terminal/commands/policy.py`
- Update help and status rendering

### Tests
- Verify preset correctness and invariant compliance

## Delivery Order
1. Fabrication command surface
2. After-action deltas
3. Surveillance hooks
4. Logistics cap system
5. Policy presets

## Acceptance Criteria
- All new commands are reflected in HELP and terminal contract tests
- World tick remains deterministic with fixed seed
- Policy changes produce visible tactical/operational consequences within 5-20 ticks
- `./.venv/bin/pytest -q game/simulations/world_state/tests`
- `./.venv/bin/pytest -q tests/test_simulation_step_world.py`



=== INFRASTRUCTURE-REVIEW-CHECK-STATE.md ===
This is a check for the existence of a **between-assault infrastructure layer spec**, implemented in full according to the design document below.

This document is the complete documentation draft + implementation plan.

---

# INFRASTRUCTURE POLICY LAYER

## Between-Assault Strategic Systems Specification

---

# 1. PURPOSE

This document defines the **Infrastructure Policy Layer**, a strategic control system that governs:

* Repair behavior
* Defense readiness
* Surveillance intensity
* Fabrication allocation
* Sector fortification posture
* Power load balancing

The goal is to:

* Transform between-assault pacing into colony/factory-style strategic optimization
* Eliminate vague policy labels (e.g. “CONSERVATIVE”, “HARDENED”)
* Replace hidden enum modes with explicit tradeoffs
* Preserve terminal-first UX
* Avoid numeric overload or spreadsheet feel
* Maintain deterministic simulation and seed reproducibility

This system does not replace assaults.
It makes assaults a stress test of infrastructure decisions.

---

# 2. DESIGN PRINCIPLES

## 2.1 No Blind Policies

Every adjustable system must show:

* What increases
* What decreases
* What it costs

No vague adjectives without consequences.

---

## 2.2 Textual Sliders, Not Raw Numbers

Policies are represented as discrete bands:

```
0 – 4 integer scale
```

Rendered as:

```
▮▮▯▯▯ (2/5)
```

With clear effect description.

No decimals shown to player.

---

## 2.3 Tradeoffs Are Mandatory

Increasing one dimension must impact another:

* Defense ↔ Power
* Repair ↔ Materials
* Surveillance ↔ Brownout Risk
* Fabrication ↔ Defense Load

---

# 3. CORE POLICY SYSTEMS

The Infrastructure Policy Layer introduces five global sliders.

Each slider is 0–4.

---

# 3.1 Repair Intensity

Controls autonomous and queued repair behavior.

### Effects

| Level | Effect Summary                            |
| ----- | ----------------------------------------- |
| 0     | Slow repair, minimal material usage       |
| 2     | Balanced repair rate                      |
| 4     | Rapid repair, high material + power drain |

### Internal Mapping

```python
REPAIR_SPEED = [0.5, 0.75, 1.0, 1.4, 1.8]
REPAIR_MATERIAL_MULT = [0.5, 0.75, 1.0, 1.5, 1.7]
REPAIR_POWER_MULT = [0.8, 0.9, 1.0, 1.2, 1.4]
```

---

# 3.2 Defense Readiness

Controls turret cycling, patrol drones, response intensity.

### Effects

| Level | Effect Summary                    |
| ----- | --------------------------------- |
| 0     | Minimal readiness, low power draw |
| 2     | Standard                          |
| 4     | Rapid response, high power + wear |

### Internal Mapping

```python
DEFENSE_MULT = [0.6, 0.8, 1.0, 1.3, 1.6]
DEFENSE_POWER_DRAW = [0.7, 0.85, 1.0, 1.25, 1.5]
WEAR_RATE = [0.5, 0.75, 1.0, 1.3, 1.6]
```

---

# 3.3 Surveillance Coverage

Controls detection speed and fidelity strength.

### Effects

| Level | Effect Summary                            |
| ----- | ----------------------------------------- |
| 0     | Delayed intrusion alerts                  |
| 2     | Normal detection                          |
| 4     | Near-immediate detection, high power load |

```python
DETECTION_SPEED = [0.6, 0.8, 1.0, 1.3, 1.6]
FIDELITY_BUFFER = [0.5, 0.75, 1.0, 1.2, 1.5]
SURVEILLANCE_POWER = [0.6, 0.8, 1.0, 1.3, 1.6]
```

---

# 3.4 Fabrication Allocation

Controls queue throughput.

Fabrication uses weighted distribution:

```
DEFENSE
DRONES
REPAIRS
ARCHIVE HARDENING
```

Each category receives 0–4 allocation.

Throughput proportional to allocation weight.

---

# 3.5 Sector Fortification (Per-Sector)

Each sector has independent fortification level 0–4.

### Effects

* Structural resistance multiplier
* Increased power demand
* Reduced fabrication throughput in that sector

```python
FORTIFICATION_MULT = [1.0, 1.1, 1.25, 1.5, 1.8]
FORTIFICATION_POWER = [0, 0.05, 0.1, 0.15, 0.25]
```

---

# 4. RENDERING SYSTEM

Add:

```
core/policies.py
```

---

## Policy Dataclass

```python
from dataclasses import dataclass

@dataclass
class PolicyState:
    repair_intensity: int = 2
    defense_readiness: int = 2
    surveillance_coverage: int = 2
```

Attach to GameState:

```python
self.policies = PolicyState()
```

---

## Render Helper

```python
def render_slider(level: int) -> str:
    filled = "▮" * level
    empty = "▯" * (5 - level)
    return f"{filled}{empty} ({level}/5)"
```

---

## STATUS Integration

Modify:

```
terminal/commands/status.py
```

Add section:

```
POLICY STATE

REPAIR INTENSITY
▮▮▮▯▯
+ Moderate repair speed
- Moderate material drain

DEFENSE READINESS
▮▮▮▮▯
+ Strong response
- Increased power load
```

Descriptions are derived from lookup tables.

---

# 5. FABRICATION QUEUE SYSTEM

Create:

```
core/fabrication.py
```

---

## FabricationTask

```python
@dataclass
class FabricationTask:
    name: str
    ticks_remaining: int
    material_cost: int
    category: str
```

GameState:

```python
self.fabrication_queue: list[FabricationTask] = []
```

---

## Tick Processing

In world tick:

```python
def tick_fabrication(state):
    if not state.fabrication_queue:
        return

    allocation_weight = state.fab_allocation[current_task.category]
    speed_mult = 0.5 + (allocation_weight * 0.25)

    current_task.ticks_remaining -= speed_mult
```

Power consumption increases based on throughput.

---

# 6. POWER LOAD SYSTEM

Add:

```
core/power_load.py
```

Compute system load each tick:

```python
def compute_power_load(state):
    base = 1.0
    base += DEFENSE_POWER_DRAW[state.policies.defense_readiness]
    base += SURVEILLANCE_POWER[state.policies.surveillance_coverage]
    base += REPAIR_POWER_MULT[state.policies.repair_intensity]
    base += sum(FORTIFICATION_POWER[level] for level in state.sector_fort_levels.values())

    state.power_load = base
```

Brownout chance tied to power_load.

---

# 7. WEAR & PASSIVE DEGRADATION

In world tick:

```python
def apply_wear(state):
    wear_factor = WEAR_RATE[state.policies.defense_readiness]
    for sector in state.sectors:
        sector.integrity -= 0.01 * wear_factor
```

Clamped at minimum.

This forces maintenance.

---

# 8. PLAYER COMMANDS

Add:

```
set repair 0-4
set defense 0-4
set surveillance 0-4
fortify <sector> 0-4
```

Implement in:

```
terminal/commands/policy.py
```

Example:

```python
def cmd_set_repair(state, level):
    state.policies.repair_intensity = int(level)
    return ["REPAIR INTENSITY UPDATED."]
```

---

# 9. AFTER-ACTION SUMMARY INTEGRATION

After assault:

* Display destroyed buildings
* Display policy load state
* Show delta effects

---

# 10. IMPLEMENTATION PLAN (ORDERED)

Codex must implement in this order:

1. Create `core/policies.py`
2. Attach PolicyState to GameState
3. Implement render_slider
4. Integrate policy section into STATUS
5. Create fabrication system + queue
6. Add fabrication tick to world loop
7. Add power_load module
8. Integrate power load into brownout logic
9. Add passive wear system
10. Add policy command handlers
11. Update docs:

* `docs/INFRASTRUCTURE_POLICY_LAYER.md`
* Update `docs/CURRENT_STATE.md`
* Update `_ai_context` if necessary

12. Add tests:

* Policy state mutation
* Fabrication speed scaling
* Power load increasing with policy levels
* Wear scaling

---

# 11. ARCHITECTURAL FIT

This integrates cleanly because:

* Uses existing tick loop
* Uses existing state object
* Respects deterministic seed
* Does not alter assault logic
* Expands between-assault pacing
* No UI creep beyond terminal rendering

---

# 12. RESULTING GAME LOOP

Between assaults:

* Allocate fabrication bandwidth
* Adjust repair intensity
* Tune defense readiness
* Balance surveillance
* Fortify key sectors
* Monitor system load
* Manage degradation

Assault hits.

Infrastructure decisions determine outcome.

Recovery phase begins.

---

# 13. STRATEGIC IDENTITY

This is not:

* RimWorld
* Factorio
* Tower defense

It is:

> Infrastructure resilience command simulation under asymmetric hostile pressure.

---

# NEXT STEP

Review the current game state and full repository. Ensure that all items above are fully realized in the codebase. Once that is verified: 

Determine the best next step to introduce:

* Enemy memory adapting to your policy bias
* Logistics throughput caps
* Multi-stage assault objectives
* Autonomous drone intelligence routing

---

This completes the Infrastructure Policy Layer specification and Codex implementation plan.



=== POWER_SYSTEMS.md ===

Below is a grounded but expressive system that integrates:

* Power tiers
* Autopilot
* Repairs
* Damage states
* Information fidelity
* Assault pressure

---

# POWER × PERFORMANCE — EXACT MATH

We formalize three axes:

1. **Power Tier**
2. **Structural Integrity**
3. **Operational Output**

Output is a function of both power and damage.

---

# 1️⃣ Power Tier Math

For every structure:

```
allocated_power = routed_power[structure_id]
min_power
standard_power
```

Define:

```
power_ratio = allocated_power / standard_power
```

Power Tier Classification:

| Condition                  | Tier     | power_efficiency     |
| -------------------------- | -------- | -------------------- |
| allocated < min            | OFFLINE  | 0.0                  |
| min ≤ allocated < standard | DEGRADED | allocated / standard |
| allocated ≥ standard       | NORMAL   | 1.0                  |

Note:

* We cap efficiency at 1.0.
* No overcharge in Phase I.

---

# 2️⃣ Structural Integrity Math

Structure states:

| State       | integrity_modifier |
| ----------- | ------------------ |
| OPERATIONAL | 1.0                |
| DAMAGED     | 0.75               |
| OFFLINE     | 0.0                |
| DESTROYED   | 0.0                |

(DESTROYED handled separately in routing.)

---

# 3️⃣ Final Operational Output

For any powered structure:

```
effective_output = power_efficiency * integrity_modifier
```

This produces a continuous scalar between 0.0 and 1.0.

This scalar drives:

* Fire rate
* Accuracy
* Range
* Repair speed
* Fabrication throughput
* Sensor fidelity modifier

---

# 4️⃣ Defense Performance (Exact)

## 4.1 Turret Example

Base stats:

```
base_fire_interval = 2 ticks
base_accuracy = 0.7
base_damage = 1
```

Adjusted:

```
fire_interval = base_fire_interval / effective_output
accuracy = base_accuracy * effective_output
damage = base_damage * effective_output
```

Clamp rules:

* If effective_output < 0.2 → turret misfires (no shot this tick)
* If effective_output == 0 → inoperable

Example:

* Power 1/2 (0.5)
* DAMAGED (0.75)

```
effective_output = 0.5 * 0.75 = 0.375
```

Turret now:

* Fires every 5.33 ticks
* Accuracy = 0.2625
* Damage = 0.375

That feels weak — and visibly so — but not binary.

---

## 4.2 Blast Door

Binary system.

If effective_output ≥ 0.5 → operational
If < 0.5 → opens slower
If 0 → fails open

Door open/close time:

```
open_time = base_open_time / max(effective_output, 0.25)
```

---

# 5️⃣ Fabricator Performance

Fabrication progress per tick:

```
progress += base_rate * effective_output
```

If below min power → zero progress
If damaged + low power → crawl speed

---

# 6️⃣ Mechanic Drone Repair Speed

Repair speed:

```
repair_ticks_remaining -= base_repair_rate * effective_output
```

This means:

Low power slows repairs.
Damaged drone system slows repairs.
Both stack multiplicatively.

---

# 7️⃣ Sensor Fidelity Modifier

Sensors influence information degradation.

Define:

```
sensor_effectiveness = effective_output
```

Information fidelity downgrade trigger:

| sensor_effectiveness | max fidelity |
| -------------------- | ------------ |
| ≥ 0.9                | FULL         |
| ≥ 0.6                | DEGRADED     |
| ≥ 0.3                | FRAGMENTED   |
| < 0.3                | LOST         |

This ties power decisions directly to informational clarity.

That’s powerful.

---

# 8️⃣ Repair System Integration

Now we integrate power into repairs.

---

# Repair State Machine Interaction

Repair progress is affected by:

1. Mechanic drone power
2. Sector power availability
3. Assault state

---

## 8.1 Base Repair Equation

For a structure under repair:

```
repair_speed = base_repair_speed
             * mechanic_drone_effective_output
             * sector_power_modifier
```

Where:

```
sector_power_modifier = 1.0 if sector has ≥ min_power
                        0.5 if degraded
                        0.0 if inoperable
```

So:

* Underpowered sector = slow repair
* Underpowered drones = slow repair
* Both underpowered = very slow repair

---

# 9️⃣ Repair During Assault — Creative but Grounded

During active assault:

Add instability penalty:

```
if state.in_assault:
    repair_speed *= 0.75
```

Additionally:

Each time the repaired structure’s sector takes damage:

```
repair_ticks_remaining += 1  # regression event
```

So repairs can slide backward under pressure.

No randomness required.

---

# 🔥 Risky Play: Field Power + Repair

If player banks portable power and deploys to a damaged turret mid-assault:

* Power raises effective_output
* Turret regains partial fire capability
* Repair speed increases if mechanic drones are powered

But:

Portable bank is finite.

So the player must choose:

* Power sensors?
* Power drones?
* Power turret?

Real decision.

---

# 10️⃣ Repair Cost Interaction with Power

Reconstruction (DESTROYED → OFFLINE):

Requires:

* Materials
* Minimum sector power online
* Mechanic drones powered at ≥ min

If either is not met:

Repair cannot start.

This forces infrastructure restoration before resurrection.

---

# 11️⃣ Cascading Failure Dynamics

Here’s where it gets interesting.

If:

* Player powers Fabricator heavily
* Leaves Defense underpowered

Then during assault:

* Turrets weak
* Repairs slow
* Sensor fidelity drops
* STATUS degrades

The world feels fragile.

But never unfair.

Because:

Everything is deterministic.

---

# 12️⃣ Edge Case Handling

## Case: Power removed mid-repair

If sector power falls below min:

* Repair pauses
* No progress lost
* Unless assault damage event triggers regression

---

## Case: System destroyed during repair

* Repair task cancelled
* Power freed
* Materials partially refunded (50%)

---

## Case: Mechanic drones unpowered

Repair_speed = 0
But manual player repair (future embodied mode) can bypass this.

---

# 13️⃣ Emergent Behavior Created

This system produces:

* Strategic triage
* Power-driven repair urgency
* Information loss from bad routing
* Visible degradation curve
* Recoverable but punishing mistakes

All without:

* Random spikes
* Hidden timers
* Background drains

---

# 14️⃣ Why This Is Grounded

We didn’t invent:

* Overcharge mechanics
* Arbitrary cooldowns
* Soft caps
* Artificial complexity

Everything is:

```
effective_output = power_ratio × integrity
```

One formula.
Applied everywhere.

Elegant systems scale.

---

# If You Want To Go Further

Next logical extension:

* Power load spike events during assault
* EMP causing temporary power_efficiency reduction
* Overload risk if reallocating during assault

But do not add that yet.

---

You now have:

* A unified power-performance equation
* Deterministic degraded math
* Repair interaction
* Assault interaction
* Information degradation linkage
* Tactical field routing impact

This is cohesive.

If you want, next we can:

* Write exact code patch diff plan
* Or simulate a first assault with this system numerically to test balance



=== PROCEDURAL_GENERATION_RESEARCH.md ===
# Procedural Description Generation in CUSTODIAN: Deterministic Event Logic with Constrained, High-Variation Terminal Text

## Repo-derived constraints

The repo’s current “spine” is a command-driven world simulation with a terminal-first UI, where **simulation state is authoritative** and presentation is downstream. That separation is already visible in the structure: `GameState` (authoritative world state), `step_world` (authoritative tick), and terminal `/command` processing that returns a `CommandResult` payload with a primary line plus optional detail lines (`text`, `lines`, `warnings`). The browser terminal is explicitly a thin client that posts commands and renders the returned lines rather than inferring changes client-side.  

A concise list of **design constraints & invariants** that matter directly for event + description generation:

- **Knowledge-first, reconstruction-first tone and progression**: the “north star” is preservation/reconstruction rather than extermination, and “knowledge changes what exists” rather than acting as XP. (Design intent is explicit in `docs/Broad_Overview_Design_Rules.md`.)  
- **Static, sectorized base form factor is locked**: the base is not an infinite builder; it’s a fixed/sectorized outpost where capability loss matters more than “HP.” (`docs/Broad_Overview_Design_Rules.md`, `docs/PROJECT_MAP.md`, and the current Phase 1 sector set in `game/simulations/world_state/core/config.py`.)  
- **Terminal-first interface; minimal, scannable, operational output**: “terse, grounded output,” all-caps conventions for STATUS, and “avoid verbose narration or speculative text.” (`docs/_ai_context/AI_CONTEXT.md`, `docs/README.md` and the actual command outputs in `terminal/commands/status.py` and `terminal/commands/wait.py`.)  
- **Time advances only via explicit operator action in terminal mode**: STATUS is read-only; WAIT/WAIT NX advance time in discrete ticks (5 ticks per WAIT unit) and emit observed lines. (`docs/_ai_context/AI_CONTEXT.md`, `game/simulations/world_state/docs/terminal-repl.md`, `terminal/commands/wait.py`.)  
- **Authority is location-/mode-based**: command/field asymmetry is enforced in the processor (e.g., field mode denies FOCUS/HARDEN/SCAVENGE). (`docs/_ai_context/AI_CONTEXT.md`, `terminal/processor.py`, plus move/deploy/return support.)  
- **Information degradation is a hard rule (not vibes)**: COMMS state drives fidelity: `FULL > DEGRADED > FRAGMENTED > LOST`. STATUS is “filtered truth” (never lies), WAIT is “filtered inference” (may be wrong at low fidelity but must remain plausible). STATUS certainty must always be ≥ WAIT certainty at the same fidelity. STATUS must never imply trends; trend/interpretation is WAIT-only. (`docs/INFORMATION_DEGRADATION.md` and implemented in `terminal/commands/status.py` and `terminal/commands/wait.py`.)  
- **Output composition rules are strict**: fixed section ordering for STATUS; WAIT output order is primary line then detail lines; WAIT may include at most one interpretive line per WAIT; LOST fidelity suppresses detail lines; FRAGMENTED suppresses subsystem naming and constrains assault signaling. (`docs/INFORMATION_DEGRADATION.md`, `terminal/commands/wait.py`.)  
- **Failure is latched and changes command affordances**: when COMMAND breach or archive loss limit hits, the session latches failure and only RESET/REBOOT are accepted, with a fixed failure phrasing strategy. (`terminal/processor.py`, `core/state.py`, `game/simulations/world_state/docs/terminal-repl.md`.)  
- **Damage model is structure-level, sectors are an aggregate view**: structures are in one of `OPERATIONAL / DAMAGED / OFFLINE / DESTROYED`, and sectors (in STATUS) are derived from structures (damaged structure forces sector “DAMAGED” aggregation). (`docs/SystemDesign.md` “Locked Decisions”; implemented in `core/structures.py` and `GameState.snapshot()` in `core/state.py`.)  
- **Repairs cost resources and advance on ticks**: repairs are explicit tasks tracked as `active_repairs` with per-tick decrement; repair visibility itself is fidelity-bound. (`core/repairs.py`, `terminal/commands/repair.py`, `terminal/commands/status.py`.)  

### How events are represented now

Events in the current world-state simulation are “ambient events” defined as **callable effects** applied to `GameState` + a chosen `SectorState`.

- **Event definition shape (current)**: `AmbientEvent(name, min_threat, weight, cooldown, sector_filter, effect, chains=...)`. (`game/simulations/world_state/core/events.py`.)  
- **Catalog construction**: `EVENT_ARCHETYPES` is a list of dict archetypes (key, min_threat, weight, cooldown, tags, optional min_damage/max_power, effect fn, and naming templates). `build_event_catalog()` binds faction-profile label/tech into templates and builds a list of `AmbientEvent`s, stored in `state.event_catalog`. (`core/events.py`, `core/factions.py`.)  
- **Selection**: candidates are all (event, sector) pairs that pass `can_trigger()` (threat threshold, sector filter, cooldown). A probability gate based on ambient threat (and a hangar damage bonus) decides whether *an* event triggers this tick. Chosen event uses weight replication and `random.choice`. (`core/events.py`, `core/config.py`.)  
- **State changes**: effects directly mutate scalar state and sector metrics (damage/alertness/power/occupied), may alter the assault timer, and may add persistent effects via `add_sector_effect` / `add_global_effect` that decay over time and apply per tick. (`core/events.py`, `core/effects.py`, `core/state.advance_time()`.)  

### What the simulation needs from events (as implemented)

The simulation’s “needs” from events are already evident in what the effects mutate and what the terminal layer observes:

- **Timing and pacing**: events are constrained by `min_threat`, per-(event, sector) cooldown tracking (`state.event_cooldowns`), and a probability gate tied to ambient threat. (`core/events.py`.)  
- **State mutation surface** (authoritative outcomes):  
  - Per-sector: `damage`, `alertness`, `power`, `occupied`, `effects`, `last_event`. (`core/state.py`, `core/events.py`, `core/effects.py`.)  
  - Global: `ambient_threat`, `assault_timer`, `global_effects`. (`core/state.py`, `core/events.py`.)  
- **Observability hooks** (what player output currently keys on): `sector.last_event` + `state.event_cooldowns` for event detection, COMMS status for fidelity, repair completion lines, and assault timer “warning window” behavior. (`terminal/commands/wait.py`, `terminal/commands/status.py`.)  
- **Persistence**: sector/global effects are persistent/decaying; repairs are persistent and complete on ticks; assaults have a lifecycle and apply damage to structures at the end. (`core/effects.py`, `core/repairs.py`, `core/assaults.py`.)  

## Recommended architecture

What you want—**explicit, deterministic event logic** with **highly variable but never-lying textual presentation**—maps cleanly onto the repo’s existing separation. The key is to introduce one additional intermediate artifact between simulation and text: a **canonical event record** and a **canonical “narrative surface”** that enumerates allowed facts and redactions.

A concrete pipeline that matches your example structure and fits the current code layout:

1. **Event selection / instantiation (seeded)**  
   - Use a deterministic RNG owned by the simulation (e.g., `state.sim_rng`) for: ambient event trigger tests, weighted selection, assault timer values, assault duration, tactical bridge randomness, scavenge yields, etc.  
   - Produce an `EventInstance` record when an event triggers (event id/key, tick, sector id/name, and *pre/post* or explicit deltas).  
   - Important: the event record is not prose; it is an audit-friendly artifact.

2. **Simulation resolution (authoritative state transition)**  
   - Apply the event’s effect function(s) to `GameState`.  
   - Apply per-tick decay/effects (`advance_time()` already does this).  
   - Resolve repairs and assault lifecycle.  
   - This stage remains the only place that changes truth.

3. **Observability layer (fidelity + authority + location)**  
   - Compute a `Fidelity` from COMMS status using the same mapping already embedded in `STATUS`/`WAIT`:  
     - `COMMS STABLE → FULL`  
     - `COMMS ALERT → DEGRADED`  
     - `COMMS DAMAGED → FRAGMENTED`  
     - `COMMS COMPROMISED → LOST`  
   - Reduce `EventInstance` and other tick outputs (repair completion, assault warning/start/end, movement task completion) into an `ObservedSignal` list that contains only facts the player is allowed to perceive.  
   - This is where you enforce “STATUS certainty ≥ WAIT certainty,” “no subsystem names below DEGRADED,” “LOST yields no detail lines,” etc. It should be a pure function.

4. **Description generation (variable text, constrained by #2 and #3)**  
   - Take each `ObservedSignal` and render it into 0–2 terminal lines using a seeded text RNG that is **separate from the simulation RNG**.  
   - All text is generated from curated templates/grammar and typed slots; no free-form hallucination.  
   - Variation comes from choosing among equivalent templates/synonyms, not from inventing new facts.

5. **Output formatting (terminal UI surface)**  
   - Enforce canonical ordering and suppression rules: primary line first (`TIME ADVANCED.` / `TIME ADVANCED xN.`), then event/warning lines, then at most one interpretive line.  
   - Keep all caps and bracket tags exactly as defined.  
   - Retain immediate-duplicate suppression behavior (already implemented in `cmd_wait_ticks`).  

## Schemas (event + narrative surface)

Below are schemas that align with your current implementation while adding the minimum structure needed to support variable narration safely.

```python
# Canonical simulation artifact (authoritative, deterministic)
@dataclass(frozen=True)
class EventDef:
    id: str                  # e.g. "power_brownout"
    min_threat: float
    weight: int
    cooldown_ticks: int
    tags: set[str]           # mirrors sector tags usage
    # Optional filters to match current _build_sector_filter:
    min_damage: float | None = None
    max_power: float | None = None
    # Deterministic effect function:
    apply: Callable[[GameState, SectorState], None]
    # Optional deterministic chaining (still sim-owned):
    chain_ids: list[str] = field(default_factory=list)

@dataclass(frozen=True)
class EventInstance:
    instance_id: str         # stable id per trigger (tick + counter)
    event_id: str            # EventDef.id
    tick: int                # state.time when applied
    sector_id: str           # e.g. "PW"
    sector_name: str         # e.g. "POWER"
    # Outcome facts for downstream use (debugging + observability)
    deltas: dict[str, Any]   # e.g. {"sector.power": -0.2, "sector.alertness": +0.6, "add_effect": "power_drain"}
    # Optionally: pre/post snapshots for dev tooling (not required for runtime)
```

```python
# Presentation artifact (what the renderer is allowed to express)
class Fidelity(Enum):
    FULL = "FULL"
    DEGRADED = "DEGRADED"
    FRAGMENTED = "FRAGMENTED"
    LOST = "LOST"

@dataclass(frozen=True)
class NarrativeSurface:
    fidelity: Fidelity
    # What kind of signal this is (maps to bracket tags)
    channel: Literal["EVENT", "WARNING", "ASSAULT", "STATUS_SHIFT", "REPAIR", "SYSTEM"]
    # Allowed facts (already redacted as needed)
    facts: dict[str, Any]
    # Required content guarantees
    must_include: set[str]   # e.g. {"channel_tag", "actionable_keyword"}
    # Prohibitions / redactions
    forbid: set[str]         # e.g. {"sector_name", "numbers", "precise_counts"}
    # Confidence is a presentation property (not a sim property)
    confidence: Literal["confirmed", "reported", "possible", "no_signal"]
```

The practical rule: **the generator never sees raw `GameState`**, only `NarrativeSurface`. That prevents “cool prose” from accidentally leaking banned information.

## Generation strategy

A hybrid of **templating + grammar + typed slot-filling** fits your constraints better than runtime free-form generation, because it is deterministic, testable, and debuggable.

A useful external pattern here is **author-focused generative text via grammars**, exemplified by entity["people","Kate Compton","tracery creator"]’s Tracery ecosystem (and ports like Allison Parrish’s Python port). These systems generate variation through rule expansion and modifiers, and they can expose a “trace” to debug why a line appeared. citeturn12search0turn12search10  

Another useful pattern is treating narrative scripting as **middleware** that “slots into your own game and UI,” as described for entity["organization","Inkle Studios","interactive narrative studio"]’s Ink: text is primary, logic is inserted, and the runtime returns lines/choices that the game renders. That conceptual boundary (logic vs rendered text) maps closely to your `CommandResult` contract and the “simulation authoritative” rule. citeturn12search6turn12search9  

A concrete strategy for CUSTODIAN:

- **Template families per channel**: EVENT/WARNING/ASSAULT/STATUS_SHIFT/REPAIR each gets a small family of templates with controlled synonym sets.  
- **Typed slots, not free strings**: slots like `PHENOMENON`, `SYSTEM`, `INTENSITY`, `EFFECT_CLASS` are enums or controlled vocab.  
- **Fidelity gates are compile-time constraints**: templates declare `min_fidelity` and `forbidden_tokens`. Example: a template that includes `{system}` cannot be eligible under FRAGMENTED.  
- **Bounded length**: each template declares `max_chars` (or computed), and the renderer picks the shortest that still satisfies “must include.”  
- **Bounded randomness without repetition**: keep a rolling window in a `TextVariantMemory` keyed by (event_id, channel, fidelity) to avoid repeating the same template/synonym choices in adjacent outputs.  
- **Two independent seeds**:  
  - `event_seed` (simulation RNG): controls what happens.  
  - `description_seed` (text RNG): controls which phrasing is chosen among equivalent renderings.  
  - Derive per-line text RNG via a stable hash like `hash(description_seed, instance_id, channel)` so replay is deterministic and testable.

This achieves what you asked for: you explicitly author events and outcomes, while the textual surface stays fresh and non-repetitive without ever contradicting truth.

## Consistency + observability rules

Your repo already encodes the fundamental distinction: **STATUS is filtered truth; WAIT is filtered inference** (`docs/INFORMATION_DEGRADATION.md`) and the implementation in `cmd_status`/`cmd_wait` follows it. The architecture above formalizes this into enforceable rules:

- **Single source of truth**: only simulation writes truth (`GameState`, `EventInstance`, structure state transitions, resource deltas). The generator cannot mutate state.  
- **Observability is a pure projection**: `observe(state, event_instance, fidelity, player_mode) -> NarrativeSurface[]`. If it’s not in `NarrativeSurface.facts`, it cannot be said.  
- **Fidelity-driven redaction is keyed off COMMS status** exactly as already implemented in `STATUS` and `WAIT`.  
- **No contradictions rule becomes structural**:  
  - Templates are only allowed to reference `facts` keys.  
  - Facts keys are derived from authoritative event outcomes.  
  - Therefore, the generator cannot invent “extra outcomes.”  
- **Uncertainty language is not creative writing; it is a mapping table**:  
  - `FULL → confirmed/detected`  
  - `DEGRADED → reported/appears`  
  - `FRAGMENTED → possible/may`  
  - `LOST → no-signal`  
  This mirrors the current wording shift in `terminal/commands/wait.py` and the canonical degradation spec.  
- **Actionability without advice**: “critical actionable information” in CUSTODIAN’s output is primarily: *that a meaningful change occurred*, *which system class is implicated (if allowed)*, and *that stability/hostility is worsening (at most one interpretive line)*. You preserve clarity by ensuring at least one of these appears when meaningful changes occur, while still forbidding explicit recommendations (which the docs prohibit).  
- **Debuggability is a first-class mechanism**: every generated line should carry a debug trace record in dev mode: template id, chosen synonyms, and the fact keys used. Tracery-style systems explicitly support traces of expansion; adopting that idea for your template engine makes “why did this text appear?” answerable. citeturn12search10turn12search0  

## Examples

Single canonical event: **Power brownout** (maps to `power_brownout` in `game/simulations/world_state/core/events.py`, which reduces power, increases alertness, and applies a decaying `power_drain` effect).

To satisfy “same event seed → same state change” and “different description seeds → different text,” each example below treats:

- **Event seed**: drives that the event triggers and picks the target sector (simulation RNG).  
- **Description seed**: drives phrasing choice only (text RNG).  

For readability, each example shows three layers: canonical outcome (debug), observability surface, and terminal output.

### Example A

**Event seed:** `4242`  
**Description seed:** `1001`  
**Fidelity:** FULL (COMMS stable)

**Canonical outcome (authoritative; debug view)**  
- Event: `power_brownout`  
- Sector: `POWER`  
- State deltas (illustrative of the effect function):  
  - `POWER.alertness += 0.6`  
  - `POWER.power -= 0.2` (clamped to ≥ 0.4)  
  - `POWER.effects += power_drain(severity=1.4, decay=0.04)`

**Narrative surface (allowed facts)**  
- channel: `EVENT`  
- facts: `{ phenomenon: "brownout", system: "power", confirmation: "detected" }`  
- forbid: `{numbers}`

**Generated terminal output (FULL)**  
```
TIME ADVANCED.

[EVENT] POWER BUS INSTABILITY DETECTED
[STATUS SHIFT] SYSTEM STABILITY DECLINING
```

### Example B

**Event seed:** `4242` (same authoritative event and deltas as Example A)  
**Description seed:** `9009`  
**Fidelity:** FULL

**Narrative surface** (same facts as Example A)

**Generated terminal output (FULL; different realization)**  
```
TIME ADVANCED.

[EVENT] LOCAL BROWNOUT CONFIRMED
[STATUS SHIFT] SYSTEM STABILITY DECLINING
```

### Example C

**Event seed:** `4242` (same authoritative event and deltas)  
**Description seed:** `1001`  
**Fidelity:** DEGRADED (COMMS alert)

**Observability changes (what gets omitted / softened)**  
- Subsystem naming is still allowed, but certainty must be hedged (“REPORTED”) and directional verbs softened.  
- Still no numeric values in WAIT output.

**Generated terminal output (DEGRADED)**  
```
TIME ADVANCED.

[EVENT] POWER FLUCTUATIONS REPORTED
[STATUS SHIFT] SYSTEM STABILITY APPEARS TO BE DECLINING
```

### Example D

**Event seed:** `4242`  
**Description seed:** `9009`  
**Fidelity:** FRAGMENTED (COMMS damaged)

**Observability changes (stronger redaction)**  
- No subsystem names.  
- Event becomes generic (“IRREGULAR SIGNALS DETECTED”).  
- Trend language becomes “MAY” level.

**Generated terminal output (FRAGMENTED)**  
```
TIME ADVANCED.

[EVENT] IRREGULAR SIGNALS DETECTED
[STATUS SHIFT] INTERNAL CONDITIONS MAY BE WORSENING
```

### Example E

**Event seed:** `4242`  
**Description seed:** `1001`  
**Fidelity:** LOST (COMMS compromised)

**Observability changes**  
- No detail lines (optionally a rare `[NO SIGNAL]` line, per spec).  

**Generated terminal output (LOST)**  
```
TIME ADVANCED.
```

These examples preserve your hard rules: text never contradicts the underlying outcome, never invents new actionable facts, never emits advice, and degrades information exactly as your canonical degradation rules specify.

## Implementation plan

A minimal viable path that fits your current implementation and avoids UI creep:

**Minimal viable path (tight loop, high confidence)**  
1. **Make simulation randomness explicit and testable**  
   - Add `state.sim_rng` (a `random.Random`) seeded once at session start.  
   - Replace direct `random.*` calls in `events.py`, `assaults.py`, and `scavenge.py` with `state.sim_rng.*` so replay with `event_seed` is stable.

2. **Replace “event name string as the only record” with a canonical `EventInstance`**  
   - When an event triggers, create an `EventInstance` with `event_id`, `tick`, `sector_id`, `sector_name`, and a small “delta facts” payload (at least: phenomenon/system class/severity class).  
   - Store it in `state.last_tick_events` (cleared each tick) and/or a bounded ring buffer for debugging.

3. **Introduce an explicit observability function**  
   - Implement `fidelity = fidelity_from_comms(state)` once (you already have it duplicated in WAIT/REPAIR; centralize).  
   - Implement `observe_event(event_instance, state, fidelity) -> NarrativeSurface[]`.  
   - Encode prohibitions directly from `docs/INFORMATION_DEGRADATION.md` (LOST: no details; FRAGMENTED: no subsystem names; etc.).

4. **Implement a constrained text renderer**  
   - Implement a lightweight template engine in Python (you can start with plain format-strings + synonym sets).  
   - If you want a grammar-based expansion approach, a Tracery-style library can be used, but keep it sandboxed: it should expand only from safe, typed slot values. citeturn12search0turn12search10  
   - Add `state.text_seed` (session-level) and derive per-event text RNG with a stable hash of `(text_seed, event_instance_id, channel)`.

5. **Wire into WAIT output without changing the command contract**  
   - Replace `_format_event_line`, `_format_warning_line`, `_format_assault_line`, `_format_status_shift`, and `_format_repair_line` with calls to the renderer fed by `NarrativeSurface`.  
   - Keep the existing suppression logic (immediate-duplicate suppression and “no more than one interpretive line”).

6. **Add narrow, high-value tests**  
   - Snapshot tests per fidelity ensuring:  
     - LOST emits no detail lines.  
     - FRAGMENTED never includes sector names or subsystem tokens.  
     - WAIT emits at most one interpretive line.  
     - STATUS never includes trend verbs.  
   - Property-style tests for “forbidden tokens” (numbers at low fidelity, sector names in summaries, etc.).  

**Extensions that stay consistent with your constraints**  
- **“WHY” / “TRACE” dev-only introspection**: a command that returns the last N `EventInstance`s and their generation traces (template ids + slot values) in a compact format. This strengthens debugging and tuning without adding UI surfaces.  
- **Event taxonomy + severity normalization**: formalize a small enum for phenomenon classes (power, intrusion, structural, comms) so you can select language consistently and maintain tone.  
- **Avoid repetition across sessions**: incorporate a “recent phrase memory” per event type so repeated brownouts do not spam identical lines, while still keeping deterministic replay when the same text seed is used.  
- **Optional ink-like authored “micro-scripts” for rare cases**: if you later need multi-line scripted sequences (e.g., boot sequences, tutorial callouts), Ink provides a model for text-first scripts with embedded logic and a runtime that yields lines in order. This is compatible with your “text is downstream” rule because Ink content still consumes a known state and returns deterministic outputs. citeturn12search6turn12search9  
- **Storyteller-style pacing knobs as configuration, not prose**: your current system already resembles a “storyteller” in the sense that global pressure and timers influence event frequency and severity. If you later want named pacing profiles (steady vs spiky), keep them as parameter sets (rates, cooldown multipliers) rather than narrative logic—similar to how colony sims expose storyteller choices as event pacing/difficulty layers. citeturn12search18turn12search15



=== RECOMMENDED_IMROVEMENTS.md ===
# RECOMMENDED_IMROVEMENTS

## Scope Reviewed
This document recommends hardening changes for the features implemented from `docs/feature_planning` and now moved into `feature_planing/completed/`.

Implemented scope includes:
- Materials economy + SCAVENGE loop
- Material-aware repair progression and reporting
- FABRICATION sector scaffolding
- Stage 1.5 UI hierarchy and map/status refinements
- Embodied Presence Phase A (field mode, travel, authority split, local/remote repair split)

## Priority 1: Robustness
1. Add deterministic simulation seeds to command/session bootstrap.
- Why: reproducible bug reports and test replay.
- Change: support optional `seed` in state init and server startup; emit active seed in STATUS FULL fidelity.

2. Add command idempotency guards for transient network retries.
- Why: duplicate POSTs can issue duplicate commands in high-latency links.
- Change: optional `command_id` in `/command` payload; keep short-lived replay cache in server process.

3. Add repair/task invariant validator in one central function.
- Why: field state, active task, and active repair interactions are now interdependent.
- Change: on each tick/command, assert:
  - at most one active task
  - at most one active repair in Phase A
  - `field_action` reflects task/repair reality
  - command mode implies location `COMMAND`

4. Add save/load schema versioning.
- Why: new fields (`player_mode`, `field_action`, `active_task`) will evolve.
- Change: introduce `snapshot_version`; add migration function from previous snapshots.

5. Strengthen endpoint parity.
- Why: UI server and simulation server diverged historically on `/command` payload shape.
- Change: enforce shared serializer + parser module consumed by both servers.

## Priority 2: Modularity
1. Extract command authority policy into a dedicated module.
- Current risk: command gating logic is split across processor and handlers.
- Change: `terminal/authority.py` with policy table by `player_mode`.

2. Extract presence system into `core/presence.py`.
- Current risk: wait tick helper owns movement progression implicitly.
- Change: expose `tick_presence(state)` and `start_move_task(...)` to remove hidden coupling.

3. Introduce typed task dataclasses.
- Current risk: loose dict tasks are easy to drift.
- Change: `MoveTask`, `RepairTask` dataclasses with explicit fields.

4. Consolidate location normalization and travel graph semantics.
- Current risk: aliases and canonical names can diverge from sector IDs.
- Change: central location registry object that maps id/name/alias/display label.

5. Move terminal message strings into a message catalog.
- Why: easier consistency, easier future localization, easier contract testing.

## Priority 3: Accessibility
1. Add reduced-motion mode for map and terminal effects.
- Change: CSS media query `prefers-reduced-motion`; disable border flashes/flicker.

2. Improve screen reader output for terminal updates.
- Change: add ARIA live region with concise summary line per command while preserving visual feed.

3. Increase contrast variance for warning/assault lines.
- Change: keep palette style but move warning/assault classes to WCAG-friendly contrast thresholds.

4. Add keyboard focus visibility and command history navigation.
- Change: visible input focus ring and `ArrowUp/ArrowDown` history buffer in terminal input.

5. Add explicit offline/network-failed banner state.
- Change: non-modal, high-contrast status strip when `/command` fetch fails repeatedly.

## Priority 4: Engagement
1. Add consequence-rich but non-prescriptive post-action telemetry.
- Change: after WAIT/SCAVENGE/REPAIR, append one factual delta line (damage delta, repaired structures, threat drift bucket).
- Constraint: no strategy hint text.

2. Expand transit identity with localized signal flavor.
- Change: transit nodes report ambient condition tags (`NOISE`, `THERMAL`, `POWER HUM`) tied to COMMS fidelity.

3. Add soft operational milestones.
- Change: non-intrusive milestones such as `FIRST FIELD REPAIR COMPLETE`, `FIRST ASSAULT AWAY FROM COMMAND` in logs.

4. Add persistent operator logbook feed.
- Change: append important events into a compact timeline panel derived from command results and snapshots.

5. Strengthen sector role readability.
- Change: keep map read-only but add subtle static role glyphs (ASCII-safe initials) without interactive hints.

## Testing Expansion Recommendations
1. Add dedicated presence-flow tests:
- deploy while assault active
- move invalid route from transit
- return while action in progress
- local repair only in local sector
- remote repair denied for offline/destroyed

2. Add snapshot contract tests for field mode branches.
- Verify STATUS in field mode never includes global threat/timers.

3. Add browser integration test for snapshot refresh triggers.
- Ensure DEPLOY/MOVE/RETURN/REPAIR/SCAVENGE all refresh right panel and map.

4. Add endpoint contract tests for both servers.
- Enforce `{ok, text, lines}` and support for `command` + `raw` fallback.

5. Add property-based tests for travel graph validity.
- Symmetric edges where expected
- no unreachable canonical nodes
- no invalid alias resolution

## Architecture Drift Risks To Watch
- Dual meaning of `COMMAND` (mode + location string) can cause subtle bugs.
- Mixed sector IDs and sector names across UI/backend can create invalid route checks.
- Future downed-state work will break if `field_action` becomes optional or inconsistent.
- Additional async tasks (future fabrication queues) can conflict with single-task assumptions.

## Suggested Next Refactor Sequence
1. Presence/task extraction (`core/presence.py`) and authority policy extraction.
2. Snapshot/version migration layer.
3. Accessibility pass (reduced motion + ARIA + focus/history).
4. Integration tests across terminal UI refresh behavior.
5. Message catalog and contract locking.



=== REPAIR_MECHANICS.md ===
Right now you have **system damage semantics without a recovery loop**, which breaks three of your own design pillars:

* deterministic simulation
* player agency
* preparation vs reaction tension

So let’s lock **System Repair** properly and minimally, in a way that:

* works with your existing world spine
* aligns with STATUS / WAIT degradation
* does *real* work immediately
* does not pre-empt fabrication, bots, or combat repair

I’ll do this in four sections:

1. Diagnosis: what’s broken right now
2. Design principles for repair (tight, non-negotiable)
3. Canonical repair model (Phase 1.75)
4. Concrete spec you can implement immediately

No questions needed — this is spec work.

---

## 1. Diagnosis: what’s broken right now

### Current situation (as you said it)

* Systems / sectors can be DAMAGED / COMPROMISED
* STATUS reflects that
* WAIT communicates worsening risk
* **REPAIR exists syntactically but does nothing**
* There is no time cost, resource cost, or outcome

That creates a fatal loop:

> Player detects damage → Player issues REPAIR → Nothing changes → Trust collapses

This is worse than not having repair at all.

---

## 2. Repair Design Principles (Locked)

These principles align with everything you’ve already locked.

### Principle 1 — Repair is **slow, costly, and boring**

Repair is not gameplay spectacle.
Repair is **maintenance under pressure**.

If repair feels fun, something went wrong.

---

### Principle 2 — Repair is **local and physical**

At first:

* No remote repair
* No omniscient fixing
* Player must be **present in the affected sector**

This preserves:

* location-based authority
* command vs field distinction
* future value of automation

---

### Principle 3 — Repair restores *capability*, not certainty

Repair:

* improves STATUS
* improves WAIT fidelity
* reduces risk

Repair does **not**:

* guarantee safety
* remove threat
* undo consequences instantly

---

### Principle 4 — Repair operates on **systems, not sectors**

Sectors are views.
Systems are things.

Repair targets:

* COMMS
* POWER
* DEFENSE GRID
* ARCHIVE
  etc.

Sector state is derived.

---

## 3. Canonical Repair Model (Phase 1.75)

This is the **smallest real repair loop** that actually works.

### 3.1 Repair Targets

Each **system sector** has:

* `integrity` (0–100, internal)
* `damage_state` (derived):

  * STABLE
  * ALERT
  * DAMAGED
  * COMPROMISED

You already *conceptually* have this — now it becomes operational.

---

### 3.2 Repair Action (Terminal)

#### Command

```
REPAIR <SYSTEM>
```

Examples:

```
REPAIR COMMS
REPAIR POWER
REPAIR DEFENSE
```

---

### 3.3 Preconditions

REPAIR is allowed only if:

* Player is **physically in the system’s sector**
* System is **not DESTROYED** (future rule)
* System integrity < 100
* No COMMAND breach lockout

If violated:

* Command is denied with an in-world reason
* Time does **not** advance

---

### 3.4 Repair Is a Time-Bound Task

REPAIR does **not** instantly fix anything.

Instead:

* REPAIR starts a **repair task**
* Repair progresses **only during WAIT**
* Repair pauses if:

  * player leaves the sector
  * an assault enters that sector
  * power drops too low (future hook)

---

### 3.5 Repair Progress Model (Minimal, Deterministic)

On each WAIT tick while repairing:

```
integrity += repair_rate
```

Where:

* `repair_rate` is small (e.g. +5 per tick)
* scaled down if:

  * assault is active elsewhere
  * COMMS is degraded
  * POWER is unstable

No randomness. No crits. No fun.

---

### 3.6 Repair Outcomes

When integrity crosses thresholds:

| Integrity | Result          |
| --------- | --------------- |
| ≥ 75      | DAMAGED → ALERT |
| ≥ 90      | ALERT → STABLE  |

STATUS updates immediately.
WAIT messaging reflects *stabilization*, not success.

Example WAIT output (FULL):

```
[EVENT] COMMS MAINTENANCE COMPLETED
[STATUS SHIFT] SIGNAL INTEGRITY STABILIZING
```

At lower fidelity:

```
[EVENT] MAINTENANCE ACTIVITY REGISTERED
```

---

## 4. STATUS Alignment (Repair Effects)

Repair **must** affect STATUS in visible ways or it’s meaningless.

### STATUS rules with repair:

* Repaired systems:

  * move back toward STABLE
* Sector labels improve automatically (derived)
* COMMS repair:

  * improves information fidelity *immediately* once thresholds are crossed

This is critical:

> Repairing COMMS is how the player *earns back truth*.

---

## 5. WAIT Alignment (Repair Messaging)

Repair events are **events**, not status shifts.

* Repair completion → `[EVENT]`
* Repair trend → `[STATUS SHIFT]` (counts as interpretive line)

At low fidelity:

* Repair may be acknowledged without clarity
* Or acknowledged incorrectly (system belief vs reality)

But repair **always actually works internally**.

---

## 6. What this unlocks cleanly (later)

Because this model is tight, it scales naturally into:

* fabrication (reconstruction after DESTROYED)
* repair bots (remote + parallel repair)
* combat repair tools
* prioritization / triage mechanics
* player skill modifiers
* automation failure

Without refactoring.

---

## Final Lock (Important)

> **Damage without repair is narrative.
> Damage with repair is gameplay.**

You are correct to stop and fix this *now*.

---

### Next move (strong recommendation)

Next, we should:

* wire **repair progress into `step_world`**
* update STATUS + WAIT outputs to acknowledge repair
* add a single test:

  > DAMAGED → REPAIR → WAIT xN → STATUS improves

If you want, I’ll write the **exact code diff** next, aligned to your repo.

This diff will:

* Add per-sector integrity tracking (without breaking current STATUS contract)
* Implement active repair tasks
* Progress repair only via `step_world`
* Block repair unless player is physically in sector
* Surface repair effects through STATUS + WAIT
* Add one deterministic test

All world mutation will remain inside `step_world` to respect your roadmap invariant.

---

# ✅ DIFF 1 — Extend `SectorState` with integrity

File:
`game/simulations/world_state/core/state.py`

---

### 🔹 Add integrity + repair tracking

```diff
@@
 @dataclass
 class SectorState:
     name: str
     damage: float = 0.0
     alertness: float = 0.0
     power: float = 1.0
     occupied: bool = False
     effects: list[str] = field(default_factory=list)
+    integrity: int = 100  # 0–100
```

---

### 🔹 Derive damage bucket from integrity (no behavior change yet)

Find existing damage bucket logic (likely inside `status_label()`).

Replace or augment it:

```diff
@@
     def status_label(self) -> str:
-        if self.damage > 0.7:
-            return "COMPROMISED"
-        if self.damage > 0.4:
-            return "DAMAGED"
-        if self.alertness > 0.5:
-            return "ALERT"
-        return "STABLE"
+        if self.integrity <= 25:
+            return "COMPROMISED"
+        if self.integrity <= 60:
+            return "DAMAGED"
+        if self.integrity <= 85:
+            return "ALERT"
+        return "STABLE"
```

Damage float can remain for assault math; integrity now drives STATUS.

---

# ✅ DIFF 2 — Add repair task tracking to GameState

Same file: `state.py`

---

### 🔹 Add repair fields

Inside `GameState.__init__`:

```diff
@@
     def __init__(self):
         ...
         self.sectors: dict[str, SectorState] = {}
+        self.active_repair: str | None = None
+        self.repair_rate: int = 5  # integrity per tick
```

Only one repair at a time (Phase 1.75 — simple and clean).

---

# ✅ DIFF 3 — Repair mutation inside `step_world`

File:
`game/simulations/world_state/core/simulation.py`

Find `step_world(state)`.

Add repair progression at end of tick loop.

```diff
@@
 def step_world(state: GameState):
     ...
 
+    # --- REPAIR PROGRESSION ---
+    if state.active_repair:
+        sector = state.sectors.get(state.active_repair)
+        if sector:
+            sector.integrity = min(100, sector.integrity + state.repair_rate)
+
+            # Stop repair automatically if fully restored
+            if sector.integrity >= 100:
+                state.active_repair = None
```

Repair progresses **only** via `step_world`, which WAIT calls.
Invariant preserved.

---

# ✅ DIFF 4 — REPAIR Command

File:
`game/simulations/world_state/terminal/commands/repair.py`
(Create if missing)

```python
from game.simulations.world_state.core.state import GameState


def cmd_repair(state: GameState, sector_id: str):
    sector_id = sector_id.upper()

    if sector_id not in state.sectors:
        return ["UNKNOWN SECTOR."]

    if state.player_location != sector_id:
        return ["REPAIR REQUIRES PHYSICAL PRESENCE."]

    sector = state.sectors[sector_id]

    if sector.integrity >= 100:
        return ["SYSTEM DOES NOT REQUIRE REPAIR."]

    state.active_repair = sector_id
    return [f"[MAINTENANCE INITIATED] {sector_id}"]
```

---

### 🔹 Wire into processor

File:
`game/simulations/world_state/terminal/processor.py`

Add import:

```diff
+from game.simulations.world_state.terminal.commands.repair import cmd_repair
```

Add to handler map:

```diff
     "HELP": cmd_help,
+    "REPAIR": cmd_repair,
```

Ensure REPAIR is classified as a write command if authority gating applies.

---

# ✅ DIFF 5 — WAIT Feedback for Repair Completion

File:
`game/simulations/world_state/core/simulation.py`

We need repair completion to emit an event.

Modify repair block:

```diff
@@
     if state.active_repair:
         sector = state.sectors.get(state.active_repair)
         if sector:
-            sector.integrity = min(100, sector.integrity + state.repair_rate)
-
-            if sector.integrity >= 100:
-                state.active_repair = None
+            before = sector.integrity
+            sector.integrity = min(100, sector.integrity + state.repair_rate)
+
+            if before < 100 and sector.integrity >= 100:
+                state.active_repair = None
+                state.last_tick_events.append(
+                    f"[EVENT] {sector.name} MAINTENANCE COMPLETED"
+                )
```

(Use whatever event collection structure your WAIT already uses — if it’s `events_this_tick`, adapt accordingly.)

---

# ✅ DIFF 6 — STATUS Reflects Repair Automatically

No change required if STATUS already calls `status_label()` per sector.

Integrity now drives that.

Repairing:

* moves sector from DAMAGED → ALERT → STABLE
* STATUS updates instantly

---

# ✅ DIFF 7 — Deterministic Test

File:
`tests/test_repair_flow.py` (new)

```python
def test_repair_progression(step_world, game_state):
    sector = game_state.sectors["POWER"]
    sector.integrity = 50  # DAMAGED

    game_state.player_location = "POWER"

    from game.simulations.world_state.terminal.commands.repair import cmd_repair

    cmd_repair(game_state, "POWER")

    # 10 ticks @ rate 5 = +50 integrity
    for _ in range(10):
        step_world(game_state)

    assert sector.integrity == 100
    assert game_state.active_repair is None
    assert sector.status_label() == "STABLE"
```

---

# 🔒 Resulting Behavior

Now the loop is real:

1. Assault damages POWER → integrity drops
2. STATUS shows DAMAGED
3. Player moves to POWER
4. `REPAIR POWER`
5. `WAIT` xN
6. STATUS improves
7. WAIT may emit completion event

This:

* preserves deterministic spine
* respects location authority
* makes COMMS repair meaningful
* enables future fabrication easily

---

# 🚨 Important Design Note

We intentionally:

* did not add resource cost yet
* did not allow parallel repairs
* did not allow remote repair
* did not auto-repair anything
* did not add combat repair

Because you asked for **minimal real functionality first**.

---

If you want, next we can:

* Tie repair effectiveness to POWER stability
* Make COMMS repair instantly raise information fidelity
* Add repair interruption during assault in that sector
* Add resource cost hook (without full economy yet)

You’re now officially past “damage is cosmetic.”



=== UI_RECOMMENDS_INSTRUCT.md ===
# STATUS UX REWORK — CODEX IMPLEMENTATION INSTRUCTIONS

This instruction set modifies the existing CUSTODIAN codebase to:

1. Add Situation Header
2. Add Priority-Sorted Sector Display
3. Add Delta Markers
4. Compress Header Block
5. Add ASCII Status Markers
6. Add Compact Map Mode (Field Mode – Top Priority)
7. Add Pulse Highlight (UI minimal)
8. Add Heat-Band Grouping (UI minimal)

---

# 🔴 PART 1 — STATUS CORE REWORK

File:
`game/simulations/world_state/terminal/commands/status.py`

---

## 1️⃣ Add Situation Header

Add function at top of file:

```python
def _compute_situation_header(state):
    degraded = []
    for sector in state.sectors.values():
        label = sector.status_label()
        if label in ("DAMAGED", "COMPROMISED"):
            degraded.append(sector.name)

    if degraded:
        count = len(degraded)
        return f"SITUATION: {count} SYSTEM{'S' if count > 1 else ''} DEGRADED"

    if state.fidelity != "FULL":
        return "SITUATION: INFORMATION UNSTABLE"

    return "SITUATION: STABLE"
```

Insert into STATUS output immediately after header line block.

---

## 2️⃣ Compress Header Block

Replace:

```
TIME: 18
THREAT: HIGH
ASSAULT: PENDING
```

With single line:

```python
lines.append(
    f"TIME: {snapshot['time']} | THREAT: {snapshot['threat']} | ASSAULT: {snapshot['assault']}"
)
```

Replace posture/archive lines with:

```python
lines.append(
    f"POSTURE: {snapshot.get('posture','-')} | ARCHIVE: {snapshot.get('archive','-')}"
)
```

Do not display posture target at degraded fidelity.

---

## 3️⃣ Priority Sort Sectors

Replace existing sector iteration.

Add:

```python
def _sector_priority(sector):
    label = sector.status_label()
    order = {
        "COMPROMISED": 0,
        "DAMAGED": 1,
        "ALERT": 2,
        "ACTIVITY DETECTED": 3,
        "STABLE": 4,
    }
    return order.get(label, 5)
```

Sort:

```python
sorted_sectors = sorted(
    state.sectors.values(),
    key=_sector_priority
)
```

---

## 4️⃣ ASCII Status Markers

Add mapping:

```python
MARKERS = {
    "COMPROMISED": "X",
    "DAMAGED": "!",
    "ALERT": "~",
    "ACTIVITY DETECTED": "?",
    "STABLE": ".",
}
```

Render sectors as:

```python
for sector in sorted_sectors:
    label = sector.status_label()
    marker = MARKERS.get(label, ".")
    lines.append(f"{sector.name:<12} {marker}")
```

Remove verbose `: DAMAGED` style rendering.

---

## 5️⃣ Add Delta Markers

Store previous snapshot hash.

In `GameState` add:

```python
self._last_sector_status = {}
```

Before rendering sectors:

```python
delta = ""
prev = state._last_sector_status.get(sector.name)
current = sector.status_label()

if prev:
    if current != prev:
        if _sector_priority(sector) < _sector_priority_by_label(prev):
            delta = " (+)"
        else:
            delta = " (-)"
```

Append delta to render line:

```python
lines.append(f"{sector.name:<12} {marker}{delta}")
```

After rendering, update:

```python
state._last_sector_status[sector.name] = current
```

---

# 🔵 PART 2 — COMPACT MAP MODE (TOP PRIORITY)

Condition:

```python
if state.player_mode == "FIELD":
```

When FIELD mode:

* Do not render full STATUS.
* Render compact tactical map view.

---

## Add Compact Renderer

Add function in `status.py`:

```python
def _render_compact_field_view(state):
    lines = []

    lines.append(f"LOCATION: {state.player_location}")
    lines.append(f"FIDELITY: {state.fidelity}")

    sorted_sectors = sorted(
        state.sectors.values(),
        key=_sector_priority
    )

    for sector in sorted_sectors:
        marker = MARKERS.get(sector.status_label(), ".")
        prefix = ">" if sector.name == state.player_location else " "
        lines.append(f"{prefix} {sector.name:<10} {marker}")

    return lines
```

At start of STATUS:

```python
if state.player_mode == "FIELD":
    return _render_compact_field_view(state)
```

Do not include:

* Threat
* Assault timers
* Archive losses
* Global posture

FIELD mode hides global data.

---

# 🟡 PART 3 — UI PULSE HIGHLIGHT (MINIMAL)

File:
`frontend/src/components/TerminalOutput.jsx`

When rendering lines:

If line contains `(+)` or `(-)`:

Add class:

```jsx
<span className="delta">{line}</span>
```

---

## CSS

Add:

```css
.delta {
  animation: pulse 1.2s ease-out 1;
}

@keyframes pulse {
  0% { background-color: rgba(255,255,255,0.2); }
  100% { background-color: transparent; }
}
```

Respect reduced motion:

```css
@media (prefers-reduced-motion: reduce) {
  .delta {
    animation: none;
  }
}
```

---

# 🟠 PART 4 — HEAT BAND GROUPING (MINIMAL)

Modify sector render loop:

Before stable sectors, insert divider:

```python
if marker == "." and not stable_header_added:
    lines.append("---")
    stable_header_added = True
```

Add CSS class per marker type in frontend:

```jsx
const heatClass = {
  "X": "heat-critical",
  "!": "heat-damaged",
  "~": "heat-alert",
  "?": "heat-unknown",
  ".": "heat-stable",
}[marker]
```

CSS:

```css
.heat-critical { color: #ff3b3b; }
.heat-damaged { color: #ff8844; }
.heat-alert { color: #ffd24d; }
.heat-unknown { color: #aaa; }
.heat-stable { color: #66cc88; }
```

Ensure WCAG AA contrast.

---

# 🟢 FIELD MODE RULES (IMPORTANT)

FIELD mode must:

* Never show global threat value
* Never show assault timer
* Never show archive counts
* Only show:

  * location
  * fidelity
  * compact sector list
  * local marker emphasis

---

# 🔒 DO NOT CHANGE

* Fidelity computation
* Assault logic
* Snapshot versioning
* Message catalog
* Repair flow

Only modify STATUS presentation layer.

---

# RESULT

COMMAND mode:

* Compact header
* Situation header
* Priority sorted sectors
* Delta markers
* Heat bands

FIELD mode:

* Minimal tactical console
* Location-centric
* No global state
* Immediate readability

---

# IMPLEMENT ORDER

1. STATUS core refactor
2. FIELD compact mode
3. Delta tracking state addition
4. UI pulse highlight
5. Heat-band CSS

Do not combine into one commit.
Max one feature per commit.




