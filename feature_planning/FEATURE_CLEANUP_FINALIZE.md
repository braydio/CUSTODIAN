- `feature_planning/`
- `docs/_ai_context/`
- `POWER_SYSTEMS.md`
- `CODEX-FEATURE-RECOMMEND.md`
- assault + world_state code
- TODO.md vs IMPLEMENTED_FEATURES.md

Now we stop improvising and build a **controlled execution roadmap**.

1. A **clear phase map** of what’s still outstanding (by system)
2. A **dependency-ordered dev roadmap**
3. For each phase:
   - Objective
   - Files touched
   - Architectural risk
   - Exit criteria

4. A final **stability-first execution order**

No fluff. Just build strategy.

---

# 🔎 High-Level System Gaps (Remaining Work)

From the consolidated planning docs and current tree , the unfinished major systems are:

### 1️⃣ Power × Performance Integration

- Power routing math exists (`core/power.py`)
- But:
  - It is not fully integrated into:
    - Repairs
    - Assault turret performance
    - Sensor-driven fidelity

  - No unified `effective_output = power_ratio × integrity`

This is partially designed (POWER_SYSTEMS.md), not fully wired.

---

### 2️⃣ Full Embodied Presence Completion

You implemented Phase A skeleton (presence, movement, repair locality), but still missing:

- Assault warning delay when in field
- Transit node risk hooks
- Downed-compatible architecture seam
- Field STATUS restriction tightening

---

### 3️⃣ Assault Instance Upgrade (Live Tactical Feel)

Assault core exists:

```
game/simulations/assault/core/
```

But still too sim-forward:

- Autopilot always primary
- Power not affecting defense math deeply
- No visible live degradation during assault
- No transit-node interactions
- No supply chain tie-in

---

### 4️⃣ Fabrication Realization (Skeleton Exists)

You have:

- FABRICATION sector
- Structures
- Repair integration

Missing:

- Recipes
- Production queue
- Power-linked throughput
- Material sink
- Unlock gating

---

### 5️⃣ Relay / Knowledge Layer (ARRN)

Defined in:

```
feature_planning/CODEX-FEATURE-RECOMMEND.md
```

Not implemented at all.

This becomes your long-term progression system.

---

### 6️⃣ Procedural Description Layer (Event Text Engine)

You researched it.
You designed architecture.
It is not implemented.

Currently:

- Event text is static strings
- WAIT has minimal variation

This is late-phase polish but structurally important.

---

### 7️⃣ Assault ↔ World-State Coherence Pass

Needed:

- Damage persistence logic audit
- Assault scaling vs campaign progress
- Hub-level timeline scaffold
- Failure pressure tuning

---

# 🧭 DEVELOPMENT ROADMAP (Dependency-Ordered)

This is the correct order. Do not reorder unless you want cascading refactors.

---

# 🟢 PHASE 1 — Power Spine Completion

## Objective

Make power mathematically authoritative everywhere.

## Why First?

Everything else (assault, fabrication, repairs, sensors) depends on power.

## Work

### 1. Implement unified effective_output function

File:

```
core/power.py
```

Create canonical:

```
compute_effective_output(structure)
```

Return scalar 0.0–1.0.

### 2. Wire into:

- Repair speed (core/repairs.py)
- Fabricator progress (future-ready hook)
- Sensor fidelity clamp
- Assault turret stats

### 3. Tie sensor_effectiveness → fidelity ceiling

Modify:

```
terminal/commands/status.py
terminal/commands/wait.py
```

Fidelity must now be:

```
min(comms_integrity_fidelity, sensor_effectiveness_fidelity_cap)
```

## Risk

Medium (touches many systems).

## Exit Criteria

- Underpowered turrets visibly weaker
- Underpowered sensors degrade info
- Repairs slow when power reduced
- No randomness added

---

# 🟢 PHASE 2 — Assault Rework (Make It Feel Alive)

## Objective

Make assaults dynamic, readable, and power-sensitive.

## Work

### 1. Apply effective_output to:

```
assault/core/defenses.py
assault/core/autopilot.py
```

- Fire rate scaling
- Damage scaling
- Accuracy scaling

### 2. Add visible live degradation:

- If sector power collapses mid-assault → defense performance drops immediately

### 3. Add brownout regression effect:

If sector damaged mid-repair:

```
repair_remaining += 1
```

### 4. Assault Warning Delay in FIELD mode

Modify:

```
core/simulation.py
terminal/commands/wait.py
```

If in FIELD:

- Delay assault warning by 1–2 ticks.

## Risk

Medium-high (assault logic sensitive).

## Exit Criteria

- Assault outcomes clearly influenced by routing
- Being in field feels dangerous
- Autopilot is sufficient but weaker than optimized routing

---

# 🟢 PHASE 3 — Fabrication System Activation

## Objective

Make FABRICATION matter.

## Work

### 1. Add recipe schema

File:

```
core/fabrication.py (new)
```

Structure:

```
Recipe:
- materials_cost
- power_required
- ticks_required
- unlock_tag
```

### 2. Add production queue in GameState

```
state.fabrication_queue
```

### 3. Production rate:

```
progress += base_rate × effective_output
```

### 4. Add command:

```
FAB BUILD <ITEM>
```

### 5. Output:

- No fluff.
- Just queue status.

## Risk

Low-medium (isolated).

## Exit Criteria

- Fabrication consumes materials
- Power affects production speed
- Damaged fab slows production

---

# 🟢 PHASE 4 — Relay Knowledge Layer (ARRN)

This is your progression spine.

## Objective

Add long-term knowledge system.

## Work

### 1. Add relay_nodes dict to GameState

### 2. Add STABILIZE RELAY task (field-only)

### 3. Add SYNC (command-only)

### 4. Add knowledge_index modifiers:

Examples:

- remote repair cost -1
- degraded fidelity improved
- fabrication unlock

### 5. Add STATUS section:

```
RELAY NETWORK
```

Fidelity-gated.

## Risk

Low (parallel to other systems).

## Exit Criteria

- Field mode has long-term purpose
- Knowledge changes mechanics, not stats
- Campaign continuity established

---

# 🟢 PHASE 5 — Procedural Text Layer

Late-phase polish.

## Objective

Introduce deterministic text variability.

## Work

### 1. Add NarrativeSurface layer

### 2. Add template families per channel

### 3. Seeded description RNG separate from simulation RNG

### 4. Debug trace for template selection

## Risk

Low (if isolated).

## Exit Criteria

- No contradictions possible
- No verbosity creep
- No change to sim behavior

---

# 🟢 PHASE 6 — Campaign Scaling & Hub Timeline

Now you unify everything.

## Work

- Assault scaling vs campaign progress
- Hub unlock gating
- Campaign world timeline generation
- Non-player-facing score
- Replayable world arcs

This is endgame architecture.

---

# 🔥 The Correct Build Order (Final)

1. **Power Spine Completion**
2. **Assault Rework**
3. **Fabrication Activation**
4. **Relay Knowledge Layer**
5. **Procedural Text Engine**
6. **Campaign Scaling Pass**

Do not start relay before power.
Do not scale campaign before assault feels good.

---

# 🎯 Brutally Honest Assessment

Right now your weakest system is:

> Assault lacks tangible mechanical tension tied to routing.

Fix that first.

Your strongest foundation is:

> World-state core + authority model.

According to a document from **2026-02-04** (your design lock-in) and your unified backlog, here’s the **one-pass, more granular roadmap** for **each remaining TODO item**—no loops, no re-arguing, just “what to build / where / how you’ll know it’s done.”

---

## 1) OPEN — ARRN relay network feature set

**Goal:** Make “field work” create persistent _knowledge_ value: relays you stabilize → packets you sync → knowledge index that unlocks efficiencies and reporting.
**Backlog asks:** new state fields, commands, authority/fidelity behavior, tests.

### Deliverables

- **State (GameState)**
  - `relay_nodes`: dict of relay_id → status + location + stability + last_seen
  - `relay_packets_pending`: int or list of packet records
  - `knowledge_index`: int (or dict of knowledge domains if you want future-proofing)
  - `last_sync_time`: int tick timestamp

- **Commands**
  - `SCAN RELAYS`
  - `STABILIZE RELAY <ID>`
  - `SYNC`

### Implementation steps (tight)

1. Add `core/relays.py` (new): state structs + tick helpers
2. Extend `core/state.py`: initialize new fields; include in snapshot if needed
3. Add terminal command handlers (new file under `terminal/commands/`):
   - scan: list known relays (fidelity gated)
   - stabilize: requires FIELD locality + time cost, sets node stable
   - sync: requires COMMAND authority; converts pending packets → knowledge_index

4. Fidelity behavior:
   - COMMAND view: precise relay listing + packet counts
   - FIELD: partial / “heard-of” relays only, no global certainty (matches your authority model)

5. Tests:
   - authority: SYNC denied outside command
   - locality: STABILIZE denied unless at relay location
   - timed stabilization: consumes ticks / progress modeled
   - fidelity output redaction rules

### Exit criteria

- You can: `SCAN RELAYS` → travel → `STABILIZE RELAY X` → return → `SYNC` and see knowledge rise.
- Deterministic under `WAIT` (no hidden time).

---

## 2) PARTIAL — Assault-resource coupling follow-ons after transit interception

**Goal:** Turn “interception” into a _budgeted decision_ loop: you spend materials to prep lanes / affect interception; salvage payout responds to that spend (bounded, deterministic).
**Backlog asks:** Phase B operator spend command; Phase C bounded salvage coupling.

### Deliverables

- **Phase B: explicit spend command**
  - Command like: `INTERCEPT PREP <LANE|NODE> <AMOUNT|MODE>`
  - Mutates a per-assault “prep ledger” (materials spent; effects applied)

- **Phase C: salvage payout coupling**
  - Salvage reward is adjusted by:
    - materials/ammo spent during assault resolution
    - but clamped to prevent degenerate loops (deterministic bounds)

### Implementation steps (tight)

1. Add `assault prep ledger` to AssaultInstance (world_state assault object, not UI)
2. Add a new terminal handler for spend
3. Modify assault outcome/salvage computation:
   - base_salvage from threat band
   - delta = f(spend) with clamp

4. Add tests:
   - spend reduces materials
   - payout changes within fixed bounds
   - same seed/state ⇒ same payout

### Exit criteria

- Prepping a lane changes outcomes in a visible way and affects salvage in a predictable bounded way.

---

## 3) PARTIAL — Embodied-presence future compatibility: DOWNED pathways

**Goal:** Make the system compatible with “player downed during assault” without rewriting later.
**Backlog asks:** implement DOWNED state pathways + interruption/recovery flow.

### Deliverables

- A `DOWNED` state that can be entered (even if not yet triggered by combat)
- Movement/repair interruptions behave safely when downed
- A recovery flow that returns to a known location/state (e.g., COMMAND or nearest safe node)

### Implementation steps (tight)

1. Extend player presence model/state machine to include DOWNED transitions
2. Terminal processor rules:
   - while DOWNED: deny MOVE/REPAIR/WRITE commands with consistent messaging
   - allow WAIT and possibly STATUS (local-only)

3. If downed mid-task:
   - task pauses or fails deterministically (choose one rule and lock it)

4. Tests:
   - entering downed denies actions
   - recovery restores authority rules cleanly

### Exit criteria

- You can forcibly set DOWNED in a test and the command surface remains coherent (no crashes, no contradictory outputs).

---

## 4) PARTIAL — Infrastructure next-step systems: logistics throughput cap + policy QoL

**Goal:** Add a throughput ceiling that creates “soft failure” pressure, plus quality-of-life policy commands.
**Backlog asks:** `core/logistics.py`, integrate with sim/status; add `POLICY PRESET` + `POLICY SHOW`; tests.

### Deliverables

- **Logistics cap**
  - A computed `logistics_throughput` vs `logistics_load`
  - Penalties when overloaded (e.g., slower repairs, slower fabrication, worse supply efficiency)

- **Policy commands**
  - `POLICY SHOW`: renders current policy table/state
  - `POLICY PRESET <name>`: applies a curated set of policy toggles (validated)

### Implementation steps (tight)

1. Create `core/logistics.py`:
   - compute load from active systems (repairs, fabrication, maybe turrets later)
   - apply penalties through a single “multiplier” function used by repairs/fab

2. Hook logistics into:
   - simulation tick step (world_state/core/simulation.py)
   - STATUS reporting (policy/status command section)

3. Implement policy commands in terminal layer:
   - presets live in a dict; applying a preset runs invariant checks

4. Tests:
   - overload triggers penalty
   - presets apply exact expected policy states
   - invariants catch illegal combos

### Exit criteria

- You can push the base “too busy” and see deterministic slowdowns + clean STATUS visibility.

---

## 5) PARTIAL — Power-performance exact mechanics missing

**Goal:** Finish the “power is authority” promise: per-structure performance obeys the exact equations and edge behaviors (misfires, low-output, thresholds like blast doors if you keep them).
**Backlog asks:** defense output wiring, explicit misfire/low-output, threshold behavior, consistency across fabrication/repair math.

### Deliverables

- Canonical per-structure `effective_output` model used by:
  - defenses
  - repairs
  - fabrication throughput

- “Low power behavior” that is deterministic:
  - either _misfire events_ (seeded) or _continuous degradation_ (recommended: continuous first; misfire later if you insist)

- Threshold behavior (blast doors) only if you explicitly keep it

### Implementation steps (tight)

1. Define one “power → output” function in `core/power*.py` (single source of truth)
2. Apply to:
   - assault defense math (assault/core/defenses.py)
   - repair speed math (core/repairs.py)
   - fabrication tick (core/fabrication.py)

3. Add tests:
   - known power ratios produce exact output ratios
   - no regressions across subsystems

### Exit criteria

- If power is cut, defenses **immediately** weaken; repairs/fab slow; outputs are consistent everywhere.

---

## 6) OPEN — Deterministic narrative/event-description architecture

**Goal:** Make event text varied but _never contradictory_, and gated by fidelity.
**Backlog asks:** canonical event instance records + observability projection; fidelity-gated narrative surface; separate RNG streams; tests for contradictions/redaction.

### Deliverables

- **Canonical event records** (facts)
- **Observability projection** (what the player is allowed to know)
- **Narrative surface** (text templates that render from observables)
- Separate RNG:
  - sim RNG for outcomes
  - text RNG for phrasing only

### Implementation steps (tight)

1. Add event schema (dataclass) for “facts” and “observable view”
2. In event generation:
   - create fact record once
   - derive observable based on fidelity/authority

3. Text generation uses only observable + text RNG
4. Tests:
   - low fidelity never leaks hidden fields
   - multiple renders differ in phrasing but not facts
   - same seed/state ⇒ same facts, stable behavior

### Exit criteria

- You can run the same simulation twice and get identical state transitions, but small safe wording variation.

---

## 7) DECISION — Repair-spec conflict resolution (before more repair refactors)

**Goal:** Stop the docs fighting the code. Decide the canonical repair model, then either close/mark superseded doc(s) or implement the delta.
**Backlog calls out:** earlier spec says local-only; newer planning supports remote damaged repair + local escalation.

### One-pass decision framework (pick one, then ship)

- **Option A (strict local-only):**
  - Strong embodied fantasy, more travel friction
  - Increases “dead time” unless assaults/field events are richer

- **Option B (hybrid remote DAMAGED-only + local escalation):**
  - Fits “command center as authority”
  - Keeps play moving while preserving field importance (OFFLINE/DESTROYED still require locality)
  - _This matches your existing direction and avoids stalling assaults_ (recommended)

### Exit criteria

- Update one canonical doc as “truth” + add a short note in the other marking it superseded.
- Then proceed with any repair feature work safely.

---

## Suggested build order (still one pass, but aligned to the TODO dependencies)

1. **#7 decision** (so you don’t refactor twice)
2. **#5 power-performance** (spine)
3. **#2 assault-resource coupling**
4. **#4 logistics + policy QoL**
5. **#1 ARRN relays**
6. **#3 DOWNED pathways**
7. **#6 narrative architecture**

If you want the next step without another planning loop: tell me “start with item X” and I’ll output a **Codex-ready patch plan** (files + functions + tests) for _that single item_ only.
