# Operator Animation Workbench Motion Lab V5

## Status

Implementation contract for parity between the Workbench Motion Lab raster
preview and its Godot runtime calibration harness.

## Authority and boundaries

Motion Lab is disposable presentation tooling. It does not author animation
pixels, rotate or fabricate directional art, publish timing, or own gameplay
movement. Cardinal heading changes resolve real sibling N/E/S/W variants of the
current profile/group/action. Canonical Operator PNGs and generated runtime
SpriteFrames remain governed by the main Operator Animation Workbench contract.

The shared ground registry is
`custodian/tools/operator/motion_ground_presets.json`. Python and Godot resolve
the same preset IDs and repo-relative textures; unavailable textures fall back
to the 32 px review grid with an explicit warning.

## Motion contract

- Requested review FPS drives an elapsed-time animation clock in Preview,
  Timeline, and Motion; the UI refresh interval never quantizes the requested
  rate.
- Each animation cycle traverses the configured root distance and curve.
- Looping defaults to three cycles; selectable spans are 2, 3, 4, 6, and 8.
- Animation phase wraps every cycle while cumulative root/world displacement
  wraps only after the configured cycle span.
- Non-looping playback performs one traversal and stops at its terminal pose.
- Presentation output separates `world_offset` from `actor_screen_offset`.
  TREADMILL fixes the actor to the anchor (`actor_screen_offset == ZERO`) and
  scrolls the world immediately; renderers never add world offset to the actor.
- WORLD allows a 96 px actor lead, then follows with the camera while absolute
  cumulative travel continues.
- Absolute ruler ticks are derived from the visible viewport at 32 px spacing;
  they are not bounded to a fixed distance window.
- Runtime requests use `custodian.operator_motion_request.v2` and carry loop,
  loop-cycle, ground, mode, curve, travel, FPS, and exact semantic direction.

## Acceptance

Pure Python validation proves multi-cycle travel/reset, cardinal vectors,
WORLD camera follow, viewport-derived rulers, shared ground IDs, and read-only
raster composition. The Textual smoke proves heading selection, shared ground
cycling, configurable cycle span, full-span scrubbing, bounded playback wrap,
and V2 runtime launch. The Godot smoke proves request parsing, shared ground
loading, requested-FPS frame sampling, three-cycle reset, and treadmill/WORLD
offset parity.
