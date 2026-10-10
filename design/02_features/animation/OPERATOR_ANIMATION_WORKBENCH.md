# Operator Animation Workbench V2

## Status

Implemented editor tooling. Canonical Operator V2 PNGs are authority; Aseprite workbenches are disposable pixel-editing surfaces. Interactive OPUI authoring runs from a dedicated persistent art worktree, and its reviewed Publish to Main action handles validation, commit, and safe landing.

## Authority and boundaries

Canonical source PNGs under `custodian/content/sprites/operator/source/animations/` remain source authority. Runtime PNGs and the generated Operator animation catalog remain generated outputs. Normal `opui` launch ensures the persistent `workbench/operator-art` checkout beside the coordination checkout and runs the UI code there while reusing the coordination checkout's ignored UI virtual environment. Workbenches live outside `res://` in that art checkout's `.ai/operator_animation_workbench/` and never become production assets. The coordination `main` checkout is not a tracked-publish authority; direct OPUI launch there leaves editing and preview available but disables tracked publish.

Deterministic agent pixel editing and visual rendering are implemented by the
separate Operator Art Agent V1 above this backend. It may mutate only the
disposable workbench and does not change Workbench publication authority. See
`OPERATOR_ART_AGENT_SYSTEM.md`.

V2 edits pixels, stages explicit frame-count and frame-canvas contract migrations, and exposes authored animation-clock timing. Canonical adjacent `.animation.json` sidecars own FPS, loop, and per-frame duration multipliers; publish updates that source sidecar transactionally and generated runtime resources remain projections. It cannot change semantic identity, transitions, direction ownership, hit windows, weapon presentation ownership, or combat simulation. Contract commands mutate only the ignored workspace; publish alone replaces canonical contract filenames and timing sidecars transactionally. Ambiguous semantic source identity is a hard error. Resolution uses Operator V2 grammar and exact identity; modification time, directory order, filename recency, arbitrary glob selection, and archives never choose authority.

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

The review modal's `PUBLISH TO MAIN` action performs the Workbench transaction
once, verifies the resulting Git change set against the selected Operator
publication paths, stages only those paths, creates one deterministic commit,
and invokes `custodian/tools/agent/land_main.py`. A same-asset change already
present on `origin/main` blocks before canonical files are replaced; unrelated
upstream changes remain eligible for the existing landing authority. A failed
landing leaves a clean committed art branch and an ignored `LAND PENDING`
receipt. Reopening Publish for the same semantic animation retries that commit
without re-exporting pixels. After landing, OPUI refreshes the selected browser
state and best-effort syncs a clean coordination `main` checkout. Local
coordination changes are preserved and shown as a pending sync.

On first launch, the art checkout is created automatically. If the older
coordination checkout has ignored Workbench files and the art checkout has no
Workbench state, OPUI copies that state once, preserves the original copy, and
rewrites checkout-root paths in JSON manifests. Migration pauses while an
Aseprite process is open. Tracked coordination changes are never copied into
the art checkout; the launcher reports them for explicit recovery. LFS-backed
Operator source/runtime art is hydrated only during explicit Publish
preparation, without an implicit network fetch. Opening OPUI over an existing
art checkout is read-only and mounts even when publication is blocked. The
Publish review first projects structured checkout identity, branch relation,
pending land/transaction state, dirty path classes, sparse health, checked-out
dependency materialization, and selected source-contract freshness. It may
prepare only a clean fast-forward, reapply the authored sparse profile, and
hydrate exact checked-out LFS paths from the local object cache or a same-path
coordination checkout file whose SHA-256 and byte size match the target LFS
pointer. It never fetches LFS, stashes, rebases, resets, cleans, or erases user
changes. Final confirmation rechecks readiness immediately before canonical
mutation.

Before normal OPUI authoring starts, the launcher attempts a bounded safe sync
of the persistent coordination `main` checkout and the identified Operator art
checkout through the shared persistent-checkout sync authority. Clean,
behind-only checkouts fast-forward automatically. Dirty, ahead, diverged,
wrong-branch, pending/recovery, or Aseprite-open states are left byte-for-byte
intact; OPUI still mounts and the exact blocker is shown in its checkout status.
The `csync`, `csync root`, `csync art`, `csync status`, and `opui-sync` shell
commands route through the same authority. Its inspect mode does not fetch or
mutate Git state.

The persistent art worktree uses the worktree-local `operator-authoring-v1`
sparse profile. It includes repository Git hooks and their required
`tools/validate_filenames.py` pre-commit dependency so Operator art commits
execute the cross-platform filename gate inside the art checkout. It keeps Operator authoring tools, the tested Godot/game and
validation dependencies, canonical Operator art/data, Operator-owned weapon
art, and the Workbench plan while leaving reports, asset-drop material, and
unrelated large art trees out of the checkout. Ordinary coordination worktrees
remain full-tree. Startup synchronization and explicit Publish preparation
both fast-forward only a clean art branch with no pending landing and no local
commits ahead. Dirty,
ahead, diverged, and `LAND PENDING` states are preserved and shown in the
status line. Safe synchronization reapplies the profile and retains ignored
`.ai/operator_animation_workbench` files byte-for-byte. A dirty full-tree
checkout fails closed before sparse migration so tracked or untracked work is
not removed.

`LAND PENDING` receipts record a stable changed-path and before/after blob
identity. If a harmless history rewrite changes the candidate commit ID, retry
relinks only when that identity matches exactly; added, missing, or changed
publication paths remain blocked. Saved Aseprite frame count, canvas, and
uniform preview timing are checked before Edit/Publish. A stale pending frame
migration can be reconciled in manifest metadata only when the saved document
still matches the source/workspace contract; both document and manifest are
backed up and a local receipt records the proof. Other mismatches preserve the
document and require the explicit migration flow. A failed publish records
primary and recovery failures separately. `ROLLED_BACK` is written only after
source, generated resource, tracked import metadata, saved document, and Git
cleanliness preimages are verified; otherwise `RECOVERY_REQUIRED` retains the
unresolved paths.

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

Browser discovery runs as a side-effect-free candidate operation. One immutable,
unfiltered snapshot in `WorkbenchUIState` is the accepted browser-record authority;
Search and superseded visibility are pure projections of that snapshot and do
not scan the filesystem or change the selected Workbench session. Refreshes use
monotonic request generations for discovery and browser-owned session projection,
so an older scan or session cannot overwrite a newer accepted candidate. Candidate
browser/tree state is committed only after its selected session projection succeeds;
a failed replacement preserves the previous coherent snapshot and selection.
Destructive candidates are confirmed by
bounded semantic rescans; missing identities and incomplete modular body-clock
migrations keep the last accepted snapshot until stable. Selection survives
Search and accepted refreshes while its semantic identity remains present.

Page-3 PREVIEW asynchronous work uses a separate generation bound to semantic
selection, source, and mode. Preview, comparison, transition, and Live Bridge
results are discarded when their generation is stale. Asynchronous Live Bridge
export commands carry their originating preview generation and semantic selection
through the command cause sequence to result application. Each result carries an
immutable issue-time token for the connected bridge generation, client session,
active Workbench path, and requested revision. The current token must still match
after each live-image, comparison, or transition-analysis await and immediately
before applying preview state. Disconnect preserves last-known document metadata
for presentation while invalidating its ownership token; reconnecting to the same
path and revision does not authorize a result from the previous connection.
Synchronous F5 live export/load uses the same token and falls back to the saved
Workbench preview when it remains valid.
F5 keeps the last usable preview visible while browser/session state and a coherent
replacement preview are prepared, then applies the replacement and restores prior
playback intent only when the same semantic preview remains valid. Refresh requests during
canonical PUBLISH mutation are coalesced and run once after publication ends.

Persistent shell widgets belong to the retained main screen, not whichever
modal is currently topmost. Activity events always append to UI state and the
underlying main-screen log while dialogs are open. A failed session projection
must preserve its exact Workbench error, open at most one error dialog, and
must not report the semantic selection as successfully loaded. Error dialogs focus
the Close button and dismiss with Escape, Enter, or Close. Preview and motion
playback clocks pause while an error dialog is open, without accumulating
catch-up time. A stale-edit refusal never launches Aseprite or replaces saved
Workbench pixels.

```bash
operator ui
operator anim list melee_1h --group posture
operator anim status melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger
operator anim edit melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger
operator anim refresh melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger
operator anim publish melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger
operator anim frame add melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger --after 2
operator anim frame remove melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger --frame 3
operator anim canvas resize unarmed fast_02 e --group attack --width 128 --height 128 --scope animation --dry-run
```

The manifest records exact repo-relative source/runtime provenance, file and pixel hashes, original frame contracts, centered integer placement, presentation-clock mapping, and the ordered editable-layer whitelist. Lua only assembles and exports workspace data. Python rejects unexpected pixels outside a binding rectangle, validates every candidate before replacement, backs up sources, performs atomic replacement, and invokes production rebuilding.

Publishing edits the requested authored direction and, only when explicitly enabled in the publish review, may promote it to its horizontal counterpart (`e↔w`, `ne↔nw`, `se↔sw`). The option defaults OFF and is unavailable for `n`, `s`, and `omni`. Preview lists direct and mirror targets with CREATE/REPLACE status; replacing authored counterpart art is permitted only by this explicit promotion. Every publishing layer participates while reference/nonpublishing layers remain excluded. Mirroring flips each frame cell independently and reassembles the cells in their original temporal order, never flips the whole strip. Counterpart PNGs and timing sidecars share the direct publish transaction, journal, downstream build, validation, and rollback. The backend constructs counterpart paths through `operator_asset_schema.py`; this flow never uses `asset_drop/inbox`. CLI automation uses `--mirror-counterpart`. A source changed after assembly makes the session stale; publishing refuses unless the explicit `--force-stale-source` escape hatch is supplied. Non-dry-run `operator anim publish` routes through the same `WorkbenchService.publish` authority as the UI: dedicated `workbench/operator-art` identity, structured readiness/preparation, a final pre-mutation readiness check, and the scoped `publish_to_main` stage/commit/land flow. It fails closed before canonical mutation from coordination `main`, an arbitrary/detached checkout, or a readiness-blocked art checkout. `--force-stale-source` waives only source freshness, never checkout identity, dirty state, dependencies, transactions, or landing. `--dry-run` stays workspace-only.

For an existing semantic animation, a saved top-level Aseprite layer named
`vfx` or `fx` can be explicitly adopted as semantic FX. Adoption remains a
human Workbench action: unbound layers are read-only until selected, unsaved
live layers cannot be adopted, and CREATE/REPLACE publication uses the normal
schema-derived transaction and rollback. No general semantic animation
creation or Art Agent autonomous layer-creation authority is implied.

## V3: new semantic animation creation

Tracked by `custodian/docs/ai_context/task_packets/OPERATOR_WORKBENCH_ANIMATION_CREATION.md`.

**New Animation** extends the same Workbench/publisher rather than creating a
second asset authority. OPUI and `operator anim create` accept a validated
semantic identity, timing contract, and either full-body or synchronized
lower+upper template. They show schema-derived source/runtime CREATE targets,
collision state, and deterministic canonical reference guides before creating
an ignored Aseprite session. No canonical PNG is written until explicit
Publish. Saved-workbench Preview supports review before publication. The
publisher uses the existing guarded transaction, strict Operator runtime sync,
Godot import preflight/import, SpriteFrames/catalog rebuild, focused validation,
and isolated art checkout landing. Failure rolls back newly created outputs;
success normalizes the session into the ordinary existing-source contract.
Horizontal counterpart creation is explicit and defaults OFF. A created action
with no registered consumer appears DORMANT/unwired until a separate gameplay
or presentation change owns it.

This native-authoring path deliberately does **not** round-trip its own saved
Workbench pixels through `asset_drop/inbox`. Asset Pipeline V2 already delegates
Operator art to this specialized backend. The inbox remains the correct boundary
for externally generated/imported/untrusted art that still needs intake,
normalization, registration, and provenance review. An external runtime-ready
Operator strip continues to use:

```text
custodian/asset_drop/inbox/operator/
operator__<layer>__<profile>__<group>__<action>__<direction>__<N>f__<size>.png
```

Newly published art does not imply gameplay use. Until a presentation/runtime
consumer selects the action, the UI must present it as source/catalog-present
but DORMANT/unwired rather than LIVE.

## Contract migration: frame count and canvas

The V2 manifest separately records canonical `source_contract`, current
`workspace_contract`, proposed `publish_contract`, explicit timeline slots,
primary source/workspace clocks, and global document frames. Automatic
migration includes synchronized lower+upper (or full body), matching-clock
head/cape, and the exact requested matching-clock authored weapon. FX and a
concurrent full-body reference remain unchanged unless explicitly selected.

Before staging and again before publish, frame-count dependency auditing checks
weapon gameplay frame fields, melee hit-window profiles, and per-frame socket
tracks. GREEN migrations proceed; YELLOW presentation dependencies and RED
gameplay dependencies fail closed. Frame-count commands export current saved
workspace pixels, stage exact strip transforms, reassemble Aseprite, and record
a pending migration.

Canvas migration is a separate `kind: frame_canvas` contract operation. It
changes each selected layer's frame canvas without resizing/resampling pixels;
the V1 placement anchor is centered and requires integer offsets. Expansion
adds transparent padding. Contraction is allowed only when no visible pixel
would be cropped. The default `animation` scope migrates editable Operator-owned
presentation layers for the selected semantic animation; `body` selects the
synchronized lower/upper pair or full body; `all` also includes linked editable
publishing layers. References are never resized and are only re-centered in the
recomputed document canvas. Pixel-coordinate socket dependencies are YELLOW and
block staging until separately migrated; animation clocks, frame count, timing,
and gameplay hit windows do not change.

Use `Ctrl+R` in WORKBENCH mode or `operator anim canvas resize ... --width W
--height H --scope animation|body|all`. Review is explicit; staging rebuilds
the physical Aseprite document from saved pixels. A matching dirty live Aseprite
document is refused until saved. Publish constructs the new canonical size-token
paths through `operator_asset_schema.py`, then uses the existing transactional
runtime, compatibility, resource, import, validation, and rollback pipeline.

Canvas/frame migrations publish the regenerated canonical runtime manifest alongside
the generated catalog, SpriteFrames, and scoped source/runtime sheets.

## Canonical SpriteFrames publication

Workbench publish refreshes the V2 runtime and builds the canonical
`content/sprites/operator/runtime/operator_runtime_frames.tres` before focused
actor checks. It does not generate or back up actor-local compatibility
SpriteFrames. Source timing remains recorded in the frozen migration evidence;
new timing authority comes from authored sidecars and the runtime catalog.

Publish transactions back up canonical runtime SpriteFrames and the generated
catalog alongside selected source/runtime paths. Rollback restores those
canonical artifacts and proves the authored files and timing contracts are
unchanged.

## Acceptance

The smoke covers exact extraction after rectangular-canvas placement, illegal outside-rectangle pixels, no-scale canvas expansion, visible-crop rejection, scope/dependency selection, and current lower/upper/Vigil semantic resolution. When Aseprite is available it stages Fast 02 E in a temporary workspace, proves centered RGBA identity, and exports the physical six-frame Aseprite document after expanding the current source canvas by 32 pixels per axis. The UI smoke covers canvas-migration projections and the dirty-live-document guard; its Textual pilot remains optional.

`operator_workbench_ui_smoke.py` exercises browser/session/context/error
projections without a terminal, then uses Textual's headless pilot when the
optional dependency is installed. It proves search, six-frame run detail,
add-frame dry-run review/cancel, publish review/cancel, modal-safe activity
logging, and exact Workbench-error survival after failed session loading,
without canonical source mutation.

`operator_art_worktree_smoke.py` uses temporary local Git remotes to verify
checkout creation/reuse, sparse-profile creation and clean migration,
FF-only synchronization, unrelated-upstream omission, selected Operator path
updates, ignored Workbench byte preservation, dirty/ahead/pending refusal,
coordination-main refusal, ignored Workbench migration and live-Aseprite
protection, same-source conflict refusal, scoped staging, and resumable
`LAND PENDING` behavior.

## V5 production cockpit

> UX hierarchy planning is tracked in `OPERATOR_WORKBENCH_UX_HIERARCHY_ROADMAP.md`. Its five packets are refresh-gated planning drafts and do not supersede the current cockpit behavior until each packet is refreshed, signed off, implemented, and landed.

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

Timeline clips contain semantic identity, direction, REVIEW FPS, loop count,
optional inclusive frame trims, and an appended `art_generation` defaulting to
`legacy_96`. Existing v1 sequence files load as legacy clips and remain
compatible with positional callers. Generation-aware clips write sequence v2;
2.5D clips resolve exact saved Workbench renders rather than legacy runtime
pixels. Their optional per-frame durations come from the saved physical
Aseprite document. Presets are unavailable when any exact component identity or
required timing is missing. Duplicates are legal. Saved sequences live under
`.ai/operator_animation_workbench/sequences/`; sequence JSON is never published
to canonical source or runtime.

### 2.5D review receipts and runtime sandbox

2.5D review receipts are derived from `project_targets()` leaves plus current
Workbench/Art Agent QA evidence. The receipt binds the manifest and saved
document, rendered frame bytes, accepted profile/reference hashes, physical
canvas/frame/duration contract, QA findings, evidence-bound human approval when
required, and the sandbox request/result. A stale or unverifiable receipt
contributes no effective verification. Advisory-only YELLOW QA remains
non-blocking; RED blocks and NEEDS_HUMAN_REVIEW requires an explicit Workbench
approval whose backend-authored provenance and evidence digest match the exact
current leaf. Review inspection derives `NOT_REQUIRED`/`REQUIRED` from live QA;
callers cannot submit a disposition record.

Family state is recomputed from the required projected directions and current
receipts on read. Missing, projected, legacy-fallback, partial, and stale cells
remain incomplete. The isolated debug sandbox displays exact hash-bound 128px
Workbench frames on the real Operator body renderer and camera/shadow context
through `OperatorBodyPresenter`. It records production runtime resource hashes
before and after; the sandbox has no source publication, selector, catalog, or
runtime-build authority. `RUNTIME_VERIFIED` is review evidence only; canonical
2.5D publication remains a later migration authority.
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

For live clipboard export, OPUI waits for the matching Live Bridge
`command.result` before reading the detached render. It uses the returned
output path and exact frame/canvas metadata, so an older cache image cannot be
mistaken for the requested render.

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
