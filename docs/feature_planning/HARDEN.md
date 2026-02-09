
Below is a spec for a second lever that:

* directly conflicts with **FOCUS**
* does **not** add power
* does **not** add new systems
* creates *irreversible tension*
* scales naturally into Phase 2

This is intentionally minimal.

---

# CUSTODIAN — SOFT LEVER #2: **HARDEN**

*(Conflicts with FOCUS by trading spread for certainty)*

**Phase:** 1.5
**Scope:** One new command, one new transient state, no UI changes

---

## 0. Design Intent (Lock This First)

* **FOCUS** answers: *“What do I protect?”*
* **HARDEN** answers: *“How much damage do I accept?”*

They **cannot both be optimal at once**.

---

## 1. Conceptual Difference (Very Important)

| Lever  | Effect Shape                | Cost                        |
| ------ | --------------------------- | --------------------------- |
| FOCUS  | Biases *where* damage lands | Other sectors suffer        |
| HARDEN | Reduces *amount* of damage  | Damage becomes concentrated |

FOCUS spreads risk.
HARDEN compresses risk.

---

## 2. New Command: HARDEN

### 2.1 Command Grammar

```
HARDEN
```

No arguments. No targeting.

---

### 2.2 Availability Rules

* Legal only during `CAMPAIGN_ACTIVE`
* Cannot be used if an assault is already resolving
* Overrides any existing FOCUS
* Does **not** advance time

---

## 3. State Addition (Minimal)

**File:** `state.py`

```python
class GameState:
    ...
    hardened: bool = False
```

Rules:

* Boolean only
* Cleared automatically after assault resolution
* Cannot coexist with `focused_sector`

---

## 4. Command Handling

**File:** `terminal/commands/harden.py` (new)

### Effect

```python
state.hardened = True
state.focused_sector = None
```

Return:

```
[HARDENING SYSTEMS]
```

No additional feedback.

---

## 5. Assault Resolution Effects (Core Conflict)

This is where HARDEN directly conflicts with FOCUS.

---

### 5.1 Damage Quantity Modification

Assume existing logic determines:

```python
damage_events = N  # number of sectors hit
```

Modify as follows:

```python
if state.hardened:
    damage_events = max(1, N - 1)
```

Meaning:

* Fewer sectors are damaged
* But damage is **not spread**

---

### 5.2 Target Selection Modification

When selecting damage targets:

```python
if state.hardened:
    # pick from highest-risk sectors only
    eligible = [s for s in sectors if s.status != COMPROMISED]
    targets = choose_from_highest_risk(eligible)
```

Interpretation:

* Damage becomes **predictable but brutal**
* Already-weakened sectors are more likely to be hit again

---

### 5.3 Reset After Assault

After resolution:

```python
state.hardened = False
state.focused_sector = None
```

Both levers are one-shot.

---

## 6. Direct Conflict with FOCUS (Enforced)

### 6.1 Mutual Exclusivity

Rules enforced in command handling:

* Issuing `HARDEN` clears FOCUS
* Issuing `FOCUS` clears HARDEN

The last decision **wins**.

No stacking.
No mitigation.

---

## 7. How This Changes Player Decisions

Now before `WAIT`, the player must decide:

### Option A — FOCUS

* Protect one sector
* Accept wider damage
* Risk ARCHIVE/STORAGE losses

### Option B — HARDEN

* Reduce total damage
* Risk catastrophic collapse of a weak sector
* Especially dangerous if COMMAND or POWER is already damaged

### Option C — Do Nothing

* Accept pure randomness
* Often worst, sometimes safest

There is **no dominant strategy**.

---

## 8. Loss Progression Interaction (Critical)

### 8.1 HARDEN Makes ARCHIVE Loss Risky

If ARCHIVE is already DAMAGED:

* HARDEN increases likelihood it becomes COMPROMISED
* This accelerates `archive_losses`

FOCUS is safer for ARCHIVE.
HARDEN is safer for COMMAND *until it isn’t*.

---

### 8.2 HARDEN Can Trigger Instant Failure

If COMMAND is already DAMAGED:

* HARDEN can concentrate damage
* COMMAND may become COMPROMISED
* Immediate failure

This creates *visible danger* in STATUS.

---

## 9. STATUS Integration (Minimal)

Add exactly one optional line:

```
SYSTEM POSTURE: HARDENED
```

or

```
SYSTEM POSTURE: FOCUSED (POWER)
```

Do not explain effects.

---

## 10. Why HARDEN Is the Correct Soft Lever

* No new resources
* No progression
* No hidden math
* Conflicts cleanly with FOCUS
* Teaches risk compression vs diffusion
* Mirrors real command decisions

It feels *smart*, not *powerful*.

---

## 11. Testing Checklist (Codex Must Pass)

Implementation is correct if:

* HARDEN reduces number of damaged sectors
* Damage clusters more aggressively
* HARDEN + weak COMMAND can end the game
* HARDEN makes ARCHIVE losses more likely over time
* Player regret emerges from *choice*, not RNG
* Game still works if player never uses HARDEN

---

## 12. Why This Scales Later (Without Rewrite)

Later phases can:

* turn HARDEN into authority routing
* make HARDEN cost power
* let HUB upgrades modify HARDEN penalties

But **none of that is required now**.

---

## Final Lock Statement

With **FOCUS** and **HARDEN**, the player now chooses between:

> *“Who do I protect?”*
> *“How much damage can I survive?”*

Neither is correct.
Both are dangerous.
Doing nothing is worse.

At this point, the game loop is no longer passive.

If you want next, I can:

* tune exact weighting numbers conservatively,
* add a third lever that conflicts with **both**,
* or design the first Phase-2 authority evolution path.

This is the right complexity at the right time.
