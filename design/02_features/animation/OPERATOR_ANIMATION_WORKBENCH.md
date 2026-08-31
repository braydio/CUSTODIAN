# Operator Animation Workbench V2

## Status

Implemented editor tooling. Canonical Operator V2 PNGs are authority; Aseprite workbenches are disposable pixel-editing surfaces.

## Authority and boundaries

Canonical source PNGs under `custodian/content/sprites/operator/source/animations/` remain source authority. Runtime PNGs and the generated Operator animation catalog remain generated outputs. Workbenches live outside `res://` in `.ai/operator_animation_workbench/` and never become production assets.

Deterministic agent pixel editing and visual rendering are implemented by the
separate Operator Art Agent V1 above this backend. It may mutate only the
disposable workbench and does not change Workbench publication authority. See
`OPERATOR_ART_AGENT_SYSTEM.md`.

V2 edits pixels and stages explicit frame-count contract migrations. It cannot change semantic identity, source-frame canvas, timing, speed, transitions, direction ownership, hit windows, weapon presentation ownership, or combat simulation. Frame commands mutate only the ignored workspace; publish alone replaces canonical frame-count filenames transactionally. Ambiguous semantic source identity is a hard error. Resolution uses Operator V2 grammar and exact identity; modification time, directory order, filename recency, arbitrary glob selection, and archives never choose authority.

## Workflow

The preferred interactive front door is `operator ui`. It is an optional
Textual control surface beside the scriptable CLI, not a wrapper around it:

```text
                    operator anim CLI
                   /
Workbench V2 APIs
                   \
                    operator ui TUI → Aseprite
```

The UI holds only selection, presentation, activity, process handles, and an
operation lock. It resolves source/session state, migrations, publish dry-runs,
weapon metadata, validation, and transaction progress through one structured
service over this backend. Publish always requires a UI review modal. Aseprite
launch is nonblocking and publishing explicitly uses the last saved document.
Textual is isolated to `tools/operator/ui/requirements.txt`; its absence must
not affect any command below.

The browser has exactly one node per semantic profile/group/action and one leaf
per direction. Only selected ancestry expands automatically; manual expansion
survives ordinary refresh. Directional rows project canonical presentation
completeness: synchronized lower+upper and valid full-body sources are COMPLETE,
while weapon-only, FX-only, and isolated fragments are PARTIAL and remain
available for audit. The primary layer view is deliberately compact—layer,
source/workspace/publish contract, and canvas—with role/owner/profile/reference
status in the selected-layer detail.

Persistent shell widgets belong to the retained main screen, not whichever
modal is currently topmost. Activity events always append to UI state and the
underlying main-screen log while dialogs are open. A failed session projection
must preserve its exact Workbench error, open at most one error dialog, and
must not report the semantic selection as successfully loaded.

```bash
operator ui
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

## Compatibility SpriteFrames boundary

`operator.tscn` still consumes ten generated compatibility `SpriteFrames`
resources directly. They preserve legacy animation aliases such as
`unarmed_run_right`, but their texture paths are generated projections rather
than source authority. After the strict runtime build, publish runs:

```bash
python3 custodian/tools/pipelines/update_operator_compatibility_resources.py
```

This path-first generator resolves current strips from the semantic V2 catalog,
updates safe full-strip aliases and their exact `AtlasTexture` frame count, and
does not rewrite manually sliced or weapon-owned mappings. It also refreshes
the catalog `.tres` paths before Godot import, avoiding a stale-resource load
cycle. `--check` fails with `STALE OPERATOR SPRITEFRAMES RESOURCE` before actor
smokes when any Operator runtime PNG reference is missing.

Publish transactions back up all ten compatibility resources plus the catalog
resource and journal old/new SHA-256 values. Rollback removes target PNG import
sidecars, restores the old source and resource contracts, rebuilds the old
runtime/catalog, runs the stale-path check, and proves `operator.tscn` loads via
the modular-layer smoke. Failure of that recovery becomes `RECOVERY_REQUIRED`.

## Acceptance

The smoke covers exact extraction after rectangular-canvas placement, illegal outside-rectangle pixels, and current lower/upper/Vigil semantic resolution. Aseprite headless assembly is exercised by the non-destructive edit demo when the executable is available.

`operator_workbench_ui_smoke.py` exercises browser/session/context/error
projections without a terminal, then uses Textual's headless pilot when the
optional dependency is installed. It proves search, six-frame run detail,
add-frame dry-run review/cancel, publish review/cancel, modal-safe activity
logging, and exact Workbench-error survival after failed session loading,
without canonical source mutation. Image rendering and an embedded sprite
editor are deliberate V1 deferrals; a future preview adapter may target Kitty,
chafa, contact sheets, or Aseprite without changing the service/provider
boundary.
