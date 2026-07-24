# Sundered Keep Vista Approach

- **Status:** route-master playable Sundered Keep Vista node implemented in the production directed route
- **Owner:** authored level / rendering / camera
- **Runtime:** `custodian/` Godot 4.x
- **Production runtime scene:** `custodian/game/world/approaches/sundered_keep/sundered_keep_approach.tscn`

## Summary

A playable first Sundered Keep slice built from the former approach scene. The player enters from mainland top-down on one authored route-master terrain sprite under a tight Operator-follow camera. The environmental plate stays hidden while the player climbs; a physical trigger at the authored overlook starts the first reveal, holds the wide composition briefly, and returns to traversal framing. The later Labyrinth section uses layered panorama/fog/parapet parallax, local depth lighting, and independently fading route-master roof crops before the route continues to Return Causeway.

**Hard constraint:** Art alpha still does not own collision. The production runtime scene uses fitted `Sprite2D` matte/terrain assets, a single perimeter-rail `StaticBody2D` made from mapper-authored thick `CapsuleShape2D` rails, and explicit `AUTHORING_MARKERS` for gameplay/event semantics. `GrandVistaRoot` is presentation-only and must not become collision, navigation, enemy AI, or sim authority. Filled path-shaped `CollisionPolygon2D` solids are not valid walkable-boundary collision because they block the path itself. Sprite2D assets are fit to their target `Rect2`; the rect is runtime layout authority. Playable terrain art must keep transparent pixels outside the authored terrain shape unless the full rectangle is intentionally terrain.

## Runtime Ingress Chain

Normal contract-world access uses the production directed route:

```
@world_origin
  -> vista_approach
  -> return_causeway
  -> front_gate
```

`ContractWorldLoader` owns placement of the procgen-side `WorldIngressSite`. `RouteTraversalManager` resolves the production graph in `content/routes/sundered_keep/sundered_keep_route.json`, while `LevelLoader` stages and activates the independent Vista, Return Causeway, and Front Gate level scenes. Route data, not a Vista scene switch or destination-loading trigger, selects production and debug profiles.

`WorldIngressSite` captures every direct child of `World` assigned to `world_origin_branch`, then hides and processing-disables the captured branches for the full route session. The Operator, Camera2D, shared lighting, LevelLoader, and RouteTraversalManager remain persistent. Node-to-node traversal never restores origin content; exact captured branch visibility and process modes are restored only during route exfil to `@world_origin`.

`SunderedKeepApproach` owns Vista presentation only: it selects `vista_approach` UI mode and suppresses Operator world-space health/target presentation while active. It does not capture, disable, or restore base-world branches. A failed ingress transaction restores the captured origin snapshot before the route is allowed to retry.

Ingress transitions must be deferred out of `Area2D.body_entered` physics callbacks before instancing this scene. The approach also defers its dynamic `StaticBody2D` boundary rails and final exit `Area2D` setup by one frame so Godot does not register or toggle physics shapes while flushing queries.

## Collision Mapping Debug Scene

Use `res://scenes/debug/sundered_keep_approach_collision_mapper.tscn` to map exact approach collision points against the active underlay/path art. The scene loads the production `sundered_keep_approach.tscn`, draws existing `BOUNDARY_SEGMENTS`, and accepts clicked points as one connected polyline: A, B, C, D exports A->B, B->C, and C->D.

Controls:

- Left click: add a point.
- Right click: remove the last point.
- `C`: copy connected polyline segments as `BOUNDARY_SEGMENTS` source entries.
- `WASD` / arrow keys: pan.
- Mouse wheel / `+` / `-`: zoom around the cursor.
- `L`: focus the final horizontal traverse.
- `E`: toggle existing collision rails.
- `V`: toggle draft lines.
- `R`: reset draft points.

The mapper prints both runtime coordinates and source coordinates. Paste the source coordinates into `BOUNDARY_SEGMENTS`; runtime lowering from `ROUTE_VERTICAL_OFFSET` is applied by the approach script. The runtime also preserves the current captured point stream by flattening the pasted entries and building rails between every consecutive point.

The same mapper now has marker mode for event authoring:

- `M`: toggle collision/marker mode.
- Marker mode currently exposes the retained Vista roles: `spawn` and `return_causeway`.
- Left click in marker mode: place the selected marker.
- Right click in marker mode: clear the selected marker.
- `C`: copy the full `AUTHORING_MARKERS` block.
- `Enter` / `U`: apply marker positions back to `sundered_keep_approach.gd`.

`AUTHORING_MARKERS` is the stable authoring contract for Vista reference points. Keep key, gate, encounter, and siege markers belong to Return Causeway or the Sundered Keep map, not this presentation route. The runtime endpoint is positioned by `LEVEL_EXIT_POS`; its authored `continue` exit resolves to Return Causeway in the production route profile.

## Scene Architecture

```
SunderedKeepApproach
├── ParallaxRoot          z=0     — shared painterly BaseDepth/RevealDepth/ForegroundDepth rig
├── UnderlayRoot          z=-300  — ocean void, cliff spires, route contact shadow
├── GrandVistaRoot        z=-220  — optional later hero overlook panorama/fog/spray/parapet, presentation-only
├── VistaRoot             z=-200  — first-vista horizon and fog veil
├── PlayableRoot          z=0     — one active ApproachRouteMaster terrain sprite
├── OcclusionRoot         z=100   — edge mist, fog strips, final gate shadow veil
├── RoofOcclusionRoot     z=90    — route-master roof crops and player-only fade zones
├── Collision             — PathBoundaryCollision thick CapsuleShape2D rails
├── Markers               — route-progress markers plus FirstRevealCameraAnchor
├── SequenceTriggers      — physical FirstVistaRevealTrigger
├── EventMarkers          — retained Vista reference markers for spawn and Return Causeway
├── EventRuntime          — authored route-exit affordances bound by RouteTraversalManager
├── VistaController       — drives vista, grand vista, fog, occlusion, and distant keep alpha
├── RevealDirector        — one-shot reveal/hold/return choreography for camera, fog peel, moonlight cue, and delayed prompt
```

### Z-order

| Root | z_index | Notes |
|------|---------|-------|
| ParallaxRoot | 0 | Presentation-only shared depth rig; child `Parallax2D` layers use absolute z ordering |
| UnderlayRoot | -300 | Behind everything |
| GrandVistaRoot | -220 | Second-beat hero overlook panorama layer; starts hidden and is visual-only |
| VistaRoot | -200 | First vista horizon/fog veil |
| PlayableRoot | 0 | Route-master walkable terrain art |
| OcclusionRoot | 100 | Edge mist, fog strips, and final gate veil |
| Collision/VistaController/EventMarkers/EventRuntime | — | Collision/event authority, no visual root concern |

The production runtime script self-heals these visual roots with `z_as_relative=false` so draw order does not depend on scene-tree insertion or inherited z values. The blockout scene remains reference/dev-only.

`UnderlayRoot/BackdropVoidFill` is the bottom safety plate. Its coverage is `RECT_CAMERA_BOUNDS.grow(768)` and its z-index is below every fitted underlay sprite. `RECT_APPROACH_UNDERLAY` also includes camera-framing slack. The safety plate owns no collision or simulation semantics; it exists solely to ensure camera zoom/framing can never expose the engine clear color.

### Camera states & markers

Gameplay framing after the first reveal is driven by player position against Marker2D waypoints. The first reveal itself is driven only by `SequenceTriggers/FirstVistaRevealTrigger`, not raw progress. Approach flows **north (decreasing Y)** then **east (increasing X)**.

| State | Camera offset/zoom | Vista alpha | Occlusion alpha | Trigger marker |
|---|---|---|---|---|
| 1 — Entry Route | intro offset `(0,-18)`, zoom `1.12` | 0.0 | Edge mist visible, final veil hidden | Player starts at EntrySpawn |
| 2 — First Reveal | anchor offset `(0,0)`, zoom `0.84` | 0→1 by reveal tween | Edge mist peels, final veil hidden | Physical overlap at `FirstVistaRevealTrigger` |
| 3 — Playable Traverse | offset `(0,-48)`, zoom `0.98` | 1.0 | Edge mist/fog strips visible, final veil hidden | Reveal returns to Operator follow |
| 4 — Labyrinth Vista | blends to offset `(18,-52)`, zoom `0.97` | 1.0 | Layered mist/depth lighting; local roofs fade | Player reaches SecondVistaStart through SecondVistaEnd |
| 5 — Final Gate Veil | normal_offset, normal_zoom | 1.0 | Final gate shadow veil fades in | Player passes SecondVistaEnd toward ReturnTopdown |

These values are live camera targets. `SunderedKeepVistaController` interpolates them and sends a reversible presentation-framing override to the shared `CameraController`; ordinary auto-zoom, lookahead, threat bias, and bob resume after the level handoff.

`FirstVistaRevealTrigger` is centered at runtime `(-150, 5)`, matching the authored overlook. `SunderedKeepRevealDirector` owns how the presentation plays, while the approach owns when it starts: 0.12 seconds of anticipation, a 0.55-second cubic blend to `FirstRevealCameraAnchor`, a 1.05-second hold, a 0.48-second return to Operator-follow traversal, and a 0.35-second atmosphere settle. Near and mid fog move away from the route on different vectors, the far strip remains as distance haze, and a soft radial `RevealMoonlightCue` briefly lifts the keep silhouette. Raw route progress cannot expose `VistaRoot` before this trigger and the one-shot reveal cannot replay.

The temporary `FarKeepSilhouetteLayerA/B` copies have been removed. The authored
`ApproachFirstVistaHorizon` is the only first-vista landmark plate while the shared
supplementary assets remain review-gated, preventing repeated Keep silhouettes at
incompatible scales.

The endpoint remains an `Area2D`, but it is a narrow walkable threshold under `EventRuntime/LevelExitAffordance`, displays the Return Causeway destination prompt, accepts automatic crossing only from the authored approach side, raises the final veil, and requests the route-owned `continue` handoff.

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

The following painterly matte/background assets already exist at `res://content/backgrounds/sundered_keep/`. They are wide single images (not split L/R pairs). Use linear filtering (not nearest-neighbor) on import.

| File | Size | Scene role |
|------|------|------------|
| `ocean_underlay.png` | 2100×1400 | UnderlayRoot — deep ocean below everything |
| `cliff_depth_underlay.png` | 520×540 | UnderlayRoot — dark cliff mass |
| `horizon_sky.png` | 2100×380 | VistaRoot — night/void sky |
| `horizon_sky_02.png` | 2100×380 | VistaRoot — sky variant |
| `far_sea.png` | 2100×260 | VistaRoot — dark sea band on horizon |
| `far_sea_02.png` | 2100×260 | VistaRoot — sea variant |
| `distant_sundered_keep.png` | 540×250 | VistaRoot — keep silhouette on horizon |
| `vista_fog_band.png` | 2100×160 | VistaRoot/VistaFogBand — seam-hiding fog |
| `keep_horizon_wide.png` | 1689×787 | Reserve — wider keep matte if needed |

These live under `content/` not `assets/`. Use `res://content/backgrounds/sundered_keep/` paths.

## Shared Painterly Parallax Depth

Vista Approach and Return Causeway both build the presentation-only
`SunderedKeepParallaxRig`, but its supplementary painterly plates are review-gated
off by default. The current source revisions contain baked checkerboard, mismatched
mist halves, or compositionally unsafe foreground coverage. Until corrected plates
pass the alpha/source-revision validator and visual review, Vista uses its existing
authored first-vista composition as the sole background authority. Return Causeway
preserves only
`BaseDepth/DistantKeep_Parallax2D/DistantSunderedKeepLandmark` for compatibility.

| Layer | Vista scroll scale | Review state |
|---|---:|---|
| `BackdropVoid` / `StormOceanBackdrop` | ordinary world presentation | active opaque safety fill |
| Distant Keep | `(0.18, 0.12)` on Return Causeway | active |
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

`GrandVistaRoot` is a second presentation layer in the same production approach scene. It fades in as the player reaches the overlook ledge and fades out as the player leaves toward the lateral traverse. It does not define terrain, collision, navigation, encounters, or exit logic; traversal remains owned by path sprites plus perimeter capsule rails.

The approach also applies `res://game/world/approaches/sundered_keep/soft_rect_feather.gdshader` to horizon, sea, fog, distant-keep, cliff-depth, and grand-vista plates so fitted matte rectangles feather at their UV edges instead of reading as hard cards. Low-opacity `Polygon2D` grounding shadows sit under the walkable chunks to tie the path art into the void/ocean composition; these are visual-only and are not collision authority.

| Sprite name | Asset path | Rect | z_index | Tint |
|---|---|---|---|---|
| GrandVistaPanorama | `res://content/backgrounds/sundered_keep/grand_vista/grand_vista_panorama.png` | `Rect2(-1280, -920, 2560, 1440)` | 0 | feathered, alpha 0.88 |
| GrandVistaOceanSprayOverlay | `res://content/backgrounds/sundered_keep/grand_vista/grand_vista_ocean_spray_overlay.png` | `Rect2(-1280, -160, 2560, 720)` | 1 | feathered, alpha 0.58 |
| GrandVistaFogOverlay | `res://content/backgrounds/sundered_keep/grand_vista/grand_vista_fog_overlay.png` | `Rect2(-1280, -520, 2560, 480)` | 2 | feathered, alpha 0.48 |
| GrandVistaShadowVignette | `res://content/backgrounds/sundered_keep/grand_vista/grand_vista_shadow_vignette.png` | `Rect2(-1280, -920, 2560, 1440)` | 3 | feathered, alpha 0.42 |
| GrandVistaForegroundParapet | `res://content/backgrounds/sundered_keep/grand_vista/grand_vista_foreground_parapet.png` | `Rect2(-1280, 260, 2560, 360)` | 20 | feathered, alpha 0.92 |

`SunderedKeepVistaController` derives the second-beat fade from `SecondVistaStart`, `SecondVistaFull`, and `SecondVistaEnd`: alpha remains `0` before the later second-vista window, rises from start to full, falls from full to end, and returns to `0` after end. `GrandVistaRoot` must not appear during the first approach reveal or the playable traversal gap before the later hero overlook. The panorama is intentionally awe-scale, while the parapet and spray overlays require real PNG alpha so they frame the camera reward without rectangular plates.

### Labyrinth depth layers and glue overlays

The first vista and Labyrinth presentation are split into five camera-relative roots: `FirstVistaFarParallax`, `FirstVistaMistParallax`, `LabyrinthFarParallax`, `LabyrinthMistParallax`, and `LabyrinthNearRoot`. Their movement ratios are intentionally subtle and never include `PlayableRoot` or `Collision`. The saved grand-vista glue overlays inherit the second-vista fade through the Labyrinth mist/near roots and remain presentation-owned while the approach scene remains the playable map.

| Sprite name | Asset path | Rect | z_index | Tint |
|---|---|---|---|---|
| GrandVistaHorizonSeamFog | `res://content/backgrounds/sundered_keep/grand_vista/grand_vista_horizon_seam_fog.png` | `Rect2(-1280, -460, 2560, 320)` | 30 | alpha 0.45 |
| GrandVistaPathContactShadow | `res://content/backgrounds/sundered_keep/grand_vista/grand_vista_path_contact_shadow.png` | `Rect2(-1280, -160, 2560, 720)` | 35 | alpha 0.50 |
| GrandVistaEdgeSprayWrap | `res://content/backgrounds/sundered_keep/grand_vista/grand_vista_edge_spray_wrap.png` | `Rect2(-1280, -160, 2560, 720)` | 40 | alpha 0.35 |
| GrandVistaForegroundEdgeMask | `res://content/backgrounds/sundered_keep/grand_vista/grand_vista_foreground_edge_mask.png` | `Rect2(-1280, 220, 2560, 420)` | 80 | alpha 0.55 |

`LabyrinthContactFog`, `LabyrinthMoonRimLight`, and `LabyrinthGateLight` add foreground separation without changing navigation or gameplay authority. Three architecture crops (`WestKeepRoof`, `CentralKeepRoof`, and `ExitKeepRoof`) are removed from the base route-master draw by `route_master_occlusion_mask.gdshader`, redrawn under `RoofOcclusionRoot`, and faded independently by player-only `RoofOccluder2D` zones. This preserves a single route-master source texture while preventing the whole keep plate from fading.

The final gate veil is sized from the union of principal visual coverage metadata and `RECT_CAMERA_BOUNDS`, then expanded asymmetrically by `FINAL_FOG_OVERSCAN`. It must enclose a 1920×1080 view centered on the final exit plus at least 256 px horizontal and 192 px vertical safety; walkable-path or collision bounds alone are not valid fog sizing authority.

The underlay correction patch candidates `approach_cliff_depth_patch.png` and `causeway_underside_shadow.png` are intentionally not required by runtime or validation. The current production underlay remains the active background authority; those patch assets are optional future polish only.

## Asset Export Contract

Route-master runtime assets:

| Role | Asset path | Runtime node |
|---|---|---|
| Playable route terrain | `res://content/sprites/world/return_causeway/path/sundered_keep_approach_route_master.png` | `PlayableRoot/ApproachRouteMaster` |
| Ocean void underlay | `res://content/backgrounds/sundered_keep/approach/approach_ocean_void_underlay.png` | `UnderlayRoot/ApproachOceanVoidUnderlay` |
| Cliff spires underlay | `res://content/backgrounds/sundered_keep/approach/approach_cliff_spires_underlay.png` | `UnderlayRoot/ApproachCliffSpiresUnderlay` |
| Route contact shadow | `res://content/backgrounds/sundered_keep/approach/approach_route_contact_shadow.png` | `UnderlayRoot/ApproachRouteContactShadow` |
| First vista horizon | `res://content/backgrounds/sundered_keep/approach/approach_first_vista_horizon.png` | `VistaRoot/FirstVistaFarParallax/ApproachFirstVistaHorizon` |
| First vista fog veil | `res://content/backgrounds/sundered_keep/approach/approach_first_vista_fog_veil.png` | `VistaRoot/FirstVistaMistParallax/ApproachFirstVistaFogVeil` |
| Edge mist wrap | `res://content/backgrounds/sundered_keep/approach/approach_edge_mist_wrap.png` | `OcclusionRoot/ApproachEdgeMistWrap` |
| Final gate shadow veil | `res://content/backgrounds/sundered_keep/approach/approach_final_gate_shadow_veil.png` | `OcclusionRoot/ApproachFinalGateShadowVeil` |
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

The production route always continues from Vista to Return Causeway before Front Gate:

```text
@world_origin
  -> vista_approach
  -> return_causeway
  -> front_gate
```

`sundered_keep_approach_smoke.gd` validates the Vista scene and mapper-authored collision. `sundered_keep_vista_polish_smoke.gd` physically enters the reveal trigger and proves the tight-entry/reveal/hold/return camera sequence, one-shot ownership, five local parallax roots, fixed playable/collision roots, Labyrinth depth pass, player-only roof fades, and computed final-fog enclosure. `sundered_keep_parallax_depth_smoke.gd` instantiates Vista and Return Causeway together and validates the shared painterly rig's assets, groups, scales, linear filtering, compatibility paths, and presentation-only descendants. The production graph smoke validates forward and reverse traversal, active-level adoption, source cache behavior, and exact world-origin restoration only after route exfil. Direct Vista-to-Front-Gate traversal exists only in the explicit `debug_direct_keep` profile.

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
| OceanUnderlay | `res://content/backgrounds/sundered_keep/ocean_underlay.png` | `Rect2(-900, -700, 2100, 1400)` | 0 |
| CliffDepthUnderlay | `res://content/backgrounds/sundered_keep/cliff_depth_underlay.png` | `Rect2(-500, -440, 520, 540)` | 1 |
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
| HorizonSky | `res://content/backgrounds/sundered_keep/horizon_sky.png` | `Rect2(-900, -700, 2100, 380)` | 0 |
| FarSea | `res://content/backgrounds/sundered_keep/far_sea.png` | `Rect2(-900, -520, 2100, 260)` | 1 |
| DistantSunderedKeep | `res://content/backgrounds/sundered_keep/distant_sundered_keep.png` | `Rect2(-260, -670, 540, 250)` | 2 |
| VistaFogBand | `res://content/backgrounds/sundered_keep/vista_fog_band.png` | `Rect2(-900, -380, 2100, 160)` | 3 |

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
- [x] Tight entry, physical first reveal, reveal hold, gameplay return, Labyrinth, and final-gate framing states are explicit
- [x] Vista/occlusion/fog alpha transitions are smooth and complete
- [x] Collision is unchanged — player cannot leave the walkable path
- [x] Smoke test passes: all Sprite2D nodes exist with non-null textures, root/Operator z-order is absolute, playable collision polygons exist, director exports are wired, and Sprite2D render rects match their intended world rectangles
- [x] Scene regenerates cleanly from builder
- [x] Scene loads via F6 in-game (debug shortcut)
- [x] Procgen simulation and procgen-specific HUD/marker presentation are isolated before Vista instancing
- [x] BackdropVoidFill covers camera bounds plus 768 px of framing slack
- [x] Production VistaController drives the shared runtime camera through authored offset/zoom targets
- [x] Exit uses a visible, directionally staged destination threshold before fade/handoff
- [x] FirstVistaRevealTrigger fires one one-shot camera/fog/light choreography and cannot replay
- [x] Near/mid fog peel independently while far haze remains after the reveal
- [x] Destination prompt remains hidden until the reveal settle completes
- [x] Five parallax roots move independently while playable art and collision remain fixed
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
  - Continue Return Causeway presentation polish without changing the production route graph
- **Constraint:** Art alpha remains non-authoritative; use mapper rails for collision and `AUTHORING_MARKERS` for semantic gameplay points.
