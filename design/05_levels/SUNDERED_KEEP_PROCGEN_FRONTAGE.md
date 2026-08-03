# Sundered Keep Procgen Frontage

- **Status:** debug-only / archived experiment
- **Owner:** retained Sundered Keep procgen frontage debug tooling
- **Runtime:** `custodian/` Godot 4.x
- **Last updated:** 2026-08-03

## Production Boundary

The generated frontage, its large distant-reveal presentation, and its
`sundered_keep_frontage` ascent-field authority are not production content.
They are retained only behind explicit debug exports for controlled comparison.

Production traversal is:

```text
ordinary generated campaign terrain
-> compact walkable Sundered Keep ingress pocket
-> ordinary fade
-> authored Sundered Keep Vista Approach
-> ordinary fade
-> Sundered Keep Front Gate
```

## Production Procgen Ownership

Procgen owns only:

- ordinary generated terrain;
- a compact walkable ingress pocket when no suitable north-edge overlook
  already exists;
- registered route ingress placement.

The ingress uses the `north_edge_overlook` strategy on valid generated floor.
It starts the `sundered_keep` route with the `production` profile. Production
continues to enter `sundered_keep_vista_approach`; it must not bypass that
authored level by selecting the direct-keep debug edge.

Procgen does not own Sundered Keep ocean, storm, fortress, reveal-camera,
route-master, authored collision, enemy, foliage, or set-dressing content.
Ordinary procgen collision, enemies, foliage, and props remain confined to the
live generated world and are isolated while the authored route is active.

## Archived Experiment

The retained frontage builder can still generate route, terrace, cliff,
camera, clearance, and landmark metadata for debug comparison. It is gated by:

```text
ProcGenMap.debug_enable_sundered_keep_procgen_frontage
ContractWorldLoader.debug_spawn_sundered_keep_procgen_vista
```

Both exports default to `false` and are explicitly `false` in their production
scene owners. Production must neither merge frontage cells into `ASCENT_FIELD`
nor instantiate `SunderedKeepProcgenFrontagePresentation` under
`WorldLandmarks`.

Presentation art never owns playable ground, collision, or navigation. Do not
make this experiment production-safe by adding ocean collision, changing draw
order, or selectively hiding generated actors.

## Lifecycle

`WorldIngressSite` remains the transition authority. It captures and isolates
all `world_origin_branch` nodes, including `ProcGenRuntime`, starts the
registered route, and restores world visibility, processing, Operator state,
camera follow, and presentation bounds on return or entry failure.

## Validation

Run from the repository root:

```bash
env HOME=/tmp/custodian-godot-home godot --headless --path custodian --import --quit
env HOME=/tmp/custodian-godot-home godot --headless --path custodian \
  --script res://tools/validation/sundered_keep_procgen_vista_isolation_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path custodian \
  --script res://tools/validation/sundered_keep_ingress_smoke.gd
```

Acceptance requires ordinary procgen terrain before entry, no generated Keep
presentation in the procgen branches, a production ingress on valid floor,
exclusive authored-vista ownership during traversal, usable authored boundary
rails, and exact world/camera restoration on exit or failure.

## Next Agent Slice

Keep the archived builder and presentation debug-only. Any future work on the
production arrival belongs in the compact ingress-pocket resolver or the
authored Vista Approach, without restoring frontage ownership to procgen.
