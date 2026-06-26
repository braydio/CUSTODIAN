# Sundered Keep Vista Approach

- **Status:** draft
- **Owner:** rendering / camera
- **Runtime:** `custodian/` Godot 4.x

## Summary

A visual-only camera-and-composition sequence for the Sundered Keep approach.
The player enters from the mainland top-down, climbs a hill as the horizon reveals
the Sundered Keep vista, traverses laterally along a cliff face (which occludes
the vista), then returns to normal top-down play.

This scene provides **no collision, navigation, combat, enemy AI, or deterministic
simulation state**. It is a presentation layer only.

## Four Camera/Composition States

| # | State | Camera | Vista | Occluders |
|---|-------|--------|-------|-----------|
| 1 | Mainland Topdown | normal offset/zoom, player walks uphill | hidden (alpha 0) | hidden |
| 2 | Hill Reveal Blend | camera lifts/offsets north, horizon fades in | alpha 0→1 (smoothstep) | hidden |
| 3 | Overlook Vista | top half of screen is Sundered Keep horizon, lower half is playable ledge | fully visible (alpha 1) | hidden |
| 4 | Lateral Traverse / Return | camera returns toward topdown, offset shrinks | fading (alpha 0.35) | occluders fade in to block vista, then fully opaque on return |

## State Triggers

Transitions are driven by the player's global position against Marker2D nodes placed
along the approach path:

```
MainlandStart (y ≈ 430)
    ↓ player moves north (decreasing y)
RevealStart  (y ≈ 80)   → camera begins lifting, vista alpha increases
    ↓
RevealFull   (y ≈ -250) → vista fully visible, camera at reveal_offset
    ↓ player moves east (increasing x)
TraverseStart (x ≈ 260) → vista partially fades, occluders rise, camera shifts to traverse_offset
    ↓
TraverseEnd   (x ≈ 760) → occluders fully opaque, vista mostly hidden
ReturnTopdown (x ≈ 720) → camera returns to normal_offset
```

## Scene Structure

```
SunderedKeepApproach
├── UnderlayRoot              — always-visible background layers
│   ├── OceanUnderlay         — dark deep-ocean polygon
│   ├── CliffDepthUnderlay    — dark cliff mass
│   └── FogUnderlay           — thin mist band over the ocean
├── PlayableRoot              — walkable path polygons + collision
│   ├── MainlandApproachPath  — uphill path from south
│   ├── HillClimbPath         — steeper incline
│   ├── OverlookLedge         — wide flat ledge at the top
│   ├── LateralTraversePath   — eastward cliff-side path
│   └── Collision             — StaticBody2D + CollisionPolygon2D per segment
├── VistaRoot                 — alpha-faded horizon layers (modulate.a driven by director)
│   ├── HorizonSky            — dark night/void sky
│   ├── DistantSunderedKeep   — keep silhouette polygon
│   ├── FarSea                — dark sea band
│   └── VistaFogBand          — seam-hiding fog (also referenced by director)
├── OcclusionRoot             — alpha-faded blocking layers (modulate.a driven by director)
│   ├── CliffOccluder         — large cliff/wall polygon that hides the vista
│   └── WallShadowOccluder    — dark shadow band
├── Markers                   — Marker2D waypoints for the camera director
│   ├── MainlandStart
│   ├── RevealStart
│   ├── RevealFull
│   ├── TraverseStart
│   ├── TraverseEnd
│   └── ReturnTopdown
├── Operator                  — player character (instanced from operator.tscn, positioned at MainlandStart)
├── Camera2D                  — active game camera
└── OverlookCameraDirector    — script driving camera offset/zoom and visual alphas (player, camera, markers, vista/occlusion/fog all wired at build time)
```

## Files

| Path | Type | Role |
|------|------|------|
| `custodian/scripts/levels/sundered_keep/overlook_camera_director.gd` | Runtime script | Drives camera offset/zoom, vista/occlusion/fog alpha from player position vs markers. Exports `player` (must be assigned at instance time). |
| `custodian/tools/build_sundered_keep_approach_blockout.gd` | Builder script (SceneTree) | Generates `sundered_keep_approach_blockout.tscn` with placeholder polygons, markers, camera, operator instance, and fully wired director node (including `.player`). |
| `custodian/scenes/levels/sundered_keep/sundered_keep_approach_blockout.tscn` | Generated scene | The playable blockout. Replace placeholder polygons with authored art. |

## Production Art Assets Required

After the blockout is validated, replace placeholder polygons with these:

| Path | Purpose |
|------|---------|
| `custodian/assets/backgrounds/sundered_keep/approach_ocean_underlay.png` | Ocean/underlay background |
| `custodian/assets/backgrounds/sundered_keep/hilltop_vista_horizon.png` | **Key asset** — fills top half during overlook |
| `custodian/assets/backgrounds/sundered_keep/distant_sundered_keep_matte.png` | Keep silhouette on the horizon |
| `custodian/assets/backgrounds/sundered_keep/vista_fog_band.png` | Fog band hiding the perspective seam |
| `custodian/assets/backgrounds/sundered_keep/traverse_occluder_cliffs.png` | Cliff occluder for lateral traverse |

## Constraints

- Rendering/camera only. No collision, navigation, combat, enemy AI, or deterministic simulation state.
- The camera director expects the approach to flow **north (negative Y)** first, then **east (positive X)**.
- The builder script now instances the operator and wires `.player` automatically. No manual assignment needed after regeneration.
- The director script uses `lerp` with `smoothing_speed` interpolation for all offset/zoom/alpha transitions.
- Generated scene uses Polygon2D placeholders. Replace with authored Texture2D sprites for production.
- `.import` files for runtime PNGs will be generated by Godot on first project open.

## Next Agent Slice

- **Goal:** Tune and validate the Sundered Keep Approach blockout in-editor, then wire unarmed heavy modular animation sheets into the runtime.
- **Files:**
  - `custodian/scenes/levels/sundered_keep/sundered_keep_approach_blockout.tscn` — open in Godot, enable `Camera2D`, walk the operator through all 4 camera states, verify transitions and fog/occlusion alpha blending
  - `custodian/game/actors/operator/operator.gd` — relax `_is_current_profile_unarmed()` guard in `_sync_modular_locomotion_layers()` for locomotion reuse
  - `custodian/tools/pipelines/update_operator_curated_resources.gd` — add unarmed heavy entries
- **Constraint:** Rendering-only for the approach scene. No collision, navigation, combat, enemy AI, or simulation state.
- **Acceptance:** Operator walks the full approach path with smooth camera transitions. Unarmed heavy animations play when no weapon is equipped.

## Future Work

- Replace placeholder polygons with authored underlay/overlay sprite art
- Tune camera smoothing, zoom, and marker positions from playtesting
- Add optional easing curves per state transition
- Integrate into the Sundered Keep approach flow (gate-side exit, not yet connected)
