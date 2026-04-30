# HUB CHROMA PROGRESSION MODEL

**Status:** draft
**Parent:** HUB_DOCTRINE.md
**Last Updated:** 2026-04-22

---

## Overview

This spec defines how color restoration works in the hub: which domains restore which hues, under what conditions, the three dimensions of fidelity, and how chromatic pressure builds in late game.

---

## 1. Color Domains

| Domain | Hue | Emotional Register | Campaign Types That Trigger |
|--------|-----|-------------------|----------------------------|
| **Sacrifice** | Red / ember / wine | Oaths, blood, war, destructive truth | Combat-heavy, loss scenarios |
| **Authority** | Gold / amber | Law, canon, validated knowledge | Successful validation, hypothesis confirmed |
| **Cognition** | Blue / violet | Cold truth, astronomy, archive | Discovery, research, understanding |
| **Persistence** | Green | Unauthorized life, surviving systems | Survival, endurance, hypothesis survives |
| **Synthesis** | White / iridescent | Total revelation, dangerous truth | Final campaigns, all domains intersect |

---

## 2. Three Dimensions of Fidelity

Every return raises one or more of:

| Dimension | Effect |
|-----------|--------|
| **Legibility** | The city can be read more accurately — details, paths, functions become distinguishable |
| **Access** | More of the city and its systems become usable — routes, archives, mechanisms open |
| **Instability** | Reality handles the recovered signal less gracefully — pressure builds, ruptures occur |

---

## 3. Scenario Intelligence by Fidelity

| Fidelity Level | Campaign Intelligence |
|-----------------|----------------------|
| Low | Vague proposals, broad unknowns |
| Mid | Campaign categories become clearer before selection |
| Later | Certain risk types, failure modes, knowledge stakes partially visible |
| Very Late | City cross-references signals, reveals hidden relationships between prior campaigns |

**Example progression:**
- Early: "Bio anomaly detected"
- Later: "Biotech precursor signal shares architectural pattern with Archive District statuary"

---

## 4. District Reactivation by Domain

| Domain | Functionality Unlocked |
|--------|---------------------|
| **Gold/amber** | Civic/adjudicative spaces — judgment halls, record chambers, doctrinal classification |
| **Blue/violet** | Observatories, archives, cosmological instruments — better campaign forecasting |
| **Green** | Living overgrowth systems — traversal openings, organic bridges, reclaimed wells |
| **Red/wine** | Martial/sacrificial districts — training grounds, reliquaries, weapon-memory halls |

---

## 5. Restoration Logic

### Trigger Conditions
- Campaign completion → evaluate outcome type → apply to domain
- Multiple domains can restore in one return
- Synthesis absorbs other domains

### District Mapping

| District | Primary Domain | Secondary |
|----------|---------------|-----------|
| The Road of Witnesses | Authority (gold) | Sacrifice (red) |
| The Archive Heights | Cognition (blue/violet) | Synthesis (white) |
| The Sunken Civic Quarter | Persistence (green) | - |
| The Prism Margin | Synthesis (white) | All domains interact |
| The Custodian's Approach | All domains | Ambient |

---

## 6. Progression Phases (Aligned with HUB_DOCTRINE)

### Phase 0: Ashen
- Nearly monochrome, broad silhouettes only
- Simple traversal, vague campaign intelligence
- Hub feels dead, vast, lonely

### Phase 1: Differentiation
- Material classes separate visually
- District identity becomes readable
- First reactivated mechanisms

### Phase 2: Recovery
- Colors return in domains
- Memory overlays begin
- New routes/sky start responding

### Phase 3: Saturation
- City becomes magnificent
- Rich environmental guidance and symbolism
- Wildlife behavior becomes informative
- Campaign intelligence becomes much richer

### Phase 4: Overfull / Terminal
- Chromatic pressure spikes
- Ruptures, fractures, collapsing grandeur
- Hub is most beautiful and most endangered

**Emotional curve:** dead → readable → wondrous → excessive → unstable

---

## 7. Memory Bleed / Historical Overlays

At certain fidelity thresholds, brief overlays of the city's former state appear:

| Overlay | Effect |
|---------|--------|
| Intact banners | Appear over ruined avenues temporarily |
| Phantom crowds | Move along stairs, then disappear |
| Vanished bridges | Appear long enough to cross |
| Light traces | Show old defensive alignments |
| Event fragments | Prior catastrophic events replay in fragments |

**Gameplay use:** Shows hidden paths, reveals lost interactables, foreshadows lore.
**Constraint:** No NPC ghosts. Hub remains unpopulated.

---

## 8. Wildlife as Diagnostic Signal

| Signal | Meaning |
|--------|---------|
| Pale birds gather | Truth-bearing structures reactivating |
| Foxlike creatures avoid | Sectors about to destabilize |
| Iridescent moths appear | Usable prismatic routes nearby |
| Scavengers nest in statues | Specific recovered knowledge domains |

---

## 9. Prismatic Routing

Once enough color exists, the sky participates:

- Certain routes only appear under specific sky angles
- Double-sunset alignment temporarily opens parts of the city
- Prism flares reveal hidden inscriptions or route markers
- Late game: sky becomes a dynamic timing system for hub interactions

---

## 10. Chromatic Pressure System (Late Game)

### Pressure Accumulation
- Each domain restoration adds to `chromatic_pressure` meter
- Pressure decays slowly over time between campaigns
- Late-game: pressure accumulates faster than it decays

### Pressure Levels

| Pressure | State | Effects |
|-----------|-------|---------|
| 0-30% | Stable | Normal gameplay |
| 30-60% | Rising | Subtle environmental strain, occasional micro-ruptures |
| 60-80% | Critical | Path hazards, blocked routes, skyline fatigue |
| 80-100% | Overfull | Massive ruptures, self-destructing grandeur, player must choose which districts to prioritize |

### 10.1 Chromatic Ruptures (Critical+)

- Statues crack, shed enormous slabs
- Floors flare into old mosaic geometry, then shatter
- Archways briefly become whole, then explode
- Windows prism and lance environment with light

### 10.2 Skyline Fatigue Events

- Distant horizon tears
- Stars misalign
- Light blooms too long after sunset
- Whole towers silhouette against cosmic rupture flashes

### 10.3 Overexposure Mechanics

- Certain hub interactions only usable during low-pressure periods
- Archive reads require bracing/dampening
- Too much active color in one district triggers failures elsewhere
- Player must decide which parts of the city to let burn brightest

---

## 11. Visual Guidelines

### Early Game
- Desaturated, near-monochrome
- Noise grain, slight desaturation shader
- Fog / particulate obscuring detail

### Mid Game
- Selective color in key areas
- Materials differentiate (bronze vs marble vs stone)
- Statues reveal detail progressively

### Late Game
- Full saturation
- Complex lighting interactions
- Chromatic aberration as subtle effect

### End State
- Slight color bleeding / overflow
- Uncanny luminosity
- Reality starts to feel thin

---

## 12. Technical Implementation Notes

- Hub scene uses shader uniforms for global saturation/saturation curves
- Per-district material overrides for domain-specific tinting
- Per-prop-type restoration state (statues, materials, murals, structures)
- Per-district + per-prop-type state tracking
- `chromatic_pressure` meter with decay rate
- Particle systems for prism effects (triggered by domain restoration)
- Skybox shader parameters linked to domain state

---

## 13. Clarifications

- **No regression** — color persists once restored (can be enhanced but not reduced)
- **Per-district + per-prop granularity** — each district has restoration level for each prop type
- **Synthesis absorbs** — final stage creates chromatic interaction between all domains
- **No maximum returns** — synthesis triggered by narrative, not count
- **No permanently lost truths** — lost can be recovered through specific campaigns
- **Wildlife is signal** — not just ambience

---

## 14. Related

- Parent: `HUB_DOCTRINE.md`
- Related: `HUB_SPATIAL_LAYOUT.md`, `HUB_RETURN_GRAMMAR.md`