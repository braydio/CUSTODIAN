# Sundered Keep World Vista

> **Superseded production authority (2026-07-30):** see
> `design/05_levels/SUNDERED_KEEP_VISTA_APPROACH.md`. The nine-tile authored
> overlook pocket and cliff-lip-as-map-seam design below are retained only as
> implementation history. Production now requires an intent-graph-owned
> procgen landmark region with authored visual identity and a generated
> terminal transition to Front Gate.

- **Status:** superseded — historical World Vista V1
- **Owner:** generated world landmark presentation / shared camera
- **Runtime:** `custodian/` Godot 4.x
- **Scene:** `custodian/game/world/vistas/sundered_keep/sundered_keep_world_vista.tscn`

## Purpose

While the Operator is still exploring the generated campaign world, reaching
the Sundered Keep overlook composes one memorable horizon shot of the distant
Keep. This is a world-map landmark feature, not an authored route node.

The generated world, storm horizon, Operator, and nearby terrain remain the
same world throughout the reveal. The Keep appears by atmospheric occlusion
removal; the reveal never swaps in a separate prestige level.

## Ownership

`ContractWorldLoader` creates one `WorldLandmarks` branch after registered
ingresses are placed. The branch belongs to `world_origin_branch`, and the
Sundered Keep Vista is configured from the generated
`SunderedKeepIngressSite` position. The ingress resolver fixes this landmark
to a north-edge overlook, and the spawner passes that authored orientation to
the Vista rather than asking the presentation to infer a boundary.

Every resolved north-edge overlook claims the same nine-tile-wide,
collision- and prop-cleared `world_overlook_floor` pocket, including seeds
whose natural centerline was already walkable. Natural walkability may select
the best attachment point, but it is never treated as sufficient cinematic
separation. This keeps the authored approach local to the generated world
instead of loading a replacement scene.

The Vista:

- never starts `RouteTraversalManager`;
- never stages a level through `LevelLoader`;
- never hides or disables `ProcGenRuntime`;
- never reparents, teleports, or movement-locks the Operator;
- owns no route, combat, navigation, or collision authority;
- temporarily drives the existing shared `Camera2D`;
- reverses solely from the Operator's physical position.

The nearby `WorldIngressSite` remains the actual level boundary. Crossing it
uses the production `enter_vista` edge and a playable blackout bridge into the
authored Approach and Outskirts. Front Gate is reached later through the beach
mist handoff.

## Scene Contract

```text
SunderedKeepWorldVista
├── HorizonPresentation
│   ├── StormParallax/StormHorizon
│   ├── KeepParallax/DistantKeep
│   └── FogParallax/FogVeil
├── ForegroundCliffLip
├── CameraPresentationAnchor
├── CameraInfluenceStart
├── CameraApex
├── CameraReturnStart
├── CameraReturnComplete
└── VistaController
```

The horizon reuses the approved first-Vista storm plate, isolated Keep, and
reveal veil. `ForegroundCliffLip` uses the dedicated 2048×512
`sundered_keep_world_vista_cliff_lip.png` separator; the former 640×200
playable-route ledge no longer owns viewport framing. The world Vista does not
include close fortress planes, Grand Vista architecture, roof fades, a second
reveal, or a playable Vista route.

## Camera Envelope

The control points are laid out relative to the north-oriented ingress. Both
enter and return progress are projected from the Operator's current position:

```gdscript
camera_weight = smootherstep(enter_progress) \
	* (1.0 - smootherstep(return_progress))
```

At nonzero weight, the Vista follows a presentation anchor interpolated
between the Operator and cinematic focal point. Framing blends from
`zoom=(0.90, 0.90)` to `(0.78, 0.78)` with a `(0, -120)` cinematic offset.
The Vista supplies a temporary presentation-bounds override and releases both
follow and bounds authority at zero weight.

Camera visible coverage is calculated by dividing viewport size by zoom. A
zoom below `1.0` sees more world and therefore requires larger safe bounds.
The Vista refits its storm region, cliff-lip horizontal scale, and presentation
bounds from the live viewport at layout time and whenever viewport size
changes.

## Visual Contract

- Storm aperture: fixed world-local plane, absolute `z=40`, restricted to a
  minimum `2600×1200` upper-frame region and widened when live cinematic
  viewport coverage requires it.
- Distant Keep: fixed world-local plane, absolute `z=50`.
- Reveal fog: fixed world-local plane, absolute `z=60`.
- Foreground cliff lip: absolute `z=80`, scaled to cover the live cinematic
  viewport width plus 192 world pixels of horizontal safety.
- These four planes are spatially limited to the overlook composition. They
  visually cover distant procgen and the outer-map seam without covering the
  Operator's immediate approach.
- Keep alpha grows from `0.08` to `0.92`.
- Fog thins from `0.68` to `0.26` and peels only about 121 px.
- The parent `HorizonPresentation` owns the common reveal alpha. The storm
  child remains at alpha `1.0`, preventing an accidental `reveal²` fade;
  Keep and fog retain intentional independent child modulation.

## Route Profiles

Production and `debug_direct_keep` use only:

```text
@world_origin -> front_gate -> @world_origin
```

The authored approach is the production route node. Return Causeway remains
isolated under `causeway_only`.

## Validation

Run:

```bash
cd custodian
godot --headless --path . \
  --script res://tools/validation/sundered_keep_world_vista_smoke.gd
godot --headless --path . \
  --script res://tools/validation/sundered_keep_ingress_smoke.gd
bash tools/validation/run_route_pipeline_suite.sh
godot --display-driver x11 --rendering-driver opengl3 \
  --audio-driver Dummy --path . \
  --script res://tools/validation/sundered_keep_world_vista_seed_review.gd
```

The focused Vista smoke proves physical forward/reverse camera behavior,
procgen/Operator/ingress continuity, absence of collision and Grand Vista
content, north orientation and edge distance, positive-z aperture ownership,
foreground-separator dimensions, mandatory natural-corridor pocket claims,
temporary bounds ownership, 2560×1440 dynamic fitting, single-parent storm
reveal, and correct zoomed-out coverage math. The renderer-backed seed review
requires an authored pocket for every seed, generates eight production-sized
procgen maps, and saves apex captures plus a manifest under
`reports/sundered_keep_world_vista/`; every successful entry must record
`"authored_pocket": true`.

The 2026-07-27 structural regeneration passed all eight seeds, but the human
composition pass did not approve the captures yet. The current fog veil exposes
a rectangular image boundary, and the seed-review fixture uses a non-rendered
Operator stand-in, so it cannot prove the lower-quarter Operator framing
requirement. Those are review/tuning defects, not reasons to weaken the
mandatory pocket contract.

## Next Agent Slice

Goal: remove the visible fog-veil boundary, give the renderer-backed review
fixture a visible Operator stand-in, regenerate the eight apex captures, and
complete human composition approval.

Files: this scene/script and the existing world-Vista background assets.

Constraints: preserve the single envelope, direct Front Gate production route,
world continuity, and collision-free presentation ownership.

Acceptance: the north overlook remains readable across production seeds, the
Operator remains in the lower quarter at apex, the Keep is readable without
becoming a replacement skyline, and no camera frame exposes engine clear
color, aperture/veil image boundaries, or procgen masses above the cliff lip.
