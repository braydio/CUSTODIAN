
# 1️⃣ Structure-level damage model (new, minimal, non-breaking)

### ✅ New file: `game/simulations/world_state/core/structures.py`

```diff
+ from enum import Enum
+
+
+ class StructureState(Enum):
+     OPERATIONAL = "OPERATIONAL"
+     DAMAGED = "DAMAGED"
+     OFFLINE = "OFFLINE"
+     DESTROYED = "DESTROYED"
+
+
+ class Structure:
+     def __init__(self, id: str, name: str, sector: str):
+         self.id = id
+         self.name = name
+         self.sector = sector
+         self.state = StructureState.OPERATIONAL
+
+     def degrade(self):
+         if self.state == StructureState.OPERATIONAL:
+             self.state = StructureState.DAMAGED
+         elif self.state == StructureState.DAMAGED:
+             self.state = StructureState.OFFLINE
+         elif self.state == StructureState.OFFLINE:
+             self.state = StructureState.DESTROYED
+
+     def can_autorepair(self) -> bool:
+         return self.state in {
+             StructureState.OPERATIONAL,
+             StructureState.DAMAGED,
+         }
```

This introduces **no coupling yet**. It’s inert until wired.

---

# 2️⃣ Extend `GameState` to own structures

### `game/simulations/world_state/core/state.py`

```diff
@@
 from dataclasses import dataclass, field
 from typing import Dict, Optional
+
+ from .structures import Structure, StructureState
```

```diff
 class GameState:
     def __init__(self):
         ...
         self.sectors: dict[str, SectorState] = {}
+
+        # Structure-level damage model
+        self.structures: dict[str, Structure] = {}
+        self.active_repairs: dict[str, int] = {}  # structure_id -> ticks remaining
```

```diff
     def snapshot(self):
         ...
-        sectors_snapshot = [
-            {
-                "name": sector.name,
-                "status": sector.status_label(),
-            }
-            for sector in self.sectors.values()
-        ]
+        sectors_snapshot = []
+        for sector in self.sectors.values():
+            sector_structures = [
+                s for s in self.structures.values()
+                if s.sector == sector.name
+            ]
+            damaged = any(s.state != StructureState.OPERATIONAL for s in sector_structures)
+
+            sectors_snapshot.append({
+                "name": sector.name,
+                "status": sector.status_label() if not damaged else "DAMAGED",
+            })
```

This preserves the old sector system while **deriving sector health from structures** (your requirement).

---

# 3️⃣ Assaults now damage structures, not raw sectors

### `game/simulations/world_state/core/assaults.py`

Inside `_apply_assault_outcome`:

```diff
@@ def _apply_assault_outcome(state, assault, outcome, assault_damage, target_names):
-    if outcome.penetration == "none" and assault_damage < 0.5:
+    if outcome.penetration == "none" and assault_damage < 0.5:
         state.ambient_threat += 0.2
         for sector in assault.target_sectors:
             sector.alertness *= 0.85
         return "[ASSAULT] DEFENSES HELD. ENEMY WITHDREW."
```

⬇️ Replace **damage mutation** blocks:

```diff
-    for sector in assault.target_sectors:
-        sector.damage += 0.6
-        sector.alertness += 0.4
+    for structure in state.structures.values():
+        if structure.sector in target_names:
+            structure.degrade()
```

Now:

* Enemies worsen damage
* Time does not
* Clean wins cause no damage

✔ Matches your answer exactly.

---

# 4️⃣ Time-based repair tasks (single-action, consumes time/resources)

### New file: `game/simulations/world_state/core/repairs.py`

```diff
+ from .structures import StructureState
+
+
+ REPAIR_TICKS = {
+     StructureState.DAMAGED: 2,
+     StructureState.OFFLINE: 4,
+     StructureState.DESTROYED: 6,
+ }
+
+
+ def start_repair(state, structure_id: str) -> str:
+     structure = state.structures.get(structure_id)
+     if not structure:
+         return "UNKNOWN STRUCTURE."
+
+     if structure.state == StructureState.OPERATIONAL:
+         return "STRUCTURE DOES NOT REQUIRE REPAIR."
+
+     if state.in_major_assault and structure.state == StructureState.DESTROYED:
+         return "RECONSTRUCTION NOT POSSIBLE DURING ASSAULT."
+
+     state.active_repairs[structure_id] = REPAIR_TICKS[structure.state]
+     return f"REPAIR STARTED: {structure.name}"
+
+
+ def tick_repairs(state):
+     completed = []
+     for sid, ticks in state.active_repairs.items():
+         state.active_repairs[sid] -= 1
+         if state.active_repairs[sid] <= 0:
+             completed.append(sid)
+
+     for sid in completed:
+         structure = state.structures[sid]
+         if structure.state == StructureState.DESTROYED:
+             structure.state = StructureState.OFFLINE
+         elif structure.state == StructureState.OFFLINE:
+             structure.state = StructureState.DAMAGED
+         elif structure.state == StructureState.DAMAGED:
+             structure.state = StructureState.OPERATIONAL
+         del state.active_repairs[sid]
```

---

# 5️⃣ Advance repairs with time (WAIT ticks)

### `game/simulations/world_state/terminal/commands/wait.py`

(or wherever `WAIT` advances time)

```diff
@@
 from game.simulations.world_state.core.assaults import tick_assault_timer
+from game.simulations.world_state.core.repairs import tick_repairs
```

```diff
     for _ in range(ticks):
         state.time += 1
         tick_assault_timer(state)
+        tick_repairs(state)
```

Repairs now:

* consume time
* pause if you don’t WAIT
* feel like progress bars

---

# 6️⃣ REPAIR command (terminal-facing)

### New file: `game/simulations/world_state/terminal/commands/repair.py`

```diff
+ from game.simulations.world_state.core.repairs import start_repair
+
+
+ def cmd_repair(state, structure_id: str):
+     result = start_repair(state, structure_id)
+     return [result]
```

### Wire it into processor

`game/simulations/world_state/terminal/processor.py`

```diff
 from game.simulations.world_state.terminal.commands import (
     cmd_focus,
     cmd_harden,
     cmd_help,
     cmd_reset,
     cmd_status,
     cmd_wait,
     cmd_wait_ticks,
+    cmd_repair,
 )
```

```diff
 COMMAND_HANDLERS = {
     "STATUS": cmd_status,
     "WAIT": cmd_wait,
     "HELP": lambda _state: cmd_help(),
+    "REPAIR": lambda state, sid=None: cmd_repair(state, sid),
 }
```

(We’ll tighten argument parsing later — this matches current style.)

---

# 7️⃣ STATUS now exposes structure damage (COMMS-aware hook)

### `game/simulations/world_state/terminal/commands/status.py`

```diff
@@
     for sector in snapshot["sectors"]:
         lines.append(f"- {sector['name']}: {sector['status']}")
+
+        if sector["status"] == "DAMAGED":
+            damaged_structures = [
+                s for s in state.structures.values()
+                if s.sector == sector["name"] and s.state != StructureState.OPERATIONAL
+            ]
+            for s in damaged_structures:
+                lines.append(f"    * {s.name}: {s.state.value}")
```

Later:

* COMMS degradation can hide this block
* Upgrades can reveal exact states

---

# 8️⃣ Tests (example, minimal)

### `tests/test_repairs.py` (new)

```diff
+ def test_structure_repair_progression(game_state):
+     s = Structure("T1", "Test Turret", "DEFENSE GRID")
+     s.state = StructureState.DAMAGED
+     game_state.structures["T1"] = s
+
+     start_repair(game_state, "T1")
+     tick_repairs(game_state)
+     tick_repairs(game_state)
+
+     assert s.state == StructureState.OPERATIONAL
```

---

## ✅ What this gives you **right now**

* Structure-level damage ✔
* Sector abstraction ✔
* Assault-driven degradation ✔
* No time-based worsening ✔
* Time + resource repair loop ✔ (resources stubbed, intentional)
* Repairs during assault ✔ (with reconstruction blocked)
* STATUS visibility ✔
* Fabrication-compatible foundation ✔

---

## ⚠️ Things I intentionally did NOT add yet

Because you explicitly said *later*:

* fabrication sector
* resource economy
* repair bots
* command-terminal remote repairs
* autorepair effectiveness > 0

The scaffolding **already supports all of them**.

---

## Next (tell me what you want)

I can now:

1. Add **fabrication & reconstruction costs**
2. Add **player multitool repair during combat**
3. Add **COMMS-based information hiding**
4. Add **autorepair unlock progression**
5. Clean up argument parsing + UX

Say the next slice and I’ll continue with diffs only.
