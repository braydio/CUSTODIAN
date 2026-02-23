# `CORE_MECHANIC_GHOST_PROTOCOL.md`

Primary reference context:

---

# CORE MECHANIC — GHOST PROTOCOL RECOVERY

## Design Pillar

**Survival is tactical. Progress is epistemic.**

CUSTODIAN is not a game about extermination — it is about reconstruction.
The Ghost Protocol system formalizes information degradation as a mechanical layer rather than cosmetic flavor.

Every major operational event produces fragmented pre-collapse records. These fragments can be reconstructed into permanent knowledge unlocks that shape long-term strategic advantage.

This mechanic establishes:

- Information as currency
- Reconstruction as progression
- Command interpretation as gameplay
- Field action as evidence acquisition

---

# Core Concept

## Ghost Logs

Major operations generate **FRAGMENTS**:

- Assault resolutions
- Major repairs
- Relay stabilization
- Fabrication anomalies
- Power grid failures
- Infrastructure collapse events

Fragments represent corrupted pre-collapse telemetry:

- Sensor traces
- Maintenance records
- Routing maps
- Distress packets
- Defense calibration tables
- Communications buffers

Fragments are **not lore collectibles**.

They are mechanical assets.

---

# Gameplay Loop Integration

## Phase 1 — Fragment Acquisition (Field Layer)

During:

- Assault resolution ticks
- Major structural repairs
- Relay stabilization tasks
- Interception events
- High-load power anomalies

The system awards:

```
FRAGMENT +<DOMAIN> [FIDELITY X%]
```

Domains:

- POWER
- DEFENSE
- COMMS
- ARCHIVE

Fragment fidelity is influenced by:

- Current comms integrity
- Power stability
- Presence (Command vs Field)
- Assault severity
- Policy allocation (future integration point)

Fragments accumulate in a domain-specific pool.

---

## Phase 2 — Command Reconstruction (Command Layer)

Command issues:

```
SCAN GHOSTLOGS
RECONSTRUCT <DOMAIN>
STATUS KNOWLEDGE
```

Reconstruction attempts consume no fragments unless successful.

Outcome is deterministic.

Result depends on:

- Total fragment count
- Aggregate fidelity
- Prior unlock tier in that domain

---

# Reconstruction Outcomes

## 1. Correct Reconstruction

Unlocks permanent systemic improvement.

Examples:

### POWER Domain

- Reduced brownout penalty curve
- Earlier overload warning
- Improved repair efficiency scaling

### DEFENSE Domain

- Earlier assault lead-time detection
- Slight turret efficiency increase
- Reduced ammo waste during interception

### COMMS Domain

- Increased STATUS certainty
- Reduced relay drift
- Improved fragment fidelity acquisition

### ARCHIVE Domain

- New terminal commands
- Historical event insights
- Assault pattern forecasting

Unlocks are:

- Deterministic
- Persistent
- Non-random
- Non-stackable beyond tier cap

---

## 2. Incomplete Reconstruction

No unlock.
Fragments retained.

Feedback indicates insufficient fidelity threshold.

No punishment.

Encourages patience and operational stability.

---

## 3. Incorrect Reconstruction (Low Fidelity)

If attempted below safe threshold:

- Temporary misinformation penalty
- Not random failure
- Not arbitrary death

Examples:

- STATUS uncertainty increases
- Power estimates slightly skewed
- Assault ETA estimation variance widens
- Fabrication throughput temporarily misreported

Penalty duration:

- 1–3 ticks
- Self-correcting
- Transparent in post-action log

This reinforces epistemic caution.

---

# Determinism & Fairness

The system must:

- Be fully seeded
- Never roll hidden RNG
- Be fidelity-threshold driven
- Be reproducible under snapshot reload

Reconstruction results must be:

- Computable from state
- Visible in debug report
- Logged in assault ledger

---

# Terminal Surface (Minimal)

Required commands:

```
SCAN GHOSTLOGS
  → Lists domains
  → Shows fragment count
  → Shows aggregate fidelity
  → Shows next threshold

RECONSTRUCT <DOMAIN>
  → Attempts reconstruction
  → Returns outcome message

STATUS KNOWLEDGE
  → Lists unlocked knowledge tiers
  → Lists temporary misinformation flags
```

No GUI dependency required.

Fully terminal-native.

---

# Knowledge Model

Each domain contains tiered unlocks.

Example structure:

```
POWER:
  Tier 1 – Grid Recovery Optimization
  Tier 2 – Brownout Dampening Curve
  Tier 3 – Predictive Surge Buffering
```

Unlock logic:

- Requires X fragments
- Requires Y average fidelity
- Higher tiers require prior unlock

No randomness.

No branching tree.

Linear domain tiers for clarity.

---

# Integration Points (Existing Systems)

Ghost Protocol should integrate with:

- Assault system (`assaults.py`)
- Power system (`power.py`)
- Relay system (`relays.py`)
- Fabrication (`fabrication.py`)
- Policy layer (`policies.py`)
- STATUS output certainty
- After-action reporting

It should not require architectural rewrites.

Hooks can be inserted:

- After assault resolution
- After repair tick
- After relay stabilization
- On power overload event

---

# Why This Fits CUSTODIAN

1. Reinforces reconstruction-over-extermination
2. Deepens Command vs Field tension
3. Makes degraded information mechanical
4. Adds long-term campaign spine
5. Remains deterministic
6. Remains terminal-first
7. Expands ARRN relay meaning
8. Adds strategic pacing without complexity explosion

---

# Minimal Viable Implementation (Phase 1)

### Add to GameState:

```
ghost_fragments: {
  "POWER": { count, total_fidelity },
  "DEFENSE": { count, total_fidelity },
  "COMMS": { count, total_fidelity },
  "ARCHIVE": { count, total_fidelity }
}

knowledge_unlocks: {
  "POWER": tier,
  "DEFENSE": tier,
  "COMMS": tier,
  "ARCHIVE": tier
}

misinformation_flags: {
  domain: ticks_remaining
}
```

### Add hooks:

- Award fragments in assault resolution
- Award fragments in relay stabilize
- Award fragments in major repair completion

### Add commands:

- SCAN GHOSTLOGS
- RECONSTRUCT <DOMAIN>
- STATUS KNOWLEDGE

### Add deterministic threshold table

Hard-coded at first.

---

# Expansion Paths (Future)

- Policy affects fidelity gain
- Relay synchronization boosts reconstruction
- Fragment decay over long idle periods
- Domain cross-influence
- Campaign-level arc unlocks
- Historical pattern forecasting
- Procedural event description integration

---

# System Philosophy

The player does not win by killing faster.

The player wins by understanding better.

Assault survival keeps you alive.

Ghost Protocol makes you evolve.

---

# Strategic Outcome

This mechanic:

- Adds a long-term progression spine
- Keeps runtime deterministic
- Enhances command decision weight
- Converts information degradation into gameplay
- Avoids RPG-stat bloat
- Preserves terminal tone

It is a pillar mechanic, not a feature.

It belongs in core architecture.
