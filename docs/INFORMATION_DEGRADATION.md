# INFORMATION DEGRADATION (Canonical)

This document is the **single source of truth** for information degradation in CUSTODIAN.
It consolidates the prior feature planning specs for:
- WAIT/WAIT NX output
- STATUS output
- STATUS ↔ WAIT parity rules

It is authoritative. Follow the structure, ordering, and suppression rules exactly.

---

## 0. Scope & Separation

This specification applies only to:
- `WAIT`
- `WAIT NX`
- `STATUS`

Separation rules:
- `STATUS` is **filtered truth**. It never lies.
- `WAIT` is **filtered inference**. At low fidelity, it may be wrong, but must remain plausible and internally consistent.
- Fidelity applies per command at the moment output is generated.

---

## 1. STATUS ↔ WAIT Alignment Principles (Locked)

1. **STATUS is filtered truth, WAIT is filtered inference.**
   - STATUS never lies, only withholds or generalizes.
   - WAIT may be wrong at low fidelity, but must never contradict player-local sensory reality directly.

2. **STATUS certainty is always >= WAIT certainty.**
   - WAIT must never reveal information that STATUS would suppress at the same fidelity.

3. **Fidelity applies uniformly per command.**
   - STATUS uses current fidelity.
   - WAIT uses fidelity at output time.

4. **STATUS never implies trend.**
   - No momentum language in STATUS. Trend language is WAIT-only.

---

## 2. Fidelity Levels

Fidelity is derived from COMMS state:

```
FULL > DEGRADED > FRAGMENTED > LOST
```

---

# STATUS OUTPUT — CANONICAL BY INFORMATION FIDELITY

STATUS presents a **filtered snapshot of the true internal state**.
It never advances time, never lies, and never implies trends.

## Global STATUS Invariants (All Fidelities)

- ALL CAPS
- Fixed section order
- No advice
- No interpretation
- No trend language
- Omitted lines represent information loss, not absence
- Sector list count never changes
- Repair progress fidelity:
  - FULL: exact progress and cost
  - DEGRADED: approximate progress, cost shown
  - FRAGMENTED (severe): vague but present, cost shown

## STATUS Section Order (Fixed)

1. TIME
2. THREAT
3. ASSAULT
4. SYSTEM POSTURE (if available)
5. ARCHIVE STATUS / LOSSES (if available)
6. RESOURCES
7. REPAIRS (if available)
8. SECTORS

## 1. INFO FIDELITY: FULL

```
TIME: 18
THREAT: HIGH
ASSAULT: PENDING

SYSTEM POSTURE: FOCUSED (POWER)
ARCHIVE LOSSES: 1 / 3

RESOURCES:
- MATERIALS: 2

REPAIRS:
- CC_CORE COMMAND CORE: 1/2 TICKS (COST: 1 MATERIALS)

SECTORS:
COMMAND: STABLE
COMMS: STABLE
POWER: DAMAGED
FABRICATION: STABLE
DEFENSE GRID: ALERT
ARCHIVE: STABLE
STORAGE: STABLE
HANGAR: STABLE
GATEWAY: STABLE
```

Rules:
- Exact values allowed
- Exact counts allowed
- Exact sector states allowed
- No interpretation of why

## 2. INFO FIDELITY: DEGRADED (COMMS = ALERT)

```
TIME: 18
THREAT: HIGH
ASSAULT: UNSTABLE

SYSTEM POSTURE: FOCUSED
ARCHIVE LOSSES: 1+

RESOURCES:
- MATERIALS: 2

REPAIRS:
- CC_CORE: MID PROGRESS (COST: 1 MATERIALS)

SECTORS:
COMMAND: STABLE
COMMS: ALERT
POWER: UNSTABLE
FABRICATION: STABLE
DEFENSE GRID: ALERT
ARCHIVE: STABLE
STORAGE: STABLE
HANGAR: STABLE
GATEWAY: STABLE
```

Degradations:
- Assault state generalized
- Posture target removed
- Archive losses imprecise
- DAMAGED → UNSTABLE
- No trend or momentum implied

## 3. INFO FIDELITY: FRAGMENTED (COMMS = DAMAGED)

```
TIME: 18
THREAT: ELEVATED
ASSAULT: UNKNOWN

SYSTEM POSTURE: ACTIVE
ARCHIVE STATUS: DEGRADED

RESOURCES:
- MATERIALS: 2

REPAIRS: ACTIVE
- CC_CORE: IN PROGRESS (COST: 1 MATERIALS)

SECTORS:
COMMAND: ACTIVITY DETECTED
COMMS: DAMAGED
POWER: ACTIVITY DETECTED
FABRICATION: ACTIVITY DETECTED
DEFENSE GRID: ACTIVITY DETECTED
ARCHIVE: ACTIVITY DETECTED
STORAGE: STABLE
HANGAR: STABLE
GATEWAY: STABLE
```

Rules:
- No assault confirmation
- No archive counts
- No exact sector states (except COMMS self-report)
- ACTIVITY DETECTED replaces certainty
- No trend language

## 4. INFO FIDELITY: LOST (COMMS = COMPROMISED)

```
TIME: ??
THREAT: UNKNOWN
ASSAULT: NO SIGNAL

ARCHIVE STATUS: NO SIGNAL

RESOURCES:
- MATERIALS: 2

SECTORS:
COMMAND: NO DATA
COMMS: COMPROMISED
POWER: NO DATA
FABRICATION: NO DATA
DEFENSE GRID: NO DATA
ARCHIVE: NO DATA
STORAGE: NO DATA
HANGAR: NO DATA
GATEWAY: NO DATA
```

Rules:
- TIME unreadable
- THREAT unreadable
- ASSAULT unreadable
- Posture omitted entirely
- Only COMMS may self-report
- No implication of safety or danger

---

# WAIT OUTPUT — CANONICAL BY INFORMATION FIDELITY

WAIT advances time and returns filtered inference.
It may be wrong at low fidelity but must remain plausible and internally consistent.

## 1. Global WAIT Invariants (All Fidelities)

- WAIT always advances time
- Primary line always present unless session terminated
- Primary line is exactly:
  - `TIME ADVANCED.`
  - `TIME ADVANCED xN.`
- Output order is fixed:
  1. Primary line
  2. Optional detail lines
- No advice
- No reassurance
- No questions
- No narration
- At most one interpretive line per WAIT
- Silence (primary line only) is valid **only if nothing meaningful occurred**

## 2. Line Types (Formal)

### Event Line (Non-Interpretive)

Describes a detected occurrence.

Examples:
- `[EVENT] POWER FLUCTUATION DETECTED`
- `[WARNING] DEFENSIVE LOAD SPIKE`

### Interpretive Line (Strictly Limited)

Describes inferred trend or implication.

Examples:
- `[STATUS SHIFT] SYSTEM STABILITY DECLINING`
- `[ASSAULT] THREAT ACTIVITY INCREASING`

Rule:
- Only one interpretive line may appear per WAIT.

## 3. Ordering Rules

If multiple lines are emitted:
1. Event or Warning line(s) first
2. Interpretive line last (if any)

Status shifts are optional and should generally be downstream of an event or warning.

## 4. Fidelity-Specific Output Rules

### FULL

Characteristics:
- Subsystem names allowed
- Directional verbs allowed
- Causal hints allowed
- No numeric values

Example:
```
TIME ADVANCED.

[EVENT] POWER DISTRIBUTION INSTABILITY DETECTED
[STATUS SHIFT] INTERNAL DAMAGE SPREADING
```

### DEGRADED (COMMS = ALERT)

Degradations:
- Confidence reduced
- Directional verbs hedged
- Causality softened

Example:
```
TIME ADVANCED.

[EVENT] POWER FLUCTUATIONS REPORTED
[STATUS SHIFT] SYSTEM STABILITY APPEARS TO BE DECLINING
```

### FRAGMENTED (COMMS = DAMAGED)

Degradations:
- No subsystem names
- Directionality inferred, not asserted
- Assaults only implied after detectable hostile effects

Example:
```
TIME ADVANCED.

[EVENT] IRREGULAR SIGNALS DETECTED
[STATUS SHIFT] INTERNAL CONDITIONS MAY BE WORSENING
```

### LOST (COMMS = COMPROMISED)

Rules:
- No detail lines
- No brackets
- No interpretation
- Output may be wrong
- Output reflects system belief, not player senses

Example:
```
TIME ADVANCED.
```

Optional (rare):
```
TIME ADVANCED.

[NO SIGNAL]
```

## 5. Assault Signaling Rules

- FULL and DEGRADED may name assaults before contact.
- FRAGMENTED may imply assaults only after detectable hostile effects.
- LOST has no assault concept.

## 6. Directional Verb Rules

- FULL: explicit directionality allowed.
- DEGRADED: directional verbs must be hedged (e.g., "APPEARS TO BE ESCALATING").
- FRAGMENTED: directional verbs must be hedged and uncertain (e.g., "MAY BE WORSENING").
- LOST: no directionality.

## 7. WAIT NX — Aggregation Rules

- No per-tick output
- Always emits a summary block unless LOST
- Fidelity used is the worst reached during the interval

### WAIT NX — FULL

```
TIME ADVANCED xN.

[SUMMARY]
- THREAT ESCALATED
- HOSTILE COUNT INCREASED
- ASSAULT STATUS CHANGED
```

### WAIT NX — DEGRADED

```
TIME ADVANCED xN.

[SUMMARY]
- SYSTEM STABILITY DECLINED
- HOSTILE ACTIVITY INCREASED
```

### WAIT NX — FRAGMENTED

```
TIME ADVANCED xN.

[SUMMARY]
- CONDITIONS MAY HAVE WORSENED
```

### WAIT NX — LOST

```
TIME ADVANCED xN.
```

## 8. Absolute Prohibitions

WAIT must never:
- Emit advice
- Emit reassurance
- Emit more than one interpretive line
- Emit subsystem names below DEGRADED
- Emit numeric values below FULL
- Emit sector identities in summaries
- Contradict player-local sensory reality directly

---

## Design Intent (Final Lock)

STATUS preserves truth under loss.
WAIT communicates risk under loss.
The system degrades, not the player’s agency.
