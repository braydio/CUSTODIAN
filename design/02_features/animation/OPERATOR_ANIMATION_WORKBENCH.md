# Operator Animation Workbench V1

## Status

Implemented editor tooling. Canonical Operator V2 PNGs are authority; Aseprite workbenches are disposable pixel-editing surfaces.

## Authority and boundaries

Canonical source PNGs under `custodian/content/sprites/operator/source/animations/` remain source authority. Runtime PNGs and the generated Operator animation catalog remain generated outputs. Workbenches live outside `res://` in `.ai/operator_animation_workbench/` and never become production assets.

V1 edits pixels only. It cannot change semantic identity, action frame count, source-frame canvas, timing, speed, transitions, direction ownership, hit windows, weapon presentation ownership, or combat simulation. Ambiguous semantic source identity is a hard error. Resolution uses Operator V2 grammar and exact identity; modification time, directory order, filename recency, arbitrary glob selection, and archives never choose authority.

## Workflow

```bash
operator anim list melee_1h --group posture
operator anim status melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger
operator anim edit melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger
operator anim refresh melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger
operator anim publish melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger
```

The manifest records exact repo-relative source/runtime provenance, file and pixel hashes, original frame contracts, centered integer placement, presentation-clock mapping, and the ordered editable-layer whitelist. Lua only assembles and exports workspace data. Python rejects unexpected pixels outside a binding rectangle, validates every candidate before replacement, backs up sources, performs atomic replacement, and invokes production rebuilding.

Publishing edits only the requested authored direction. It never mirrors a counterpart. Unknown helper layers and `__REFERENCE_*` layers never publish. A source changed after assembly makes the session stale; publishing refuses unless the explicit `--force-stale-source` escape hatch is supplied.

## Acceptance

The smoke covers exact extraction after rectangular-canvas placement, illegal outside-rectangle pixels, and current lower/upper/Vigil semantic resolution. Aseprite headless assembly is exercised by the non-destructive edit demo when the executable is available.
