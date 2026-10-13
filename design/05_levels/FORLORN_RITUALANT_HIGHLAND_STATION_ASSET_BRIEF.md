# Forlorn Ritualant — Highland Station Production Art Brief V2

**Status:** full approved *art-production design brief*, not generated/ingested artwork
**Workstream:** `ritualant-highland-station-redesign`
**Date:** 2026-10-12
**Verified baseline:** CUSTODIAN `main@85cabcfe6aa5` at authoring start; verify latest `main` before intake
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
**Design authority:** `design/05_levels/FORLORN_RITUALANT_HIGHLAND_STATION_DESIGN_LOCK.md`
**Companion machine-readable planning inventory:** `design/05_levels/FORLORN_RITUALANT_HIGHLAND_STATION_ART_HANDOFF_MANIFEST.json`
**Runtime:** Godot 4.x, authored 112×128 cell Underground; 32px/cell; camera bounds `Rect2(-1792,-2048,3584,4096)`; chapel origin `(0,-1120)`; lift dock `(0,1696)`; chamber bound `Rect2(-640,-1600,1280,960)`

> **Do not treat this as a command to generate art immediately.** The existing 37-state Underground family is live; reviewed six-state ritual-prop and six-state chamber-dressing asset batches are already tracked via a separate intake packet and their family metadata was not found at the reviewed `main`. Audit the actual supplied source ZIP/repository catalog first. The states below are scoped candidates with explicit priority, not claims of pixels already approved, bound or production-ready.

## 0. Art-direction decision

This level is **not a decorated cave**. The walk from the lift should progressively expose a worked Highland installation, then a compromised receiver gallery, then a non-original chapel physically intruding into the station. The visual story is built from **four traceable material layers**:

- **H0 / active-Highland geology:** mountain rock, chasms, natural drainage, local ground; preserve the existing native cave framing, rims and far underlays. Do not automatically claim the lift belongs to the original station. Its provenance must be proved at the route blockout.
- **H1 / station-original structure, displaced during the Open Interval:** reinforced service tunnel, gallery, receiver support, conduit channels, lockers, measured industrial construction. *Station-original* means original to the Ash-Bell Highland station, **not automatically original to the active continuity**.
- **H2 / non-original continuity overlap:** an improperly registered chapel, false arch, remembered gate and Dry Fountain apparition; these need obvious mismatches to the station's material logic without becoming random impossible geometry.
- **H3 / Ritualant's later human ritual:** reused White Thread, black containment cloth, hand-laid ash and counting/mourning arrangements. This is handwork layered on both H1 and H2, not a magical native building style.

The station is **one of I–VIII**, precise numeral reserved. The Meridian city, Lower Quarter and historical Station IX remain across Bridged Falls. Don't engrave Station IX onto new artwork, manufacture a physical Ninth Bell or depict the Ritualant completing the original historic Open Interval.

## 1. Visual language and target experience

### First-read silhouette

At the lower lift, recognizable engineered details appear inside rugged rock. Through the service tunnel, the construction becomes more ordered: consistent rib spacing, exposed mechanical anchors and aligned cable routes. In the gallery, one **receiver mass** visibly connects to support frame, service floor and conduits. Beyond it, the chapel's columns and masonry interrupt those rules. The player's feeling should change from *abandoned infrastructure* to *something occupying the wrong space*. The Ritualant is the final emotional focus, not another giant prop.

### Materials

- **Station stone and concrete:** worn ash-gray masonry, dark graphite mortar, practical repairs. Rectilinear load-bearing masses and larger-scale, readable bolted joints.
- **Iron/steel:** blackened structural members, edge wear only where handling/contact occurs. Never uniformly rusty orange.
- **Ceramic insulation:** pale ivory/gray segments on receiver assembly; this is what visually distinguishes genuine station machinery from gothic fantasy furniture.
- **Service copper/brass:** restrained, browned contact surfaces at junctions and handles. The key should look manufactured and serviceable, not ornate.
- **Highland geology:** dark stratified stone, mineral seep, a few natural cutouts, no tile-pattern wallpaper or amorphous gray void.
- **Chapelic displacement:** older or foreign masonry with inconsistent joints, incomplete edges and selective apparition opacity. Keep provenance visible at seams.
- **Ritual material:** real cloth and thread, physical bindings, imperfect human knots. White Thread should remain an observed custody practice; avoid luminous web magic.

### Values, light and colors

Use existing Underground and Meridian civic palettes as review targets; do **not** impose arbitrary new global hex colors. Keep cave H0 dark but navigable. H1 edges need value separation so railings, plinths and machinery silhouettes can be recognized at standard gameplay zoom. Ceramics should be cooler/lighter than iron. Small weak amber service residues may identify operator controls. H2 should differ chiefly through **geometry/material registration**, not purple neon or constant color grading. H3 is warm/dim and tactile, not a flood of candles.

The intentional brightest **functional** point is the receiver socket/key match when in reach. During final release, lower intensity and simplify instead of turning everything gold.

### Pixel-art and camera

- Art is authored for a 2D top-down/oblique game where world layout uses **32px** semantic cells; preserve hard, intentionally stepped pixel contours.
- Actor scale is currently **128×128 per source frame**, not a license to draw 128px props at four times the human scale.
- Art canvases are **source bounds**, not mandatory world footprint size. Align placed art to native size unless the accepted existing scene uses a documented transform; no arbitrary nearest-neighbor enlargement just to fill space.
- In-screen UI, physical collision, interaction and navigation are independent authorities; no painting traversable surfaces where mapper collisions disagree.
- Structural top faces, near-side occluders, floor contact and foreground overlays must be separately placeable. No single flattening image that permanently hides an Operator walking behind its front edge.
- Stable alpha on prop and overlay silhouette boundaries. Large far underlays may be deliberately opaque or feathered under existing materials. True-transparent states must not contain opaque black void, white matting or premultiplied fringes.

## 2. Authored zone-to-art direction

| Zone / player beat | Construction read | Art focal point | Gameplay/interaction read | Composition / anti-filler |
| --- | --- | --- | --- | --- |
| **01 Lower lift landing** | H0 rock, measured H1 fittings; lift itself subject to existing authority | `landing_dock_interface`, current lift back/fore and shaft assets | A built access into a staffed underground facility, optional plaque | Start mostly normal; no strong cosmic effect at spawn |
| **02 Service tunnel** | H1 ribs, conduit, wet engineering; H0 intrudes at fractures | Rib + straight/junction trenches | Inspection reveals original industrial purpose; movement remains uninterrupted | Repeat kit intelligently, use unequal spacing/damage; do not make a long empty runway |
| **03 Receiver approach** | H1 machinery grows legible | Gallery silhouette visible before keypad/item | **Player sees the absent keyed seat** and learns what sort of component is missing | Keep the socket legible before a quest prompt; use framing rather than screen text |
| **04 Key recovery alcove** | H1 tool storage/recent breakage, some H2 displacement | Open/closed case, key pickup, small record | Item found **outside chapel arena**; evidence explains where staff stored it | A short, physically justified side pocket, not a scavenger-hunt maze |
| **05 Isolation Gallery** | H1 machine with real load-bearing receiver support | `gallery_support_mass`, receiver chassis, isolated seat, reference marks | Return and turn Receiver Key; local contact/reference both settle | Largest station-authored hero composition; leave player movement space |
| **06 Chapel overlap threshold** | H1 engineering physically interrupted by H2 chapel | Station bones beneath false arch, displaced column edge | Local visual doubling shows not every wall belongs to the station | Impossible seam is found in geometry itself, not a cutscene |
| **07 Ritualant chapel** | H1 receiver traces, H2 shell/wrong basin, H3 ritual cloth and thread | Ritualant silhouette, basin, chapel bell, personal arrangements | Free-roaming dialogue and distinct violence/peaceful outcomes | Maintain actor sightlines and combat telegraphs; do not bury chapel under extra set dressing |
| **08 Resolved north throat** | H0 Highland rock beneath retreating H2 obstruction | Existing north seal plus optional station edge | Opens toward generated Highlands; safe return/re-entry | Art changes never silently modify collision/route state |

**Spatial order is a design sequence, not fictional mapper coordinates.** The empty socket should be noticed before or around key discovery, and the key should not require dialogue-topic exhaustion to obtain. Existing south lift exfil, camera zones and chapel combat bounds must survive. The 112×128 map is ample; do **not** increase map size until a traversal review proves need.

## 3. Receiver machine: visual mechanism and states

A station-original **Isolation Gallery** supports a receiver chassis on a braced wall/floor bed. A service-facing insulated socket accepts a removable **Receiver Key**. The key has a machined keyed end, short handle, ceramic isolation sleeve and at least one visible mechanical register/collar. It is **not** a door key, clapper, dagger, spike or magical rune rod.

**Before:** the port is visibly vacant. Contact guard exposes an incorrect return contact. Reference witness marks fail to meet. The receiver is tense/active, its shadow occasionally misregistered, but the machine itself remains materially credible.

**Recovery:** an abandoned service case in a side alcove has the outline/fit for the same component. The item is handled like a tool someone removed in a bad emergency. The pickup world art and inventory icon must match each other exactly in geometry and materials.

**Seat:** insertion aligns physical stops, but the key still needs a brief lock turn. This is **one gameplay interaction with staged animation**, not a new mandatory multi-switch puzzle. The socket `empty`→`inserted`→`locked` is a presentation contract; state authority is separate.

**Result:** return contacts are isolated and local reference indices match. The receiver changes to an inactive/quiet condition. A localized registration mismatch at the gallery/chapel seam relaxes. The Ritualant recognizes the completed act and releases. Do not infer that the player reissued Station IX's historic Answer.

Important: keep the **wrong basin** and the **remembered Dry Fountain** physically distinct from the receiver keyhole. Existing `SetStillingPinInteract` near the basin is **current runtime**, not an art-placement target for the future key. Do not paint a socket into the basin and then have to explain it backward.

## 4. Art family contracts and file identity

These are **proposed** V2 families, not registered live contracts. Reuse currently real family kinds: `backdrop`, `world_prop` and `effect`. The existing `ritualant_underground_environment` uses `backdrop` and exact per-state frame sizes; `carrow_machine_house_props` proves `world_prop` with copy-layout frames; `ritualant_underground_hazard_fx` proves `effect` and horizontal strips.

**No hand-authored canonical runtime basenames.** The `runtime.domain` in the table is a *proposed* location. Final names and bindings come from `asset.py plan`, status/catalog and family `filename_template`. Each source state's normalized inbox filename is exactly `<state_id>.png` and source master filename `<state_id>_source.png`. The companion JSON gives the **complete repo-relative path for every individual source and inbox file**.

| Family ID | Kind | Source-work directory | Normalized inbox directory | Proposed runtime domain |
| --- | --- | --- | --- | --- |
| `ritualant_highland_station_infrastructure` | `backdrop` | `custodian/asset_drop/source_work/ash_bell/ritualant_highland_station_infrastructure/` | `custodian/asset_drop/inbox/ritualant_highland_station_infrastructure/` | `custodian/content/tiles/encounters/ritualant_set/highland_station/` |
| `ritualant_highland_station_receiver_props` | `world_prop` | `custodian/asset_drop/source_work/ash_bell/ritualant_highland_station_receiver_props/` | `custodian/asset_drop/inbox/ritualant_highland_station_receiver_props/` | `custodian/content/sprites/environment/props/ash_bell/highland_station/` |
| `ritualant_highland_station_overlaps` | `backdrop` | `custodian/asset_drop/source_work/ash_bell/ritualant_highland_station_overlaps/` | `custodian/asset_drop/inbox/ritualant_highland_station_overlaps/` | `custodian/content/tiles/encounters/ritualant_set/highland_station/overlaps/` |
| `ritualant_highland_station_overlap_fx` | `effect` | `custodian/asset_drop/source_work/ash_bell/ritualant_highland_station_overlap_fx/` | `custodian/asset_drop/inbox/ritualant_highland_station_overlap_fx/` | `custodian/content/sprites/effects/runtime/ritualant_highland_station_overlap/` |

All family metadata targets: `custodian/content/metadata/assets/families/<family_id>.asset.json`. Final `frame_width`, `frame_height`, `frames`, `fps`, `layout`, `layer`, `action_group`, `variant` and direction fields must be validated against the actual `asset_contract` schema and live generator, not guessed from this list. The manifest JSON is a **planning handoff**, not a substitute for `custodian.asset_family.v2`.

**Priority convention:** `core` = intended minimum viable visual redesign, subject to reuse inspection; `conditional` = produce only if the real blockout/camera evidence proves needed. All entries are presently `unproduced / not verified`. This includes state contracts where no source art yet exists.

### A · Station-original architecture

A person could have maintained this installation. Load paths, bolted supports, service reach and repeated engineering standards must be believable.

| State ID / normalized inbox name | Exact canvas or sheet | Frames; cadence | Provenance | Need | Function / visual notes |
| --- | ---: | --- | --- | --- | --- |
| `landing_dock_interface.png` | 768×512px | 1f static | H0/H1 | core | Station access apron and work-worn lift landing; align existing entry footprint; Reuse current lift assembly; never repaint its moving deck. |
| `service_tunnel_rib.png` | 256×384px | 1f static | H1 | core | Repeatable braced stone-to-iron tunnel support with plausible footings; Create single readable module; do not imply every rock is constructed. |
| `service_tunnel_endwall.png` | 512×384px | 1f static | H1 | core | Service tunnel termination/joint into machinery approach; Architectural transition, not an artificial blocking gate. |
| `conduit_trench_straight.png` | 512×128px | 1f static | H1 | core | Cable/drain trench and maintenance covers along walkable approach; Artwork cannot own walkability or collision. |
| `conduit_trench_junction.png` | 256×256px | 1f static | H1 | core | 90-degree service channel bend/split near gallery; Must tile/align with straight trench at 32px increments. |
| `gallery_support_mass.png` | 1024×768px | 1f static | H1 | core | Primary installed load-bearing receiver bay and support arch; Hero original facility asset; legible anchorage and structural mass. |
| `gallery_work_floor.png` | 768×512px | 1f static | H1 | core | Station maintenance floor, seam bolts and receiver bed footprint; Meet 32px world grid; walkability comes from authored mapper. |
| `gallery_service_walkway.png` | 512×256px | 1f static | H1 | core | Rail, inspection reach and machinery platform edge; Only human-scale reachable sections; no implied vertical platformer. |
| `receiver_isolation_bed.png` | 512×384px | 1f static | H1 | core | Massive wall/floor machinery support carrying receiver assembly; Keep key socket independently readable, do not bury under decorations. |
| `station_bones_under_chapel.png` | 1024×768px | 1f static | H1 | core | Original civil infrastructure visible under displaced chapel shell; Preserve embedded existing arena art where approved. |
| `north_throat_station_edge.png` | 768×512px | 1f static | H0/H1 | conditional | Edge of facility dissolving into genuine highland passage; Coordinate only with north-egress packet, not before route geometry. |

Source path per state: `custodian/asset_drop/source_work/ash_bell/ritualant_highland_station_infrastructure/<state_id>_source.png`; normalized inbox: `custodian/asset_drop/inbox/ritualant_highland_station_infrastructure/<state_id>.png`. See the JSON for all **expanded exact paths** and metadata.

### B · Receiver, key and service props

All machine states must be mechanically continuous. The key and its seat are a matched physical pair and the most important item-read in the level.

| State ID / normalized inbox name | Exact canvas or sheet | Frames; cadence | Provenance | Need | Function / visual notes |
| --- | ---: | --- | --- | --- | --- |
| `receiver_chassis_unstable.png` | 384×384px | 1f static | H1 | core | Receiver body with open return contact, oblique reference marks; Same canvas/pivot as settled state. |
| `receiver_chassis_settled.png` | 384×384px | 1f static | H1 | core | Identical receiver after proper isolation and alignment; Do not shift machine body or create unrelated upgraded design. |
| `receiver_socket_empty.png` | 128×128px | 1f static | H1 | core | Clearly keyed negative-shaped receiver opening; Must visibly accept actual key end at playable scale. |
| `receiver_socket_inserted.png` | 128×128px | 1f static | H1 | core | Receiver Key placed but not turned to full home position; Optional temporal phase used in physical one-shot. |
| `receiver_socket_locked.png` | 128×128px | 1f static | H1 | core | Key fully turned, contacts seated, alignment registered; Distinct from inserted state by mechanical orientation. |
| `return_contact_guard.png` | 128×96px | 1f static | H1 | core | Exposed return contact shroud/ceramic safety guard; Mechanically supports termination without making a magic button. |
| `reference_index_marks.png` | 128×64px | 1f static | H1 | core | Two engraved alignment witness marks with unmatched and matched read; Two marks can be separate scene nodes/rotations, not two duplicated textures. |
| `receiver_key_pickup.png` | 64×64px | 1f static | H1 | core | Standalone iron-and-ceramic keyed service component; Not a fantasy key, pin, clapper, ornament or glowing relic. |
| `receiver_key_inventory.png` | 64×64px | 1f static | H1 | core | UI silhouette of same physical Receiver Key with crisp ceramic/iron contrast; Inventory rendering should be measured, not baked behind colored card. |
| `maintenance_case_closed.png` | 128×96px | 1f static | H1 | core | Recovery alcove box with a keyed fitted compartment; Evidence of proper storage, may be displaced with key absent. |
| `maintenance_case_open.png` | 128×96px | 1f static | H1 | core | Same storage case open, correct key-shaped insert visible; Same registration/pivot as closed; no animate without approval. |
| `service_cabinet.png` | 128×160px | 1f static | H1 | conditional | Abandoned service cupboard, lockable/dented, maintenance used; Reuse old inspected prop if suitable. |
| `station_duty_log.png` | 64×64px | 1f static | H1 | conditional | Small worn maintenance record readable as paper/board; Full text in inspect UI, not raster tiny typography. |
| `ceramic_cable_coupler.png` | 96×96px | 1f static | H1 | conditional | Standardized ceramic/iron conduit junction prop; Reuse existing Meridian support hardware if visual language matches. |
| `receiver_status_active.png` | 128×64px | 1f static | H1 | core | Mechanical indicators for unstable local receiver; No IX label; avoid exposition/status text clutter. |
| `receiver_status_quiet.png` | 128×64px | 1f static | H1 | core | Same indicator plate after returned key has settled the local receiver; Distinguish dark operation from destroyed machine. |

Source path per state: `custodian/asset_drop/source_work/ash_bell/ritualant_highland_station_receiver_props/<state_id>_source.png`; normalized inbox: `custodian/asset_drop/inbox/ritualant_highland_station_receiver_props/<state_id>.png`. See the JSON for all **expanded exact paths** and metadata.

### C · Non-original chapel geometry

The chapel is introduced by cross-continuity overlap. Keep the facility skeleton exposed so the player understands why this architecture should not fit.

| State ID / normalized inbox name | Exact canvas or sheet | Frames; cadence | Provenance | Need | Function / visual notes |
| --- | ---: | --- | --- | --- | --- |
| `chapel_false_arch.png` | 512×512px | 1f static | H2 | core | Cross-continuity chapel arch not matching original support loads; Not a native station wall; leave original structural ribs visible. |
| `chapel_inset_shell.png` | 768×512px | 1f static | H2 | core | Fragment of funerary enclosure overlaid on machine corridor; Physical contradictory edge; not generalized haunted cave dressing. |
| `offset_column_slice.png` | 384×512px | 1f static | H2 | core | Displaced column/wall seam with second impossible registration; Visual copy requires a stable source silhouette. |
| `false_gate_negative.png` | 384×384px | 1f static | H2 | conditional | Suggestion of remembered west gate where no actual route exists; Must not read as accessible actual route or station IX. |

Source path per state: `custodian/asset_drop/source_work/ash_bell/ritualant_highland_station_overlaps/<state_id>_source.png`; normalized inbox: `custodian/asset_drop/inbox/ritualant_highland_station_overlaps/<state_id>.png`. See the JSON for all **expanded exact paths** and metadata.

### D · Local overlap VFX sources

Visible discontinuity should come from local geometry duplication and opacity mismatches rather than a big postprocess effect swallowing the game.

| State ID / normalized inbox name | Exact canvas or sheet | Frames; cadence | Provenance | Need | Function / visual notes |
| --- | ---: | --- | --- | --- | --- |
| `phase_edge_mask.png` | 512×256px | 1f static | H2 | core | Localized alpha mask for scene-relative 1–3px image echo; Shader/material work should own displacement, not baked screenshot. |
| `chapel_echo_mask.png` | 512×384px | 1f static | H2 | core | Selectively reveals alternate chapel/industrial edges; Must be local to geometry, never full-screen HUD overlay. |
| `receiver_seating_pulse.png` | 1536×192px (8 × 192×192) | 8f @ 12 FPS, one-shot | H1/H2 | core | Single restrained mechanical refit event after turning the key; 8-frame 1536×192 strip. No flash or ringing bell. |
| `threshold_shadow_offset.png` | 384×256px | 1f static | H2 | conditional | Second registration/silhouette at chapel threshold; Prefer geometry duplication if a raster cannot prove value. |

Source path per state: `custodian/asset_drop/source_work/ash_bell/ritualant_highland_station_overlap_fx/<state_id>_source.png`; normalized inbox: `custodian/asset_drop/inbox/ritualant_highland_station_overlap_fx/<state_id>.png`. See the JSON for all **expanded exact paths** and metadata.


## 5. Reuse/de-duplication matrix

| Current authority / asset | Treatment | Why |
| --- | --- | --- |
| `ritualant_underground_environment` 37-state family | **Reuse** existing ground, rims, far depth, arrival shaft, mineral haze, native wet/fracture and occluder detail. Extend only on evidence. | Already provides natural cave framework and live camera compatibility |
| `ritualant_underground_hazard_fx` 2-state warning/activation | **Reuse**, do not regenerate | White Thread is a gameplay hazard and already has V2-owned presentation |
| `ash_bell_ritual_props` 6 reviewed source states | **Pending separate intake; check actual catalog** | Bell frame, Pin, thread assets have archived reviewed source. Pin is legacy runtime, not approved future Receiver Key |
| `ash_bell_chamber_dressing` 6 reviewed source states | **Pending separate intake; check actual catalog** | Banners/handprints/sealed markers. Keep usable non-mechanical components without duplicating |
| Ritualant `enemy_forlorn_ritualant` family | **No actor sprite generation in this brief** | Actor state/animation changes need dedicated runtime/pose audit |
| Lower Quarter / Station IX civic art | **Reference material only**, selective reuse of generic bolts/couplers after review | Do not import Station IX's landmark, signage or identical receiver as a shortcut |
| `lower_quarter_seal_01`, DistantChapelProxy, chapel/arena masters | **Preserve live ownership** pending route/visual review | North seal still has a separately gated route packet; distant camera proxy is existing behavior |
| Existing `GhostProcession`, apparition, basin black-water | **Reuse where possible** | Effects have meaningful stage timing; avoid extra anonymous ghost crowds |

No artwork should be marked fulfilled merely because this document now lists it. Require the matching V2 family/state, real file provenance, scene consumer and objective render/alpha evidence.

## 6. Scene composition and layering contract

A suggested presenter stack is:

```text
UnderlayRoot            current cavern void/parallax, mineral/chapel haze
BackgroundRoot          approved ground + H1 gallery floor and work channels
StructuralBase          new H1 wall/receiver support, no independently authored nav
WorldProps              equipment, key alcove, inspected cabinet, key pickup
ContinuityOverlapRoot   H2 chapel shell and localized cross-registered geometry
PlayableRoot            world actor, hazards, canonical interactable areas
OcclusionRoot           near-side ribs, overhangs, chapel threshold, north seal
LocalizedPhaseFX        mask/property presenter tied to encounter/receiver state
HUD/dialogue            unaffected by phase shader or world overlay
```

This is a **logical art ownership map**, not instructions to create parallel physics or hard-code these exact Godot node names. Reuse present `UnderlayRoot`, `BackgroundRoot`, `PlayableRoot`, `OcclusionRoot` and camera-zone directors rather than growing another global presentation stack.

**Registration:** define named anchors for lift interface, first rib, key case, receiver chassis, socket, chapel seam and north throat via authored mapper/debug geometry. Illustrator produces separate PNGs with crisp full-frame alpha; scene owns transforms, occlusion, pivot, collision, trigger volumes and physical actor paths. Use integer world-pixel placement where feasible and preserve pixel snapping.

**Collision / occlusion:** one physical frame near gallery could obstruct movement, but don't invent wall collision by painting pixels; level/mapper authority must explicitly agree. Put receivers behind the actor only when he actually passes in front. Put top beams/near-side lips in occlusion layers with correct origin/pivot and camera behavior. No alpha leak on sprites above the Operator. Keep UI selectable even under overlap effect.

**Visual grammar by reveal:** (1) minimal engineering at lift; (2) repeated built details in tunnel; (3) first large receiver mass; (4) empty socket + recovery clue; (5) shrine/church does not match adjacent machinery; (6) receiver quiet + perceptible but calm site; (7) exit no longer visually sealed. Resist assigning a clue to every meter.

## 7. Dual-reality VFX: renderer-level art acceptance

The player's phrase **"3D-type double vision flickers"** is implemented as **short registration disagreement at different perceived depths**, not an actual 3D conversion or stereo display trick. Two carefully separated representations of the same environmental edge momentarily disagree. Foreground and background may shift by *different* 1–3 world pixels, maintaining legible walkable ground and predictable collisions.

| Parameter | Production target |
| --- | --- |
| Spatial scope | Scene-local only: gallery fault, key alcove anomaly, chapel threshold, wrong-basin echo |
| Default duration | Short, infrequent interruptions, roughly 0.15–0.45 seconds per local pulse; tune after playtest |
| Amplitude | 1–3 world pixels for duplicate sprite/UV registration; no shift of collision or interaction |
| Opacity | Generally faint enough to preserve original structure as authoritative; measured in runtime review |
| Edge treatment | Sparse non-chromatic value separation, no full rainbow aberration |
| Trigger | Bounded encounter/receiver presentation signal or deterministic ambient cadence |
| Resolution | One readable refit pulse, then **less** disturbance; do not escalate to screen-filling victory FX |
| Accessibility | Reduced-flicker option substitutes low-frequency, slow opacity crossfade; never flicker HUD/subtitles |
| Gameplay | No hitbox changes, duplicate actor silhouettes, misleading exits or false hazards |
| Determinism | Event-bound variant ID and deterministic/seeded timing for focused tests and re-entry |

**No dedicated full-screen baked VFX art required.** Source state `phase_edge_mask` and `chapel_echo_mask` are selected local masks, not a permanent noise sheet. Prefer one layered material/controller that duplicates existing **approved** geometry rather than repainting a second environment for every pulse. Keep `receiver_seating_pulse` very restrained: the key seats, a line of registration settles, light/vibration reduces. It should work in silence before sound production is added.

Trigger/event inventory to use in eventual receiver VFX packet (not live yet): player enters tunnel → little/no overlap; nearing gallery fault → occasional; inspecting keyed seat → subtle line disagreement; carrying key nearby → optional small local response but not an invented gameplay detector; successful key turn → fixed one-shot + cessation; hostile/defiled → original unstable effect may persist; return/reload → render the saved resolved state without replaying the one-shot. Terminal `RITUALANT_DISSOLVED` without key remains a separate design case and must not be silently shown as mechanical repair.

## 8. Art / interaction readability and microstory placement

Each new visual clue has one concrete reason to exist:

1. **Access fixture at lift:** a service path was built for workers, not pilgrims.
2. **Ribs, cable trench and cabinet:** people maintained equipment in this mountain; machinery is connected through the level, not a freestanding altar.
3. **Empty receiver seat:** the user notices a missing physical component before a dialogue choice explains it.
4. **Key-shaped maintenance case:** confirms the key's physical origin and why it was absent, without a long exposition plaque. Avoid implying the object simply spawned from the air.
5. **Reference witness marks:** they are out of registration, and later match after key turns.
6. **Chapel seam:** a wall physically contradicts its own support structure. No painted decorative cracks standing in for impossible architecture.
7. **Ritualant working over thread:** this is a person's attempt to organize grief; avoid mystical particles emerging from his hands.
8. **Settled receiver:** ordinary mechanical quiet is the strongest payoff. Let that absence support the existing music cue later.

**Inspectable text is handled in UI/data**, not baked into illegible art. Use only insignia and numbering that do not invent a station ID. Station IX must not be printed as if this facility is IX. If a panel must show numerical synchronization, depict eight historical successes and a recorded remote IX late Answer only with careful lore review; prefer simple mechanical indicators until actor/dialogue audit.

## 9. Art handoff files and pipeline commands

Per-state source/normalized paths and technical sizes are committed in `design/05_levels/FORLORN_RITUALANT_HIGHLAND_STATION_ART_HANDOFF_MANIFEST.json` (planning manifest only). Raw generated or painted assets first enter source-work:

```text
custodian/asset_drop/source_work/ash_bell/<family-id>/<state-id>_source.png
```

After cropping and normalizing to the exact sheet geometry, approved RGBA states enter:

```text
custodian/asset_drop/inbox/<family-id>/<state-id>.png
```

Each registered family contract will live at `custodian/content/metadata/assets/families/<family-id>.asset.json` and declare appropriate `schema`, valid `kind`, `runtime`, `states`, scene `consumers` and per-state `layout`/frame fields **using current live schema**. Avoid direct writes to runtime paths or hand-authored canonical filename assumptions.

Relevant existing command front door from `custodian/tools/assets/asset.py` and pipeline docs:

```bash
python3 custodian/tools/assets/asset.py --help
python3 custodian/tools/assets/asset.py families
python3 custodian/tools/assets/asset.py plan <family-id>
python3 custodian/tools/assets/asset.py status <family-id>
python3 custodian/tools/assets/asset.py doctor
python3 custodian/tools/assets/asset.py needs --check
```

Validate actual CLI syntax before running ingest; an example documented for existing families is `python3 custodian/tools/assets/asset.py ingest <family-id> --yes --godot-import` **only after a dry-run plan, approval and correct source states**. Requirement statuses belong in `custodian/content/metadata/assets/required_assets.registry.json`; don't mark missing art complete until actual ingest/consumer proof. Do not overwrite/clone existing 37-state environment family by name.

### Source normalization and quality gates

- All static states: **1 frame**, exactly as specified, RGBA PNG where alpha is `true`. `mixed` means underlay portions may be opaque while exposed silhouette/edges require real alpha. Masks carry intentional alpha (no solid white plate).
- `receiver_seating_pulse`: exactly **1536×192 px**, 8 cells × 192×192, horizontal strip, 12 FPS, one-shot. Fixed registered center/pivot across frames; no variation in total canvas.
- Source_work master can be a larger layered working image, but never upscale low-resolution pixels with smoothing to achieve the normalized size. Preserve silhouette, intended world-scale and registration through nearest-neighbor/art-directed refinement.
- Transparent corners and anti-aliased fringe checks; no solid opaque fake checkerboard, black rectangular matte, stretched slices or frame-to-frame bounding-box drift.
- Optional human review uses compact crops for lift, empty-seat read, key/case pairing, chapel seam and a single before/after receiver-key scene. Do not screenshot the whole 3584×4096 map repeatedly.
- Exact scene consumer or atlas tiles plus runtime grid/camera/occlusion proof required for a state to count as production-integrated.

### Minimum objective validation

1. Assert family schema, state IDs, normalized dimensions, alpha and file hashes match actual accepted files.
2. Run family plan/status/doctor and `needs --check`; collect no false complete/pending claims.
3. Run current Ritualant environment assets smoke and targeted scene/build validations. Reuse `custodian/tools/validation/ritualant_underground_environment_assets_smoke.gd` and `custodian/tools/validation/forlorn_ritualant_completion_smoke.gd`; add specific receiver/gap/interpolation tests after implementation.
4. Check real camera-zone activation, background/occluder parallax and front-of-Operator layer correctness.
5. Verify key not inside chapel, key fits seat, storage/receiver match, art has no independent collision, all three endings keep valid screen presentation and persisted no-replay.
6. Prove source asset completeness through V2 registry, not manually asserted "37 + N = finished" arithmetic. Queue/CI checks follow `custodian/AGENTS.md`.

## 10. Production scheduling and explicit handoff gates

| Gate | Deliverable | Owner and decision | Blocking condition |
| --- | --- | --- | --- |
| A0 · Intake audit | Existing user-supplied Ritualant asset ZIP and current V2 catalog classified against H0/H1/H2/H3 | ChatGPT + user art decision | Source ZIP not yet inspected; no speculative duplicate art generation |
| A1 · Mapper blockout | 32px-grid route thumbnails, H1 foundation vs H2 intrusion placement and sightlines; no art generation | Godot/Codex level owner, human spatial approval | Prove key alcove, receiver, chapel and north throat physically fit |
| A2 · Design sheet | Machine anatomy, key/socket silhouettes and gallery/chapel seam paintover | Artist + user | Key and receiver must fit physically and read at native gameplay scale |
| A3 · Core source kit | Core states from infrastructure, receiver, chapel and targeted FX groups | Artist/asset generator | Source masters+normalized candidates with exact manifest and alpha |
| A4 · V2 ingest | Registered family contracts, standard intake, scene consumers and sprite/texture import | Codex/Asset V2 workstream | No direct asset drops, unverified file names or stale requirements |
| A5 · Visual integration | Native-scale before/after ROI, readability, z/occlusion and reduced-flicker behavior | User/ChatGPT visual approval | Subjective quality must be approved separately from passing schema |
| A6 · Gameplay proof | Detectability and key/socket spatial grammar; peaceful and hostile persistence and route restoration | Codex and fresh-context review | No false collision, replay, duplicate actions or route softlocks |
| A7 · Character follow-up | Dialogue ownership, free-roam choices, behavior graph, actor 128px source states and sparse echoes | Separate actor workstream | Do not re-author actor idle states blindly in this art pass |
| A8 · Audio follow-up | Foley/SFX scene cues, sound motif and licensed/approved high-quality TTS auditions for a voiced Ritualant | Later sound/voice workstream | Wait for dialogue, timings and on-screen actors to be locked |

**Gate A8 / voice note:** Select an AI voice/TTS system only after the final words, timing, actor motions and shot/presentation map are accepted. Require commercial game usage rights, stable character casting, consent or licensed synthetic voice, pronunciation guide, line IDs, per-line pickups, mono dry masters, consistent prosody and lip/jaw/gesture timing compatibility. Evaluate several high-quality engines/voices by human listening; **do not lock a vendor, voice clone or pronunciation style in this visual-art brief**.

## 11. Production risks and drift findings

- **Old item:** active runtime uses Stilling Pin in basin. The newly approved Receiver Key is not wired or in inventory.
- **Old chapel-only art plan:** detailed encounter spec still contains historical bell-component/pin semantics and placement; this future brief overrides *new artwork* only, not current runtime claims.
- **Historical Station IX:** wrong to transplant Station IX into the cavern; its actual level remains across generated Highlands/Bridged Falls route.
- **Existing resources:** 37 environment states and two hazard FX are already live; 12 reviewed rituals/dressing states are in another intake packet. Check whether that packet lands before commissioning replacements.
- **Actor state:** current enemy family and presentation builder own action strips; extra idles/echo actors require an explicitly reviewed action graph rather than art at random FPS.
- **South/north access:** `ritualant-north-egress-and-chapel-vista` remains a separate dependency-gated packet; a faded art seal is not route implementation.
- **Legacy nomenclature:** `lower_quarter_seal` is a current scene-node/asset name; do not rename it casually or treat that name as proof the Lower Quarter sits in the cave.
- **No broad retcon:** current design lock establishes station-original construction vs active continuity; the number I–VIII is reserved and the original Open Interval remains closed.

## 12. Final production acceptance rubric

The art pass is ready to close only if independent checks can answer **yes** to all:

1. The first 30–60 seconds visually indicate a human-built maintained installation in an actual mountain.
2. The route includes varied interactions/discoveries, not simply additional corridor length.
3. A player can point to a load-bearing original **Isolation Gallery**, not a freestanding fantasy altar.
4. The actual **Receiver Key** can be compared side-by-side with a socket and it is visibly the matching hardware.
5. The key is recovered outside the chapel; the machine is the key's receiving location, and the basin remains a distinct contradiction.
6. The chapel's construction is visibly inconsistent with the original station but retains enough recognizable material to be credible.
7. No art depicts the physical ninth bell or misidentifies Highland facility as Station IX.
8. Local double-vision feels like misregistered depth/geometry, not a global filter or optical nuisance; reduced-flicker mode works.
9. Ritualant/Operator, dialogue and combat telegraph legibility are preserved at real camera profiles.
10. Assets have true alpha where required, exact sheet/frame dimensions, correct input pipeline and tested scene consumer/pivot/occlusion.
11. Peaceful key turn visually changes mechanical state; alternate terminal outcomes do not falsely depict the same repair.
12. All relevant V2/catalog/required-assets statuses, current-state and implementation docs agree with **actual** live pixels/code; no false production-ready milestone.

**Next after this brief:** complete A0 inventory with the collected asset ZIP, then mapper-space A1/Gallery anatomy sketch before generating the first core source assets. After environmental visuals are signed off, audit/rebuild the Ritualant actor, dialogue, animations and ambient state machine. Only after that lock SFX, three music integrations and high-quality TTS voice performance.
