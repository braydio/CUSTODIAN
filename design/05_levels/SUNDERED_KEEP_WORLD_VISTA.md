# Sundered Keep World Vista

- **Status:** production
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
`SunderedKeepIngressSite` position and nearest map boundary.

The Vista:

- never starts `RouteTraversalManager`;
- never stages a level through `LevelLoader`;
- never hides or disables `ProcGenRuntime`;
- never reparents, teleports, or movement-locks the Operator;
- owns no route, combat, navigation, or collision authority;
- temporarily drives the existing shared `Camera2D`;
- reverses solely from the Operator's physical position.

The nearby `WorldIngressSite` remains the actual level boundary. Crossing it
uses the production `enter_keep` edge and a short fade directly into
`front_gate`.

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

The first pass reuses the approved first-Vista storm horizon, isolated Keep,
reveal veil, and overlook-ledge art. It does not include close fortress planes,
Grand Vista architecture, roof fades, a second reveal, or a playable Vista
route.

## Camera Envelope

The control points are laid out relative to the ingress, inward from the
nearest map boundary. Both enter and return progress are projected from the
Operator's current position:

```gdscript
camera_weight = smootherstep(enter_progress) \
	* (1.0 - smootherstep(return_progress))
```

At nonzero weight, the Vista follows a presentation anchor interpolated
between the Operator and cinematic focal point. Framing blends from
`zoom=(0.90, 0.90)` to `(0.78, 0.78)` with a `(0, -120)` cinematic offset.
The Vista supplies a temporary presentation-bounds override and releases both
follow and bounds authority at zero weight.

Camera visible coverage is calculated by dividing viewport half-size by zoom.
A zoom below `1.0` sees more world and therefore requires larger safe bounds.

## Visual Contract

- Storm horizon: absolute `z=-300`, scroll scale `(0.02, 0.01)`.
- Distant Keep: absolute `z=-250`, scroll scale `(0.08, 0.03)`.
- Reveal fog: absolute `z=-200`, scroll scale `(0.18, 0.08)`.
- Foreground lip: absolute `z=100`, world-relative overlook occlusion.
- Keep alpha grows from `0.08` to `0.92`.
- Fog thins from `0.68` to `0.26` and peels only about 121 px.

## Route Profiles

Production and `debug_direct_keep` use only:

```text
@world_origin -> front_gate -> @world_origin
```

The former authored approach is retained under `legacy_vista_debug` for
debugging and historical validation. Return Causeway remains isolated under
`causeway_only`.

## Validation

Run:

```bash
cd custodian
godot --headless --path . \
  --script res://tools/validation/sundered_keep_world_vista_smoke.gd
godot --headless --path . \
  --script res://tools/validation/sundered_keep_ingress_smoke.gd
bash tools/validation/run_route_pipeline_suite.sh
```

The focused Vista smoke proves physical forward/reverse camera behavior,
procgen/Operator/ingress continuity, absence of collision and Grand Vista
content, temporary bounds ownership, and correct zoomed-out coverage math.

## Next Agent Slice

Goal: review final placement and composition in several real procgen seeds.

Files: this scene/script and the existing world-Vista background assets.

Constraints: preserve the single envelope, direct Front Gate production route,
world continuity, and collision-free presentation ownership.

Acceptance: the overlook points outward at every supported map edge, the
Operator remains in the lower quarter at apex, the Keep is readable without
becoming a replacement skyline, and no camera frame exposes engine clear color.
