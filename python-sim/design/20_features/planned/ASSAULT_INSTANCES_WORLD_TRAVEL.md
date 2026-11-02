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
