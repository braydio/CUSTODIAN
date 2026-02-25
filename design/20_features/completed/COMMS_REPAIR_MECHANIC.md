
Absolutely — **COMMS repair must directly improve information fidelity**.
Right now fidelity is a *derived property*, but there is no mechanical connection between sector integrity and fidelity levels. We’re going to fix that.

In this spec:

* I’ll precisely define how **COMMS sector integrity maps to fidelity**
* I’ll define transition thresholds
* I’ll define how changes in fidelity affect:

  * STATUS output
  * WAIT output
* I’ll provide **exact code diffs** for the implementation
* I’ll provide **tests** for the behavior

This will make COMMS repair **meaningful**, not cosmetic.

---

# 🧠 DESIGN PRINCIPLES

1. **Fidelity is determined by COMMS integrity only**

   * Other sectors may be degraded, but *information fidelity* is specifically about COMMS
2. **COMMS integrity must be persistent**

   * Until repaired, fidelity stays at its current level or worse
3. **Repair can raise fidelity**

   * As COMMS integrity passes thresholds, fidelity improves
4. **Fidelity determines how STATUS & WAIT are filtered**

   * These are tied to COMMS level, not abstract “COMMS status”
5. **Fidelity changes should emit events**

   * Provide feedback to the player immediately

---

# 📊 FIDELITY ↔ COMMS INTEGRITY MAPPING

This mapping is absolute and deterministic.

| COMMS INTEGRITY | FIDELITY LEVEL |
| --------------- | -------------- |
| 85–100          | FULL           |
| 60–84           | DEGRADED       |
| 30–59           | FRAGMENTED     |
| 0–29            | LOST           |

**Codex Rule:** Fidelity must be recomputed *every world tick* after repair effects.

---

# 🧠 SYSTEM BEHAVIOR SUMMARY

### Before Repair

* COMMS integrity drops from assault
* Fidelity falls accordingly
* STATUS & WAIT use lower fidelity

### During Repair

* Integrity rises via WAIT
* As thresholds are crossed, fidelity upgrades
* A fidelity increase emits a *one-time event*

### After Repair

* Fidelity reaches FULL when COMMS integrity ≥85
* STATUS now shows richer info
* WAIT now uses stricter suppression rules

---

# 🛠 IMPLEMENTATION PLAN

This diff assumes you already have:

* `state.sectors["COMMS"].integrity`
* `step_world(state)` advancing ticks
* STATUS and WAIT systems already respecting fidelity levels

We will:

1. Add a fidelity field to `GameState`
2. Update fidelity after each tick
3. Emit fidelity-change events
4. Connect fidelity to rendering pipelines (STATUS/WAIT)

---

## ✅ DIFF 1 — Add Fidelity State

File:
`game/simulations/world_state/core/state.py`

```diff
 from dataclasses import dataclass, field
 from typing import Dict, Optional
 
+from enum import Enum, IntEnum
```

```python
 class InformationFidelity(IntEnum):
     FULL = 3
     DEGRADED = 2
     FRAGMENTED = 1
     LOST = 0
```

Within the `GameState.__init__`:

```diff
     def __init__(self):
         ...
         self.sectors: dict[str, SectorState] = {}
+        self.fidelity: InformationFidelity = InformationFidelity.FULL
```

---

## ✅ DIFF 2 — Fidelity Computation Logic

Add this utility:

File:
`game/simulations/world_state/core/fidelity.py`

```python
from .state import InformationFidelity, SectorState

# Thresholds controlling fidelity:
F_FULL = 85
F_DEGRADED = 60
F_FRAGMENTED = 30

def compute_fidelity(comms_sector: SectorState) -> InformationFidelity:
    integrity = comms_sector.integrity

    if integrity >= F_FULL:
        return InformationFidelity.FULL
    if integrity >= F_DEGRADED:
        return InformationFidelity.DEGRADED
    if integrity >= F_FRAGMENTED:
        return InformationFidelity.FRAGMENTED
    return InformationFidelity.LOST
```

---

## ✅ DIFF 3 — Update Fidelity Each Tick

In `step_world(state)`:

```diff
+from game.simulations.world_state.core.fidelity import compute_fidelity

 def step_world(state: GameState):
     ...
 
+    # --- UPDATE FIDELITY (based on COMMS) ---
+    old = state.fidelity
+    comms = state.sectors.get("COMMS")
+    if comms:
+        state.fidelity = compute_fidelity(comms)
+        if state.fidelity != old:
+            # emit event for fidelity change
+            level_name = state.fidelity.name
+            state.last_tick_events.append(
+                f"[EVENT] INFORMATION FIDELITY UPGRADED TO {level_name}"
+            )
```

This ensures fidelity updates each tick after repair.

---

## ✅ DIFF 4 — STATUS & WAIT Read Fidelity From `state.fidelity`

Anywhere your rendering code uses COMMS to determine fidelity, replace with:

```python
fidelity = state.fidelity
```

### Example in STATUS

```diff
- if comms_status == "STABLE":
-     fidelity = InformationFidelity.FULL
+ fidelity = state.fidelity
```

### Example in WAIT

```diff
- use_comms_to_determine_output()
+ use state.fidelity instead
```

You should not reference sector integrity directly anywhere outside this mapping.

---

# 📣 MESSAGE GUIDELINES

When fidelity upgrades, WAIT / STATUS should show:

### Full Upgrade Event (FULL)

```text
[EVENT] INFORMATION FIDELITY UPGRADED TO FULL
```

### Degraded Upgrade Event

```text
[EVENT] INFORMATION FIDELITY UPGRADED TO DEGRADED
```

And so on.

These events count as non-interpretive lines during WAIT.

---

## 🧪 TESTS

### `tests/test_fidelity_upgrade.py`

```python
def test_comms_repair_improves_fidelity(step_world, game_state):
    comms = game_state.sectors["COMMS"]
    comms.integrity = 50  # FRAGMENTED
    game_state.fidelity = InformationFidelity.FRAGMENTED

    game_state.player_location = "COMMS"
    cmd_repair(game_state, "COMMS")

    # repair to above 60 (DEGRADED)
    for _ in range(3):
        step_world(game_state)

    assert game_state.fidelity == InformationFidelity.DEGRADED

    # repair to above 85 (FULL)
    for _ in range(5):
        step_world(game_state)

    assert game_state.fidelity == InformationFidelity.FULL
```

---

# ✔ RESULTING EFFECTS

* **COMMS repair now directly impacts game clarity**
* STATUS improves immediately as fidelity changes
* WAIT narrative richness scales with COMMS repair
* Players feel *rewarded* for restoring COMMS
* Information problems are mechanics, not flavor text

---

# OPTIONAL EXTENSIONS (Not required now)

We can also:

* Make fidelity reversion emit downgrade events
* Tie WAIT event wording fuzziness to fidelity
* Allow partial STATUS details at certain thresholds
* Tie recon feedback to fidelity

Just tell me which direction you want next.

But this core spec and code will make COMMS repair real — not cosmetic.
