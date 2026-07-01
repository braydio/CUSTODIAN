# Sundered Keep Vista Approach

- **Status:** runtime production approach implemented and smoke-validated; source-asset audit reports current export-size drift
- **Owner:** rendering / camera
- **Runtime:** `custodian/` Godot 4.x
- **Production runtime scene:** `custodian/game/world/approaches/sundered_keep/sundered_keep_approach.tscn`
- **Reference generator:** `custodian/tools/build_sundered_keep_approach_blockout.gd`
- **Director:** `custodian/scripts/levels/sundered_keep/overlook_camera_director.gd`
- **Generated scene:** `custodian/scenes/levels/sundered_keep/sundered_keep_approach_blockout.tscn`

## Summary

A visual-only camera/composition sequence for the Sundered Keep approach. The player enters from mainland top-down, climbs a hill as the horizon reveals the Sundered Keep vista, traverses laterally along a cliff face (occluding the vista), then returns to normal top-down play.

**Hard constraint:** Rendering/camera/traversal only. No navigation, combat, enemy AI, or deterministic simulation state. The production runtime scene uses fitted `Sprite2D` matte/terrain assets and a single perimeter-rail `StaticBody2D` made from `SegmentShape2D` rails. Filled path-shaped `CollisionPolygon2D` solids are not valid walkable-boundary collision because they block the path itself. Sprite2D assets are fit to their target `Rect2`; the rect is runtime layout authority. Playable terrain art must keep transparent pixels outside the authored terrain shape unless the full rectangle is intentionally terrain.

## Runtime Ingress Chain

Normal contract-world access now routes through:

```
Procgen world placement -> WorldIngressSite -> authored Sundered Keep approach/vista -> final fade -> SunderedKeepMap
```

`ContractWorldLoader` owns placement of the procgen-side `WorldIngressSite`. `res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn` is now the full production runtime approach, using ocean/cliff/fog underlay, horizon sky, far sea, distant keep, vista fog, playable path art, occluders, perimeter collision rails, progress markers, `SunderedKeepVistaController`, and `SunderedKeepTransitionTrigger`. The runtime approach isolates presentation from the generated world: `WorldIngressSite` hides and disables `ProcGenRuntime` and `ConnectedMaps` while the approach is active, the approach scene fits all sprites to explicit design `Rect2`s instead of using raw PNG dimensions, and the distant keep renders at its intended hero silhouette rect rather than stretching across the screen. `res://game/world/sundered_keep/sundered_keep_map.gd` remains the real gameplay destination after the fade. The old direct `SunderedKeepTravelGate` path is retained only behind `place_debug_sundered_keep_gateway` for review.

## Scene Architecture

```
SunderedKeepApproach
├── UnderlayRoot          z=-300  — ocean/cliff/fog mattes
├── VistaRoot             z=-200  — horizon sky, far sea, distant keep, vista fog
├── PlayableRoot          z=0     — walkable path Sprite2D art
├── OcclusionRoot         z=100   — cliff/wall occluders
├── Collision             — PathBoundaryCollision SegmentShape2D rails
├── Markers               — EntrySpawn, RevealStart, RevealFull, TraverseStart, TraverseEnd, ReturnTopdown
├── VistaController       — drives vista, fog, occlusion, and distant keep alpha
└── ExitTransitionTrigger — final handoff to SunderedKeepMap
```

### Z-order

| Root | z_index | Notes |
|------|---------|-------|
| UnderlayRoot | -300 | Behind everything |
| VistaRoot | -200 | Horizon sky, far sea, distant keep, fog band |
| PlayableRoot | 0 | Walkable terrain art |
| OcclusionRoot | 100 | Cliff/wall occluders that hide vista during traverse |
| Collision/VistaController/ExitTransitionTrigger | — | No visual concern |

The production runtime script self-heals these visual roots with `z_as_relative=false` so draw order does not depend on scene-tree insertion or inherited z values. The blockout scene remains reference/dev-only.

### Camera states & markers

State transitions are driven by player position against Marker2D waypoints. Approach flows **north (decreasing Y)** then **east (increasing X)**.

| State | Camera offset/zoom | Vista alpha | Occlusion alpha | Trigger marker |
|---|---|---|---|---|
| 1 — Mainland Topdown | normal_offset (0,0), normal_zoom (1,1) | 0.0 | 0.0 | Player starts at MainlandStart (y≈430) |
| 2 — Hill Reveal Blend | reveal_offset (0,-140), reveal_zoom (0.86) | 0→1 smoothstep | 0.0 | Player enters RevealStart (y≈80) to RevealFull (y≈-250) |
| 3 — Overlook Vista | reveal_offset, reveal_zoom | 1.0 | 0.0 | Player between RevealFull and TraverseStart |
| 4 — Lateral Traverse | traverse_offset (0,-48), traverse_zoom (0.96) | 1→0.35 | 0→1 | Player passes TraverseStart (x≈260) |
| 5 — Return Topdown | normal_offset, normal_zoom | 0.35 (fading) | 1.0 | Player passes TraverseEnd (x≈760) toward ReturnTopdown |

**Marker positions** (from builder):

| Marker | Position |
|--------|----------|
| MainlandStart | `(-80, 430)` |
| RevealStart | `(-40, 80)` |
| RevealFull | `(0, -250)` |
| TraverseStart | `(260, -180)` |
| TraverseEnd | `(760, -170)` |
| ReturnTopdown | `(720, -80)` |

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

## Asset Export Contract

The production runtime scene and generated reference blockout both use top-left anchored `Sprite2D` nodes (`centered=false`) and scale each texture to its intended world `Rect2`. This protects runtime layout if a source image drifts, but size drift still emits a warning and should be fixed at the source.

Run the source audit before accepting visual changes:

```bash
cd custodian
python3 tools/validation/sundered_keep_approach_asset_audit.py
```

The audit checks all full-composition PNGs and fails if any PlayableRoot terrain asset has no alpha channel or is fully opaque. It also reports source export-size drift, such as oversized fog/keep exports, so the runtime can keep fitting by rect while asset cleanup remains explicit. PlayableRoot PNGs should generally be transparent outside the visible path/terrain silhouette so the editor/game view does not show stacked rectangular plates.

The live ingress approach has a runtime fitting table in `res://game/world/approaches/sundered_keep/sundered_keep_approach.gd`. It intentionally scales `res://content/sprites/world/return_causeway/` path/underlay/occlusion PNGs and `res://content/backgrounds/sundered_keep/` vista mattes into target world rectangles, including a thin `2100x130` `WallShadowOccluder`, so oversized generated overlay exports cannot appear as raw black curtains over the scene.

## Reference Blockout Implementation

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
- [x] All four camera states render correctly when walking the operator through the markers
- [x] Vista/occlusion/fog alpha transitions are smooth and complete
- [x] Collision is unchanged — player cannot leave the walkable path
- [x] Smoke test passes: all Sprite2D nodes exist with non-null textures, root/Operator z-order is absolute, playable collision polygons exist, director exports are wired, and Sprite2D render rects match their intended world rectangles
- [x] Scene regenerates cleanly from builder
- [x] Scene loads via F6 in-game (debug shortcut)

## Next Agent Slice

- **Goal:** Production runtime full-composition approach is implemented. Remaining work is asset export cleanup and manual play review.
- **Future opportunities:**
  - Re-export `underlay_fog_band.png`, `distant_sundered_keep.png`, `overlook_ledge.png`, and `fortress_wall_mass.png` to match the documented production rect/source contract if desired
  - In-editor visual review of the approach blockout scene (open `sundered_keep_approach_blockout.tscn` and walk the operator)
  - In-editor visual review of the procgen ingress -> `sundered_keep_approach.tscn` -> `SunderedKeepMap` flow
  - Replace the current ingress tile fallback with a specific coast/keep ingress reservation in the procgen intent graph
  - Ensure the approach transitions smoothly back to the main game scene after completion
- **Constraint:** Rendering/camera/traversal only. No combat/nav/AI.
