# CODEX BRIEF — Lower Quarter Gothic Sci-Fi Art Integration V1

Repo:
`/home/braydenchaffee/Projects/CUSTODIAN`

Mode:
**APPLY**

## Read first

- `AGENTS.md`
- `design/05_levels/ASH_BELL_LOWER_QUARTER.md`
- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/FILE_INDEX.md`
- `custodian/game/world/levels/authored/ash_bell/lower_quarter/lower_quarter.tscn`
- `custodian/game/world/levels/authored/ash_bell/common/lower_quarter_native_prop_layer_2d.gd`
- `custodian/game/world/levels/authored/ash_bell/common/ash_bell_catastrophe_prop_layer_2d.gd`
- `custodian/game/world/levels/presentation/semantic_native_prop_2d.gd`
- `custodian/game/world/levels/authored/ash_bell/common/meridian_civic_art_presenter.gd`
- `custodian/content/metadata/assets/meridian_civic_wall.semantic.json`
- `custodian/docs/ai_context/task_packets/ASH_BELL_WALL_COMPOSITION_FIRST_PASS.md`
- `custodian/docs/ai_context/task_packets/ASH_BELL_CATASTROPHE_DRESSING.md`

## Art-direction authority

Lower Quarter base architecture is:

**distant-future Meridian civic infrastructure with Gothic/Yharnam-like massing and ornament, fused to industrial/containment technology and apocalyptic sci-fi decay.**

Gothic architecture is allowed and wanted:
- pointed/lancet silhouettes
- strong vertical piers
- wrought-iron language
- spires/finials in moderation
- monumental old-city facade rhythms

Do not confuse Gothic architecture with later religion. Explicit shrines, saints,
altars, devotional icons and Pale-Bell ritual additions remain separate later
history layers.

## Inputs

Install exact source masters:

`custodian/asset_drop/source_work/lower_quarter_region/lower_quarter_gothic_scifi_walls__master__1448x1086.png`
- 1448x1086 RGBA
- 1 frame
- source/master only

`custodian/asset_drop/source_work/lower_quarter_region/lower_quarter_gothic_scifi_props__master__1448x1086.png`
- 1448x1086 RGBA
- 1 frame
- source/master only

Install reviewed source manifests:

`custodian/content/metadata/assets/lower_quarter_gothic_scifi_walls.source_review.json`
- 97 detected modules
- 75 generic-production
- 22 explicit-only damage/hero modules

`custodian/content/metadata/assets/lower_quarter_gothic_scifi_props.source_review.json`
- 73 detected modules
- 56 generic-production
- 15 explicit-only authored set pieces
- 2 detail-only micro-debris entries, not promoted in V1

Install builder:

`custodian/tools/art/build_lower_quarter_gothic_scifi_runtime.py`

Run:

```bash
cd /home/braydenchaffee/Projects/CUSTODIAN
python3 custodian/tools/art/build_lower_quarter_gothic_scifi_runtime.py
```

The builder MUST preserve:
- one global 0.5 source scale for both sheets
- no per-asset autofit
- source relative size relationships
- binary alpha
- one shared source-sheet palette per sheet
- no runtime collision generation

## Critical implementation decision

DO NOT force the 97 generated wall components into the existing 14x14 / 32px
`meridian_civic_wall_atlas_512.png`.

Inspection of the real source sheet shows that these are intentionally multi-cell
facades, piers, corners, arches, caps and collapse pieces. Flattening every one
into one 32x32 cell would destroy the approved design.

Keep the existing 32px wall atlas and its reviewed topology as the low-level
structural substrate. Add a deterministic authored native structural presentation
layer over it for Lower Quarter only.

## New wall module runtime

Create:

`custodian/game/world/levels/authored/ash_bell/common/lower_quarter_native_wall_module_layer_2d.gd`

Responsibilities:
1. read an exact authored placement JSON
2. resolve variants through `SemanticNativeProp2D` using
   `lower_quarter_gothic_scifi_walls_native.semantic.json`
3. accept only entries with production_status `generic` for generic placements
4. allow `explicit_only` entries only when a placement names the exact variant
5. scale must always be `Vector2.ONE`
6. never rotate/mirror
7. no collision
8. no alpha-derived topology
9. existing `MeridianCivicArtPresenter`, collision, navigation and wall masses remain authority

Scene:

```text
BackgroundRoot
  MeridianCivicArtPresenter        # existing 32px substrate
  GothicSciFiWallModuleRoot        # new native structural overlay
```

`GothicSciFiWallModuleRoot` must be below physical/y-sorted props but above the
generic floor substrate.

## First authored wall overlay pass

Create:

`custodian/game/world/levels/authored/ash_bell/common/lower_quarter_gothic_scifi_wall_placements.json`

Do NOT attempt to cover every wall cell.

Use native hero modules only at:
- Entry Forecourt framing
- Direct Personnel collapse flanks
- Evacuation Arcade facade
- Lower Market civic edge
- Civic Basin formal edge
- Eight Answers Court
- Station IX approach

The existing 32px wall substrate remains visible between hero modules.

For V1:
- use generic facade/pier/corner/opening/cap variants for intact runs
- use explicit-only damage/collapse variants only at the Direct Personnel collapse
  and already-authored damaged edges
- never place damage on route-critical visual continuity merely for variety
- black/red closure banners are containment-response history, not Penitent material

## Props integration

Do not delete the existing civic/catastrophe placement authorities in the same
commit. Replace high-signal props first while preserving their exact anchors.

Generalize both existing native-prop layers to allow manifest/root overrides.

Lower Quarter theme replacements should prioritize:
- civic lighting -> new Gothic civic lights
- benches -> Gothic civic bench
- bollards -> new civic bollards
- information/sign terminals -> new terminals/information column/warning sign
- railings/barriers -> Gothic fence / containment barrier
- emergency lighting -> floodlights
- utility cabinets -> new utility cabinets
- floor hardware -> new floor grates
- direct-collapse debris -> new structural debris
- containment-response areas -> generator, containment canisters, screens
- West-gate/evacuation vocabulary -> closure banners and barriers

Do not globally substitute every old placement merely because a new asset exists.
Unmatched old placements remain until a gameplay-scale art review approves their
replacement.

All replacement anchors remain exactly where the current placement authority puts
them in V1. Do not move collision or navigation.

## Recommended first replacement IDs

Use the existing placement coordinates but swap visual variants for these roles:

- arrival_w_lamp / arrival_e_lamp -> `lower_quarter_civic_lighting`
- arrival_w_bench / arrival_e_bench -> `lower_quarter_bench`
- personnel_sign -> `lower_quarter_warning_sign`
- arrival_directory -> `lower_quarter_terminal`
- arrival_bin -> `lower_quarter_waste_bin`
- arrival_bollard_w / arrival_bollard_e -> `lower_quarter_bollard`
- arrival_railing / arrival_chain_railing -> `lower_quarter_gothic_fence`
- arrival_beacon -> `lower_quarter_emergency_floodlight`

Direct Personnel / evacuation replacements:
- concrete/crowd barriers -> `lower_quarter_containment_barrier`
- emergency/service lights -> `lower_quarter_emergency_floodlight`
- damaged utility -> `lower_quarter_destroyed_terminal`
- floor grille/hatch -> `lower_quarter_floor_hardware`
- structural rubble -> `lower_quarter_structural_debris`
- emergency power -> `lower_quarter_generator`
- screening/containment hardware -> `lower_quarter_containment_canister`
- abandoned utilities -> `lower_quarter_utility_cabinet`

Use deterministic variant selection in the checked-in migration script, then write
the selected exact `variant_key` into placement JSON. Do not select variants
randomly at runtime.

## Validation

Add:
`custodian/tools/validation/lower_quarter_gothic_scifi_art_smoke.gd`

Assert:
- wall source review contains exactly 97 entries
- 75 generic + 22 explicit-only wall entries
- prop source review contains exactly 73 entries
- 56 generic + 15 explicit-only + 2 detail-only prop entries
- runtime-scale metadata is exactly 0.5 for all promoted entries
- no promoted texture is scaled by Sprite2D
- binary alpha is present
- every runtime texture exists
- no runtime rotation/mirroring
- wall overlay owns no collision
- prop replacements own no collision
- old authored collision/navigation hashes or structural snapshots are unchanged
- existing 32px wall topology catalog remains loaded and valid
- Lower Quarter scene mounts `GothicSciFiWallModuleRoot`
- Station IX and West Gate Works do not mount this Lower-Quarter-only layer

Run existing regressions:
- `lower_quarter_native_prop_placement_smoke.gd`
- `ash_bell_lower_quarter_art_integration_smoke.gd`
- wall semantic/catalog smokes
- authored route/nav smokes

Capture gameplay-scale screenshots:
1. Arrival
2. Direct Personnel collapse
3. Evacuation Arcade
4. Lower Market
5. Civic Basin
6. Wrong Street
7. Eight Answers Court
8. Station approach

## Documentation drift

`ASH_BELL_WALL_COMPOSITION_FIRST_PASS.md` and
`ASH_BELL_CATASTROPHE_DRESSING.md` are mechanically complete but their prior
Lower Quarter visual vocabulary is superseded by this art-direction pass.

Preserve them as implementation history and append a supersession note.

Update before/with runtime implementation:
- `design/05_levels/ASH_BELL_LOWER_QUARTER.md`
- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/FILE_INDEX.md`

Do not describe the new look as "non-Gothic". The intended distinction is:
**Gothic-futurist Meridian architecture vs. later explicit Penitent religion.**
