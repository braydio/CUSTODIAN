# HUB SPATIAL LAYOUT

**Status:** draft
**Parent:** HUB_DOCTRINE.md
**Last Updated:** 2026-04-22

---

## Overview

Defines the physical geometry of the hub: major districts, landmarks, traversal routes, reveal sequencing, and chromatic progression mapped to city areas.

**Core spatial idea:** A ruined legendary capital built on a long elevated spine, with one dominant ceremonial axis and several broken ring-districts. A dead, overgrown record of civilization's attempt to make itself legible to eternity.

---

## CANONICAL CITY MAP — "THE HISTORICAL CITY"

```text
                                     NORTH

                         ┌─────────────────────────────┐
                         │      THE TWIN SOLARIA       │
                         │  sunset terraces / sky law  │
                         └─────────────┬───────────────┘
                                       │
                      ┌────────────────┴────────────────┐
                      │        ARCHIVE HEIGHTS          │
                      │  sealed libraries / index halls │
                      │  observatories / choir vaults   │
                      └───────┬───────────────┬─────────┘
                              │               │
                    ┌─────────┘               └──────────┐
                    │                                    │
          ┌─────────┴──────────┐              ┌──────────┴─────────┐
          │   WEST MEMORY      │              │    EAST MEMORY     │
          │   BASTIONS         │              │    BASTIONS        │
          │ toppled wardens    │              │ broken heraldry    │
          └─────────┬──────────┘              └──────────┬─────────┘
                    │                                    │
════════════════════╪══════════════ ROAD OF WITNESSES ═══╪════════════════════
                    │                                    │
            ┌───────┴────────┐                   ┌───────┴─────────┐
            │   STATUE LINE   │                   │   STATUE LINE   │
            │ oath-heroes     │                   │ law-heroes      │
            └───────┬────────┘                   └───────┬─────────┘
                    │                                    │
                 ┌──┴────────────────────────────────────┴──┐
                 │             THE ASHEN FORUM               │
                 │ central plaza / scenario surfacing /      │
                 │ historical focal point / dead civic heart │
                 └──┬────────────────────────────────────┬───┘
                    │                                    │
        ┌───────────┴──────────┐              ┌──────────┴───────────┐
        │  SUNKEN CIVIC        │              │   RELIQUARY WARD     │
        │  QUARTER             │              │ shrines / records /  │
        │ drowned courts /     │              │ sealed memory houses │
        │ root-broken streets  │              └──────────┬───────────┘
        └───────────┬──────────┘                         │
                    │                                    │
                    │                           ┌────────┴──────────┐
                    │                           │   PRISM MARGIN    │
                    │                           │ city edge / glass │
                    │                           │ causeways / void  │
                    │                           └────────┬──────────┘
                    │                                    │
            ┌───────┴────────┐                   ┌───────┴──────────┐
            │ SEPULCHER      │                   │  THE LONG EDGE    │
            │ GARDENS        │                   │  OF THE WORLD     │
            │ little wildlife│                   │ impossible sky    │
            └───────┬────────┘                   └───────────────────┘
                    │
           ┌────────┴─────────┐
           │ CUSTODIAN        │
           │ APPROACH         │
           │ return path /    │
           │ familiar entry   │
           └────────┬─────────┘
                    │
           ┌────────┴─────────┐
           │ GATE OF DUST     │
           │ first arrival /  │
           │ departure spine  │
           └──────────────────┘

                                     SOUTH
```

---

## 1. Districts (Revised)

### 1.1 Gate of Dust

**Purpose:** First threshold, departure/arrival spine

**Geometry:**
- Severe broken ingress
- Surviving grandeur implies ritual weight
- Not welcoming — moral/ritual entry threshold

**Function:** Player's first encounter with the city. Sets the tone that entry into this place once had significance.

---

### 1.2 Custodian Approach

**Purpose:** Repeated return route, emotional anchor

**Geometry:**
- Long paving stones, collapsed side chapels
- Dead braziers, shallow stairs
- Distant first glimpse of Ashen Forum
- Modest path compared to monuments

**Function:** The route walked every return. Changes here hit hardest because player sees it every cycle.

---

### 1.3 Sepulcher Gardens

**Purpose:** Life-vs-ruin contrast, wildlife presence

**Geometry:**
- Burial terraces, cloister courts
- Broken statuary plinths
- Stubborn life pushing through stone

**Wildlife:** Pale birds, burrow-creatures, moths, distant deerlike silhouettes

**Constraint:** Life reads as witness, NOT repopulation. Remains lonely.

---

### 1.4 Road of Witnesses

**Purpose:** Dominant ceremonial axis, main spine

**Geometry:**
- Broad avenue (~500m equivalent)
- Lined with ruined statues (oath-heroes west, law-heroes east)
- Processional paving, cracked heraldic markers
- Statue Line sections on both sides

**Chromatic progression:**
- Phase 0: Stone-grey almost all
- Phase 1: Bruised reds, cold gold traces, faded heraldry
- Phase 2+: Banners, mineral veins, gold leaf, sky-refracted color

**Prototype Runtime Note:**
- `res://scenes/hub_road_of_witnesses_prototype.tscn` is the current fast-playable authored preview for this district.
- It uses the authored map image as a background layer with hand-placed collision blockers and a small set of foreground occlusion masks.
- It is a traversal/readability prototype, not yet a canonical reusable TileMap conversion.
- `res://scenes/twin_solaria_backdrop_test.tscn` is a separate development-only fidelity preview using the largest current Twin Solaria composite as a gameplay backdrop. It intentionally provides perimeter collision only; internal traversal and collision are not authored.

---

### 1.5 Ashen Forum

**Purpose:** Dead civic heart, scenario surfacing, interpretation center

**Geometry:**
- Central plaza
- Broken council dais
- Central blackened basin or star-map floor
- Fractured circular inlay
- Surviving plinths that can light/react

**Function:** Where scenario proposals surface, knowledge becomes actionable, player feels the city as historical machine.

---

### 1.6 Sunken Civic Quarter

**Purpose:** Environmental contrast, scale, sadness

**Geometry:**
- Lower elevation
- Drowned courtyards, flooded archives
- Collapsed colonnades, stairwells to nowhere
- Root-split residences, broken administrative streets

**Atmosphere:** Gives city scale and sadness without becoming a cozy town.

---

### 1.7 Reliquary Ward

**Purpose:** Protected memory fragments

**Geometry:**
- Smaller memory-chambers
- Sealed houses, reliquaries
- Saint-shrines

**Function:** Specific recovered truths appear physically: new inscriptions readable, one reliquary opening, dead mural resolves.

---

### 1.8 West/East Memory Bastions

**Purpose:** Ruined defense/memory structures

**West Memory Bastions:** Toppled wardens, broken guardians
**East Memory Bastions:** Broken heraldry, fallen exemplars

**Function:** Imply categories of civilization (law, stewardship, war, craft, mourning, pilgrimage)

---

### 1.9 Archive Heights

**Purpose:** Knowledge machine, north crown

**Geometry:**
- Elevated (stairs/ramp from road)
- Tower structures cluster
- Connecting colonnades

**Landmarks:**
- Hall of Indices
- Choir Vault (fan-vaulted)
- Tower of Catalogues (skyline anchor)
- Astral Registry
- Windowless Deep Archive

**Chromatic:** Violets, cobalt, old glass green, lamp-amber appear

---

### 1.10 Twin Solaria

**Purpose:** Double-sunset cosmology, terminal sky measurement

**Geometry:**
- Long terraces, solar courts
- Horizon galleries
- Sky instruments aligned to impossible celestial behavior
- NOT "sun worship" — civilizational measurement attempt

**Function:** Where the city measures the terminal sky. Cosmology becomes architectural.

---

### 1.11 Prism Margin

**Purpose:** Climactic view, end-game spectacle, city-edge

**Geometry:**
- Eastern edge where city/impossible landscape touch
- Glass causeways, fractured parapets
- Broken bridges, prism towers
- Void-facing platforms

**Function:** Beautiful and slightly dangerous. Atmosphere "fireworks" when chroma returns. End-game chromatic effects concentrate here.

---

### 1.12 The Long Edge of the World

**Purpose:** View of impossible sky

**Geometry:** Beyond Prism Margin, open to cosmic void

---

## 2. Landmark List (Priority Order)

| # | Landmark | District | Function |
|---|----------|----------|----------|
| 1 | Gate of Dust | Gate | First threshold |
| 2 | The Long Stair | Custodian Approach | Approach into city spine |
| 3 | Road of Witnesses | Road | Main ceremonial axis |
| 4 | Ashen Forum | Forum | Scenario/interpretive center |
| 5 | Choir Vault | Archive Heights | Archive landmark |
| 6 | Tower of Catalogues | Archive Heights | Skyline anchor |
| 7 | The Drowned Courts | Sunken Civic | Quarter anchor |
| 8 | Reliquary of Names | Reliquary Ward | Memory node |
| 9 | Twin Solaria | Twin Solaria | Sunset terraces |
| 10 | Prism Margin | Prism Margin | End-of-world overlook |

---

## 3. Traversal Loop

```
[GATE OF DUST]
        |
        v
[CUSTODIAN APPROACH] <-- repeated every return
        |
        v
[ROAD OF WITNESSES] <-- main axis
    /   |   \
   /    |    \
  v     v     v
[SEPULCHER] [ASHEN] [MEMORY]
  GARDENS  FORUM BASTIONS
   |       |       \
   v       v        v
[SUNKEN] [ARCHIVE] [TWIN SOLARIA]
  CIVIC  HEIGHTS
   \      |      /
    \     |     /
     v    v    v
  [RELIQUARY WARD]
         |
         v
   [PRISM MARGIN] <-- eastern edge
         |
         v
[THE LONG EDGE OF THE WORLD]
```

---

## 4. First Playable Slice

For first playable hub, build this route:

> **Gate of Dust → Custodian Approach → Ashen Forum → one side loop into Sepulcher Gardens → one north climb into lower Archive Heights → one east overlook at the Prism Margin**

This gives:
- Arrival mood
- Core civic heart
- Life-vs-ruin contrast
- Archive identity
- Impossible cosmic edge

Without overbuilding the entire city initially.

---

## 5. Chromatic Progression by District

| Phase | Districts Affected | Chromatic Effect |
|--------|----------------|---------------|
| **0: Ash/Pall** | All | Nearly monochrome, tiny blue-white sky hints |
| **1: Oath Colors** | Road of Witnesses | Bruised reds, cold gold, faded heraldry, identifiable statues |
| **2: Archive Colors** | Archive Heights | Violets, cobalt, glass green, lamp-amber |
| **3: Living Pressure** | Sepulcher Gardens, Sunken Civic | Moss-green, wet stone umber, pale flowers, varied wildlife |
| **4: Civic Revelation** | Ashen Forum, Reliquary Ward | Golds, whites, mural pigments, enamel, stained stone, ceremonial surfacing |
| **5: Prism Excess** | Twin Solaria, Prism Margin | Almost too vivid, spectral bands, double sunsets, more revealed not safer |

---

## 6. Scale Reference

- Road of Witnesses: ~500m length equivalent
- Archive Heights towers: ~60m height equivalent
- Full hub walkable area: ~1km x 1km
- Intimate scale (2-3 minutes to traverse)

---

## 7. Sky / Celestial Framing

| Location | Sky Exposure | Celestial Moment |
|----------|-----------|--------------|
| Road of Witnesses | Partial (colonnade frames) | Sunrise / first sun |
| Ashen Forum | Partial | Star-map floor visible |
| Archive Heights - Observatory | Full 360 | Star patterns, double sunset |
| Prism Margin | Full 180+ | Both suns, prismatic effects |
| Twin Solaria | Full | Solar alignment events |
| Sunken Civic (flooded) | Reflected | Inverted sky views |

---

## 8. Related

- Parent: `HUB_DOCTRINE.md`
- Related: `HUB_CHROMA_PROGRESSION.md`, `HUB_RETURN_GRAMMAR.md`
- Integrates: City map with chroma progression, landmarks
