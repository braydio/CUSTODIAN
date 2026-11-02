

# PART A — Review of the Tree Map & File Ownership

Based on the **current project map** and the **design-lock devlog**, the CUSTODIAN repo cleanly separates:

* **Authoritative world state** (simulation)
* **Terminal commands** (UI contract)
* **Docs/specs** (non-executable, canonical intent)

The Phase-1 Resource Economy touches **exactly these layers** — no more, no less.

---

## A.1 Files That WILL Be Modified (Existing)

These already exist and are the **correct hook points**.

### 1. Authoritative World State

```
game/simulations/world_state/core/state.py
```

Used for:

* Adding `materials: int`
* Persisting campaign-scoped resources
* Exposing resources via `snapshot()`

Why this file:

* `GameState` already owns **time, threat, assault state, sector state**
* Snapshot is the single source of truth for STATUS and UI projections


---

### 2. STATUS Command Output

```
game/simulations/world_state/terminal/commands/status.py
```

Used for:

* Rendering `RESOURCES` block
* Displaying materials in a COMMS-agnostic way

Why this file:

* STATUS is explicitly locked as **truth display**, not advice


---

### 3. Repair Logic (Consumption Point)

```
game/simulations/world_state/core/repairs.py
```

Status:

* **Newly added in recent work**
* Correct place to:

  * consume materials
  * gate repairs
  * enforce reconstruction rules

Why this file:

* Repairs are **world actions**, not terminal commands
* This preserves separation of concerns

---

## A.2 Files That Will Be Added (New)

These do **not** exist yet and should be added deliberately.

### 4. Temporary Resource Gain Command (Phase-1 Only)

```
game/simulations/world_state/terminal/commands/scavenge.py
```

Purpose:

* Stub expedition risk
* Explicitly grant materials
* Advance time + assault pressure

Why this is correct:

* Commands are the **only player interface**
* Expeditions do not exist yet
* This keeps the economy testable without future systems


---

## A.3 Files That Are Explicitly NOT Used

These are **intentionally untouched** in Phase 1:

* `custodian-terminal/*` (frontend only)
* Assault combat resolvers
* Hub / knowledge systems
* Fabrication / construction code
* Any UI beyond STATUS

This matches the design-lock principle:

> *“Do not expand sideways until the spine is playable.”*
>

---

# PART B — Rewritten Canonical Instructional Markdown

(**Updated for Tree Map + Real Files**)

This is the **final corrected document**, suitable to save as:

```
docs/PHASE_1_RESOURCE_ECONOMY.md
```

---

# PHASE 1 RESOURCE ECONOMY — CANONICAL SPEC (TREE-ALIGNED)

**Project:** CUSTODIAN
**Status:** Design-locked, engine-accurate
**Scope:** Campaign-local materials economy (Phase 1)

---

## 0. Purpose

Introduce **material scarcity** that makes **repair decisions meaningful** without:

* inventory systems
* crafting trees
* combat dependencies
* UI creep

This phase answers one question:

> **“Can I afford to fix what just broke?”**

Nothing else.

---

## 1. Canonical Resource Model (Locked)

### 1.1 Single Resource

Introduce **exactly one** resource:

```
MATERIALS
```

Properties:

* Integer
* Campaign-scoped
* No subtypes
* No decay
* No storage or weight

This aligns with the terminal-first, legibility-first philosophy


---

## 2. Where Materials Live (Authoritative)

**File:**

```
game/simulations/world_state/core/state.py
```

Add to `GameState.__init__`:

```python
self.materials: int
```

Recommended tutorial start value:

```
MATERIALS = 3
```

Why here:

* `GameState` is the **single authoritative spine**
* Snapshot is derived from it
* No command owns state directly


---

## 3. What Materials Are Used For (Hard Scope)

Phase-1 materials are consumed **only** by repairs.

| Action                | Materials | Notes     |
| --------------------- | --------- | --------- |
| DAMAGED → OPERATIONAL | ✅         | Cheap     |
| OFFLINE → DAMAGED     | ✅         | Moderate  |
| DESTROYED → OFFLINE   | ✅         | Expensive |
| Fabrication           | ❌         | Phase 2   |
| Power routing         | ❌         | Never     |
| Combat actions        | ❌         | Never     |
| Assault defense       | ❌         | Never     |

Defense preserves. Leaving the base provides.

---

## 4. Repair Costs (Locked)

| Transition            | Cost |
| --------------------- | ---- |
| DAMAGED → OPERATIONAL | 1    |
| OFFLINE → DAMAGED     | 2    |
| DESTROYED → OFFLINE   | 4    |

Design intent:

* You cannot fully recover without leaving
* Partial repair is a valid choice
* Clean defenses are rewarded

---

## 5. Repair Rules (Engine-Aligned)

Repairs:

* consume **time** (`WAIT`)
* consume **materials**
* are interruptible

Reconstruction:

* forbidden during `state.in_major_assault`
* allowed only post-assault

Autopilot:

* performs no repairs in Phase 1
* never spends materials

Consumption happens in:

```
game/simulations/world_state/core/repairs.py
```

---

## 6. How Materials Are Gained (Phase 1)

### 6.1 Explicit Risk Only

Materials are gained **only** by leaving the base.

Because expeditions are not implemented yet, introduce a **temporary command**:

```
SCAVENGE
```

**File:**

```
game/simulations/world_state/terminal/commands/scavenge.py
```

Behavior:

* advances time
* advances assault timers
* grants a small random amount of materials (e.g. 1–3)

This is a placeholder for expeditions, not a final system.

---

### 6.2 No Passive Income

Materials do **not**:

* accrue over time
* come from WAIT
* come from assault success
* come from defense

This preserves **stability vs progress** tension.

---

## 7. STATUS Output (Truth-Only)

STATUS must show:

```
RESOURCES:
- MATERIALS: 2
```

**Files:**

```
game/simulations/world_state/core/state.py
game/simulations/world_state/terminal/commands/status.py
```

Rules:

* Always visible
* No advice
* No projections
* No warnings

Zero is shown plainly.

---

## 8. Failure & Pressure

Running out of materials does **not** end the campaign.

Instead:

* damage persists
* defenses remain offline
* future assaults are harder
* pressure to leave increases

Failure remains positional and informational


---

## 9. Explicit Non-Goals (Phase 1)

Do **not** implement:

* multiple resources
* crafting trees
* fabrication queues
* storage limits
* loot tables
* salvage during assault
* UI beyond STATUS

These come **after** the first repair → scavenge → assault loop is playable.

---

## 10. Why This Fits the Engine

This design:

* respects terminal-first gameplay
* preserves explicit time advancement
* keeps all mutation in `GameState`
* requires no combat system
* leaves clean seams for:

  * fabrication
  * multitool repair
  * bots
  * efficiency upgrades

---

## Bottom Line

This is the **correct first economy slice** for CUSTODIAN.

If this loop isn’t interesting, nothing built on top of it will be.

---

If you want next, the *correct* follow-ups are:

1. Exact `SCAVENGE` command diff
2. Material-aware repair diffs
3. Tests that lock the economy spine
4. Deletion plan for the SCAVENGE placeholder

Say which one you want.
