Below is a **clean, implementable instructional** for introducing the **first slice of the resource economy** in _CUSTODIAN_, written to slot directly into your existing architecture and respect all locked decisions. This is **Phase-correct**, minimal, and deliberately leaves seams for later expansion.

I am explicitly aligning this with the locked loop and terminal contract in your devlog and architecture notes .

---

# Phase 1 Resource Economy — Instructional Specification

> **Goal:**
> Introduce material scarcity that creates real tradeoffs **without** introducing inventory complexity, UI creep, or combat dependencies.

This phase exists to answer one question:

> **“Can I afford to fix what just broke?”**

Nothing more.

---

## 1. Canonical Resource Model (Lock This)

### 1.1 Single Resource Only

Introduce **exactly one** campaign-scoped resource:

```text
MATERIALS
```

- Integer value
- Campaign-local (lost on campaign end)
- No subtypes
- No quality tiers
- No weight, storage, or transport logic

**Rationale:**
Multiple resources add decision _noise_ before the player understands cost. One resource makes cost **legible**.

---

### 1.2 Where Materials Live

Add to `GameState`:

```python
state.materials: int
```

Initial tutorial value (recommended):

```text
MATERIALS = 3
```

This is **intentionally insufficient** to repair everything after the first assault.

---

## 2. What Materials Are Used For (Hard Scope)

In Phase 1, **materials are consumed only by repair and reconstruction**.

| Action                       | Uses Materials? | Notes     |
| ---------------------------- | --------------- | --------- |
| Repair DAMAGED → OPERATIONAL | ✅              | Cheap     |
| Repair OFFLINE → DAMAGED     | ✅              | Moderate  |
| Rebuild DESTROYED → OFFLINE  | ✅              | Expensive |
| Fabricate new structures     | ❌              | Phase 2   |
| Power routing                | ❌              | Never     |
| Combat actions               | ❌              | Never     |
| Assault defense              | ❌              | Never     |

> **Important:**
> Assault success does **not** generate materials. Defense preserves; expeditions provide.

---

## 3. Repair Costs (First-Pass Numbers)

These numbers are intentionally small and painful.

| Transition            | Material Cost |
| --------------------- | ------------- |
| DAMAGED → OPERATIONAL | 1             |
| OFFLINE → DAMAGED     | 2             |
| DESTROYED → OFFLINE   | 4             |

Design intent:

- You **cannot** fully recover from a bad assault without leaving the base.
- “Just patch the worst thing” is a valid and common choice.
- Clean defenses are rewarded.

---

## 4. Repair Rules (Reinforced)

All previously discussed repair rules still apply:

- Repairs:
  - Consume **time** (via `WAIT`)
  - Consume **materials**
  - Are **interruptible**

- Reconstruction (`DESTROYED → OFFLINE`):
  - **Not allowed during an active assault**
  - Allowed post-assault only

- Autopilot:
  - Does **not** spend materials
  - Does **not** repair in Phase 1

---

## 5. How the Player Gets Materials (Phase 1)

### 5.1 Single Source: Expeditions

In Phase 1:

> **The only way to gain materials is to leave the base and return.**

You do **not** need to implement full expeditions yet.

Instead, stub the loop:

- Add a temporary command (dev-only or tutorial-only):

  ```text
  SCAVENGE
  ```

- Behavior:
  - Advances time by N ticks
  - Triggers assault timer advancement as usual
  - Returns a small random material amount (e.g. 1–3)

This is a **placeholder**, not a final mechanic.

> The important thing is not _how_ materials are gained —
> it’s that **gaining them increases risk**.

---

### 5.2 No Passive Income

Materials do **not**:

- Accrue over time
- Appear from defense
- Appear from waiting
- Appear from success alone

This preserves the core tension:

> **Stability vs progress**

---

## 6. STATUS Output (Minimal, Visible)

Update `STATUS` to include a resource block:

```text
RESOURCES:
MATERIALS: 2
```

Rules:

- Always visible (even with degraded COMMS)
- Never estimates
- Never projections
- Never advice

If materials are zero:

```text
MATERIALS: 0
```

No warnings. The player figures it out.

---

## 7. Failure & Pressure (Subtle but Real)

Running out of materials does **not** cause immediate failure.

Instead, it causes:

- Damaged systems to persist
- Defenses to remain offline
- Future assaults to be harder
- Expedition pressure to increase

This aligns with the campaign philosophy:

> **Failure is informational and positional, not binary.**

---

## 8. Explicit Non-Goals (Do Not Implement Yet)

Do **not** add any of the following in Phase 1:

- Multiple resource types
- Crafting trees
- Fabrication queues
- Storage limits
- Loot tables
- Salvage from enemies
- Material drops during assault
- UI affordances beyond STATUS

All of these belong **after** the first full repair → expedition → assault loop is playable.

---

## 9. Why This Is the Correct First Cut

This design:

- Integrates cleanly with:
  - terminal-first interface
  - explicit time model
  - location-based authority

- Requires **no combat implementation**
- Creates immediate, readable tension
- Teaches the player what matters **without tutorials**
- Leaves clean seams for:
  - fabrication
  - multitool repair
  - bots
  - power-material coupling
  - campaign rewards

Most importantly:

> It makes **repair decisions meaningful** before combat mastery exists.

---

## 10. Next Natural Extensions (Not Now)

Once this phase is stable, the **correct** next additions are:

1. **Fabrication sector**
   - Converts materials → structures

2. **Combat presence modifiers**
   - Player presence reduces degradation

3. **Knowledge-gated efficiencies**
   - Repairs get cheaper, not free

4. **Autopilot baseline repair**
   - Only DAMAGED → OPERATIONAL, very slow

None of those should be started until this phase is _felt_ in play.

---

### Bottom line (direct)

You are doing this in the right order.

Implement **materials + repair costs + expedition income** first.
If that loop isn’t interesting, nothing built on top of it will be.

Below is a **concrete, minimal, code-accurate implementation plan with exact diffs** to add the **initial materials economy** to the current CUSTODIAN codebase **without breaking Phase-1 guarantees**.

I am deliberately keeping this **surgical**:

- no new commands yet
- no fabrication yet
- no UI creep
- no hidden ticking
- no balance bikeshedding

This gives you a real resource spine you can safely build on.

---

# INITIAL MATERIALS ECONOMY — IMPLEMENTATION DIFFS

## Design constraints (locked before code)

These are enforced by the diffs below:

- **Single resource**: `materials`
- **Campaign-scoped** (lives in `GameState`)
- **No passive income**
- **No decay**
- **Only consumed by repair / rebuild (future)**
- **Visible in STATUS**
- **Mutated only by explicit events**

---

## 1️⃣ Add materials to `GameState`

### File

```
game/simulations/world_state/core/state.py
```

### Diff

```diff
diff --git a/game/simulations/world_state/core/state.py b/game/simulations/world_state/core/state.py
index 9c2a1d1..e41b7c9 100644
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
+        # ── Resources (campaign-scoped) ─────────────────────────────
+        # Single resource for Phase 1–2 economy.
+        # Expanded later into typed materials.
+        self.materials = 0
```

✅ **Why here**
`GameState` is already the single source of truth. Resources must live nowhere else.

---

## 2️⃣ Expose materials in `STATUS`

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
+            "materials": self.materials
+        }
```

---

### File

```
game/simulations/world_state/terminal/commands/status.py
```

### Diff

```diff
@@ def handle_status(state: GameState):
     lines = [
         f"TIME: {state.time}",
         f"THREAT: {state.threat_bucket()}",
         f"ASSAULT: {state.assault_state()}",
     ]
+
+    lines.append("")
+    lines.append("RESOURCES:")
+    lines.append(f"- MATERIALS: {state.materials}")
```

✅ **Resulting STATUS output**

```
RESOURCES:
- MATERIALS: 3
```

This obeys:

- all-caps
- deterministic ordering
- no advice

---

## 3️⃣ Add material gain via explicit world events (NOT time)

We do **not** add commands yet.
We inject **controlled material acquisition** through **events**.

### File

```
game/simulations/world_state/core/events.py
```

### Add helper

```diff
+def grant_materials(state, amount, reason):
+    state.materials += amount
+    return f"[RESOURCE GAIN] +{amount} MATERIALS ({reason})"
```

---

### Example: hook into an existing return-style event

Locate a low-impact ambient or expedition-return event (exact name may differ; adjust as needed).

### Diff

```diff
@@ def handle_expedition_return(state):
     lines = []
+
+    gained = random.randint(2, 4)
+    msg = grant_materials(state, gained, "SCAVENGED SALVAGE")
+    lines.append(msg)
```

✅ **Why events, not ticks**

- No passive income
- No WAIT abuse
- Keeps recon/expedition meaningful
- Easy to rebalance later

---

## 4️⃣ Gate repairs on materials (core economy loop)

This is the **most important part**.

### Rule enforced in code:

> You cannot repair without materials.

### File

```
game/simulations/world_state/core/assaults.py
```

Locate post-assault repair logic (search for sector damage resolution).

### Diff (example pattern)

```diff
@@ def apply_repair(state, sector):
-    sector.status = SectorStatus.STABLE
+    if state.materials <= 0:
+        return "[REPAIR FAILED] INSUFFICIENT MATERIALS"
+
+    state.materials -= 1
+    sector.status = SectorStatus.STABLE
+    return "[REPAIR COMPLETE] MATERIALS CONSUMED: 1"
```

If repairs currently happen inline without a function, **extract this logic** into a helper so it can be reused later by:

- multitool repair
- fabrication bots
- command-issued repairs

---

## 5️⃣ Prevent auto-repair from bypassing economy

You explicitly said:

> autopilot autorepair exists later, is weak, and not at start

So we **hard-disable** free repair.

### File

```
game/simulations/world_state/core/assaults.py
```

### Diff

```diff
- sector.status = SectorStatus.STABLE
+ sector.status = SectorStatus.DAMAGED
```

And require explicit repair paths to consume materials.

This ensures:

- damage persists
- repairs are decisions
- materials matter immediately

---

## 6️⃣ Tests (minimal but critical)

### File

```
tests/test_resources.py
```

### New tests

```python
def test_materials_start_at_zero():
    state = GameState()
    assert state.materials == 0


def test_repair_consumes_materials():
    state = GameState()
    state.materials = 1
    sector = state.sectors["POWER"]
    sector.status = SectorStatus.DAMAGED

    msg = apply_repair(state, sector)

    assert state.materials == 0
    assert sector.status == SectorStatus.STABLE
    assert "MATERIALS CONSUMED" in msg
```

These lock the economy spine so it can’t regress silently.

---

## What this unlocks next (important)

With **just these diffs**, you now have:

- a real resource economy
- meaningful loss
- visible scarcity
- a repair loop
- a seam for fabrication
- a seam for multitool repair
- no UI or command expansion yet

### Safe next additions (in order)

1. `SALVAGE` event tuning
2. `REPAIR <SECTOR>` command
3. Fabricator sector consuming materials
4. Weak autopilot repair (material-inefficient)
5. Multitool repair as time-based material drain

---

## Hard stop (coach mode)

Do **not** add:

- multiple resources
- crafting trees
- percentages
- upkeep
- market logic
