# Sundered Keep Vista Approach

> **Production clarification (2026-07-30):** this is a reference/debug
> composition and collision-authoring artifact, not production playable-world
> authority. The production approach is specified by
> `design/05_levels/SUNDERED_KEEP_PROCGEN_FRONTAGE.md`; procgen owns all
> frontage floor, terrain, collision, side paths, and traversal.

- **Status:** superseded / debug-only under `legacy_vista_debug`
- **Owner:** authored level / rendering / camera
- **Runtime:** `custodian/` Godot 4.x
- **Production runtime scene:** `custodian/game/world/approaches/sundered_keep/sundered_keep_approach.tscn`

## Superseded Production Role

The production landmark reveal now lives in the generated world. See
`design/05_levels/SUNDERED_KEEP_WORLD_VISTA.md`.

This authored approach remains loadable for focused visual experiments and
historical validation only. It must not be restored to the production ingress
without explicit design review.

## Summary

A playable first Sundered Keep slice built from the former approach scene. The player enters from mainland top-down on one authored route-master terrain sprite under a tight gameplay camera. Camera 1 is a reversible influence corridor evaluated from the Operator's physical position: it blends toward the first cinematic anchor, holds that composition across an authored route interval, and blends back to traversal framing without trigger order, timers, or completion state. The later Labyrinth section uses layered panorama/fog/parapet parallax, local depth lighting, and independently fading route-master roof crops before the route continues directly to the approved large Front Gate map.

**Hard constraint:** Art alpha still does not own collision. The production runtime scene uses fitted `Sprite2D` matte/terrain assets, a single perimeter-rail `StaticBody2D` made from mapper-authored thick `CapsuleShape2D` rails, and explicit `AUTHORING_MARKERS` for gameplay/event semantics. `GrandVistaRoot` is presentation-only and must not become collision, navigation, enemy AI, or sim authority. Filled path-shaped `CollisionPolygon2D` solids are not valid walkable-boundary collision because they block the path itself. Sprite2D assets are fit to their target `Rect2`; the rect is runtime layout authority. Playable terrain art must keep transparent pixels outside the authored terrain shape unless the full rectangle is intentionally terrain.

## Runtime Ingress Chain

The retained `legacy_vista_debug` profile uses:

```
@world_origin
  -> vista_approach
  -> front_gate
```

Production bypasses this node and enters Front Gate directly. `RouteTraversalManager`
and `LevelLoader` stage this scene only for `legacy_vista_debug`. The unfinished
Return Causeway remains registered only for the isolated `causeway_only` debug
profile and must not be promoted without explicit user review.

`WorldIngressSite` captures every direct child of `World` assigned to `world_origin_branch`, then hides and processing-disables the captured branches for the full route session. The Operator, Camera2D, shared lighting, LevelLoader, and RouteTraversalManager remain persistent. Node-to-node traversal never restores origin content; exact captured branch visibility and process modes are restored only during route exfil to `@world_origin`.

`SunderedKeepApproach` owns Vista presentation only: it selects `vista_approach` UI mode and suppresses Operator world-space health/target presentation while active. It does not capture, disable, or restore base-world branches. A failed ingress transaction restores the captured origin snapshot before the route is allowed to retry.

Ingress transitions must be deferred out of `Area2D.body_entered` physics callbacks before instancing this scene. The approach also defers its dynamic `StaticBody2D` boundary rails and final exit `Area2D` setup by one frame so Godot does not register or toggle physics shapes while flushing queries.

## Collision Mapping Debug Scene

The former Keep-specific approach collision mapper has been retired. The old
approach is a reference/debug composition artifact and is not an independently
authored production level. Use the generic `level_collision_poi_mapper.tscn`
only for historical inspection. All production Front Gate authoring routes
through `sundered_keep_mapper.tscn`.
- `WASD` / arrow keys: pan.
- Mouse wheel / `+` / `-`: zoom around the cursor.
- `L`: focus the final horizontal traverse.
- `E`: toggle existing collision rails.
- `V`: toggle draft lines.
- `R`: reset draft points.

The mapper prints both runtime coordinates and source coordinates. Paste the source coordinates into `BOUNDARY_SEGMENTS`; runtime lowering from `ROUTE_VERTICAL_OFFSET` is applied by the approach script. The runtime also preserves the current captured point stream by flattening the pasted entries and building rails between every consecutive point.

The same mapper now has marker mode for route and presentation authoring:

- `M`: toggle collision/marker mode.
- Marker mode exposes `spawn`, `return_causeway`, `level_exit`, the four Camera 1
  envelope points, the second-reveal trigger center, and both cinematic anchors.
- Left click in marker mode: place the selected marker.
- Right click in marker mode: clear the selected marker.
- `C`: copy the full `AUTHORING_MARKERS` block.
- `Enter` / `U`: apply marker positions back to `sundered_keep_approach.gd`.

`AUTHORING_MARKERS` is the stable authoring contract for Vista reference points. Keep key, gate, encounter, and siege markers belong to the Sundered Keep map, not this presentation route. The runtime endpoint is positioned by `LEVEL_EXIT_POS`; its authored `continue` exit resolves directly to Front Gate in production.

For Camera 1 tuning, place `FirstCameraControlStart`,
`RevealControlStart` (the apex), `RevealControlEnd` (return start), and
`FirstCameraReturnComplete` on the walkable route. These are `Marker2D` control
points, not `Area2D` triggers. Place `FirstRevealCameraAnchor` on the
composition's focal center. Zoom and offset remain code-owned. Do not add an
extra second camera anchor. The existing `SecondVistaFull` and `SecondVistaEnd`
markers own the second reveal's progress-controlled handback.

## Scene Architecture

```
SunderedKeepApproach
├── ParallaxRoot          z=0     — shared painterly BaseDepth/RevealDepth/ForegroundDepth rig
├── UnderlayRoot          z=-300  — ocean void, cliff spires, route contact shadow
├── GrandVistaRoot        z=-220  — always-visible presentation container
│   ├── GrandVistaCinematicRoot   — second-beat panorama/fog/spray/parapet
│   └── FortressVistaRoot         — persistent northeast modular fortress
├── VistaRoot             z=-200  — first-vista horizon and fog veil
├── PlayableRoot          z=0     — one active ApproachRouteMaster terrain sprite
├── OcclusionRoot         z=100   — edge mist, fog strips, final gate shadow veil
├── RoofOcclusionRoot     z=90    — route-master roof crops and player-only fade zones
├── Collision             — PathBoundaryCollision thick CapsuleShape2D rails
├── Markers               — route markers, Camera 1 envelope points, and cinematic anchors
├── SequenceTriggers      — second-reveal and second-handback triggers only
├── EventMarkers          — retained Vista reference markers for spawn and Return Causeway
├── EventRuntime          — authored route-exit affordances bound by RouteTraversalManager
├── VistaController       — drives vista, grand vista, fog, occlusion, and distant keep alpha
├── RevealDirector        — optional one-shot Camera 1/2 prompt, signal, and near-fog accents
```

### Z-order

| Root | z_index | Notes |
|------|---------|-------|
| ParallaxRoot | 0 | Presentation-only shared depth rig; child `Parallax2D` layers use absolute z ordering |
| UnderlayRoot | -300 | Behind everything |
| GrandVistaRoot | -220 | Visual-only container fixed at alpha 1; its cinematic and fortress children own independent alpha |
| VistaRoot | -200 | First vista horizon/fog veil |
| PlayableRoot | 0 | Route-master walkable terrain art |
| OcclusionRoot | 100 | Edge mist, fog strips, and final gate veil |
| Collision/VistaController/EventMarkers/EventRuntime | — | Collision/event authority, no visual root concern |

The production runtime script self-heals these visual roots with `z_as_relative=false` so draw order does not depend on scene-tree insertion or inherited z values. The blockout scene remains reference/dev-only.

`UnderlayRoot/BackdropVoidFill` is the bottom safety plate. Its coverage is `RECT_CAMERA_BOUNDS.grow(768)` and its z-index is below every fitted underlay sprite. `RECT_APPROACH_UNDERLAY` also includes camera-framing slack. The safety plate owns no collision or simulation semantics; it exists solely to ensure camera zoom/framing can never expose the engine clear color.

### Camera states & markers

Camera 1 and Camera 2 are driven entirely by the Operator's position against
their `Marker2D` control points. Camera 2's trigger is retained only for
one-shot prompt, signal, sound, or near-fog accents; it has no framing authority.
Approach flows **north (decreasing Y)** then **east (increasing X)**.

| State | Camera offset/zoom | Vista alpha | Occlusion alpha | Trigger marker |
|---|---|---|---|---|
| 1 — Entry Route | intro offset `(0,-18)`, zoom `1.12` | 0.0 | Edge mist visible, final veil hidden | Player starts at EntrySpawn |
| 2 — Camera 1 Enter | gameplay → anchor offset `(0,0)`, zoom `0.84` | 0→1 from enter weight | Cinematic treatment follows camera weight | `FirstCameraControlStart → RevealControlStart` |
| 3 — Camera 1 Apex | anchor offset `(0,0)`, zoom `0.84` | 1.0 | Full first composition | `RevealControlStart → RevealControlEnd` |
| 3b — Camera 1 Return | reveal → traverse offset `(0,-48)`, zoom `0.98` | 1.0 | Cinematic treatment reverses | `RevealControlEnd → FirstCameraReturnComplete` |
| 4 — Labyrinth Vista | gameplay → anchor offset `(150,-115)`, zoom `0.98→0.78` | 1.0 | Cinematic atmosphere and modular fortress blend in; local roofs fade | `SecondVistaStart → SecondVistaFull` |
| 4b — Fortress Traverse | anchor → gameplay offset `(150,-115)→(0,-48)`, zoom `0.78→0.98` | 1.0 | Cinematic layers fade; fortress planes recede independently | `SecondVistaFull → SecondVistaEnd` |
| 5 — Final Gate Veil | normal_offset, normal_zoom | 1.0 | Final gate shadow veil fades in | Player passes SecondVistaEnd toward ReturnTopdown |

These values are live camera targets. `SunderedKeepVistaController` interpolates
them and sends a reversible presentation-framing override to the shared
`CameraController`. Every runtime-map binding clears any previous level's
presentation mode, restores Operator follow, and resets transient camera offsets
before the incoming level establishes its own presentation.

Camera 1 independently projects the Operator onto
`FirstCameraControlStart → RevealControlStart` and
`RevealControlEnd → FirstCameraReturnComplete`. Both progress values use
smootherstep easing; `camera_weight = enter_weight * (1 - return_weight)`.
Every frame, `CameraPresentationAnchor` is the Operator position lerped toward
`FirstRevealCameraAnchor` by that weight. The shared Camera2D follows this
presentation anchor throughout the level, so weight zero tracks the Operator
exactly and no follow-target switch occurs at an envelope boundary. Entry-tight
and traverse gameplay targets are themselves blended from return weight before
the cinematic influence is applied. Camera 1 is an occlusion-removal reveal,
not a background crossfade: `UnderlayRoot/FirstVistaBaseStormHorizon`,
`ApproachOceanVoidUnderlay`, `ParallaxRoot/BaseDepth`, and the playable route
remain at alpha `1.0`. Only the isolated distant Keep, the first-vista reveal
veil, and the moonlight separation cue respond to `enter_weight`.

The Keep uses a delayed smootherstep window from `0.12–0.82`, moving from
`0.08` concealed alpha to `0.92` at the apex. The reveal veil uses
`0.05–0.90`, peeling from `0.68` to `0.24` while moving only
`Vector2(-110, 50)` (about 121 pixels). Return weight settles the Keep at
`0.82`, the veil at `0.32`, and the veil offset at `Vector2(-90, 42)`.
Reverse travel before the apex restores the concealed state positionally.
The moonlight cue peaks at `0.20`; it is a separation accent rather than a new
moon/sky composition. Grand Vista, close fortress planes, foreground ruins,
and the final-gate veil remain hidden throughout Camera 1.

`SunderedKeepRevealDirector` may threshold-detect Camera 1 once for destination
prompt timing and reveal signals, but it does not own Camera 1 position, zoom,
follow target, movement restraint, presentation alpha, fog movement, or
moonlight energy. Respawn, teleport, route restoration, and reverse travel
immediately reevaluate the same envelope from the Operator's actual position.

Camera 2 independently projects the Operator onto
`SecondVistaStart → SecondVistaFull` for entry and
`SecondVistaFull → SecondVistaEnd` for return. Both use smootherstep easing and
`camera_weight = enter_weight * (1 - return_weight)`. Every frame,
`CameraPresentationAnchor` lerps from the Operator to
`SecondVistaCameraAnchor` by that physical weight, while offset and zoom lerp
from gameplay framing to `(150,-115)` / `0.78`. Forward travel, reverse travel,
spawn restoration, and teleporting therefore reconstruct the same framing
immediately. `SecondVistaRevealTrigger` and `SecondReturnToGameplayTrigger`
remain event-bookkeeping hooks only: the reveal director may emit signals and
briefly accent near fog, but cannot restrain movement or change camera position,
zoom, presentation anchor, or fortress alpha. Direct Operator follow resumes
only when the map is deactivated.

In debug-UI builds, `VistaDebugProbe` draws Camera 1 marker/anchor swatches and
Camera 2 trigger rectangles, plus a route guide and derived phase banner. The
detailed readout reports enter/return progress and weights, camera weight,
presentation-anchor position, route/profile/node identity, follow ownership,
handoff status, zoom, and presentation alphas.

The temporary `FarKeepSilhouetteLayerA/B` copies and baked
`ApproachFirstVistaHorizon` wallpaper are not active. The opaque
`first_vista_base_storm_horizon.png` contains storm sky and ocean only and
remains under `UnderlayRoot`. The alpha-valid
`distant_sundered_keep_landmark_v2.png` under `ParallaxRoot/RevealDepth`
contains only the Keep and low island silhouette. The separate
`first_vista_reveal_veil.png` owns the directional fog peel. This prevents
Camera 1 from introducing a new moon, skyline, ocean, or contrast composition.

The endpoint remains an `Area2D`, but it is a narrow walkable threshold under
`EventRuntime/LevelExitAffordance`, displays the `ENTER SUNDERED KEEP` destination
prompt, accepts automatic crossing only from the authored approach side, raises
the final veil, and requests the route-owned `continue` handoff. Production uses
the route's `fade` transition style: the route manager fades fully to black,
clears Vista presentation framing, activates Front Gate at `EntrySpawn`,
rebinds and snaps the shared camera while obscured, then fades back in. The
`debug_direct_keep` profile remains the only Vista exit that intentionally skips
Front Gate. Its `backtrack` edge returns directly to Vista `ReturnTopdown`.

**Marker positions** (from builder):

| Marker | Position |
|--------|----------|
| EntrySpawn | `(45, 430)` |
| RevealStart | `(-40, 120)` |
| RevealFull | `(-150, -175)` |
| MidGameplayStart | `(50, -235)` |
| SecondVistaStart | `(300, -305)` |
| SecondVistaFull | `(590, -305)` |
| SecondVistaEnd | `(830, -305)` |
| TraverseEnd | `(915, -305)` |
| ReturnTopdown | `(980, -305)` |

All transitions use `lerp` with `smoothing_speed=5.0`. Fog band starts at `alpha=0.35`.

## Existing Background Assets

The following shared painterly matte/background assets live in role folders
under `res://content/backgrounds/sundered_keep/shared/`. They are wide single
images (not split L/R pairs). Use linear filtering (not nearest-neighbor) on
import.

| Relative path | Size | Scene role |
|------|------|------------|
| `underlay/ocean_underlay.png` | 2100×1400 | UnderlayRoot — deep ocean below everything |
| `underlay/cliff_depth_underlay.png` | 520×540 | UnderlayRoot — dark cliff mass |
| `horizon/horizon_sky.png` | 2100×380 | VistaRoot — night/void sky |
| `horizon/horizon_sky_02.png` | 2100×380 | VistaRoot — sky variant |
| `horizon/far_sea.png` | 2100×260 | VistaRoot — dark sea band on horizon |
| `horizon/far_sea_02.png` | 2100×260 | VistaRoot — sea variant |
| `landmarks/distant_sundered_keep.png` | 540×250 | Legacy broad distant composition retained for non-Vista compatibility |
| `landmarks/distant_sundered_keep_landmark_v2.png` | 1840×854 | Alpha-valid Camera 1 Keep/island landmark only |
| `horizon/vista_fog_band.png` | 2100×160 | VistaRoot/VistaFogBand — seam-hiding fog |
| `landmarks/keep_horizon_wide.png` | 1689×787 | Reserve — wider keep matte if needed |

These live under `content/`, not `assets/`. See the local background README
before adding or moving plates.

## Shared Painterly Parallax Depth

Vista Approach and Return Causeway both build the presentation-only
`SunderedKeepParallaxRig`, but its supplementary painterly plates are review-gated
off by default. The current source revisions contain baked checkerboard, mismatched
mist halves, or compositionally unsafe foreground coverage. Until corrected plates
pass the alpha/source-revision validator and visual review, Vista uses the
persistent base storm horizon plus isolated Keep and reveal veil as first-vista
authority. Return Causeway preserves only
`BaseDepth/DistantKeep_Parallax2D/DistantSunderedKeepLandmark` for compatibility.

| Layer | Vista scroll scale | Review state |
|---|---:|---|
| `BackdropVoid` / `StormOceanBackdrop` | ordinary world presentation | active opaque safety fill |
| Distant Keep | `(0.12, 0.06)` on Vista; `(0.18, 0.12)` on Return Causeway | active |
| Far cliff islands | `(0.08, 0.04)` | disabled pending clean alpha |
| Causeway far arches | `(0.14, 0.07)` | disabled pending clean alpha and composition review |
| Lower cliff depth | `(0.24, 0.13)` | disabled pending clean alpha |
| Ocean mist | `(0.42, 0.24)` | disabled pending a coherent clean split pair |
| Playable terrain | ordinary world transform | active; never parented to `ParallaxRoot` |
| Foreground ruined arch | `(1.04, 1.02)` | disabled; alpha remains `0.0` |
| Near edge mist | `(0.82, 0.72)` | disabled pending clean alpha |

The layer gates are exported on both `SunderedKeepApproach` and the shared rig.
Disabled layers are not constructed and their textures are not loaded. When a layer
is approved, ocean/near mist remain separate left/right runtime sprites with a
96-pixel overlap; they are not stitched offline. Bounded `scroll_offset`, disabled
repetition, explicit linear filtering, and the presentation-only node contract remain
mandatory.

Required plates live under
`res://content/backgrounds/sundered_keep/approach/parallax/`. If edited in Aseprite,
their source files belong under
`custodian/content/_aseprite/backgrounds/sundered_keep/approach/parallax/`; generated
PNG plates do not require artificial Aseprite source files.

## Grand Vista Presentation Beat

`GrandVistaRoot` is an always-visible presentation container in the production
approach scene. `GrandVistaCinematicRoot` owns the temporary panorama, fog,
spray, vignette, and glue overlays. `FortressVistaRoot` owns a
deterministic 30-piece fortress kit anchored at source-space `(-360,-1280)` near
the northeast route, shifted 70 px east, and scaled to `0.82` (about 93% of the
previous composition). All pieces are instantiated at level
build time, but the primary composition enables only 17 connected, supported
pieces; unattached crowns, unconnected bridges/causeways, and redundant masses
remain loaded and hidden for later visual review. Neither child defines terrain,
collision, navigation, encounters, or exit logic.

The 17-piece shot is organized into a western collapsed ward, central round
citadel, eastern gate ward, and softened remote inner keep. Existing bridge,
causeway, wall, and broken-arch pieces form three implied labyrinth routes: an
upper walk that disappears behind the citadel, a middle approach entering a dark
central opening, and a lower route descending into fog. Pieces overlap their
supporting masses so no visible route terminates at a transparent asset edge.

The approach also applies `res://game/world/approaches/sundered_keep/soft_rect_feather.gdshader` to horizon, sea, fog, distant-keep, cliff-depth, and grand-vista plates so fitted matte rectangles feather at their UV edges instead of reading as hard cards. Low-opacity `Polygon2D` grounding shadows sit under the walkable chunks to tie the path art into the void/ocean composition; these are visual-only and are not collision authority.

| Sprite name | Asset path | Rect | z_index | Tint |
|---|---|---|---|---|
| GrandVistaPanorama | `res://content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_panorama.png` | `Rect2(-1280, -920, 2560, 1440)` | 0 | feathered, alpha 0.22 when all 30 fortress parts load; 0.88 fallback |
| GrandVistaOceanSprayOverlay | `res://content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_ocean_spray_overlay.png` | `Rect2(-1280, -160, 2560, 720)` | 1 | feathered, alpha 0.58 |
| GrandVistaFogOverlay | `res://content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_fog_overlay.png` | `Rect2(-1280, -520, 2560, 480)` | 2 | feathered, alpha 0.48 |
| GrandVistaShadowVignette | `res://content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_shadow_vignette.png` | `Rect2(-1280, -920, 2560, 1440)` | 3 | feathered, alpha 0.42 |
| GrandVistaForegroundParapet | `res://content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_foreground_parapet.png` | `Rect2(-1280, 260, 2560, 360)` | 20 | disabled, alpha 0; removes the chest-like central focal mass while the playable route remains visible |

The physical Camera 2 envelope drives the cinematic child and all fortress
planes. Far architecture appears earliest and remains longest, mid architecture
owns the hero citadel and reaches full visual authority at the apex, and near
framing appears latest and recedes earliest. Apex far/mid/near alpha is
`0.66/0.96/0.68`; after physical return it settles at `0.58/0.42/0.10` before
the final-gate veil drives the remaining fortress to zero. The far plane is
cooler, darker, and lower-contrast than the mid hero plane, without heavy blur.
Neither Grand Vista child may appear during the first reveal or its traversal
gap.

### Labyrinth depth layers and glue overlays

The first vista keeps its two camera-relative roots. The Grand Vista has six
local camera-relative groups: the cinematic `LabyrinthFarParallax`,
`LabyrinthMistParallax`, and `LabyrinthNearRoot`, plus persistent
`FortressFarParallax`, `FortressMidParallax`, and `FortressNearParallax`.
Fortress follow ratios are `(0.18,0.06)`, `(0.11,0.04)`, and
`(0.045,0.018)`. None includes `PlayableRoot` or `Collision`, and the
composition is intentionally local to Vista Approach rather than the shared
Vista/Return Causeway rig.

| Sprite name | Asset path | Rect | z_index | Tint |
|---|---|---|---|---|
| GrandVistaHorizonSeamFog | `res://content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_horizon_seam_fog.png` | `Rect2(-1280, -560, 2560, 420)` | 30 | continuous mid-fog band, alpha 0.56 |
| GrandVistaPathContactShadow | `res://content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_path_contact_shadow.png` | `Rect2(-1280, -160, 2560, 720)` | 35 | alpha 0.50 |
| GrandVistaEdgeSprayWrap | `res://content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_edge_spray_wrap.png` | `Rect2(-1280, -160, 2560, 720)` | 40 | alpha 0.35 |
| GrandVistaForegroundEdgeMask | `res://content/backgrounds/sundered_keep/grand_vista/atmosphere/grand_vista_foreground_edge_mask.png` | `Rect2(-1280, 220, 2560, 420)` | 80 | alpha 0.55 |

`LabyrinthContactFog`, `LabyrinthMoonRimLight`, and `LabyrinthGateLight` add foreground separation without changing navigation or gameplay authority. Three architecture crops (`WestKeepRoof`, `CentralKeepRoof`, and `ExitKeepRoof`) are removed from the base route-master draw by `route_master_occlusion_mask.gdshader`, redrawn under `RoofOcclusionRoot`, and faded independently by player-only `RoofOccluder2D` zones. This preserves a single route-master source texture while preventing the whole keep plate from fading.

The final gate veil is sized from the union of principal visual coverage metadata
and `RECT_CAMERA_BOUNDS`, then expanded asymmetrically by `FINAL_FOG_OVERSCAN`. Its
maximum alpha is 0.38 so the route remains legible during handoff. It must enclose a
1920×1080 view centered on the final exit plus at least 256 px horizontal and 192 px
vertical safety; walkable-path or collision bounds alone are not valid fog sizing
authority. Shared Vista foreground depth stays within 0.08–0.24.

The underlay correction patch candidates `approach_cliff_depth_patch.png` and `causeway_underside_shadow.png` are intentionally not required by runtime or validation. The current production underlay remains the active background authority; those patch assets are optional future polish only.

## Asset Export Contract

Route-master runtime assets:

| Role | Asset path | Runtime node |
|---|---|---|
| Playable route terrain | `res://content/sprites/world/return_causeway/path/sundered_keep_approach_route_master.png` | `PlayableRoot/ApproachRouteMaster` |
| Ocean void underlay | `res://content/backgrounds/sundered_keep/approach/underlay/approach_ocean_void_underlay.png` | `UnderlayRoot/ApproachOceanVoidUnderlay` |
| Cliff spires underlay | `res://content/backgrounds/sundered_keep/approach/underlay/approach_cliff_spires_underlay.png` | `UnderlayRoot/ApproachCliffSpiresUnderlay` |
| Route contact shadow | `res://content/backgrounds/sundered_keep/approach/underlay/approach_route_contact_shadow.png` | `UnderlayRoot/ApproachRouteContactShadow` |
| Persistent first-vista storm horizon | `res://content/backgrounds/sundered_keep/approach/underlay/first_vista_base_storm_horizon.png` | `UnderlayRoot/FirstVistaBaseStormHorizon` |
| Isolated first-vista Keep landmark | `res://content/backgrounds/sundered_keep/shared/landmarks/distant_sundered_keep_landmark_v2.png` | `ParallaxRoot/RevealDepth/DistantKeep_Parallax2D/DistantSunderedKeepLandmark` |
| First-vista reveal veil | `res://content/backgrounds/sundered_keep/approach/fog/first_vista_reveal_veil.png` | `VistaRoot/FirstVistaMistParallax/ApproachFirstVistaFogVeil` |
| Edge mist wrap | `res://content/backgrounds/sundered_keep/approach/occlusion/approach_edge_mist_wrap.png` | `OcclusionRoot/ApproachEdgeMistWrap` |
| Final gate shadow veil | `res://content/backgrounds/sundered_keep/approach/occlusion/approach_final_gate_shadow_veil.png` | `OcclusionRoot/ApproachFinalGateShadowVeil` |
| Fog strips | `res://content/backgrounds/sundered_keep/approach/fog/approach_fog_strip_0*.png` | `OcclusionRoot/ApproachFogStrip0*` |

The route master is the visible ground. Support layers must not become collision, navigation, terrain metadata, or separate scenes.

The production runtime scene and generated reference blockout both use top-left anchored `Sprite2D` nodes (`centered=false`) and scale each texture to its intended world `Rect2`. This protects runtime layout if a source image drifts, but size drift still emits a warning and should be fixed at the source.

Run the source audit before accepting visual changes:

```bash
cd custodian
python3 tools/validation/sundered_keep_approach_asset_audit.py
```

The audit checks all full-composition PNGs and fails if any PlayableRoot terrain asset has no alpha channel or is fully opaque. It also checks the grand vista PNGs and requires real alpha on `grand_vista_foreground_parapet.png`, `grand_vista_ocean_spray_overlay.png`, and the four saved glue overlays. PlayableRoot PNGs should generally be transparent outside the visible path/terrain silhouette so the editor/game view does not show stacked rectangular plates.

The live ingress approach has a runtime fitting table in `res://game/world/approaches/sundered_keep/sundered_keep_approach.gd`. It intentionally scales `res://content/sprites/world/return_causeway/` path/underlay/occlusion PNGs and `res://content/backgrounds/sundered_keep/` vista mattes into target world rectangles, including a thin `2100x130` `WallShadowOccluder`, so oversized generated overlay exports cannot appear as raw black curtains over the scene.

The production route continues directly from Vista to the approved large Front Gate:

```text
@world_origin
  -> vista_approach
  -> front_gate
```

Return Causeway is an isolated, unfinished experiment available only through
`causeway_only`; production traversal and backtracking never activate it.

`sundered_keep_approach_smoke.gd` validates the Vista scene and mapper-authored
collision. `sundered_keep_vista_polish_smoke.gd` exercises Camera 1 forward,
backward, from mid-envelope spawns, across teleports, and through direction
reversals, then physically exercises Camera 2 reveal and handback. It validates all six local Grand
Vista parallax groups, all 30 preloaded textured fortress components, the curated
17-piece visible composition, continuous second-anchor travel, staged plane
alphas, physical-progress recession, and final-veil clearance while retaining
the existing roof/fog and fixed-gameplay checks.
`sundered_keep_parallax_depth_smoke.gd` validates the
separate shared Vista/Return rig. Direct Vista-to-Front-Gate traversal exists
only in the explicit `debug_direct_keep` profile.

## Historical Reference Blockout Implementation

The generator, former camera director, and generated blockout scene described below
are historical implementation notes and are not live production files. The dynamic
production scene and scripts named at the top of this document are authoritative.

### Phase 1 — Add `_sprite_rect()` helper to builder

In `custodian/tools/build_sundered_keep_approach_blockout.gd`, add a helper that creates a `Sprite2D` with centered=false, positioned at rect top-left, loading the texture, scaling it to the requested `Rect2.size`, and warning if missing or size-mismatched. Then rewrite `_build_underlay()`, `_build_playable()`, `_build_vista()`, `_build_occlusion()` to emit `Sprite2D` nodes instead of visible `Polygon2D` placeholders.

**Helper pattern:**
```gdscript
func _sprite_rect(parent: Node2D, owner: Node, name: String, texture_path: String, rect: Rect2, z_index := 0) -> Sprite2D:
    var sprite := Sprite2D.new()
    sprite.name = name
    sprite.centered = false
    sprite.position = rect.position
    sprite.z_index = z_index
    var texture := load(texture_path) as Texture2D
    if texture == null:
        push_warning("Missing approach texture for %s: %s" % [name, texture_path])
    else:
        sprite.texture = texture
        var actual := Vector2i(texture.get_width(), texture.get_height())
        var expected := Vector2i(int(rect.size.x), int(rect.size.y))
        if actual.x > 0 and actual.y > 0:
            sprite.scale = Vector2(rect.size.x / float(actual.x), rect.size.y / float(actual.y))
        if actual != expected:
            push_warning("Size mismatch for %s: expected %s, got %s; scaling to fit Rect2." % [name, str(expected), str(actual)])
    parent.add_child(sprite)
    sprite.owner = owner
    return sprite
```

### Phase 2 — Replace UnderlayRoot Polygon2D with Sprite2D

Current `_build_underlay()` creates three visible `Polygon2D` nodes (`OceanUnderlay`, `CliffDepthUnderlay`, `FogUnderlay`). Replace them with `_sprite_rect()` calls. **Remove the visible Polygon2D creation; keep no visual polygons.** The collision is in PlayableRoot only — underlay has no collision.

| Sprite name | Asset path | Rect position & size | z_index |
|---|---|---|---|
| OceanUnderlay | `res://content/backgrounds/sundered_keep/shared/underlay/ocean_underlay.png` | `Rect2(-900, -700, 2100, 1400)` | 0 |
| CliffDepthUnderlay | `res://content/backgrounds/sundered_keep/shared/underlay/cliff_depth_underlay.png` | `Rect2(-500, -440, 520, 540)` | 1 |
| FogUnderlay | `res://content/backgrounds/sundered_keep/approach/playable/underlay_fog_band.png` | `Rect2(-900, -620, 2172, 724)` | 2 |

Use `z_index` within UnderlayRoot to establish draw order: ocean (0), cliff (1), fog (2).

### Phase 3 — Replace PlayableRoot Polygon2D with Sprite2D + keep collision

Current `_build_playable()` creates five visible `Polygon2D` nodes then calls `_add_collision_polygon()` for four of them. **Replace the Polygon2D nodes with Sprite2D. Keep all `_add_collision_polygon()` calls unchanged.** Collision polygons stay as the sole collision authority.

PlayableRoot now uses all authored Sprite2D art. Collision polygons remain on StaticBody2D unchanged.

| Sprite name | Asset path | Rect | z_index |
|---|---|---|---|
| MainlandApproachPath | `res://content/backgrounds/sundered_keep/approach/playable/mainland_approach_path.png` | `Rect2(-300, 120, 470, 400)` | 0 |
| HillClimbPath | `res://content/backgrounds/sundered_keep/approach/playable/hill_climb_path.png` | `Rect2(-190, -120, 400, 240)` | 1 |
| OverlookLedge | `res://content/backgrounds/sundered_keep/approach/playable/overlook_ledge.png` | `Rect2(-320, -320, 640, 240)` | 2 |
| LateralTraversePath | `res://content/backgrounds/sundered_keep/approach/playable/lateral_traverse_path.png` | `Rect2(260, -260, 520, 180)` | 3 |
| FortressWallMass | `res://content/backgrounds/sundered_keep/approach/playable/fortress_wall_mass.png` | `Rect2(650, -420, 360, 380)` | 10 |

All five playable sprites exist and are wired as Sprite2D.

### Phase 4 — Replace VistaRoot Polygon2D with Sprite2D

Current `_build_vista()` creates four visible Polygon2D nodes (`HorizonSky`, `FarSea`, `DistantSunderedKeep`, `VistaFogBand`). Replace with `_sprite_rect()`. Preserve `parent.modulate.a = 0.0` (starts hidden, director fades in).

The VistaFogBand should remain a single `Sprite2D` named `VistaFogBand` so the director's `fog_band` export reference (pointing at `VistaRoot/VistaFogBand`) continues to work without changes.

| Sprite name | Asset path | Rect | z_index |
|---|---|---|---|
| HorizonSky | `res://content/backgrounds/sundered_keep/shared/horizon/horizon_sky.png` | `Rect2(-900, -700, 2100, 380)` | 0 |
| FarSea | `res://content/backgrounds/sundered_keep/shared/horizon/far_sea.png` | `Rect2(-900, -520, 2100, 260)` | 1 |
| DistantSunderedKeep | `res://content/backgrounds/sundered_keep/shared/landmarks/distant_sundered_keep.png` | `Rect2(-260, -670, 540, 250)` | 2 |
| VistaFogBand | `res://content/backgrounds/sundered_keep/shared/horizon/vista_fog_band.png` | `Rect2(-900, -380, 2100, 160)` | 3 |

### Phase 5 — Replace OcclusionRoot Polygon2D with Sprite2D

Current `_build_occlusion()` creates two visible Polygon2D nodes (`CliffOccluder`, `WallShadowOccluder`). Replace with `_sprite_rect()`. Preserve `parent.modulate.a = 0.0` (starts hidden, director fades in during traverse).

Both occluder sprites now exist under `approach/playable/` and are wired as Sprite2D.

| Sprite name | Asset path | Rect | z_index |
|---|---|---|---|
| CliffOccluder | `res://content/backgrounds/sundered_keep/approach/playable/cliff_occluder.png` | `Rect2(520, -420, 520, 540)` | 0 |
| WallShadowOccluder | `res://content/backgrounds/sundered_keep/approach/playable/wall_shadow_occluder.png` | `Rect2(-900, -360, 2100, 130)` | 1 |

### Phase 6 — Regenerate the scene

```bash
cd custodian
godot --headless --path . --script res://tools/build_sundered_keep_approach_blockout.gd
```

Expected output: `Generated: res://scenes/levels/sundered_keep/sundered_keep_approach_blockout.tscn`

After regeneration, open the scene in the editor and verify the node tree matches expectations.

### Phase 7 — Add validation smoke test

Create `custodian/tools/validation/sundered_keep_approach_render_smoke.gd`.

Checks:
- Packed scene loads successfully
- All expected Sprite2D nodes exist per root (UnderlayRoot, PlayableRoot, VistaRoot, OcclusionRoot)
- Each Sprite2D has a non-null texture
- Each Sprite2D position matches its expected `Rect2.position`
- Each Sprite2D texture size multiplied by scale matches its expected `Rect2.size`
- `Operator` node exists
- `Camera2D` node exists
- `OverlookCameraDirector` node exists with wired exports: `player`, `camera`, `vista_root`, `occlusion_root`, `fog_band`

Run:
```bash
cd custodian
godot --headless --path . --script res://tools/validation/sundered_keep_approach_render_smoke.gd
```

### Phase 8 — Wire into playable acceptance

Open the generated scene in Godot editor:
```bash
godot --path custodian/scenes/levels/sundered_keep/sundered_keep_approach_blockout.tscn
```

Enable Camera2D and walk the Operator through all four camera states:
```
MainlandStart → RevealStart → RevealFull → TraverseStart → TraverseEnd → ReturnTopdown
```

Verify at each state:
- Camera offset/zoom transitions smoothly
- Vista alpha fades in correctly during hill reveal
- Occlusion fades in during lateral traverse
- Fog band alpha blends correctly
- Collision prevents walking off the path
- No rendering artifacts or missing textures

## Constraints

1. **Rendering/camera only.** No collision, navigation, combat, enemy AI, or simulation state.
2. **Collision stays on existing StaticBody2D polygons.** Visual Sprite2D replacements must not add or alter collision.
3. **Approach flows north (negative Y) then east (positive X).** The director and markers assume this orientation.
4. **The builder is the source of truth.** Edit `build_sundered_keep_approach_blockout.gd`, not the `.tscn` directly. Regenerate after changes.
5. **The director expects `VistaRoot/VistaFogBand` to exist** as a single node it can alpha-fade via the `fog_band` export.
6. **Imported background assets should use linear filtering** (not nearest-neighbor) since they are painterly mattes, not pixel tiles.
7. **Scene is connected to the main game flow via F6 key** in `debug_bus.gd`. Pressing F6 in the main game changes to the approach blockout scene.

## Acceptance Criteria

- [x] Builder emits Sprite2D nodes for all four roots (UnderlayRoot, PlayableRoot, VistaRoot, OcclusionRoot) with correct textures, positions, and sizes
- [x] All approach playable sprites exist as authored PNGs, no Polygon2D placeholders remain
- [x] FortressWallMass uses 360×380 Sprite2D (actual file dimensions)
- [x] Source asset audit verifies expected PNG dimensions and alpha-bearing PlayableRoot exports
- [x] Tight entry, reversible position-controlled Camera 1 envelope, Camera 2 hero beat, and final-gate framing are explicit
- [x] Vista/occlusion/fog alpha transitions are smooth and complete
- [x] Collision is unchanged — player cannot leave the walkable path
- [x] Smoke test passes: all Sprite2D nodes exist with non-null textures, root/Operator z-order is absolute, playable collision polygons exist, director exports are wired, and Sprite2D render rects match their intended world rectangles
- [x] Scene regenerates cleanly from builder
- [x] Scene loads via F6 in-game (debug shortcut)
- [x] Procgen simulation and procgen-specific HUD/marker presentation are isolated before Vista instancing
- [x] BackdropVoidFill covers camera bounds plus 768 px of framing slack
- [x] Production VistaController drives the shared runtime camera through authored offset/zoom targets
- [x] Exit uses a visible, directionally staged destination threshold before fade/handoff
- [x] Camera 1 framing and Vista visibility are reversible functions of four route markers and require no Area2D trigger, timer, or completion flag
- [x] The optional Camera 1 moonlight/prompt accent cannot influence camera correctness or replay
- [x] Destination prompt remains hidden until the reveal settle completes
- [x] First-vista roots and all six local Grand Vista parallax groups move independently while playable art and collision remain fixed
- [x] Thirty northeast fortress components preload, a curated 17-piece shot reveals by depth plane, and the remaining architecture recedes then clears beneath the final veil
- [x] Shared Vista/Return painterly depth rig preserves gameplay ownership and Return Causeway compatibility paths
- [x] Three route-master roof crops fade only for Operator/player bodies and restore exactly
- [x] Final fog coverage encloses the 1920×1080 exit view plus required safety margins

## Next Agent Slice

- **Goal:** Production runtime reveal choreography and presentation isolation are implemented. Remaining work is bespoke reveal-asset export and manual play review.
- **Future opportunities:**
  - Re-export `underlay_fog_band.png`, `distant_sundered_keep.png`, `overlook_ledge.png`, and `fortress_wall_mass.png` to match the documented production rect/source contract if desired
  - Replace the procedural/reused reveal scaffolds with the tracked fog-veil, fog-ribbon, moonlight-sweep, and far-silhouette production assets
  - In-editor visual review of the approach blockout scene (open `sundered_keep_approach_blockout.tscn` and walk the operator)
  - In-editor visual review of the procgen ingress -> `sundered_keep_approach.tscn` playable-map flow
  - Replace the current ingress tile fallback with a specific coast/keep ingress reservation in the procgen intent graph
  - Expand `AUTHORING_MARKERS` into richer encounter scripting once enemy compositions are selected
  - Keep Return Causeway changes isolated to `causeway_only`; do not promote it into production without explicit user review
- **Constraint:** Art alpha remains non-authoritative; use mapper rails for collision and `AUTHORING_MARKERS` for semantic gameplay points.
