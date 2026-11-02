# Awakening — Dust Lung V2 Asset Manifest + Generation Prompts

Status: **active production manifest / source art pending review**  
Design authority: `design/04_architecture/AWAKENING_DUST_LUNG_V2.md`  
Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d

## 1. Asset Pipeline V2 family

Proposed family:

```yaml
schema: custodian.asset_family.v2
id: awakening_dust_lung_environment_v2
kind: backdrop
priority: P0
runtime:
  domain: levels/awakening/05_dust_lung_v2
  owner: awakening_dust_lung_v2
direction_policy: omni
auto_mirror: false
```

This manifest is the planning/source contract. Do not hand-copy generated art
into `custodian/content/`. Asset Pipeline V2 owns normalization, canonical
runtime filenames, publication and catalog evidence.

### Source and inbox naming

Every new/unprocessed source master must be preserved under:

```text
custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/<state>_source.png
```

Every normalized candidate handed to Asset V2 must use:

```text
custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/<state>.png
```

Future registered family schema:

```text
custodian/content/metadata/assets/families/awakening_dust_lung_environment_v2.asset.json
```

Do not register the family until the required source states below have been
generated, composition-reviewed, and their actual normalization canvases are
confirmed.

## 2. Global visual lock

All Dust Lung V2 generation must follow the accepted V2 identity:

- top-down / high aerial-oblique gameplay environment art compatible with the
  current Awakening camera;
- monumental dry cistern / pressure-infrastructure complex, not a single room;
- cold charcoal masonry, oil-dark/rusted pipe iron, chalky mineral residue,
  ashen sediment, interrupted aged brass institutional linework;
- sparse cyan/teal service lamps used primarily as scale markers;
- diluted pale-blue light and haze deep in shafts;
- architecture should feel ancient, overbuilt, partially collapsed, and still
  structurally legible;
- clear distinction between broad **playable deck/floor** and inaccessible
  catwalks / broken platforms / hard void;
- no characters, creatures, UI, labels, arrows, text, loot, or baked interaction
  prompts;
- no giant central arena composition;
- no clean symmetric ceremonial chamber;
- no horizon line;
- no opaque black rectangular matte unless that black is actual deep shaft
  interior inside the painted architecture;
- no fake doors/exits that compete with the authored Locker or Undergate route;
- no full-scene vignette; runtime lighting remains authoritative.

The current generated Dust Lung plates in the Authoring chat are the style and
material reference. New art should preserve that visual family while improving
gameplay registration and route legibility.

## 3. Generation tiers

### Required P0 underlays

1. `north_upper_works`
2. `central_broken_service_spine`
3. `western_lift_spine`
4. `cistern_core`
5. `deep_cistern_field`
6. `south_ingress_transition`

### Required P0 connective overlays

7. `service_route_splice_lower`
8. `lift_station_transition_upper`

### Recommended P1 connective / atmosphere

9. `ingress_rubble_blend`
10. `distant_pipe_gallery`
11. `daylight_rupture_overlay`

The six underlays define the main visual geography. The RGBA overlays exist only
to repair real seams after placement; do not proliferate connector art if the
major plates already register cleanly.

## 4. State contracts + prompts

---

## 4.1 `north_upper_works`

**Tier:** required P0  
**Kind:** backdrop / underlay  
**Target source canvas:** **2048×1024**, 1 frame  
**Alpha:** opaque within the intended underlay footprint; no external matte
requirement because this is a base plate  
**Runtime role:** upper lift landing → Undergate compression  
**Playable requirement:** one broad central/northbound service route with
unambiguous floor edges; no alternate intact route around the cistern  
**Reference geography:** top/north of the 1536×2048 V2 planning composition

**Save as source:**
```text
custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/north_upper_works_source.png
```

**Inbox:**
```text
custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/north_upper_works.png
```

**Generation prompt:**

> Create one high-resolution **2048×1024 top-down / high aerial-oblique game
> environment underlay** for CUSTODIAN's Awakening, Dust Lung Cistern V2:
> **North Upper Works**. This is the surviving upper cistern service deck that
> receives the player after a western maintenance lift and compresses northward
> into the Undergate. Preserve the accepted Dust Lung material language:
> cold charcoal masonry, oil-dark pipe iron, rust, chalky mineral residue,
> ashen sediment, broken aged-brass institutional linework, sparse cyan service
> lamps, pale-blue abyssal haze below. Compose a **broad, clearly playable
> central route** entering from the lower-left / west-central side and turning
> north into one unmistakable top-center exit throat. The walkable deck must be
> wide enough to read as normal gameplay floor, with continuous floor texture,
> edge curbs, grates and safe staging space. To either side, show enormous
> inaccessible cistern depth, pipe banks, broken maintenance balconies and
> distant rings. The route should become more ordered and mechanically dense as
> it approaches the north exit, foreshadowing Undergate routeworks. Do not place
> a second usable exit. Do not make the room symmetrical or ceremonial. No
> characters, text, UI, arrows or interaction prompts. No horizon. One static
> frame.

---

## 4.2 `central_broken_service_spine`

**Tier:** required P0  
**Kind:** backdrop / underlay  
**Target source canvas:** **1536×2048**, 1 frame  
**Runtime role:** main lower traversal / broken route spine  
**Playable requirement:** broad lower route enters from the east/southeast and
travels west toward the lift; damaged scenery must not create equally plausible
alternate routes  
**Reference route band:** planning reference x ≈ 313..863, y ≈ 825..950

**Source:**
```text
custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/central_broken_service_spine_source.png
```

**Inbox:**
```text
custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/central_broken_service_spine.png
```

**Generation prompt:**

> Create one high-resolution **1536×2048 top-down / high aerial-oblique game
> underlay** for CUSTODIAN Awakening's **Dust Lung V2 Central Broken Service
> Spine**. This plate carries the primary lower traversal after the player sees
> the vast cistern rupture. The main readable floor must enter from the
> **right/east-lower side**, continue **west across the lower-middle of the
> image**, then narrow toward a western maintenance-lift approach. Make the
> canonical route broad, continuous and unmistakably walkable, with old
> institutional paving, service grates, interrupted brass route lines, broken
> railings and accumulated dust. Surround it with collapsed bridge fragments,
> snapped pipe galleries, inaccessible maintenance ledges and deep pale-blue
> shaft void. Show the remains of an **obvious former/direct route that has
> failed**, so the surviving westbound route feels like an improvised detour.
> Distant catwalks must be visibly broken, narrow, disconnected or below the
> playable elevation so they do not promise traversal. Materials: charcoal
> stone, blackened/rusted iron, mineral crust, ash, aged brass, sparse cyan
> service lamps. Avoid symmetry, arena framing and decorative central-hole
> composition. No characters, labels, UI, arrows or prompts. One static frame.

---

## 4.3 `western_lift_spine`

**Tier:** required P0  
**Kind:** backdrop / underlay  
**Target source canvas:** **1024×1536**, 1 frame  
**Runtime role:** vertical traversal bridge between lower service spine and north
upper works  
**Playable requirement:** readable lower station, vertical lift machine, and
upper receiving landing; enough empty floor for separate runtime lift/lever
sprites  
**Reference lift bands:** lower station x ≈ 366..507 / y ≈ 796..895; shaft
x ≈ 271..358 / y ≈ 529..805; upper landing x ≈ 216..358 / y ≈ 461..563 in the
planning composite

**Source:**
```text
custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/western_lift_spine_source.png
```

**Inbox:**
```text
custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/western_lift_spine.png
```

**Generation prompt:**

> Create one high-resolution **1024×1536 top-down / high aerial-oblique
> environment underlay** for CUSTODIAN Awakening's **Dust Lung V2 Western
> Service Lift Spine**. This is not a clean elevator room. It is a stubborn,
> half-ruined vertical maintenance mechanism bridging two surviving decks over
> an enormous dry cistern. At the **lower-right / lower-center**, provide a broad
> intact service landing that connects naturally to the westbound lower route.
> Leave a clear rectangular interaction pad where the separate runtime lift and
> lever can be placed. Through the center-left, show a tall vertical lift
> apparatus: heavy rails, cable drums, counterweight tracks, exposed chains,
> guide frames, pipe trunks, maintenance brackets and sparse cyan service lamps.
> At the **upper-left / upper-center**, provide a second broad safe landing that
> connects toward the north upper works. The lower and upper floors must be
> visually distinct elevations connected by the machine, not by an ordinary
> staircase that bypasses the lift. Surround the machinery with hard void,
> ruined inaccessible platforms and deep pale-blue industrial haze. Preserve
> cold charcoal masonry, oil-dark/rusted iron, chalky mineral residue, ashen
> dust, interrupted aged brass linework. Do **not** bake a character, lever,
> usable console, text, arrows or UI into the plate. One static frame.

---

## 4.4 `cistern_core`

**Tier:** required P0  
**Kind:** backdrop / underlay  
**Target source canvas:** **2048×2048**, 1 frame  
**Runtime role:** dominant lower rupture / first-scale vista  
**Playable requirement:** only bounded rim/landing floor where specified by
composition; most of the image is hard scenic depth

**Source:**
```text
custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/cistern_core_source.png
```

**Inbox:**
```text
custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/cistern_core.png
```

**Generation prompt:**

> Create one high-resolution **2048×2048 top-down / high aerial-oblique hero
> underlay** for CUSTODIAN Awakening's **Dust Lung V2 Cistern Core**. Depict a
> colossal dry civic-industrial reservoir rupture that extends far below the
> playable route. The center and majority of the plate are **hard void /
> inaccessible depth**, with multiple descending maintenance rings, enormous
> vertical pipe banks, dead intake trunks, mineral tide marks, fractured
> galleries, tiny cyan service lights and pale-blue haze establishing immense
> scale. Around only selected edges, include broad surviving deck/rim fragments
> suitable for composition with adjacent playable plates. Those floor fragments
> must have clear curb/edge treatment and must not imply a complete ring around
> the shaft. Show evidence that this was once ordered institutional
> infrastructure: aged brass route inlays, repeated structural ribs and service
> lamps, now interrupted by collapse, ash and mineral deposits. Avoid a clean
> octagonal arena, perfect symmetry, or a single neat hole surrounded by a
> complete room. No characters, text, UI, arrows, prompts or horizon. One static
> frame.

---

## 4.5 `deep_cistern_field`

**Tier:** required P0  
**Kind:** backdrop / deep scenic underlay  
**Target source canvas:** **2048×2048**, 1 frame  
**Runtime role:** lowest scenic depth owner beneath overlapping plates  
**Playable requirement:** **none**; any visible decks must be clearly distant or
broken and not resemble current-elevation gameplay floor

**Source:**
```text
custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/deep_cistern_field_source.png
```

**Inbox:**
```text
custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/deep_cistern_field.png
```

**Generation prompt:**

> Create one high-resolution **2048×2048 top-down / high aerial-oblique deep
> background underlay** for CUSTODIAN Awakening's **Dust Lung V2 Deep Cistern
> Field**. This plate owns unreachable depth beneath the playable structures.
> Fill it with enormous descending reservoir walls, multiple far-lower
> maintenance rings, distant pipe trunks, broken suspended galleries, tiny cyan
> service lamps, mineral-stained masonry and pale-blue particulate haze. The
> composition must feel **hundreds of feet below the player**. Any catwalks or
> platforms visible here must be narrow, distant, interrupted, shadowed or
> obviously disconnected; do not paint broad current-elevation walkable floor.
> Values and brass detail should be more subdued than foreground/gameplay
> plates so this reads behind them. No characters, text, UI, prompts, arrows,
> horizon or close foreground framing. One static frame.

---

## 4.6 `south_ingress_transition`

**Tier:** required P0  
**Kind:** backdrop / underlay  
**Target source canvas:** **2048×1024**, 1 frame  
**Runtime role:** Locker Reliquary → Dust Lung visual handoff  
**Playable requirement:** broad lower/southeastern entry platform that feeds the
main broken service route

**Source:**
```text
custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/south_ingress_transition_source.png
```

**Inbox:**
```text
custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/south_ingress_transition.png
```

**Generation prompt:**

> Create one high-resolution **2048×1024 top-down / high aerial-oblique game
> underlay** for CUSTODIAN Awakening's **Dust Lung V2 South Ingress
> Transition**, immediately after Locker Reliquary. The lower/southeastern edge
> should retain some of Locker's disciplined institutional ancestry: intact
> heavy deck plates, consistent service grates, ordered brass linework, robust
> wall massing and controlled cyan fixtures. Moving inward/upward toward Dust
> Lung, progressively break that order: interrupted brass traces, cracked slabs,
> torn railing, thicker exposed pipework, mineral deposits, ash, fractured edge
> masonry and widening pale-blue cistern void. Provide one **broad, continuous
> playable entry platform** that naturally hands the player into the lower
> broken service route. The transition should feel like the same institution
> physically failing, not an abrupt tileset swap. Do not create a second exit or
> a clean ceremonial room. No characters, text, UI, arrows or prompts. One
> static frame.

---

## 4.7 `service_route_splice_lower`

**Tier:** required P0  
**Kind:** connector overlay  
**Target source canvas:** **1024×768**, 1 frame  
**Alpha:** true RGBA outside architecture  
**Runtime role:** repair S1 lower critical-route join after underlay registration

**Source:**
```text
custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/service_route_splice_lower_source.png
```

**Inbox:**
```text
custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/service_route_splice_lower.png
```

**Generation prompt:**

> Create one **1024×768 transparent RGBA top-down / aerial-oblique connector
> overlay** for Dust Lung V2. It must bridge two already-authored damaged service
> decks on the critical lower route. Compose a broad fractured but continuous
> walkable floor strip with matching charcoal industrial paving, service grates,
> interrupted aged-brass route inlay, rubble and one or two damaged rail
> fragments. Outside the actual floor/edge architecture, preserve **true
> transparency** so underlying cistern depth remains visible. The connector
> should look repaired only by survival, not intentionally rebuilt. Do not add a
> door, console, character, sign or alternate route. One static frame.

This state should be generated **after** exact plate registration so the prompt
can include seam crops/reference images if necessary.

---

## 4.8 `lift_station_transition_upper`

**Tier:** required P0  
**Kind:** connector overlay  
**Target source canvas:** **1024×768**, 1 frame  
**Alpha:** true RGBA outside architecture  
**Runtime role:** repair upper lift landing → north upper works seam

**Source:**
```text
custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/lift_station_transition_upper_source.png
```

**Inbox:**
```text
custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/lift_station_transition_upper.png
```

**Generation prompt:**

> Create one **1024×768 transparent RGBA top-down / aerial-oblique connector
> overlay** for the **upper western lift landing** in Dust Lung V2. Join a
> battered maintenance-lift platform into the more ordered north upper
> routeworks. The floor must remain broad and clearly walkable, with structural
> brackets, grates, interrupted brass routing and a few damaged edge rails.
> Allow the material language to become slightly denser and more institutional
> toward the north, foreshadowing Undergate. Preserve true transparency outside
> the connector structure so deep cistern art remains visible below. No
> characters, text, UI, lever, console or alternate route. One static frame.

Generate only after the registered lift and north-works placement is known.

---

## 4.9 `ingress_rubble_blend`

**Tier:** recommended P1  
**Kind:** connector/detail overlay  
**Target source canvas:** **1024×512**, 1 frame  
**Alpha:** true RGBA  
**Runtime role:** soften S4 Locker-side material transition only if lighting and
major plates do not already solve it

**Generation prompt:**

> Create one **1024×512 transparent RGBA transition overlay** for the
> Locker-Reliquary-to-Dust-Lung handoff. Use broken service grates, fractured
> charcoal masonry, severed brass route strips, chalky dust, pipe fragments and
> small rubble to move from intact institutional floor into ruptured cistern
> infrastructure. Keep the central walkable lane visually clear. Irregular
> alpha silhouette only; no full rectangular matte, no new door, no character,
> no text.

---

## 4.10 `distant_pipe_gallery`

**Tier:** recommended P1  
**Kind:** scenic backdrop insert  
**Target source canvas:** **1536×768**, 1 frame  
**Alpha:** true RGBA around silhouette  
**Runtime role:** optional inaccessible support for large camera-visible gaps

**Generation prompt:**

> Create one **1536×768 transparent RGBA distant-architecture silhouette** for
> Dust Lung V2: suspended broken pipe galleries, reservoir ribs, tiny
> maintenance decks and cable runs hanging across deep pale-blue haze. It must
> read as inaccessible background several structural levels away, with reduced
> contrast and no broad walkable deck. Match the cold charcoal / oil-dark iron /
> aged brass / sparse cyan service-light family. No doors, characters, text or
> gameplay affordances.

---

## 4.11 `daylight_rupture_overlay`

**Tier:** recommended P1  
**Kind:** scenic/lighting-support overlay  
**Target source canvas:** **1024×1024**, 1 frame  
**Alpha:** true RGBA outside broken structural silhouette  
**Runtime role:** visually establish the `daylight_split` landmark without
taking lighting authority

**Generation prompt:**

> Create one **1024×1024 transparent RGBA structural-rupture overlay** for Dust
> Lung V2's `daylight_split` landmark. Show a torn cistern wall / pipe-gallery
> breach with fractured masonry, exposed structural ribs, mineral deposits and
> pale desaturated exterior light visible through the opening. The asset should
> provide the broken silhouette only; do not paint a full-screen light beam or
> vignette because Godot WorldLightingDirector owns illumination. No usable
> doorway, no character, no text, no UI. One static frame.

## 5. Interactive assets are separate

Do not bake the critical interaction itself into these underlays.

Existing / separately presented gameplay assets should remain independent where
possible:

- `awakening_dust_lung_lift`;
- `awakening_dust_lung_structures/lift_lever`;
- any future interaction beacon/affordance presentation.

The underlays provide the **machine environment and clear station pads**. Runtime
props provide the thing the player actually interacts with.

## 6. Generation and review order

Generate and review in this order:

```text
1 north_upper_works
2 central_broken_service_spine
3 western_lift_spine
4 south_ingress_transition
5 cistern_core
6 deep_cistern_field

→ compose at planning scale
→ verify main route / western lift / Undergate geography
→ register exact plate transforms

7 service_route_splice_lower
8 lift_station_transition_upper

→ generate only against exact registered seam crops

9-11 optional/recommended support only if camera coverage still needs them
```

Do not generate all optional support art preemptively.

## 7. Source acceptance before Asset V2 ingest

Each required source must pass:

- correct state identity and canvas/aspect contract;
- no characters/UI/text;
- no unexpected second route/exit;
- clear walkable vs inaccessible vs hard-void read;
- no nonuniform-stretch requirement to fit the layout;
- no source-edge architectural cutoff through a required connector;
- material/lighting family consistent with the accepted Dust Lung V2 plates;
- no opaque black exterior matte where alpha is required;
- no obvious duplicated hero motif across neighboring plates;
- no baked interaction object where runtime needs an independent prop.

The six major underlays require one composition-level human review before
normalization/ingest.

## 8. Runtime publication boundary

After the six required underlays are approved:

1. preserve immutable source masters under `source_work`;
2. finalize exact Asset V2 family canvas/state schema;
3. normalize to `asset_drop/inbox/awakening_dust_lung_environment_v2/`;
4. run Asset V2 plan/ingest/status/doctor;
5. only then author the DL0 runtime layout/collision cutover.

Generated source art alone does **not** authorize modifying
`awakening_layout.gd`.
