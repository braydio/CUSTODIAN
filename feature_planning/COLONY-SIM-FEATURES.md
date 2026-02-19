Now we’re talking about the two things that actually determine whether this becomes addictive or forgettable:

1. Assault instances must feel live and tactical — not abstract math.
2. Fabrication must feel like a real strategic supply chain — not just a timer queue.

We’re going to do this in three parts:

---

# PART I — CURRENT STATE RECONCILIATION

## (Codex must finish incomplete items first)

Below is the explicit reconciliation of what is implemented vs what is not fully wired.

Codex must treat this as priority completion work before adding new systems.

## ONCE the reconcialtion of mandatory required work is complete, review the files in /feature_planning. Identify the planning document that details the implementation of said required work. DO one final review for completion then mark it as complete and move it into the completed folder. Then continue with the changes per this document.

## ✅ Already Implemented

Confirmed live:

- `core/policies.py` — policy state + mapping tables exist.
- `core/state.py` — PolicyState attached to GameState.
- `terminal/commands/status.py` — policy section rendering.
- `core/fabrication.py` — internal tick processing exists.
- `core/power_load.py` + brownout linkage in `events.py`.
- `core/wear.py` — passive wear implemented.
- `terminal/commands/policy.py` — SET / SET FAB / FORTIFY commands wired.
- After-action includes policy load line (`core/assaults.py`).
- Tests for policy mutation/fabrication/power/wear exist.

This is your strategic layer.

---

## ❌ Not Fully Implemented As-Written

These MUST be completed before assault/fabrication expansion:

---

### 1️⃣ Surveillance Coverage Not Deeply Wired

Currently:

- `DETECTION_SPEED`
- `FIDELITY_BUFFER`

Are defined in `core/policies.py`.

But:

- Detection chance in `core/detection.py` does not scale with DETECTION_SPEED.
- Fidelity refresh in `core/fidelity.py` does not incorporate FIDELITY_BUFFER.
- Brownout and interference do not degrade fidelity differently based on surveillance coverage.

### Required Completion

Modify:

```
core/detection.py
core/fidelity.py
core/events.py
```

Integrate:

```python
speed_mult = DETECTION_SPEED[state.policies.surveillance_coverage]
```

Use it to:

- Shorten warning delay
- Increase probability of event detection
- Reduce time to detect ongoing assault

In `refresh_comms_fidelity`:

```python
buffer_mult = FIDELITY_BUFFER[state.policies.surveillance_coverage]
effective_integrity = comms_integrity * buffer_mult
```

This makes surveillance meaningful beyond power cost.

---

### 2️⃣ After-Action Delta Effects Incomplete

Currently:

- Policy load line appears.
- Destroyed buildings shown.
- Basic summary printed.

Missing:

- Before/after integrity comparison.
- Power load change.
- Materials delta.
- Fabrication delay impact.
- Surveillance impact.

Codex must modify:

```
core/assaults.py
```

Add:

```python
pre_snapshot = state.snapshot_before_assault
post_snapshot = state.current_snapshot
```

Compute deltas:

- integrity delta per sector
- material change
- fabrication queue slowdown
- power load shift

Render:

```
ASSAULT IMPACT:
- ARCHIVE integrity -23
- MATERIALS -4
- Power Load +0.8
- Fabrication throughput reduced
```

This is not optional. It creates consequence clarity.

---

### 3️⃣ Fabrication Command Loop Incomplete

Currently:

- Fabrication ticks internally.
- No operator-facing queue management loop.

Missing:

Commands:

```
FAB ADD <item>
FAB QUEUE
FAB CANCEL <id>
FAB PRIORITY <category>
```

Codex must:

Create in:

```
terminal/commands/fabrication.py
```

Implement:

```python
def cmd_fab_add(state, item_name):
    # validate recipe
    # check material availability
    # append FabricationTask
```

Queue rendering in STATUS or separate command:

```
FAB QUEUE
```

Must show:

```
1. DEFENSE DRONE FRAME (12 ticks remaining)
2. ARCHIVE PLATING (34 ticks remaining)
```

Without this, fabrication is invisible.

---

# PART II — ASSAULT INSTANCE: LIVE ACTION SPEC

Now we elevate assault from “math resolution” to “live tactical phase.”

Goal:

- Increase intensity
- Increase immediacy
- Increase operator decision impact
- Maintain terminal-first UX
- Avoid turning into FPS

---

# 1️⃣ Assault Instance Mode

When assault engages:

Switch simulation into:

```
ASSAULT ACTIVE — SECTOR: ARCHIVE
```

Tick cadence remains world-tick driven.

But add:

### Micro-Tactical Actions Available:

- REROUTE POWER <sector>
- BOOST DEFENSE <sector>
- DEPLOY DRONE <sector>
- LOCKDOWN <sector>
- PRIORITIZE REPAIR <sector>

Each action:

- Consumes power or materials
- Applies temporary modifier
- Has duration

---

# 2️⃣ Assault Flow Phases

Instead of immediate resolution:

Use staged resolution:

### Phase 1 — Breach Attempt

- Defense multiplier applied
- Fortification multiplier applied

### Phase 2 — Internal Contest

- Sector integrity reduced per tick
- Repair drones act
- Power rerouting matters

### Phase 3 — Critical Roll

- Building destruction possible
- Archive loss if AR_CORE destroyed

This makes assault last 5–12 ticks, not instant.

---

# 3️⃣ Real-Time Feeling Without Real-Time Engine

During assault:

Each WAIT (5 ticks) is compressed to 1 assault tick.

In assault:

```
WAIT = 1 tick
```

In world:

```
WAIT = 5 ticks
```

This increases pacing intensity.

---

# 4️⃣ Tactical Feedback Lines

Every assault tick must output:

```
ARCHIVE UNDER FIRE
- DEFENSE GRID ENGAGED
- STRUCTURAL DAMAGE ACCRUING
- AUTONOMOUS DRONE REPAIRING
```

Dynamic lines based on:

- Power load
- Defense readiness
- Repair intensity
- Surveillance coverage

---

# 5️⃣ Assault Interaction with Policies

Defense readiness increases:

- mitigation
- wear

Repair intensity increases:

- recovery rate
- material drain

Surveillance affects:

- early detection
- target switching

Fortification affects:

- breach probability

This is where colony sim meets tactical defense.

---

# PART III — SUPPLY CHAIN FABRICATION SPEC

Right now fabrication is:

Materials → Task → Complete.

That’s too flat.

We introduce a tiered supply chain.

---

# 1️⃣ Resource Tiers

Tier 0: Scrap
Tier 1: Refined Components
Tier 2: Assemblies
Tier 3: Strategic Modules

Example:

```
Scrap → Components → Drone Frame → Repair Drone
Scrap → Plating → Archive Reinforcement
Scrap → Electronics → Sensor Array
```

---

# 2️⃣ Fabrication Facilities Matter

FABRICATION sector buildings determine:

- Queue slots
- Max concurrent categories
- Throughput multiplier

Destroy FAB_TOOLS → lose advanced assembly ability.

---

# 3️⃣ Throughput Bottlenecks

Each fabrication category has:

- Required input tier
- Power cost
- Minimum surveillance threshold (for advanced items)

This ties systems together.

---

# 4️⃣ Example Supply Chain

Repair Drone:

Requires:

- 2 Drone Frames
- 1 Electronics Core
- 5 Components

Drone Frame requires:

- 3 Components

Components require:

- 2 Scrap

This creates production planning.

---

# 5️⃣ Fabrication Must Influence Assault

If drone stockpile is low:

Repair slower during assault.

If turret ammo production paused:

Defense readiness effectiveness drops.

Fabrication must impact combat readiness.

---

# IMPLEMENTATION PLAN — ASSAULT & SUPPLY CHAIN

Order:

1. Finish incomplete surveillance wiring.
2. Complete fabrication command loop.
3. Implement after-action delta snapshot system.
4. Introduce assault phase system.
5. Modify assault resolution to multi-tick.
6. Add tactical command handlers.
7. Expand fabrication into tiered supply chain.
8. Add resource conversion recipes.
9. Add storage tracking per resource type.
10. Update STATUS to show inventory tiers.

---

# FINAL VISION

Between assaults:

- Manage power load
- Allocate fabrication
- Convert scrap into infrastructure
- Tune policies
- Plan drone stock

During assaults:

- Reroute
- Boost
- Deploy
- Contain
- React

After assault:

- Analyze deltas
- Repair
- Reallocate
- Prepare

This creates:

Colony pacing
Factory planning
Tactical tension
Strategic consequence

All within your deterministic terminal-first framework.

---

Please note somewhere that subsequent features to focus on will include:

- Exact assault multi-phase state machine spec
- Exact fabrication recipe schema
- Or a unified “Resilience Index” model tying everything together

