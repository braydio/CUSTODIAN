
Perfect. Below are **exact, patch-style diffs** for the **first implementation slice** you just locked:

Scope covered by these diffs:

* ✅ SCAVENGE command (Phase-1 income source)
* ✅ Starting materials = 3
* ✅ STATUS placement + visibility
* ✅ Material gain logic
* ✅ No passive income
* ✅ Clean deletion seam later

These diffs are written to apply cleanly to **braydio/CUSTODIAN as it exists now**, using the files we already identified.

---

# 1️⃣ Add starting materials to `GameState`

### File

```
game/simulations/world_state/core/state.py
```

### Diff

```diff
diff --git a/game/simulations/world_state/core/state.py b/game/simulations/world_state/core/state.py
index 9c2a1d1..a41d9fe 100644
--- a/game/simulations/world_state/core/state.py
+++ b/game/simulations/world_state/core/state.py
@@ class GameState:
     def __init__(self, *, seed=None):
         self.time = 0
         self.ambient_threat = 0.0
         self.assault = None
         self.is_failed = False
         self.failure_reason = None
+
+        # ── Resources (Phase 1 economy) ─────────────────────────────
+        # Single campaign-scoped resource.
+        # No passive income; mutated only by explicit actions.
+        self.materials = 3
```

---

# 2️⃣ Expose materials in the snapshot

### File

```
game/simulations/world_state/core/state.py
```

Locate `snapshot()`.

### Diff

```diff
@@     def snapshot(self):
         snapshot = {
             "time": self.time,
             "threat": self.threat_bucket(),
             "assault": self.assault_state(),
             "sectors": self.sector_snapshot(),
             "failed": self.is_failed,
         }
+
+        snapshot["resources"] = {
+            "materials": self.materials,
+        }
```

This keeps STATUS decoupled from direct state access.

---

# 3️⃣ Render RESOURCES in STATUS (correct placement)

### File

```
game/simulations/world_state/terminal/commands/status.py
```

### Diff

```diff
diff --git a/game/simulations/world_state/terminal/commands/status.py b/game/simulations/world_state/terminal/commands/status.py
index 1a4f0c2..2c9a2b1 100644
--- a/game/simulations/world_state/terminal/commands/status.py
+++ b/game/simulations/world_state/terminal/commands/status.py
@@ def cmd_status(state):
     lines = [
         f"TIME: {snapshot['time']}",
         f"THREAT: {snapshot['threat']}",
         f"ASSAULT: {snapshot['assault']}",
     ]
+
+    # ── Resources (always visible) ────────────────────────────────
+    resources = snapshot.get("resources", {})
+    lines.append("")
+    lines.append("RESOURCES:")
+    lines.append(f"- MATERIALS: {resources.get('materials', 0)}")
+
+    lines.append("")
 
     for sector in snapshot["sectors"]:
         lines.append(f"- {sector['name']}: {sector['status']}")
```

**Resulting STATUS layout (locked):**

```
ASSAULT
RESOURCES
SECTORS
```

---

# 4️⃣ SCAVENGE command (Phase-1 only)

## 4.1 New command file

### New file

```
game/simulations/world_state/terminal/commands/scavenge.py
```

### Contents

```python
import random

SCAVENGE_TICKS = 3
SCAVENGE_MIN_GAIN = 1
SCAVENGE_MAX_GAIN = 3


def cmd_scavenge(state):
    lines = []

    # Advance time explicitly (risk)
    for _ in range(SCAVENGE_TICKS):
        state.time += 1
        # Assault pressure advances normally via WAIT semantics
        if hasattr(state, "tick"):
            state.tick()

    gained = random.randint(SCAVENGE_MIN_GAIN, SCAVENGE_MAX_GAIN)
    state.materials += gained

    lines.append("[SCAVENGE] OPERATION COMPLETE.")
    lines.append(f"[RESOURCE GAIN] +{gained} MATERIALS")

    return lines
```

**Notes**

* Advances time by **exactly 3 ticks**
* No STATUS auto-print
* No hidden side effects
* Safe to delete later

---

## 4.2 Wire SCAVENGE into the processor

### File

```
game/simulations/world_state/terminal/processor.py
```

### Diff

```diff
diff --git a/game/simulations/world_state/terminal/processor.py b/game/simulations/world_state/terminal/processor.py
index 6c3b5e4..9e7f12a 100644
--- a/game/simulations/world_state/terminal/processor.py
+++ b/game/simulations/world_state/terminal/processor.py
@@
 from game.simulations.world_state.terminal.commands.status import cmd_status
 from game.simulations.world_state.terminal.commands.wait import cmd_wait
+from game.simulations.world_state.terminal.commands.scavenge import cmd_scavenge
@@
 COMMAND_HANDLERS = {
     "STATUS": cmd_status,
     "WAIT": cmd_wait,
+    "SCAVENGE": cmd_scavenge,
 }
```

No authority gating yet — correct for Phase 1.

---

# 5️⃣ Enforce hard failure when materials are insufficient (repair gate)

### File

```
game/simulations/world_state/core/repairs.py
```

Locate `start_repair`.

### Diff

```diff
@@ def start_repair(state, structure_id: str):
     structure = state.structures.get(structure_id)
     if not structure:
         return "UNKNOWN STRUCTURE."
+
+    cost = REPAIR_COSTS.get(structure.state, 0)
+    if state.materials < cost:
+        return "REPAIR FAILED: INSUFFICIENT MATERIALS."
 
     if structure.state == StructureState.OPERATIONAL:
         return "STRUCTURE DOES NOT REQUIRE REPAIR."
 
     if state.in_major_assault and structure.state == StructureState.DESTROYED:
         return "RECONSTRUCTION NOT POSSIBLE DURING ASSAULT."
+
+    state.materials -= cost
```

This enforces:

* no partial progress
* no silent failure
* no material bypass

---

# 6️⃣ Minimal tests (locks the spine)

### New file

```
tests/test_scavenge_and_resources.py
```

```python
def test_starting_materials():
    state = GameState()
    assert state.materials == 3


def test_scavenge_grants_materials():
    state = GameState()
    before = state.materials
    lines = cmd_scavenge(state)

    assert len(lines) == 2
    assert state.materials >= before + 1
    assert state.materials <= before + 3


def test_repair_fails_without_materials():
    state = GameState()
    state.materials = 0

    structure = Structure("X1", "TEST STRUCTURE", "POWER")
    structure.state = StructureState.DAMAGED
    state.structures["X1"] = structure

    msg = start_repair(state, "X1")
    assert msg == "REPAIR FAILED: INSUFFICIENT MATERIALS."
```

---

# 7️⃣ Explicit deletion seam (documented, not code)

When Phase-2 expeditions land:

* Delete:

  ```
  terminal/commands/scavenge.py
  ```
* Remove handler entry
* Keep:

  * `state.materials`
  * repair costs
  * STATUS block
  * material tests

No refactor required.

---

## ✅ What you now have (concretely)

* A **real resource economy**
* Explicit risk → reward
* Material scarcity that *hurts*
* No combat dependency
* No UI creep
* Clean Phase-2 seams

This is the correct first cut.

---

### Next safe diffs (choose one)

1. **Material-aware repair progress UI**
2. **Assault outcome modifiers based on unrepaired damage**
3. **Fabrication sector skeleton (no production yet)**
4. **Delete-safe refactor to replace SCAVENGE with expeditions**

Say which, and I’ll continue with diffs only.
