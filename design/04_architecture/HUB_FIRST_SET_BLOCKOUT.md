# HUB FIRST SET BLOCKOUT

**Status:** active blockout target  
**Runtime target:** Godot 4.x (`custodian/`)  
**Parent authorities:** `HUB_SPATIAL_LAYOUT.md`, `CAMPAIGN_FLOW_AND_GAME_LOOP.md`, `WORLD_TRANSITION_SYSTEM.md`  
**Southern seam authority:** `AWAKENING_FIRST_RETURN.md` / `awakening_layout.gd`  
**Twin authority:** `design/05_levels/TWIN_SOLARIA.md`

---

## 1. Purpose

Define the first large playable Hub blockout that begins exactly where Awakening / The First Return ends and carries the player through the first persistent civic set to:

- the Road of Witnesses continuation;
- the Ashen Forum;
- one west Sepulcher loop;
- a north Archive Rise;
- a Crown Transfer branch to Twin Solaria;
- a physical campaign-deployment wing;
- the ordinary Continuity Port that will later hand off into the procgen CampaignRegion runtime.

This is the second half of the first playable flow. It does not replace Awakening sections 01-10 and does not make Twin Solaria the ordinary Contract ingress.

---

## 2. Source-Derived Locks

These are current repository facts, not new layout invention.

### Awakening handoff

Awakening section 10 translates the current Road prototype by:

```text
ROAD_WORLD_OFFSET      (6,-6626)
ROAD_LOCAL_SOUTH_ENTRY (-6,482)
ROAD_WORLD_SOUTH_ENTRY (0,-6144)
South Reach completion world center (0,-6464)
South Reach barrier world y -6530
```

Therefore the equivalent Road-local completion position is:

```text
(-6,162)
```

The Hub first-set scene uses the Road prototype's local coordinate system so its existing five production module plates can be reused without resampling or a second translation.

### Existing Road module registration

```text
south_reach_civic_axis   center (0,34)      size 768x896
witness_plaza            center (0,-862)    size 896x896
collapsed_chapel_court   center (-832,-862) size 768x896
overgrown_reliquary_east center (832,-862)  size 896x896
archive_ruin_west        center (-832,-1820) size 896x896
```

The current Road prototype's presentation footprint is materially larger than its legacy central collision footprint. In the Hub first-set runtime, these plates are presentation, while the new first-set layout owns traversal/collision/navigation.

### Canonical Hub topology

The Road is the dominant ceremonial axis. The Ashen Forum is the civic/scenario-surfacing center. Archive Heights lie north. Twin Solaria is a detached Crown Annex reached by Crown Transfer, not by ordinary street. Continuity Ports are the ordinary verified transit/logistics infrastructure.

---

## 3. Design Decision: replace "Field Terminal as destination"

The first-set blockout does **not** route the player to a free-standing Field Terminal as the destination.

Instead:

1. **Ashen Forum / Adjudication Dais** is where a Contract proposal becomes actionable.
2. **Muster Court** is the embodied deployment/preparation destination.
3. The actual world threshold is an ordinary **Continuity Port** at the east end of Muster Court.

A terminal may remain as a witness/status console inside the Forum or Muster Court, but it is an interface embedded in the architecture rather than the place the player walks to.

This better matches current Hub canon: the Hub is an archive/tribunal/decision engine, while Continuity Ports are physical transit and logistics infrastructure.

---

## 4. Coordinate System

Use Road-local coordinates for the complete first-set blockout.

```text
+X east
-X west
+Y south
-Y north
base authored cell: 32 px
```

### World bounds

```text
Rect2(-2816,-5504,6016,6080)
```

Equivalent grid:

```text
origin world: (-2816,-5504)
map size: 188 x 190 cells
cell size: 32 px
```

This keeps the existing Road south entry at `(-6,482)` inside the bounds and provides a northern/eastern first-set expansion without pretending to build the full ~1 km Hub.

---

## 5. First-Set Spatial Plan

### A. Existing Road / South Reach complex

Reuse the current five Road production module pairs at their existing local positions.

Runtime handoff spawn:

```text
Spawn_SouthReach = (-6,162)
```

This is the current Awakening completion point transformed into Road-local coordinates.

Do not carry the Awakening-only collapsed north barricade into the Hub scene.

### B. North Processional

```text
envelope: Rect2(-512,-2400,1024,1152)
center:   (0,-1824)
grid:     Rect2i(72,97,32,36)
```

Purpose:

- extend the Road north from Witness Plaza;
- create the first long civic-axis read;
- frame the Forum reveal;
- give Archive Ruin West a meaningful side relationship rather than leaving it as a detached image.

The envelope overlaps the current Witness Plaza presentation by ~62 px at its south edge. This is a blockout/traversal overlap, not a new raster-art contract.

### C. Ashen Forum

```text
envelope: Rect2(-1280,-4032,2560,1792)
center:   (0,-3136)
grid:     Rect2i(48,46,80,56)
```

Purpose:

- first civic heart;
- scenario/Contract surfacing;
- historical focal point;
- major branch junction.

Blockout landmarks:

```text
Adjudication Dais      (0,-3136)
Forum South Marker     (0,-2464)
Forum North Marker     (0,-3904)
West Garden Threshold  (-1280,-3200)
East Muster Threshold  (1280,-3104)
```

The central dais is presentation/interaction space, not a mandatory giant collision disk.

### D. Sepulcher Gardens first loop

```text
envelope: Rect2(-2560,-3904,1152,1408)
center:   (-1984,-3200)
grid:     Rect2i(8,50,36,44)

north connector: Rect2(-1408,-3328,128,256)
north connector grid: Rect2i(44,68,4,8)

south connector: Rect2(-1408,-2784,128,256)
south connector grid: Rect2i(44,85,4,8)
```

Purpose:

- first life-vs-ruin side loop;
- proves the Hub is not one hallway;
- forms a literal circulation loop with two separated Forum connections;
- lets the player enter through either connector and leave through the other without retracing the same neck.

No finished wildlife/population work in this blockout slice.

### E. Lower Archive Rise

```text
envelope: Rect2(-704,-5216,1408,1280)
center:   (0,-4576)
grid:     Rect2i(66,9,44,40)
```

Purpose:

- first northward climb into Archive identity;
- vertical/monumental staging;
- parent branch for Twin Solaria access.

It overlaps the Forum's north edge by 96 px, preserving continuous traversal while letting future art author stairs/terraces.

### F. Crown Transfer Court

```text
envelope: Rect2(704,-5056,768,768)
center:   (1088,-4672)
grid:     Rect2i(110,14,24,24)
```

Markers:

```text
CrownTransfer           (1088,-4672)
Spawn_TwinReturn        (864,-4672)
```

Purpose:

- visible/physical Hub access point for the detached Twin Solaria annex;
- later route traversal enters `hub_twin_solaria` at `Spawn_CrownCauseway`;
- return lands at `Spawn_TwinReturn`.

This court does not visually or physically extend a street into Twin Solaria. The transfer is a world/route handoff.

### G. Muster Court

```text
envelope: Rect2(1408,-3712,1088,1408)
center:   (1952,-3008)
grid:     Rect2i(132,56,34,44)
connector: Rect2(1280,-3264,128,320)
connector grid: Rect2i(128,70,4,10)
```

Markers:

```text
MusterEntry             (1472,-3008)
MusterCenter            (1952,-3008)
```

Purpose:

- embodied departure/preparation space;
- separates "we chose a Contract" from "we are leaving now";
- staging ground for loadout/ready checks later;
- makes deployment feel like departure from home rather than clicking a menu.

### H. Continuity Port Chamber

```text
envelope: Rect2(2496,-3456,704,896)
center:   (2848,-3008)
grid:     Rect2i(166,64,22,28)
```

Markers:

```text
Spawn_CampaignReturn    (2592,-3008)
ContinuityPort          (2944,-3008)
CampaignExitThreshold   (3136,-3008)
```

Suggested threshold volume:

```text
Rect2(3104,-3072,96,128)
```

Purpose:

- physical final ingress from Hub into the first CampaignRegion;
- consumes an already selected/prewarmed Contract;
- later transition enters the existing `game.tscn` Contract runtime shell.

The port does not generate the world itself.

`Spawn_CampaignReturn` is the west return bay inside the Continuity Port chamber, not a Muster Court marker. A completed campaign therefore returns through the same physical transit infrastructure used for departure.

---

## 6. First-Set Topology

```text
                                  [CROWN TRANSFER]
                                        |
                                  [TWIN SOLARIA]
                                        ^
                                        |
                              +-- CROWN TRANSFER COURT
                              |
                        [LOWER ARCHIVE RISE]
                              |
                              |
[SEPULCHER GARDENS] -- [ASHEN FORUM] -- [MUSTER COURT] -- [CONTINUITY PORT]
        |                    |                 |                  |
        +--------------------+                 |                  v
                              |                 |          PROCGEN CAMPAIGN
                        NORTH PROCESSIONAL      |             REGION
                              |                 |
                        WITNESS PLAZA ----------+
                              |
                         SOUTH REACH
                              ^
                              |
                      AWAKENING COMPLETE
```

The east line from Witness Plaza to Muster is conceptual circulation, not a second direct bypass around the Forum. The Forum remains the decision junction.

---

## 7. Runtime Ownership

### Spatial authority

Create one data/layout authority:

```text
custodian/game/world/hub/first_set/hub_first_set_layout.gd
```

It owns:

- world bounds;
- walkable regions;
- blockout visual regions;
- connectors;
- markers;
- branch identity;
- named spawn positions.

It does not own campaign selection, Twin route state, or world transitions.

### Blockout runtime

Use the existing generic authored blockout foundation:

```text
AuthoredBlockoutGrid2D
AuthoredNavigationProvider2D
```

Preferred files:

```text
custodian/game/world/hub/first_set/hub_first_set_map.gd
custodian/game/world/hub/first_set/hub_first_set_map.tscn
custodian/scenes/hub_first_set_blockout_playtest.tscn
```

The map scene must contain no permanent player/camera ownership assumptions. The standalone playtest wrapper may supply them.

### Road presentation reuse

Instance the current Road of Witnesses prototype/module presentation at local origin.

In this Hub map:

- Road module art may remain visible;
- the Road prototype's existing legacy `CollisionRoot` must not become a competing traversal authority;
- the first-set layout/grid owns blockout collision/navigation;
- do not duplicate the five Road plate coordinates.

The Awakening scene may continue using its current Road collision adapter until its own migration says otherwise.

---

## 8. Blockout Walkability

Use 32px-grid walkable regions. The exact visual module bounds do not have to equal collision cell bounds.

Minimum walkable regions should include:

- central South Reach / Witness route;
- the current side courts sufficiently to enter/exit them;
- North Processional;
- Forum;
- Sepulcher loop + both Forum connectors;
- Archive Rise;
- Crown Transfer Court;
- Muster Court + connector;
- Continuity Port chamber.

Every mandatory route must retain at least 128 px / 4 cells of clear width.

The primary civic axis should normally read 320-640 px wide rather than as a 128px corridor.

---

## 9. First-Playable Interaction Flow

This design fixes spatial placement only; later slices own the interactions.

Target sequence:

```text
Awakening complete
→ Spawn_SouthReach
→ Road / Witness Plaza
→ North Processional
→ Ashen Forum
→ Adjudication Dais surfaces/selects provisional Contract
→ WorldContractBootstrap.ensure_started(seed)
→ optional Hub exploration / Twin visit while generation continues
→ Muster Court
→ Continuity Port
→ READY: deploy
→ GENERATING: wait/interstitial at port
→ FAILED: remain in Hub, expose retry
→ game.tscn
→ existing WorldContractProxy
→ same persistent bootstrap contract
→ ContractWorldLoader
→ procgen CampaignRegion
```

Twin route:

```text
Forum
→ Archive Rise
→ Crown Transfer Court
→ hub_twin_solaria / Spawn_CrownCauseway
→ return to Spawn_TwinReturn
```

---

## 10. Why Muster Court Replaces Field Terminal As Destination

The current Field Terminal script can remain useful as a witness/status surface. It already expresses "ESTABLISH WITNESS" and terminal access.

But walking to a 48px computer as the climax of the Hub introduction undersells the setting.

Muster Court makes three different things physically legible:

1. **Forum:** decide whether an intervention should happen.
2. **Muster:** prepare/commit to leave.
3. **Continuity Port:** actually cross contexts.

That separation also gives the Contract generator useful time to prewarm between selection and deployment.

---

## 11. Future Art / Asset Families

No new raster art is required for the blockout implementation slice.

When production art begins, use Asset Pipeline V2 and create families only after the blockout is reviewed. Recommended family boundaries:

```text
hub_first_set_north_processional_environment
hub_first_set_ashen_forum_environment
hub_first_set_sepulcher_gardens_environment
hub_first_set_archive_rise_environment
hub_first_set_crown_transfer_environment
hub_first_set_muster_court_environment
hub_first_set_continuity_port_environment
```

Suggested source-work roots:

```text
custodian/asset_drop/source_work/hub/first_set/<family>/
```

Suggested normalized inbox roots:

```text
custodian/asset_drop/inbox/<family>/
```

Do not create these families during blockout work merely to reserve names.

---

## 12. Documentation Drift

Implementation should reconcile these current mismatches:

1. `HUB_SPATIAL_LAYOUT.md` still describes the Road prototype as one authored map image; live presentation uses five modular plate pairs.
2. The same doc still describes the old Twin backdrop preview as lacking authored internal traversal; production `hub_twin_solaria` now exists as an authored level.
3. Its "First Playable Slice" begins at Gate of Dust / Custodian Approach, which Awakening already owns. The Hub first playable now begins at South Reach.
4. `CONTEXT.md` still describes the next Hub milestone as introducing the Field Terminal as a destination. Replace that with Forum adjudication + Muster Court + ordinary Continuity Port.
5. Older campaign/integration prose may still use terminal-first examples. Preserve terminal capability but stop treating it as the embodied world destination.

---

## 13. Implementation Slices

The durable implementation tracker is `HUB_FIRST_SET_IMPLEMENTATION_ROADMAP.md`. It owns H1-H7 packet status, dependencies, refresh gates, and program progress; this document remains the behavioral/spatial authority.

### H1 — First Set Blockout

Build this document's complete spatial blockout and standalone playtest. No campaign/Twin transitions.

### H2 — Awakening → Hub Context Handoff

Consume the reviewed `awakening_completed` seam and enter the Hub runtime at `Spawn_SouthReach`.

### H3 — Forum Adjudication + Contract Prewarm

Surface/select the first provisional Contract at the Adjudication Dais and start exactly one persistent `WorldContractBootstrap` generation.

### H4 — Crown Transfer → Twin Solaria

Wire Crown Transfer to `hub_twin_solaria / Spawn_CrownCauseway` and return to `Spawn_TwinReturn`.

### H5 — Muster Court + Continuity Port Deployment

Wire deployment state to the existing prewarmed Contract and enter `game.tscn` without duplicate generation.

### H6 — Campaign Return To Hub

Apply outcome exactly once, destroy disposable CampaignRegion runtime, restore Hub, and spawn at `Spawn_CampaignReturn`.

### H7 — First Set Integration Closeout

Prove:

```text
boot
→ full Awakening
→ Hub South Reach
→ Forum
→ optional Twin visit + return
→ Contract selection
→ Muster/Port deployment
→ procgen CampaignRegion
→ outcome/return
→ Hub
```

---

## 14. Deferred

- full Archive Heights;
- Memory Bastions;
- Reliquary Ward production district;
- Sunken Civic;
- Prism Margin / Long Edge;
- final Forum/Muster/Port art;
- NPC population;
- final Hub lighting/audio;
- campaign persistence/save integration beyond the first runtime loop;
- Crown-class Passage restoration.
