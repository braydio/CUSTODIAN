# Ash Bell Lift Ingress Presentation

Status: implemented V1
Owner: world presentation / authored-level ingress
Runtime target: Godot 4 (`custodian/`)

## Purpose

The Empty Bell entrance uses a surface-side lift descent and return ascent around the existing
fade into the Forlorn Ritualant Underground. The presentation belongs to the
generated `WorldIngressSite`; it is not part of
`forlorn_ritualant_underground.tscn`, whose `Spawn_DescentLanding` remains at
`(0, 224)`.

## Runtime ownership

- `ash_bell_lift_ingress_presentation.tscn` owns the surface cave shell,
  scrolling shaft, two chains, lift, dust, lamp, foreground occluder, and local
  cliff collision.
- `ash_bell_lift_ingress_presentation.gd` owns the 1.05-second travel presentation,
  detached rider-puppet lifecycle, 176 px lift travel, 384 px shaft scroll,
  staged cave-lip occlusion, and reusable reset.
- `operator_presentation_rig_2d.tscn` is a reusable visual-only snapshot rig.
  It clones the Operator's currently visible body/equipment presentation leaves
  without copying gameplay scripts, collision, input, health, or inventory.
- `ash_bell_lift_ingress_site.gd` specializes only the
  `forlorn_ritualant_underground` world ingress.
- `WorldIngressSite` captures the origin snapshot before awaiting an optional
  entry presentation. Route start and its existing fade happen afterward.
- `WorldIngressSpawner` selects the specialized site by exact route identity;
  every other route retains the generic ingress.

## Sequence contract

```text
surface trigger
  -> capture origin snapshot
  -> explicit Interact: TRAVERSE THE DERELICT LIFT
  -> capture visible Operator presentation into detached rider puppet
  -> hide live Operator visual leaves without moving its CharacterBody2D
  -> attach puppet to RiderAnchor in a restrained lift-braced pose
  -> vibrate platform + burst dust
  -> move lift and puppet downward
  -> scroll shaft upward behind them
  -> puppet crosses behind the foreground lip after entering the shaft
  -> free puppet and restore live Operator visual leaves
  -> start existing fade route
  -> load Underground at Spawn_DescentLanding
```

Return restoration uses the pre-descent snapshot, leaving the live Operator at
the captured surface position. A second detached puppet begins on the lowered
lift, rises through the staged cave-lip occlusion, and is freed before the live
visual leaves are restored. The live CharacterBody2D position, process mode,
and Z state are never changed by either presentation. Cancellation, failed
capture, teardown, and ordinary completion all restore the recorded visibility
state. The return ingress guard tracks the restored Operator's actual distance
and ignores synthetic `body_exited` signals caused by rebuilding Area2D
monitoring, so descent cannot immediately retrigger.

The specialized Ash Bell ingress is an explicit `interactable`; entering its
Area2D does not begin traversal. Generic world ingresses retain their existing
body-entry behavior.

## Art and import contract

Runtime art lives under
`custodian/assets/sprites/world/ingress/ash_bell/`; source generations are
preserved under `source/generated/`. Runtime PNGs use exact filename
dimensions, alpha outside isolated sprites, lossless compression, no mipmaps,
and nearest CanvasItem filtering. The shaft uses enabled texture repeat and a
mirrored vertical construction to reduce the scrolling seam. The static
entrance shell contains no lift platform or active lamp.

## Validation

```bash
godot --headless --path custodian --import --quit
godot --headless --path custodian \
  --script res://tools/validation/ash_bell_lift_ingress_presentation_smoke.gd
godot --headless --path custodian \
  --script res://tools/validation/levels/forlorn_ritualant_underground_smoke.gd
godot --headless --path custodian \
  --script res://tools/validation/world_ingress_physics_reentry_smoke.gd
godot --headless --path custodian \
  --script res://tools/validation/authored_level_ingress_return_smoke.gd
```

The focused smoke verifies asset dimensions/import settings, animation
contracts, node placement/Z, actor-state restoration, reset, snapshot ordering,
and specialized spawner selection.
