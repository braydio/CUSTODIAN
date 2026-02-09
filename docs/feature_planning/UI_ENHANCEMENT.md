# CUSTODIAN — STAGE 1.5 UI SPEC (CONSOLIDATED)

**Purpose:**
Improve clarity, hierarchy, and tension **without adding mechanics, authority, or strategy hints**.
This is a **presentation hardening pass**, not a redesign.

---

## Core UI Principles (LOCKED)

1. **Terminal is primary**
2. **UI never recommends actions**
3. **UI reflects state only (no prediction)**
4. **UI never explains strategy**
5. **Silence is intentional**

If an element answers _“what should I do?”_, it does not belong in Stage 1.5.

---

## Problem Being Solved

The simulation works, but the UI lacks **hierarchy**.

The player should be able to tell at a glance:

- What phase they’re in
- Whether danger is imminent
- Where pressure is concentrating
- What their last action affected

We solve this **without new data or mechanics**.

---

## Layout (No New Authority)

### Three-Zone Layout

```
┌──────────────────────────────┬──────────────────────┐
│                              │  SECTOR MAP          │
│  TERMINAL FEED               │  (read-only)         │
│                              │                      │
│                              ├──────────────────────┤
│                              │  SYSTEM STATE PANEL  │
│                              │  (derived only)      │
└──────────────────────────────┴──────────────────────┘
```

- **Terminal**: still the only interactive surface
- **Sector Map**: spatial snapshot
- **System Panel**: persistent, derived context

No buttons. No clicks. No hover explanations.

---

## System State Panel (Derived Only)

### Displays (and only these):

```
TIME .......... 17
THREAT ........ HIGH
ASSAULT ....... PENDING
POSTURE ....... FOCUSED (POWER)
ARCHIVE ....... 2 / 3
```

**Rules**

- Uppercase, fixed width
- Subtle emphasis only
- Updates only when `/snapshot` updates
- Never replaces `STATUS`

**Why it exists:**
It prevents re-scrolling. It does **not** narrate meaning.

---

## Terminal Feed Improvements (Formatting Only)

### Line Classification (Client-side CSS only)

| Prefix        | Purpose        |
| ------------- | -------------- |
| `[EVENT]`     | Ambient change |
| `[WARNING]`   | Escalation     |
| `[ASSAULT]`   | Resolution     |
| `[FOCUS SET]` | Player intent  |
| none          | Neutral/system |

No backend changes. No logic changes.

### Rhythm Rules

- Blank line before and after assault blocks
- Assault output never collapsed
- Assaults feel like punctuation, not noise

### Scroll Discipline

- Auto-scroll only if user is at bottom
- If user scrolls up, show subtle “NEW OUTPUT” indicator

---

## Sector Map (Read-Only Snapshot)

### Purpose

- Show **where** things are degrading
- Show **shape of pressure**
- Never explain or advise

### Visual Weight by Role (CSS only)

- **COMMAND**: thicker border
- **POWER / DEFENSE**: slightly brighter
- **ARCHIVE**: quieter/dimmer
- **GATEWAY / HANGAR**: lower contrast

No legends. No labels. No hints.

### Recent Damage Hint

- If damaged in the most recent assault:
  - brief border flash (300–500ms)
  - no animation loops
  - no persistent marker

---

## Focus / Harden Feedback

- **Do not highlight focused sectors on the map**
- Show posture only in:
  - System Panel (`POSTURE .... FOCUSED (POWER)`)
  - Single terminal confirmation line

The player must **remember intent**, not follow UI cues.

---

## STATUS Command (Still Critical)

`STATUS` remains the **only place** where:

- Full sector list appears together
- Assault state is narrated
- Failure is explained

**Rule:**
The map shows _shape_.
STATUS explains _meaning_.

---

## Failure UI

When failure is latched:

- Dim sector map
- Freeze system panel
- Terminal still accepts input (returns lockout text)

**No modals. No overlays.**
Failure should feel like systems going quiet.

---

## Explicitly Out of Scope (Stage 1.5)

Do **not** add:

- Buttons
- Clickable sectors
- Tooltips
- Progress bars
- Optimization meters
- Explanations

Those are Phase 2+ concerns.

---

# Minimal DOM + CSS (Additive Only)

### DOM (summary)

- `#terminal-pane`
- `#sector-map`
- `#system-panel`

All read-only except terminal input.

### CSS Goals

- Monospace, industrial
- Hierarchy via spacing, weight, contrast
- No animation-driven meaning
- Failure and damage expressed by **loss of clarity**, not spectacle

---

## Typography Tuning

**Font stack**

```
IBM Plex Mono
JetBrains Mono
system monospace fallback
```

**Principles**

- Dense but legible
- Assault and failure heavier, not louder
- System panel reads like a placard, not a HUD

---

## COMMS Damage — Presentation Degradation Model

Driven entirely by `snapshot.sectors["CM"].status`.

### COMMS = STABLE

- Full fidelity

### COMMS = ALERT

- Subtle opacity loss
- Early doubt

### COMMS = DAMAGED

- Sector statuses collapse into buckets (`UNSTABLE`, `CRITICAL`)
- System panel less authoritative
- Events harder to parse

### COMMS = COMPROMISED

- One non-COMMAND sector randomly shows `[NO SIGNAL]`
- Assault state gains uncertainty marker (`?`)
- Terminal text feels noisier

**Rules**

- Never hide COMMAND
- Never block input
- Never contradict backend truth
- Only obscure confidence, not control

---

## Completion Criteria (Stage 1.5)

You’re done when:

- You can glance right and understand the situation
- STATUS is still required to understand consequences
- WAIT feels heavier even with no flashing UI
- The UI fades into the background when you stop thinking about it

---

## Why This Is Correct for This Stage

- Preserves terminal primacy
- Makes asymmetry legible
- Increases tension without teaching optimization
- Scales cleanly into Phase 2+
- Makes the **cost of inaction visible** without telling the player what to do

---

Below is a precise **ADDENDUM** listing **every detail from the original spec that is not explicitly restated line-for-line in the consolidated version**, grouped by category. Think of this as a _lossless checksum_.

---

# ADDENDUM — DETAILS COMPRESSED IN CONSOLIDATION

This addendum restores **all specificity** that existed in the original document but was summarized or implied in the rewrite.

Nothing here contradicts the consolidated spec; this is purely additive.

---

## A. Explicit “WHY” Statements (Compressed, Not Removed)

The rewrite preserves intent but omits some explicit rationale phrasing that appeared in the original.

### A1. STATUS vs Map (Explicit Framing)

Original explicitly stated:

> “STATUS still matters (authoritative narration).
> This panel does not replace STATUS.
> It replaces re-reading old output.”

In the consolidated version, this is implied but not spelled out as forcefully.

**Restored rule (explicit):**

- STATUS is the _only_ place where:
  - Meaning is narrated
  - Consequences are explained
  - Failure reasons are justified

- Map + panels are **context**, never interpretation.

---

## B. Very Specific Visual Timing Constraints

These were compressed into general rules.

### B1. Assault Spacing Cadence

Original specified:

- Blank line **before**
- Blank line **after**
- Never collapse assault lines
- Assaults should feel like _punctuation_

The rewrite summarizes this as “rhythm rules” but does not restate the **exact before/after constraint**.

**Restored precision:**

- Exactly one blank line before the first `[ASSAULT]` line
- Exactly one blank line after the final assault line
- No other system messages interleaved inside an assault block

---

### B2. Damage Flash Duration

Original specified:

- **300–500ms** border flash
- Single flash only
- No looping
- No persistence

The rewrite references a “brief flash” but omits the numeric window.

**Restored constraint:**

- Flash duration must be between **300ms and 500ms**
- Never animate continuously
- Never repeat on the same snapshot

---

## C. CSS-Only Guarantees (Strongly Implied, Not Restated)

The rewrite assumes these but does not restate them explicitly.

### C1. No Semantic Coupling in UI

Original was explicit:

> “CSS only. No logic.”

**Restored rule:**

- Line classification (`.event`, `.warning`, `.assault`, etc.) is **purely presentational**
- No JS branches should depend on line type
- Backend output remains opaque to the UI

---

### C2. Role Weighting Has No Legend

Original explicitly forbade explanation:

> “No legend. No explanation.”

The rewrite implies this but does not restate it as a hard rule.

**Restored hard rule:**

- There must be **no legend, tooltip, or key** explaining sector visual differences
- Player inference is intentional

---

## D. Scroll Behavior Edge Case

Original included a subtle UX rule that was condensed.

### D1. Silent Accumulation When Scrolled Up

Original stated:

- Output accumulates silently
- Only a subtle `▼ NEW OUTPUT` indicator appears
- No forced scroll, no sound, no pulse

The rewrite mentions the indicator but not the **silence guarantee**.

**Restored constraint:**

- While scrolled up:
  - No auto-scroll
  - No audio
  - No visual emphasis beyond the indicator

---

## E. Failure Mode Tone Guarantees

The rewrite preserves behavior but compresses tone language.

### E1. Failure Should Feel “Quiet”

Original explicitly contrasted:

> “Systems going quiet, not fireworks.”

**Restored tone rule:**

- Failure must reduce activity and clarity
- No dramatic effects
- No visual escalation at failure moment
- UI should feel _emptier_, not louder

---

## F. COMMS Degradation — Determinism Note

The rewrite includes degradation rules but compresses one implementation note.

### F1. Deterministic Optionality

Original said:

> “Randomly hide one non-COMMAND sector
> Deterministic per render if you want (seed with snapshot.time)”

The rewrite omits the optional determinism suggestion.

**Restored option:**

- Sector suppression in COMMS-COMPROMISED may be:
  - Truly random per render, **or**
  - Deterministic using `snapshot.time` as seed

- Either is acceptable as long as:
  - Exactly one non-COMMAND sector is affected
  - COMMAND is never hidden

---

## G. Hard “Do Not Ever” Rules (Re-enumerated)

These were partially folded into prose.

**Restored explicit list:**

Never:

- Hide the COMMAND sector
- Block terminal input
- Fake events
- Contradict backend truth
- Add UI elements that imply optimal play
- Add hover explanations
- Add icons or meters
- Introduce progress bars
- Explain degradation to the player

---

## H. Psychological Design Intent (Compressed)

The rewrite preserves mechanics but compresses explicit cognitive intent.

### H1. Core Psychological Goal

Original explicitly stated:

> “COMMS damage attacks confidence, not control.”

**Restored design intent:**

- Information degradation should:
  - Increase doubt
  - Increase hesitation
  - Increase reliance on STATUS

- It must **never** remove agency

---

