# PROJECT MAP — “Airfield Campaign (Tutorial)”

## 1. Core Fantasy (Locked)

* Post-apocalyptic spacer tech world
* Complete collapse of information systems
* You are a last relic of a forgotten institution, **The Custodian**, preserving and reconstructing knowledge
* Victory is **survival + reconstruction**, not extermination
* Enemies are driven by **ideology, scarcity, and misunderstanding**

---

## 2. High-Level Game Loop (Locked)

```
Recon / Expedition
        ↓
Return with knowledge + materials
        ↓
Build / reinforce base sectors
        ↓
Assault (defense under pressure)
        ↓
Repair, recover, adapt
        ↓
Repeat until campaign objective achieved or lost
```

Campaign progress is **knowledge-driven**, not stat-driven.

---

## 3. Campaign Structure (Tutorial)

### Campaign Premise

* Starts on **home planet**
* Setting: **Destroyed military airfield**
* Primary objective: **Rebuild a ship** to reach the Archive Hub
* World remains hostile even after escape

### Persistence Rules

* **Knowledge & schematics persist**
* **Resources & construction progress are fragile**
* Losing battles sets back material progress, not identity

---

## 4. Base Form Factor (Locked)

### Base Type

* **Static, asymmetrical outpost**
* Inspired by a **destroyed military airfield**
* Large footprint → travel time matters
* Sectorized, not free-form wall building

### Total Sectors (Tutorial)

* **9 total sectors**

  * **2 Critical**
  * **7 Peripheral**

---

## 5. Critical Sectors (Hard Rules)

### C1 — Command Center

**Role**

* Bridge, comms, security monitors
* Full tactical intelligence & control ONLY here

**Player Capabilities (When Present)**

* Enemy monitoring (HP state, ammo state, preparedness)
* Precise defense activation & timing
* Target prioritization
* Power routing & overrides

**Autopilot When Absent**

* Base operates with dumb, reactive logic

**Loss Condition**

* If Command Center is overrun or destroyed
  → **Immediate Battle Lost**
  → Campaign continues with setbacks

---

### C2 — Goal Sector

**Role**

* Ship construction / reconstruction objective
* Does NOT provide combat benefit early

**Rules**

* Cannot be abandoned
* Cannot be rebuilt if destroyed

**Loss Condition**

* Loss = **Campaign Failure**

---

## 6. Peripheral Sectors (Tutorial Set)

(Names may change, structure is locked)

* Main Terminal (near Command)
* Security Gate / Checkpoint (primary ingress)
* Hangar A (open, long sightlines)
* Hangar B (collapsed, ambush routes)
* Fuel Depot (radiation + explosive hazard)
* Radar / Control Tower (sensor value, long travel)
* Service Tunnels (internal shortcuts, sabotage risk)
* Maintenance Yard (scrap-heavy, far)

**Key Principle**

* You cannot be everywhere
* Movement = opportunity cost
* Command presence vs field presence is a constant tradeoff

---

## 7. Custodian (Player Unit)

### Combat Loadout (Tutorial)

* **One melee weapon**
* **One ranged OR deployable**

  * Not both at once

### On-Foot Capabilities

* Fight enemies directly
* Repair damaged systems
* Deploy limited auxiliary defenses
* Manually trigger systems
* Draw enemy aggro

### Health & Loss States

* HP reaches zero = **soft loss**

  * Base continues defending
  * You lose field agency
* If downed in a **critical sector**

  * **Battle Lost**

---

## 8. Autopilot System (Fully Specified)

### Scope

* Operates **per sector**
* No cross-sector coordination

### Activation Rules

* If ≥1 enemy in sector → defenses activate
* If no enemies → defenses disengage

### What Autopilot DOES

* Turrets fire when line-of-sight exists
* Mines auto-arm
* Barriers deploy
* Environmental traps trigger
* Engages all enemies that enter
* Never allows enemies to pass unchallenged

### What Autopilot NEVER Does

* No prediction
* No delayed activation
* No target prioritization
* No pre-arming
* No movement or pursuit
* No action without enemies present

### Targeting Priority

1. First enemy in sector
2. Closest visible threat
3. No threat evaluation

Autopilot is **reliable but dumb** by design.

---

## 9. First Assault — Threat Composition (Locked)

### Total Threat Budget

* **100 Threat Points**
* Enemies arrive in **phases**, not all at once

---

### Group A — Religious Zealots (30 TP)

* Trio of wanderers (≈20 TP total)
* One “holy man” (≈10 TP)
* Melee only, blunt damage
* Poor awareness, trigger traps
* Unpredictable, loud, distracting

**Design Role**

* Teach traps
* Teach target prioritization
* Low lethality, high chaos

---

### Group B — Iconoclasts (30 TP)

* 2 units (≈15 TP each)
* Poorly maintained firearms
* Cautious, observant
* Avoid traps when possible
* Interact with cons, schematics, knowledge

**Design Role**

* Teach non-combat threats
* Teach command-center intel value
* Cause delayed harm (theft, sabotage)

---

### Group C — Raiders (40 TP)

* 4–6 units
* Firearms + makeshift melee
* Moderate coordination
* Opportunistic looting
* Mental state variance

**Design Role**

* Baseline combat threat
* Sustained pressure
* Multi-zone engagement

---

## 10. Assault Pacing & Spawn Logic

### Spawn Triggers

Next group’s spawn timer begins when:

* Previous group crosses into base
  **OR**
* Any enemy from previous group is downed

### Timing

* Semi-random within bounded windows
* Escalation tied to player success, not clock

---

## 11. Morale System (Locked Concept)

* Each group has morale tied to its threat points
* Morale decreases via:

  * Unit deaths
  * Leader death
  * Trap/environmental damage

### Retreat Condition

* Morale < threshold → group attempts to flee

---

## 12. Victory & Failure Conditions

### Battle Victory

* All enemies neutralized
  **OR**
* Remaining enemies retreat

### Battle Loss

* Command Center destroyed
* Custodian downed in critical sector

### Campaign Loss

* Goal Sector destroyed

---

## 13. Design Pillars (Implicit but Clear)

* Knowledge > Materials
* Information = power
* Presence has a cost
* Enemies have intent
* Autopilot is safety, not strategy
* Player mastery = prediction, not reflex

---

## 14. What Is NOT Designed Yet (Intentionally)

* Morale math formulas
* Command Center action economy
* Post-assault damage persistence
* Upgrades beyond tutorial
* Later factions / non-human enemies
* Hub meta-progression details

These are **correctly deferred**.

---

## Bottom Line

You now have:

* A complete tutorial campaign
* A fully specified first assault
* Clear base topology
* Explicit loss rules
* A coherent command vs field tension
* Systems that can be simulated and coded
