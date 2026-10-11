# Awakening Perimeter Batch 01: Ten Calibration Assets + Generation Prompts

**Status:** **Batch 01 GENERATION REJECTED by user 2026-10-10** (all 10 atlas-cropped outputs, not ingestible). This document remains the ten-state design/prompt contract for *future* independently generated replacements; sources are not approved, ingested, scene-bound, or complete. Full defect ledger: [AWAKENING_GATE_STAIRS_WIND_AND_ART_REVIEW_V1.md](AWAKENING_GATE_STAIRS_WIND_AND_ART_REVIEW_V1.md). **Date:** 2026-10-10.
**Parent:** [AWAKENING_PERIMETER_SUPPORT_V1.md](AWAKENING_PERIMETER_SUPPORT_V1.md) · [ASSET PROMPTS V1](AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md) · [IMPLEMENTATION ROADMAP](AWAKENING_PERIMETER_SUPPORT_IMPLEMENTATION_ROADMAP.md).
**Scope:** Zones 01, 06, 07, 10 only; **excludes** separately reauthored Dust Lung Zone 05.
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a

## Mandatory regeneration / Gate branch preservation

**Stop:** Reject the prior 10-state ZIP as `REJECT_REGENERATE`. It consists of atlas crops, mirrored pseudo-tiles, and visibly incoherent structures; it is not evidence of native production assets or a satisfied art gate. Future generation must issue **one independent output per state**, evaluate structural consistency and real gameplay-scale presentation before resize, and may not fabricate exact-size/source-quality by mirror replication. The real Gate plaza underlay exposes west and east stairways: keep their apparent entrances intact pending explicit side-branch decisions. Do not paste blocked-side-route architecture on either stair mouth. See [Gate Stair + Wind + Art QA ledger](AWAKENING_GATE_STAIRS_WIND_AND_ART_REVIEW_V1.md).

## Why exactly these ten

Three complete calibration families (07 Gate, 10 South Reach, 01 Crèche) test all three generic Asset V2 roles: structural tile, distant silhouette and ragged RGBA transition. The tenth asset tests Zone 06's machinery-to-exterior continuity without waiting for the full interior suite. Generate 1–3 first, **compare with real scene-bound art at actual game zoom**, and only then generate 4–10 if their compositional and perspective vocabulary reads correctly. No speculative Dust Lung generic family and no interaction-console art in this batch. Other 17 generic states stay source-pending.

## Global negative and quality contract

Match actual Godot production underlays / overhead-to-gently-oblique gameplay camera; do not import the prior high-perspective 1774×887 photo-textured panorama as-is. Single frame, `omni`, zero looping, native 32px structural cadence where relevant. `distant_structures` 1024×512 true RGBA irregular architecture with low tonal dominance; `edge_transition` 256×256 true RGBA; `structural_support` 512×512 rigorously tileable on 4 sides (opaque within intended off-route substrate is allowed). The earlier Gate and Road images are **source-style donors, not approved runtime art**. Keep original canonical road/gate/Crèche console hero and their gameplay route authoritative. Reject characters, UI, labels, readable signs, broad opaque panel edges, floor-shadow hallucinations, obvious angled 3D miniatures, glowing magic, false open paths or a second central boulevard/Gate/interactive computer. If image model cannot output exact pixel size, retain aspect and upscale source, then normalize only by uniform scale/pad/crop with measurable preserved silhouette, never distortion. Always inspect RGBA in actual PNG bytes and review at gameplay scale before Art V2 intake.

**Per-family schema:** `custodian.asset_family.v2` · kind `backdrop` · state values `structural_support`, `distant_structures`, `edge_transition`, all 1 frame, omni, no mirroring. These remain proposed until AP0 formally registers family contracts and requirements.

| # | Zone | State | Requested canvas | Generation priority |
|---:|---|---|---:|---|
| 1 | 07 Gate of Dust | `distant_structures` | 1024×512, 1f | P0 calibration |
| 2 | 10 South Reach | `distant_structures` | 1024×512, 1f | P0 calibration |
| 3 | 01 Crèche | `distant_structures` | 1024×512, 1f | P0 calibration |
| 4 | 07 Gate of Dust | `structural_support` | 512×512, 1f | P1 next-pass |
| 5 | 10 South Reach | `structural_support` | 512×512, 1f | P1 next-pass |
| 6 | 01 Crèche | `structural_support` | 512×512, 1f | P1 next-pass |
| 7 | 07 Gate of Dust | `edge_transition` | 256×256, 1f | P1 next-pass |
| 8 | 10 South Reach | `edge_transition` | 256×256, 1f | P1 next-pass |
| 9 | 01 Crèche | `edge_transition` | 256×256, 1f | P1 next-pass |
| 10 | 06 Undergate | `distant_structures` | 1024×512, 1f | P1 next-pass |

## 1. 07 Gate of Dust · `distant_structures` (1024×512, 1 frame)

**Reason:** Test monumental city-scale without visually duplicating the Gate.

**Full image-generation prompt**

> Create a SINGLE static top-down / gently angled aerial-oblique (match existing production Gate plaza, NOT a diorama), 1024×512 RGBA environmental SUPPORT silhouette for CUSTODIAN Zone 07. These are the RUINED THRESHOLD DISTRICT outside the existing playable 1536×768 Gate plaza: dark collapsed retaining terraces on both lateral margins, fractured checkpoint wall fragments, inaccessible snapped bridge ends, weathered civic buttresses, sparse fallen statuary and dust-muted city fragments in the far wings. Leave protected transparent clearance for both existing lateral stair apertures in the real production Gate art as well as the midframe/central route and existing Gate body, west/east pylons and sealed aperture; do not paste rubble over the stair mouths, and DO NOT paint a second complete central Gate, causeway, arch or broad road. Pale ash and subdued rust-red sediment over smoke-dark limestone and basalt, oxidized dull-brass detail. Forms must read at actual game zoom and be visibly blocked/inaccessible. Authentic transparency OUTSIDE irregular architecture; no floor-shaped full opaque rectangle; no characters, text, UI or new portals. Light/dark values must be lower priority than the playable floor.

- **Asset family:** `awakening_gate_of_dust_perimeter_support`
- **Source master:** `custodian/asset_drop/source_work/awakening/awakening_gate_of_dust_perimeter_support/distant_structures_source.png`
- **Normalized intake:** `custodian/asset_drop/inbox/awakening_gate_of_dust_perimeter_support/distant_structures.png`
- **Future family contract:** `custodian/content/metadata/assets/families/awakening_gate_of_dust_perimeter_support.asset.json`
- **Technical gate:** Real alpha outside silhouettes, correct production-camera perspective, no occlusion/duplicate gameplay path.

## 2. 10 South Reach · `distant_structures` (1024×512, 1 frame)

**Reason:** Show ruined civic sprawl without painting another playable boulevard.

**Full image-generation prompt**

> Create ONE static 1024×512 PNG RGBA irregular silhouette supporting CUSTODIAN Zone 10 South Reach. Match the real Road of Witnesses' five 2D aerial-oblique runtime modules and their vertical 768×896 south_reach_civic_axis, retaining a deliberately transparent central corridor: the production Road, paving, statues and northern barricade already exist. Paint only LATERAL nonplayable ruins and receding civic skyline fragments: left broken administrative arcades and column bases; right partly collapsed roofless colonnades, inaccessible plaza fragments and broken office/civic foundations. Architectural masses must terminate at collapse or impassable rubble, never supply a convincing alternative footpath, center boulevard or opening north. Desaturated charcoal basalt, pale worn stone, dull bronze trim, dry grey ash haze, very limited verdigris, restrained lighting. Genuine irregular-alpha boundary, not a tiny standalone illustrated city/map and no replacement Road floor. Single frame.

- **Asset family:** `awakening_road_south_reach_perimeter_support`
- **Source master:** `custodian/asset_drop/source_work/awakening/awakening_road_south_reach_perimeter_support/distant_structures_source.png`
- **Normalized intake:** `custodian/asset_drop/inbox/awakening_road_south_reach_perimeter_support/distant_structures.png`
- **Future family contract:** `custodian/content/metadata/assets/families/awakening_road_south_reach_perimeter_support.asset.json`
- **Technical gate:** Real alpha outside silhouettes, correct production-camera perspective, no occlusion/duplicate gameplay path.

## 3. 01 Crèche · `distant_structures` (1024×512, 1 frame)

**Reason:** Set the interior institutional architecture language for 02–04.

**Full image-generation prompt**

> Paint ONE 1024×512 transparent RGBA overhead/near-overhead CUSTODIAN Zone 01 periphery silhouette, DORMANT RECOVERY STACKS. Take the production Crèche 960×704 underlay's exact scale/palette as the reference. Beyond the room edges show inaccessible side banks of redundant recovery-alcove cubicles, sterile-industrial wall bays, thick compartment seals, dark machine cabling and faint cold diagnosis indicators fading away. Every possible side route must be blocked by physical partitions, closed containment shutters or rubble, not an open playable hall. Materials near-black graphite, aged medical-ceramic ivory, smoked glass, recessed dull-brass authority trims, barely-visible teal status. Reserve a no-overlap region for the actual already-baked first computer, its existing 128×128 published console sprite, and its screen-local activation FX; do not depict any new functional console or text. Irregular real RGBA perimeter silhouette with deep structural shadow, not a framed second room. One frame, no people/UI.

- **Asset family:** `awakening_creche_perimeter_support`
- **Source master:** `custodian/asset_drop/source_work/awakening/awakening_creche_perimeter_support/distant_structures_source.png`
- **Normalized intake:** `custodian/asset_drop/inbox/awakening_creche_perimeter_support/distant_structures.png`
- **Future family contract:** `custodian/content/metadata/assets/families/awakening_creche_perimeter_support.asset.json`
- **Technical gate:** Real alpha outside silhouettes, correct production-camera perspective, no occlusion/duplicate gameplay path.

## 4. 07 Gate of Dust · `structural_support` (512×512, 1 frame)

**Reason:** Test a 32px-aligned seamless exterior foundation without misleading floor.

**Full image-generation prompt**

> Create an EXACT 512×512 1-frame seamless REPEATABLE top-down architectural foundation texture for the unplayable margins of CUSTODIAN's Gate of Dust. Every opposing left/right and top/bottom edge MUST join seamlessly. Thirty-two-pixel-cadence construction: cracked smoked limestone slabs, aged civic hardstand, graphite basalt insets, narrow oxidized-bronze seams, mineral wear, shallow ashen sediment. It is an underlying material field for collapsed retaining terraces, NOT the actual central Gate route, NOT a standalone room and NOT a decorative terrain portrait. No vignette, no full-scene lighting, no buildings, no statues, no doors or landmarks, no isolated path. Keep low contrast so imported room plates remain focal. Opaque within the intended background tile is permissible. Top-down game scale, no photoreal perspective.

- **Asset family:** `awakening_gate_of_dust_perimeter_support`
- **Source master:** `custodian/asset_drop/source_work/awakening/awakening_gate_of_dust_perimeter_support/structural_support_source.png`
- **Normalized intake:** `custodian/asset_drop/inbox/awakening_gate_of_dust_perimeter_support/structural_support.png`
- **Future family contract:** `custodian/content/metadata/assets/families/awakening_gate_of_dust_perimeter_support.asset.json`
- **Technical gate:** Seamless left/right and top/bottom repeat tests at actual pixel edges; no distinctive baked giant landmark.

## 5. 10 South Reach · `structural_support` (512×512, 1 frame)

**Reason:** Match Road's established civic paving without repainting it.

**Full image-generation prompt**

> Produce an EXACT 512×512 seamless horizontally and vertically tileable top-down support substrate for off-Road SOUTH REACH civic ruins. Match the real Road of Witnesses module colors and scale but never imitate or repaint its central processional avenue. Use peripheral shattered basalt hardstand, pale limestone rubble-cement matrix, hairline mortar seams in a 32px modular cadence, old dull brass edge fittings and restrained dust. This supports ruined side streets that have become impassable, not new playable pavement. Continuous tile edges with no visible repeats, no centered circular medallion, no statues, no structures, no route arrows, no perspective elevation, no lighting vignette. Single PNG frame.

- **Asset family:** `awakening_road_south_reach_perimeter_support`
- **Source master:** `custodian/asset_drop/source_work/awakening/awakening_road_south_reach_perimeter_support/structural_support_source.png`
- **Normalized intake:** `custodian/asset_drop/inbox/awakening_road_south_reach_perimeter_support/structural_support.png`
- **Future family contract:** `custodian/content/metadata/assets/families/awakening_road_south_reach_perimeter_support.asset.json`
- **Technical gate:** Seamless left/right and top/bottom repeat tests at actual pixel edges; no distinctive baked giant landmark.

## 6. 01 Crèche · `structural_support` (512×512, 1 frame)

**Reason:** Provide a matching repeatable indoor structural rim and gauge material fit.

**Full image-generation prompt**

> Create an EXACT 512×512, edge-to-edge seamless overhead texture of the unplayable outer FOUNDATION surrounding the Crèche of Answerless Names, at 32px registration. Reinforced dark graphite/ceramic containment plinths, thick sealed machine footings, sparse narrow weathered-brass seam rails, ash-smudged ivory floor edges and old maintenance cable slots. Must tile perfectly on every image boundary, without a center room outline, open corridor, decorative glowing screen, console or floor-arrow markings. Flat legible production-game appearance, muted against the actual 960×704 Crèche underlay. One frame; no character/text. Intended as a structural background substrate, not a route.

- **Asset family:** `awakening_creche_perimeter_support`
- **Source master:** `custodian/asset_drop/source_work/awakening/awakening_creche_perimeter_support/structural_support_source.png`
- **Normalized intake:** `custodian/asset_drop/inbox/awakening_creche_perimeter_support/structural_support.png`
- **Future family contract:** `custodian/content/metadata/assets/families/awakening_creche_perimeter_support.asset.json`
- **Technical gate:** Seamless left/right and top/bottom repeat tests at actual pixel edges; no distinctive baked giant landmark.

## 7. 07 Gate of Dust · `edge_transition` (256×256, 1 frame)

**Reason:** Test real irregular alpha seam with major outdoor architecture.

**Full image-generation prompt**

> Generate a static 256×256 top-down/production-camera-aligned TRUE RGBA DECAL for the nonplayable edge of Gate of Dust. A physically plausible fragment of fractured limestone parapet, broken relief masonry, loose graphite rubble and a shallow drift of ash-red dust fading out through irregular damaged edges. Do NOT compose a full tower, another Gate, a small independent road, a giant statue, or a playable doorway. Real transparent alpha exterior, crisp premultiplication-safe edges, no fake black rectangle and no checkerboard; restrained highlights and scale matched to existing 1536×768 Gate underlay. No UI or text. One frame.

- **Asset family:** `awakening_gate_of_dust_perimeter_support`
- **Source master:** `custodian/asset_drop/source_work/awakening/awakening_gate_of_dust_perimeter_support/edge_transition_source.png`
- **Normalized intake:** `custodian/asset_drop/inbox/awakening_gate_of_dust_perimeter_support/edge_transition.png`
- **Future family contract:** `custodian/content/metadata/assets/families/awakening_gate_of_dust_perimeter_support.asset.json`
- **Technical gate:** Alpha bounding mask and edge-halo test; irregular nonplayable margin, not faux open ground.

## 8. 10 South Reach · `edge_transition` (256×256, 1 frame)

**Reason:** Connect fallen civic architecture to Road-owned modules without duplicating floor.

**Full image-generation prompt**

> Generate one 256×256 pixel true transparent-alpha edge-detail for the unusable margins of the Road of Witnesses at South Reach. A broken street-side stone arcade FOOTING with two partial worn column bases, fractured gutters and pale collapsed limestone grit against dark chipped basalt, with low grey dust and irregular boundary. Match top-down/near-overhead runtime perspective, no isometric diorama depth; zero intact side walkway, zero replacement Road centerline, no sign/console/loot. The center of the canvas remains local context only; outlying pixels genuinely transparent. No opaque rectangular matte, one static frame.

- **Asset family:** `awakening_road_south_reach_perimeter_support`
- **Source master:** `custodian/asset_drop/source_work/awakening/awakening_road_south_reach_perimeter_support/edge_transition_source.png`
- **Normalized intake:** `custodian/asset_drop/inbox/awakening_road_south_reach_perimeter_support/edge_transition.png`
- **Future family contract:** `custodian/content/metadata/assets/families/awakening_road_south_reach_perimeter_support.asset.json`
- **Technical gate:** Alpha bounding mask and edge-halo test; irregular nonplayable margin, not faux open ground.

## 9. 01 Crèche · `edge_transition` (256×256, 1 frame)

**Reason:** Prove an indoor broken wall/alcove seam without covering playable Crèche.

**Full image-generation prompt**

> Create ONE 256×256 RGBA overhead edge-transition decal for the inaccessible OUTSIDE of CUSTODIAN's first Crèche room. Partial reinforced ceramic compartment footings, severed insulated cabling, a broken UNUSED recovery-alcove casing and chipped charcoal partition dust on the floor edge, all diminishing into true transparent damaged silhouette. Materials exactly graphite, ivory aged medical ceramic and sparse aged-brass trim at existing Crèche 960×704 plate scale. This is an architectural seam, NOT the interactive first computer, a second waking pod, a new door, or an illuminated VFX overlay. Do not cover the actual console or activation FX. No legible lettering, broad dark rectangle, fake checkerboard or open path. One frame.

- **Asset family:** `awakening_creche_perimeter_support`
- **Source master:** `custodian/asset_drop/source_work/awakening/awakening_creche_perimeter_support/edge_transition_source.png`
- **Normalized intake:** `custodian/asset_drop/inbox/awakening_creche_perimeter_support/edge_transition.png`
- **Future family contract:** `custodian/content/metadata/assets/families/awakening_creche_perimeter_support.asset.json`
- **Technical gate:** Alpha bounding mask and edge-halo test; irregular nonplayable margin, not faux open ground.

## 10. 06 Undergate · `distant_structures` (1024×512, 1 frame)

**Reason:** Set the machine-to-civic visual handoff without duplicating Dust Lung V2.

**Full image-generation prompt**

> Render a single static 1024×512 transparent RGBA top-down/production-camera-aligned silhouette of the INACCESSIBLE BURIED ROUTEWORKS outside Undergate's existing 1536×1216 Mechanism Hall underlay. Immense dark gear-housing shoulders on the sides, pressure conduits bolted into old stone, blind transport drums, heavy cable galleries and a partly collapsed WEST records annex at the extremity. Interior is unlit except very small dull cyan/amber index lights; iron black, lead-grey stone and stained brass coil architecture. Keep the live 05→06 passage, mechanism hall floor and actual damaged-port console entirely unobstructed; never create a new door, another transit lift or a continuous bypass hallway. Low contrast distant atmospheric shadows, believable industrial scale with irregular transparent cutouts, not a rendered 3D miniature city or box-shaped overlay. No characters/text/UI.

- **Asset family:** `awakening_undergate_perimeter_support`
- **Source master:** `custodian/asset_drop/source_work/awakening/awakening_undergate_perimeter_support/distant_structures_source.png`
- **Normalized intake:** `custodian/asset_drop/inbox/awakening_undergate_perimeter_support/distant_structures.png`
- **Future family contract:** `custodian/content/metadata/assets/families/awakening_undergate_perimeter_support.asset.json`
- **Technical gate:** Real alpha outside silhouettes, correct production-camera perspective, no occlusion/duplicate gameplay path.

## Provenance, review and use boundary

Do not manually copy rendered outputs into `custodian/content`. For each generated candidate retain the original source-work PNG, actual output dimensions and SHA-256, image/family/state ID, intended normalization plan and human review status; stage to inbox only after acceptance, then Asset Pipeline V2 plan/ingest/status/doctor. Calibration must be compared with the actual scene-bound Crèche underlay/foreground and console prop, Gate plaza plus hero components, all five Road module pairs and Undergate machinery; also sample the attached Crèche console eight-frame FX for a **separately-owned** known screen-attachment defect. This batch must not edit console FX, registration or interaction: defect owner is `AWAKENING_INTERACTIBLE_CONSOLE_PORT_PRESENTATION_V1`.

**Stop/go:** 1–3 are visual gate for 4–10. Passing PNG metadata or dimensional normalization never substitutes human review of the in-game overlay. AP0 first measures geometry/camera gaps; artwork may remain source-ready while area masks/layouts are finalized. No readiness promotion of art-dependent packets without approved exact sources/ingested catalog evidence.
