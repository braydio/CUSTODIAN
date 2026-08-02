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
  temporary Operator placement/process/Z state, 176 px lift travel, 384 px
  shaft scroll, staged cave-lip occlusion, and reusable reset.
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
  -> snap Operator to RiderAnchor
  -> vibrate platform + burst dust
  -> move lift and Operator downward
  -> scroll shaft upward behind them
  -> Operator crosses behind the foreground lip after entering the shaft
  -> restore temporary Operator process/Z state
  -> start existing fade route
  -> load Underground at Spawn_DescentLanding
```

Return restoration uses the pre-descent snapshot, then reverses the lift travel
so the live Operator rises from behind the lip onto the parked platform. The
occluder is between the platform and rider instead of above the entire modular
Operator. Reset restores the parked lift, shaft region, idle platform, and dust
frame so the ingress can be used again after the Operator exits its trigger overlap.

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
