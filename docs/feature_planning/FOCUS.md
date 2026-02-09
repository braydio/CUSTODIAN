# CUSTODIAN — FOCUS COMMAND, EFFECTS, AND LOSS PROGRESSION

_(Phase 1.5 – Canonical Implementation Spec)_

**Scope:**
Introduce one player lever (`FOCUS`), integrate it into existing pressure + assault logic, and scaffold a deterministic loss condition.

**Non-Goals:**
No repairs, no resources, no upgrades, no hub persistence, no UI indicators.

---

## 0. Design Invariants (DO NOT VIOLATE)

1. `FOCUS` does **not**:
   - stop time
   - reduce global pressure
   - heal sectors
   - guarantee safety

2. `FOCUS`:
   - biases _where_ damage lands, not _whether_ it happens

3. Loss occurs because of **compound neglect**, not a single bad roll
4. The player can lose **without ever using FOCUS**
5. The game remains playable if FOCUS is ignored

---

## 1. State Additions (Minimal)

### 1.1 Add Focus State to GameState

**File:**
`game/simulations/world_state/core/state.py`

Add exactly one field:

```python
class GameState:
    ...
    focused_sector: Optional[str] = None  # sector.id
```

Rules:

- Stores sector ID only
- No counters
- No timestamps
- Cleared automatically after assault resolution

---

## 2. Command: FOCUS

### 2.1 Command Grammar

```
FOCUS <SECTOR_ID>
```

Examples:

```
FOCUS POWER
FOCUS DEFENSE
FOCUS ARCHIVE
```

---

### 2.2 Command Handler

**File:**
`game/simulations/world_state/terminal/commands/focus.py` (new)

#### Validation Rules

- Sector ID must exist
- Sector must not already be COMPROMISED
- Command does **not** advance time
- Command is always legal during CAMPAIGN_ACTIVE
- Command is ignored (with warning) if an assault is already resolving

---

### 2.3 Command Effect

```python
state.focused_sector = sector_id
```

Return text only:

```
[FOCUS SET] POWER
```

No additional lines. No feedback about consequences.

---

## 3. Integrating FOCUS into Existing Systems

FOCUS affects **two systems only**:

1. Assault damage targeting
2. Ambient decay selection (if present)

It does **not** change pressure values directly.

---

## 4. Assault Resolution Bias (Core Effect)

### 4.1 Where This Hooks In

Locate existing assault resolution logic, typically:

- `resolve_assault(...)`
- or wherever sector damage is selected/applied

There will already be logic like:

> choose N sectors to damage based on threat / assault strength

---

### 4.2 Modify Target Selection (Not Damage Severity)

Assume existing logic does something like:

```python
targets = random.sample(eligible_sectors, k)
```

Replace with **weighted selection**.

---

### 4.3 Weighting Rules

Let:

- `focused = state.focused_sector`
- `eligible_sectors = all non-COMPROMISED sectors`

Assign weights:

```python
for sector in eligible_sectors:
    if sector.id == focused:
        weight = 0.25      # protected, not immune
    else:
        weight = 1.0
```

Then normalize and sample.

**Important:**

- FOCUS does not remove sector from eligibility
- FOCUS only biases probability

---

### 4.4 After Assault Resolution

Immediately clear focus:

```python
state.focused_sector = None
```

This prevents “set and forget” play.

---

## 5. Ambient Decay Bias (Secondary Effect)

If you already have **ambient decay** (e.g. random sector degradation over time):

Apply the same weighting logic:

- Focused sector = reduced decay chance
- Others = slightly increased chance

If ambient decay does not exist yet:

- Do nothing here
- FOCUS still functions via assault bias alone

---

## 6. Sector Semantics (Already Locked In)

FOCUS gains meaning because sectors are asymmetric.

### 6.1 Required Sector Effects (Internal)

Ensure these effects already exist or are stubbed:

| Sector  | Effect if Damaged             |
| ------- | ----------------------------- |
| POWER   | pressure increases faster     |
| DEFENSE | assaults deal more damage     |
| COMMS   | fewer warnings before assault |
| STORAGE | decay elsewhere accelerates   |
| ARCHIVE | **loss counter increments**   |
| COMMAND | triggers failure              |

FOCUS interacts with these **indirectly** by steering damage.

---

## 7. Loss Condition (Scaffolded, Not Sudden)

### 7.1 Loss Is Not Instant (Except COMMAND)

The game should end via **one of two paths**:

---

### Path A — Immediate Failure (COMMAND)

If `COMMAND` sector becomes `COMPROMISED`:

```python
state.is_failed = True
state.failure_reason = "COMMAND CENTER LOST"
```

This already exists or should.

---

### Path B — Accumulated Irreversible Loss (ARCHIVE)

This is the **new scaffolded loss path**.

---

## 8. Archive Loss Progression (Critical)

### 8.1 Add Archive Integrity Counter

**File:**
`state.py`

```python
class GameState:
    ...
    archive_losses: int = 0
```

Rules:

- Increments when ARCHIVE transitions to DAMAGED or COMPROMISED
- Never decreases
- Does not reset unless full REBOOT

---

### 8.2 Increment Logic

When applying damage:

```python
if sector.id == "AR" and sector.status in {"DAMAGED", "COMPROMISED"}:
    state.archive_losses += 1
```

Only increment **once per assault**, not per tick.

---

### 8.3 Threshold-Based Failure

Define a fixed threshold (start conservative):

```python
ARCHIVE_LOSS_LIMIT = 3
```

After increment:

```python
if state.archive_losses >= ARCHIVE_LOSS_LIMIT:
    state.is_failed = True
    state.failure_reason = "ARCHIVAL INTEGRITY LOST"
```

---

## 9. Why This Loss Progression Is Correct

- The player can **see it coming**
- FOCUS can delay it, not prevent it
- Saving POWER or DEFENSE may doom ARCHIVE
- Saving ARCHIVE may doom COMMAND indirectly
- Loss feels **earned**, not random

This creates **strategic tragedy**, not surprise failure.

---

## 10. STATUS Integration (Minimal)

STATUS should already report:

- sector states
- failure reason when failed

Add **one line only** when archive losses exist:

```
ARCHIVE LOSSES: 2/3
```

Do not explain consequences.

---

## 11. UI Integration (NONE)

- No map highlight for focus
- No timers
- No reminders

The player must remember what they chose.

---

## 12. Testing Checklist (Codex Must Pass)

Codex implementation is correct if:

- FOCUS does not advance time
- Different FOCUS choices produce different damaged sectors
- FOCUS resets after assault
- Ignoring FOCUS is still viable (but riskier)
- ARCHIVE loss can end the game without COMMAND falling
- COMMAND loss still ends immediately
- No new UI dependencies were added

---

## 13. Logical Progression (What This Enables Later)

Without changing FOCUS:

- Phase 2 can add:
  - repairs
  - hub persistence
  - partial recovery

- ARCHIVE losses can later:
  - affect endings
  - affect hub unlocks

- FOCUS becomes:
  - a precursor to authority routing
  - a conceptual foundation for “command decisions”

Nothing here needs to be rewritten later.

---

## Final Lock Statement

This implementation:

- adds **agency without power**
- creates **meaningful regret**
- produces **two distinct failure paths**
- preserves Phase-1 constraints
- does not bloat scope

Once this is in:

> The game is no longer “a bunch of waits.”
> It is a sequence of **deliberate sacrifices**.

If you want next, I can:

- tune the weighting numbers conservatively,
- add a second soft lever that _conflicts_ with FOCUS,
- or spec the Phase-2 transition conditions.

This is the correct next move.
