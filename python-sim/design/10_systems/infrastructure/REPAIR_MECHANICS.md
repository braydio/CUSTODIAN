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
