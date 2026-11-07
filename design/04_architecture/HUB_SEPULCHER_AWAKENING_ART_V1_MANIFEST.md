# CUSTODIAN · Hub, Sepulcher, Awakening and Dust Lung Artwork V2

**Status:** Complete expanded source-art roadmap; human source and production approval remain separate.
**Date:** 2026-11-03
**Program ID:** `hub-sepulcher-awakening-art-v1`
**Machine authority:** `design/04_architecture/HUB_SEPULCHER_AWAKENING_ART_V1_MANIFEST.json` (same program and file identity as original manifest)
**Chat URL:** not supplied; do not fabricate backlink.

## Master inventory

| Scope | Count |
|---|---:|
| Original core states, preserved | 72 |
| New core states | 126 |
| **Required core** | **198** |
| Existing optional states | 12 |
| New optional extras | 24 |
| **Optional sources** | **36** |
| **All individual source prompts** | **234** |
| **Ordered candidate-generation sets** | **193** |
| Original set IDs preserved | 67 |
| Proposed/registerable family IDs | 42 |

The intent is a full-art pipeline, from **flat ground**, through **water/shorelines and real masonry**, to **landmarks, interior presentation, local environmental storytelling**, then the **neighboring Hub, Awakening and Dust Lung** districts. Each source is separately identified and can be regenerated and reviewed independently. This is an artwork roadmap, not an automatic game/collision modification.

**Candidate cursor:** `CAL-02`; **human production source cursor:** `CAL-01`. The only verified completed candidate is CAL-01: SHA-256 `5bf414069ea9c70139fa0ffe5ceee3378e2c226f22fb76e8a55e46a7e14773d2`, Dropbox `id:8NXqdXuW6GUAAAAAAAAHEw` revision `65f57a8e1c486915cdd61`. **PASS_CANDIDATE is NOT human source approval.**

**CAL-02 design authorization:** D6 Root-choked Outer Arcade, one true-alpha 384x576 image at world origin `(-1824,-4096)`; clip structural pixels to existing D6 nonwalkable polygon; do not invent collision, stairs or an accessible room. The obsolete 1152x1408 mixed scene has been superseded. All other 197 core source authorizations remain pending individual image screening/production review.

**Existing paving V3 and earlier water/shoreline concepts:** Design/reference candidates only unless original source identity and explicit human approval receipt are verified. No unverified image conditioning or false Asset V2 readiness is asserted.

## Artistic and spatial doctrine

Large-scale burial-civic world, not generic haunted cemetery. Formal pale limestone and graphite basalt civic construction is slowly erased by collapsed architecture, ash, low sparse roots and quiet blackwater. Very little growth, no legible fake inscriptions, no brightly lit invented gates or theatrical vignette. A strict 90-degree overhead projection and consistent 32px construction units for Godot Hub sprites; no sprite adds navigation, collision, dynamic loot or interactions.

**Sepulcher runtime geometry:** 3072x2688 world-pixel authoring envelope at (-4128,-4480), 96x84 cells, nonrectangular walkable mask. Real artwork must respect D1-D7 obstacle/voids, P1-P8 walkable paths, L01-L10 landmarks, both east-facing 128px Gardens connectors, and the E0-E5 grave-event markers. The JSON geometry is called a human design draft despite its mask already being used by the game. That does NOT authorize new interior access, door or secret loot.

### Ten existing landmark anchors

| ID | Site | World center (x,y) | Zone |
|---|---|---|---|
| L01 | North Threshold Cloister | (-1376,-3296) | A |
| L02 | South Threshold Cloister | (-1376,-2752) | A |
| L03 | Cloister of Unreturned Names | (-1632,-3136) | A |
| L04 | Memorial Slab Court / grave | (-1984,-3200) | B |
| L05 | Bell-less Rotunda | (-2080,-3776) | C |
| L06 | Witness Pool | (-3040,-3584) | D |
| L07 | Twin Sarcophagus Terrace | (-3424,-3104) | D |
| L08 | Sunken Blackwater Basin | (-2624,-2464) | E |
| L09 | Rootbound Reliquary Nook | (-3392,-2176) | E |
| L10 | Pale Growth Orchard | (-1920,-2144) | E |

### Four fully specified interior ART complexes

| ID | Name | Binding | Gameplay authority |
|---|---|---|---|
| I01 | Root-choked Outer Arcade | D6 | NONWALKABLE_D6; CAL-02 locks only visual module |
| I02 | Closed Crypt Garden | D5 | NONWALKABLE_D5; no access, door or interaction authorized |
| I03 | Bell-less Rotunda Undercroft | L05 | INTERIOR_LAYOUT_AND_PORTAL_NOT_RUNTIME_AUTHORIZED; no invented entrance |
| I04 | Rootbound Reliquary | L09/S1 | EXISTING_RELIQUARY_NOOK_ACCESS_ONLY; sealed interior scene/secret rewards not authorized |

Each interior has its own floor/structural/occlusion visual states. D5 and D6 remain sealed/nonwalkable. The L05 and L09 complex artwork is preparatory presentation, **not** a claim that playable interior scenes, portals or secret pickup logic exist. Those require an independently approved runtime footprint and implementation.

### Three environmental storytelling languages

- **Registry:** Absent identities, empty name-sockets and minimal corroded bronze enumeration on approved masonry.
- **Erasure:** Sealed ossuary blocks, scrubbed ceremonial records and collapsed old administrative infrastructure.
- **Encroachment:** Sparse roots, pale orchard growth and two still blackwater basins invading civic masonry. No story element claims a quest, readable text or item grant.
- **Proposed hidden cues:** S1 reliquary arch slit, S2 pool-wall breach, S3 rotunda rubble, S4 sarcophagus flank, S5 orchard low screen. These are visual telegraphs only.

## Candidate and production pipeline

1. Codex sends only `GENERATE_ASSET`, `REVIEW_ASSET` or `UPLOAD_ASSET_TO_DROPBOX`, with the exact manifest set ID and existing asset ID.
2. Generate independent PNG source from the complete per-asset prompt, preserving reference-input provenance. Do NOT treat contact-sheet crops as independent production-approved masters.
3. Review actual visuals and byte evidence independently. For RGBA: report apparent transparency, matte/checkerboard and uncertainty; prove true alpha only from pixels. For RGB opaque: transparency is NOT APPLICABLE. Check native framing, clipping, scale, 3x3 repeats, geometry, edge registration and unexpected routes.
4. Only PASS_CANDIDATE images enter `/CUSTODIAN/candidate_staging/hub-sepulcher-awakening-art-v1`. Verify file name/path, bytes, SHA-256, Dropbox ID and revision. Candidate receipt advances candidate cursor, **never** human source approval.
5. Individually human-approved production source masters later move to the asset's exact `source_work_path`, with normalized derivatives to `inbox_path`, family schemas to `family_contract_path`, then Asset V2 doctor/ingest and Godot gameplay/128px Operator review.
6. The old 27 Awakening perimeter art states retain their registered family and source ownership; the eight existing Dust Lung V2 states still require the independent DL0 owner for actual placement/cutover. No optional state is generated automatically.

## Full-art production milestones

| Phase | Scope | Status | Validation gate |
|---|---|---|---|
| P00 | Authority and current coverage survey | DOCUMENTED | Audit current main, detect geometry drift, confirm 198 unique core/36 optional states without skipped IDs |
| P01 | CAL-A multi-region material calibration | CANDIDATE_IN_PROGRESS | Six independently screened calibration images, including CAL-01 opaque repeat tile, CAL-02 D6 modular structure, grave slab and three Awakening anchors; human source lock remains separate |
| P02 | Expanded Gardens walkable materials | NOT_STARTED | Five repeatable floor textures, byte-level RGB/alpha as specified, 3x3 seams and 128px Operator-scale readability; apply only through irregular live mask |
| P03 | Both pond material systems | NOT_STARTED | Seven water sprites/overlays; D3/D4 mask-only application, restrained sheen, real opacity/alpha checks and no walkability change |
| P04 | Complete modular shoreline and hard margins | NOT_STARTED | 20 shoreline+10 void states with join test for each neighboring profile and D1-D7 coverage, no alpha gaps, no accidental crossing |
| P05 | Ten Gardens landmarks | NOT_STARTED | 26 distinct registered visual assets cover L01-L10, visible monument silhouettes, P1-P8 clearance and no invented interactions |
| P06 | Four notable interior complexes | NOT_STARTED | Four 4-piece named visual suites I01 D6/I02 D5/I03 L05/I04 L09, with structural/ground/occlusion previews; actual accessible interior gameplay requires independent geometry approval |
| P07 | Gardens foliage, secrets, environmental storytelling | NOT_STARTED | 8 vegetation+10 S1-S5 cue sprites, authentic alpha, predictable low-density placement and no unapproved loot/doors |
| P08 | Existing Garden B1 and Forum connectors | LEGACY_REQUIRED | All historic Sepulcher B1 grave/dressing/connector candidates; real east connectors remain 128px clear, pixel contact tests once adjacent sources exist |
| P09 | Other Hub ground and civic architecture | LEGACY_AND_NEW | Six original non-Gardens Hub underlays revised floor-only, 12 independently staged structural overlays plus all original civic fixtures, actual anchors/collisions unchanged |
| P10 | Awakening perimeter and narrative support | LEGACY_AND_NEW | 27 existing registered AP support states plus six new offroute narrative props, never replacing nine already registered family owners |
| P11 | Dust Lung DL0 full environmental set | OWNER_DEPENDENT_CANDIDATE | Eight existing Dust Lung V2 independently authored images and six additional details; separate DL0 owner approves layer/source fit and cutover |
| P12 | Candidate quality completion | NOT_STARTED | All 198 PASS_CANDIDATE core images uploaded with exact file identities/hashes, raw generation preserved, no deferred candidates or partial grouped states; human approval still separate |
| P13 | Human production-source lock | NOT_STARTED | 198 explicit per-state human art decisions after actual full-size and gameplay-scale reviews, immutable sources, true RGB/RGBA and join/crop QA; no automatic promotion |
| P14 | Asset Pipeline V2 and in-engine registration | NOT_STARTED | Each human-approved family schema, normalized file, doctor/ingest evidence, Godot rendering and source/scene ownership verified without gameplay authority changes; 128px Operator comparisons, path occlusion, 3x3 tiling, D3/D4 and connector screenshots |
| P15 | Visual completeness audit and opt-in extra polish | NOT_STARTED | Full 198-state art coverage, no hero-scenery holes, four interior layouts visually coherent; separately opt-in to any of 36 optional sources, never use optional images as prerequisite for core completion |

## Complete 198-state required core inventory

All individual source prompts below are copied from the authoritative JSON entry, not rewritten summaries. Frame sizes, true-alpha requirements, geometry bindings, source/inbox paths and independent asset IDs remain explicit.


### CAL-A calibration

#### `hub_first_set_sepulcher_gardens_environment/underlay`

**Set:** `CAL-01`, order 1; **family:** `hub_first_set_sepulcher_gardens_environment`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, OPAQUE RGB, 512x512; transparency is not applicable to CAL-01.

**Generation prompt:** Generate EXACTLY ONE independent seamless 512x512 opaque RGB WALKABLE-GROUND-ONLY material tile for CUSTODIAN's expanded Sepulcher Gardens. Strict 90-degree orthographic overhead, world north up, one static frame, 32px architectural rhythm. Use the Sepulcher burial-civic material vocabulary of aged chalk-limestone, charcoal basalt and restrained oxidized bronze. Existing paving images, including the V3-named candidate, are UNAPPROVED material references only: the pilot manifest records source_approved=false and failed 3x3 repeat, and no authoritative human-approved V3 SHA/receipt has been verified. Do not claim any reference image was supplied or image-conditioned unless the exact source bytes and generator-use evidence are actually recorded. Flat old civic burial paving ONLY: worn chalk-limestone and charcoal basalt slabs, subdued grout, mineral dust, fine cracks, restrained irregular bronze floor indexing. Every edge and corner MUST join seamlessly under unrotated 3x3 repetition; deterministic quarter-turn rotation may supply variation but must not be required to hide bad seams. No distinctive recurring central emblem, artificial picture border, vignette, baked directional shadow, stone height transition, wall, column, slab monument, steps, pond, shoreline, flora, raised terrace, scenic void, overhang, objects, characters, readable writing, UI, logos or false path. The image is a REPEATABLE MATERIAL SOURCE, NOT A DISTRICT MAP OR FULL-SCENE 3072x2688 PAINTING. Runtime must repeat and clip this texture ONLY to the current SepulcherGardensGeometryV1 96x84 irregular walkable cell mask within world Rect2(-4128,-4480,3072,2688), and leave nonwalkable water/collapse/crypt cells untouched. Artwork does NOT own the mask, collision, routes, grave-event clearances or either preserved Forum connector. Candidate passes only after byte-level RGB/dimensions checks, actual edge/corner 3x3 test and visual assessment against the unapproved paving material reference, only when its exact source is available (never as human approval evidence); human approval remains separate.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_gardens_environment/underlay_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_gardens_environment/underlay.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_gardens_environment.asset.json`  
**Anchor/constraints:** Texture-grid origin world (-4128,-4480); repeat 512px at native scale, clip to SepulcherGardensGeometryV1's exact 96x84 walkable mask; artwork never authors mask/collision; Modular floor source only; repeat and clip to irregular walkable mask in current expanded Gardens (3072x2688 authoring envelope), preserving E0-E5 grave-event world anchors and both Forum connectors. No 1152x1408 rectangle; no pond, void or architectural paint.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation modular ground renderer; not yet registered or runtime-bound  
**Provenance:** CAL-01 modular geometry reconciliation 2026-11-02; design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json; AI_ART_GENERATION_REVIEW_PROTOCOL_V1.md  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_sepulcher_gardens_environment/structural_presentation`

**Set:** `CAL-02`, order 2; **family:** `hub_first_set_sepulcher_gardens_environment`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 384x576px total; 1 frame(s), 384x576px per frame, `copy`, TRUE RGBA; empty pixels outside D6 authorized structural silhouette; no baked floor, no background/checkerboard/matte.

**Generation prompt:** Produce EXACTLY ONE independent 384x576 one-frame true-RGBA architectural asset: CUSTODIAN Sepulcher Gardens Root-choked Outer Arcade D6, strictly vertical 90-degree orthographic overhead, north up, 32px geometry. Form a ruined institutional cloister along an irregular, tightly bounded nonwalkable wedge: pale weathered limestone crown/coping fragments, charcoal basalt piers, narrow oxidized-bronze registration lines, broken double arch foundations and a restrained root-bound seam. Use D6 source world polygon [(-1792,-4064),(-1632,-4032),(-1472,-3712),(-1568,-3552),(-1696,-3712)] within a 384x576 canvas registered at (-1824,-4096). Sprite art is a modular structural presentation, NOT a 1152x1408 full-Gardens plate, never a floor map. Keep exterior alpha truly 0, with no painted matte, checkerboard, shadow carpet, invented usable entrance or protrusion into walkable routes. No readable text, human, flowers, foliage carpet, UI, fake collision, invented room, roof perspective or isometric camera. Provide full object edges; renderer deterministically clips to authorized D6 polygon if needed after source normalization. Align material scale with the burial-civic weathering direction, not a claimed human-approved paving image. Candidate quality requires visual contour and byte alpha inspection; candidate staging is NOT production source approval.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_gardens_environment/structural_presentation_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_gardens_environment/structural_presentation.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_gardens_environment.asset.json`  
**Anchor/constraints:** SepulcherGardensGeometryV1 obstacle D6; world origin (-1824,-4096), 384x576 source canvas at 1 world px/image px, north up; D6 Root-choked Outer Arcade ONLY: 32px world-grid canvas origin (-1824,-4096), extent (-1824..-1440,-4096..-3520); clip masonry alpha to D6 world polygon [(-1792,-4064),(-1632,-4032),(-1472,-3712),(-1568,-3552),(-1696,-3712)] after normalization. Every visible solid is within currently nonwalkable D6. Preserve all walkable P1-P8 route cells, grave evidence clearances and both east connectors. No new collision or gameplay rooms.  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** User-approved CAL-02 D6 structural calibration 2026-11-03; design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json D6 and current live SepulcherGardensGeometryV1  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_sepulcher_grave_evidence_art/memorial_slab`

**Set:** `CAL-03`, order 3; **family:** `hub_sepulcher_grave_evidence_art`; **core:** yes; **kind:** world_prop; **priority:** P0.

**Target:** 160x96px total; 1 frame(s), 160x96px per frame, `copy`, isolated object PNG true RGBA, no floor or matte.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 160×96 pixels as a one-frame image. Singular low memorial slab with aged charcoal base, pale inset fractured limestone and bronze registration/date cutlines too abstract to read. The fixed CYCLE 184 date and contradictory records remain in interaction text, not visible etched identities. No living flowers or growth. isolated object PNG true RGBA, no floor or matte.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_sepulcher_grave_evidence_art/memorial_slab_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_sepulcher_grave_evidence_art/memorial_slab.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_sepulcher_grave_evidence_art.asset.json`  
**Anchor/constraints:** world (-1984,-3200); replace procedural rendering only; three readings, persistence, choice IDs and later-return growth gate remain unchanged  
**Consumer:** res://game/world/hub/events/sepulcher_grave/sepulcher_grave_evidence.gd  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** human-approved by the project owner; registered and runtime-verified. Dropbox source revision `65f4aa8f42035915cdd61`; source SHA-256 `349d642e74f246fc277993c5bfd46889795e3f771d7846e98daba9b031b2d028`; normalized SHA-256 `374235ea43ebad385df86b30cb1f7dfd27d330a10d50476955a1fce8b2248312`; Asset V2 job `job_20261107T070300Z_3d825703`. Runtime binding and production Hub smoke evidence are recorded in the installation workstream summary.

#### `awakening_creche_perimeter_support/structural_support`

**Set:** `CAL-04`, order 4; **family:** `awakening_creche_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, seamless repeat on all 4 edges.

**Generation prompt:** Produce one 512×512 pixel **seamless-tileable top-down foundation/rim texture** for Dormant Recovery Stacks in CUSTODIAN's Awakening. Compose seamless reinforced recovery-wing outer-wall foundations and maintenance slab skirts, regular bays with sparse broken inserts. Materials: charcoal graphite ceramic, oxidized brass ID trims, matte medical-industrial panels, cold pinprick status lamps. Every boundary repeats pixel-consistently; no standalone room center, no framing borders, no lighting vignette, no scenery implying a playable doorway. This is just the off-route lower architectural field beneath the existing Crèche of Answerless Names production underlay. 1 static frame, native scale, overhead orthographic.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_creche_perimeter_support/structural_support_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_creche_perimeter_support/structural_support.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_creche_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_gate_of_dust_perimeter_support/distant_structures`

**Set:** `CAL-05`, order 5; **family:** `awakening_gate_of_dust_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 1024x512px total; 1 frame(s), 1024x512px per frame, `copy`, genuine RGBA transparent outside irregular silhouette.

**Generation prompt:** Produce one 1024×512 pixel **top-down overhead ruined-architecture silhouette** for Ruined Threshold District. Depict fallen checkpoint terraces, collapsed buttress bridges, dislocated colossal statues and faint city silhouette through dust. Architecture: fortified threshold terraces, cracked defensive walls, collapsed causeway approaches and first hints of historical city. Materials: smoke-stained monumental limestone, dark civic basalt, tarnished bronze, ashen sand, rust-red dust. Make each ruined structure visibly inaccessible by collapse, masonry or void; arrange high-level masses with believable foundations and subdued distant values. Transparent RGBA outside irregular nonplayable structures, never an opaque rectangular full-canvas matte. This should suggest passage between institutional machinery and the scale of the old city, and sit fully behind established gameplay art. Preserve the existing east/west stair openings from the LIVE Gate plaza underlay; do not cover either with rubble or visually close an existing flight while its branch meaning is decided. Do not invent extra entrances beyond those already painted. Place architectural density in peripheral terraces and lateral distant city fragments, with deliberate transparent negative space around the existing centerline and canonical Gate hero. Never depict a second monumental central Gate, an opened Gate state, or a new traversable causeway. Reconcile depth, charcoal/brass palette, and tonal brightness against the real scene-bound 1536×768 Gate plaza underlay. One static isolated silhouette plate.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_gate_of_dust_perimeter_support/distant_structures_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_gate_of_dust_perimeter_support/distant_structures.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_gate_of_dust_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; do not seal real east/west Gate stairs; existing AP3 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_road_south_reach_perimeter_support/edge_transition`

**Set:** `CAL-06`, order 6; **family:** `awakening_road_south_reach_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, genuine RGBA transparent outside irregular silhouette.

**Generation prompt:** Produce a single 256×256 **transparent RGBA overhead edge-transition decal** for the off-route margin of Road of Witnesses: South Reach. Include collapsed street-side arcade fragment, cracked paving gutter and dusty debris marking inaccessible civic continuation. Follow the same existing top-down CUSTODIAN palette of worn dark civic basalt, sun-bleached limestone, dulled brass wayfinding, low dusty rust and grey haze. Irregular organically damaged silhouette and clean partially transparent erosion; subtle dark-to-haze visual falloff must not be baked as a solid square. It is a noninteractive support seam, not a corridor, gate or piece of playable ground. One static frame.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_road_south_reach_perimeter_support/edge_transition_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_road_south_reach_perimeter_support/edge_transition.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_road_south_reach_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.


### Gardens walkable ground

#### `hub_first_set_sepulcher_floor_materials_v2/quiet_chalk_limestone`

**Set:** `SG-GROUND-001`, order 7; **family:** `hub_first_set_sepulcher_floor_materials_v2`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, OPAQUE RGB, one frame, no transparency, no black or checkerboard borders.

**Generation prompt:** Create exactly ONE 512x512 one-frame opaque RGB CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_floor_materials_v2/quiet_chalk_limestone. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Small and medium ash-limestone slabs in quiet running bond, occasional charcoal insert, subtly varied abraded faces and thin bronze indexing only between some stones. Spatial authority: Gardens zones A/B, general walkable mask only. This is flat repeatable ground/water material; make every edge continuous, native 3x3 repeatable without rotating to conceal seams; no raised structures or collision-marking visual blocks. Placement safeguard: Flat level repeatable flooring across the irregular walkability mask; 3x3 joins required. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_floor_materials_v2/quiet_chalk_limestone_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_floor_materials_v2/quiet_chalk_limestone.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_floor_materials_v2.asset.json`  
**Anchor/constraints:** Spatial source: Gardens zones A/B, general walkable mask only. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Flat level repeatable flooring across the irregular walkability mask; 3x3 joins required. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_floor_materials_v2/civic_charcoal_register`

**Set:** `SG-GROUND-002`, order 8; **family:** `hub_first_set_sepulcher_floor_materials_v2`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, OPAQUE RGB, one frame, no transparency, no black or checkerboard borders.

**Generation prompt:** Create exactly ONE 512x512 one-frame opaque RGB CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_floor_materials_v2/civic_charcoal_register. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Dark graphite basalt pavers and thin worn brass register seams, fine chalk deposits, unremarkable scattered cracks. Spatial authority: Zones A/C and existing east civic connectors. This is flat repeatable ground/water material; make every edge continuous, native 3x3 repeatable without rotating to conceal seams; no raised structures or collision-marking visual blocks. Placement safeguard: No recognizable centered seal and no implied boundary to block a route. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_floor_materials_v2/civic_charcoal_register_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_floor_materials_v2/civic_charcoal_register.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_floor_materials_v2.asset.json`  
**Anchor/constraints:** Spatial source: Zones A/C and existing east civic connectors. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; No recognizable centered seal and no implied boundary to block a route. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_floor_materials_v2/memorial_court_worn`

**Set:** `SG-GROUND-003`, order 9; **family:** `hub_first_set_sepulcher_floor_materials_v2`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, OPAQUE RGB, one frame, no transparency, no black or checkerboard borders.

**Generation prompt:** Create exactly ONE 512x512 one-frame opaque RGB CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_floor_materials_v2/memorial_court_worn. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Pale institutional setting slabs rubbed smooth by centuries of readings, minimal charcoal aggregate grout, faint broken longitudinal indexing marks. Spatial authority: L04 Memorial Slab Court, world (-1984,-3200). This is flat repeatable ground/water material; make every edge continuous, native 3x3 repeatable without rotating to conceal seams; no raised structures or collision-marking visual blocks. Placement safeguard: Do not paint the active memorial slab or any of its interaction locations. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_floor_materials_v2/memorial_court_worn_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_floor_materials_v2/memorial_court_worn.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_floor_materials_v2.asset.json`  
**Anchor/constraints:** Spatial source: L04 Memorial Slab Court, world (-1984,-3200). Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Do not paint the active memorial slab or any of its interaction locations. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_floor_materials_v2/west_terrace_grit`

**Set:** `SG-GROUND-004`, order 10; **family:** `hub_first_set_sepulcher_floor_materials_v2`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, OPAQUE RGB, one frame, no transparency, no black or checkerboard borders.

**Generation prompt:** Create exactly ONE 512x512 one-frame opaque RGB CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_floor_materials_v2/west_terrace_grit. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Light compacted crushed burial stone in flat weathered rectangular edging, balanced grey fine grit and faded stone dust. Spatial authority: L07 Twin Sarcophagus Terrace and P3/P5 route contacts. This is flat repeatable ground/water material; make every edge continuous, native 3x3 repeatable without rotating to conceal seams; no raised structures or collision-marking visual blocks. Placement safeguard: No stairs, wall or walkability transition baked into the texture. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_floor_materials_v2/west_terrace_grit_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_floor_materials_v2/west_terrace_grit.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_floor_materials_v2.asset.json`  
**Anchor/constraints:** Spatial source: L07 Twin Sarcophagus Terrace and P3/P5 route contacts. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; No stairs, wall or walkability transition baked into the texture. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_floor_materials_v2/southern_orchard_path`

**Set:** `SG-GROUND-005`, order 11; **family:** `hub_first_set_sepulcher_floor_materials_v2`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, OPAQUE RGB, one frame, no transparency, no black or checkerboard borders.

**Generation prompt:** Create exactly ONE 512x512 one-frame opaque RGB CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_floor_materials_v2/southern_orchard_path. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Sparse flat limestone stepping pavers integrated with dark earth-stained mortar and very little moss, readable as existing historic walkway. Spatial authority: L10 Pale Growth Orchard, P6/P7/P8 walkable route. This is flat repeatable ground/water material; make every edge continuous, native 3x3 repeatable without rotating to conceal seams; no raised structures or collision-marking visual blocks. Placement safeguard: No trees, plants or obstacles baked into this base-ground source. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_floor_materials_v2/southern_orchard_path_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_floor_materials_v2/southern_orchard_path.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_floor_materials_v2.asset.json`  
**Anchor/constraints:** Spatial source: L10 Pale Growth Orchard, P6/P7/P8 walkable route. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; No trees, plants or obstacles baked into this base-ground source. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.


### Both ponds and blackwater

#### `hub_first_set_sepulcher_water_materials_v2/blackwater_base_still`

**Set:** `SG-WATER-001`, order 12; **family:** `hub_first_set_sepulcher_water_materials_v2`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, OPAQUE RGB, one frame, no transparency, no black or checkerboard borders.

**Generation prompt:** Create exactly ONE 512x512 one-frame opaque RGB CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_water_materials_v2/blackwater_base_still. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Almost still charcoal-green opaque blackwater surface with extremely subtle olive mineral bloom and dim neutral sheen, no objects or stark reflections. Spatial authority: D3 Witness Pool and D4 Sunken Blackwater Basin water polygons. This is flat repeatable ground/water material; make every edge continuous, native 3x3 repeatable without rotating to conceal seams; no raised structures or collision-marking visual blocks. Placement safeguard: 3x3 seamless water source; render only within D3/D4 nonwalkable water masks. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_water_materials_v2/blackwater_base_still_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_water_materials_v2/blackwater_base_still.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_water_materials_v2.asset.json`  
**Anchor/constraints:** Spatial source: D3 Witness Pool and D4 Sunken Blackwater Basin water polygons. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; 3x3 seamless water source; render only within D3/D4 nonwalkable water masks. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_water_materials_v2/witness_shallow_reflection`

**Set:** `SG-WATER-002`, order 13; **family:** `hub_first_set_sepulcher_water_materials_v2`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 512x512 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_water_materials_v2/witness_shallow_reflection. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Very sparse pale grey soft skyless reflections near inner Witness Pool edge, thin elongated smudges broken by dark negative space. Spatial authority: D3 Witness Pool polygon, reflective overlay only. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: No shorelines, geometry or bright mirror-like objects; never draws beyond approved water mask. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_water_materials_v2/witness_shallow_reflection_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_water_materials_v2/witness_shallow_reflection.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_water_materials_v2.asset.json`  
**Anchor/constraints:** Spatial source: D3 Witness Pool polygon, reflective overlay only. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; No shorelines, geometry or bright mirror-like objects; never draws beyond approved water mask. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_water_materials_v2/witness_depth_haze`

**Set:** `SG-WATER-003`, order 14; **family:** `hub_first_set_sepulcher_water_materials_v2`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 512x512 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_water_materials_v2/witness_depth_haze. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Subdued graphite-to-muted-green transparent water-depth stains, restrained cold diffuse mottling without a radial ring center. Spatial authority: D3 Witness Pool interior depth gradation. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Clip to D3 only; do not alter physical water depth or route access. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_water_materials_v2/witness_depth_haze_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_water_materials_v2/witness_depth_haze.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_water_materials_v2.asset.json`  
**Anchor/constraints:** Spatial source: D3 Witness Pool interior depth gradation. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Clip to D3 only; do not alter physical water depth or route access. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_water_materials_v2/sunken_basin_silt`

**Set:** `SG-WATER-004`, order 15; **family:** `hub_first_set_sepulcher_water_materials_v2`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 512x512 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_water_materials_v2/sunken_basin_silt. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Fine ash sediment and olive-black silt bands over deep water, sparse diffuse pale mineral suspension, irregular softly transparent patches. Spatial authority: D4 Sunken Blackwater Basin polygon. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Clip within D4 water, no bank rubble or waterline shapes. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_water_materials_v2/sunken_basin_silt_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_water_materials_v2/sunken_basin_silt.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_water_materials_v2.asset.json`  
**Anchor/constraints:** Spatial source: D4 Sunken Blackwater Basin polygon. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Clip within D4 water, no bank rubble or waterline shapes. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_water_materials_v2/submerged_broken_limestone`

**Set:** `SG-WATER-005`, order 16; **family:** `hub_first_set_sepulcher_water_materials_v2`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x256 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_water_materials_v2/submerged_broken_limestone. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Two eroded submerged burial blocks faintly seen below opaque dark water through distorted low-contrast edges, one separate isolated overlay. Spatial authority: D4 submerged environmental storytelling, non-interactive. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: No solid obstacle or loot trigger asserted; render as underwater visual only. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_water_materials_v2/submerged_broken_limestone_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_water_materials_v2/submerged_broken_limestone.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_water_materials_v2.asset.json`  
**Anchor/constraints:** Spatial source: D4 submerged environmental storytelling, non-interactive. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; No solid obstacle or loot trigger asserted; render as underwater visual only. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_water_materials_v2/submerged_bronze_index`

**Set:** `SG-WATER-006`, order 17; **family:** `hub_first_set_sepulcher_water_materials_v2`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x256 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_water_materials_v2/submerged_bronze_index. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: One partial corroded bronze registry-rail trace obscured by inky water, faint weathered geometric lines, not readable text. Spatial authority: D3 registrarial water pattern, non-interactive. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: No invented puzzle or path information; overlay lives inside water mask. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_water_materials_v2/submerged_bronze_index_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_water_materials_v2/submerged_bronze_index.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_water_materials_v2.asset.json`  
**Anchor/constraints:** Spatial source: D3 registrarial water pattern, non-interactive. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; No invented puzzle or path information; overlay lives inside water mask. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_water_materials_v2/dark_water_microripples`

**Set:** `SG-WATER-007`, order 18; **family:** `hub_first_set_sepulcher_water_materials_v2`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x256 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_water_materials_v2/dark_water_microripples. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: A few widely separated soft disturbed-water micro-ripples, broken concentric smears with nearly invisible brown-green high points. Spatial authority: D3/D4 rare static variation overlay. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Optional deterministic sparse placement; no animated gameplay, no bright highlight rings. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_water_materials_v2/dark_water_microripples_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_water_materials_v2/dark_water_microripples.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_water_materials_v2.asset.json`  
**Anchor/constraints:** Spatial source: D3/D4 rare static variation overlay. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Optional deterministic sparse placement; no animated gameplay, no bright highlight rings. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.


### 20-piece modular shoreline

#### `hub_first_set_sepulcher_shoreline_v2/formal_straight_plain`

**Set:** `SG-SHORE-001`, order 19; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x128px total; 1 frame(s), 256x128px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x128 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/formal_straight_plain. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Long precision-fitted horizontal limestone coping cap, charcoal block fascia and uninterrupted thin oxidized-bronze molding with no central focal mark. Spatial authority: D3 Witness Pool formal perimeter, flat edge segment. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Left/right coping and bronze anchors must meet exactly at 256px pitch. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/formal_straight_plain_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/formal_straight_plain.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D3 Witness Pool formal perimeter, flat edge segment. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Left/right coping and bronze anchors must meet exactly at 256px pitch. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_shoreline_v2/formal_straight_weathered`

**Set:** `SG-SHORE-002`, order 20; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x128px total; 1 frame(s), 256x128px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x128 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/formal_straight_weathered. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Same exact endpoint profile as formal_straight_plain with small chipped ends, subtler limestone whitening and one nonrepeating weather stain. Spatial authority: D3 straight perimeter alternative. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Use identical end heights/bronze band with plain segment, preserve clean connection. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/formal_straight_weathered_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/formal_straight_weathered.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D3 straight perimeter alternative. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Use identical end heights/bronze band with plain segment, preserve clean connection. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_shoreline_v2/formal_outer_corner_90`

**Set:** `SG-SHORE-003`, order 21; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 128x128px total; 1 frame(s), 128x128px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 128x128 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/formal_outer_corner_90. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Compact convex formal coping turning exactly ninety degrees, consistent bronze trim wrapped over vertex and believable orthographic stone corner. Spatial authority: D3 polygon angular outer turn. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Connect 128px north/south and east/west legs; no gap or false path. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/formal_outer_corner_90_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/formal_outer_corner_90.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D3 polygon angular outer turn. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Connect 128px north/south and east/west legs; no gap or false path. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_shoreline_v2/formal_inner_corner_90`

**Set:** `SG-SHORE-004`, order 22; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 128x128px total; 1 frame(s), 128x128px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 128x128 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/formal_inner_corner_90. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Recessed right-angle limestone coping socket with uninterrupted aged-bronze L band and correctly chamfered inward face. Spatial authority: D3 concave inward shoreline turn. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Two orthogonal straight-leg profiles must physically match. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/formal_inner_corner_90_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/formal_inner_corner_90.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D3 concave inward shoreline turn. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Two orthogonal straight-leg profiles must physically match. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_shoreline_v2/formal_convex_curve_45`

**Set:** `SG-SHORE-005`, order 23; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x256 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/formal_convex_curve_45. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: A gently faceted convex segment of formal burial-pool coping with four-course masonry and a bronze line that follows the outer arc. Spatial authority: D3 45-degree shallow outer bend. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Both tangent ends meet formal straight and each other, not a freestanding fountain. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/formal_convex_curve_45_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/formal_convex_curve_45.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D3 45-degree shallow outer bend. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Both tangent ends meet formal straight and each other, not a freestanding fountain. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_shoreline_v2/formal_concave_curve_45`

**Set:** `SG-SHORE-006`, order 24; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x256 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/formal_concave_curve_45. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Concave shallow-angle formal shoreline fascia with inset limestone return and rusted-bronze indexing curve. Spatial authority: D3 inward diagonal approach. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Check curvature sign against D3 authored polygon, never cover water access path. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/formal_concave_curve_45_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/formal_concave_curve_45.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D3 inward diagonal approach. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Check curvature sign against D3 authored polygon, never cover water access path. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_shoreline_v2/formal_terminal_cap`

**Set:** `SG-SHORE-007`, order 25; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 128x128px total; 1 frame(s), 128x128px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 128x128 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/formal_terminal_cap. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Clearly recognizable capped termination of a formal limestone coping run with compact two-stone end face and closed bronze-band tip. Spatial authority: D3 short formal coping end. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Must read as a terminal, not a small corner or gate. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/formal_terminal_cap_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/formal_terminal_cap.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D3 short formal coping end. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Must read as a terminal, not a small corner or gate. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_shoreline_v2/formal_step_landing`

**Set:** `SG-SHORE-008`, order 26; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x192px total; 1 frame(s), 256x192px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x192 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/formal_step_landing. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Low ceremonial flat landing and visually shallow coping threshold, oxidized-bronze perimeter rails worn smooth by records, no actual stairs into water. Spatial authority: D3 ceremonial edge at existing walkable approach. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: No new traversable water route; keep staging outside water mask. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/formal_step_landing_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/formal_step_landing.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D3 ceremonial edge at existing walkable approach. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; No new traversable water route; keep staging outside water mask. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_shoreline_v2/ruined_straight_cracked`

**Set:** `SG-SHORE-009`, order 27; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x128px total; 1 frame(s), 256x128px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x128 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/ruined_straight_cracked. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Long collapsed limestone-and-charcoal retaining fascia with deep individual cracks but unbroken coping terminal profile and limited roots. Spatial authority: D4 ruined straight bank segment. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Same endpoint height as formal straight, no exposed alpha gap at seams. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/ruined_straight_cracked_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/ruined_straight_cracked.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D4 ruined straight bank segment. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Same endpoint height as formal straight, no exposed alpha gap at seams. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_shoreline_v2/ruined_straight_gap`

**Set:** `SG-SHORE-010`, order 28; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x128px total; 1 frame(s), 256x128px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x128 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/ruined_straight_gap. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: A pronounced local center breach of cracked coping revealing old foundation stone and a little ash rubble, but intact matching edge terminals. Spatial authority: D4 single masonry breach segment. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Preserve rubble center and continuous module connection flanks. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/ruined_straight_gap_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/ruined_straight_gap.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D4 single masonry breach segment. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Preserve rubble center and continuous module connection flanks. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_shoreline_v2/ruined_outer_corner_90`

**Set:** `SG-SHORE-011`, order 29; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 128x128px total; 1 frame(s), 128x128px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 128x128 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/ruined_outer_corner_90. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Convex ruin corner with chipped masonry course, corroded bronze line dying into concrete-like mineral erosion. Spatial authority: D4 angular collapsed convex bank. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Physically closes two matching ruined straight ends. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/ruined_outer_corner_90_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/ruined_outer_corner_90.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D4 angular collapsed convex bank. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Physically closes two matching ruined straight ends. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_shoreline_v2/ruined_inner_corner_90`

**Set:** `SG-SHORE-012`, order 30; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 128x128px total; 1 frame(s), 128x128px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 128x128 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/ruined_inner_corner_90. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Recessed ninety-degree broken-bank corner with several offset damaged stone end courses and aged green tarnish. Spatial authority: D4 tucked-in concave bank. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Maintain distinct concave profile and matching terminal elevations. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/ruined_inner_corner_90_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/ruined_inner_corner_90.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D4 tucked-in concave bank. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Maintain distinct concave profile and matching terminal elevations. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_shoreline_v2/ruined_curve_45`

**Set:** `SG-SHORE-013`, order 31; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x256 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/ruined_curve_45. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: One curving ruin-limestone coping arc with a displaced off-center stone, controlled modest roots and slender broken bronze band. Spatial authority: D4 broken shallow diagonal bank. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Tangent ends fit ruined straight profile; no floating duplicate curve or stray fragment. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/ruined_curve_45_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/ruined_curve_45.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D4 broken shallow diagonal bank. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Tangent ends fit ruined straight profile; no floating duplicate curve or stray fragment. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_shoreline_v2/ruined_rubble_terminal`

**Set:** `SG-SHORE-014`, order 32; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 128x128px total; 1 frame(s), 128x128px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 128x128 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/ruined_rubble_terminal. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: A masonry shoreline termination where the last large capstone fragments into two modest rubble pieces on the bank side. Spatial authority: D4 collapsed bank endpoint. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Keep water-facing edge continuous; do not depict traversable breach. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/ruined_rubble_terminal_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/ruined_rubble_terminal.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D4 collapsed bank endpoint. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Keep water-facing edge continuous; do not depict traversable breach. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_shoreline_v2/ruined_root_breach`

**Set:** `SG-SHORE-015`, order 33; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x128px total; 1 frame(s), 256x128px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x128 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/ruined_root_breach. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Low roots exploiting a mortar collapse seam within damaged basalt and limestone fascia, coping profile survives at both ends. Spatial authority: D4 bank root intrusion. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Do not treat root-breach center as a new solid obstacle or path. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/ruined_root_breach_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/ruined_root_breach.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D4 bank root intrusion. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Do not treat root-breach center as a new solid obstacle or path. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_shoreline_v2/raw_earth_bank_straight`

**Set:** `SG-SHORE-016`, order 34; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x128px total; 1 frame(s), 256x128px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x128 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/raw_earth_bank_straight. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: A short thin earthen scarp mixed with ash grit and sharp thin limestone fragments as retaining wall deteriorates. Spatial authority: D4 natural exposed earth shoreline. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Both ends terminate at registered raw-bank profile, no water material baked in. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/raw_earth_bank_straight_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/raw_earth_bank_straight.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D4 natural exposed earth shoreline. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Both ends terminate at registered raw-bank profile, no water material baked in. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_shoreline_v2/formal_to_ruined_joint`

**Set:** `SG-SHORE-017`, order 35; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x128px total; 1 frame(s), 256x128px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x128 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/formal_to_ruined_joint. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: A controlled change from intact limestone and continuous bronze on left to fractured coping and broken metal on right. Spatial authority: D3/D4 shared palette transition reference. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Explicit matching F and R end contours; no floor or water rendered. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/formal_to_ruined_joint_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/formal_to_ruined_joint.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D3/D4 shared palette transition reference. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Explicit matching F and R end contours; no floor or water rendered. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_shoreline_v2/ruined_to_raw_bank_joint`

**Set:** `SG-SHORE-018`, order 36; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x128px total; 1 frame(s), 256x128px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x128 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/ruined_to_raw_bank_joint. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Ruin-stone coping reducing gradually into an earth-and-gravel shoreline with a single credible buried foundation stone. Spatial authority: D4 eroded bank junction. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Ruin terminal left, soil terminal right; preserve no gap at native pitch. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/ruined_to_raw_bank_joint_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/ruined_to_raw_bank_joint.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D4 eroded bank junction. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Ruin terminal left, soil terminal right; preserve no gap at native pitch. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_shoreline_v2/formal_to_raw_bank_joint`

**Set:** `SG-SHORE-019`, order 37; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x128px total; 1 frame(s), 256x128px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x128 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/formal_to_raw_bank_joint. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Institutional coping pulled away to reveal mineral mud and historic bedrock underneath, bronze detail ends intentionally. Spatial authority: D3/D4 configurable architecture-to-earth transition. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Formal terminal left matches F, raw bank terminal right matches earth segments. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/formal_to_raw_bank_joint_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/formal_to_raw_bank_joint.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D3/D4 configurable architecture-to-earth transition. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Formal terminal left matches F, raw bank terminal right matches earth segments. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_shoreline_v2/shallow_angle_adapter`

**Set:** `SG-SHORE-020`, order 38; **family:** `hub_first_set_sepulcher_shoreline_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 128x128px total; 1 frame(s), 128x128px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 128x128 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_shoreline_v2/shallow_angle_adapter. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Small faceted limestone and charcoal stone wedge transitioning a straight coping line to one shallow diagonal without warped metal trim. Spatial authority: D3/D4 diagonals requiring small registered changes. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Final placed tangent orientation comes from actual water polygon, not invented connection topology. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_shoreline_v2/shallow_angle_adapter_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_shoreline_v2/shallow_angle_adapter.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_shoreline_v2.asset.json`  
**Anchor/constraints:** Spatial source: D3/D4 diagonals requiring small registered changes. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Final placed tangent orientation comes from actual water polygon, not invented connection topology. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.


### Impassable ruin and collapsed-depth margins

#### `hub_first_set_sepulcher_void_boundaries_v2/western_collapse_upper_lip`

**Set:** `SG-VOID-001`, order 39; **family:** `hub_first_set_sepulcher_void_boundaries_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x192px total; 1 frame(s), 512x192px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 512x192 true RGBA one-frame asset, identity hub_first_set_sepulcher_void_boundaries_v2/western_collapse_upper_lip. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Irregular raised charcoal limestone collapse face with high unbroken coping and fractured ash-grey vertical masonry visible only from overhead. Registered authoring context: D1 Western collapse trench cell polygon western edge. Gameplay/geometry rule: No walkable crossing; place along authored D1 edge. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_void_boundaries_v2/western_collapse_upper_lip_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_void_boundaries_v2/western_collapse_upper_lip.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_void_boundaries_v2.asset.json`  
**Anchor/constraints:** Design binding: D1 Western collapse trench cell polygon western edge; world scale 1px/1 world unit where spatially defined; No walkable crossing; place along authored D1 edge; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_void_boundaries_v2/western_collapse_depth_rubble`

**Set:** `SG-VOID-002`, order 40; **family:** `hub_first_set_sepulcher_void_boundaries_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 512x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_void_boundaries_v2/western_collapse_depth_rubble. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Downward-feeling but strictly overhead stone debris field, broken thin slabs sinking into dark gravel and near-black gap. Registered authoring context: D1 interior nonwalkable collapse trench. Gameplay/geometry rule: Confine visual stonefall within D1, leave mask unchanged. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_void_boundaries_v2/western_collapse_depth_rubble_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_void_boundaries_v2/western_collapse_depth_rubble.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_void_boundaries_v2.asset.json`  
**Anchor/constraints:** Design binding: D1 interior nonwalkable collapse trench; world scale 1px/1 world unit where spatially defined; Confine visual stonefall within D1, leave mask unchanged; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_void_boundaries_v2/north_cloister_rubble_cap`

**Set:** `SG-VOID-003`, order 41; **family:** `hub_first_set_sepulcher_void_boundaries_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 512x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_void_boundaries_v2/north_cloister_rubble_cap. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Irregular collapsed upper limestone arch masonry and dead basalt pillars piled along north side, chipped capstone shapes. Registered authoring context: D2 North ruined cloister debris polygon. Gameplay/geometry rule: Nonwalkable D2 only; never spill into P5 approach. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_void_boundaries_v2/north_cloister_rubble_cap_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_void_boundaries_v2/north_cloister_rubble_cap.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_void_boundaries_v2.asset.json`  
**Anchor/constraints:** Design binding: D2 North ruined cloister debris polygon; world scale 1px/1 world unit where spatially defined; Nonwalkable D2 only; never spill into P5 approach; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_void_boundaries_v2/north_cloister_depth_field`

**Set:** `SG-VOID-004`, order 42; **family:** `hub_first_set_sepulcher_void_boundaries_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 512x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_void_boundaries_v2/north_cloister_depth_field. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Fine rubble carpet with subdued shadow cavities between big eroded blocks, one larger granite socket. Registered authoring context: D2 ruined cloister sink. Gameplay/geometry rule: Keep dark depth cues localized; do not mark a new entrance. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_void_boundaries_v2/north_cloister_depth_field_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_void_boundaries_v2/north_cloister_depth_field.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_void_boundaries_v2.asset.json`  
**Anchor/constraints:** Design binding: D2 ruined cloister sink; world scale 1px/1 world unit where spatially defined; Keep dark depth cues localized; do not mark a new entrance; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_void_boundaries_v2/closed_crypt_outer_wall`

**Set:** `SG-VOID-005`, order 43; **family:** `hub_first_set_sepulcher_void_boundaries_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x192px total; 1 frame(s), 512x192px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 512x192 true RGBA one-frame asset, identity hub_first_set_sepulcher_void_boundaries_v2/closed_crypt_outer_wall. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Low continuous sealed wall of ashen limestone and dark basalt joints surrounding a dead overgrown inner precinct. Registered authoring context: D5 Closed Crypt Garden nonwalkable perimeter. Gameplay/geometry rule: Must match D5 silhouette after geometry clipping; no opened doorway. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_void_boundaries_v2/closed_crypt_outer_wall_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_void_boundaries_v2/closed_crypt_outer_wall.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_void_boundaries_v2.asset.json`  
**Anchor/constraints:** Design binding: D5 Closed Crypt Garden nonwalkable perimeter; world scale 1px/1 world unit where spatially defined; Must match D5 silhouette after geometry clipping; no opened doorway; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_void_boundaries_v2/closed_crypt_blind_corner`

**Set:** `SG-VOID-006`, order 44; **family:** `hub_first_set_sepulcher_void_boundaries_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 256x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_void_boundaries_v2/closed_crypt_blind_corner. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Strong squared-over corner masonry of a blind crypt wall with collapsed dark register rail. Registered authoring context: D5 sealed polygon kink. Gameplay/geometry rule: No corridor gap through sealed D5. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_void_boundaries_v2/closed_crypt_blind_corner_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_void_boundaries_v2/closed_crypt_blind_corner.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_void_boundaries_v2.asset.json`  
**Anchor/constraints:** Design binding: D5 sealed polygon kink; world scale 1px/1 world unit where spatially defined; No corridor gap through sealed D5; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_void_boundaries_v2/outer_arcade_broken_footing`

**Set:** `SG-VOID-007`, order 45; **family:** `hub_first_set_sepulcher_void_boundaries_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x256px total; 1 frame(s), 384x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 384x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_void_boundaries_v2/outer_arcade_broken_footing. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Broken rear foundation of civic arcade, one tall free-standing stump and scattered stones with warped bronze line. Registered authoring context: D6 Root-choked Outer Arcade nonwalkable rear side. Gameplay/geometry rule: Supplement to CAL-02 only; D6 remains nonwalkable. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_void_boundaries_v2/outer_arcade_broken_footing_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_void_boundaries_v2/outer_arcade_broken_footing.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_void_boundaries_v2.asset.json`  
**Anchor/constraints:** Design binding: D6 Root-choked Outer Arcade nonwalkable rear side; world scale 1px/1 world unit where spatially defined; Supplement to CAL-02 only; D6 remains nonwalkable; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_void_boundaries_v2/southern_thicket_broken_wall`

**Set:** `SG-VOID-008`, order 46; **family:** `hub_first_set_sepulcher_void_boundaries_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 512x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_void_boundaries_v2/southern_thicket_broken_wall. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Two isolated fragments of low burial wall with dark debris between, under sparse dead roots. Registered authoring context: D7 South thicket and fallen masonry. Gameplay/geometry rule: Off walkable P7/P8 paths, preserve full route widths. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_void_boundaries_v2/southern_thicket_broken_wall_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_void_boundaries_v2/southern_thicket_broken_wall.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_void_boundaries_v2.asset.json`  
**Anchor/constraints:** Design binding: D7 South thicket and fallen masonry; world scale 1px/1 world unit where spatially defined; Off walkable P7/P8 paths, preserve full route widths; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_void_boundaries_v2/southern_thicket_scree`

**Set:** `SG-VOID-009`, order 47; **family:** `hub_first_set_sepulcher_void_boundaries_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 512x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_void_boundaries_v2/southern_thicket_scree. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Flat small pulverized stone and sparse roots over an irregular nonwalkable rubble island, compressed low-contrast silhouette. Registered authoring context: D7 southern dead masonry spread. Gameplay/geometry rule: Do not turn walkway material into a blocked path. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_void_boundaries_v2/southern_thicket_scree_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_void_boundaries_v2/southern_thicket_scree.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_void_boundaries_v2.asset.json`  
**Anchor/constraints:** Design binding: D7 southern dead masonry spread; world scale 1px/1 world unit where spatially defined; Do not turn walkway material into a blocked path; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_void_boundaries_v2/external_garden_dead_margin`

**Set:** `SG-VOID-010`, order 48; **family:** `hub_first_set_sepulcher_void_boundaries_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 512x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_void_boundaries_v2/external_garden_dead_margin. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Broken massive limestone boundary ledge meeting near-black collapsed stone depth, irregular nonpicture-edge silhouette. Registered authoring context: Outer nonrectangular Gardens boundary cells outside walkable mask. Gameplay/geometry rule: Border visual only outside playable region, never fill active cells or create an entrance. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_void_boundaries_v2/external_garden_dead_margin_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_void_boundaries_v2/external_garden_dead_margin.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_void_boundaries_v2.asset.json`  
**Anchor/constraints:** Design binding: Outer nonrectangular Gardens boundary cells outside walkable mask; world scale 1px/1 world unit where spatially defined; Border visual only outside playable region, never fill active cells or create an entrance; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.


### Ten distinct landmark architectures

#### `hub_first_set_sepulcher_landmark_architecture_v2/north_threshold_coping`

**Set:** `SG-LANDMARK-001`, order 49; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x256px total; 1 frame(s), 384x256px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 384x256 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/north_threshold_coping. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Twin separated flat-topped cloister footing pier assemblies and chipped upper threshold coping with narrow bronze civic index. Spatial authority: L01 North Threshold Cloister world (-1376,-3296). Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: No solid or fake door across the full north connector's 128px open passage. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/north_threshold_coping_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/north_threshold_coping.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L01 North Threshold Cloister world (-1376,-3296). Absolute placement on 32px world grid; artist cannot add collision or change path availability.; No solid or fake door across the full north connector's 128px open passage. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/north_threshold_heraldic_footing`

**Set:** `SG-LANDMARK-002`, order 50; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x128px total; 1 frame(s), 256x128px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x128 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/north_threshold_heraldic_footing. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Broken bronze-inscribed lintel foundation fragment, inset but unreadable civic witness motif and chipped limestone base. Spatial authority: L01 North Threshold Cloister margins. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Off-route end foundation only; no center gate. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/north_threshold_heraldic_footing_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/north_threshold_heraldic_footing.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L01 North Threshold Cloister margins. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Off-route end foundation only; no center gate. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/south_threshold_coping`

**Set:** `SG-LANDMARK-003`, order 51; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x256px total; 1 frame(s), 384x256px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 384x256 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/south_threshold_coping. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: More ruined return-side pair of civic threshold coping remnants with fractured ochre limewash and worn basalt trims. Spatial authority: L02 South Threshold Cloister world (-1376,-2752). Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Do not narrow south connector or mirror L01. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/south_threshold_coping_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/south_threshold_coping.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L02 South Threshold Cloister world (-1376,-2752). Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Do not narrow south connector or mirror L01. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/south_threshold_return_plinth`

**Set:** `SG-LANDMARK-004`, order 52; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x128px total; 1 frame(s), 256x128px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x128 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/south_threshold_return_plinth. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Low abandoned return-procession marker plinth with aged bronze stripes and flattened stone chamfers. Spatial authority: L02 edge of southern garden opening. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: At pathway margin only, no invented exit. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/south_threshold_return_plinth_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/south_threshold_return_plinth.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L02 edge of southern garden opening. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; At pathway margin only, no invented exit. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/unreturned_names_east_arcade`

**Set:** `SG-LANDMARK-005`, order 53; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 512x256 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/unreturned_names_east_arcade. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Repeated but individually broken overhead archive-cloister piers with slender limestone lintel stubs and dead name-register slots. Spatial authority: L03 Cloister of Unreturned Names world (-1632,-3136). Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Single isolated south-north arcade edge, preserve P1/P2 routes. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/unreturned_names_east_arcade_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/unreturned_names_east_arcade.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L03 Cloister of Unreturned Names world (-1632,-3136). Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Single isolated south-north arcade edge, preserve P1/P2 routes. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/unreturned_names_broken_arch`

**Set:** `SG-LANDMARK-006`, order 54; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x256px total; 1 frame(s), 384x256px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 384x256 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/unreturned_names_broken_arch. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: One fallen heavy stone arch springer and shattered twin pillar stumps still geometrically aligned to original aisle. Spatial authority: L03 Cloister arcade fragmentation. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: No new roof occlusion or impassable walkable cell claim. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/unreturned_names_broken_arch_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/unreturned_names_broken_arch.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L03 Cloister arcade fragmentation. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; No new roof occlusion or impassable walkable cell claim. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/unreturned_names_registry_recess`

**Set:** `SG-LANDMARK-007`, order 55; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x192px total; 1 frame(s), 256x192px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x192 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/unreturned_names_registry_recess. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Blind shallow register niche with empty inset charcoal slabs and corroded rail ends, no legible inscriptions. Spatial authority: L03 record-wall recess. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: A narrative-only architectural recess, not a usable loot container. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/unreturned_names_registry_recess_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/unreturned_names_registry_recess.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L03 record-wall recess. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; A narrative-only architectural recess, not a usable loot container. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/memorial_court_index_ring`

**Set:** `SG-LANDMARK-008`, order 56; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 512x512 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/memorial_court_index_ring. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: One damaged concentric pavement registry band in two thin nested arcs with gaps and minimalist oxidized-bronze linear markings. Spatial authority: L04 Memorial Slab Court world (-1984,-3200). Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Flat decoration, preserve grave slab and inspection/choice clearance. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/memorial_court_index_ring_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/memorial_court_index_ring.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L04 Memorial Slab Court world (-1984,-3200). Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Flat decoration, preserve grave slab and inspection/choice clearance. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/memorial_court_low_side_wall`

**Set:** `SG-LANDMARK-009`, order 57; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x192px total; 1 frame(s), 512x192px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 512x192 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/memorial_court_low_side_wall. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Very low capped double-course limestone memorial border with charcoal base, weathered bronze seam and short broken return. Spatial authority: L04 court outer margin. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Off event approaches and outside required grave clearance. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/memorial_court_low_side_wall_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/memorial_court_low_side_wall.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L04 court outer margin. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Off event approaches and outside required grave clearance. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/memorial_court_marker_footing`

**Set:** `SG-LANDMARK-010`, order 58; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x192px total; 1 frame(s), 256x192px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x192 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/memorial_court_marker_footing. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: A paired compact paver-and-metal foundation for absent administrative witness standards, now empty. Spatial authority: L04 old civic center perimeter. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: No functional interaction or duplicated memorial slab. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/memorial_court_marker_footing_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/memorial_court_marker_footing.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L04 old civic center perimeter. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; No functional interaction or duplicated memorial slab. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/bell_less_rotunda_ring`

**Set:** `SG-LANDMARK-011`, order 59; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 768x768px total; 1 frame(s), 768x768px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 768x768 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/bell_less_rotunda_ring. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Large overhead ring of ruined low arc masonry with absent northern segment, layered charcoal foundations and pale stone arc plinths. Spatial authority: L05 Bell-less Rotunda world (-2080,-3776). Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Do not enclose a new room or obstruct P4 without approved collision. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/bell_less_rotunda_ring_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/bell_less_rotunda_ring.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L05 Bell-less Rotunda world (-2080,-3776). Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Do not enclose a new room or obstruct P4 without approved collision. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/bell_less_rotunda_pedestal`

**Set:** `SG-LANDMARK-012`, order 60; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x256 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/bell_less_rotunda_pedestal. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Broken hollow bell-bearing pedestal, empty socket with copper oxidation and minimal stonefall, no actual bell. Spatial authority: L05 rotunda center. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Not a gameplay objective; spatial placement must be vetted. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/bell_less_rotunda_pedestal_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/bell_less_rotunda_pedestal.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L05 rotunda center. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Not a gameplay objective; spatial placement must be vetted. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/bell_less_rotunda_outer_footings`

**Set:** `SG-LANDMARK-013`, order 61; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 512x256 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/bell_less_rotunda_outer_footings. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Three separated curving old archive-footing shards and one recessed registrar niche arranged along a broken orbit. Spatial authority: L05 rotunda rear edge and S3 recess. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Leave rotunda approach and rear secret telegraph sightline. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/bell_less_rotunda_outer_footings_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/bell_less_rotunda_outer_footings.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L05 rotunda rear edge and S3 recess. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Leave rotunda approach and rear secret telegraph sightline. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/witness_pool_formal_entry`

**Set:** `SG-LANDMARK-014`, order 62; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x256px total; 1 frame(s), 384x256px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 384x256 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/witness_pool_formal_entry. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: A formal shallow limestone overlook with two offset coping piers and thin bronze grave-register rails. Spatial authority: L06 Witness Pool world (-3040,-3584), D3. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: No steps into nonwalkable water; must meet shoreline F01 end profile. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/witness_pool_formal_entry_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/witness_pool_formal_entry.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L06 Witness Pool world (-3040,-3584), D3. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; No steps into nonwalkable water; must meet shoreline F01 end profile. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/witness_pool_mute_marker`

**Set:** `SG-LANDMARK-015`, order 63; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x128px total; 1 frame(s), 256x128px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x128 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/witness_pool_mute_marker. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: A compact empty stone witnessing stand next to the water with paired bronze index nibs and abrasion from standing feet. Spatial authority: L06 shallow bank scenic marker. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: No legible labels or interactive promise. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/witness_pool_mute_marker_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/witness_pool_mute_marker.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L06 shallow bank scenic marker. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; No legible labels or interactive promise. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/twin_sarcophagus_pair`

**Set:** `SG-LANDMARK-016`, order 64; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 512x256 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/twin_sarcophagus_pair. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Two distinct long low ceremonial stone sarcophagus lids, one intact and one fractured, weathered charcoal bases with pale inset caps. Spatial authority: L07 Twin Sarcophagus Terrace world (-3424,-3104). Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Isolated true RGBA, collision placement must not block P3 and S4. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/twin_sarcophagus_pair_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/twin_sarcophagus_pair.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L07 Twin Sarcophagus Terrace world (-3424,-3104). Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Isolated true RGBA, collision placement must not block P3 and S4. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/twin_sarcophagus_low_terrace`

**Set:** `SG-LANDMARK-017`, order 65; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 640x320px total; 1 frame(s), 640x320px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 640x320 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/twin_sarcophagus_low_terrace. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Long low inset paved dais and paired border coping with visible graded masonry construction but no physical riser access. Spatial authority: L07 western terraces walkable rim. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Keep walkable paths visually flat and preserve landscape edges. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/twin_sarcophagus_low_terrace_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/twin_sarcophagus_low_terrace.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L07 western terraces walkable rim. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Keep walkable paths visually flat and preserve landscape edges. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/twin_sarcophagus_inspection_niche`

**Set:** `SG-LANDMARK-018`, order 66; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x192px total; 1 frame(s), 256x192px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x192 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/twin_sarcophagus_inspection_niche. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Small separated burial-offering wall recess with weathered flattened stone lip and bronze-framed dark cavity. Spatial authority: L07 S4 offering flank. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: No actual offering pickup until separately authorized. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/twin_sarcophagus_inspection_niche_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/twin_sarcophagus_inspection_niche.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L07 S4 offering flank. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; No actual offering pickup until separately authorized. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/sunken_basin_collapsed_overlook`

**Set:** `SG-LANDMARK-019`, order 67; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 512x256 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/sunken_basin_collapsed_overlook. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Partial ruin overlook projecting visually toward the water, broken low stone rail and one displaced coping segment. Spatial authority: L08 Sunken Blackwater Basin world (-2624,-2464), D4. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: No raised bridge or new crossing over nonwalkable basin. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/sunken_basin_collapsed_overlook_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/sunken_basin_collapsed_overlook.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L08 Sunken Blackwater Basin world (-2624,-2464), D4. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; No raised bridge or new crossing over nonwalkable basin. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/sunken_basin_foundation_stub`

**Set:** `SG-LANDMARK-020`, order 68; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x192px total; 1 frame(s), 256x192px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x192 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/sunken_basin_foundation_stub. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Foundation stump of a missing registry channel, cracked basalt, oxidized metal cap and mineral deposits. Spatial authority: L08 water-side ruined infrastructure. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Contained to approved bank or nonwalkable D4 mask. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/sunken_basin_foundation_stub_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/sunken_basin_foundation_stub.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L08 water-side ruined infrastructure. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Contained to approved bank or nonwalkable D4 mask. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/rootbound_reliquary_arch_slit`

**Set:** `SG-LANDMARK-021`, order 69; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x320px total; 1 frame(s), 256x320px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x320 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/rootbound_reliquary_arch_slit. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Tall narrow side-view-free overhead arch slit with heavy old stone jambs and small roots binding the top. Spatial authority: L09 Rootbound Reliquary Nook world (-3392,-2176), S1. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Telegraph hidden nook without inventing authorized interior door or pickup. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/rootbound_reliquary_arch_slit_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/rootbound_reliquary_arch_slit.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L09 Rootbound Reliquary Nook world (-3392,-2176), S1. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Telegraph hidden nook without inventing authorized interior door or pickup. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/rootbound_reliquary_stone_shrine`

**Set:** `SG-LANDMARK-022`, order 70; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x256 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/rootbound_reliquary_stone_shrine. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Compact empty reliquary pedestal with dark limestone box bed, open top, two aged bronze prongs and sparse roots. Spatial authority: L09 secluded nook. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: No implied functional loot or collision route. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/rootbound_reliquary_stone_shrine_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/rootbound_reliquary_stone_shrine.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L09 secluded nook. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; No implied functional loot or collision route. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/rootbound_reliquary_outer_coping`

**Set:** `SG-LANDMARK-023`, order 71; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x192px total; 1 frame(s), 384x192px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 384x192 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/rootbound_reliquary_outer_coping. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Broken stone wall coping fragment protecting concealed alcove, graded darker into roots with a single missing corner. Spatial authority: L09 low-screen alcove flank. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Keep existing walkable route unobstructed, no fake entrance. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/rootbound_reliquary_outer_coping_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/rootbound_reliquary_outer_coping.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L09 low-screen alcove flank. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Keep existing walkable route unobstructed, no fake entrance. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/pale_growth_orchard_boundary`

**Set:** `SG-LANDMARK-024`, order 72; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x192px total; 1 frame(s), 512x192px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 512x192 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/pale_growth_orchard_boundary. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Low regular limestone orchard edging with a faint washed pale patina and root pressure distortions. Spatial authority: L10 Pale Growth Orchard world (-1920,-2144). Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Separate from walkable ground, no tree trunks across P6-P8. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/pale_growth_orchard_boundary_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/pale_growth_orchard_boundary.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L10 Pale Growth Orchard world (-1920,-2144). Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Separate from walkable ground, no tree trunks across P6-P8. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/pale_growth_orchard_witness_tree`

**Set:** `SG-LANDMARK-025`, order 73; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 512x512 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/pale_growth_orchard_witness_tree. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: One twisted pale-barked memorial tree viewed exactly overhead, sparse canopy with cool desaturated leaves and aged root base. Spatial authority: L10 off-route planted region. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: Off-path scenic object with collision placement not authorized by image. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/pale_growth_orchard_witness_tree_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/pale_growth_orchard_witness_tree.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L10 off-route planted region. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; Off-path scenic object with collision placement not authorized by image. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_landmark_architecture_v2/pale_growth_orchard_small_shrine`

**Set:** `SG-LANDMARK-026`, order 74; **family:** `hub_first_set_sepulcher_landmark_architecture_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, TRUE RGBA with genuinely transparent exterior pixels, no simulated checkerboard/matte; verify alpha bytes.

**Generation prompt:** Create exactly ONE 256x256 one-frame true RGBA CUSTODIAN pixel-art style candidate for state hub_first_set_sepulcher_landmark_architecture_v2/pale_growth_orchard_small_shrine. Strict orthographic 90-degree overhead, north up, 32px architecture, consistent visual scale with the 128px Operator. CUSTODIAN burial-civic palette: weathered chalk limestone, charcoal basalt, ash, oxidized bronze, aged stone joints, restrained cold-grey light. EXACTLY ONE independent PNG source, no contact sheet, labels, UI, characters, readable writing, borrowed image conditioning claim, directional vignette or scenic picture frame. Composition and unique subject: Empty offering stone beneath sparse pale growth, two dark carved registers and fractured old civic bronze inlay. Spatial authority: L10 east quiet alcove. Isolate only the described object/overlay with clean fully transparent exterior, physically plausible top-down silhouette, consistent pixel scale, no painted floor or solid background; no fake alpha/checkerboard. Placement safeguard: No readable ritual directions or invented interaction. No art-owned walkability, event offsets, water collision, connector widths, invented entrance or extra gameplay. Check actual native-size readability and separate visual assessment from byte-level PNG/alpha/seam checks. Existing paving, blackwater and shoreline chat candidates are NOT automatically production-approved or verified image conditioning.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_landmark_architecture_v2/pale_growth_orchard_small_shrine_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_landmark_architecture_v2/pale_growth_orchard_small_shrine.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_landmark_architecture_v2.asset.json`  
**Anchor/constraints:** Spatial source: L10 east quiet alcove. Absolute placement on 32px world grid; artist cannot add collision or change path availability.; No readable ritual directions or invented interaction. Use only authored footprint or off-route presentation after registration; visual candidate may be staged before gameplay placement approval; never invent navigable interior, water boundary or loot.  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json + user-authorized full-artwork roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.


### Four notable interior complexes

#### `hub_first_set_sepulcher_interiors_v2/arcade_vestibule_floor_plate`

**Set:** `SG-INTERIOR-001`, order 75; **family:** `hub_first_set_sepulcher_interiors_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, OPAQUE RGB, no transparency, one flat floor frame; candidate-only until room geometry approved.

**Generation prompt:** Generate EXACTLY ONE independent 512x512 opaque RGB one-frame asset, identity hub_first_set_sepulcher_interiors_v2/arcade_vestibule_floor_plate. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Quiet small grid of burial cloister floor slabs worn by registrars, sparse broken bronze stations and no raised features. Registered authoring context: I01 Root-choked Outer Arcade visual interior, obstacle D6. Gameplay/geometry rule: Interior floor is only a candidate material reference; D6 remains nonwalkable and no interior runtime scene exists. Only FLAT floor material and no framed walls, doors, void, routes or raised scenery. Treat as room material proposal, not existing collision geometry. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_interiors_v2/arcade_vestibule_floor_plate_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_interiors_v2/arcade_vestibule_floor_plate.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_interiors_v2.asset.json`  
**Anchor/constraints:** Design binding: I01 Root-choked Outer Arcade visual interior, obstacle D6; world scale 1px/1 world unit where spatially defined; Interior floor is only a candidate material reference; D6 remains nonwalkable and no interior runtime scene exists; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_interiors_v2/arcade_architrave_broken`

**Set:** `SG-INTERIOR-002`, order 76; **family:** `hub_first_set_sepulcher_interiors_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 512x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_interiors_v2/arcade_architrave_broken. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: One heavy overhead architrave spanning two isolated broken civic piers, old dark metal register underneath and modest root pressure. Registered authoring context: I01 D6, CAL-02 structural edge register. Gameplay/geometry rule: Visual extension of CAL-02 within D6 nonwalkable silhouette, no proposed playable doorway. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_interiors_v2/arcade_architrave_broken_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_interiors_v2/arcade_architrave_broken.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_interiors_v2.asset.json`  
**Anchor/constraints:** Design binding: I01 D6, CAL-02 structural edge register; world scale 1px/1 world unit where spatially defined; Visual extension of CAL-02 within D6 nonwalkable silhouette, no proposed playable doorway; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_interiors_v2/arcade_registry_wall`

**Set:** `SG-INTERIOR-003`, order 77; **family:** `hub_first_set_sepulcher_interiors_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 512x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_interiors_v2/arcade_registry_wall. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Long shallow dead archive wall with twelve empty name sockets, chipped limestone and darkened metal spine. Registered authoring context: I01 D6 rear interior wall. Gameplay/geometry rule: Must not imply legible names or human interactable wall panels. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_interiors_v2/arcade_registry_wall_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_interiors_v2/arcade_registry_wall.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_interiors_v2.asset.json`  
**Anchor/constraints:** Design binding: I01 D6 rear interior wall; world scale 1px/1 world unit where spatially defined; Must not imply legible names or human interactable wall panels; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_interiors_v2/arcade_rear_occluder`

**Set:** `SG-INTERIOR-004`, order 78; **family:** `hub_first_set_sepulcher_interiors_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x256px total; 1 frame(s), 384x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 384x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_interiors_v2/arcade_rear_occluder. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: One deep overlapping overhead slab lip and tangled-root hanging vault fragment for future Operator partial occlusion. Registered authoring context: I01 D6 rear arcade occlusion fragment. Gameplay/geometry rule: Occlusion test required; no runtime roof/visibility behavior granted. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_interiors_v2/arcade_rear_occluder_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_interiors_v2/arcade_rear_occluder.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_interiors_v2.asset.json`  
**Anchor/constraints:** Design binding: I01 D6 rear arcade occlusion fragment; world scale 1px/1 world unit where spatially defined; Occlusion test required; no runtime roof/visibility behavior granted; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_interiors_v2/crypt_garden_floor_plate`

**Set:** `SG-INTERIOR-005`, order 79; **family:** `hub_first_set_sepulcher_interiors_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, OPAQUE RGB, no transparency, one flat floor frame; candidate-only until room geometry approved.

**Generation prompt:** Generate EXACTLY ONE independent 512x512 opaque RGB one-frame asset, identity hub_first_set_sepulcher_interiors_v2/crypt_garden_floor_plate. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Cold sealed interior burial garden paving, organized small cut limestone squares around empty old socket channels and ash deposits. Registered authoring context: I02 Closed Crypt Garden obstacle D5. Gameplay/geometry rule: D5 remains sealed; floor image never implies accessibility. Only FLAT floor material and no framed walls, doors, void, routes or raised scenery. Treat as room material proposal, not existing collision geometry. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_interiors_v2/crypt_garden_floor_plate_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_interiors_v2/crypt_garden_floor_plate.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_interiors_v2.asset.json`  
**Anchor/constraints:** Design binding: I02 Closed Crypt Garden obstacle D5; world scale 1px/1 world unit where spatially defined; D5 remains sealed; floor image never implies accessibility; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_interiors_v2/crypt_garden_sealed_grate`

**Set:** `SG-INTERIOR-006`, order 80; **family:** `hub_first_set_sepulcher_interiors_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 512x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_interiors_v2/crypt_garden_sealed_grate. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Large solid stone crypt grille with blind dark square apertures and oxidized bronze band edging, no open gap. Registered authoring context: I02 D5 sealed outer closure. Gameplay/geometry rule: No usable entrance; fully contained in D5 proposed visual area. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_interiors_v2/crypt_garden_sealed_grate_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_interiors_v2/crypt_garden_sealed_grate.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_interiors_v2.asset.json`  
**Anchor/constraints:** Design binding: I02 D5 sealed outer closure; world scale 1px/1 world unit where spatially defined; No usable entrance; fully contained in D5 proposed visual area; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_interiors_v2/crypt_garden_ossuary_wall`

**Set:** `SG-INTERIOR-007`, order 81; **family:** `hub_first_set_sepulcher_interiors_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 512x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_interiors_v2/crypt_garden_ossuary_wall. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Row of sealed burial niche fronts, alternating dark stone shutters and collapsed pale lintel strips, non-readable metal tabs. Registered authoring context: I02 D5 internal closed court. Gameplay/geometry rule: Only visual built interior, no contents or pickups. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_interiors_v2/crypt_garden_ossuary_wall_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_interiors_v2/crypt_garden_ossuary_wall.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_interiors_v2.asset.json`  
**Anchor/constraints:** Design binding: I02 D5 internal closed court; world scale 1px/1 world unit where spatially defined; Only visual built interior, no contents or pickups; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_interiors_v2/crypt_garden_dead_cenotaph`

**Set:** `SG-INTERIOR-008`, order 82; **family:** `hub_first_set_sepulcher_interiors_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 320x256px total; 1 frame(s), 320x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 320x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_interiors_v2/crypt_garden_dead_cenotaph. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Low damaged anonymous cenotaph and dry mineral basin recess with black calcified corners. Registered authoring context: I02 D5 center of nonwalkable sealed compound. Gameplay/geometry rule: No gameplay access or collision authority. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_interiors_v2/crypt_garden_dead_cenotaph_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_interiors_v2/crypt_garden_dead_cenotaph.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_interiors_v2.asset.json`  
**Anchor/constraints:** Design binding: I02 D5 center of nonwalkable sealed compound; world scale 1px/1 world unit where spatially defined; No gameplay access or collision authority; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_interiors_v2/rotunda_undercroft_floor_plate`

**Set:** `SG-INTERIOR-009`, order 83; **family:** `hub_first_set_sepulcher_interiors_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, OPAQUE RGB, no transparency, one flat floor frame; candidate-only until room geometry approved.

**Generation prompt:** Generate EXACTLY ONE independent 512x512 opaque RGB one-frame asset, identity hub_first_set_sepulcher_interiors_v2/rotunda_undercroft_floor_plate. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Darker ash-and-limestone rectangular lower-court flooring with ancient faint circular registration but no stairs or exits. Registered authoring context: I03 Bell-less Rotunda L05 proposed lower chamber. Gameplay/geometry rule: Not a built existing underground scene; design-only source until spatial unlock. Only FLAT floor material and no framed walls, doors, void, routes or raised scenery. Treat as room material proposal, not existing collision geometry. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_interiors_v2/rotunda_undercroft_floor_plate_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_interiors_v2/rotunda_undercroft_floor_plate.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_interiors_v2.asset.json`  
**Anchor/constraints:** Design binding: I03 Bell-less Rotunda L05 proposed lower chamber; world scale 1px/1 world unit where spatially defined; Not a built existing underground scene; design-only source until spatial unlock; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_interiors_v2/rotunda_undercroft_column`

**Set:** `SG-INTERIOR-010`, order 84; **family:** `hub_first_set_sepulcher_interiors_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 256x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_interiors_v2/rotunda_undercroft_column. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Single massive cracked black basalt column footprint and fractured pale limestone capital pieces seen fully overhead. Registered authoring context: I03 L05 undercroft visual interior. Gameplay/geometry rule: No invented route obstruction in current playable rotunda. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_interiors_v2/rotunda_undercroft_column_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_interiors_v2/rotunda_undercroft_column.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_interiors_v2.asset.json`  
**Anchor/constraints:** Design binding: I03 L05 undercroft visual interior; world scale 1px/1 world unit where spatially defined; No invented route obstruction in current playable rotunda; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_interiors_v2/rotunda_undercroft_record_wall`

**Set:** `SG-INTERIOR-011`, order 85; **family:** `hub_first_set_sepulcher_interiors_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 512x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_interiors_v2/rotunda_undercroft_record_wall. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Half-circle low wall fragment carrying six blank empty record slots with broken narrow bronze index ribs. Registered authoring context: I03 L05 undercroft abandoned registrar wall. Gameplay/geometry rule: No readable writing or actual archive interaction. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_interiors_v2/rotunda_undercroft_record_wall_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_interiors_v2/rotunda_undercroft_record_wall.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_interiors_v2.asset.json`  
**Anchor/constraints:** Design binding: I03 L05 undercroft abandoned registrar wall; world scale 1px/1 world unit where spatially defined; No readable writing or actual archive interaction; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_interiors_v2/rotunda_undercroft_occlusion`

**Set:** `SG-INTERIOR-012`, order 86; **family:** `hub_first_set_sepulcher_interiors_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 512x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_interiors_v2/rotunda_undercroft_occlusion. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: One ruined overhead sloping stone vault crosspiece with dark fissure exposing negative-space aperture. Registered authoring context: I03 L05 speculative chamber roofline fragment. Gameplay/geometry rule: No working stairs or door until a separate room model exists. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_interiors_v2/rotunda_undercroft_occlusion_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_interiors_v2/rotunda_undercroft_occlusion.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_interiors_v2.asset.json`  
**Anchor/constraints:** Design binding: I03 L05 speculative chamber roofline fragment; world scale 1px/1 world unit where spatially defined; No working stairs or door until a separate room model exists; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_interiors_v2/reliquary_chamber_floor_plate`

**Set:** `SG-INTERIOR-013`, order 87; **family:** `hub_first_set_sepulcher_interiors_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, OPAQUE RGB, no transparency, one flat floor frame; candidate-only until room geometry approved.

**Generation prompt:** Generate EXACTLY ONE independent 512x512 opaque RGB one-frame asset, identity hub_first_set_sepulcher_interiors_v2/reliquary_chamber_floor_plate. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Old narrow reliquary chamber ground: interleaved charcoal slabs and pale limestone small-gauge path with two empty floor register sockets. Registered authoring context: I04 Rootbound Reliquary L09 S1 concept interior. Gameplay/geometry rule: No assumption that chamber exists or is connected to existing walkability. Only FLAT floor material and no framed walls, doors, void, routes or raised scenery. Treat as room material proposal, not existing collision geometry. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_interiors_v2/reliquary_chamber_floor_plate_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_interiors_v2/reliquary_chamber_floor_plate.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_interiors_v2.asset.json`  
**Anchor/constraints:** Design binding: I04 Rootbound Reliquary L09 S1 concept interior; world scale 1px/1 world unit where spatially defined; No assumption that chamber exists or is connected to existing walkability; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_interiors_v2/reliquary_inner_shelf`

**Set:** `SG-INTERIOR-014`, order 88; **family:** `hub_first_set_sepulcher_interiors_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x192px total; 1 frame(s), 384x192px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 384x192 true RGBA one-frame asset, identity hub_first_set_sepulcher_interiors_v2/reliquary_inner_shelf. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Long low ceremonial votive shelf in old cream limestone with three empty compartments and corroded bronze lips. Registered authoring context: I04 L09 rootbound secret niche. Gameplay/geometry rule: No functional item or chest contents authorized. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_interiors_v2/reliquary_inner_shelf_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_interiors_v2/reliquary_inner_shelf.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_interiors_v2.asset.json`  
**Anchor/constraints:** Design binding: I04 L09 rootbound secret niche; world scale 1px/1 world unit where spatially defined; No functional item or chest contents authorized; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_interiors_v2/reliquary_roof_occlusion`

**Set:** `SG-INTERIOR-015`, order 89; **family:** `hub_first_set_sepulcher_interiors_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x256px total; 1 frame(s), 384x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 384x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_interiors_v2/reliquary_roof_occlusion. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Overhead broken archivolt lintel covered with a small number of pale dead roots, hollow central opening. Registered authoring context: I04 L09 hidden nook enclosure. Gameplay/geometry rule: Occlude only after separate test; preserve existing nook route view. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_interiors_v2/reliquary_roof_occlusion_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_interiors_v2/reliquary_roof_occlusion.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_interiors_v2.asset.json`  
**Anchor/constraints:** Design binding: I04 L09 hidden nook enclosure; world scale 1px/1 world unit where spatially defined; Occlude only after separate test; preserve existing nook route view; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_interiors_v2/reliquary_blind_door`

**Set:** `SG-INTERIOR-016`, order 90; **family:** `hub_first_set_sepulcher_interiors_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 256x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_interiors_v2/reliquary_blind_door. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: A sealed inset stone panel with unreadable flaked engraved shapes and bronze bolt sockets, not an interactable portal. Registered authoring context: I04 L09 S1 visual rear niche. Gameplay/geometry rule: Do not hint that it opens or create portal gameplay. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_interiors_v2/reliquary_blind_door_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_interiors_v2/reliquary_blind_door.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_interiors_v2.asset.json`  
**Anchor/constraints:** Design binding: I04 L09 S1 visual rear niche; world scale 1px/1 world unit where spatially defined; Do not hint that it opens or create portal gameplay; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.


### Garden vegetation and eroded roots

#### `hub_first_set_sepulcher_vegetation_v2/pale_orchard_witness_shrub`

**Set:** `SG-VEGETATION-001`, order 91; **family:** `hub_first_set_sepulcher_vegetation_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 256x256 true RGBA one-frame asset, identity hub_first_set_sepulcher_vegetation_v2/pale_orchard_witness_shrub. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: One low pale-grey-leaf memorial shrub with jagged old stem and spare chalk-colored foliage at overhead angle. Registered authoring context: L10 Pale Growth Orchard planted offpath soil. Gameplay/geometry rule: Never across P6/P7/P8 routes; real alpha except foliage. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_vegetation_v2/pale_orchard_witness_shrub_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_vegetation_v2/pale_orchard_witness_shrub.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_vegetation_v2.asset.json`  
**Anchor/constraints:** Design binding: L10 Pale Growth Orchard planted offpath soil; world scale 1px/1 world unit where spatially defined; Never across P6/P7/P8 routes; real alpha except foliage; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_vegetation_v2/ashen_low_ground_cover`

**Set:** `SG-VEGETATION-002`, order 92; **family:** `hub_first_set_sepulcher_vegetation_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 128x128px total; 1 frame(s), 128x128px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 128x128 true RGBA one-frame asset, identity hub_first_set_sepulcher_vegetation_v2/ashen_low_ground_cover. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: A tiny low patch of dead muted-olive creeper and ash grit with restrained leaf density. Registered authoring context: Southern Gardens edge planting on nonwalkable margins. Gameplay/geometry rule: Small scattered placement only, not tiled as floor base. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_vegetation_v2/ashen_low_ground_cover_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_vegetation_v2/ashen_low_ground_cover.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_vegetation_v2.asset.json`  
**Anchor/constraints:** Design binding: Southern Gardens edge planting on nonwalkable margins; world scale 1px/1 world unit where spatially defined; Small scattered placement only, not tiled as floor base; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_vegetation_v2/root_seam_short`

**Set:** `SG-VEGETATION-003`, order 93; **family:** `hub_first_set_sepulcher_vegetation_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x128px total; 1 frame(s), 256x128px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 256x128 true RGBA one-frame asset, identity hub_first_set_sepulcher_vegetation_v2/root_seam_short. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Two thin brown-black roots prying through an old masonry seam with pale chalk flecks and few stem ends. Registered authoring context: D6/D7 ruined offroute architecture. Gameplay/geometry rule: Overlay on confirmed ruin only, no path obstruction. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_vegetation_v2/root_seam_short_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_vegetation_v2/root_seam_short.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_vegetation_v2.asset.json`  
**Anchor/constraints:** Design binding: D6/D7 ruined offroute architecture; world scale 1px/1 world unit where spatially defined; Overlay on confirmed ruin only, no path obstruction; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_vegetation_v2/root_seam_long`

**Set:** `SG-VEGETATION-004`, order 94; **family:** `hub_first_set_sepulcher_vegetation_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x128px total; 1 frame(s), 512x128px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 512x128 true RGBA one-frame asset, identity hub_first_set_sepulcher_vegetation_v2/root_seam_long. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: One branched aged root line tracing a 512px ruined stone boundary, sparse pale fungus and attached grit. Registered authoring context: L09 reliquary and D2 cloister ruins. Gameplay/geometry rule: No new collision and no corridor-spanning wall. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_vegetation_v2/root_seam_long_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_vegetation_v2/root_seam_long.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_vegetation_v2.asset.json`  
**Anchor/constraints:** Design binding: L09 reliquary and D2 cloister ruins; world scale 1px/1 world unit where spatially defined; No new collision and no corridor-spanning wall; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_vegetation_v2/pale_flower_sparse`

**Set:** `SG-VEGETATION-005`, order 95; **family:** `hub_first_set_sepulcher_vegetation_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 128x128px total; 1 frame(s), 128x128px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 128x128 true RGBA one-frame asset, identity hub_first_set_sepulcher_vegetation_v2/pale_flower_sparse. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Three tiny pale medicinal flowers with fine dry stems and lots of negative alpha space, not a bouquet. Registered authoring context: L10 orchard and S5 quiet margin. Gameplay/geometry rule: No readable arrow/quest signal, use infrequently. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_vegetation_v2/pale_flower_sparse_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_vegetation_v2/pale_flower_sparse.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_vegetation_v2.asset.json`  
**Anchor/constraints:** Design binding: L10 orchard and S5 quiet margin; world scale 1px/1 world unit where spatially defined; No readable arrow/quest signal, use infrequently; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_vegetation_v2/dead_reed_small`

**Set:** `SG-VEGETATION-006`, order 96; **family:** `hub_first_set_sepulcher_vegetation_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 128x128px total; 1 frame(s), 128x128px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 128x128 true RGBA one-frame asset, identity hub_first_set_sepulcher_vegetation_v2/dead_reed_small. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Sparse dark desiccated reeds rooted to a very small gravel seam, low shadow and strong edge readability. Registered authoring context: D3/D4 water banks only. Gameplay/geometry rule: Never render as solid/bridge over pool, rare placement. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_vegetation_v2/dead_reed_small_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_vegetation_v2/dead_reed_small.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_vegetation_v2.asset.json`  
**Anchor/constraints:** Design binding: D3/D4 water banks only; world scale 1px/1 world unit where spatially defined; Never render as solid/bridge over pool, rare placement; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_vegetation_v2/dead_reed_large`

**Set:** `SG-VEGETATION-007`, order 97; **family:** `hub_first_set_sepulcher_vegetation_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x192px total; 1 frame(s), 256x192px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 256x192 true RGBA one-frame asset, identity hub_first_set_sepulcher_vegetation_v2/dead_reed_large. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: One asymmetrical small dry reed cluster with broken brown seed head and minimal pale leaf remnants. Registered authoring context: D4 basin shoreline outside P6. Gameplay/geometry rule: Break repetition at basin edge only, preserve path clarity. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_vegetation_v2/dead_reed_large_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_vegetation_v2/dead_reed_large.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_vegetation_v2.asset.json`  
**Anchor/constraints:** Design binding: D4 basin shoreline outside P6; world scale 1px/1 world unit where spatially defined; Break repetition at basin edge only, preserve path clarity; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_vegetation_v2/chipped_lichen_overlay`

**Set:** `SG-VEGETATION-008`, order 98; **family:** `hub_first_set_sepulcher_vegetation_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x128px total; 1 frame(s), 256x128px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 256x128 true RGBA one-frame asset, identity hub_first_set_sepulcher_vegetation_v2/chipped_lichen_overlay. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: A thin isolated irregular chalk-olive lichen weathering mask with pinhole textures and no photographic rectangle. Registered authoring context: L01-L10 walls and low civic plinths. Gameplay/geometry rule: Apply only to stone surfaces, not floor paths or water. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_vegetation_v2/chipped_lichen_overlay_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_vegetation_v2/chipped_lichen_overlay.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_vegetation_v2.asset.json`  
**Anchor/constraints:** Design binding: L01-L10 walls and low civic plinths; world scale 1px/1 world unit where spatially defined; Apply only to stone surfaces, not floor paths or water; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.


### Hidden cues and environmental storytelling

#### `hub_first_set_sepulcher_story_cues_v2/s1_arch_slit_telegraph`

**Set:** `SG-STORY-001`, order 99; **family:** `hub_first_set_sepulcher_story_cues_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x128px total; 1 frame(s), 256x128px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 256x128 true RGBA one-frame asset, identity hub_first_set_sepulcher_story_cues_v2/s1_arch_slit_telegraph. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Half-obscured dark arch slit with chipped pale stone edges and a fine oxidized bronze glint behind roots. Registered authoring context: S1 Rootbound Reliquary Nook at world(-3392,-2176). Gameplay/geometry rule: Only visual clue toward existing S1 nook, not a new portal. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_story_cues_v2/s1_arch_slit_telegraph_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_story_cues_v2/s1_arch_slit_telegraph.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_story_cues_v2.asset.json`  
**Anchor/constraints:** Design binding: S1 Rootbound Reliquary Nook at world(-3392,-2176); world scale 1px/1 world unit where spatially defined; Only visual clue toward existing S1 nook, not a new portal; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_story_cues_v2/s1_broken_register`

**Set:** `SG-STORY-002`, order 100; **family:** `hub_first_set_sepulcher_story_cues_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 128x128px total; 1 frame(s), 128x128px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 128x128 true RGBA one-frame asset, identity hub_first_set_sepulcher_story_cues_v2/s1_broken_register. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: One warped old bronze registry stub beside a collapsed empty stone holder, etched marks deliberately unreadable. Registered authoring context: S1 reliquary secret proposal. Gameplay/geometry rule: Never assert S1 Bronze witness token pickup exists. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_story_cues_v2/s1_broken_register_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_story_cues_v2/s1_broken_register.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_story_cues_v2.asset.json`  
**Anchor/constraints:** Design binding: S1 reliquary secret proposal; world scale 1px/1 world unit where spatially defined; Never assert S1 Bronze witness token pickup exists; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_story_cues_v2/s2_pool_breach_telegraph`

**Set:** `SG-STORY-003`, order 101; **family:** `hub_first_set_sepulcher_story_cues_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x192px total; 1 frame(s), 256x192px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 256x192 true RGBA one-frame asset, identity hub_first_set_sepulcher_story_cues_v2/s2_pool_breach_telegraph. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Water-stained broken limestone retaining wall exposing one dark recessed crevice, old thin bronze rail visible inside. Registered authoring context: S2 Witness Pool retaining-wall breach world(-3232,-3296). Gameplay/geometry rule: No walkable water cut-through or secret collection behavior. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_story_cues_v2/s2_pool_breach_telegraph_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_story_cues_v2/s2_pool_breach_telegraph.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_story_cues_v2.asset.json`  
**Anchor/constraints:** Design binding: S2 Witness Pool retaining-wall breach world(-3232,-3296); world scale 1px/1 world unit where spatially defined; No walkable water cut-through or secret collection behavior; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_story_cues_v2/s2_wet_registry_shard`

**Set:** `SG-STORY-004`, order 102; **family:** `hub_first_set_sepulcher_story_cues_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 128x128px total; 1 frame(s), 128x128px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 128x128 true RGBA one-frame asset, identity hub_first_set_sepulcher_story_cues_v2/s2_wet_registry_shard. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Partly wet dark registry tablet shard with blank weathered bronze inset and mineral scouring. Registered authoring context: S2 pool registry fragment proposal. Gameplay/geometry rule: Candidate visual only; waterlogged registry fragment not a real inventory item. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_story_cues_v2/s2_wet_registry_shard_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_story_cues_v2/s2_wet_registry_shard.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_story_cues_v2.asset.json`  
**Anchor/constraints:** Design binding: S2 pool registry fragment proposal; world scale 1px/1 world unit where spatially defined; Candidate visual only; waterlogged registry fragment not a real inventory item; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_story_cues_v2/s3_rotunda_recess_telegraph`

**Set:** `SG-STORY-005`, order 103; **family:** `hub_first_set_sepulcher_story_cues_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x192px total; 1 frame(s), 256x192px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 256x192 true RGBA one-frame asset, identity hub_first_set_sepulcher_story_cues_v2/s3_rotunda_recess_telegraph. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: One discreet rotunda rear wall notch partly hidden by the remains of a shattered stone arc. Registered authoring context: S3 Bell-less Rotunda rear rubble world(-2240,-3968). Gameplay/geometry rule: No invented undercroft access at S3. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_story_cues_v2/s3_rotunda_recess_telegraph_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_story_cues_v2/s3_rotunda_recess_telegraph.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_story_cues_v2.asset.json`  
**Anchor/constraints:** Design binding: S3 Bell-less Rotunda rear rubble world(-2240,-3968); world scale 1px/1 world unit where spatially defined; No invented undercroft access at S3; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_story_cues_v2/s3_empty_offering_socket`

**Set:** `SG-STORY-006`, order 104; **family:** `hub_first_set_sepulcher_story_cues_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 128x128px total; 1 frame(s), 128x128px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 128x128 true RGBA one-frame asset, identity hub_first_set_sepulcher_story_cues_v2/s3_empty_offering_socket. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Small old empty offering socket with a single chipped metal setting and dusty granite fragments. Registered authoring context: S3 old relic shard proposal. Gameplay/geometry rule: No real relic shard or interaction data. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_story_cues_v2/s3_empty_offering_socket_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_story_cues_v2/s3_empty_offering_socket.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_story_cues_v2.asset.json`  
**Anchor/constraints:** Design binding: S3 old relic shard proposal; world scale 1px/1 world unit where spatially defined; No real relic shard or interaction data; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_story_cues_v2/s4_sarcophagus_flank_telegraph`

**Set:** `SG-STORY-007`, order 105; **family:** `hub_first_set_sepulcher_story_cues_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x192px total; 1 frame(s), 256x192px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 256x192 true RGBA one-frame asset, identity hub_first_set_sepulcher_story_cues_v2/s4_sarcophagus_flank_telegraph. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Offset low burial wall with one deliberately missing triangular stone and nearly invisible side shadow. Registered authoring context: S4 Twin Sarcophagus flank world(-3616,-2848). Gameplay/geometry rule: Preserve route and no fake accessible cabinet. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_story_cues_v2/s4_sarcophagus_flank_telegraph_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_story_cues_v2/s4_sarcophagus_flank_telegraph.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_story_cues_v2.asset.json`  
**Anchor/constraints:** Design binding: S4 Twin Sarcophagus flank world(-3616,-2848); world scale 1px/1 world unit where spatially defined; Preserve route and no fake accessible cabinet; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_story_cues_v2/s4_offering_cavity`

**Set:** `SG-STORY-008`, order 106; **family:** `hub_first_set_sepulcher_story_cues_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 128x128px total; 1 frame(s), 128x128px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 128x128 true RGBA one-frame asset, identity hub_first_set_sepulcher_story_cues_v2/s4_offering_cavity. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: A dark empty niche with two dull copper rivets and chipped lime plaster along the lower rim. Registered authoring context: S4 old offering cache proposed. Gameplay/geometry rule: Not a real loot cache until game authorizes one. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_story_cues_v2/s4_offering_cavity_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_story_cues_v2/s4_offering_cavity.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_story_cues_v2.asset.json`  
**Anchor/constraints:** Design binding: S4 old offering cache proposed; world scale 1px/1 world unit where spatially defined; Not a real loot cache until game authorizes one; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_story_cues_v2/s5_orchard_low_screen`

**Set:** `SG-STORY-009`, order 107; **family:** `hub_first_set_sepulcher_story_cues_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x192px total; 1 frame(s), 256x192px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 256x192 true RGBA one-frame asset, identity hub_first_set_sepulcher_story_cues_v2/s5_orchard_low_screen. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Short low ruined orchard screen that hides part of the trail from oblique sight, sparse dry pale leaves. Registered authoring context: S5 Pale Growth Orchard low-screen approach world(-1824,-2016). Gameplay/geometry rule: No blocking actual P8 path, no real new secret door. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_story_cues_v2/s5_orchard_low_screen_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_story_cues_v2/s5_orchard_low_screen.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_story_cues_v2.asset.json`  
**Anchor/constraints:** Design binding: S5 Pale Growth Orchard low-screen approach world(-1824,-2016); world scale 1px/1 world unit where spatially defined; No blocking actual P8 path, no real new secret door; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_sepulcher_story_cues_v2/s5_seed_votive_socket`

**Set:** `SG-STORY-010`, order 108; **family:** `hub_first_set_sepulcher_story_cues_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 128x128px total; 1 frame(s), 128x128px per frame, `copy`, TRUE RGBA; object isolated against genuine alpha-zero pixels; no matte/checkerboard, visually and byte-verify.

**Generation prompt:** Generate EXACTLY ONE independent 128x128 true RGBA one-frame asset, identity hub_first_set_sepulcher_story_cues_v2/s5_seed_votive_socket. CUSTODIAN burial-civic, strict 90-degree top-down orthographic, world north at image top, 32px architectural proportions, physically consistent with the canonical 128px Operator. Restrained aged limestone, charcoal basalt, dead ash, dark oxidized bronze; no false emissive glow or text. Exactly one named asset image, never a labeled sheet, picture frame, scene mockup or composited multiple states. Unique subject and composition: Tiny covered stone votive socket and old bronze latch silhouette under sparse pale moss. Registered authoring context: S5 pale seed cache proposed. Gameplay/geometry rule: No item-grant, quest or seed gameplay implied. Transparent exterior only, no baked ground, camera tilt, hidden canvas object or matte; do not invent a solid footprint or playable access. This image alone does NOT authorize a new room, portal, collectible, loot state, secret interaction, collision or route. Interior placement and occlusion must be separately approved; use existing nonwalkable D1-D7 and named landmark paths only for fit checks. Generated output must be technically examined at native resolution for dimensions, RGBA alpha when required, clipping and scene readability; no image-conditioning claims without input evidence.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_story_cues_v2/s5_seed_votive_socket_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_story_cues_v2/s5_seed_votive_socket.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_story_cues_v2.asset.json`  
**Anchor/constraints:** Design binding: S5 pale seed cache proposed; world scale 1px/1 world unit where spatially defined; No item-grant, quest or seed gameplay implied; no source-image collision/navigation authority  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_geometry_registered_presentation  
**Provenance:** design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json and user-approved expanded art roadmap 2026-11-03  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.


### Existing Sepulcher B1 objects and connectors

#### `hub_first_set_connector_environment/garden_north_transition`

**Set:** `B1-01`, order 109; **family:** `hub_first_set_connector_environment`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 128x256px total; 1 frame(s), 128x256px per frame, `copy`, true alpha outside intentional ground and architectural seam.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 128×256 pixels as a one-frame image. Distinct north Gardens-to-Forum open threshold, uninterrupted level civic paving across the entire 128px four-cell corridor; any broken cloister piers, root intrusions or raised walls are SEPARATE off-route dressing and must not be painted into this corridor image. Preserve full width of real four-cell corridor. true alpha outside intentional ground and architectural seam. Exact LIVE HubFirstSetLayout anchor: sepulcher_north_connector Rect2i(85,68,4,8). The intended passage is four cells wide, 32px per cell, and must remain fully open; this art cannot own navigation, route width or collision. Do not certify a neighbor seam without visually and byte-checking source pixels from the actual adjoining surfaces; until then staging is candidate-only.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_connector_environment/garden_north_transition_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_connector_environment/garden_north_transition.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_connector_environment.asset.json`  
**Anchor/constraints:** sepulcher_north_connector Rect2i(85,68,4,8); underlay-floor blend only in the real open four-cell-wide connector; no architecture or obstacles inside corridor; test registered actual neighbor images before any runtime placement  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** Live HubFirstSetLayout.ENVELOPES 2026-11-03 connector-coordinate reconciliation; earlier B1/B2 anchor superseded  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_connector_environment/garden_south_transition`

**Set:** `B1-02`, order 110; **family:** `hub_first_set_connector_environment`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 128x256px total; 1 frame(s), 128x256px per frame, `copy`, true alpha outside intentional ground and architectural seam.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 128×256 pixels as a one-frame image. Distinct south Gardens-to-Forum return threshold with slightly paler age-worn flush pavers and cracked grout WITHOUT raised retaining stones, rooted growth or solids inside the passage, never mirrored north-threshold detail; maintain full actual passage. true alpha outside intentional ground and architectural seam. Exact LIVE HubFirstSetLayout anchor: sepulcher_south_connector Rect2i(85,85,4,8). The intended passage is four cells wide, 32px per cell, and must remain fully open; this art cannot own navigation, route width or collision. Do not certify a neighbor seam without visually and byte-checking source pixels from the actual adjoining surfaces; until then staging is candidate-only.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_connector_environment/garden_south_transition_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_connector_environment/garden_south_transition.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_connector_environment.asset.json`  
**Anchor/constraints:** sepulcher_south_connector Rect2i(85,85,4,8); underlay-floor blend only in the real open four-cell-wide connector; no architecture or obstacles inside corridor; test registered actual neighbor images before any runtime placement  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** Live HubFirstSetLayout.ENVELOPES 2026-11-03 connector-coordinate reconciliation; earlier B1/B2 anchor superseded  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_sepulcher_grave_evidence_art/inspection_stone`

**Set:** `B1-03`, order 111; **family:** `hub_sepulcher_grave_evidence_art`; **core:** yes; **kind:** world_prop; **priority:** P0.

**Target:** 64x64px total; 1 frame(s), 64x64px per frame, `copy`, isolated object PNG true RGBA, no floor or matte.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 64×64 pixels as a one-frame image. Small unlettered civic inspection marker with chipped pale stone and understated ring inlay, one isolated reusable marker for all three event reading positions. Do not paint ABC letter labels. isolated object PNG true RGBA, no floor or matte.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_sepulcher_grave_evidence_art/inspection_stone_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_sepulcher_grave_evidence_art/inspection_stone.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_sepulcher_grave_evidence_art.asset.json`  
**Anchor/constraints:** three existing physical inspection offsets; replace procedural rendering only; three readings, persistence, choice IDs and later-return growth gate remain unchanged  
**Consumer:** res://game/world/hub/events/sepulcher_grave/sepulcher_grave_evidence.gd  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_sepulcher_grave_evidence_art/resolution_stone`

**Set:** `B1-03`, order 111; **family:** `hub_sepulcher_grave_evidence_art`; **core:** yes; **kind:** world_prop; **priority:** P0.

**Target:** 64x64px total; 1 frame(s), 64x64px per frame, `copy`, isolated object PNG true RGBA, no floor or matte.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 64×64 pixels as a one-frame image. Understated ceremonial choice-marker stone with old bronze authority ring, reusable at both attestation outcomes. No choice words, glow or game UI. isolated object PNG true RGBA, no floor or matte.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_sepulcher_grave_evidence_art/resolution_stone_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_sepulcher_grave_evidence_art/resolution_stone.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_sepulcher_grave_evidence_art.asset.json`  
**Anchor/constraints:** two existing resolution points; replace procedural rendering only; three readings, persistence, choice IDs and later-return growth gate remain unchanged  
**Consumer:** res://game/world/hub/events/sepulcher_grave/sepulcher_grave_evidence.gd  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_sepulcher_grave_evidence_art/return_pale_growth`

**Set:** `B1-04`, order 112; **family:** `hub_sepulcher_grave_evidence_art`; **core:** yes; **kind:** world_prop; **priority:** P0.

**Target:** 64x64px total; 1 frame(s), 64x64px per frame, `copy`, isolated object PNG true RGBA, no floor or matte.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 64×64 pixels as a one-frame image. One very small newly sprouted pallid two-bud plant emerging at the slab edge, faint sage leaves and chalky blossoms, natural not supernatural; no cast-wide glow. isolated object PNG true RGBA, no floor or matte.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_sepulcher_grave_evidence_art/return_pale_growth_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_sepulcher_grave_evidence_art/return_pale_growth.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_sepulcher_grave_evidence_art.asset.json`  
**Anchor/constraints:** world grave + (42,18), visible only on subsequent visit after either resolution; replace procedural rendering only; three readings, persistence, choice IDs and later-return growth gate remain unchanged  
**Consumer:** res://game/world/hub/events/sepulcher_grave/sepulcher_grave_evidence.gd  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_sepulcher_gardens_dressing/grave_upright`

**Set:** `B1-05`, order 113; **family:** `hub_first_set_sepulcher_gardens_dressing`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 96x128px total; 1 frame(s), 96x128px per frame, `copy`, true isolated RGBA with no baked backdrop.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 96×128 pixels as a one-frame image. A vertically set witness gravestone, worn pale rectangular face, modest basalt footing, tiny unreadable institutional engravings, chipped capstone. true isolated RGBA with no baked backdrop.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_gardens_dressing/grave_upright_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_gardens_dressing/grave_upright.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_gardens_dressing.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; dressing only; deterministic variation, limit repeats, clear minimum 128px route and physical event offsets  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_sepulcher_gardens_dressing/grave_fractured`

**Set:** `B1-05`, order 113; **family:** `hub_first_set_sepulcher_gardens_dressing`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 96x128px total; 1 frame(s), 96x128px per frame, `copy`, true isolated RGBA with no baked backdrop.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 96×128 pixels as a one-frame image. Distinct fractured/partially toppled gravestone with split ivory edge, skewed fragments and tarnished bronze index bands, no mirror of upright stone. true isolated RGBA with no baked backdrop.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_gardens_dressing/grave_fractured_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_gardens_dressing/grave_fractured.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_gardens_dressing.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; dressing only; deterministic variation, limit repeats, clear minimum 128px route and physical event offsets  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_sepulcher_gardens_dressing/terraced_sarcophagus`

**Set:** `B1-06`, order 114; **family:** `hub_first_set_sepulcher_gardens_dressing`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 192x128px total; 1 frame(s), 192x128px per frame, `copy`, true isolated RGBA with no baked backdrop.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 192×128 pixels as a one-frame image. Low sealed terraced stone burial chest with offset square plinth, old cataloguing cuts and weathered limestone top, unopenable. true isolated RGBA with no baked backdrop.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_gardens_dressing/terraced_sarcophagus_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_gardens_dressing/terraced_sarcophagus.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_gardens_dressing.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; dressing only; deterministic variation, limit repeats, clear minimum 128px route and physical event offsets  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_sepulcher_gardens_dressing/memorial_plinth`

**Set:** `B1-06`, order 114; **family:** `hub_first_set_sepulcher_gardens_dressing`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 160x160px total; 1 frame(s), 160x160px per frame, `copy`, true isolated RGBA with no baked backdrop.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 160×160 pixels as a one-frame image. Square damaged monument pedestal after a long-removed statue, civic frieze fragments and sand in cracks, no active altar. true isolated RGBA with no baked backdrop.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_gardens_dressing/memorial_plinth_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_gardens_dressing/memorial_plinth.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_gardens_dressing.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; dressing only; deterministic variation, limit repeats, clear minimum 128px route and physical event offsets  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_sepulcher_gardens_dressing/cloister_arch_ruin`

**Set:** `B1-07`, order 115; **family:** `hub_first_set_sepulcher_gardens_dressing`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, true isolated RGBA with no baked backdrop.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 256×256 pixels as a one-frame image. One massive broken stone cloister arch stump and two piers with credible structural foundations viewed overhead, blocked against walking through. true isolated RGBA with no baked backdrop.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_gardens_dressing/cloister_arch_ruin_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_gardens_dressing/cloister_arch_ruin.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_gardens_dressing.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; dressing only; deterministic variation, limit repeats, clear minimum 128px route and physical event offsets  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_sepulcher_gardens_dressing/retaining_wall_segment`

**Set:** `B1-08`, order 116; **family:** `hub_first_set_sepulcher_gardens_dressing`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x128px total; 1 frame(s), 256x128px per frame, `copy`, true isolated RGBA with no baked backdrop.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 256×128 pixels as a one-frame image. Cracked burial terrace retaining wall of repeated ash-brown blocks, fallen capstones and organically eroded edges aligned to 32px architecture. true isolated RGBA with no baked backdrop.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_gardens_dressing/retaining_wall_segment_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_gardens_dressing/retaining_wall_segment.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_gardens_dressing.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; dressing only; deterministic variation, limit repeats, clear minimum 128px route and physical event offsets  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_sepulcher_gardens_dressing/root_intrusion`

**Set:** `B1-09`, order 117; **family:** `hub_first_set_sepulcher_gardens_dressing`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 128x96px total; 1 frame(s), 128x96px per frame, `copy`, true isolated RGBA with no baked backdrop.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 128×96 pixels as a one-frame image. Rare pale root fragments threading mortar and broken gravestones, desaturated olive/sage, thin asymmetrical silhouette, no jungle. true isolated RGBA with no baked backdrop.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_gardens_dressing/root_intrusion_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_gardens_dressing/root_intrusion.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_gardens_dressing.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; dressing only; deterministic variation, limit repeats, clear minimum 128px route and physical event offsets  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_sepulcher_gardens_dressing/pale_flower_cluster`

**Set:** `B1-09`, order 117; **family:** `hub_first_set_sepulcher_gardens_dressing`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 96x64px total; 1 frame(s), 96x64px per frame, `copy`, true isolated RGBA with no baked backdrop.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 96×64 pixels as a one-frame image. Tiny cluster of chalk-white blossoms beside burial stone, dusty leaves and low contrast, rare accent rather than a flower bed. true isolated RGBA with no baked backdrop.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_gardens_dressing/pale_flower_cluster_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_gardens_dressing/pale_flower_cluster.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_gardens_dressing.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; dressing only; deterministic variation, limit repeats, clear minimum 128px route and physical event offsets  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.


### Original first-set Hub districts and fixtures

#### `hub_first_set_north_processional_environment/underlay`

**Set:** `B2-01`, order 118; **family:** `hub_first_set_north_processional_environment`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 1024x1152px total; 1 frame(s), 1024x1152px per frame, `copy`, May be opaque inside exact approved playable footprint, no hard painted exterior rectangle or vignette.

**Generation prompt:** Generate exactly ONE independent 1024x1152 opaque RGB environment FLOOR-ONLY source for CUSTODIAN north processional. Strict orthographic 90° overhead and north up, 1 world pixel to 1 image pixel, exactly 32px construction rhythm. Design a coherent walkable old civic ground material only: Broad dead northbound road with worn interlocking stone pavers and faint bronze alignment marks, spatially quiet near all roads. Binding: current HubFirstSetLayout.ENVELOPES.north_processional Rect2i(113,97,32,36); world (-512,-2400), camera north up. Do not paint walls, colonnades, a raised dais, actual stairs, rooftops, vertical structures, impassable void, props, usable entrances, doors, collision obstacles, player, text, directional shadow, UI or false path. Structural geometry, details and skyline are separate manifest source states; this floor cannot invent them. Keep real marker positions and connector routes visually open; true gameplay navigation is owned by existing authored grid. No banner, contact sheet, picture-frame border, vignette or simulated transparent checkerboard. A standalone opaque 1-frame artwork source; record native dimensions and validate actual seamless adjacent contact at a separate runtime stage. Existing adjacent art is a design reference only unless actual bytes supplied and recorded. Source staging is candidate-only; human production approval and registration remain pending.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_north_processional_environment/underlay_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_north_processional_environment/underlay.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_north_processional_environment.asset.json`  
**Anchor/constraints:** HubFirstSetLayout.ENVELOPES.north_processional, 1px/world-unit candidate; Flat walkable-ground-only underlay within current HubFirstSetLayout.ENVELOPES.north_processional; architecture and solids separated into dedicated V2 props, preserve existing routes/markers and do not alter navigation  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** 2026-11-03 user-approved floor-first full-artwork roadmap; live HubFirstSetLayout.ENVELOPES.north_processional  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_ashen_forum_environment/underlay`

**Set:** `B2-02`, order 119; **family:** `hub_first_set_ashen_forum_environment`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 2560x1792px total; 1 frame(s), 2560x1792px per frame, `copy`, May be opaque inside exact approved playable footprint, no hard painted exterior rectangle or vignette.

**Generation prompt:** Generate exactly ONE independent 2560x1792 opaque RGB environment FLOOR-ONLY source for CUSTODIAN ashen forum. Strict orthographic 90° overhead and north up, 1 world pixel to 1 image pixel, exactly 32px construction rhythm. Design a coherent walkable old civic ground material only: Huge intentionally empty administrative plaza floor, thin broken concentric registration lines flush with stone, pale chalk erosion and charcoal civic basalt. Binding: current HubFirstSetLayout.ENVELOPES.ashen_forum Rect2i(89,46,80,56); world (-1280,-4032), Dais center (0,-3136). Do not paint walls, colonnades, a raised dais, actual stairs, rooftops, vertical structures, impassable void, props, usable entrances, doors, collision obstacles, player, text, directional shadow, UI or false path. Structural geometry, details and skyline are separate manifest source states; this floor cannot invent them. Keep real marker positions and connector routes visually open; true gameplay navigation is owned by existing authored grid. No banner, contact sheet, picture-frame border, vignette or simulated transparent checkerboard. A standalone opaque 1-frame artwork source; record native dimensions and validate actual seamless adjacent contact at a separate runtime stage. Existing adjacent art is a design reference only unless actual bytes supplied and recorded. Source staging is candidate-only; human production approval and registration remain pending.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_ashen_forum_environment/underlay_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_ashen_forum_environment/underlay.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_ashen_forum_environment.asset.json`  
**Anchor/constraints:** HubFirstSetLayout.ENVELOPES.ashen_forum, 1px/world-unit candidate; Flat walkable-ground-only underlay within current HubFirstSetLayout.ENVELOPES.ashen_forum; architecture and solids separated into dedicated V2 props, preserve existing routes/markers and do not alter navigation  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** 2026-11-03 user-approved floor-first full-artwork roadmap; live HubFirstSetLayout.ENVELOPES.ashen_forum  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_archive_rise_environment/underlay`

**Set:** `B2-03`, order 120; **family:** `hub_first_set_archive_rise_environment`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 1408x1280px total; 1 frame(s), 1408x1280px per frame, `copy`, May be opaque inside exact approved playable footprint, no hard painted exterior rectangle or vignette.

**Generation prompt:** Generate exactly ONE independent 1408x1280 opaque RGB environment FLOOR-ONLY source for CUSTODIAN archive rise. Strict orthographic 90° overhead and north up, 1 world pixel to 1 image pixel, exactly 32px construction rhythm. Design a coherent walkable old civic ground material only: Flat old archive court paving with rows of thin worn ledger grooves and ash-dusted limestone squares, no actual stairs. Binding: current HubFirstSetLayout.ENVELOPES.archive_rise Rect2i(107,9,44,40); world (-704,-5216). Do not paint walls, colonnades, a raised dais, actual stairs, rooftops, vertical structures, impassable void, props, usable entrances, doors, collision obstacles, player, text, directional shadow, UI or false path. Structural geometry, details and skyline are separate manifest source states; this floor cannot invent them. Keep real marker positions and connector routes visually open; true gameplay navigation is owned by existing authored grid. No banner, contact sheet, picture-frame border, vignette or simulated transparent checkerboard. A standalone opaque 1-frame artwork source; record native dimensions and validate actual seamless adjacent contact at a separate runtime stage. Existing adjacent art is a design reference only unless actual bytes supplied and recorded. Source staging is candidate-only; human production approval and registration remain pending.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_archive_rise_environment/underlay_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_archive_rise_environment/underlay.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_archive_rise_environment.asset.json`  
**Anchor/constraints:** HubFirstSetLayout.ENVELOPES.archive_rise, 1px/world-unit candidate; Flat walkable-ground-only underlay within current HubFirstSetLayout.ENVELOPES.archive_rise; architecture and solids separated into dedicated V2 props, preserve existing routes/markers and do not alter navigation  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** 2026-11-03 user-approved floor-first full-artwork roadmap; live HubFirstSetLayout.ENVELOPES.archive_rise  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_crown_transfer_environment/underlay`

**Set:** `B2-04`, order 121; **family:** `hub_first_set_crown_transfer_environment`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 768x768px total; 1 frame(s), 768x768px per frame, `copy`, May be opaque inside exact approved playable footprint, no hard painted exterior rectangle or vignette.

**Generation prompt:** Generate exactly ONE independent 768x768 opaque RGB environment FLOOR-ONLY source for CUSTODIAN crown transfer. Strict orthographic 90° overhead and north up, 1 world pixel to 1 image pixel, exactly 32px construction rhythm. Design a coherent walkable old civic ground material only: Quiet transfer-court stone floor with faint flat bronze nested-register inlays but no physical portal or causeway height. Binding: current HubFirstSetLayout.ENVELOPES.crown_transfer Rect2i(151,14,24,24); world (704,-5056), CrownTransfer (1088,-4672), TwinReturn (864,-4672). Do not paint walls, colonnades, a raised dais, actual stairs, rooftops, vertical structures, impassable void, props, usable entrances, doors, collision obstacles, player, text, directional shadow, UI or false path. Structural geometry, details and skyline are separate manifest source states; this floor cannot invent them. Keep real marker positions and connector routes visually open; true gameplay navigation is owned by existing authored grid. No banner, contact sheet, picture-frame border, vignette or simulated transparent checkerboard. A standalone opaque 1-frame artwork source; record native dimensions and validate actual seamless adjacent contact at a separate runtime stage. Existing adjacent art is a design reference only unless actual bytes supplied and recorded. Source staging is candidate-only; human production approval and registration remain pending.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_crown_transfer_environment/underlay_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_crown_transfer_environment/underlay.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_crown_transfer_environment.asset.json`  
**Anchor/constraints:** HubFirstSetLayout.ENVELOPES.crown_transfer, 1px/world-unit candidate; Flat walkable-ground-only underlay within current HubFirstSetLayout.ENVELOPES.crown_transfer; architecture and solids separated into dedicated V2 props, preserve existing routes/markers and do not alter navigation  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** 2026-11-03 user-approved floor-first full-artwork roadmap; live HubFirstSetLayout.ENVELOPES.crown_transfer  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_muster_court_environment/underlay`

**Set:** `B2-05`, order 122; **family:** `hub_first_set_muster_court_environment`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 1088x1408px total; 1 frame(s), 1088x1408px per frame, `copy`, May be opaque inside exact approved playable footprint, no hard painted exterior rectangle or vignette.

**Generation prompt:** Generate exactly ONE independent 1088x1408 opaque RGB environment FLOOR-ONLY source for CUSTODIAN muster court. Strict orthographic 90° overhead and north up, 1 world pixel to 1 image pixel, exactly 32px construction rhythm. Design a coherent walkable old civic ground material only: Dead civic training/deployment court floor with regular old rollcall rank etchings, graphite pavers and worn pale edge ticks. Binding: current HubFirstSetLayout.ENVELOPES.muster_court Rect2i(173,56,34,44); world (1408,-3712), MusterCenter (1952,-3008). Do not paint walls, colonnades, a raised dais, actual stairs, rooftops, vertical structures, impassable void, props, usable entrances, doors, collision obstacles, player, text, directional shadow, UI or false path. Structural geometry, details and skyline are separate manifest source states; this floor cannot invent them. Keep real marker positions and connector routes visually open; true gameplay navigation is owned by existing authored grid. No banner, contact sheet, picture-frame border, vignette or simulated transparent checkerboard. A standalone opaque 1-frame artwork source; record native dimensions and validate actual seamless adjacent contact at a separate runtime stage. Existing adjacent art is a design reference only unless actual bytes supplied and recorded. Source staging is candidate-only; human production approval and registration remain pending.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_muster_court_environment/underlay_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_muster_court_environment/underlay.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_muster_court_environment.asset.json`  
**Anchor/constraints:** HubFirstSetLayout.ENVELOPES.muster_court, 1px/world-unit candidate; Flat walkable-ground-only underlay within current HubFirstSetLayout.ENVELOPES.muster_court; architecture and solids separated into dedicated V2 props, preserve existing routes/markers and do not alter navigation  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** 2026-11-03 user-approved floor-first full-artwork roadmap; live HubFirstSetLayout.ENVELOPES.muster_court  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_continuity_port_environment/underlay`

**Set:** `B2-06`, order 123; **family:** `hub_first_set_continuity_port_environment`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 704x896px total; 1 frame(s), 704x896px per frame, `copy`, May be opaque inside exact approved playable footprint, no hard painted exterior rectangle or vignette.

**Generation prompt:** Generate exactly ONE independent 704x896 opaque RGB environment FLOOR-ONLY source for CUSTODIAN continuity port. Strict orthographic 90° overhead and north up, 1 world pixel to 1 image pixel, exactly 32px construction rhythm. Design a coherent walkable old civic ground material only: Portal-adjacent flat mechanical floor with dark basalt masonry and thin inlaid inactive bronze circuitry, no active portal object. Binding: current HubFirstSetLayout.ENVELOPES.continuity_port Rect2i(207,64,22,28); world (2496,-3456), port (2944,-3008), threshold (3136,-3008). Do not paint walls, colonnades, a raised dais, actual stairs, rooftops, vertical structures, impassable void, props, usable entrances, doors, collision obstacles, player, text, directional shadow, UI or false path. Structural geometry, details and skyline are separate manifest source states; this floor cannot invent them. Keep real marker positions and connector routes visually open; true gameplay navigation is owned by existing authored grid. No banner, contact sheet, picture-frame border, vignette or simulated transparent checkerboard. A standalone opaque 1-frame artwork source; record native dimensions and validate actual seamless adjacent contact at a separate runtime stage. Existing adjacent art is a design reference only unless actual bytes supplied and recorded. Source staging is candidate-only; human production approval and registration remain pending.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_continuity_port_environment/underlay_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_continuity_port_environment/underlay.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_continuity_port_environment.asset.json`  
**Anchor/constraints:** HubFirstSetLayout.ENVELOPES.continuity_port, 1px/world-unit candidate; Flat walkable-ground-only underlay within current HubFirstSetLayout.ENVELOPES.continuity_port; architecture and solids separated into dedicated V2 props, preserve existing routes/markers and do not alter navigation  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** 2026-11-03 user-approved floor-first full-artwork roadmap; live HubFirstSetLayout.ENVELOPES.continuity_port  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_connector_environment/road_north_transition`

**Set:** `B2-07`, order 124; **family:** `hub_first_set_connector_environment`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, true alpha outside intentional ground and architectural seam.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 256×256 pixels as a one-frame image. A physically believable stone and bronze ground join between the existing Road of Witnesses production modules and North Processional, no replacement of Road-owned source pixels or fake alternate street. true alpha outside intentional ground and architectural seam.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_connector_environment/road_north_transition_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_connector_environment/road_north_transition.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_connector_environment.asset.json`  
**Anchor/constraints:** Road module north seam, measured before source lock; underlay blend only; preserve real connectors and Road plates  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_connector_environment/muster_transition`

**Set:** `B2-08`, order 125; **family:** `hub_first_set_connector_environment`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 128x320px total; 1 frame(s), 128x320px per frame, `copy`, true alpha outside intentional ground and architectural seam.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 128×320 pixels as a one-frame image. One open 4-cell stone passage from Forum to Muster Court, ceremonial paving transitioning into rank/rollcall groove. No depicted gate or collision barrier. true alpha outside intentional ground and architectural seam. Exact LIVE HubFirstSetLayout anchor: muster_connector Rect2i(169,70,4,10). The intended passage is four cells wide, 32px per cell, and must remain fully open; this art cannot own navigation, route width or collision. Do not certify a neighbor seam without visually and byte-checking source pixels from the actual adjoining surfaces; until then staging is candidate-only.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_connector_environment/muster_transition_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_connector_environment/muster_transition.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_connector_environment.asset.json`  
**Anchor/constraints:** muster_connector Rect2i(169,70,4,10); underlay-floor blend only in the real open four-cell-wide connector; no architecture or obstacles inside corridor; test registered actual neighbor images before any runtime placement  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** Live HubFirstSetLayout.ENVELOPES 2026-11-03 connector-coordinate reconciliation; earlier B1/B2 anchor superseded  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_perimeter_support/western_burial_depth`

**Set:** `B2-09`, order 126; **family:** `hub_first_set_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 1024x768px total; 1 frame(s), 1024x768px per frame, `copy`, true RGBA around irregular inaccessible silhouette, no full-canvas black matte.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 1024×768 pixels as a one-frame image. Beyond the western Gardens, sealed ranked tomb terraces and collapsed tiny memorial stairs diminish into dark stone depth, visibly inaccessible and never a playable burial floor. true RGBA around irregular inaccessible silhouette, no full-canvas black matte.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_perimeter_support/western_burial_depth_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_perimeter_support/western_burial_depth.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; place ONLY after measured off-route camera coverage; no route/collision authority; lower contrast than playable floor  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_perimeter_support/eastern_civic_depth`

**Set:** `B2-10`, order 127; **family:** `hub_first_set_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 1024x768px total; 1 frame(s), 1024x768px per frame, `copy`, true RGBA around irregular inaccessible silhouette, no full-canvas black matte.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 1024×768 pixels as a one-frame image. Beyond Forum/Muster, roofless administrative annexes, dead colonnade footings and broken census courts, physically grounded and blocked from entry. true RGBA around irregular inaccessible silhouette, no full-canvas black matte.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_perimeter_support/eastern_civic_depth_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_perimeter_support/eastern_civic_depth.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; place ONLY after measured off-route camera coverage; no route/collision authority; lower contrast than playable floor  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_perimeter_support/north_archive_horizon`

**Set:** `B2-11`, order 128; **family:** `hub_first_set_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 1536x768px total; 1 frame(s), 1536x768px per frame, `copy`, true RGBA around irregular inaccessible silhouette, no full-canvas black matte.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 1536×768 pixels as a one-frame image. Far north stacked archive towers and registry wall foundations seen as a compressed overhead ruin silhouette, never a traversable secret road. true RGBA around irregular inaccessible silhouette, no full-canvas black matte.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_perimeter_support/north_archive_horizon_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_perimeter_support/north_archive_horizon.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; place ONLY after measured off-route camera coverage; no route/collision authority; lower contrast than playable floor  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_perimeter_support/south_processional_falloff`

**Set:** `B2-12`, order 129; **family:** `hub_first_set_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 1024x768px total; 1 frame(s), 1024x768px per frame, `copy`, true RGBA around irregular inaccessible silhouette, no full-canvas black matte.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 1024×768 pixels as a one-frame image. Outside the five existing Road modules, distant broken statue bases and incomplete roads fading into ashen civic collapse; do not repaint active South Reach. true RGBA around irregular inaccessible silhouette, no full-canvas black matte.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_perimeter_support/south_processional_falloff_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_perimeter_support/south_processional_falloff.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; place ONLY after measured off-route camera coverage; no route/collision authority; lower contrast than playable floor  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_perimeter_support/outer_court_fragments`

**Set:** `B2-13`, order 130; **family:** `hub_first_set_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 1024x768px total; 1 frame(s), 1024x768px per frame, `copy`, true RGBA around irregular inaccessible silhouette, no full-canvas black matte.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 1024×768 pixels as a one-frame image. Sparse corner-of-frame structural courts, disconnected roofless tribunal walls, snapped colonnade arcs and foundation rubble connected by plausible masonry shadows. true RGBA around irregular inaccessible silhouette, no full-canvas black matte.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_perimeter_support/outer_court_fragments_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_perimeter_support/outer_court_fragments.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; place ONLY after measured off-route camera coverage; no route/collision authority; lower contrast than playable floor  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_processional_fixtures/oath_statue_base`

**Set:** `B2-14`, order 131; **family:** `hub_first_set_processional_fixtures`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 192x192px total; 1 frame(s), 192x192px per frame, `copy`, true isolated RGBA, no full rectangular background.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 192×192 pixels as a one-frame image. West-edge broken oath-hero statue base with small boot/stone fragments and unreadable pledge relief, weathered foundation. true isolated RGBA, no full rectangular background.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_processional_fixtures/oath_statue_base_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_processional_fixtures/oath_statue_base.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_processional_fixtures.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; visual dressing; never change Dais, route or Port mechanic ownership  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_processional_fixtures/law_statue_base`

**Set:** `B2-14`, order 131; **family:** `hub_first_set_processional_fixtures`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 192x192px total; 1 frame(s), 192x192px per frame, `copy`, true isolated RGBA, no full rectangular background.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 192×192 pixels as a one-frame image. East-edge distinct old law-hero base with snapped proportional scales motif and layered civic bronze, not a mirrored oath statue. true isolated RGBA, no full rectangular background.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_processional_fixtures/law_statue_base_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_processional_fixtures/law_statue_base.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_processional_fixtures.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; visual dressing; never change Dais, route or Port mechanic ownership  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_forum_fixtures/fractured_star_map_inlay`

**Set:** `B2-15`, order 132; **family:** `hub_first_set_forum_fixtures`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, true isolated RGBA, no full rectangular background.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 512×512 pixels as a one-frame image. Large damaged radial star-chart floor insert with physically plausible concentric bronze and dark stone arcs, never a navigational or active lore UI. true isolated RGBA, no full rectangular background.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_forum_fixtures/fractured_star_map_inlay_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_forum_fixtures/fractured_star_map_inlay.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_forum_fixtures.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; visual dressing; never change Dais, route or Port mechanic ownership  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_forum_fixtures/dais_dressing`

**Set:** `B2-16`, order 133; **family:** `hub_first_set_forum_fixtures`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x256px total; 1 frame(s), 384x256px per frame, `copy`, true isolated RGBA, no full rectangular background.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 384×256 pixels as a one-frame image. Two collapsed half-height civic frame pieces that surround but do not duplicate or hide the already-interactive Forum Adjudication Dais. true isolated RGBA, no full rectangular background.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_forum_fixtures/dais_dressing_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_forum_fixtures/dais_dressing.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_forum_fixtures.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; visual dressing; never change Dais, route or Port mechanic ownership  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_archive_fixtures/collapsed_registry_arcade`

**Set:** `B2-17`, order 134; **family:** `hub_first_set_archive_fixtures`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 320x256px total; 1 frame(s), 320x256px per frame, `copy`, true isolated RGBA, no full rectangular background.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 320×256 pixels as a one-frame image. Collapsed open-air registry arcade with broken deep shelves under ash masonry, unreadable ledger remnants and impassable ruin. true isolated RGBA, no full rectangular background.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_archive_fixtures/collapsed_registry_arcade_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_archive_fixtures/collapsed_registry_arcade.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_archive_fixtures.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; visual dressing; never change Dais, route or Port mechanic ownership  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_crown_transfer_fixtures/route_anchor_shroud`

**Set:** `B2-18`, order 135; **family:** `hub_first_set_crown_transfer_fixtures`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x320px total; 1 frame(s), 256x320px per frame, `copy`, true isolated RGBA, no full rectangular background.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 256×320 pixels as a one-frame image. Dormant monumental route-machine shroud, interrupted filigree rails, inert armature and amethyst tarnish, leaves real route marker clear. true isolated RGBA, no full rectangular background.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_crown_transfer_fixtures/route_anchor_shroud_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_crown_transfer_fixtures/route_anchor_shroud.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_crown_transfer_fixtures.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; visual dressing; never change Dais, route or Port mechanic ownership  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_muster_fixtures/muster_rollcall_plinth`

**Set:** `B2-19`, order 136; **family:** `hub_first_set_muster_fixtures`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x192px total; 1 frame(s), 256x192px per frame, `copy`, true isolated RGBA, no full rectangular background.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 256×192 pixels as a one-frame image. Abandoned rollcall stand with dark stone plinth and worn brass index slots, no readable roster or active console. true isolated RGBA, no full rectangular background.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_muster_fixtures/muster_rollcall_plinth_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_muster_fixtures/muster_rollcall_plinth.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_muster_fixtures.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; visual dressing; never change Dais, route or Port mechanic ownership  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.

#### `hub_first_set_continuity_port_fixtures/port_frame_fascia`

**Set:** `B2-20`, order 137; **family:** `hub_first_set_continuity_port_fixtures`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x384px total; 1 frame(s), 384x384px per frame, `copy`, true isolated RGBA, no full rectangular background.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 384×384 pixels as a one-frame image. Heavily aged ordinary Continuity Port frame ribs, mechanical bronze/black basalt around existing portal path, no active gate FX or blocking collision. true isolated RGBA, no full rectangular background.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_continuity_port_fixtures/port_frame_fascia_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_continuity_port_fixtures/port_frame_fascia.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_continuity_port_fixtures.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; visual dressing; never change Dais, route or Port mechanic ownership  
**Consumer:** res://game/world/hub/first_set/hub_first_set_map.tscn:DistrictPresentation  
**Provenance:** new Hub V1 proposal under owner-approved art program  
**Approval/registration:** pending; proposed_not_registered. Candidate status: check live receipts separately.


### Additional Hub structural presentation

#### `hub_first_set_civic_structures_v2/processional_broken_hero_footing`

**Set:** `HUB-STRUCTURE-001`, order 138; **family:** `hub_first_set_civic_structures_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 512x256 true-RGBA source for hub_first_set_civic_structures_v2/processional_broken_hero_footing. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: One empty footed plinth once carrying an oath hero statue, sharply eroded pale limestone base and narrow damaged old bronze cornice. Source binding: North Processional offroute western margin. Placement/design guard: Cannot obstruct existing northbound road. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_civic_structures_v2/processional_broken_hero_footing_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_civic_structures_v2/processional_broken_hero_footing.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_civic_structures_v2.asset.json`  
**Anchor/constraints:** North Processional offroute western margin; actual placement dependent on authored separate spatial footprint; Cannot obstruct existing northbound road; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_scenic_structure_layer  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_civic_structures_v2/processional_law_pier`

**Set:** `HUB-STRUCTURE-002`, order 139; **family:** `hub_first_set_civic_structures_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x256px total; 1 frame(s), 384x256px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 384x256 true-RGBA source for hub_first_set_civic_structures_v2/processional_law_pier. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: Tall overhead base fragment of a broken law standard, side stone piers and hollow stone register shelf. Source binding: North Processional offroute eastern margin. Placement/design guard: Separate from the existing oath/law hero fixture asset states. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_civic_structures_v2/processional_law_pier_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_civic_structures_v2/processional_law_pier.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_civic_structures_v2.asset.json`  
**Anchor/constraints:** North Processional offroute eastern margin; actual placement dependent on authored separate spatial footprint; Separate from the existing oath/law hero fixture asset states; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_scenic_structure_layer  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_civic_structures_v2/ashen_forum_outer_council_coping`

**Set:** `HUB-STRUCTURE-003`, order 140; **family:** `hub_first_set_civic_structures_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 768x256px total; 1 frame(s), 768x256px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 768x256 true-RGBA source for hub_first_set_civic_structures_v2/ashen_forum_outer_council_coping. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: Long low broken civic council coping edge with dark basalt stones and chipped pale inscription rail with no readable lettering. Source binding: Ashen Forum offroute north-west perimeter. Placement/design guard: Do not duplicate Adjudication Dais or block Sepulcher access. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_civic_structures_v2/ashen_forum_outer_council_coping_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_civic_structures_v2/ashen_forum_outer_council_coping.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_civic_structures_v2.asset.json`  
**Anchor/constraints:** Ashen Forum offroute north-west perimeter; actual placement dependent on authored separate spatial footprint; Do not duplicate Adjudication Dais or block Sepulcher access; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_scenic_structure_layer  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_civic_structures_v2/ashen_forum_colonnade_relic`

**Set:** `HUB-STRUCTURE-004`, order 141; **family:** `hub_first_set_civic_structures_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x320px total; 1 frame(s), 512x320px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 512x320 true-RGBA source for hub_first_set_civic_structures_v2/ashen_forum_colonnade_relic. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: Three separated ruined old civic column foundations lying under soft ash in one long row. Source binding: Ashen Forum outer nonplayable margin. Placement/design guard: Dais (0,-3136) and all four Forum connectors remain open. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_civic_structures_v2/ashen_forum_colonnade_relic_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_civic_structures_v2/ashen_forum_colonnade_relic.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_civic_structures_v2.asset.json`  
**Anchor/constraints:** Ashen Forum outer nonplayable margin; actual placement dependent on authored separate spatial footprint; Dais (0,-3136) and all four Forum connectors remain open; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_scenic_structure_layer  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_civic_structures_v2/archive_rise_torn_terrace_wall`

**Set:** `HUB-STRUCTURE-005`, order 142; **family:** `hub_first_set_civic_structures_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 512x256 true-RGBA source for hub_first_set_civic_structures_v2/archive_rise_torn_terrace_wall. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: One tiered ruined library retaining fascia with no raised walkable steps, deep black basalt backing and silvered limestone top. Source binding: Archive Rise nonplayable old terrace edge. Placement/design guard: Do not create stair obstacle over current walkability. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_civic_structures_v2/archive_rise_torn_terrace_wall_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_civic_structures_v2/archive_rise_torn_terrace_wall.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_civic_structures_v2.asset.json`  
**Anchor/constraints:** Archive Rise nonplayable old terrace edge; actual placement dependent on authored separate spatial footprint; Do not create stair obstacle over current walkability; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_scenic_structure_layer  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_civic_structures_v2/archive_rise_broken_registry_pier`

**Set:** `HUB-STRUCTURE-006`, order 143; **family:** `hub_first_set_civic_structures_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x256px total; 1 frame(s), 384x256px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 384x256 true-RGBA source for hub_first_set_civic_structures_v2/archive_rise_broken_registry_pier. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: One heavy stone old registry pier with a corroded brass index rib and dust-clogged square recesses. Source binding: Archive Rise archive offroute hollow. Placement/design guard: No text or usable doorway. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_civic_structures_v2/archive_rise_broken_registry_pier_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_civic_structures_v2/archive_rise_broken_registry_pier.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_civic_structures_v2.asset.json`  
**Anchor/constraints:** Archive Rise archive offroute hollow; actual placement dependent on authored separate spatial footprint; No text or usable doorway; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_scenic_structure_layer  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_civic_structures_v2/crown_transfer_dead_causeway`

**Set:** `HUB-STRUCTURE-007`, order 144; **family:** `hub_first_set_civic_structures_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x192px total; 1 frame(s), 512x192px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 512x192 true-RGBA source for hub_first_set_civic_structures_v2/crown_transfer_dead_causeway. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: Low broken suspended-route foundation remnant seen entirely overhead, fractured stone and discarded metal mooring sockets. Source binding: Crown Transfer court outer scenic edge. Placement/design guard: Cannot change Twin Solaria handoff or Spawn_TwinReturn. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_civic_structures_v2/crown_transfer_dead_causeway_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_civic_structures_v2/crown_transfer_dead_causeway.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_civic_structures_v2.asset.json`  
**Anchor/constraints:** Crown Transfer court outer scenic edge; actual placement dependent on authored separate spatial footprint; Cannot change Twin Solaria handoff or Spawn_TwinReturn; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_scenic_structure_layer  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_civic_structures_v2/crown_transfer_inactive_arc`

**Set:** `HUB-STRUCTURE-008`, order 145; **family:** `hub_first_set_civic_structures_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x384px total; 1 frame(s), 384x384px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 384x384 true-RGBA source for hub_first_set_civic_structures_v2/crown_transfer_inactive_arc. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: One small incomplete stone and oxidized bronze transfer-calibration outer arc, silent and inert. Source binding: Crown Transfer offroute frame remnant. Placement/design guard: Not a functioning Crown Transfer portal or collision source. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_civic_structures_v2/crown_transfer_inactive_arc_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_civic_structures_v2/crown_transfer_inactive_arc.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_civic_structures_v2.asset.json`  
**Anchor/constraints:** Crown Transfer offroute frame remnant; actual placement dependent on authored separate spatial footprint; Not a functioning Crown Transfer portal or collision source; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_scenic_structure_layer  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_civic_structures_v2/muster_outer_rollcall_wall`

**Set:** `HUB-STRUCTURE-009`, order 146; **family:** `hub_first_set_civic_structures_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 512x256 true-RGBA source for hub_first_set_civic_structures_v2/muster_outer_rollcall_wall. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: Collapsed dry roster wall with old blank brass index plates and chipped dark stone copings. Source binding: Muster Court nonplayable western civic margin. Placement/design guard: Do not obstruct MusterCenter or Forum entrance. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_civic_structures_v2/muster_outer_rollcall_wall_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_civic_structures_v2/muster_outer_rollcall_wall.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_civic_structures_v2.asset.json`  
**Anchor/constraints:** Muster Court nonplayable western civic margin; actual placement dependent on authored separate spatial footprint; Do not obstruct MusterCenter or Forum entrance; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_scenic_structure_layer  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_civic_structures_v2/muster_rank_stand_remnant`

**Set:** `HUB-STRUCTURE-010`, order 147; **family:** `hub_first_set_civic_structures_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 320x192px total; 1 frame(s), 320x192px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 320x192 true-RGBA source for hub_first_set_civic_structures_v2/muster_rank_stand_remnant. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: One low disused stone rank stand base with flattened bronze parallel ridges and abandoned sockets. Source binding: Muster Court low offroute service apron. Placement/design guard: No interactive deployment element. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_civic_structures_v2/muster_rank_stand_remnant_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_civic_structures_v2/muster_rank_stand_remnant.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_civic_structures_v2.asset.json`  
**Anchor/constraints:** Muster Court low offroute service apron; actual placement dependent on authored separate spatial footprint; No interactive deployment element; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_scenic_structure_layer  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_civic_structures_v2/port_inactive_frame_footing`

**Set:** `HUB-STRUCTURE-011`, order 148; **family:** `hub_first_set_civic_structures_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x384px total; 1 frame(s), 384x384px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 384x384 true-RGBA source for hub_first_set_civic_structures_v2/port_inactive_frame_footing. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: A dead black civic-mechanical frame foundation, dark stone interlocking with copper brackets, incomplete upper ring. Source binding: Continuity Port chamber edge off route. Placement/design guard: Not active port or gameplay threshold. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_civic_structures_v2/port_inactive_frame_footing_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_civic_structures_v2/port_inactive_frame_footing.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_civic_structures_v2.asset.json`  
**Anchor/constraints:** Continuity Port chamber edge off route; actual placement dependent on authored separate spatial footprint; Not active port or gameplay threshold; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_scenic_structure_layer  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `hub_first_set_civic_structures_v2/port_service_conduit_fascia`

**Set:** `HUB-STRUCTURE-012`, order 149; **family:** `hub_first_set_civic_structures_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x192px total; 1 frame(s), 512x192px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 512x192 true-RGBA source for hub_first_set_civic_structures_v2/port_service_conduit_fascia. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: Short old service conduit casing and dark registry stone cap, oxidized bronze clamp ribs on upper surface. Source binding: Continuity Port floor side perimeter. Placement/design guard: Keep real return bay, port and east threshold walkable. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_civic_structures_v2/port_service_conduit_fascia_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_civic_structures_v2/port_service_conduit_fascia.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_civic_structures_v2.asset.json`  
**Anchor/constraints:** Continuity Port floor side perimeter; actual placement dependent on authored separate spatial footprint; Keep real return bay, port and east threshold walkable; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://game/world/hub/first_set/hub_first_set_map.tscn:independent_scenic_structure_layer  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.


### Existing Awakening perimeter sources

#### `awakening_creche_perimeter_support/distant_structures`

**Set:** `AP-01`, order 150; **family:** `awakening_creche_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 1024x512px total; 1 frame(s), 1024x512px per frame, `copy`, genuine RGBA transparent outside irregular silhouette.

**Generation prompt:** Produce one 1024×512 pixel **top-down overhead ruined-architecture silhouette** for Dormant Recovery Stacks. Depict receding banks of inert crèche alcoves interrupted by thick partition walls; different depths imply adjacent rooms but no doors. Architecture: serial recovery chambers, inactive body alcoves, separated vault cells and heavily insulated conduits. Materials: charcoal graphite ceramic, oxidized brass ID trims, matte medical-industrial panels, cold pinprick status lamps. Make each ruined structure visibly inaccessible by collapse, masonry or void; arrange high-level masses with believable foundations and subdued distant values. Transparent RGBA outside irregular nonplayable structures, never an opaque rectangular full-canvas matte. This should suggest one recovered Operator among hundreds of vacant/unresponsive units, and sit fully behind established gameplay art. No new entrances. One static isolated silhouette plate.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_creche_perimeter_support/distant_structures_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_creche_perimeter_support/distant_structures.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_creche_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_creche_perimeter_support/edge_transition`

**Set:** `AP-02`, order 151; **family:** `awakening_creche_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, genuine RGBA transparent outside irregular silhouette.

**Generation prompt:** Produce a single 256×256 **transparent RGBA overhead edge-transition decal** for the off-route margin of Crèche of Answerless Names. Include broken ceramic threshold, partially obscured dormant unit housing and wall debris fading into shadow. Follow the same existing top-down CUSTODIAN palette of charcoal graphite ceramic, oxidized brass ID trims, matte medical-industrial panels, cold pinprick status lamps. Irregular organically damaged silhouette and clean partially transparent erosion; subtle dark-to-haze visual falloff must not be baked as a solid square. It is a noninteractive support seam, not a corridor, gate or piece of playable ground. One static frame.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_creche_perimeter_support/edge_transition_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_creche_perimeter_support/edge_transition.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_creche_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_ambulatory_perimeter_support/structural_support`

**Set:** `AP-03`, order 152; **family:** `awakening_ambulatory_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, seamless repeat on all 4 edges.

**Generation prompt:** Produce one 512×512 pixel **seamless-tileable top-down foundation/rim texture** for Abandoned Processing Wards in CUSTODIAN's Awakening. Compose seamless outer ambulatory floor ribs and medical partition bases; cold ceramic with intermittent diagnostic inlays. Materials: aged pale bone ceramic, blackened glass, desaturated teal indicator glass, brushed brass medical fixtures. Every boundary repeats pixel-consistently; no standalone room center, no framing borders, no lighting vignette, no scenery implying a playable doorway. This is just the off-route lower architectural field beneath the existing Recovery Ambulatory production underlay. 1 static frame, native scale, overhead orthographic.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_ambulatory_perimeter_support/structural_support_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_ambulatory_perimeter_support/structural_support.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_ambulatory_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_ambulatory_perimeter_support/distant_structures`

**Set:** `AP-04`, order 153; **family:** `awakening_ambulatory_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 1024x512px total; 1 frame(s), 1024x512px per frame, `copy`, genuine RGBA transparent outside irregular silhouette.

**Generation prompt:** Produce one 1024×512 pixel **top-down overhead ruined-architecture silhouette** for Abandoned Processing Wards. Depict glimpses of sealed inspection corridors and dark glass wards beyond the ring; the central shaft falls downward into unlit structure. Architecture: octagonal circulation's surrounding medical processing cells, observation partitions and descending central service shaft. Materials: aged pale bone ceramic, blackened glass, desaturated teal indicator glass, brushed brass medical fixtures. Make each ruined structure visibly inaccessible by collapse, masonry or void; arrange high-level masses with believable foundations and subdued distant values. Transparent RGBA outside irregular nonplayable structures, never an opaque rectangular full-canvas matte. This should suggest the Crèche was a processing facility, not a lone awakening chamber, and sit fully behind established gameplay art. No new entrances. One static isolated silhouette plate.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_ambulatory_perimeter_support/distant_structures_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_ambulatory_perimeter_support/distant_structures.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_ambulatory_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_ambulatory_perimeter_support/edge_transition`

**Set:** `AP-05`, order 154; **family:** `awakening_ambulatory_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, genuine RGBA transparent outside irregular silhouette.

**Generation prompt:** Produce a single 256×256 **transparent RGBA overhead edge-transition decal** for the off-route margin of Recovery Ambulatory. Include broken medical glass, sheared observation rail, hanging insulated cable and faded processing diagram fragments. Follow the same existing top-down CUSTODIAN palette of aged pale bone ceramic, blackened glass, desaturated teal indicator glass, brushed brass medical fixtures. Irregular organically damaged silhouette and clean partially transparent erosion; subtle dark-to-haze visual falloff must not be baked as a solid square. It is a noninteractive support seam, not a corridor, gate or piece of playable ground. One static frame.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_ambulatory_perimeter_support/edge_transition_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_ambulatory_perimeter_support/edge_transition.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_ambulatory_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_attestation_perimeter_support/structural_support`

**Set:** `AP-06`, order 155; **family:** `awakening_attestation_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, seamless repeat on all 4 edges.

**Generation prompt:** Produce one 512×512 pixel **seamless-tileable top-down foundation/rim texture** for Silent Registry in CUSTODIAN's Awakening. Compose seamless formal registry foundation with linear record-bay plinths and precise seal borders. Materials: near-black dressed stone, bronze registry rails, aged parchment composite plates, soot-faded ivory seals. Every boundary repeats pixel-consistently; no standalone room center, no framing borders, no lighting vignette, no scenery implying a playable doorway. This is just the off-route lower architectural field beneath the existing Attestation Gallery production underlay. 1 static frame, native scale, overhead orthographic.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_attestation_perimeter_support/structural_support_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_attestation_perimeter_support/structural_support.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_attestation_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_attestation_perimeter_support/distant_structures`

**Set:** `AP-07`, order 156; **family:** `awakening_attestation_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 1024x512px total; 1 frame(s), 1024x512px per frame, `copy`, genuine RGBA transparent outside irregular silhouette.

**Generation prompt:** Produce one 1024×512 pixel **top-down overhead ruined-architecture silhouette** for Silent Registry. Depict sealed side archive halls, high-ranked shelves holding fragmented identity records, fallen ceremonial columns. Architecture: side archives and long ranked record stacks behind rows of authority attestation steles. Materials: near-black dressed stone, bronze registry rails, aged parchment composite plates, soot-faded ivory seals. Make each ruined structure visibly inaccessible by collapse, masonry or void; arrange high-level masses with believable foundations and subdued distant values. Transparent RGBA outside irregular nonplayable structures, never an opaque rectangular full-canvas matte. This should suggest identity verification once demanded a sprawling bureaucracy, and sit fully behind established gameplay art. No new entrances. One static isolated silhouette plate.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_attestation_perimeter_support/distant_structures_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_attestation_perimeter_support/distant_structures.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_attestation_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_attestation_perimeter_support/edge_transition`

**Set:** `AP-08`, order 157; **family:** `awakening_attestation_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, genuine RGBA transparent outside irregular silhouette.

**Generation prompt:** Produce a single 256×256 **transparent RGBA overhead edge-transition decal** for the off-route margin of Attestation Gallery. Include stone fragments, shattered authority tablet fragments and dust-filled gaps between archival shelves. Follow the same existing top-down CUSTODIAN palette of near-black dressed stone, bronze registry rails, aged parchment composite plates, soot-faded ivory seals. Irregular organically damaged silhouette and clean partially transparent erosion; subtle dark-to-haze visual falloff must not be baked as a solid square. It is a noninteractive support seam, not a corridor, gate or piece of playable ground. One static frame.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_attestation_perimeter_support/edge_transition_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_attestation_perimeter_support/edge_transition.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_attestation_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_locker_reliquary_perimeter_support/structural_support`

**Set:** `AP-09`, order 158; **family:** `awakening_locker_reliquary_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, seamless repeat on all 4 edges.

**Generation prompt:** Produce one 512×512 pixel **seamless-tileable top-down foundation/rim texture** for Sealed Armament Annex in CUSTODIAN's Awakening. Compose seamless fortified equipment-annex outer footing and inset empty rack bases with worn security markings. Materials: smoked gunmetal, dark basalt flooring, brushed brass designation rails, faded amber lock indicators. Every boundary repeats pixel-consistently; no standalone room center, no framing borders, no lighting vignette, no scenery implying a playable doorway. This is just the off-route lower architectural field beneath the existing Locker Reliquary production underlay. 1 static frame, native scale, overhead orthographic.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_locker_reliquary_perimeter_support/structural_support_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_locker_reliquary_perimeter_support/structural_support.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_locker_reliquary_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_locker_reliquary_perimeter_support/distant_structures`

**Set:** `AP-10`, order 159; **family:** `awakening_locker_reliquary_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 1024x512px total; 1 frame(s), 1024x512px per frame, `copy`, genuine RGBA transparent outside irregular silhouette.

**Generation prompt:** Produce one 1024×512 pixel **top-down overhead ruined-architecture silhouette** for Sealed Armament Annex. Depict receding inaccessible locker banks and immense welded armory bulkheads; locked void bays, no open side passage. Architecture: inaccessible designation-keyed vault banks, reinforced armament racks, sealed security compartments. Materials: smoked gunmetal, dark basalt flooring, brushed brass designation rails, faded amber lock indicators. Make each ruined structure visibly inaccessible by collapse, masonry or void; arrange high-level masses with believable foundations and subdued distant values. Transparent RGBA outside irregular nonplayable structures, never an opaque rectangular full-canvas matte. This should suggest P-9 issuance is a narrow surviving right, not general arsenal access, and sit fully behind established gameplay art. No new entrances. One static isolated silhouette plate.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_locker_reliquary_perimeter_support/distant_structures_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_locker_reliquary_perimeter_support/distant_structures.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_locker_reliquary_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_locker_reliquary_perimeter_support/edge_transition`

**Set:** `AP-11`, order 160; **family:** `awakening_locker_reliquary_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, genuine RGBA transparent outside irregular silhouette.

**Generation prompt:** Produce a single 256×256 **transparent RGBA overhead edge-transition decal** for the off-route margin of Locker Reliquary. Include frayed conduits, armory debris, severed latch rails and cracked floor security threshold. Follow the same existing top-down CUSTODIAN palette of smoked gunmetal, dark basalt flooring, brushed brass designation rails, faded amber lock indicators. Irregular organically damaged silhouette and clean partially transparent erosion; subtle dark-to-haze visual falloff must not be baked as a solid square. It is a noninteractive support seam, not a corridor, gate or piece of playable ground. One static frame.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_locker_reliquary_perimeter_support/edge_transition_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_locker_reliquary_perimeter_support/edge_transition.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_locker_reliquary_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_undergate_perimeter_support/structural_support`

**Set:** `AP-12`, order 161; **family:** `awakening_undergate_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, seamless repeat on all 4 edges.

**Generation prompt:** Produce one 512×512 pixel **seamless-tileable top-down foundation/rim texture** for Buried Routeworks in CUSTODIAN's Awakening. Compose seamless industrial nave perimeter base with repeating bolted machine foundations and routing channels. Materials: oil-dark iron, lead-grey masonry, dull brass coils, worn calibration enamel, tiny dim indicator cyan. Every boundary repeats pixel-consistently; no standalone room center, no framing borders, no lighting vignette, no scenery implying a playable doorway. This is just the off-route lower architectural field beneath the existing Undergate Mechanism Hall production underlay. 1 static frame, native scale, overhead orthographic.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_undergate_perimeter_support/structural_support_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_undergate_perimeter_support/structural_support.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_undergate_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_undergate_perimeter_support/distant_structures`

**Set:** `AP-13`, order 162; **family:** `awakening_undergate_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 1024x512px total; 1 frame(s), 1024x512px per frame, `copy`, genuine RGBA transparent outside irregular silhouette.

**Generation prompt:** Produce one 1024×512 pixel **top-down overhead ruined-architecture silhouette** for Buried Routeworks. Depict immense sealed gear chambers, heavy lift housings, dark cable galleries, and partly collapsed west records vault. Architecture: immense blind pressure and route-indexing mechanisms, gear housings, cable galleries and west-side departure records. Materials: oil-dark iron, lead-grey masonry, dull brass coils, worn calibration enamel, tiny dim indicator cyan. Make each ruined structure visibly inaccessible by collapse, masonry or void; arrange high-level masses with believable foundations and subdued distant values. Transparent RGBA outside irregular nonplayable structures, never an opaque rectangular full-canvas matte. This should suggest the player's mechanisms are exposed fragments of a city-scale transport system, and sit fully behind established gameplay art. No new entrances. One static isolated silhouette plate.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_undergate_perimeter_support/distant_structures_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_undergate_perimeter_support/distant_structures.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_undergate_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_undergate_perimeter_support/edge_transition`

**Set:** `AP-14`, order 163; **family:** `awakening_undergate_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, genuine RGBA transparent outside irregular silhouette.

**Generation prompt:** Produce a single 256×256 **transparent RGBA overhead edge-transition decal** for the off-route margin of Undergate Mechanism Hall. Include severed bundled cables, cracked machine shroud, broken index dials and collapsed engineering stone. Follow the same existing top-down CUSTODIAN palette of oil-dark iron, lead-grey masonry, dull brass coils, worn calibration enamel, tiny dim indicator cyan. Irregular organically damaged silhouette and clean partially transparent erosion; subtle dark-to-haze visual falloff must not be baked as a solid square. It is a noninteractive support seam, not a corridor, gate or piece of playable ground. One static frame.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_undergate_perimeter_support/edge_transition_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_undergate_perimeter_support/edge_transition.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_undergate_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_gate_of_dust_perimeter_support/structural_support`

**Set:** `AP-15`, order 164; **family:** `awakening_gate_of_dust_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, seamless repeat on all 4 edges.

**Generation prompt:** Produce one 512×512 pixel **seamless-tileable top-down foundation/rim texture** for Ruined Threshold District in CUSTODIAN's Awakening. Compose seamless city-gate apron foundations with cracked civic paving and scattered shallow ash drifts. Materials: smoke-stained monumental limestone, dark civic basalt, tarnished bronze, ashen sand, rust-red dust. Every boundary repeats pixel-consistently; no standalone room center, no framing borders, no lighting vignette, no scenery implying a playable doorway. This is just the off-route lower architectural field beneath the existing Gate of Dust production underlay. 1 static frame, native scale, overhead orthographic.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_gate_of_dust_perimeter_support/structural_support_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_gate_of_dust_perimeter_support/structural_support.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_gate_of_dust_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; do not seal real east/west Gate stairs; existing AP3 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_gate_of_dust_perimeter_support/edge_transition`

**Set:** `AP-16`, order 165; **family:** `awakening_gate_of_dust_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, genuine RGBA transparent outside irregular silhouette.

**Generation prompt:** Produce a single 256×256 **transparent RGBA overhead edge-transition decal** for the off-route margin of Gate of Dust. Include fractured gate-era parapet, broken relief sculpture and windswept ash at a genuinely nonplayable masonry edge OUTSIDE the pre-existing east/west Gate stair-mouth corridors. Protect both real stairway apertures for later explicit spatial decisions. Follow the same existing top-down CUSTODIAN palette of smoke-stained monumental limestone, dark civic basalt, tarnished bronze, ashen sand, rust-red dust. Irregular organically damaged silhouette and clean partially transparent erosion; subtle dark-to-haze visual falloff must not be baked as a solid square. It is a noninteractive support seam, not a corridor, gate or piece of playable ground. One static frame.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_gate_of_dust_perimeter_support/edge_transition_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_gate_of_dust_perimeter_support/edge_transition.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_gate_of_dust_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; do not seal real east/west Gate stairs; existing AP3 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_approach_perimeter_support/structural_support`

**Set:** `AP-17`, order 166; **family:** `awakening_approach_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, seamless repeat on all 4 edges.

**Generation prompt:** Produce one 512×512 pixel **seamless-tileable top-down foundation/rim texture** for Dead Processional Quarter in CUSTODIAN's Awakening. Compose seamless outer civic-processional pavement and weed-bound retaining-footing texture. Materials: pale ashen stone, dark slate processional paving, subdued bronze, dead grasses, muted rust patina. Every boundary repeats pixel-consistently; no standalone room center, no framing borders, no lighting vignette, no scenery implying a playable doorway. This is just the off-route lower architectural field beneath the existing Custodian Approach production underlay. 1 static frame, native scale, overhead orthographic.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_approach_perimeter_support/structural_support_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_approach_perimeter_support/structural_support.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_approach_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_approach_perimeter_support/distant_structures`

**Set:** `AP-18`, order 167; **family:** `awakening_approach_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 1024x512px total; 1 frame(s), 1024x512px per frame, `copy`, genuine RGBA transparent outside irregular silhouette.

**Generation prompt:** Produce one 1024×512 pixel **top-down overhead ruined-architecture silhouette** for Dead Processional Quarter. Depict collapsed roadside chapel shells, ruined statuary, burial terraces and branching streets ending behind rubble. Architecture: burial terraces, ruined chapel shells, fractured civic gardens and abandoned processional side streets. Materials: pale ashen stone, dark slate processional paving, subdued bronze, dead grasses, muted rust patina. Make each ruined structure visibly inaccessible by collapse, masonry or void; arrange high-level masses with believable foundations and subdued distant values. Transparent RGBA outside irregular nonplayable structures, never an opaque rectangular full-canvas matte. This should suggest history, burial and civic memory gradually replace sterile machinery, and sit fully behind established gameplay art. No new entrances. One static isolated silhouette plate.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_approach_perimeter_support/distant_structures_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_approach_perimeter_support/distant_structures.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_approach_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_approach_perimeter_support/edge_transition`

**Set:** `AP-19`, order 168; **family:** `awakening_approach_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, genuine RGBA transparent outside irregular silhouette.

**Generation prompt:** Produce a single 256×256 **transparent RGBA overhead edge-transition decal** for the off-route margin of Custodian Approach. Include uprooted stone garden edge, dead growth, fractured votive slabs and rubble obscuring any apparent side route. Follow the same existing top-down CUSTODIAN palette of pale ashen stone, dark slate processional paving, subdued bronze, dead grasses, muted rust patina. Irregular organically damaged silhouette and clean partially transparent erosion; subtle dark-to-haze visual falloff must not be baked as a solid square. It is a noninteractive support seam, not a corridor, gate or piece of playable ground. One static frame.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_approach_perimeter_support/edge_transition_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_approach_perimeter_support/edge_transition.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_approach_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_late_service_perimeter_support/structural_support`

**Set:** `AP-20`, order 169; **family:** `awakening_late_service_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, seamless repeat on all 4 edges.

**Generation prompt:** Produce one 512×512 pixel **seamless-tileable top-down foundation/rim texture** for Forgotten Devotional Precinct in CUSTODIAN's Awakening. Compose seamless devotional precinct perimeter flagstone with worn memorial engraving and shallow root scars. Materials: smoked limestone, desaturated bronze votive details, weathered linen banners, chalk white thread. Every boundary repeats pixel-consistently; no standalone room center, no framing borders, no lighting vignette, no scenery implying a playable doorway. This is just the off-route lower architectural field beneath the existing Chapel of Late Service production underlay. 1 static frame, native scale, overhead orthographic.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_late_service_perimeter_support/structural_support_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_late_service_perimeter_support/structural_support.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_late_service_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_late_service_perimeter_support/distant_structures`

**Set:** `AP-21`, order 170; **family:** `awakening_late_service_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 1024x512px total; 1 frame(s), 1024x512px per frame, `copy`, genuine RGBA transparent outside irregular silhouette.

**Generation prompt:** Produce one 1024×512 pixel **top-down overhead ruined-architecture silhouette** for Forgotten Devotional Precinct. Depict collapsed side cloisters and side shrines lined with unlit lamps and faded banners; no open routes. Architecture: inaccessible cloisters, broken side shrines, memorial galleries and retired relay-lamp service conduits. Materials: smoked limestone, desaturated bronze votive details, weathered linen banners, chalk white thread. Make each ruined structure visibly inaccessible by collapse, masonry or void; arrange high-level masses with believable foundations and subdued distant values. Transparent RGBA outside irregular nonplayable structures, never an opaque rectangular full-canvas matte. This should suggest people ritualized pieces of the abandoned institution after official service ended, and sit fully behind established gameplay art. No new entrances. One static isolated silhouette plate.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_late_service_perimeter_support/distant_structures_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_late_service_perimeter_support/distant_structures.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_late_service_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_late_service_perimeter_support/edge_transition`

**Set:** `AP-22`, order 171; **family:** `awakening_late_service_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, genuine RGBA transparent outside irregular silhouette.

**Generation prompt:** Produce a single 256×256 **transparent RGBA overhead edge-transition decal** for the off-route margin of Chapel of Late Service. Include broken shrine threshold, torn ceremonial textile, dust-covered memorial fragments and white thread ties. Follow the same existing top-down CUSTODIAN palette of smoked limestone, desaturated bronze votive details, weathered linen banners, chalk white thread. Irregular organically damaged silhouette and clean partially transparent erosion; subtle dark-to-haze visual falloff must not be baked as a solid square. It is a noninteractive support seam, not a corridor, gate or piece of playable ground. One static frame.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_late_service_perimeter_support/edge_transition_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_late_service_perimeter_support/edge_transition.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_late_service_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_road_south_reach_perimeter_support/structural_support`

**Set:** `AP-23`, order 172; **family:** `awakening_road_south_reach_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 512x512px total; 1 frame(s), 512x512px per frame, `copy`, seamless repeat on all 4 edges.

**Generation prompt:** Produce one 512×512 pixel **seamless-tileable top-down foundation/rim texture** for Fallen Civic Expanse in CUSTODIAN's Awakening. Compose seamless old civic road foundation with chipped processional paving, grout cracks and buried city edges. Materials: worn dark civic basalt, sun-bleached limestone, dulled brass wayfinding, low dusty rust and grey haze. Every boundary repeats pixel-consistently; no standalone room center, no framing borders, no lighting vignette, no scenery implying a playable doorway. This is just the off-route lower architectural field beneath the existing Road of Witnesses: South Reach production underlay. 1 static frame, native scale, overhead orthographic.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_road_south_reach_perimeter_support/structural_support_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_road_south_reach_perimeter_support/structural_support.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_road_south_reach_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.

#### `awakening_road_south_reach_perimeter_support/distant_structures`

**Set:** `AP-24`, order 173; **family:** `awakening_road_south_reach_perimeter_support`; **core:** yes; **kind:** backdrop; **priority:** P1.

**Target:** 1024x512px total; 1 frame(s), 1024x512px per frame, `copy`, genuine RGBA transparent outside irregular silhouette.

**Generation prompt:** Produce one 1024×512 pixel **top-down overhead ruined-architecture silhouette** for Fallen Civic Expanse. Depict distant ruined administrative arcades, plazas, colonnades, toppled civic arches and blocked branching streets. Architecture: collapsed colonnades, broken civic plazas, inaccessible avenues, distant administrative towers and city foundations. Materials: worn dark civic basalt, sun-bleached limestone, dulled brass wayfinding, low dusty rust and grey haze. Make each ruined structure visibly inaccessible by collapse, masonry or void; arrange high-level masses with believable foundations and subdued distant values. Transparent RGBA outside irregular nonplayable structures, never an opaque rectangular full-canvas matte. This should suggest the Road belongs to a much larger dead city; north barricade still closes the prologue, and sit fully behind established gameplay art. No new entrances. Concentrate architecture in lateral ruined arcades and distant civic edges; keep the center open/transparent so no second road, central boulevard, plaza axis, northern opening, or route indication competes with the existing Road. Verify composition against all five registered Road modules and the South Reach 768×896 vertical civic-axis plate, using no replacement paving and no new northward passage. One static isolated silhouette plate.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_road_south_reach_perimeter_support/distant_structures_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_road_south_reach_perimeter_support/distant_structures.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_road_south_reach_perimeter_support.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; nonplayable support only; existing AP1–AP4 authority  
**Consumer:** res://game/world/awakening/awakening_perimeter_support.gd  
**Provenance:** design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md  
**Approval/registration:** pending; already_registered. Candidate status: check live receipts separately.


### Additional Awakening narrative props

#### `awakening_environment_story_v2/creche_cold_record_tray`

**Set:** `AW-DETAIL-001`, order 174; **family:** `awakening_environment_story_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x192px total; 1 frame(s), 256x192px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 256x192 true-RGBA source for awakening_environment_story_v2/creche_cold_record_tray. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: One abandoned low ash-steel nursery record tray with empty dark narrow vials and enameled pale dividers. Source binding: Awakening Crèche off-path institutional bench. Placement/design guard: No character, loot, power-on screens or health gameplay. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_environment_story_v2/creche_cold_record_tray_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_environment_story_v2/creche_cold_record_tray.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_environment_story_v2.asset.json`  
**Anchor/constraints:** Awakening Crèche off-path institutional bench; actual placement dependent on authored separate spatial footprint; No character, loot, power-on screens or health gameplay; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://scenes/awakening_first_return.tscn:AP_perimeter_support_separate_review  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `awakening_environment_story_v2/ambulatory_broken_service_cabinet`

**Set:** `AW-DETAIL-002`, order 175; **family:** `awakening_environment_story_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 256x256 true-RGBA source for awakening_environment_story_v2/ambulatory_broken_service_cabinet. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: One tilted empty hospital-civic cabinet with chipped stone-like porcelain door and dark bronze trim. Source binding: Awakening Ambulatory offroute old service alcove. Placement/design guard: Do not create a new interactable cabinet. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_environment_story_v2/ambulatory_broken_service_cabinet_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_environment_story_v2/ambulatory_broken_service_cabinet.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_environment_story_v2.asset.json`  
**Anchor/constraints:** Awakening Ambulatory offroute old service alcove; actual placement dependent on authored separate spatial footprint; Do not create a new interactable cabinet; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://scenes/awakening_first_return.tscn:AP_perimeter_support_separate_review  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `awakening_environment_story_v2/attestation_blank_ledger_altar`

**Set:** `AW-DETAIL-003`, order 176; **family:** `awakening_environment_story_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x256px total; 1 frame(s), 384x256px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 384x256 true-RGBA source for awakening_environment_story_v2/attestation_blank_ledger_altar. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: One mute graphite archive altar bearing unreadable blank stone register plates and pale mineral dust. Source binding: Awakening Attestation near old wall but offroute. Placement/design guard: No readable scripted testimony or interactive action. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_environment_story_v2/attestation_blank_ledger_altar_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_environment_story_v2/attestation_blank_ledger_altar.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_environment_story_v2.asset.json`  
**Anchor/constraints:** Awakening Attestation near old wall but offroute; actual placement dependent on authored separate spatial footprint; No readable scripted testimony or interactive action; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://scenes/awakening_first_return.tscn:AP_perimeter_support_separate_review  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `awakening_environment_story_v2/locker_reliquary_iron_hooks`

**Set:** `AW-DETAIL-004`, order 177; **family:** `awakening_environment_story_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x192px total; 1 frame(s), 256x192px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 256x192 true-RGBA source for awakening_environment_story_v2/locker_reliquary_iron_hooks. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: One row of old bronze clothing hooks on a flaking charcoal stone support with two missing fixtures. Source binding: Awakening Locker Reliquary nonwalkable upper alcove. Placement/design guard: No hanging items or loot. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_environment_story_v2/locker_reliquary_iron_hooks_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_environment_story_v2/locker_reliquary_iron_hooks.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_environment_story_v2.asset.json`  
**Anchor/constraints:** Awakening Locker Reliquary nonwalkable upper alcove; actual placement dependent on authored separate spatial footprint; No hanging items or loot; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://scenes/awakening_first_return.tscn:AP_perimeter_support_separate_review  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `awakening_environment_story_v2/gate_of_dust_lost_civic_seal`

**Set:** `AW-DETAIL-005`, order 178; **family:** `awakening_environment_story_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x256px total; 1 frame(s), 384x256px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 384x256 true-RGBA source for awakening_environment_story_v2/gate_of_dust_lost_civic_seal. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: One heavily eroded old civic stone seal block with broken bronze concentric ribs and no legible emblem. Source binding: Awakening Gate of Dust exterior nonplayable edge. Placement/design guard: Must not fake a new gate or stair. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_environment_story_v2/gate_of_dust_lost_civic_seal_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_environment_story_v2/gate_of_dust_lost_civic_seal.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_environment_story_v2.asset.json`  
**Anchor/constraints:** Awakening Gate of Dust exterior nonplayable edge; actual placement dependent on authored separate spatial footprint; Must not fake a new gate or stair; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://scenes/awakening_first_return.tscn:AP_perimeter_support_separate_review  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `awakening_environment_story_v2/south_reach_abandoned_marker`

**Set:** `AW-DETAIL-006`, order 179; **family:** `awakening_environment_story_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 256x256px total; 1 frame(s), 256x256px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 256x256 true-RGBA source for awakening_environment_story_v2/south_reach_abandoned_marker. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: One chipped low road registry plinth, ash grey limestone and a snapped oxidized copper index spine. Source binding: Awakening Road South Reach offroad scenic edge. Placement/design guard: Keep existing Road of Witnesses five-pair presentation and southern ingress open. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_environment_story_v2/south_reach_abandoned_marker_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_environment_story_v2/south_reach_abandoned_marker.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_environment_story_v2.asset.json`  
**Anchor/constraints:** Awakening Road South Reach offroad scenic edge; actual placement dependent on authored separate spatial footprint; Keep existing Road of Witnesses five-pair presentation and southern ingress open; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://scenes/awakening_first_return.tscn:AP_perimeter_support_separate_review  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.


### Original Dust Lung V2 owner sources

#### `awakening_dust_lung_environment_v2/north_upper_works`

**Set:** `DL-01`, order 180; **family:** `awakening_dust_lung_environment_v2`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 2048x1024px total; 1 frame(s), 2048x1024px per frame, `copy`, opaque within intended registered architectural footprint.

**Generation prompt:** Create one high-resolution 2048×1024 top-down / high aerial-oblique game environment underlay for CUSTODIAN's Awakening, Dust Lung Cistern V2: North Upper Works. This is the surviving upper cistern service deck that receives the player after a western maintenance lift and compresses northward into the Undergate. Preserve the accepted Dust Lung material language: cold charcoal masonry, oil-dark pipe iron, rust, chalky mineral residue, ashen sediment, broken aged-brass institutional linework, sparse cyan service lamps, pale-blue abyssal haze below. Compose a broad, clearly playable central route entering from the lower-left / west-central side and turning north into one unmistakable top-center exit throat. The walkable deck must be wide enough to read as normal gameplay floor, with continuous floor texture, edge curbs, grates and safe staging space. To either side, show enormous inaccessible cistern depth, pipe banks, broken maintenance balconies and distant rings. The route should become more ordered and mechanically dense as it approaches the north exit, foreshadowing Undergate routeworks. Do not place a second usable exit. Do not make the room symmetrical or ceremonial. No characters, text, UI, arrows or interaction prompts. No horizon. One static frame.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/north_upper_works_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/north_upper_works.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_environment_v2.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; dedicated Dust Lung V2 source review and DL0 spatial cutover; do not replace live 04→05 composite or old fallback without approval  
**Consumer:** res://scenes/awakening_first_return.tscn:separate_DL0_cutover  
**Provenance:** design/04_architecture/AWAKENING_DUST_LUNG_V2_ASSET_MANIFEST.md  
**Approval/registration:** pending; planned_not_registered_separate_owner. Candidate status: check live receipts separately.

#### `awakening_dust_lung_environment_v2/central_broken_service_spine`

**Set:** `DL-02`, order 181; **family:** `awakening_dust_lung_environment_v2`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 1536x2048px total; 1 frame(s), 1536x2048px per frame, `copy`, opaque within intended registered architectural footprint.

**Generation prompt:** Create one high-resolution 1536×2048 top-down / high aerial-oblique game underlay for CUSTODIAN Awakening's Dust Lung V2 Central Broken Service Spine. This plate carries the primary lower traversal after the player sees the vast cistern rupture. The main readable floor must enter from the right/east-lower side, continue west across the lower-middle of the image, then narrow toward a western maintenance-lift approach. Make the canonical route broad, continuous and unmistakably walkable, with old institutional paving, service grates, interrupted brass route lines, broken railings and accumulated dust. Surround it with collapsed bridge fragments, snapped pipe galleries, inaccessible maintenance ledges and deep pale-blue shaft void. Show the remains of an obvious former/direct route that has failed, so the surviving westbound route feels like an improvised detour. Distant catwalks must be visibly broken, narrow, disconnected or below the playable elevation so they do not promise traversal. Materials: charcoal stone, blackened/rusted iron, mineral crust, ash, aged brass, sparse cyan service lamps. Avoid symmetry, arena framing and decorative central-hole composition. No characters, labels, UI, arrows or prompts. One static frame.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/central_broken_service_spine_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/central_broken_service_spine.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_environment_v2.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; dedicated Dust Lung V2 source review and DL0 spatial cutover; do not replace live 04→05 composite or old fallback without approval  
**Consumer:** res://scenes/awakening_first_return.tscn:separate_DL0_cutover  
**Provenance:** design/04_architecture/AWAKENING_DUST_LUNG_V2_ASSET_MANIFEST.md  
**Approval/registration:** pending; planned_not_registered_separate_owner. Candidate status: check live receipts separately.

#### `awakening_dust_lung_environment_v2/western_lift_spine`

**Set:** `DL-03`, order 182; **family:** `awakening_dust_lung_environment_v2`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 1024x1536px total; 1 frame(s), 1024x1536px per frame, `copy`, opaque within intended registered architectural footprint.

**Generation prompt:** Create one high-resolution 1024×1536 top-down / high aerial-oblique environment underlay for CUSTODIAN Awakening's Dust Lung V2 Western Service Lift Spine. This is not a clean elevator room. It is a stubborn, half-ruined vertical maintenance mechanism bridging two surviving decks over an enormous dry cistern. At the lower-right / lower-center, provide a broad intact service landing that connects naturally to the westbound lower route. Leave a clear rectangular interaction pad where the separate runtime lift and lever can be placed. Through the center-left, show a tall vertical lift apparatus: heavy rails, cable drums, counterweight tracks, exposed chains, guide frames, pipe trunks, maintenance brackets and sparse cyan service lamps. At the upper-left / upper-center, provide a second broad safe landing that connects toward the north upper works. The lower and upper floors must be visually distinct elevations connected by the machine, not by an ordinary staircase that bypasses the lift. Surround the machinery with hard void, ruined inaccessible platforms and deep pale-blue industrial haze. Preserve cold charcoal masonry, oil-dark/rusted iron, chalky mineral residue, ashen dust, interrupted aged brass linework. Do not bake a character, lever, usable console, text, arrows or UI into the plate. One static frame.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/western_lift_spine_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/western_lift_spine.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_environment_v2.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; dedicated Dust Lung V2 source review and DL0 spatial cutover; do not replace live 04→05 composite or old fallback without approval  
**Consumer:** res://scenes/awakening_first_return.tscn:separate_DL0_cutover  
**Provenance:** design/04_architecture/AWAKENING_DUST_LUNG_V2_ASSET_MANIFEST.md  
**Approval/registration:** pending; planned_not_registered_separate_owner. Candidate status: check live receipts separately.

#### `awakening_dust_lung_environment_v2/cistern_core`

**Set:** `DL-04`, order 183; **family:** `awakening_dust_lung_environment_v2`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 2048x2048px total; 1 frame(s), 2048x2048px per frame, `copy`, opaque within intended registered architectural footprint.

**Generation prompt:** Create one high-resolution 2048×2048 top-down / high aerial-oblique hero underlay for CUSTODIAN Awakening's Dust Lung V2 Cistern Core. Depict a colossal dry civic-industrial reservoir rupture that extends far below the playable route. The center and majority of the plate are hard void / inaccessible depth, with multiple descending maintenance rings, enormous vertical pipe banks, dead intake trunks, mineral tide marks, fractured galleries, tiny cyan service lights and pale-blue haze establishing immense scale. Around only selected edges, include broad surviving deck/rim fragments suitable for composition with adjacent playable plates. Those floor fragments must have clear curb/edge treatment and must not imply a complete ring around the shaft. Show evidence that this was once ordered institutional infrastructure: aged brass route inlays, repeated structural ribs and service lamps, now interrupted by collapse, ash and mineral deposits. Avoid a clean octagonal arena, perfect symmetry, or a single neat hole surrounded by a complete room. No characters, text, UI, arrows, prompts or horizon. One static frame.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/cistern_core_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/cistern_core.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_environment_v2.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; dedicated Dust Lung V2 source review and DL0 spatial cutover; do not replace live 04→05 composite or old fallback without approval  
**Consumer:** res://scenes/awakening_first_return.tscn:separate_DL0_cutover  
**Provenance:** design/04_architecture/AWAKENING_DUST_LUNG_V2_ASSET_MANIFEST.md  
**Approval/registration:** pending; planned_not_registered_separate_owner. Candidate status: check live receipts separately.

#### `awakening_dust_lung_environment_v2/deep_cistern_field`

**Set:** `DL-05`, order 184; **family:** `awakening_dust_lung_environment_v2`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 2048x2048px total; 1 frame(s), 2048x2048px per frame, `copy`, opaque within intended registered architectural footprint.

**Generation prompt:** Create one high-resolution 2048×2048 top-down / high aerial-oblique deep background underlay for CUSTODIAN Awakening's Dust Lung V2 Deep Cistern Field. This plate owns unreachable depth beneath the playable structures. Fill it with enormous descending reservoir walls, multiple far-lower maintenance rings, distant pipe trunks, broken suspended galleries, tiny cyan service lamps, mineral-stained masonry and pale-blue particulate haze. The composition must feel hundreds of feet below the player. Any catwalks or platforms visible here must be narrow, distant, interrupted, shadowed or obviously disconnected; do not paint broad current-elevation walkable floor. Values and brass detail should be more subdued than foreground/gameplay plates so this reads behind them. No characters, text, UI, prompts, arrows, horizon or close foreground framing. One static frame.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/deep_cistern_field_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/deep_cistern_field.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_environment_v2.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; dedicated Dust Lung V2 source review and DL0 spatial cutover; do not replace live 04→05 composite or old fallback without approval  
**Consumer:** res://scenes/awakening_first_return.tscn:separate_DL0_cutover  
**Provenance:** design/04_architecture/AWAKENING_DUST_LUNG_V2_ASSET_MANIFEST.md  
**Approval/registration:** pending; planned_not_registered_separate_owner. Candidate status: check live receipts separately.

#### `awakening_dust_lung_environment_v2/south_ingress_transition`

**Set:** `DL-06`, order 185; **family:** `awakening_dust_lung_environment_v2`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 2048x1024px total; 1 frame(s), 2048x1024px per frame, `copy`, opaque within intended registered architectural footprint.

**Generation prompt:** Create one high-resolution 2048×1024 top-down / high aerial-oblique game underlay for CUSTODIAN Awakening's Dust Lung V2 South Ingress Transition, immediately after Locker Reliquary. The lower/southeastern edge should retain some of Locker's disciplined institutional ancestry: intact heavy deck plates, consistent service grates, ordered brass linework, robust wall massing and controlled cyan fixtures. Moving inward/upward toward Dust Lung, progressively break that order: interrupted brass traces, cracked slabs, torn railing, thicker exposed pipework, mineral deposits, ash, fractured edge masonry and widening pale-blue cistern void. Provide one broad, continuous playable entry platform that naturally hands the player into the lower broken service route. The transition should feel like the same institution physically failing, not an abrupt tileset swap. Do not create a second exit or a clean ceremonial room. No characters, text, UI, arrows or prompts. One static frame.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/south_ingress_transition_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/south_ingress_transition.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_environment_v2.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; dedicated Dust Lung V2 source review and DL0 spatial cutover; do not replace live 04→05 composite or old fallback without approval  
**Consumer:** res://scenes/awakening_first_return.tscn:separate_DL0_cutover  
**Provenance:** design/04_architecture/AWAKENING_DUST_LUNG_V2_ASSET_MANIFEST.md  
**Approval/registration:** pending; planned_not_registered_separate_owner. Candidate status: check live receipts separately.

#### `awakening_dust_lung_environment_v2/service_route_splice_lower`

**Set:** `DL-07`, order 186; **family:** `awakening_dust_lung_environment_v2`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 1024x768px total; 1 frame(s), 1024x768px per frame, `copy`, true RGBA outside connective art.

**Generation prompt:** Create one 1024×768 transparent RGBA top-down / aerial-oblique connector overlay for Dust Lung V2. It must bridge two already-authored damaged service decks on the critical lower route. Compose a broad fractured but continuous walkable floor strip with matching charcoal industrial paving, service grates, interrupted aged-brass route inlay, rubble and one or two damaged rail fragments. Outside the actual floor/edge architecture, preserve true transparency so underlying cistern depth remains visible. The connector should look repaired only by survival, not intentionally rebuilt. Do not add a door, console, character, sign or alternate route. One static frame.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/service_route_splice_lower_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/service_route_splice_lower.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_environment_v2.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; dedicated Dust Lung V2 source review and DL0 spatial cutover; do not replace live 04→05 composite or old fallback without approval  
**Consumer:** res://scenes/awakening_first_return.tscn:separate_DL0_cutover  
**Provenance:** design/04_architecture/AWAKENING_DUST_LUNG_V2_ASSET_MANIFEST.md  
**Approval/registration:** pending; planned_not_registered_separate_owner. Candidate status: check live receipts separately.

#### `awakening_dust_lung_environment_v2/lift_station_transition_upper`

**Set:** `DL-08`, order 187; **family:** `awakening_dust_lung_environment_v2`; **core:** yes; **kind:** backdrop; **priority:** P0.

**Target:** 1024x768px total; 1 frame(s), 1024x768px per frame, `copy`, true RGBA outside connective art.

**Generation prompt:** Create one 1024×768 transparent RGBA top-down / aerial-oblique connector overlay for the upper western lift landing in Dust Lung V2. Join a battered maintenance-lift platform into the more ordered north upper routeworks. The floor must remain broad and clearly walkable, with structural brackets, grates, interrupted brass routing and a few damaged edge rails. Allow the material language to become slightly denser and more institutional toward the north, foreshadowing Undergate. Preserve true transparency outside the connector structure so deep cistern art remains visible below. No characters, text, UI, lever, console or alternate route. One static frame.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/lift_station_transition_upper_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/lift_station_transition_upper.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_environment_v2.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; dedicated Dust Lung V2 source review and DL0 spatial cutover; do not replace live 04→05 composite or old fallback without approval  
**Consumer:** res://scenes/awakening_first_return.tscn:separate_DL0_cutover  
**Provenance:** design/04_architecture/AWAKENING_DUST_LUNG_V2_ASSET_MANIFEST.md  
**Approval/registration:** pending; planned_not_registered_separate_owner. Candidate status: check live receipts separately.


### Additional Dust Lung visual presentation

#### `awakening_dust_lung_details_v2/north_pipe_bank_closed`

**Set:** `DL-DETAIL-001`, order 188; **family:** `awakening_dust_lung_details_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 512x256 true-RGBA source for awakening_dust_lung_details_v2/north_pipe_bank_closed. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: Cluster of thick heavily corroded cistern service pipes enclosed behind flat black girders and carbonate chalk crust. Source binding: Dust Lung V2 North Upper Works offroute pipe bank. Placement/design guard: Separate DL0 scenic owner must approve placement; do not reroute ingress. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_details_v2/north_pipe_bank_closed_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_details_v2/north_pipe_bank_closed.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_details_v2.asset.json`  
**Anchor/constraints:** Dust Lung V2 North Upper Works offroute pipe bank; actual placement dependent on authored separate spatial footprint; Separate DL0 scenic owner must approve placement; do not reroute ingress; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://scenes/awakening_first_return.tscn:DL0_separate_approved_cutover  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `awakening_dust_lung_details_v2/central_service_grate_failed`

**Set:** `DL-DETAIL-002`, order 189; **family:** `awakening_dust_lung_details_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x256px total; 1 frame(s), 384x256px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 384x256 true-RGBA source for awakening_dust_lung_details_v2/central_service_grate_failed. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: Twisted nonfunctional old drainage grate with two broken iron frames and mineralized stone contact pads. Source binding: Dust Lung V2 Central Broken Service Spine margin. Placement/design guard: Never depict a new traversable shortcut. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_details_v2/central_service_grate_failed_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_details_v2/central_service_grate_failed.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_details_v2.asset.json`  
**Anchor/constraints:** Dust Lung V2 Central Broken Service Spine margin; actual placement dependent on authored separate spatial footprint; Never depict a new traversable shortcut; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://scenes/awakening_first_return.tscn:DL0_separate_approved_cutover  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `awakening_dust_lung_details_v2/western_lift_counterweight`

**Set:** `DL-DETAIL-003`, order 190; **family:** `awakening_dust_lung_details_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x384px total; 1 frame(s), 384x384px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 384x384 true-RGBA source for awakening_dust_lung_details_v2/western_lift_counterweight. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: Large seized dark iron counterweight assembly with chain bracket stubs and oil-dark rust stains. Source binding: Dust Lung V2 Western Lift Spine closed machinery. Placement/design guard: Keep current lift path and upper transition unchanged. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_details_v2/western_lift_counterweight_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_details_v2/western_lift_counterweight.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_details_v2.asset.json`  
**Anchor/constraints:** Dust Lung V2 Western Lift Spine closed machinery; actual placement dependent on authored separate spatial footprint; Keep current lift path and upper transition unchanged; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://scenes/awakening_first_return.tscn:DL0_separate_approved_cutover  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `awakening_dust_lung_details_v2/cistern_rim_broken_arc`

**Set:** `DL-DETAIL-004`, order 191; **family:** `awakening_dust_lung_details_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x256px total; 1 frame(s), 512x256px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 512x256 true-RGBA source for awakening_dust_lung_details_v2/cistern_rim_broken_arc. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: A broken stone and iron arc of huge cistern retaining lip, dark graphite stone and salt crust in isolated silhouette. Source binding: Dust Lung V2 Cistern Core scenic perimeter. Placement/design guard: Do not paint abyss or floor into this prop; nonwalkable only. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_details_v2/cistern_rim_broken_arc_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_details_v2/cistern_rim_broken_arc.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_details_v2.asset.json`  
**Anchor/constraints:** Dust Lung V2 Cistern Core scenic perimeter; actual placement dependent on authored separate spatial footprint; Do not paint abyss or floor into this prop; nonwalkable only; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://scenes/awakening_first_return.tscn:DL0_separate_approved_cutover  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `awakening_dust_lung_details_v2/deep_cistern_distant_ring`

**Set:** `DL-DETAIL-005`, order 192; **family:** `awakening_dust_lung_details_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 512x384px total; 1 frame(s), 512x384px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 512x384 true-RGBA source for awakening_dust_lung_details_v2/deep_cistern_distant_ring. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: One far below suspended rust-black iron service ring fragment and broken lower walkway silhouette. Source binding: Dust Lung V2 Deep Cistern Field scenic abyss depth. Placement/design guard: Separate parallax/scenic depth only; no bridge or floor authority. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_details_v2/deep_cistern_distant_ring_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_details_v2/deep_cistern_distant_ring.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_details_v2.asset.json`  
**Anchor/constraints:** Dust Lung V2 Deep Cistern Field scenic abyss depth; actual placement dependent on authored separate spatial footprint; Separate parallax/scenic depth only; no bridge or floor authority; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://scenes/awakening_first_return.tscn:DL0_separate_approved_cutover  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.

#### `awakening_dust_lung_details_v2/south_ingress_valve_bank`

**Set:** `DL-DETAIL-006`, order 193; **family:** `awakening_dust_lung_details_v2`; **core:** yes; **kind:** world_prop; **priority:** P1.

**Target:** 384x256px total; 1 frame(s), 384x256px per frame, `copy`, TRUE RGBA isolated architectural component; verify actual pixel alpha; no baked checkerboard or matte.

**Generation prompt:** Create one standalone 384x256 true-RGBA source for awakening_dust_lung_details_v2/south_ingress_valve_bank. Produce exactly ONE independent transparent PNG, 90-degree top-down, 32px civic stone rhythm, visual size matching 128px Operator. Age-worn charcoal basalt, pale limestone, subtle ash and oxidized brass. No painted ground, no false route or claim to collision; placement on actual nonwalkable or approved offroute footprint must be checked. No legible writing, picture frame, watermarks, characters, UI, matte or checkerboard. Subject: Three jammed old industrial valve sockets in a stone mount, minimal tarnished brass, no lever or functional color. Source binding: Dust Lung V2 South Ingress offroute dark service wall. Placement/design guard: No operating mechanism, no new player interaction. Fully isolated silhouette with real alpha-zero outside the object; not a full-scene screenshot. This is a candidate only, no scene cutover or Asset V2 ingestion. Visually test at native pixel size and verify RGBA bytes and geometry clearance independently.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_details_v2/south_ingress_valve_bank_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_details_v2/south_ingress_valve_bank.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_details_v2.asset.json`  
**Anchor/constraints:** Dust Lung V2 South Ingress offroute dark service wall; actual placement dependent on authored separate spatial footprint; No operating mechanism, no new player interaction; preserve live navigation, scene ownership and existing event coordinates, do not promote unapproved source to production  
**Consumer:** PLANNED res://scenes/awakening_first_return.tscn:DL0_separate_approved_cutover  
**Provenance:** 2026-11-03 full-world art roadmap; existing source layout authority retained  
**Approval/registration:** pending; proposed_not_registered. Candidate status: NOT_GENERATED.


## 36 optional / conditional extras (not in automatic core queue)

The following sources are individually prompted, but require explicit opt-in before generation. They do not block the 198-state core artwork program.

#### `hub_first_set_north_processional_environment/foreground`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 1024x1152px; 1 frame(s) at 1024x1152px; copy; true RGBA with transparent ground, exact same canvas registration.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 1024×1152 pixels as a one-frame image. Exactly registered true-alpha foreground occlusion ONLY for approved north processional underlay: damaged upper arch pieces, overhangs or roof/cornice fragments that truly overlap Operator from above. Do not redraw floor, walls below Operator or complete room. Use reviewed underlay as absolute pixel-registration source. true RGBA with transparent ground, exact same canvas registration.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_north_processional_environment/foreground_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_north_processional_environment/foreground.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_north_processional_environment.asset.json`  
**Anchor/constraints:** paired registered underlay; produce only if renderer confirms genuine occlusion is needed  
**Source authority:** new Hub V1 proposal under owner-approved art program  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_ashen_forum_environment/foreground`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 2560x1792px; 1 frame(s) at 2560x1792px; copy; true RGBA with transparent ground, exact same canvas registration.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 2560×1792 pixels as a one-frame image. Exactly registered true-alpha foreground occlusion ONLY for approved ashen forum underlay: damaged upper arch pieces, overhangs or roof/cornice fragments that truly overlap Operator from above. Do not redraw floor, walls below Operator or complete room. Use reviewed underlay as absolute pixel-registration source. true RGBA with transparent ground, exact same canvas registration.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_ashen_forum_environment/foreground_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_ashen_forum_environment/foreground.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_ashen_forum_environment.asset.json`  
**Anchor/constraints:** paired registered underlay; produce only if renderer confirms genuine occlusion is needed  
**Source authority:** new Hub V1 proposal under owner-approved art program  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_sepulcher_gardens_environment/foreground`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 1152x1408px; 1 frame(s) at 1152x1408px; copy; true RGBA with transparent ground, exact same canvas registration.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 1152×1408 pixels as a one-frame image. Exactly registered true-alpha foreground occlusion ONLY for approved sepulcher gardens underlay: damaged upper arch pieces, overhangs or roof/cornice fragments that truly overlap Operator from above. Do not redraw floor, walls below Operator or complete room. Use reviewed underlay as absolute pixel-registration source. true RGBA with transparent ground, exact same canvas registration.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_gardens_environment/foreground_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_gardens_environment/foreground.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_gardens_environment.asset.json`  
**Anchor/constraints:** paired registered underlay; produce only if renderer confirms genuine occlusion is needed  
**Source authority:** new Hub V1 proposal under owner-approved art program  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_archive_rise_environment/foreground`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 1408x1280px; 1 frame(s) at 1408x1280px; copy; true RGBA with transparent ground, exact same canvas registration.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 1408×1280 pixels as a one-frame image. Exactly registered true-alpha foreground occlusion ONLY for approved archive rise underlay: damaged upper arch pieces, overhangs or roof/cornice fragments that truly overlap Operator from above. Do not redraw floor, walls below Operator or complete room. Use reviewed underlay as absolute pixel-registration source. true RGBA with transparent ground, exact same canvas registration.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_archive_rise_environment/foreground_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_archive_rise_environment/foreground.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_archive_rise_environment.asset.json`  
**Anchor/constraints:** paired registered underlay; produce only if renderer confirms genuine occlusion is needed  
**Source authority:** new Hub V1 proposal under owner-approved art program  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_crown_transfer_environment/foreground`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 768x768px; 1 frame(s) at 768x768px; copy; true RGBA with transparent ground, exact same canvas registration.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 768×768 pixels as a one-frame image. Exactly registered true-alpha foreground occlusion ONLY for approved crown transfer underlay: damaged upper arch pieces, overhangs or roof/cornice fragments that truly overlap Operator from above. Do not redraw floor, walls below Operator or complete room. Use reviewed underlay as absolute pixel-registration source. true RGBA with transparent ground, exact same canvas registration.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_crown_transfer_environment/foreground_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_crown_transfer_environment/foreground.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_crown_transfer_environment.asset.json`  
**Anchor/constraints:** paired registered underlay; produce only if renderer confirms genuine occlusion is needed  
**Source authority:** new Hub V1 proposal under owner-approved art program  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_muster_court_environment/foreground`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 1088x1408px; 1 frame(s) at 1088x1408px; copy; true RGBA with transparent ground, exact same canvas registration.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 1088×1408 pixels as a one-frame image. Exactly registered true-alpha foreground occlusion ONLY for approved muster court underlay: damaged upper arch pieces, overhangs or roof/cornice fragments that truly overlap Operator from above. Do not redraw floor, walls below Operator or complete room. Use reviewed underlay as absolute pixel-registration source. true RGBA with transparent ground, exact same canvas registration.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_muster_court_environment/foreground_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_muster_court_environment/foreground.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_muster_court_environment.asset.json`  
**Anchor/constraints:** paired registered underlay; produce only if renderer confirms genuine occlusion is needed  
**Source authority:** new Hub V1 proposal under owner-approved art program  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_continuity_port_environment/foreground`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 704x896px; 1 frame(s) at 704x896px; copy; true RGBA with transparent ground, exact same canvas registration.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 704×896 pixels as a one-frame image. Exactly registered true-alpha foreground occlusion ONLY for approved continuity port underlay: damaged upper arch pieces, overhangs or roof/cornice fragments that truly overlap Operator from above. Do not redraw floor, walls below Operator or complete room. Use reviewed underlay as absolute pixel-registration source. true RGBA with transparent ground, exact same canvas registration.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_continuity_port_environment/foreground_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_continuity_port_environment/foreground.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_continuity_port_environment.asset.json`  
**Anchor/constraints:** paired registered underlay; produce only if renderer confirms genuine occlusion is needed  
**Source authority:** new Hub V1 proposal under owner-approved art program  
**Human approval:** pending; not automatically dispatchable.

#### `awakening_dust_lung_environment_v2/ingress_rubble_blend`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 1024x512px; 1 frame(s) at 1024x512px; copy; true RGBA outside connective art.

**Generation prompt:** Create one 1024×512 transparent RGBA transition overlay for the Locker-Reliquary-to-Dust-Lung handoff. Use broken service grates, fractured charcoal masonry, severed brass route strips, chalky dust, pipe fragments and small rubble to move from intact institutional floor into ruptured cistern infrastructure. Keep the central walkable lane visually clear. Irregular alpha silhouette only; no full rectangular matte, no new door, no character, no text.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/ingress_rubble_blend_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/ingress_rubble_blend.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_environment_v2.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; dedicated Dust Lung V2 source review and DL0 spatial cutover; do not replace live 04→05 composite or old fallback without approval  
**Source authority:** design/04_architecture/AWAKENING_DUST_LUNG_V2_ASSET_MANIFEST.md  
**Human approval:** pending; not automatically dispatchable.

#### `awakening_dust_lung_environment_v2/distant_pipe_gallery`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 1536x768px; 1 frame(s) at 1536x768px; copy; true RGBA outside connective art.

**Generation prompt:** Create one 1536×768 transparent RGBA distant-architecture silhouette for Dust Lung V2: suspended broken pipe galleries, reservoir ribs, tiny maintenance decks and cable runs hanging across deep pale-blue haze. It must read as inaccessible background several structural levels away, with reduced contrast and no broad walkable deck. Match the cold charcoal / oil-dark iron / aged brass / sparse cyan service-light family. No doors, characters, text or gameplay affordances.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/distant_pipe_gallery_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/distant_pipe_gallery.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_environment_v2.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; dedicated Dust Lung V2 source review and DL0 spatial cutover; do not replace live 04→05 composite or old fallback without approval  
**Source authority:** design/04_architecture/AWAKENING_DUST_LUNG_V2_ASSET_MANIFEST.md  
**Human approval:** pending; not automatically dispatchable.

#### `awakening_dust_lung_environment_v2/daylight_rupture_overlay`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 1024x1024px; 1 frame(s) at 1024x1024px; copy; true RGBA outside connective art.

**Generation prompt:** Create one 1024×1024 transparent RGBA structural-rupture overlay for Dust Lung V2's daylight_split landmark. Show a torn cistern wall / pipe-gallery breach with fractured masonry, exposed structural ribs, mineral deposits and pale desaturated exterior light visible through the opening. The asset should provide the broken silhouette only; do not paint a full-screen light beam or vignette because Godot WorldLightingDirector owns illumination. No usable doorway, no character, no text, no UI. One static frame.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment_v2/daylight_rupture_overlay_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_environment_v2/daylight_rupture_overlay.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_environment_v2.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; dedicated Dust Lung V2 source review and DL0 spatial cutover; do not replace live 04→05 composite or old fallback without approval  
**Source authority:** design/04_architecture/AWAKENING_DUST_LUNG_V2_ASSET_MANIFEST.md  
**Human approval:** pending; not automatically dispatchable.

#### `hub_sepulcher_wildlife_fx/pale_moth_hover`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 256x64px; 4 frame(s) at 64x64px; horizontal_strip; true PNG RGBA, transparent outside physical artwork, no painted square or halo.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 64×64 pixels per cell, 4 equal cells in a horizontal 256×64 strip. Four individually aligned frames of one tiny pale moth gently fluttering wings with fixed body center, transparent background, no magical glow or group of moths. true PNG RGBA, transparent outside physical artwork, no painted square or halo.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_sepulcher_wildlife_fx/pale_moth_hover_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_sepulcher_wildlife_fx/pale_moth_hover.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_sepulcher_wildlife_fx.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; ambient only; no AI or collision  
**Source authority:** new Hub V1 proposal under owner-approved art program  
**Human approval:** pending; not automatically dispatchable.

#### `hub_sepulcher_wildlife_fx/pale_bird_perch`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 384x96px; 4 frame(s) at 96x96px; horizontal_strip; true PNG RGBA, transparent outside physical artwork, no painted square or halo.

**Generation prompt:** Create one professional CUSTODIAN top-down 2D game art image, overhead orthographic, world north at image top, 32px construction rhythm, near-black civic basalt, pale weathered limestone, charcoal, aged brass, ash and restrained cold environmental light. Match existing Road of Witnesses, Hub and Awakening production-camera scale. Architecture must be physically plausible with consistent light and material logic. No people, loot, monsters, UI, legible lettering, watermarks, new entrances, fake navigation, baked global lighting, rectangular background matte, checkerboard or AI-mirrored pseudo-architecture. Target 96×96 pixels per cell, 4 equal cells in a horizontal 384×96 strip. Four individually aligned frames of one small desaturated bird perched on a ruin making a tiny head movement; fixed feet/anchor throughout, no flight pose. true PNG RGBA, transparent outside physical artwork, no painted square or halo.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_sepulcher_wildlife_fx/pale_bird_perch_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_sepulcher_wildlife_fx/pale_bird_perch.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_sepulcher_wildlife_fx.asset.json`  
**Anchor/constraints:** visual anchor to registered scene; confirm in live context; ambient only; no wildlife gameplay authority  
**Source authority:** new Hub V1 proposal under owner-approved art program  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_sepulcher_optional_extras_v2/grave_moth_idle_strip`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 512x128px; 4 frame(s) at 128x128px; horizontal_strip; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_sepulcher_optional_extras_v2/grave_moth_idle_strip for CUSTODIAN: one horizontal 4-frame strip of 128x128 pixel frames, TOTAL 512x128, with stable fixed anchor and original loop, true RGBA. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: Single small dusty grey moth hovering in a tiny closed non-directional four-frame idle cycle. Intended visual anchor: L03/L09 noninteractive shade. Restriction: Ambient only; no insect AI gameplay or obstruction. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_optional_extras_v2/grave_moth_idle_strip_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_optional_extras_v2/grave_moth_idle_strip.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_optional_extras_v2.asset.json`  
**Anchor/constraints:** L03/L09 noninteractive shade; Ambient only; no insect AI gameplay or obstruction  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_sepulcher_optional_extras_v2/ashen_moth_idle_strip`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 512x128px; 4 frame(s) at 128x128px; horizontal_strip; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_sepulcher_optional_extras_v2/ashen_moth_idle_strip for CUSTODIAN: one horizontal 4-frame strip of 128x128 pixel frames, TOTAL 512x128, with stable fixed anchor and original loop, true RGBA. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: One ash-brown moth with a slightly irregular four-frame overhead wing-flutter. Intended visual anchor: L05 ruined rotunda dark quarter. Restriction: No gameplay navigation or pickup. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_optional_extras_v2/ashen_moth_idle_strip_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_optional_extras_v2/ashen_moth_idle_strip.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_optional_extras_v2.asset.json`  
**Anchor/constraints:** L05 ruined rotunda dark quarter; No gameplay navigation or pickup  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_sepulcher_optional_extras_v2/witness_pool_glint_strip`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 1024x128px; 4 frame(s) at 256x128px; horizontal_strip; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_sepulcher_optional_extras_v2/witness_pool_glint_strip for CUSTODIAN: one horizontal 4-frame strip of 256x128 pixel frames, TOTAL 1024x128, with stable fixed anchor and original loop, true RGBA. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: Nearly invisible slow cold-grey elongated surface glint moving naturally on dark water over four static-camera frames. Intended visual anchor: D3 only. Restriction: Keep visually muted and within existing D3 water mask. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_optional_extras_v2/witness_pool_glint_strip_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_optional_extras_v2/witness_pool_glint_strip.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_optional_extras_v2.asset.json`  
**Anchor/constraints:** D3 only; Keep visually muted and within existing D3 water mask  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_sepulcher_optional_extras_v2/sunken_basin_glint_strip`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 1024x128px; 4 frame(s) at 256x128px; horizontal_strip; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_sepulcher_optional_extras_v2/sunken_basin_glint_strip for CUSTODIAN: one horizontal 4-frame strip of 256x128 pixel frames, TOTAL 1024x128, with stable fixed anchor and original loop, true RGBA. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: Intermittent very dim mineral specular distortion in dark olive water, four-frame nonpulsing sequence. Intended visual anchor: D4 only. Restriction: No bright radial rings and no changed water mask. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_optional_extras_v2/sunken_basin_glint_strip_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_optional_extras_v2/sunken_basin_glint_strip.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_optional_extras_v2.asset.json`  
**Anchor/constraints:** D4 only; No bright radial rings and no changed water mask  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_sepulcher_optional_extras_v2/quiet_leaf_fall_strip`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 512x128px; 4 frame(s) at 128x128px; horizontal_strip; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_sepulcher_optional_extras_v2/quiet_leaf_fall_strip for CUSTODIAN: one horizontal 4-frame strip of 128x128 pixel frames, TOTAL 512x128, with stable fixed anchor and original loop, true RGBA. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: Four-frame tiny dry pale leaf drifting across a single local overhead scene region. Intended visual anchor: L10 orchard offroute. Restriction: Ambient only; no windy full-screen effect or moving collider. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_optional_extras_v2/quiet_leaf_fall_strip_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_optional_extras_v2/quiet_leaf_fall_strip.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_optional_extras_v2.asset.json`  
**Anchor/constraints:** L10 orchard offroute; Ambient only; no windy full-screen effect or moving collider  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_sepulcher_optional_extras_v2/dust_mote_cluster_strip`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 512x128px; 4 frame(s) at 128x128px; horizontal_strip; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_sepulcher_optional_extras_v2/dust_mote_cluster_strip for CUSTODIAN: one horizontal 4-frame strip of 128x128 pixel frames, TOTAL 512x128, with stable fixed anchor and original loop, true RGBA. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: Subtle group of three drifting ash motes across transparent background, no camera-facing particle streaks. Intended visual anchor: L03 cloister dark columns. Restriction: Purely decorative, no screen-filling effect. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_optional_extras_v2/dust_mote_cluster_strip_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_optional_extras_v2/dust_mote_cluster_strip.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_optional_extras_v2.asset.json`  
**Anchor/constraints:** L03 cloister dark columns; Purely decorative, no screen-filling effect  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_sepulcher_optional_extras_v2/grave_side_lantern_dead`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 128x192px; 1 frame(s) at 128x192px; copy; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_sepulcher_optional_extras_v2/grave_side_lantern_dead for CUSTODIAN: one 128x192 true-alpha PNG. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: One cold, extinguished bronze-in-stone memorial lantern shell, no active light. Intended visual anchor: L04 side court. Restriction: Never imply gameplay light source or quest. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_optional_extras_v2/grave_side_lantern_dead_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_optional_extras_v2/grave_side_lantern_dead.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_optional_extras_v2.asset.json`  
**Anchor/constraints:** L04 side court; Never imply gameplay light source or quest  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_sepulcher_optional_extras_v2/cemetery_fallen_standard`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 256x192px; 1 frame(s) at 256x192px; copy; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_sepulcher_optional_extras_v2/cemetery_fallen_standard for CUSTODIAN: one 256x192 true-alpha PNG. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: One snapped old grave register standard in stone resting on side, bronze foot worn matte. Intended visual anchor: L07 remote burial terrace. Restriction: Off path only, no new collision. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_optional_extras_v2/cemetery_fallen_standard_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_optional_extras_v2/cemetery_fallen_standard.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_optional_extras_v2.asset.json`  
**Anchor/constraints:** L07 remote burial terrace; Off path only, no new collision  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_sepulcher_optional_extras_v2/lost_ceremonial_chain`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 256x128px; 1 frame(s) at 256x128px; copy; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_sepulcher_optional_extras_v2/lost_ceremonial_chain for CUSTODIAN: one 256x128 true-alpha PNG. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: One discarded rusty bronze ceremonial chain fragment with broken mount and ash grit. Intended visual anchor: L05 Rotunda rear near S3. Restriction: No actual loot item. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_optional_extras_v2/lost_ceremonial_chain_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_optional_extras_v2/lost_ceremonial_chain.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_optional_extras_v2.asset.json`  
**Anchor/constraints:** L05 Rotunda rear near S3; No actual loot item  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_sepulcher_optional_extras_v2/witness_path_bronze_stain`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 256x128px; 1 frame(s) at 256x128px; copy; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_sepulcher_optional_extras_v2/witness_path_bronze_stain for CUSTODIAN: one 256x128 true-alpha PNG. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: Thin irregular aged copper oxidation stain across old floor, detached transparent grime overlay. Intended visual anchor: L04 path margin only. Restriction: No directional trail clue or route marking. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_optional_extras_v2/witness_path_bronze_stain_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_optional_extras_v2/witness_path_bronze_stain.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_optional_extras_v2.asset.json`  
**Anchor/constraints:** L04 path margin only; No directional trail clue or route marking  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_sepulcher_optional_extras_v2/pool_edge_snow_ash`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 256x128px; 1 frame(s) at 256x128px; copy; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_sepulcher_optional_extras_v2/pool_edge_snow_ash for CUSTODIAN: one 256x128 true-alpha PNG. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: Pale fine mineral dust settled on limestone coping, detached top-down translucent spot overlay. Intended visual anchor: D3 bank rubble only. Restriction: No painted pool or game water physics. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_optional_extras_v2/pool_edge_snow_ash_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_optional_extras_v2/pool_edge_snow_ash.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_optional_extras_v2.asset.json`  
**Anchor/constraints:** D3 bank rubble only; No painted pool or game water physics  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_sepulcher_optional_extras_v2/orchard_mourning_ribbon`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 128x128px; 1 frame(s) at 128x128px; copy; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_sepulcher_optional_extras_v2/orchard_mourning_ribbon for CUSTODIAN: one 128x128 true-alpha PNG. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: One torn pale cloth mourning ribbon wound onto old twig, darkened with age, no writing. Intended visual anchor: L10 shrub offroute. Restriction: No interactive clue or collectible. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_optional_extras_v2/orchard_mourning_ribbon_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_optional_extras_v2/orchard_mourning_ribbon.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_optional_extras_v2.asset.json`  
**Anchor/constraints:** L10 shrub offroute; No interactive clue or collectible  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_sepulcher_optional_extras_v2/small_bronze_cenotaph`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 256x256px; 1 frame(s) at 256x256px; copy; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_sepulcher_optional_extras_v2/small_bronze_cenotaph for CUSTODIAN: one 256x256 true-alpha PNG. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: Tiny silent cenotaph made of oxidized bronze atop dark stone, flat top visible. Intended visual anchor: L02 peripheral ruined threshold. Restriction: Only offroute if real collision placement approved. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_optional_extras_v2/small_bronze_cenotaph_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_optional_extras_v2/small_bronze_cenotaph.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_optional_extras_v2.asset.json`  
**Anchor/constraints:** L02 peripheral ruined threshold; Only offroute if real collision placement approved  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_sepulcher_optional_extras_v2/cracked_offering_bowl`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 128x128px; 1 frame(s) at 128x128px; copy; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_sepulcher_optional_extras_v2/cracked_offering_bowl for CUSTODIAN: one 128x128 true-alpha PNG. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: One empty fractured stone ritual bowl with dark metal rim and chalk dust. Intended visual anchor: L09 reliquary empty pedestal. Restriction: No item inventory or offering mechanic. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_optional_extras_v2/cracked_offering_bowl_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_optional_extras_v2/cracked_offering_bowl.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_optional_extras_v2.asset.json`  
**Anchor/constraints:** L09 reliquary empty pedestal; No item inventory or offering mechanic  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_sepulcher_optional_extras_v2/weathered_archive_roll`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 128x128px; 1 frame(s) at 128x128px; copy; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_sepulcher_optional_extras_v2/weathered_archive_roll for CUSTODIAN: one 128x128 true-alpha PNG. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: A sealed rolled bronze-foil civic scroll fragment, curled and unreadable under ash. Intended visual anchor: L03 registrar niche. Restriction: No readable text, no actual quest pickup. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_optional_extras_v2/weathered_archive_roll_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_optional_extras_v2/weathered_archive_roll.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_optional_extras_v2.asset.json`  
**Anchor/constraints:** L03 registrar niche; No readable text, no actual quest pickup  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_sepulcher_optional_extras_v2/pale_root_occlusion_strip`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 256x128px; 1 frame(s) at 256x128px; copy; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_sepulcher_optional_extras_v2/pale_root_occlusion_strip for CUSTODIAN: one 256x128 true-alpha PNG. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: Long thin overhead root fringe for foreground occlusion on an already approved arch silhouette. Intended visual anchor: I04 reliquary roofline. Restriction: Requires occlusion review, not always visible. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_optional_extras_v2/pale_root_occlusion_strip_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_optional_extras_v2/pale_root_occlusion_strip.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_optional_extras_v2.asset.json`  
**Anchor/constraints:** I04 reliquary roofline; Requires occlusion review, not always visible  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_hub_optional_polish_v2/forum_dust_register`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 256x128px; 1 frame(s) at 256x128px; copy; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_hub_optional_polish_v2/forum_dust_register for CUSTODIAN: one 256x128 true-alpha PNG. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: A faint dust-streaked bronze register decal lightly etched between level civic stones. Intended visual anchor: Ashen Forum far offroute. Restriction: Only as decorative overlay; preserve Dais area. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_hub_optional_polish_v2/forum_dust_register_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_hub_optional_polish_v2/forum_dust_register.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_hub_optional_polish_v2.asset.json`  
**Anchor/constraints:** Ashen Forum far offroute; Only as decorative overlay; preserve Dais area  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_hub_optional_polish_v2/archive_distant_broken_arch`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 512x256px; 1 frame(s) at 512x256px; copy; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_hub_optional_polish_v2/archive_distant_broken_arch for CUSTODIAN: one 512x256 true-alpha PNG. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: A single distant broken overhead library arch silhouette with cold graphite ruin patina. Intended visual anchor: Archive Rise nonplayable edge. Restriction: Do not introduce usable stairs or portals. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_hub_optional_polish_v2/archive_distant_broken_arch_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_hub_optional_polish_v2/archive_distant_broken_arch.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_hub_optional_polish_v2.asset.json`  
**Anchor/constraints:** Archive Rise nonplayable edge; Do not introduce usable stairs or portals  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_hub_optional_polish_v2/muster_failed_standard`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 256x192px; 1 frame(s) at 256x192px; copy; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_hub_optional_polish_v2/muster_failed_standard for CUSTODIAN: one 256x192 true-alpha PNG. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: One fallen ceremonial deployment standard mount and thin bent oxidized bronze shaft. Intended visual anchor: Muster Court perimeter. Restriction: Pure scenic offroute object. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_hub_optional_polish_v2/muster_failed_standard_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_hub_optional_polish_v2/muster_failed_standard.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_hub_optional_polish_v2.asset.json`  
**Anchor/constraints:** Muster Court perimeter; Pure scenic offroute object  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `hub_first_set_hub_optional_polish_v2/port_dead_diagnostic_strip`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 256x128px; 1 frame(s) at 256x128px; copy; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source hub_first_set_hub_optional_polish_v2/port_dead_diagnostic_strip for CUSTODIAN: one 256x128 true-alpha PNG. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: Small inlaid mechanical registry stripe with dark turquoise corroded light sockets, permanently unlit. Intended visual anchor: Continuity Port inactive sidewall. Restriction: Do not fake active calibration UI or world portal. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_hub_optional_polish_v2/port_dead_diagnostic_strip_source.png`  
**Inbox:** `custodian/asset_drop/inbox/hub_first_set_hub_optional_polish_v2/port_dead_diagnostic_strip.png`  
**Family schema:** `custodian/content/metadata/assets/families/hub_first_set_hub_optional_polish_v2.asset.json`  
**Anchor/constraints:** Continuity Port inactive sidewall; Do not fake active calibration UI or world portal  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `awakening_dust_lung_optional_polish_v2/cistern_condensation_strip`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 1024x128px; 4 frame(s) at 256x128px; horizontal_strip; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source awakening_dust_lung_optional_polish_v2/cistern_condensation_strip for CUSTODIAN: one horizontal 4-frame strip of 256x128 pixel frames, TOTAL 1024x128, with stable fixed anchor and original loop, true RGBA. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: Subtle condensation droplet pattern rolling across oxidized cold iron in four aligned frames. Intended visual anchor: Dust Lung Cistern Core pipe underpass. Restriction: No interactive slip or water mechanic. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_optional_polish_v2/cistern_condensation_strip_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_optional_polish_v2/cistern_condensation_strip.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_optional_polish_v2.asset.json`  
**Anchor/constraints:** Dust Lung Cistern Core pipe underpass; No interactive slip or water mechanic  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `awakening_dust_lung_optional_polish_v2/deep_mineral_fall_strip`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 1024x256px; 4 frame(s) at 256x256px; horizontal_strip; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source awakening_dust_lung_optional_polish_v2/deep_mineral_fall_strip for CUSTODIAN: one horizontal 4-frame strip of 256x256 pixel frames, TOTAL 1024x256, with stable fixed anchor and original loop, true RGBA. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: Tiny thin pale mineral particulate falls within deep charcoal fog over four frames. Intended visual anchor: Dust Lung deep abyss nonplayable depth. Restriction: No light source, physics or traversal hint. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_optional_polish_v2/deep_mineral_fall_strip_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_optional_polish_v2/deep_mineral_fall_strip.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_optional_polish_v2.asset.json`  
**Anchor/constraints:** Dust Lung deep abyss nonplayable depth; No light source, physics or traversal hint  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `awakening_dust_lung_optional_polish_v2/broken_pipe_vapor_strip`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 1024x128px; 4 frame(s) at 256x128px; horizontal_strip; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source awakening_dust_lung_optional_polish_v2/broken_pipe_vapor_strip for CUSTODIAN: one horizontal 4-frame strip of 256x128 pixel frames, TOTAL 1024x128, with stable fixed anchor and original loop, true RGBA. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: Very faint nonluminous steam residue rising from a cracked iron outlet, four crisp consistent overhead frames. Intended visual anchor: Dust Lung Central Service Spine inactive pipe. Restriction: No direction-changing wind or player collision. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_optional_polish_v2/broken_pipe_vapor_strip_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_optional_polish_v2/broken_pipe_vapor_strip.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_optional_polish_v2.asset.json`  
**Anchor/constraints:** Dust Lung Central Service Spine inactive pipe; No direction-changing wind or player collision  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.

#### `awakening_dust_lung_optional_polish_v2/lift_chain_shadow_overlay`

**Status:** OPTIONAL, independent human opt-in required. **Target:** 256x256px; 1 frame(s) at 256x256px; copy; TRUE RGBA (no matte/checkerboard); actual byte-level alpha verification required.

**Generation prompt:** Create exactly ONE individually identifiable optional art source awakening_dust_lung_optional_polish_v2/lift_chain_shadow_overlay for CUSTODIAN: one 256x256 true-alpha PNG. Strict 90-degree overhead, 32px civic architectural scale, restrained sepulchral graphite/limestone/brass materials, appropriate minimal ambient animation where specified; no picture-frame composition, labels, montage, people, UI, border or baked floor. Unique scene subject: One diagonal soft low-contrast rusted chain shadow and chipped mineral staining in isolated alpha. Intended visual anchor: Dust Lung western lift service wall. Restriction: Not an active lift interaction, registration optional. All exterior/background pixels genuinely alpha-zero, NO fake checkerboard or matte; alpha must be proven from bytes rather than appearance. Never invent collision, loot/quest behavior, player routes, active gates, existing source approval or image-conditioning provenance. Optional source is EXCLUDED from unattended 198-core generation sets until user explicitly opts in.

**Source:** `custodian/asset_drop/source_work/awakening/awakening_dust_lung_optional_polish_v2/lift_chain_shadow_overlay_source.png`  
**Inbox:** `custodian/asset_drop/inbox/awakening_dust_lung_optional_polish_v2/lift_chain_shadow_overlay.png`  
**Family schema:** `custodian/content/metadata/assets/families/awakening_dust_lung_optional_polish_v2.asset.json`  
**Anchor/constraints:** Dust Lung western lift service wall; Not an active lift interaction, registration optional  
**Source authority:** 2026-11-03 expanded full-world roadmap optional extras; independent user opt-in for generation  
**Human approval:** pending; not automatically dispatchable.


## Complete-art acceptance gates

1. 198 unique core source IDs and 193 single-state ordered generation sets, retaining 67 prior IDs
2. 36 optional prompt-defined extras excluded until user explicitly opts in
3. Each actual image individually screened, source bytes verified, candidate-only Dropbox receipt recorded before candidate advancement
4. Opaque sources: actual RGB/no alpha; transparent sources: actual byte-level RGBA/alpha and explicit visual matte/checkerboard/uncertainty
5. Repeatable floor/water materials: actual 3x3 repeats, edges and corners examined at 1:1 native scale, no recognizable motifs
6. 20 shoreline pieces: formal/ruined/raw registered end profiles tested with 256px straight runs and 45-degree/90-degree D3/D4 corner contacts
7. D1-D7 nonwalkable, P1-P8 routes, both east connectors and grave interaction offsets remain unaltered by artwork
8. All ten L01-L10 landmark sites and four I01-I04 interior visual suites individually identifiable and scale-correct
9. S1-S5 clues remain artistic telegraphs, not actual item-grant or entrance authority
10. 198 production source masters individually human-reviewed and approved before immutable source_work/inbox promotion
11. Asset Pipeline V2 schema, normalization, doctor/ingest and Godot scene rendering validated for each human-approved family
12. 128px canonical Operator in-game comparison, no obstructed routes or unexpected overdraw, no DL0/AP ownership violations
13. Optional extras are supplemental only; core completeness does not depend on them

**Full-world in-game proof:** use the real 128px 2.5D Operator rather than a placeholder to review the complete Gardens, D3/D4 pool masks, all shoreline transition profiles, L01-L10 landmark identity, P1-P8 paths, S1-S5 clue occlusion and existing grave events. Review first-set Hub contacts, Awakening perimeter families and DL0 scenic art independently with their owners. Human source approval, Asset V2 normalization/doctor/ingest and runtime validation must all be recorded before claiming production completion.

**Documentation drift validation:** `python3 custodian/tools/validation/validate_hub_art_manifest.py` checks counts, per-state prompts/frames/source paths, 193 set assignments, all 67 old IDs, optional exclusion and exact Markdown prompt mirrors.

**Next candidate operation (not a work packet):** Codex `GENERATE_ASSET` set `CAL-02`, asset `hub_first_set_sepulcher_gardens_environment/structural_presentation`; next `REVIEW_ASSET`, then `UPLOAD_ASSET_TO_DROPBOX` only after PASS_CANDIDATE. Codex should issue only one of these three commands when requesting further artwork.
