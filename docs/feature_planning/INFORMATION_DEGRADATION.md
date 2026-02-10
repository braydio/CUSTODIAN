
Below are **golden reference WAIT outputs**, one set per **information fidelity level**.

These are **authoritative examples** — Codex should match **structure, tone, and suppression rules**, not necessarily exact wording in every situation, but these define the *ceiling and floor* of information.

---

# WAIT OUTPUT — CANONICAL BY INFORMATION FIDELITY

> **Invariant rules (all levels):**
>
> * WAIT always advances time (even if unreadable)
> * Primary line always present (unless session terminated)
> * Zero advice
> * Max **one** interpretive line per WAIT
> * Silence is valid output

---

## 1. INFO FIDELITY: **FULL**

```text
TIME ADVANCED.

[EVENT] POWER DISTRIBUTION INSTABILITY DETECTED
[STATUS SHIFT] INTERNAL DAMAGE SPREADING
```

**Characteristics:**

* Precise subsystem named
* Explicit causal hint
* Status shift explains *trend*, not just event

Other valid FULL examples:

```text
TIME ADVANCED.

[WARNING] DEFENSE GRID UNDER ELEVATED LOAD
```

```text
TIME ADVANCED.

[ASSAULT] CONTACT IMMINENT
```

---

## 2. INFO FIDELITY: **DEGRADED** (COMMS = ALERT)

```text
TIME ADVANCED.

[EVENT] POWER FLUCTUATIONS REPORTED
[STATUS SHIFT] SYSTEM STABILITY DECLINING
```

**Degradations applied:**

* Still names system
* Removes confidence
* Shifts from “is happening” → “reported”

Other valid DEGRADED examples:

```text
TIME ADVANCED.

[WARNING] DEFENSIVE SYSTEMS STRAINED
```

```text
TIME ADVANCED.

[ASSAULT] THREAT ACTIVITY INCREASING
```

---

## 3. INFO FIDELITY: **FRAGMENTED** (COMMS = DAMAGED)

```text
TIME ADVANCED.

[EVENT] IRREGULAR SIGNALS DETECTED
[STATUS SHIFT] INTERNAL CONDITIONS UNSTABLE
```

**Degradations applied:**

* No subsystem names
* No directionality
* “Detected” replaces “confirmed”

Other valid FRAGMENTED examples:

```text
TIME ADVANCED.

[WARNING] STRUCTURAL STRESS INDICATED
```

```text
TIME ADVANCED.

[ASSAULT] HOSTILE MOVEMENT POSSIBLE
```

---

## 4. INFO FIDELITY: **LOST** (COMMS = COMPROMISED)

```text
TIME ADVANCED.
```

That’s it.

No brackets.
No hints.
No reassurance.

---

### Optional LOST variant (rare, 1-in-N ticks)

If you want a *very light* psychological hook without breaking rules:

```text
TIME ADVANCED.

[NO SIGNAL]
```

Use sparingly. Silence should dominate.

---

# WAIT 10X — SPECIAL CASE

WAIT 10X **never** prints per-tick lines.
It prints **at most one summary block**, fidelity-gated.

---

## WAIT 10X — FULL

```text
TIME ADVANCED x10.

[SUMMARY]
- THREAT ESCALATED
- 1 SECTOR DAMAGED
- ASSAULT STATUS CHANGED
```

---

## WAIT 10X — DEGRADED

```text
TIME ADVANCED x10.

[SUMMARY]
- SYSTEM STABILITY DECLINED
- MULTIPLE ALERTS RECORDED
```

---

## WAIT 10X — FRAGMENTED

```text
TIME ADVANCED x10.

[SUMMARY]
- CONDITIONS WORSENED
```

---

## WAIT 10X — LOST

```text
TIME ADVANCED x10.
```

---

# IMPLEMENTATION RULES (IMPORTANT)

Codex should enforce:

* ✅ **Never** show more information at lower fidelity
* ✅ If fidelity drops mid-WAIT 10X, use the **worst** fidelity reached
* ✅ STATUS after WAIT always reflects **true internal state**, even if unreadable
* ❌ No numeric values below FULL
* ❌ No subsystem names below DEGRADED

---

## Design intent (one sentence)

> **At high fidelity, WAIT explains risk.
> At low fidelity, WAIT *creates* it.**
