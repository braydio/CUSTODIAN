# Operator Animation Workbench V2

## Status

Implemented editor tooling. Canonical Operator V2 PNGs are authority; Aseprite workbenches are disposable pixel-editing surfaces.

## Authority and boundaries

Canonical source PNGs under `custodian/content/sprites/operator/source/animations/` remain source authority. Runtime PNGs and the generated Operator animation catalog remain generated outputs. Workbenches live outside `res://` in `.ai/operator_animation_workbench/` and never become production assets.

V2 edits pixels and stages explicit frame-count contract migrations. It cannot change semantic identity, source-frame canvas, timing, speed, transitions, direction ownership, hit windows, weapon presentation ownership, or combat simulation. Frame commands mutate only the ignored workspace; publish alone replaces canonical frame-count filenames transactionally. Ambiguous semantic source identity is a hard error. Resolution uses Operator V2 grammar and exact identity; modification time, directory order, filename recency, arbitrary glob selection, and archives never choose authority.

## Workflow

```bash
operator anim list melee_1h --group posture
operator anim status melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger
operator anim edit melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger
operator anim refresh melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger
operator anim publish melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger
operator anim frame add melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger --after 2
operator anim frame remove melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger --frame 3
```

The manifest records exact repo-relative source/runtime provenance, file and pixel hashes, original frame contracts, centered integer placement, presentation-clock mapping, and the ordered editable-layer whitelist. Lua only assembles and exports workspace data. Python rejects unexpected pixels outside a binding rectangle, validates every candidate before replacement, backs up sources, performs atomic replacement, and invokes production rebuilding.

Publishing edits only the requested authored direction. It never mirrors a counterpart. Unknown helper layers and `__REFERENCE_*` layers never publish. A source changed after assembly makes the session stale; publishing refuses unless the explicit `--force-stale-source` escape hatch is supplied.

## Frame-contract migration

The V2 manifest separately records canonical `source_contract`, current
`workspace_contract`, proposed `publish_contract`, explicit timeline slots,
primary source/workspace clocks, and global document frames. Automatic
migration includes synchronized lower+upper (or full body), matching-clock
head/cape, and the exact requested matching-clock authored weapon. FX and a
concurrent full-body reference remain unchanged unless explicitly selected.

Before staging and again before publish, dependency auditing checks weapon
gameplay frame fields, melee hit-window profiles, and per-frame socket tracks.
GREEN migrations proceed; YELLOW presentation dependencies and RED gameplay
dependencies fail closed. Frame commands export current saved workspace pixels,
stage exact strip transforms, reassemble Aseprite, and record a pending
migration. Publish journals the source swap and rolls source/runtime/import/
resource state back if any mandatory downstream stage fails.

## Acceptance

The smoke covers exact extraction after rectangular-canvas placement, illegal outside-rectangle pixels, and current lower/upper/Vigil semantic resolution. Aseprite headless assembly is exercised by the non-destructive edit demo when the executable is available.
