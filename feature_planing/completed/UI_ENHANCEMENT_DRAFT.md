
Below is a **stage-appropriate UI spec** that improves clarity, tension, and readability **without violating a single architectural constraint** you’ve locked.

This is **not a redesign**.
It is a **presentation hardening pass**.

---

# CUSTODIAN — STAGE 1.5 UI IMPROVEMENT SPEC

*(Terminal-first, map-secondary, zero new authority)*

## UI Design Principles (LOCK THESE)

1. **Terminal is still the primary interface**
2. **UI never explains strategy**
3. **UI never recommends actions**
4. **UI reflects state, never predicts it**
5. **Silence is a tool** — don’t fill space

If a UI element answers *“what should I do?”*, it’s wrong.

---

## 1. Problem Diagnosis (Current UI)

Right now you have:

* A scrolling, mostly unstructured text feed
* A sector map that works but doesn’t *frame attention*
* STATUS output that’s correct but visually flat

What’s missing is **hierarchy**, not features.

The player needs to be able to answer, at a glance:

1. *What phase am I in?*
2. *Is something about to happen?*
3. *Where is the danger concentrating?*
4. *What choice did I last make?*

We’ll solve all four **without adding mechanics**.

---

## 2. UI Layout Upgrade (No New Data)

### 2.1 Split the Screen into 3 Zones

**Left (Primary): Terminal Feed**
**Right-Top: Sector Map**
**Right-Bottom: System Readouts**

This keeps the terminal dominant but stops it from doing *everything*.

```
┌──────────────────────────────┬──────────────────────┐
│                              │  SECTOR MAP          │
│  TERMINAL FEED               │  (read-only)         │
│                              │                      │
│                              ├──────────────────────┤
│                              │  SYSTEM STATE        │
│                              │  (derived only)      │
└──────────────────────────────┴──────────────────────┘
```

No interactivity outside the terminal input.

---

## 3. System State Panel (Derived, Not New State)

This is the **single biggest clarity win**.

### 3.1 What Goes Here (ONLY THESE)

Pulled from `snapshot()` and existing command results:

```
TIME .......... 17
THREAT ........ HIGH
ASSAULT ....... PENDING
POSTURE ....... FOCUSED (POWER)
ARCHIVE LOSSES  2 / 3
```

Rules:

* Uppercase
* Fixed-width alignment
* No colors beyond subtle emphasis
* Updates only when `/snapshot` updates

### 3.2 Why This Works

* Player no longer needs to scroll for context
* STATUS still matters (authoritative narration)
* This panel is a **persistent mental anchor**

Importantly:

> This panel **does not replace STATUS**
> It replaces *re-reading old output*

---

## 4. Terminal Feed Improvements (Pure Formatting)

### 4.1 Message Typing (Visual, Not Semantic)

Without changing backend output, classify lines client-side by prefix:

| Prefix        | Class   | Meaning           |
| ------------- | ------- | ----------------- |
| `[EVENT]`     | event   | ambient change    |
| `[WARNING]`   | warning | escalating danger |
| `[ASSAULT]`   | assault | resolution lines  |
| `[FOCUS SET]` | action  | player decision   |
| system text   | system  | neutral           |

CSS only. No logic.

---

### 4.2 Vertical Rhythm Rules

* **Blank line before assault blocks**
* **Blank line after assault blocks**
* Never collapse assault lines together

This makes assaults feel like *punctuation*, not noise.

---

### 4.3 Terminal Scroll Discipline

* Auto-scroll **only if** user is at bottom
* If user scrolls up:

  * new output accumulates silently
  * show a subtle `▼ NEW OUTPUT` indicator

This preserves immersion and prevents panic scrolling.

---

## 5. Sector Map Enhancements (Still Read-Only)

The map works — now make it *communicate asymmetry*.

### 5.1 Visual Weight by Sector Role

Without adding icons or text:

* COMMAND: slightly thicker border
* POWER / DEFENSE: slightly brighter labels
* ARCHIVE: dimmer, quieter
* GATEWAY / HANGAR: lower contrast but “edgy”

This is **pure CSS** based on sector ID.

No legend. No explanation.

---

### 5.2 Damage History Hint (Very Subtle)

If a sector was damaged in the **most recent assault**:

* briefly (300–500ms) flash border on update
* no animation loop
* no persistent marker

This answers: *“What just happened?”*
Without replaying text.

---

## 6. Focus / Harden Feedback (Cognitive, Not Visual)

Do **not** highlight focused sectors on the map.

Instead:

* System State panel shows:

  * `POSTURE ....... FOCUSED (POWER)`
  * or `POSTURE ....... HARDENED`
* Terminal shows confirmation line only

This forces the player to **remember intent**, not follow UI hints.

That’s intentional.

---

## 7. STATUS Still Matters (Do Not Undercut It)

STATUS remains the **only place** where:

* full sector list appears together
* assault state is narrated
* failure reason is explained

UI panels never show *explanations*.

STATUS is where *meaning* lives.

---

## 8. Failure UI (When It Happens)

When failure is latched:

### 8.1 Visual Lock

* Dim the sector map
* Freeze system state panel
* Terminal accepts input but returns lockout text

### 8.2 No Modal, No Overlay

Do not pop dialogs.
Do not block the screen.

Failure should feel like **systems going quiet**, not fireworks.

---

## 9. What You Explicitly Do NOT Add Yet

Do not add:

* buttons
* clickable sectors
* hover tooltips
* explanations
* progress bars
* meters that imply optimization

Those come later — after the player understands loss.

---

## 10. Minimal Implementation Checklist

You’re done when:

* You can glance right and know the situation
* You still need STATUS to understand consequences
* Assaults *feel heavier* without new mechanics
* You hesitate before WAIT even when nothing is flashing
* The UI disappears when you stop thinking about it

---

## 11. Why This Is the Right UI for This Stage

This UI:

* respects terminal primacy
* makes asymmetry legible
* preserves tension
* does not teach the player how to win
* scales cleanly into Phase 2+

Most importantly:

> It makes the *cost of inaction visible*
> without ever telling the player what to do.

---

Here is an **exact, minimal DOM + CSS spec** you can drop in **without touching backend logic**.

Everything below assumes your existing files (`index.html`, `terminal.js`, `sector-map.js`) stay intact, with only **additive markup + CSS**.

---

# CUSTODIAN — MINIMAL UI DOM + CSS SPEC (PHASE 1.5)

## Design Constraints (Reaffirmed)

* Terminal remains primary
* No clickable UI outside terminal
* No icons, no meters, no tooltips
* No explanations
* Everything derived from existing state (`/command`, `/snapshot`)

---

## 1. Minimal DOM Structure

### 1.1 `index.html` — Canonical Layout

Replace your body content (or wrap existing terminal) with:

```html
<body>
  <div id="app">

    <!-- LEFT: TERMINAL -->
    <div id="terminal-pane">
      <div id="terminal-output"></div>
      <div id="terminal-input">
        <span class="prompt">&gt;</span>
        <input id="command-input" autocomplete="off" />
      </div>
    </div>

    <!-- RIGHT: STATUS + MAP -->
    <div id="side-pane">

      <!-- SYSTEM STATE -->
      <div id="system-panel">
        <div class="sys-line"><span class="label">TIME</span><span id="sys-time">--</span></div>
        <div class="sys-line"><span class="label">THREAT</span><span id="sys-threat">--</span></div>
        <div class="sys-line"><span class="label">ASSAULT</span><span id="sys-assault">--</span></div>
        <div class="sys-line"><span class="label">POSTURE</span><span id="sys-posture">--</span></div>
        <div class="sys-line"><span class="label">ARCHIVE</span><span id="sys-archive">--</span></div>
      </div>

      <!-- SECTOR MAP -->
      <div id="sector-map"></div>

    </div>
  </div>
</body>
```

Notes:

* `terminal-output` is whatever you already append lines into
* `system-panel` is *read-only*, updated only after `/snapshot`
* No buttons, no handlers here

---

## 2. Exact CSS (Drop-In)

This CSS is intentionally conservative and monospace-safe.

```css
/* ========== ROOT ========== */

html, body {
  margin: 0;
  padding: 0;
  background: #0b0d10;
  color: #d7dae0;
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  height: 100%;
}

#app {
  display: grid;
  grid-template-columns: 2fr 1fr;
  height: 100vh;
}

/* ========== TERMINAL PANE ========== */

#terminal-pane {
  display: flex;
  flex-direction: column;
  border-right: 1px solid #222;
  padding: 10px;
}

#terminal-output {
  flex: 1;
  overflow-y: auto;
  white-space: pre-wrap;
  line-height: 1.35;
  font-size: 13px;
}

#terminal-input {
  display: flex;
  align-items: center;
  margin-top: 6px;
}

#terminal-input .prompt {
  margin-right: 6px;
}

#command-input {
  flex: 1;
  background: transparent;
  border: none;
  outline: none;
  color: inherit;
  font: inherit;
}

/* ========== SIDE PANE ========== */

#side-pane {
  display: flex;
  flex-direction: column;
  padding: 10px;
  gap: 10px;
}

/* ========== SYSTEM PANEL ========== */

#system-panel {
  border: 1px solid #222;
  padding: 8px;
  font-size: 12px;
  background: #0e1117;
}

.sys-line {
  display: flex;
  justify-content: space-between;
  line-height: 1.4;
}

.sys-line .label {
  color: #7a7f87;
}

/* Emphasis via tone only */
#sys-threat.CRITICAL { color: #ff6b6b; }
#sys-threat.HIGH     { color: #ff9f43; }
#sys-threat.ELEVATED { color: #feca57; }
#sys-threat.LOW      { color: #1dd1a1; }

/* ========== SECTOR MAP ========== */

#sector-map {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  grid-auto-rows: 52px;
  gap: 6px;
}

.sector {
  border: 1px solid #333;
  background: #0e1117;
  padding: 4px;
  text-align: center;
  font-size: 11px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.sector-name {
  font-weight: bold;
  margin-bottom: 2px;
}

/* Status coloring — no animation */
.sector.STABLE {
  color: #1dd1a1;
  border-color: #1dd1a1;
}

.sector.ALERT {
  color: #feca57;
  border-color: #feca57;
}

.sector.DAMAGED {
  color: #ff9f43;
  border-color: #ff9f43;
}

.sector.COMPROMISED {
  color: #ff6b6b;
  border-color: #ff6b6b;
}

/* ========== ROLE WEIGHTING (SUBTLE) ========== */

.sector[data-id="CC"] {
  border-width: 2px;
}

.sector[data-id="PW"],
.sector[data-id="DF"] {
  filter: brightness(1.1);
}

.sector[data-id="AR"] {
  opacity: 0.85;
}

/* ========== FAILURE STATE ========== */

body.failed #sector-map {
  opacity: 0.4;
}

body.failed #system-panel {
  opacity: 0.6;
}
```

---

## 3. Minimal JS Wiring (Conceptual Only)

You already fetch `/snapshot`. When you do:

### 3.1 Update System Panel

```js
function updateSystemPanel(snapshot) {
  document.getElementById("sys-time").textContent = snapshot.time;
  document.getElementById("sys-threat").textContent = snapshot.threat;
  document.getElementById("sys-assault").textContent = snapshot.assault;
  document.getElementById("sys-posture").textContent =
    snapshot.posture ?? "NONE";
  document.getElementById("sys-archive").textContent =
    snapshot.archive_losses
      ? `${snapshot.archive_losses} / 3`
      : "--";
}
```

Call this **only** when you already fetch snapshot (after `WAIT`, `WAIT 10X`, etc).

---

### 3.2 Failure Visual Lock

When backend indicates failure:

```js
document.body.classList.add("failed");
```

No modal. No overlay.

---

## 4. Why This Works (Important)

This UI:

* Creates **visual hierarchy** without gameplay hints
* Makes *state legible* without *strategy leakage*
* Keeps STATUS relevant
* Makes WAIT feel heavier
* Requires no refactors later

Most importantly:

> The UI tells you **what is happening**,
> not **what you should do about it**.

That’s the correct tone for CUSTODIAN.

---

## 5. Hard Stop Rule (UI Scope)

If you feel tempted to add:

* hover text
* icons
* arrows
* progress bars
* explanations

**Stop.**
That’s Phase 2+ work.

Below is a **precise, Phase-1.5-safe spec** that does two things:

1. **Tunes typography** to increase tension, hierarchy, and legibility
2. **Defines deterministic UI degradation when COMMS is damaged**, using *only presentation-layer changes*

No backend changes required beyond what you already have (`snapshot.sectors`).

---

# CUSTODIAN — TYPOGRAPHY TUNING + COMMS UI DEGRADATION SPEC

*(Phase 1.5, Presentation-Only)*

---

## PART 1 — TYPOGRAPHY TUNING (TENSION WITHOUT NOISE)

### Goals

* Make the terminal feel *industrial and brittle*
* Increase readability without comfort
* Encode hierarchy via **weight, spacing, and contrast**, not color explosions
* Avoid “retro cosplay” fonts that undermine seriousness

---

## 1. Font Stack (Exact)

Replace your global font-family with this:

```css
html, body {
  font-family:
    "IBM Plex Mono",
    "JetBrains Mono",
    ui-monospace,
    SFMono-Regular,
    Menlo,
    Consolas,
    monospace;
}
```

Why:

* IBM Plex Mono: technical, restrained, legible under stress
* JetBrains Mono fallback: strong differentiation at small sizes
* System monospace last: no webfont dependency required

---

## 2. Terminal Typography

### 2.1 Base Terminal Output

```css
#terminal-output {
  font-size: 13px;
  line-height: 1.35;
  letter-spacing: 0.2px;
}
```

This keeps density high but readable.

---

### 2.2 Message Class Weighting

Apply **visual emphasis only**, no layout change.

```css
.line.system {
  color: #d7dae0;
}

.line.event {
  color: #9aa0a6;
}

.line.warning {
  color: #feca57;
  font-weight: 500;
}

.line.assault {
  color: #ff9f43;
  font-weight: 600;
  letter-spacing: 0.4px;
}

.line.failure {
  color: #ff6b6b;
  font-weight: 700;
  letter-spacing: 0.6px;
}
```

Result:

* Assaults *feel louder* without extra text
* Failure reads as final, not dramatic

---

### 2.3 Prompt & Input

```css
#terminal-input .prompt {
  color: #7a7f87;
}

#command-input {
  caret-color: #d7dae0;
}
```

Subtle, non-distracting.

---

## 3. System Panel Typography (Anchor the Eye)

This panel should feel like a **status placard**, not a HUD.

```css
#system-panel {
  font-size: 12px;
  letter-spacing: 0.4px;
}

.sys-line .label {
  font-weight: 400;
  color: #6c7078;
}

.sys-line span:last-child {
  font-weight: 600;
}
```

Values are heavier than labels → the eye goes to facts, not categories.

---

## PART 2 — COMMS DAMAGE UI DEGRADATION

*(Presentation-Only, Deterministic)*

This is the important part.

**COMMS damage should reduce clarity, not remove information outright.**
The UI becomes *less trustworthy*, not blind.

---

## 4. COMMS Damage States (Derived from Snapshot)

You already have:

```json
{ "id": "CM", "status": "STABLE | ALERT | DAMAGED | COMPROMISED" }
```

UI behavior is driven entirely by that value.

---

## 5. Degradation Rules by COMMS State

### 5.1 COMMS = STABLE (Baseline)

* Full UI fidelity
* No effects

---

### 5.2 COMMS = ALERT (Early Interference)

**Goal:** introduce doubt, not failure.

#### Effects

```css
body.comms-alert #system-panel {
  opacity: 0.95;
}

body.comms-alert .line.warning {
  opacity: 0.9;
}
```

Subtle. Almost placebo-level.
Players *feel* something is off before they can articulate it.

---

### 5.3 COMMS = DAMAGED (Loss of Precision)

**This is the key state.**

#### Effects

##### A. System Panel Degradation

```css
body.comms-damaged #system-panel {
  opacity: 0.8;
}
```

Still readable, but less authoritative.

---

##### B. Sector Map Fidelity Loss

* Sector **names remain**
* Sector **statuses degrade to buckets**

Instead of:

```
DAMAGED
```

UI renders:

```
UNSTABLE
```

Mapping (UI-only):

| Real Status | Displayed |
| ----------- | --------- |
| STABLE      | STABLE    |
| ALERT       | UNSTABLE  |
| DAMAGED     | UNSTABLE  |
| COMPROMISED | CRITICAL  |

This is **intentional ambiguity**.

No backend change.
Just a display mapping in `sector-map.js`.

---

##### C. Terminal Output Noise

```css
body.comms-damaged .line.event {
  opacity: 0.7;
}
```

Events become harder to parse at a glance.

---

### 5.4 COMMS = COMPROMISED (Intermittent Blindness)

**This is the maximum degradation without removing control.**

#### Effects

##### A. Sector Map Partial Suppression

* Every snapshot render:

  * Randomly hide **one non-COMMAND sector**
  * Replace with:

```
[NO SIGNAL]
```

Implementation:

* Client-side only
* Deterministic per render if you want (seed with snapshot.time)

CSS:

```css
.sector.no-signal {
  color: #555;
  border-color: #333;
  font-style: italic;
}
```

---

##### B. System Panel Uncertainty

```css
body.comms-compromised #sys-assault::after {
  content: " ?";
  opacity: 0.6;
}
```

ASSAULT state is now *suspect*, not wrong.

---

##### C. Terminal Trust Erosion

```css
body.comms-compromised #terminal-output {
  letter-spacing: 0.3px;
}
```

Tiny change. Psychological effect: text feels “noisy”.

---

## 6. Implementation Hook (Minimal JS)

When snapshot updates:

```js
function applyCommsState(snapshot) {
  const comms = snapshot.sectors.find(s => s.id === "CM");
  document.body.classList.remove(
    "comms-alert",
    "comms-damaged",
    "comms-compromised"
  );

  if (!comms) return;

  if (comms.status === "ALERT") {
    document.body.classList.add("comms-alert");
  } else if (comms.status === "DAMAGED") {
    document.body.classList.add("comms-damaged");
  } else if (comms.status === "COMPROMISED") {
    document.body.classList.add("comms-compromised");
  }
}
```

Call this whenever you already update the map/system panel.

---

## 7. Why This Is the *Correct* Degradation Model

* No lies — only **uncertainty**
* No authority shift — terminal still rules
* No gameplay change — only interpretation cost
* No tutorials needed — players *feel* it

Most importantly:

> COMMS damage attacks **confidence**, not control.

That’s exactly what information loss should do.

---

## 8. Hard Rules (Do Not Break)

* Never hide COMMAND sector
* Never block input
* Never fake events
* Never contradict backend truth — only obscure it

---

## Final Lock-In Statement

With these changes:

* The UI *tightens* as pressure rises
* The player loses **clarity before safety**
* STATUS becomes more valuable under stress
* Damage feels systemic, not cosmetic

You now have a UI that **fails gracefully**—which is rare, and powerful.

If you want next, I can:

* spec UI degradation for **POWER** or **ARCHIVE**
* tune micro-animations that don’t violate determinism
* or define the exact UI transition when COMMAND is breached

This is excellent work.

