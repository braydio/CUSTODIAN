# Operator Animation Workbench V2

## Status

Implemented editor tooling. Canonical Operator V2 PNGs are authority; Aseprite workbenches are disposable pixel-editing surfaces.

## Authority and boundaries

Canonical source PNGs under `custodian/content/sprites/operator/source/animations/` remain source authority. Runtime PNGs and the generated Operator animation catalog remain generated outputs. Workbenches live outside `res://` in `.ai/operator_animation_workbench/` and never become production assets.

Deterministic agent pixel editing and visual rendering are implemented by the
separate Operator Art Agent V1 above this backend. It may mutate only the
disposable workbench and does not change Workbench publication authority. See
`OPERATOR_ART_AGENT_SYSTEM.md`.

V2 edits pixels, stages explicit frame-count contract migrations, and exposes authored animation-clock timing. Canonical adjacent `.animation.json` sidecars own FPS, loop, and per-frame duration multipliers; publish updates that source sidecar transactionally and generated runtime resources remain projections. It cannot change semantic identity, source-frame canvas, transitions, direction ownership, hit windows, weapon presentation ownership, or combat simulation. Frame commands mutate only the ignored workspace; publish alone replaces canonical frame-count filenames and timing sidecars transactionally. Ambiguous semantic source identity is a hard error. Resolution uses Operator V2 grammar and exact identity; modification time, directory order, filename recency, arbitrary glob selection, and archives never choose authority.

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
service over this backend. Publish always requires a semantic-first, timing-aware
UI review modal: compact direct/mirror operation tables and adjacent mirror
consequences own the decision path, while full canonical paths, retired contracts,
exact timing, and audit/preflight detail remain available on demand. Aseprite
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
status in the selected-layer detail. When a matching Aseprite Live Bridge
document is connected, the table also shows editor visibility/focus state;
these controls are limited to manifest-authorized layers and do not alter the
manifest-complete LIVE preview composition.

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

Publishing edits the requested authored direction and, only when explicitly enabled in the publish review, may promote it to its horizontal counterpart (`e↔w`, `ne↔nw`, `se↔sw`). The option defaults OFF and is unavailable for `n`, `s`, and `omni`. Preview lists direct and mirror targets with CREATE/REPLACE status; replacing authored counterpart art is permitted only by this explicit promotion. Every publishing layer participates while reference/nonpublishing layers remain excluded. Mirroring flips each frame cell independently and reassembles the cells in their original temporal order, never flips the whole strip. Counterpart PNGs and timing sidecars share the direct publish transaction, journal, downstream build, validation, and rollback. The backend constructs counterpart paths through `operator_asset_schema.py`; this flow never uses `asset_drop/inbox`. CLI automation uses `--mirror-counterpart`. A source changed after assembly makes the session stale; publishing refuses unless the explicit `--force-stale-source` escape hatch is supplied.

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
without canonical source mutation.

## V5 production cockpit

`operator ui` has five shared-selection modes: `1` PLAN, `2` WORKBENCH, `3`
PREVIEW, `4` TIMELINE, and `5` MOTION. The implementation plan JSON beside this document is
the only implementation-order authority. Rank, priority, and plan state are
human-authored. Coverage and health are computed annotations; recommendations
may explain a next action but never mutate or reorder authored rank.

Preview is now a first-class review surface. One provider composes semantic
layers for saved Workbench, canonical source, and generated runtime views. It
uses each layer's recorded frame count and rectangular frame dimensions,
centers smaller layers on the largest canvas, and applies one presentation-layer
policy to all three views: modular lower+upper replaces full-body, otherwise
full-body is used, followed by authored head/cape/weapon/FX overlays. Reference
and compatibility duplicates are excluded.

The primary Textual renderer receives the composed PIL RGBA raster directly and
uses TGP or Sixel through `textual-image`. Native 1×, 2×, and 3× modes use only
integer nearest-neighbor replication. AUTO chooses 2× when it fits and otherwise
1×; FIT is visibly labeled as a fitted review representation. Unicode/half-cell
output is a visibly marked LOW-FIDELITY FALLBACK, never the production review
path. Space, arrows, Home/End, brackets, `Z`, and `L` control playback, frame
review, REVIEW FPS, zoom, and looping. REVIEW FPS is disposable presentation
state and never writes gameplay timing or transition authority.

Timeline clips contain only semantic identity, direction, REVIEW FPS, loop
count, and optional inclusive frame trims. Duplicates are legal. Saved sequences
live under `.ai/operator_animation_workbench/sequences/`; clip boundaries are
exact, and sequence JSON is never published to canonical source or runtime.
Enter jumps to the selected clip; I / Shift+I and O / Shift+O edit inclusive
trim edges; brackets edit selected-clip REVIEW FPS; Shift+L cycles clip repeat
count while L loops the whole sequence; arrows navigate flattened source frames;
Ctrl+A appends the current semantic animation; Delete removes; Ctrl+Up/Down
reorders; and Ctrl+S/Ctrl+O save/load the `.ai` review sequence. These are
disposable review controls and never mutate source art, gameplay timing, or the
Aseprite document.
WorkbenchService remains the exclusive UI/backend boundary. Saved-workbench
preview exports are keyed by the `.aseprite` SHA under the ignored workspace,
so a changed saved workbench cannot reuse an earlier export.

### Clipboard reference export

The selected semantic animation can be copied as an exact native-resolution
transparent horizontal PNG with `Y`. `Shift+Y` cycles `BODY`, `FX ONLY`, and
`BODY + FX`; the mode is process-local and shown in the contextual key bar.
The export prefers a matching live unsaved Workbench document, then saved
Workbench/canonical/runtime sources, and also writes the exact bytes beneath
`.ai/operator_animation_workbench/clipboard/`. Wayland uses `wl-copy --type
image/png`; X11 falls back to `xclip`. Missing providers are reported with the
cache path rather than claimed as a successful copy. `Shift+U` reveals or hides
reachability-classified `SUPERSEDED` browser rows; preserved source art is not
deleted. Aseprite failures retain their useful script error in the Workbench
error dialog.

The persistent Aseprite channel is independently specified in
`OPERATOR_ASEPRITE_LIVE_BRIDGE.md`. The UI owns its stable loopback server
lifecycle and truthfully reports waiting/connected/unavailable state. Manual
PREVIEW frame navigation synchronizes with the matching disposable Aseprite
document. WORKBENCH-source PREVIEW prefers a revision-guarded render of its
unsaved manifest-whitelisted pixels, with saved Workbench fallback. Playback,
TIMELINE, MOTION, and semantic document following do not drive the bridge.
Art Agent coexistence is revision-locked when the exact Workbench is open in
Aseprite: reads rebase to current in-memory pixels, mutations remain unsaved
and advance one live revision per operation, and `undo_last` uses Aseprite
undo rather than restoring a disk backup. Human edits invalidate Art Agent
mutation/undo authority; unknown live outcomes close the session fail-closed.
When no matching live document is open, the legacy headless Art Agent path
remains available.
