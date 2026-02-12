
Below are **exact, patch-style diffs** for **both steps**, done **incrementally and safely**:

1. **Material-aware Repair UI** (visibility + progress + cost clarity)
2. **Fabrication Sector Skeleton** (non-functional, economy-aware, future-proof)

No combat assumptions. No fabrication yet. No balance creep.

---

# PART 1 — MATERIAL-AWARE REPAIR UI

### Goals (locked)

* Player can see:

  * repair **cost**
  * **materials remaining**
  * **progress**
* No hidden queues
* No auto-repairs
* No partial progress without materials

---

## 1️⃣ Track repair progress in state (already mostly present)

We extend what you already added (`active_repairs`) to expose **progress**, not just completion.

### File

```
game/simulations/world_state/core/repairs.py
```

### Diff

```diff
@@
 REPAIR_TICKS = {
     StructureState.DAMAGED: 2,
     StructureState.OFFLINE: 4,
     StructureState.DESTROYED: 6,
 }
+
+REPAIR_COSTS = {
+    StructureState.DAMAGED: 1,
+    StructureState.OFFLINE: 2,
+    StructureState.DESTROYED: 4,
+}
```

```diff
 def start_repair(state, structure_id: str) -> str:
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
 
-    state.active_repairs[structure_id] = REPAIR_TICKS[structure.state]
+    state.materials -= cost
+    state.active_repairs[structure_id] = {
+        "remaining": REPAIR_TICKS[structure.state],
+        "total": REPAIR_TICKS[structure.state],
+        "cost": cost,
+    }
 
-    return f"REPAIR STARTED: {structure.name}"
+    return f"REPAIR STARTED: {structure.name} (COST: {cost} MATERIALS)"
```

---

## 2️⃣ Tick repairs with progress preserved

```diff
 def tick_repairs(state):
     completed = []
-    for sid, ticks in state.active_repairs.items():
-        state.active_repairs[sid] -= 1
-        if state.active_repairs[sid] <= 0:
-            completed.append(sid)
+    for sid, job in state.active_repairs.items():
+        job["remaining"] -= 1
+        if job["remaining"] <= 0:
+            completed.append(sid)
 
     for sid in completed:
         structure = state.structures[sid]
```

(no semantic change beyond structure)

---

## 3️⃣ Surface repair progress in STATUS

### File

```
game/simulations/world_state/terminal/commands/status.py
```

### Diff

```diff
@@
     for sector in snapshot["sectors"]:
         lines.append(f"- {sector['name']}: {sector['status']}")
+
+        # Show active repairs in this sector
+        for sid, job in state.active_repairs.items():
+            structure = state.structures.get(sid)
+            if structure and structure.sector == sector["name"]:
+                done = job["total"] - job["remaining"]
+                lines.append(
+                    f"    * REPAIRING {structure.name}: "
+                    f"{done}/{job['total']} TICKS"
+                )
```

### Resulting STATUS example

```
RESOURCES:
- MATERIALS: 1

SECTORS:
- POWER: DAMAGED
    * REPAIRING MAIN RELAY: 1/4 TICKS
```

This gives:

* progress
* location
* urgency
* zero UI creep

---

## 4️⃣ (Optional but recommended) Repair command echo

### File

```
game/simulations/world_state/terminal/commands/repair.py
```

Already returns the cost line. No further changes needed.

---

# PART 2 — FABRICATION SECTOR SKELETON (NO PRODUCTION)

This is **pure structure**, not gameplay.

### Goals

* Sector exists
* Appears in STATUS
* Can be damaged / repaired
* Consumes **nothing yet**
* Does **nothing yet**

---

## 1️⃣ Define FABRICATION sector

### File

```
game/simulations/world_state/core/config.py
```

### Diff

```diff
 CRITICAL_SECTORS = {
     "COMMAND",
     "ARCHIVE",
 }
+
+OPTIONAL_SECTORS = {
+    "FABRICATION",
+}
```

(If you don’t have `OPTIONAL_SECTORS`, add it — this is intentional separation.)

---

## 2️⃣ Register FABRICATION in GameState init

### File

```
game/simulations/world_state/core/state.py
```

Locate sector initialization.

### Diff

```diff
+from .sector import SectorState
```

```diff
+        if "FABRICATION" not in self.sectors:
+            self.sectors["FABRICATION"] = SectorState(
+                name="FABRICATION",
+                damage=0.0,
+                alertness=0.0,
+                power=1.0,
+            )
```

This makes FABRICATION:

* damageable
* assault-targetable later
* repairable now

---

## 3️⃣ Add placeholder structures for FABRICATION

### File

```
game/simulations/world_state/core/structures.py
```

### Diff

```diff
+def create_fabrication_structures():
+    return [
+        Structure(
+            id="FAB_CORE",
+            name="FABRICATION CORE",
+            sector="FABRICATION",
+        ),
+        Structure(
+            id="FAB_TOOLS",
+            name="ASSEMBLY TOOLS",
+            sector="FABRICATION",
+        ),
+    ]
```

### Wire into GameState init

```
game/simulations/world_state/core/state.py
```

```diff
+from .structures import create_fabrication_structures
```

```diff
+        for s in create_fabrication_structures():
+            self.structures[s.id] = s
```

Now FABRICATION:

* has real structures
* participates in damage / repair loop
* costs materials to recover
* produces nothing (yet)

---

## 4️⃣ Explicitly block fabrication commands (future-proof)

### File

```
game/simulations/world_state/terminal/processor.py
```

Optional but clean:

```diff
+    "FABRICATE": lambda *_: [
+        "FABRICATION SYSTEM NOT OPERATIONAL.",
+        "CAPABILITY NOT YET UNLOCKED.",
+    ],
```

This prevents:

* confusion
* silent no-ops
* later API breaks

---

# ✅ What you have now

After these diffs, the game supports:

* visible material scarcity
* visible repair costs
* visible repair progress
* FABRICATION as a real, damageable system
* zero fabrication logic
* zero combat dependency

This is **exactly the right scaffolding**.

---

## Next safe extensions

1. **Fabrication recipes (materials → defenses)**
2. **Fabrication repair efficiency bonuses**
3. **Assault targeting bias for FABRICATION**
4. **Multitool repair seam (non-combat stub)**

This is written so an automated or human implementer can proceed **confidently, without guesswork**, and without breaking architectural contracts.

I will do **four things**, in order:

1. **Confirm the decisions you just locked**
2. **Enumerate the exact files involved (authoritative list)**
3. **Describe the required changes to each file, precisely**
4. **State the invariants Codex must not violate**

No diffs yet. This is the *“do it right” brief*.

---

# 0. Locked Decisions (Authoritative)

These are **final** and should be treated as constraints, not suggestions:

1. **FABRICATION is the 9th canonical sector**

   * Visible
   * Damageable
   * Repairable
   * Does nothing yet

2. **`active_repairs` schema is migrated**

   * From: `dict[structure_id → remaining_ticks:int]`
   * To:

     ```python
     dict[structure_id → {
         "remaining": int,
         "total": int,
         "cost": int,
     }]
     ```

3. **Repair UI rules**

   * Cost is **always shown**
   * Progress ticks are:

     * shown exactly in FULL fidelity
     * estimated in degraded modes
     * never completely hidden unless COMMS is nearly dead

These decisions resolve all prior ambiguity.

---

# 1. Exact Files Involved (From Real Repo)

This is the **complete and minimal set** of files that must be touched.

---

## 1.1 World-State Core (Authoritative Logic)

### 🔹 `game/simulations/world_state/core/state.py`

**Role:**
Canonical world state container and snapshot producer.

**Why touched:**

* Stores `materials`
* Stores `active_repairs`
* Initializes sectors (now 9 instead of 8)
* Exposes data to STATUS via `snapshot()`

---

### 🔹 `game/simulations/world_state/core/repairs.py`

**Role:**
Owns repair lifecycle and ticking.

**Why touched:**

* Migrate `active_repairs` schema
* Deduct materials on repair start
* Track progress and cost
* Complete repairs correctly

This is the **most sensitive file** in this change set.

---

### 🔹 `game/simulations/world_state/core/config.py`

**Role:**
Defines canonical sectors and invariants.

**Why touched:**

* Add `FABRICATION` as a 9th sector
* Update any sector lists/constants that assume 8 sectors

---

### 🔹 `game/simulations/world_state/core/structures.py`

**Role:**
Defines structure templates.

**Why touched:**

* Add placeholder FABRICATION structures
* Ensure they bind to the FABRICATION sector

---

## 1.2 Terminal / UI Projection Layer

### 🔹 `game/simulations/world_state/terminal/commands/status.py`

**Role:**
Human-readable projection of snapshot state.

**Why touched:**

* Show repair cost always
* Show progress exactly or approximately depending on fidelity
* Include FABRICATION in sector listing
* Maintain correct ordering:

  ```
  TIME
  THREAT
  ASSAULT
  RESOURCES
  SECTORS (now 9)
  ```

---

### 🔹 `game/simulations/world_state/terminal/commands/repair.py`

**Role:**
Repair command interface.

**Why touched:**

* Echo repair cost clearly
* Fail hard if insufficient materials
* No logic duplication (delegate to `repairs.py`)

---

## 1.3 Frontend / Visualization

### 🔹 `custodian-terminal/sector_layout.js`

(or equivalent path inside `custodian-terminal`)

**Role:**
Spatial map of base sectors.

**Why touched:**

* Add FABRICATION node
* Decide position (edge / peripheral recommended)
* Ensure layout does not assume exactly 8 sectors

This is a **structural UI update**, not cosmetic.

---

## 1.4 Documentation (Contractual Truth)

### 🔹 `docs/PROJECT_MAP.md`

* Update canonical sector list to 9
* Mention FABRICATION as present-but-inert

### 🔹 `docs/INFORMATION_DEGRADATION.md`

* Update examples that enumerate sectors
* Clarify degraded repair reporting:

  * exact → approximate → vague

### 🔹 `docs/SystemDesign.md` (light touch)

* Note FABRICATION exists before it functions

---

# 2. File-by-File Change Requirements (Exact)

Below is what Codex must do **per file**, without interpretation.

---

## 2.1 `state.py`

**Required changes:**

* Ensure `self.materials` exists (already does)
* Ensure `self.active_repairs` holds **objects**, not ints
* Ensure FABRICATION sector is instantiated like the others
* Ensure `snapshot()` includes enough repair data for STATUS

**Must not:**

* Add logic
* Mutate materials in snapshot
* Hardcode sector count

---

## 2.2 `repairs.py`

**Required changes:**

* Replace integer tick model with progress objects
* Deduct materials **once, at repair start**
* Tick `remaining`
* Use `total` only for UI
* Complete repair when `remaining <= 0`

**Must not:**

* Refund materials
* Auto-repair anything
* Assume sector type

---

## 2.3 `config.py`

**Required changes:**

* Add `"FABRICATION"` to canonical sector definitions
* Ensure any lists/sets reflect **9 sectors**

**Must not:**

* Introduce phase flags
* Gate FABRICATION behind unlock logic (not yet)

---

## 2.4 `structures.py`

**Required changes:**

* Add at least one FABRICATION structure (e.g. “FAB CORE”)
* Bind it to sector `"FABRICATION"`

**Must not:**

* Add production logic
* Consume materials
* Add commands

---

## 2.5 `status.py`

**Required changes:**

* Always show repair **cost**
* Show progress:

  * FULL: `2 / 4 TICKS`
  * DEGRADED: `~HALF COMPLETE`
  * SEVERE: `REPAIR IN PROGRESS`
* Include FABRICATION in sector list
* Preserve order invariants

**Must not:**

* Hide materials
* Auto-summarize or advise

---

## 2.6 `sector_layout.js`

**Required changes:**

* Add FABRICATION node
* Do not break existing coordinates
* Do not assume fixed-length sector arrays

**Must not:**

* Add interactivity
* Add tooltips or logic

---

## 2.7 Docs

**Required changes:**

* Replace “8 sectors” → “9 sectors”
* Update STATUS examples
* Clarify degraded repair info rules

**Must not:**

* Over-explain mechanics
* Add future features

---

# 3. Global Invariants (Codex Must Respect)

These are **non-negotiable**:

* `GameState` is the single source of truth
* Terminal commands do not own logic
* Repairs are time-based and interruptible
* Materials are scarce and explicit
* FABRICATION exists but does nothing
* No combat assumptions
* No passive income
* No hidden automation

---

# 4. Implementation Risk Summary

* **Difficulty:** Medium
* **Risk:** Low
* **Primary complexity:** `active_repairs` migration
* **Primary coordination cost:** docs + UI map

This is a **clean, well-contained change set**.

---

## Next step (if you want)

I can now:

* produce **exact diffs** for all files above, in safe order
* or produce a **Codex prompt** that includes this context verbatim
* or do **backend-only first**, then UI/docs

Say which, and we proceed cleanly.
