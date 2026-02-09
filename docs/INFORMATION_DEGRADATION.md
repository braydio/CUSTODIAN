These are **golden reference outputs**.
Codex should implement formatting so that **only wording changes**, never structure or ordering.

---

# STATUS OUTPUT — CANONICAL BY INFORMATION FIDELITY

> **Invariant rules (apply to all):**
>
> - ALL CAPS
> - Fixed section order
> - No advice
> - No interpretation outside what’s written
> - Omitted lines are intentional signal loss

---

## 1. INFO FIDELITY: **FULL**

```text
TIME: 18
THREAT: HIGH
ASSAULT: PENDING

SYSTEM POSTURE: FOCUSED (POWER)
ARCHIVE LOSSES: 1 / 3

SECTORS:
COMMAND: STABLE
COMMS: STABLE
POWER: DAMAGED
DEFENSE GRID: ALERT
ARCHIVE: STABLE
STORAGE: STABLE
HANGAR: STABLE
GATEWAY: STABLE
```

**Notes (for implementer, not player):**

- Precise assault state
- Exact archive count
- Exact posture target
- True sector statuses

---

## 2. INFO FIDELITY: **DEGRADED** (COMMS = ALERT)

```text
TIME: 18
THREAT: HIGH
ASSAULT: UNSTABLE

SYSTEM POSTURE: FOCUSED
ARCHIVE LOSSES: 1+

SECTORS:
COMMAND: STABLE
COMMS: ALERT
POWER: UNSTABLE
DEFENSE GRID: ALERT
ARCHIVE: STABLE
STORAGE: STABLE
HANGAR: STABLE
GATEWAY: STABLE
```

**Key degradations:**

- Assault state generalized
- Focus target hidden
- Archive count imprecise
- DAMAGED → UNSTABLE

---

## 3. INFO FIDELITY: **FRAGMENTED** (COMMS = DAMAGED)

```text
TIME: 18
THREAT: ELEVATED
ASSAULT: UNKNOWN

SYSTEM POSTURE: ACTIVE
ARCHIVE STATUS: DEGRADED

SECTORS:
COMMAND: ACTIVITY DETECTED
COMMS: DAMAGED
POWER: ACTIVITY DETECTED
DEFENSE GRID: ACTIVITY DETECTED
ARCHIVE: ACTIVITY DETECTED
STORAGE: STABLE
HANGAR: STABLE
GATEWAY: STABLE
```

**Key degradations:**

- Threat bucket softened
- Assault state lost
- Archive count removed entirely
- Sector certainty replaced with activity language

---

## 4. INFO FIDELITY: **LOST** (COMMS = COMPROMISED)

```text
TIME: ??
THREAT: UNKNOWN
ASSAULT: NO SIGNAL

ARCHIVE STATUS: NO SIGNAL

SECTORS:
COMMAND: NO DATA
COMMS: COMPROMISED
POWER: NO DATA
DEFENSE GRID: NO DATA
ARCHIVE: NO DATA
STORAGE: NO DATA
HANGAR: NO DATA
GATEWAY: NO DATA
```

**Critical points:**

- Time unreadable
- Posture omitted entirely
- Sector truth unavailable
- Only COMMS reports itself accurately (self-diagnosis)

---

# IMPLEMENTATION SAFETY CHECKLIST

Codex should verify:

- ✅ Section order identical across all fidelities
- ✅ Only wording changes, never structure
- ✅ No randomness in phrasing
- ✅ LOST omits posture line entirely
- ✅ Sector count never changes
- ✅ Internal state remains untouched

---

## Final design intent (one sentence)

> **The system does not get weaker — the operator gets blinder.**
