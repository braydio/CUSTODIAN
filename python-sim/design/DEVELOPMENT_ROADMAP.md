# CUSTODIAN — Development Roadmap

> **Status:** ACTIVE
> **Last Updated:** 2026-03-03

---

## Core Philosophy

Build the heartbeat first. Validate feel before features.

**Previous optimization:** Deterministic systems integrity.
**New optimization:** Real-time feel + systemic clarity.

---

## Step 1 — Lock Core Game Loop

**Priority:** CRITICAL

Before combat. Before sectors. Before relays.

Establish:

- [ ] Load base
- [ ] Operator exists
- [ ] Simulation runs (fixed-step 60Hz)
- [ ] Pause works
- [ ] Time scaling works (1x, 2x, 4x)
- [ ] Camera works
- [ ] Tick counter visible (debug)

**Deliverable:** Playable empty base where operator moves, pause works, time scaling works.

---

## Step 2 — Camera & Control Polish

**Priority:** HIGH

RimWorld-style isometric camera:

- [ ] Middle-mouse pan
- [ ] Scroll zoom with smooth lerp
- [ ] Screen-edge pan (optional)
- [ ] Clamp camera bounds to base area
- [ ] Zoom levels appropriate for tactical view

---

## Step 3 — Sector Representation Scaffold

**Priority:** HIGH

Create sector system (even if placeholder):

- [ ] Sector Node2D container per sector
- [ ] Sector type (COMMAND, POWER, DEFENSE, ARCHIVE, etc.)
- [ ] Sector health
- [ ] Sector power status
- [ ] Damage visualization
- [ ] Health propagation

**Deliverable:** Colored rectangles showing damage propagation visually.

---

## Step 4 — Minimal Combat Prototype

**Priority:** HIGH

- [ ] One dummy enemy
- [ ] Simple AI (move toward operator)
- [ ] Hitscan test weapon
- [ ] Health bars
- [ ] Damage application pipeline
- [ ] Visual hit feedback (flash)
- [ ] Entity cleanup on death

**Validate:** Combat readable, pause works, damage deterministic, clean removal.

---

## Step 5 — Power System Skeleton

**Priority:** MEDIUM

- [ ] Global power value
- [ ] Sector power requirements
- [ ] Toggle power on/off per sector
- [ ] Visual power indicator
- [ ] Power gating verification

---

## Step 6 — Pause Command Interface

**Priority:** MEDIUM

Simple UI overlay when paused:

- [ ] Toggle power to sector
- [ ] Trigger repair
- [ ] Change time scale
- [ ] View sector status

**Deliverable:** FTL-style command flow works while paused.

---

## Step 7 — Port Python Mechanics (Only Then)

**Priority:** LOW (after feel validation)

After core loop feels good:

- [ ] Review Python assault math
- [ ] Review relay system logic
- [ ] Review logistics formulas
- [ ] Review fabrication queue math
- [ ] Port intentionally, not blindly

**Principle:** Python becomes design reference library, not dependency.

---

## Session Plan

### Session 1 — Core Loop
- [ ] Camera implementation
- [ ] Operator movement feel
- [ ] Zoom scaling
- [ ] Pause toggle

### Session 2 — Sector System
- [ ] Sector containers
- [ ] Health/damage visualization
- [ ] Sector state display

### Session 3 — Combat Prototype
- [ ] One enemy type
- [ ] One weapon
- [ ] Hit detection
- [ ] Health bars

### Session 4+ — Evaluation
- Assess feel
- Adjust priorities
- Continue systems

---

## Why This Order?

Biggest unknown: **Does embodied real-time CUSTODIAN feel correct?**

Don't spend weeks porting relay progression only to discover combat pacing feels wrong.

Validate the heartbeat first.

---

## References

- `MASTER_DESIGN_DOCTRINE.md` — Locked design decisions
- `python-sim/game/` — Reference implementation (deprecated)
