# STATUS UX REWORK — CODEX IMPLEMENTATION INSTRUCTIONS

This instruction set modifies the existing CUSTODIAN codebase to:

1. Add Situation Header
2. Add Priority-Sorted Sector Display
3. Add Delta Markers
4. Compress Header Block
5. Add ASCII Status Markers
6. Add Compact Map Mode (Field Mode – Top Priority)
7. Add Pulse Highlight (UI minimal)
8. Add Heat-Band Grouping (UI minimal)

---

# 🔴 PART 1 — STATUS CORE REWORK

File:
`game/simulations/world_state/terminal/commands/status.py`

---

## 1️⃣ Add Situation Header

Add function at top of file:

```python
def _compute_situation_header(state):
    degraded = []
    for sector in state.sectors.values():
        label = sector.status_label()
        if label in ("DAMAGED", "COMPROMISED"):
            degraded.append(sector.name)

    if degraded:
        count = len(degraded)
        return f"SITUATION: {count} SYSTEM{'S' if count > 1 else ''} DEGRADED"

    if state.fidelity != "FULL":
        return "SITUATION: INFORMATION UNSTABLE"

    return "SITUATION: STABLE"
```

Insert into STATUS output immediately after header line block.

---

## 2️⃣ Compress Header Block

Replace:

```
TIME: 18
THREAT: HIGH
ASSAULT: PENDING
```

With single line:

```python
lines.append(
    f"TIME: {snapshot['time']} | THREAT: {snapshot['threat']} | ASSAULT: {snapshot['assault']}"
)
```

Replace posture/archive lines with:

```python
lines.append(
    f"POSTURE: {snapshot.get('posture','-')} | ARCHIVE: {snapshot.get('archive','-')}"
)
```

Do not display posture target at degraded fidelity.

---

## 3️⃣ Priority Sort Sectors

Replace existing sector iteration.

Add:

```python
def _sector_priority(sector):
    label = sector.status_label()
    order = {
        "COMPROMISED": 0,
        "DAMAGED": 1,
        "ALERT": 2,
        "ACTIVITY DETECTED": 3,
        "STABLE": 4,
    }
    return order.get(label, 5)
```

Sort:

```python
sorted_sectors = sorted(
    state.sectors.values(),
    key=_sector_priority
)
```

---

## 4️⃣ ASCII Status Markers

Add mapping:

```python
MARKERS = {
    "COMPROMISED": "X",
    "DAMAGED": "!",
    "ALERT": "~",
    "ACTIVITY DETECTED": "?",
    "STABLE": ".",
}
```

Render sectors as:

```python
for sector in sorted_sectors:
    label = sector.status_label()
    marker = MARKERS.get(label, ".")
    lines.append(f"{sector.name:<12} {marker}")
```

Remove verbose `: DAMAGED` style rendering.

---

## 5️⃣ Add Delta Markers

Store previous snapshot hash.

In `GameState` add:

```python
self._last_sector_status = {}
```

Before rendering sectors:

```python
delta = ""
prev = state._last_sector_status.get(sector.name)
current = sector.status_label()

if prev:
    if current != prev:
        if _sector_priority(sector) < _sector_priority_by_label(prev):
            delta = " (+)"
        else:
            delta = " (-)"
```

Append delta to render line:

```python
lines.append(f"{sector.name:<12} {marker}{delta}")
```

After rendering, update:

```python
state._last_sector_status[sector.name] = current
```

---

# 🔵 PART 2 — COMPACT MAP MODE (TOP PRIORITY)

Condition:

```python
if state.player_mode == "FIELD":
```

When FIELD mode:

* Do not render full STATUS.
* Render compact tactical map view.

---

## Add Compact Renderer

Add function in `status.py`:

```python
def _render_compact_field_view(state):
    lines = []

    lines.append(f"LOCATION: {state.player_location}")
    lines.append(f"FIDELITY: {state.fidelity}")

    sorted_sectors = sorted(
        state.sectors.values(),
        key=_sector_priority
    )

    for sector in sorted_sectors:
        marker = MARKERS.get(sector.status_label(), ".")
        prefix = ">" if sector.name == state.player_location else " "
        lines.append(f"{prefix} {sector.name:<10} {marker}")

    return lines
```

At start of STATUS:

```python
if state.player_mode == "FIELD":
    return _render_compact_field_view(state)
```

Do not include:

* Threat
* Assault timers
* Archive losses
* Global posture

FIELD mode hides global data.

---

# 🟡 PART 3 — UI PULSE HIGHLIGHT (MINIMAL)

File:
`frontend/src/components/TerminalOutput.jsx`

When rendering lines:

If line contains `(+)` or `(-)`:

Add class:

```jsx
<span className="delta">{line}</span>
```

---

## CSS

Add:

```css
.delta {
  animation: pulse 1.2s ease-out 1;
}

@keyframes pulse {
  0% { background-color: rgba(255,255,255,0.2); }
  100% { background-color: transparent; }
}
```

Respect reduced motion:

```css
@media (prefers-reduced-motion: reduce) {
  .delta {
    animation: none;
  }
}
```

---

# 🟠 PART 4 — HEAT BAND GROUPING (MINIMAL)

Modify sector render loop:

Before stable sectors, insert divider:

```python
if marker == "." and not stable_header_added:
    lines.append("---")
    stable_header_added = True
```

Add CSS class per marker type in frontend:

```jsx
const heatClass = {
  "X": "heat-critical",
  "!": "heat-damaged",
  "~": "heat-alert",
  "?": "heat-unknown",
  ".": "heat-stable",
}[marker]
```

CSS:

```css
.heat-critical { color: #ff3b3b; }
.heat-damaged { color: #ff8844; }
.heat-alert { color: #ffd24d; }
.heat-unknown { color: #aaa; }
.heat-stable { color: #66cc88; }
```

Ensure WCAG AA contrast.

---

# 🟢 FIELD MODE RULES (IMPORTANT)

FIELD mode must:

* Never show global threat value
* Never show assault timer
* Never show archive counts
* Only show:

  * location
  * fidelity
  * compact sector list
  * local marker emphasis

---

# 🔒 DO NOT CHANGE

* Fidelity computation
* Assault logic
* Snapshot versioning
* Message catalog
* Repair flow

Only modify STATUS presentation layer.

---

# RESULT

COMMAND mode:

* Compact header
* Situation header
* Priority sorted sectors
* Delta markers
* Heat bands

FIELD mode:

* Minimal tactical console
* Location-centric
* No global state
* Immediate readability

---

# IMPLEMENT ORDER

1. STATUS core refactor
2. FIELD compact mode
3. Delta tracking state addition
4. UI pulse highlight
5. Heat-band CSS

Do not combine into one commit.
Max one feature per commit.

