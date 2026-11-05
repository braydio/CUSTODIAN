# CUSTODIAN · Crèche Layered High-Fidelity PBR Art Manifest V2

**Status:** REPOSITORY DESIGN PROPOSAL ONLY. New families are **not** registered, images are **not** generated/approved, and no Godot scene was changed. This file is a human-facing mirror of the JSON.

**Authority inspected:** `braydio/CUSTODIAN@f42cc51cb5689d6b8ae596e489eb995ac9cde46f` · `awakening_layout.gd` · existing six Asset Pipeline V2 family schemas · approved Crèche clean-room design · interactible affordance contract.

## Visual quality lock

- **Target:** photoreal, high-fidelity **3D-modeled, physically based rendered 2.5D** presentation in the current Godot **Node2D** scene. NOT 32px pixel-art, painted maps, flat checker tiles, perspective-isometric camera shots, or a migration to 3D gameplay.
- **Projection:** one shared floor-perpendicular 90° orthographic camera, north up. Actual model heights, bevels, ironwork, recessed alcoves and physically plausible shadows provide depth; camera alignment matches all registered Sprite2D origins.
- **Materials:** scanned-quality chalk limestone, basalt, oxidized iron, ceramic, fatigued brass; restrained cold teal restricted to real devices. 32px architectural construction rhythm is a measurement system, not conspicuous 32px repeated linework.
- **Source-to-runtime:** offline PBR 3D render each frame at **4×** target resolution; preserve 3D master as preproduction evidence; normalize reviewed PNGs to exact existing family/state dimensions and process through Asset Pipeline V2. No silent stretching or source approval by existence.
- **Visual depth:** floor-only albedo separate from flush floor insets, wall relief, scenic objects, physical interactive console, local FX, foreground occlusion and screen-space HUD. Do not bake global lighting/vignette into L0.

## Spatial lock

| Contract | Exact live value |
|---|---|
| Registered room plate | 960×704, centered `(0,-32)` |
| World plate rect | `Rect2(-480,-384,960,704)` |
| Room envelope | `Rect2(-416,-320,832,576)` |
| Walkable floor | `Rect2(-352,-256,704,512)` |
| Wake / active alcove | `(0,160)` / `(0,208)` |
| Only live interactible | CrecheConsole `(112,144)`; body art `(105,118)` |
| Authority seal | `(0,-160)` |
| North door | `Rect2(-64,-320,128,64)` → Zone02 Ambulatory |
| Inactive alcoves | Four each side at x=±320, y=-192,-64,64,192 |
| Architectural grid | 32px authoring; not a visible checkerboard |

## Depth stack and character relationship

| Band | Source family role | Relationship to Operator |
|---|---|---|
| `D-1` | Beyond-room depth / inaccessible exterior | Always behind room; never collision/navigation |
| `D0` | Floor material and registered floor plate | Beneath Operator feet, fully traversable where map permits |
| `D1` | Flush floor inlays / scuffs | Below Operator; does not change route or collision |
| `D2` | Structural shell / wall relief | Behind player at wall base; no art-owned collision |
| `D3` | Physical scenic fixtures | Depth-sorted by mapped bases; existing blockers stay owned by Layout |
| `D4` | Gameplay prop body / animation | Scene-sorted with Operator; gameplay behavior owned by existing nodes |
| `D5` | Local light, screen, particles and interaction emphasis | Attached to prop/scene as bounded effects; no fake use targets |
| `D6` | Foreground occlusion | Over Operator where geometric foreground overlaps; opacity/occlusion mask tested |
| `HUD` | UI prompt and readout | Screen-space only; generated as native Godot UI, not image-baked text |

## Required artwork states

**22 required states:** 16 existing registered, 6 new proposed. Existing states are not automatically replaced. New states are not registered yet.

| ID | Depth | Exact frame × frames | Alpha | Decision |
|---|---|---|---|---|
| `awakening_creche_environment/underlay` | `D0` | 960×704 × 1 | RGBA | REAUTHOR_REQUIRED_ATOMIC_CUTOVER |
| `awakening_creche_environment/foreground` | `D6` | 960×704 × 1 | RGBA | PRESERVE_REVIEW_OCCLUSION |
| `awakening_creche_recovery_alcove/idle` | `D4` | 192×256 × 1 | RGBA | PRESERVE_UNLESS_QUALITY_OR_DEPTH_PARITY_FAILS |
| `awakening_creche_recovery_alcove/wake` | `D4` | 192×256 × 8 | RGBA | PRESERVE_UNLESS_QUALITY_OR_DEPTH_PARITY_FAILS |
| `awakening_creche_console/idle` | `D4` | 128×128 × 1 | RGBA | REVIEW_PROBABLE_PBR_REAUTHOR |
| `awakening_creche_console_activation_fx/activate` | `D5` | 128×128 × 8 | RGBA | RETAIN_REANCHOR_TO_MEASURED_SCREEN |
| `awakening_creche_fixtures/alcove_closed` | `D3` | 128×192 × 1 | RGBA | PRESERVE_UNLESS_VISUAL_PARITY_FAILS |
| `awakening_creche_fixtures/alcove_broken` | `D3` | 128×192 × 1 | RGBA | PRESERVE_UNLESS_VISUAL_PARITY_FAILS |
| `awakening_creche_fixtures/alcove_fused` | `D3` | 128×192 × 1 | RGBA | PRESERVE_UNLESS_VISUAL_PARITY_FAILS |
| `awakening_creche_fixtures/alcove_empty` | `D3` | 128×192 × 1 | RGBA | PRESERVE_UNLESS_VISUAL_PARITY_FAILS |
| `awakening_creche_fixtures/wall_of_seals` | `D3` | 256×192 × 1 | RGBA | REVIEW_FOR_PBR_REAUTHOR |
| `awakening_creche_fixtures/relic_table` | `D3` | 192×128 × 1 | RGBA | REVIEW_FOR_PBR_REAUTHOR |
| `awakening_creche_fixtures/authority_inscription` | `D2` | 384×96 × 1 | RGBA | REVIEW_FOR_PBR_REAUTHOR |
| `awakening_creche_perimeter_support/structural_support` | `D-1` | 512×512 × 1 | RGBA | PRESERVE_UNLESS_CAMERA_SEAM_FAILS |
| `awakening_creche_perimeter_support/distant_structures` | `D-1` | 1024×512 × 1 | RGBA | PRESERVE_UNLESS_CAMERA_SEAM_FAILS |
| `awakening_creche_perimeter_support/edge_transition` | `D-1` | 256×256 × 1 | RGBA | PRESERVE_UNLESS_CAMERA_SEAM_FAILS |
| `awakening_creche_floor_material/stone_base` | `D0` | 512×512 × 1 | RGB | CREATE_NEW_SOURCE_AND_REGISTER_AFTER_REVIEW |
| `awakening_creche_floor_insets/authority_floor_seal` | `D1` | 160×160 × 1 | RGBA | CREATE_NEW_SOURCE_AND_REGISTER_AFTER_REVIEW |
| `awakening_creche_floor_insets/central_service_aisle` | `D1` | 192×320 × 1 | RGBA | CREATE_NEW_SOURCE_AND_REGISTER_AFTER_REVIEW |
| `awakening_creche_floor_insets/north_threshold_wear` | `D1` | 128×64 × 1 | RGBA | CREATE_NEW_SOURCE_AND_REGISTER_AFTER_REVIEW |
| `awakening_creche_architecture/structural_shell` | `D2` | 960×704 × 1 | RGBA | CREATE_NEW_SOURCE_AND_REGISTER_AFTER_REVIEW |
| `awakening_creche_architecture/north_exit_frame` | `D2` | 192×128 × 1 | RGBA | CREATE_NEW_SOURCE_AND_REGISTER_AFTER_REVIEW |

## Optional polish (not automatic)

| ID | Frame × frames | Status |
|---|---|---|
| `awakening_creche_floor_material/quieter_variant` | 512×512 × 1 | PROPOSED_UNREGISTERED_STATE |
| `awakening_creche_floor_insets/wear_scuffs` | 128×128 × 1 | PROPOSED_UNREGISTERED_STATE |
| `awakening_creche_architecture/alcove_trim_variation` | 96×128 × 1 | PROPOSED_UNREGISTERED_STATE |
| `awakening_creche_ambient_fx/pressure_vent` | 128×128 × 8 | PROPOSED_UNREGISTERED_STATE |
| `awakening_creche_fixtures/collapsed_service_harness` | 128×128 × 1 | EXISTING_REGISTERED_OPTIONAL_STATE |
| `awakening_creche_fixtures/cracked_sidearm_holster` | 64×64 × 1 | EXISTING_REGISTERED_OPTIONAL_STATE |
| `awakening_creche_fixtures/petrified_bandage_spool` | 64×64 × 1 | EXISTING_REGISTERED_OPTIONAL_STATE |
| `awakening_creche_fixtures/maintenance_slate` | 96×64 × 1 | EXISTING_REGISTERED_OPTIONAL_STATE |

## Immediate regeneration priorities

1. `awakening_creche_environment/underlay`: **REAUTHOR_REQUIRED**. Existing monolithic/baked plate must be replaced as an atomic layer stack; true floor-only output must not contain console, structural wall relief or fixtures.
2. `awakening_creche_architecture/structural_shell`: **GENERATE_REQUIRED_NEW**. New 3D PBR architectural layer, not currently registered.
3. `awakening_creche_floor_material/stone_base`: **GENERATE_REQUIRED_NEW**. Realistic PBR material source; 512x512 repeat.
4. `awakening_creche_floor_insets/authority_floor_seal`: **GENERATE_REQUIRED_NEW**. Separate flush inlay, not baked onto room floor.
5. `awakening_creche_floor_insets/central_service_aisle`: **GENERATE_REQUIRED_NEW**. Controlled floor-level route reading, not baked into base.
6. `awakening_creche_floor_insets/north_threshold_wear`: **GENERATE_REQUIRED_NEW**. Precise open transition floor.
7. `awakening_creche_architecture/north_exit_frame`: **GENERATE_REQUIRED_NEW**. Isolated physical frame, cannot obstruct doorway.
8. `awakening_creche_console/idle`: **REVIEW_PROBABLE_REAUTHOR**. Must read as the single photoreal physical console, aligned with actual screen-local FX and clean room.
9. `awakening_creche_fixtures/wall_of_seals`: **REVIEW_REAUTHOR_IF_MISMATCH**. Prominent setpiece against new physically rendered wall relief.
10. `awakening_creche_fixtures/relic_table`: **REVIEW_REAUTHOR_IF_MISMATCH**. High-value foreground fixture; preserve placement and collision authority.
11. `awakening_creche_fixtures/authority_inscription`: **REVIEW_REAUTHOR_IF_MISMATCH**. Existing headwall inscription family already registered; do not add duplicate.
12. `awakening_creche_environment/foreground`: **RETAIN_REVIEW_OCCLUSION**. Keep unless opacity/overdraw fails with new shell; preserve registered 960x704 plate.
13. `awakening_creche_recovery_alcove/idle`: **RETAIN_REVIEW_PBR_CONSISTENCY**. Already separate prop family.
14. `awakening_creche_recovery_alcove/wake`: **RETAIN_REVIEW_SPRITESHEET**. Existing 8 frames 8fps; not a new interactible.
15. `awakening_creche_console_activation_fx/activate`: **RETAIN_VERIFY_SCREEN_ANCHOR**. Existing 8 frames 8fps screen effect; no new FX needed unless image fails.

## L0 authoring specifications (create next only after human signoff)

### `awakening_creche_floor_material/stone_base`

- **Normalized:** 512×512, 1 frame; OPAQUE_RGB_SEAMLESS.
- **4× render master per frame:** 2048×2048. Only normalized PNG is Asset V2 input.
- **Repo source:** `custodian/asset_drop/source_work/awakening/awakening_creche_floor_material/stone_base_source.png`
- **Repo inbox:** `custodian/asset_drop/inbox/awakening_creche_floor_material/stone_base.png`
- **Family schema:** `custodian/content/metadata/assets/families/awakening_creche_floor_material.asset.json` (registered state if existing; proposed if new)
- **Role:** Naturalistic source material only; repeated and masked to authorized floor by renderer. No designed room plan, alcove, seal, border, light pool or path.
- **Generation/rendering brief:** Physical PBR scan-quality institutional chalk-limestone and graphite basalt civic paving; micro-chipped seams, mineral salts, powder ash, extremely subtle wax residue; realistic roughness/normal breakup; continuous 32px architectural module (not a printed 32px grid). Strict perpendicular 90-degree overhead orthographic floor capture, north up, evenly lit albedo-leaning neutral exposure. Tile repeats without edge seam, dominant emblems, or obvious repeated cracks. No object, architectural baseboard, puddle, shaft, gradient/vignette or baked directional shadow.

### `awakening_creche_environment/underlay`

- **Normalized:** 960×704, 1 frame; ROOM_PLATE_RGBA_OUTSIDE_FLOOR__OPAQUE_ON_FLOOR.
- **4× render master per frame:** 3840×2816. Only normalized PNG is Asset V2 input.
- **Repo source:** `custodian/asset_drop/source_work/awakening/awakening_creche_environment/underlay_source.png`
- **Repo inbox:** `custodian/asset_drop/inbox/awakening_creche_environment/underlay.png`
- **Family schema:** `custodian/content/metadata/assets/families/awakening_creche_environment.asset.json` (registered state if existing; proposed if new)
- **Role:** Exact registered 960x704 floor-only composite (L0); keep all machines/arch/wall relief off this layer; optional alpha outside actual exposed floor. Do not treat the old room plate as a clean L0 source.

### Why L0 is not a fully opaque 960×704 rectangle

An **opaque RGB material** can be sampled/repeated under the existing floor geometry, but the **registered room plate** must have genuine transparency outside exposed floor if used as floor-only art. A 960×704 opaque bitmap would paint unwalkable void and swallow the surrounding shell/foreground. The old underlay remains in runtime until an **atomic reviewed cutover** to new floor/shell/prop layers is complete.

## Interaction and UI (no new gameplay)

Crèche Console is the only live room interactible. The active recovery alcove is cinematic, the eight inactive alcoves and nearby details are scenic. Use the existing `AffordancePresentation`, `CustodianHUD` and `BlackReliquaryPrompt`: world physical clue → bounded focus only for actual target → proximity action glyph → 8f/8fps console screen-local activation → quieter acknowledged state. Never bake text or a faux `E` prompt into a PNG. Do not create a new interaction detector/controller.

## Production sequence and quality gates

- P0 freeze scene snapshot and extract current 960x704 room and 128px Operator composition; inspect actual art source bytes, including alpha; preserve old runtime until cutover.
- P1 generate/review PBR 512x512 stone material and floor-only 960x704 composited underlay with transparent outside exposed floor and unchanged origin.
- P2 generate/review L1 insets (floor seal, aisle, north threshold) independently as true RGBA.
- P3 generate/review L2 structural shell and north exit frame, with exact occlusion and existing eight inactive alcove sockets.
- P4 compare fixtures/recovery/console with new 3D-rendered style; selectively reauthor only failed states; measure screen-local FX anchor.
- P5 review all candidate images at native resolution, actual 2.25x camera setting, 128px Operator context, no hidden underlay machine; obtain per-image human source approvals.
- P6 register new Asset V2 families and required-assets registry, stage immutable source masters, normalize/ingest through the existing tools; atomically bind reviewed layers; keep one visible console.
- P7 run focused Godot layout/route/interactible/FX/alpha/occlusion and source receipt tests, verify both entry/exit and live 8f screen event; update current-state documentation.

**Failure conditions:** wrong projection or visual scale; obviously repeated seams; photographic backdrop flattened as floor; baked fixtures/console in underlay; alpha matte/checkerboard; off-route artwork implying collision; fake interactive signals; missing current source approval; 8f screen animation rendered on floor; floor occlusion duplicated in foreground; changing the 128px north exit or camera/origin.

**Drift to resolve:** older Crèche plan incorrectly allowed a 960×704 opaque full floor rectangle and mixed the floor, structural shell and console into a single underlay. `AWAKENING_INTERACTIBLE_CLEAN_ROOM_PLATES_V1.md` already calls for removing embedded interactibles. This manifest extends that into full floor/shell/inset decomposition without changing the currently registered family schema or gameplay. Existing global 198-art roadmap counts must not silently incorporate new Crèche families.

**Not performed:** source art regeneration, new Asset V2 family registration, runtime binding, user approval, host Godot scene tests, or production source handoff.
