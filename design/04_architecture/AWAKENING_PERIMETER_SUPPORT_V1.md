# Awakening / The First Return: Perimeter Underlay Support V1

**Status:** Approved planning direction; **not implemented art, registered assets, or runtime behavior**.
**Scope:** Nonplayable environmental support immediately outside the authored playable footprints for zones 01–10. 
**Parent authority:** [AWAKENING_FIRST_RETURN.md](AWAKENING_FIRST_RETURN.md); exact gameplay envelopes/route are exclusively owned by `custodian/game/world/awakening/awakening_layout.gd`.
**Asset rules:** [AWAKENING_ASSET_MANIFEST.md](AWAKENING_ASSET_MANIFEST.md), [ASSET_PIPELINE_V2.md](ASSET_PIPELINE_V2.md).
**Production prompt source:** [AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md](AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md).
**Implementation sequence:** [AWAKENING_PERIMETER_SUPPORT_IMPLEMENTATION_ROADMAP.md](AWAKENING_PERIMETER_SUPPORT_IMPLEMENTATION_ROADMAP.md).
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a
**Date:** 2026-10-09

## Design lock

The First Return must read as **one vast, failed institution that opens into a ruined civic landscape**, not nine floating room plates. Off-route visible geography is a physical continuation of existing architecture, not a secret alternate playable level. Visual evolution is deliberately staged: recovery stacks → processing wards → registry → armament annex → ruptured cistern → buried routeworks → gate district → processional quarter / devotional chapel → fallen civic expanse.

The player must perceive three concentric visual roles, ordered front-to-back below existing actor and canonical foreground:
1. **Structural rim**: believable immediate continuation of floors/walls/cavern edge, accurately joined to the existing plate without changing its pixels.
2. **Inaccessible continuation**: blocked side chambers, machinery depths, broken bridges, city ruins; visibly unusable, with no false entrances or collision promises.
3. **Atmospheric falloff**: reduced contrast/saturation and occluded or dust-darkened distance that hides scene extent, not a solid rectangular edge.

These are visual roles, not three extra playable regions. No physics, triggers, navigation, Zone Area2D, spatial authority, quest rewards or interactions may be supplied by a support plate. Never use support art as a workaround for missing authored geometry.

## Zone-by-zone contract

| Zone | Existing section | Proposed peripheral region | Proposed Asset V2 family | Narrative function |
|---|---|---|---|---|
| 01 | Crèche of Answerless Names | **Dormant Recovery Stacks** | awakening_creche_perimeter_support | one recovered Operator among hundreds of vacant/unresponsive units |
| 02 | Recovery Ambulatory | **Abandoned Processing Wards** | awakening_ambulatory_perimeter_support | the Crèche was a processing facility, not a lone awakening chamber |
| 03 | Attestation Gallery | **Silent Registry** | awakening_attestation_perimeter_support | identity verification once demanded a sprawling bureaucracy |
| 04 | Locker Reliquary | **Sealed Armament Annex** | awakening_locker_reliquary_perimeter_support | P-9 issuance is a narrow surviving right, not general arsenal access |
| 05 | Dust Lung Cistern | **Subterranean Rupture** | awakening_dust_lung_perimeter_support | first shocking reveal of institutional scale and collapse |
| 06 | Undergate Mechanism Hall | **Buried Routeworks** | awakening_undergate_perimeter_support | the player's mechanisms are exposed fragments of a city-scale transport system |
| 07 | Gate of Dust | **Ruined Threshold District** | awakening_gate_of_dust_perimeter_support | passage between institutional machinery and the scale of the old city |
| 08 | Custodian Approach | **Dead Processional Quarter** | awakening_approach_perimeter_support | history, burial and civic memory gradually replace sterile machinery |
| 09 | Chapel of Late Service | **Forgotten Devotional Precinct** | awakening_late_service_perimeter_support | people ritualized pieces of the abandoned institution after official service ended |
| 10 | Road of Witnesses: South Reach | **Fallen Civic Expanse** | awakening_road_south_reach_perimeter_support | the Road belongs to a much larger dead city; north barricade still closes the prologue |

### Specific composition instructions

**01 Dormant Recovery Stacks.** Frame the Crèche of Answerless Names with serial recovery chambers, inactive body alcoves, separated vault cells and heavily insulated conduits. Material language: charcoal graphite ceramic, oxidized brass ID trims, matte medical-industrial panels, cold pinprick status lamps. Its storytelling purpose is one recovered Operator among hundreds of vacant/unresponsive units. Do not depict accessible new exits.

**02 Abandoned Processing Wards.** Frame the Recovery Ambulatory with octagonal circulation's surrounding medical processing cells, observation partitions and descending central service shaft. Material language: aged pale bone ceramic, blackened glass, desaturated teal indicator glass, brushed brass medical fixtures. Its storytelling purpose is the Crèche was a processing facility, not a lone awakening chamber. Do not depict accessible new exits.

**03 Silent Registry.** Frame the Attestation Gallery with side archives and long ranked record stacks behind rows of authority attestation steles. Material language: near-black dressed stone, bronze registry rails, aged parchment composite plates, soot-faded ivory seals. Its storytelling purpose is identity verification once demanded a sprawling bureaucracy. Do not depict accessible new exits.

**04 Sealed Armament Annex.** Frame the Locker Reliquary with inaccessible designation-keyed vault banks, reinforced armament racks, sealed security compartments. Material language: smoked gunmetal, dark basalt flooring, brushed brass designation rails, faded amber lock indicators. Its storytelling purpose is P-9 issuance is a narrow surviving right, not general arsenal access. Do not depict accessible new exits.

**05 Subterranean Rupture.** Frame the Dust Lung Cistern with vast ruptured reservoir, deep maintenance shafts, hanging pipe galleries, broken bridges, enormous dry void. Material language: cold charcoal stone, rusted pipe iron, chalky deposits, ashen sediment, diluted pale-blue daylight. Its storytelling purpose is first shocking reveal of institutional scale and collapse. Do not depict accessible new exits.

**06 Buried Routeworks.** Frame the Undergate Mechanism Hall with immense blind pressure and route-indexing mechanisms, gear housings, cable galleries and west-side departure records. Material language: oil-dark iron, lead-grey masonry, dull brass coils, worn calibration enamel, tiny dim indicator cyan. Its storytelling purpose is the player's mechanisms are exposed fragments of a city-scale transport system. Do not depict accessible new exits.

**07 Ruined Threshold District.** Frame the Gate of Dust with fortified threshold terraces, cracked defensive walls, collapsed causeway approaches and first hints of historical city. Material language: smoke-stained monumental limestone, dark civic basalt, tarnished bronze, ashen sand, rust-red dust. Its storytelling purpose is passage between institutional machinery and the scale of the old city. Do not depict accessible new exits.

**08 Dead Processional Quarter.** Frame the Custodian Approach with burial terraces, ruined chapel shells, fractured civic gardens and abandoned processional side streets. Material language: pale ashen stone, dark slate processional paving, subdued bronze, dead grasses, muted rust patina. Its storytelling purpose is history, burial and civic memory gradually replace sterile machinery. Do not depict accessible new exits.

**09 Forgotten Devotional Precinct.** Frame the Chapel of Late Service with inaccessible cloisters, broken side shrines, memorial galleries and retired relay-lamp service conduits. Material language: smoked limestone, desaturated bronze votive details, weathered linen banners, chalk white thread. Its storytelling purpose is people ritualized pieces of the abandoned institution after official service ended. Do not depict accessible new exits.

**10 Fallen Civic Expanse.** Frame the Road of Witnesses: South Reach with collapsed colonnades, broken civic plazas, inaccessible avenues, distant administrative towers and city foundations. Material language: worn dark civic basalt, sun-bleached limestone, dulled brass wayfinding, low dusty rust and grey haze. Its storytelling purpose is the Road belongs to a much larger dead city; north barricade still closes the prologue. Do not depict accessible new exits.

## Runtime ownership and seams

- Current runtime already creates `AwakeningVoidBackdrop` beneath all underlays using `Layout.WORLD_BOUNDS.grow(1024)`; this remains the **last-resort neutral fallback**, not the full design. Do not globally delete/replace it until every camera-visible support region is complete and coverage-tested.
- The **actual** underlays and foregrounds for Zones 01–09 remain untouched in their established canvases at the exact Layout-derived centers. Existing Road-of-Witnesses modular plates remain separate Road-owned art.
- The accepted registered 04→05 Dust→connector→Locker art is a **single source-preserving 1502×2048 composition**, placed at shared root `(349,-2585)`, native 1:1, zero rotation, with order Dust → connector → Locker. All perimeter plates remain below that composition and cannot replace, crop, resize, feather or alter any of its source pixels or fade ownership. Resolve the pending narrow connector fade repair and handoff-convergence review first.
- Lower-to-upper 05→06 is a single `Rect2(-64,-3840,128,96)` passage. No perimeter texture may cover its walkable samples or occlude the Operator.
- Gate pylons, the authored central path, optional Chapel 08↔09 and Approach→Road south gate remain unchanged. The visually sealed Gate aperture is a separate known authored-state question; **do not fake an opened gate with perimeter art**.
- The Road's five production modules are owned by `RoadOfWitnessesPrototype`. Zone 10 support only surrounds the South Reach relevant to Awakening; it does not paint future Hub playable streets or change the north barricade at `y=-6530`.
- Build a focused scene-owned presentation host/controller or appropriately bounded dedicated layer beneath zone art; avoid swelling `awakening_first_return.gd` with a second world geometry implementation. Camera-visible support may be driven by Layout zone envelopes and resolved actual art bounds, but must never define collisions or expand the gameplay world.
- Presentation bounds, z-index, fade, order, clipping and culling are derived and tested from current scene/renderer evidence. No frame-rate dependent load hitch, per-frame texture churn, global lighting replacement or camera bounds enlargement.

## Proposed Asset V2 source specification (planning sizes, not yet registered)

Each named zone family is a **`backdrop` family** with three static, omni, no-mirror, one-frame states; native mapping = one source pixel per world unit where feasible. Same semantic states are independent images rather than baked expansions of existing production plates.

| State | Proposal | Alpha | Placement role |
|---|---:|---|---|
| `structural_support` | 512×512, 1 frame, 1×1 | Tile/fill can be opaque **within intended support coverage**; no opaque pasted rectangular border over live plate | Repeatable 32px-aligned rim material. Seamless when tiled. |
| `distant_structures` | 1024×512, 1 frame, 1×1 | True RGBA outside architectural silhouette; physically coherent internal shadows | Sparse large site-specific ruined architecture beyond structural rim. |
| `edge_transition` | 256×256, 1 frame, 1×1 | True RGBA and clean partial silhouettes (no baked checkerboard) | Local jagged detail hiding obvious straight image terminations. |

**All dimensions are proposed first-pass inbox targets**, not promises that unknown model-generated images can be nonuniformly resized. Generators may deliver larger masters. Reject/regenerate any source whose silhouette/registration cannot be cropped/padded or uniformly resized without losing aspect ratio. Confirm actual camera footprint, required extension and placement rectangles in AP0 before final family publication. If support cannot be safely realized from exactly these three states, amend this specification with evidence before creating additional states. Layered atmospheric falloff may be deterministic Godot opacity/shading rather than a new PNG.

New/unprocessed assets must use:
```text
custodian/asset_drop/source_work/awakening/<family>/<state>_source.png
custodian/asset_drop/inbox/<family>/<state>.png
custodian/content/metadata/assets/families/<family>.asset.json
```
`asset.py plan/ingest/status/doctor` (Asset Pipeline V2) owns publication; never copy art directly to `custodian/content/` or handwrite canonical runtime filenames. Do not add nonexistent files to generated `REQUIRED_ASSETS.md`; register actual demand in `required_assets.registry.json` when the technical contracts are implemented, regenerate its view, and keep the need pending until provenance/catalog confirms fulfillment.

## Objective acceptance

1. Normal authored traversal and all canonical collisions, encounter slots, triggers, progression, camera reveals and exit anchors remain untouched.
2. Camera-visible off-route areas appear architecturally continuous across mandatory joins, without black/grey rectangular drops, duplicated floors, false open paths or art masking the Operator.
3. Foreground/player readability and LightDirector ownership are unchanged; distant shapes are less contrasty than active floor/interactive props.
4. No perpetual live art/legacy fallback double-render, transparent-edge halo, source-stretching or new frame-time spikes.
5. Proof order: Layout + registered bounds → scene/node identity/alpha/z-order/collision absence → image alpha/seam metrics → one compact human-owned aesthetic review per materially distinct batch. Prefer `Moment Forge --capture-mode none` during iteration and at most a targeted evidence pass for final art approval.
6. Missing/unapproved art **fails safely to existing appearance**, not to invented filler. Any user visual rejection reopens the specific asset state, not the traversal logic.

## Status / dependencies

- **Planning decision locked:** region identities and atmospheric progression.
- **Technical/image production unfulfilled:** none of the 30 proposed perimeter images are claimed to exist or be ingested.
- **Active prerequisite:** finish/review the 04→05 fade-ownership repair and the Awakening handoff/art-convergence workstream before touching shared registration/fade.
- **Human gates:** actual generated art and aesthetic acceptance for each group; preserve draft/manual downstream packet states until reviewed source and manifest exist.
