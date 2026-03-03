# AMBIENT EVENT DIVERSITY — Feature Specification

## Problem Statement

The ambient event layer feels repetitive and spammy because:

1. **Small archetype pool** — 14 events, narrow emotional band
2. **Linear tension** — Everything implies assault; no calm/environmental variation
3. **Random selection** — No category awareness or context weighting
4. **No memory** — Exact repeats possible within short windows

**Root cause:** Selection logic is "pick random event from small pool" rather than "compose diverse signals."

---

## Solution Overview

Replace throttling (fewer events) with **structural diversity** (different events). Keep frequency; change composition.

**Target feel:** Signals in a system, not random log spam.

**Emotional cadence:** Calm → Uncertainty → Signal → Escalation → Assault → Aftermath → Calm

---

## Implementation Plan

### Phase 1: Event Taxonomy Refactor

#### New Category Structure

```python
EVENT_CATEGORIES = {
    "QUIET": {           # Non-threatening status reports
        "weight_base": 0.35,
        "min_threat": 0.0,
    },
    "ENVIRONMENTAL": {   # Non-hostile stressors
        "weight_base": 0.25,
        "min_threat": 0.3,
    },
    "INFRASTRUCTURE": { # Wear, decay, failures
        "weight_base": 0.20,
        "min_threat": 0.8,
    },
    "RECON": {          # Pre-assault signals
        "weight_base": 0.12,
        "min_threat": 1.5,
    },
    "HOSTILE": {        # Active threat events
        "weight_base": 0.08,
        "min_threat": 2.5,
    },
}
```

#### New Event Archetypes by Category

| Category | New Events |
|----------|-----------|
| **QUIET** | Perimeter stable, Night cycle nominal, No movement detected, Ambient systems nominal |
| **ENVIRONMENTAL** | Power grid fluctuation, Microfracture detected, Thermal anomaly, Radiation burst, Dust intake interference |
| **INFRASTRUCTURE** | Fabrication queue delay, Grid recalibration, Archive checksum warning, Storage mismatch |
| **RECON** | Long-range scan triangulation, Sensor sweep signature, Vector estimation incomplete |
| **FALSE_POSITIVE** | Signal echo misclassification, Abandoned drone signature, Static burst |

#### Quiet Events (Critical)

These are essential for emotional modulation:

```python
QUIET_EVENTS = [
    "Perimeter stable. No external movement.",
    "Night cycle nominal. All sectors reporting.",
    "Atmospheric processors cycling within tolerance.",
    "No anomalous signatures on long-range scans.",
    "Perimeter defense grid at full readiness.",
]
```

---

### Phase 2: Category Rotation System

#### State Additions

```python
class WorldState:
    # ... existing fields ...
    last_event_category: str = None      # Prevent same-category spam
    category_cooldown: dict = {}         # Per-category cooldown ticks
    recent_events: deque(maxlen=5)       # Exact repeat prevention
    context_modifiers: dict = {}          # Dynamic weight adjustments
```

#### Rotation Logic

```python
def compute_category_weight(category, state):
    base = EVENT_CATEGORIES[category]["weight_base"]
    
    # Rotation penalty: reduce weight if same category as last event
    if state.last_event_category == category:
        base *= 0.25  # Strong deprioritization, not ban
    
    # Context modifiers (Phase 3)
    if category in state.context_modifiers:
        base *= state.context_modifiers[category]
    
    return base
```

**Effect:** Prevents Probe → Probe → Probe without killing frequency.

---

### Phase 3: Context-Aware Weighting

#### Heuristic Modifiers

| Condition | Increase Weight Of | Multiplier |
|-----------|-------------------|------------|
| `power < 40%` | INFRASTRUCTURE | ×1.5 |
| `ticks_since_assault < 5` | AFTERMATH (infra/quiet) | ×1.4 |
| `ticks_since_assault > 30` | RECON/ENVIRONMENTAL | ×1.3 |
| `sector.damage > 2.0` | INFRASTRUCTURE | ×1.4 |
| `ambient_threat > 5.0` | HOSTILE | ×1.5 |

#### Implementation

```python
def update_context_modifiers(state):
    modifiers = {}
    
    if state.power_grid.total_output < 40:
        modifiers["INFRASTRUCTURE"] = 1.5
    
    ticks_since = state.time - (state.last_assault_tick or 0)
    if ticks_since < 5:
        modifiers["INFRASTRUCTURE"] = modifiers.get("INFRASTRUCTURE", 1.0) * 1.4
        modifiers["QUIET"] = 1.3  # Aftermath reassurance
    elif ticks_since > 30:
        modifiers["RECON"] = 1.3
        modifiers["ENVIRONMENTAL"] = 1.2
    
    if state.ambient_threat > 5.0:
        modifiers["HOSTILE"] = 1.5
    
    state.context_modifiers = modifiers
```

---

### Phase 4: Recent Event Memory

```python
def select_event(state, candidates):
    # Filter recent events (exact repeat prevention)
    filtered = []
    for event, sector in candidates:
        if event.name in state.recent_events:
            continue  # Skip exact repeats
        filtered.append((event, sector))
    
    if not filtered:
        # Fallback: allow repeats only after exhausting options
        filtered = candidates
    
    # Select using category-weighted logic...
```

```python
# After event selection, before emission:
state.recent_events.append(event.name)
if len(state.recent_events) > 5:
    state.recent_events.popleft()
```

---

### Phase 5: Lightweight Event Sequences

Instead of full chain objects, use **conditional follow-up weighting**:

```python
# When these events trigger, boost follow-up weights:
SEQUENCE_BOOSTS = {
    "signal_anomaly": {
        "categories": ["RECON", "ENVIRONMENTAL"],
        "duration": 3,
        "multiplier": 1.6,
    },
    "perimeter_probe": {
        "categories": ["RECON", "HOSTILE"],
        "duration": 4,
        "multiplier": 1.4,
    },
    "structural_fatigue": {
        "categories": ["INFRASTRUCTURE"],
        "duration": 3,
        "multiplier": 1.3,
    },
}
```

```python
def apply_sequence_boosts(state, category_weights):
    # Check active boosts
    for event_key, boost in SEQUENCE_BOOSTS.items():
        if event_key in state.recent_events:
            for cat in boost["categories"]:
                if cat in category_weights:
                    category_weights[cat] *= boost["multiplier"]
    return category_weights
```

---

### Phase 6: Selection Algorithm (Full)

```python
def select_ambient_event(state):
    update_context_modifiers(state)
    
    # 1. Build category weights
    category_weights = {}
    for category, config in EVENT_CATEGORIES.items():
        if state.ambient_threat >= config["min_threat"]:
            weight = compute_category_weight(category, state)
            category_weights[category] = weight
    
    # 2. Apply sequence boosts
    category_weights = apply_sequence_boosts(state, category_weights)
    
    # 3. Normalize
    total = sum(category_weights.values())
    category_weights = {k: v/total for k, v in category_weights.items()}
    
    # 4. Select category
    selected_category = weighted_random(state.rng, category_weights)
    
    # 5. Filter events in category + candidates
    candidates = get_candidates_for_category(state, selected_category)
    candidates = filter_recent_events(state, candidates)
    
    # 6. Select event
    event, sector = weighted_random(state.rng, candidates)
    
    # 7. Update state
    state.last_event_category = selected_category
    state.recent_events.append(event.name)
    
    return event, sector
```

---

## File Changes

| File | Change |
|------|--------|
| `game/simulations/world_state/core/events.py` | Refactor to use EventDirector class |
| `game/simulations/world_state/core/state.py` | Add new state fields |
| `game/simulations/world_state/core/config.py` | Add category configs and new event definitions |

---

## Backward Compatibility

- Keep existing event effect functions unchanged
- Migrate existing EVENT_ARCHETYPES to new category structure
- Preserve existing cooldown logic per-event, per-sector

---

## Testing Checklist

- [ ] Category rotation prevents 3+ same-category events in a row
- [ ] Exact string repeats never appear within 5 events
- [ ] Context weighting produces visibly different event mixes at different threat levels
- [ ] Quiet events appear at low threat (baseline ~35% of events)
- [ ] Sequence boosts create organic tension escalation
- [ ] Performance: no measurable tick overhead

---

## Out of Scope (Future)

- Full tension meter system
- Explicit event chains (beyond lightweight follow-ups)
- Player-visible category filtering
- Event narrative log stitching
