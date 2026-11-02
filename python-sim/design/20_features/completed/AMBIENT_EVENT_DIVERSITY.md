# AMBIENT EVENT DIVERSITY — Completed

Status: Implemented on 2026-03-03.

## Problem Statement

The ambient event layer feels repetitive and spammy because:

1. **Small archetype pool** — 14 events, narrow emotional band
2. **Linear tension** — Everything implies assault; no calm/environmental variation
3. **Random selection** — No category awareness or context weighting
4. **No memory** — Exact repeats possible within short windows

**Root cause:** Selection logic is "pick random event from small pool" rather than "compose diverse signals."

---

## Solution Overview

**Philosophy:** Fix surface variety first. Structural pacing systems only if variety still feels weak.

**Approach:** Throttle suppression → Structural diversity. Keep frequency; change composition.

**Target feel:** Signals in a system, not random log spam.

---

## Implemented Scope (Phases 1–2)

### Phase 1: Categorization & Memory Suppression

#### 1.1 Wrap Existing Events in Categories

Keep all existing effect functions unchanged. Add category metadata:

```python
class AmbientEvent:
    def __init__(self, key, name, category, min_threat, weight, cooldown, sector_filter, effect, chains=None):
        self.key = key
        self.name = name
        self.category = category          # NEW FIELD
        self.min_threat = min_threat
        self.weight = weight
        self.cooldown = cooldown
        self.sector_filter = sector_filter
        self.effect = effect
        self.chains = chains or []
```

#### 1.2 Category Definitions

```python
EVENT_CATEGORIES = {
    "QUIET": {           # Non-threatening status reports
        "weight": 0.35,
        "min_threat": 0.0,
    },
    "ENVIRONMENTAL": {   # Non-hostile stressors (existing structural, coolant)
        "weight": 0.20,
        "min_threat": 0.8,
    },
    "INFRASTRUCTURE": { # Wear, decay, failures
        "weight": 0.15,
        "min_threat": 1.5,
    },
    "RECON": {          # Pre-assault signals (probes, jamming)
        "weight": 0.15,
        "min_threat": 1.0,
    },
    "HOSTILE": {        # Active threat events (sabotage, breach)
        "weight": 0.15,
        "min_threat": 2.0,
    },
}
```

#### 1.3 Map Existing Events to Categories

| Existing Event | Category |
|---------------|----------|
| perimeter_probe | RECON |
| sabotage_charge | HOSTILE |
| conduit_cut | HOSTILE |
| power_blackout | INFRASTRUCTURE |
| structural_fatigue | ENVIRONMENTAL |
| coolant_leak | ENVIRONMENTAL |
| fuel_fire | HOSTILE |
| tunnel_infiltration | HOSTILE |
| sensor_jam | RECON |
| signal_blackout | RECON |
| data_siphon | HOSTILE |
| doctrine_panic | HOSTILE |
| goal_breach | HOSTILE |

#### 1.4 Add Quiet Events (2–3 new archetypes)

```python
QUIET_EVENTS = [
    ("quiet_perimeter_stable", "Perimeter stable. No external movement.", "QUIET", 0.0, 1.5, 8, None, lambda s, sec: None),
    ("quiet_night_cycle", "Night cycle nominal. All sectors reporting.", "QUIET", 0.0, 1.2, 10, None, lambda s, sec: None),
    ("quiet_atmospheric", "Atmospheric processors cycling within tolerance.", "QUIET", 0.0, 1.0, 12, None, lambda s, sec: None),
]
```

#### 1.5 Recent Event Memory

```python
class WorldState:
    # ... existing fields ...
    recent_events: deque = field(default_factory=lambda: deque(maxlen=5))
    last_event_category: str = None
```

```python
def filter_recent_events(candidates, recent_events):
    """Prevent exact repeat within last 5 events."""
    filtered = []
    for event, sector in candidates:
        if event.name not in recent_events:
            filtered.append((event, sector))
    return filtered if filtered else candidates  # Fallback to all if exhausted
```

---

### Phase 2: Contextual Weighting

#### 2.1 State Fields

```python
class WorldState:
    # ... existing fields ...
    ticks_since_assault: int = 0
    ticks_since_hostile: int = 0
```

#### 2.2 Update Logic (in tick loop)

```python
def update_event_context(state):
    """Heuristic-based context weighting."""
    state.ticks_since_assault += 1
    if state.last_assault_tick:
        state.ticks_since_assault = state.time - state.last_assault_tick
    
    state.ticks_since_hostile += 1
    # Track hostile events in tick_events to update this
```

#### 2.3 Weight Modifiers (Three Heuristics Only)

Low-power heuristic is implemented using aggregate sector power percentage (average sector power * 100), with the same `< 40` threshold behavior.

---

### Phase 2.5: Add 2–3 New Archetypes

Add these new events to flesh out categories:

#### ENVIRONMENTAL
- "Microfracture detected in sector plating"
- "Thermal anomaly in intake systems"
- "Radiation burst — origin unknown"

#### INFRASTRUCTURE  
- "Fabrication queue delay — resource contention"
- "Archive checksum mismatch detected"
- "Defense grid recalibrating"

---

### Selection Algorithm (Final)

```python
def select_ambient_event(state):
    # 1. Build category weights with heuristics
    category_weights = compute_category_weights(state)
    
    # 2. Select category
    categories = list(category_weights.keys())
    weights = list(category_weights.values())
    selected_category = state.rng.choices(categories, weights=weights)[0]
    
    # 3. Get candidates in category
    all_events = build_event_catalog(state)
    candidates = [(e, s) for e in all_events for s in state.sectors.values() 
                 if e.category == selected_category and e.can_trigger(state, s)]
    
    # 4. Filter recent events (exact repeat prevention)
    candidates = filter_recent_events(candidates, state.recent_events)
    
    if not candidates:
        return None
    
    # 5. Select event, sector
    event, sector = state.rng.choice(candidates)
    
    # 6. Update state
    state.recent_events.append(event.name)
    state.last_event_category = selected_category
    
    return event, sector
```

---

## File Changes

| File | Change |
|------|--------|
| `game/simulations/world_state/core/events.py` | Added event categories, quiet/new archetypes, context weighting heuristics, recent-event suppression, and category-based selector |
| `game/simulations/world_state/core/state.py` | Added event context fields (`recent_events`, `last_event_category`, `ticks_since_assault`, `ticks_since_hostile`, `last_assault_tick`) and snapshot payload (`event_context`) |
| `game/simulations/world_state/core/assaults.py` | Added `last_assault_tick` update on assault resolution |
| `game/simulations/world_state/core/snapshot_migration.py` | Added migration/default handling for `event_context`; snapshot version bumped to 7 |
| `game/simulations/world_state/tests/test_ambient_event_diversity.py` | Added coverage for category catalog, repeat suppression, heuristics, and selector memory updates |
| `game/simulations/world_state/tests/test_snapshot.py` | Updated snapshot schema assertion and event-context coverage |

---

## Backward Compatibility

- **Existing core hostile/recon/environmental effect functions preserved** — `probe_perimeter()`, `power_blackout()`, and existing archetype effects remain intact
- **Selection layer expanded** — Existing selector replaced with category-aware selection and anti-repeat memory
- **Cooldowns preserved** — Per-event, per-sector cooldown logic intact

---

## Testing Checklist

- [x] Category rotation penalty active for same-category follow-up events
- [x] Exact string repeats suppressed within last 5 events (with candidate-exhaustion fallback)
- [x] QUIET events available at low threat and included in category weighting
- [x] After assault: ENVIRONMENTAL/QUIET weighting boost
- [x] Low power: INFRASTRUCTURE weighting boost
- [x] Long calm: RECON weighting boost
- [x] Existing world-state suite passes (172 tests)

---

## Verification Command

```bash
./.venv/bin/pytest -q game/simulations/world_state/tests
```

---

## Out of Scope (Future Phases)

- Formal tension meter
- Explicit cadence phase enum
- Event chain objects
- Suppression cooldown windows
- Full EventDirector class abstraction
