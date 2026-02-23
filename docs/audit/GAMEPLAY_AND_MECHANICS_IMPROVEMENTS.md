# GAMEPLAY_AND_MECHANICS_IMPROVEMENTS.md

**CUSTODIAN — Mechanical & Experiential Refinement Layer**

This document isolates **player-facing systems, mechanical depth, pacing, and long-term campaign identity**.
It intentionally excludes engine refactors and code-efficiency concerns.

---

# 1. Assault Experience — Make It Player-First

## Current State

Assaults are mechanically strong:

- Deterministic
- Multi-tick resolution
- Interception routing
- After-action reports
- Policy + logistics coupling
- Ammo expenditure + defense throughput

However:

- Player agency is front-loaded (preparation), not mid-assault.
- Assaults resolve largely automatically once engaged.
- The system is simulation-rich but interaction-light.
- There is limited meaningful operator decision-making during live engagement.

---

## Required Evolution: Active Tactical Authority Layer

### Add: Mid-Assault Command Decisions

During active assault:

Player may issue limited, costly commands:

- `REDIRECT POWER <SECTOR>`
- `LOCKDOWN <SECTOR>`
- `OVERCLOCK DEFENSE`
- `RECALL FIELD UNIT`
- `VENT ATMOS <ZONE>`
- `DEPLOY DRONES`

Each action:

- Consumes limited tactical currency (power banks, coolant, reserve ammo)
- Has cooldowns
- Alters assault math deterministically
- May cause long-term wear or system strain

---

## Why This Matters

Assaults must feel:

- Reactive
- Tense
- Scarcity-driven
- High consequence

The player should feel like a commander making tradeoffs — not a spectator watching resolution math.

---

# 2. Logistics as a Real Strategic Lever

## Current State

Logistics throughput:

- Impacts fabrication speed
- Impacts policy penalties
- Impacts system performance

But it is mostly invisible to player cognition.

---

## Improvement: Make Logistics a Visible Strategic Pressure

Add:

- `STATUS LOGISTICS`
- Explicit throughput ceiling display
- Overload warning states
- Clear coupling to:
  - Ammo availability
  - Repair time
  - Interception rate
  - Fabrication queue delays

Add mechanic:

### Supply Saturation Events

If player:

- Over-fortifies
- Over-fabricates
- Maintains high readiness constantly

Then:

- Logistics strain builds
- Delays cascade
- Assault defense readiness degrades

Logistics becomes something the player actively manages — not background math.

---

# 3. Fabrication Should Feel Like a Supply Chain, Not a Queue

## Current State

Fabrication:

- Recipe-based
- Priority-adjustable
- Throughput-coupled
- Cancelable

Mechanically solid.

But:

- It lacks strategic tension.
- There are no material classes or dependency chains.
- It doesn’t drive campaign identity.

---

## Improvement: Introduce Tiered Materials

Add material categories:

- Structural
- Electrical
- Ammunition
- Relay Components
- Archival Media

Recipes require:

- Multiple classes
- Cross-category dependencies

Example:

```
AUTOTURRET:
  - 4 Structural
  - 2 Electrical
  - 3 Ammunition
```

---

## Add: Material Shortage Events

Campaign-level strain could:

- Degrade supply of specific material classes
- Force fabrication tradeoffs
- Encourage recon or relay progression

Fabrication should create strategic bottlenecks.

---

# 4. ARRN Relay Layer — Expand to Campaign Spine

## Current State

ARRN:

- Scan
- Stabilize
- Sync
- Small knowledge unlocks

Mechanically present but shallow.

---

## Required Expansion

### Add Relay Tiers

Each relay node:

- Has stability decay over time
- Requires maintenance
- Unlocks domain-specific improvements

Domains:

- POWER
- DEFENSE
- COMMS
- ARCHIVE

Relay progression unlocks:

- Better assault warnings
- Fabrication efficiency
- Policy presets
- Knowledge reconstruction bonuses

---

## Make ARRN the Campaign Backbone

Instead of:

> Survive assault → repeat

Make it:

> Survive → stabilize relays → reconstruct lost knowledge → reshape future assaults

---

# 5. The Core Mechanic Proposal: Ghost Protocol Recovery

This is the recommended pillar mechanic from .

---

## Mechanic: Ghost Protocol Recovery

### Core Idea

Every major system action generates fragmented pre-collapse ghost logs:

- Sensor traces
- Maintenance records
- Distress packets
- Degraded telemetry

You reconstruct truth from fragments.

Progression becomes epistemic, not purely material.

---

## How It Plays

### Fragment Generation

During:

- Assaults
- Repairs
- Relay stabilization
- Fabrication of advanced systems

You gain:

`FRAGMENTS`

Each fragment:

- Tagged by domain
- Has fidelity score
- Accumulates deterministically

---

### Reconstruction Phase

Command surface:

- `SCAN GHOSTLOGS`
- `RECONSTRUCT <DOMAIN>`
- `STATUS KNOWLEDGE`

Domains:

- POWER
- DEFENSE
- COMMS
- ARCHIVE

---

### Deterministic Reconstruction Outcomes

If fidelity threshold met:

→ Permanent unlock

- Efficiency bonuses
- Repair cost reduction
- Better assault ETA precision
- More accurate STATUS reports

If insufficient fidelity:

→ No unlock

- Fragments retained

If reconstruction attempted too early:

→ Temporary misinformation penalty

- False readiness confidence
- Delayed warnings
- Repair misallocation

Never random death — only systemic misjudgment.

---

## Why This Mechanic Is Critical

It:

- Reinforces reconstruction-over-extermination.
- Makes information degradation a gameplay pillar.
- Deepens command vs field tension.
- Keeps progression terminal-native.
- Avoids arbitrary RPG stat creep.

Survival becomes tactical.
Progress becomes epistemic.

---

# 6. Field vs Command Tension

Currently:

Embodied presence exists mechanically.

But gameplay identity isn’t fully differentiated.

---

## Expand Distinction

### Field Layer

- Collects fragments
- Performs local repairs
- Faces risk
- Discovers incomplete information

### Command Layer

- Reconstructs knowledge
- Sets policy
- Allocates fabrication
- Manages power
- Interprets incomplete data

Make field dangerous but necessary.
Make command powerful but uncertain.

---

# 7. Campaign Identity — Deterministic but Replayable

Currently deterministic seeds exist.

Next step:

## Procedural Campaign Spine

Generate:

- Broad narrative arc
- Relay topology
- Assault pressure curve
- Resource strain pattern

No scripted story — but systemic variation.

Campaign types:

- Failing grid
- Siege lockdown
- Communications collapse
- Infrastructure starvation

Each seed shifts which systems are stressed.

Replayability comes from systemic variance, not random flavor text.

---

# 8. Balance & Pacing Pass (Required)

From roadmap items in :

Still open:

- Assault pacing refinement
- Long-run integration balance
- Snapshot/UI parity

Gameplay impact tasks:

- Adjust assault frequency curves
- Tune power-repair-defense multipliers
- Balance fabrication throughput ceilings
- Prevent permanent spiral-collapse states

---

# 9. Summary of Gameplay Priorities

Immediate mechanical upgrades:

1. Mid-assault tactical authority layer
2. Logistics visibility + strain model
3. Tiered fabrication materials
4. ARRN relay tier progression
5. Ghost Protocol Reconstruction system
6. Stronger command vs field differentiation
7. Campaign seed archetypes

---

# Final Vision

CUSTODIAN becomes:

Not a defense simulator.
Not a base builder.
Not a survival game.

It becomes:

A deterministic reconstruction strategy game where
information degradation is the primary adversary.

Survival is temporary.
Understanding is permanent.
