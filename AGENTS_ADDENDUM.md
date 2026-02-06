Here is context for the next series of features. Agents should review this and identify the parts of the following that they are currently implementing. AS you implement said feature you should remove it from this file. This file should be gone by the time the features are all implemented. And be sure to be updating the _ai_context as you go. 

---

# Feature Descriptions:

Below is a **Phase-1 terminal contract** for the *first playable loop*. Once this is locked, implementation is straightforward and low-risk.

---

## Phase 1 Terminal Design (Locked Scope)

### Design goals

* Establish **player situational awareness**
* Preserve **uncertainty** (no omniscience)
* Keep output **operational and terse**
* Avoid leaking internal simulation mechanics

No lore. No flavor text beyond headers. No UI metaphors.

---

## Command 1: `STATUS` (read-only, always allowed)

### Purpose

Answer one question only:

> *“What is happening right now that I am responsible for?”*

Not:

* exact numbers everywhere
* prediction
* optimization hints

---

## `STATUS` Output Structure (locked)

```
TIME: <integer>
THREAT: <LOW | ELEVATED | HIGH | CRITICAL>
ASSAULT: <NONE | PENDING | ACTIVE>

SECTORS:
- <Sector Name>: <State>
- <Sector Name>: <State>
```

That’s it. No extra sections.

---

## Field definitions (important)

### TIME

* Integer tick count
* No units
* No “days” or “hours”

Why: reinforces *machine time*, not human time.

---

### THREAT (derived, not numeric)

Map internally, display discretely:

* `LOW`
* `ELEVATED`
* `HIGH`
* `CRITICAL`

Why:

* Prevents players from reverse-engineering formulas
* Leaves room for later mechanics (fog, misreads, interference)

---

### ASSAULT

One of:

* `NONE`
* `PENDING`
* `ACTIVE`

Rules:

* `PENDING` means an assault timer exists but hasn’t fired
* No countdown numbers in Phase 1
* Warnings come via events, not STATUS verbosity

---

### SECTORS (summary only)

Each sector reports **one word**, chosen from:

* `STABLE`
* `ALERT`
* `DAMAGED`
* `COMPROMISED`

**Mapping rule (locked):**

* This is derived from internal damage + alertness
* No numbers shown
* Worst condition wins

Why:

* Forces prioritization
* Keeps scanning fast
* Supports later misreporting mechanics

---

## Visibility rules (Phase 1)

* Player sees **all sectors**
* No hidden sectors
* No false data yet

(Deception, sensor loss, and partial visibility come later.)

---

## Tone & formatting rules (non-negotiable)

* All caps
* ASCII only
* No emojis
* No color codes
* Blank line between sections
* Output must be ≤ ~20 lines

The terminal should feel like a **status board**, not a console dump.

---

## Non-goals for `STATUS` (explicitly forbidden)

`STATUS` must NOT:

* Show raw damage values
* Show exact threat numbers
* Predict outcomes
* Recommend actions
* Mention internal mechanics (timers, thresholds)

If the player wants detail later, that’s a **different command**.

---

## Immediate follow-on commands (not designed yet)

Do **not** implement yet, but design assumes they exist later:

* `SECTORS` (detail view)
* `WAIT`
* `HELP`

`STATUS` should remain high-level forever.

---

## Final lock check

If implemented exactly as above, `STATUS` will:

* Be useful on tick 1
* Still be useful on tick 500
* Not collapse under added mechanics
* Train the player to read the system, not exploit it

