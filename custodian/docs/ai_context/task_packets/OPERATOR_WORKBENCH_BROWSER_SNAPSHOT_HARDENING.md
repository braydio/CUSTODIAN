# OPERATOR WORKBENCH BROWSER SNAPSHOT HARDENING

Status: implementation  
Primary subsystem: Operator Workbench UI  
Scope: one coherent browser/discovery consistency slice

## Objective

Make Operator Workbench animation discovery transactional from the user's perspective.

A transient or superseded canonical-source scan must never:

- make an existing animation temporarily disappear;
- expose a half-migrated modular body as healthy;
- silently change the selected animation;
- allow an older asynchronous refresh to overwrite newer browser state.

Canonical Operator source remains authoring authority.

Do not change animation art or gameplay/runtime animation behavior.

## Current failure surfaces

Verify these against current main before editing.

### 1. Browser applies one filesystem scan directly

`custodian/tools/operator/ui/app.py::_reload_browser()` currently:

- awaits `AnimationFeature.refresh()` in a worker thread;
- filters that result;
- immediately calls `AnimationTree.set_records()`;
- falls back to `filtered[0]` when current selection is absent.

There is no accepted/last-known-good browser snapshot.

### 2. AnimationFeature mutates cache from a worker thread

`custodian/tools/operator/ui/features/animations.py` currently stores `_records`.

`refresh()` mutates `_records` and is called through `asyncio.to_thread()`.

Cancellation of the awaiting Textual worker does not stop that Python thread,
so a canceled older refresh may mutate `_records` after a newer request exists.

Remove this background-thread side effect.

### 3. Canonical publication can temporarily expose an incomplete source tree

`custodian/tools/operator/animation_workbench.py::publish()` currently performs
path-changing contract publication by removing an old canonical path before
installing the replacement path.

This means a frame/canvas contract migration can briefly expose an incomplete
canonical semantic action to concurrent readers.

This packet must make OPUI resilient to that fact.

Do NOT redesign Workbench publication in this slice.

### 4. Search and refresh selection semantics are coupled incorrectly

A search filter may legitimately hide the selected row.

Refreshing while that filter is active must not interpret "not visible under
this filter" as "the canonical animation disappeared."

Search is presentation state, not animation authority.

### 5. Superseded visibility has two owners

Both:

- `WorkbenchUIState.show_superseded`
- `WorkbenchService.show_superseded`

currently carry mutable presentation state.

Leave one owner.

### 6. Reachability projection is not snapshot-consistent

`WorkbenchService._reachability_status()` rereads
`operator_animation_reachability.json` per animation record.

One browser discovery must parse reachability exactly once.

Action status must prefer the action-level reachability entry. A layer-level
DORMANT / ALTERNATE_LAYER / SUPERSEDED row must not accidentally classify the
entire action.

### 7. Browser COMPLETE does not currently prove synchronization

The active design document says synchronized lower+upper body presentation is
COMPLETE.

Current `classify_layers()` only proves both layer names exist.

For browser projection, modular body presentation is COMPLETE only when its
required lower+upper clocks agree.

Existing legitimate weapon-only / FX-only / fragment records remain PARTIAL
and visible.

## Authority

Use the existing boundaries:

- `animation_workbench_model.source_index()`:
  canonical semantic source discovery

- `WorkbenchService`:
  pure source/reachability -> browser-record projection

- `WorkbenchUIState`:
  accepted UI browser state and presentation preferences

- `OperatorWorkbenchApp`:
  asynchronous refresh orchestration and application

- `AnimationTree`:
  rendering/navigation only

Do not create another persistent browser cache authority.

If local helper/class names differ from this packet, preserve these ownership
boundaries rather than forcing the suggested names.

## Behavioral contract

### A. Side-effect-free discovery

A browser filesystem discovery performed in a worker thread must return a
candidate value only.

It must not mutate:

- accepted browser records;
- search state;
- selected animation;
- AnimationTree;
- a feature-level cache subsequently consumed by search.

Remove or retire `AnimationFeature._records` as an independent source of truth.

`AnimationFeature.refresh()` may remain as a thin provider facade if useful,
but worker-thread execution must be side-effect-free.

### B. One accepted browser snapshot

Keep exactly one accepted, unfiltered canonical browser snapshot in UI state.

A tuple of immutable `AnimationRecord` projections is sufficient unless the
live code benefits from a small dedicated value object.

Search and visibility filters derive from that accepted snapshot.

Do not use AnimationTree contents as source state.

### C. Latest-request-wins refresh ordering

Every asynchronous browser refresh must have a monotonically increasing request
generation.

After every await / thread completion / stabilization delay:

    if this request is no longer the newest request:
        discard it without touching UI state

An older slow scan must never replace a newer accepted snapshot.

Do not rely only on Textual `exclusive=True`; canceled `asyncio.to_thread()`
work can continue executing.

### D. Destructive candidate stabilization

Ordinary additive/non-destructive discoveries may apply immediately.

A candidate is destructive relative to the last accepted canonical snapshot if
at least one previously accepted directional identity:

1. disappears; or
2. loses required body presentation such that COMPLETE becomes PARTIAL; or
3. loses one of the previously accepted body layers.

Do not compare against the currently filtered/search-visible tree.

For a destructive candidate use bounded confirmation:

    initial destructive candidate
        wait ~100 ms
        rescan

    if scan 2 has the same semantic browser signature:
        accept it

    if scan 2 differs:
        wait ~250 ms
        perform one final scan

    accept only if two consecutive candidate signatures agree

    otherwise:
        retain the previous accepted snapshot
        report that canonical source remained unstable

Maximum discovery attempts for one request:

    3

Maximum stabilization delay budget:

    approximately 350 ms

Tests must inject/fake the delay rather than sleeping in real time.

A genuine deletion therefore becomes visible after confirmation while a brief
source-swap hole never reaches the tree.

### E. Candidate signature

Use semantic records, not filenames or mtimes.

The stability signature must account for enough browser contract data to detect
a half migration:

    profile
    group
    action
    direction
    body/presentation layers
    frame contract relevant to browser completeness

Do not use file modification time or arbitrary directory ordering as identity.

### F. In-app publish coordination

A user-triggered F5/full-browser refresh must not start a canonical scan while
this same OPUI instance is inside its canonical PUBLISH mutation.

Coalesce/defer that request.

Exactly one normal browser refresh must run when publication has completed.

Do not block unrelated preview rendering or Aseprite live events.

Canvas/frame migration staging itself remains workspace-local; canonical
publication is the dangerous boundary.

### G. Search is a pure view

Typing or clearing Search must:

- perform no filesystem discovery;
- filter only the accepted browser snapshot;
- never mutate canonical source;
- never change `state.selection` merely because the selected row is hidden.

If the current selected identity matches the current filter, restore its tree
selection silently.

If it does not match:

- the tree may omit it;
- the current Workbench/session selection remains unchanged.

When the filter is cleared, restore the selected semantic leaf if it still
exists.

### H. Superseded visibility has one owner

`WorkbenchUIState.show_superseded` is the presentation preference authority.

Remove mutable `WorkbenchService.show_superseded` ownership.

Expose action-level reachability status in the browser projection sufficiently
for the UI to hide/show SUPERSEDED records without creating a second authority.

Shift+U remains the UX.

Do not let SUPERSEDED records leak into transition/timeline candidate behavior
merely because the browser projection now carries their status.

### I. Reachability is read once per discovery

Read and parse:

`custodian/content/data/operator/operator_animation_reachability.json`

once per browser discovery.

Build an action lookup keyed by:

    profile / group / action

Classification rule:

1. use the action-level row where `layer` is absent;
2. layer-specific entries describe layers and do not supersede action status;
3. absence of an action-level classification must not be inferred as
   SUPERSEDED merely because one layer is classified separately.

Preserve existing reachability-audit authority. This packet does not edit
reachability classifications.

### J. Modular completeness must be truthful

For browser records:

- valid full_body presentation -> COMPLETE;
- lower_body + upper_body with synchronized body clock -> COMPLETE;
- lower+upper with mismatched frame clocks -> PARTIAL / contract mismatch;
- only one required modular body layer -> PARTIAL;
- weapon-only / FX-only fragments remain PARTIAL;
- reference-only semantics retain existing reference/legacy presentation.

Do not globally outlaw independent FX/weapon clocks.

The synchronization check applies to the required modular body pair.

### K. Selection restoration

When an accepted snapshot is applied:

If current semantic selection still exists in the unfiltered accepted snapshot:

    preserve it

If current search hides it:

    preserve session selection without selecting another animation

If it is genuinely removed after stabilization:

    select a deterministic visible fallback
    and emit one explicit activity message identifying:
        removed identity
        replacement selection

Never silently fall back to `filtered[0]` because of a transient scan or search
filter.

### L. Tree application must not duplicate session loads

`AnimationTree.set_records()` already preserves expanded semantic branch keys.

Retain that behavior.

Programmatic restoration of the selected leaf must not accidentally emit a
second user-selection event that causes duplicate `_load_session()` work.

Use the cleanest Textual seam available:

- silent programmatic selection; or
- a bounded selection-event suppression guard.

Do not invent a second selection authority.

One completed browser refresh should cause at most one intentional session
reload for an unchanged selected identity.

### M. Refresh failures preserve usable state

If source discovery or reachability projection raises after a last-known-good
snapshot exists:

- retain the accepted records;
- retain the visible tree;
- retain selection/session state;
- report:

    browser refresh failed; previous snapshot retained

Then surface the useful underlying error through the existing error path.

Do not replace the tree with an empty set on refresh failure.

## Fast-chain regression fixture

Extend the existing focused UI smoke with the observed class of failure.

Accepted initial snapshot:

    unarmed/attack/fast_01/e
    unarmed/attack/fast_02/e
    unarmed/attack/fast_03/e
    unarmed/attack/fast_04/e

Select:

    unarmed/attack/fast_02/e

Candidate discovery 1 temporarily returns:

    fast_01
    fast_04

Candidate discovery 2 returns:

    fast_01
    fast_02
    fast_03
    fast_04

Expected:

- Fast 02/03 never disappear from the rendered accepted tree;
- Fast 02 remains selected;
- no fallback session is loaded;
- one stabilization/recovery activity event is sufficient.

## Additional focused regressions

Add focused deterministic coverage for:

### Stable removal

Two consecutive destructive scans omit Fast 03.

Expected:

- omission is accepted after confirmation;
- Fast 03 disappears;
- if it was selected, explicit deterministic fallback behavior occurs.

### Half modular migration

Accepted Fast 02:

    lower_body 6f
    upper_body 6f
    COMPLETE

Transient candidate:

    lower_body 7f
    upper_body 6f

Expected:

    candidate is not exposed as COMPLETE
    destructive stabilization protects the accepted browser view

Stable synchronized replacement:

    lower_body 7f
    upper_body 7f

Expected:

    new contract is accepted

### Out-of-order completion

Refresh A starts.
Refresh B starts afterward.
B completes first and is accepted.
A completes later.

Expected:

    A cannot mutate accepted browser state or feature cache

### Search + F5

Select Fast 02.
Search for Fast 01.
Press full refresh.

Expected:

    Fast 02 remains the actual selected session
    only Fast 01 is visible under the filter

Clear Search.

Expected:

    all accepted records return without filesystem discovery
    Fast 02 is restored as the selected tree leaf

### Refresh exception

Accepted snapshot exists.
Next discovery raises.

Expected:

    tree and selection remain unchanged
    previous-snapshot-retained message is emitted

### Reachability projection

Fixture contains:

    action-level LIVE
    layer-level ALTERNATE_LAYER

Expected:

    action remains LIVE

Prove reachability source is parsed once for the discovery rather than once per
record.

### Programmatic selection

Refresh while current identity survives.

Expected:

    exactly one intended session projection/reload
    no duplicate selection-event session load

## Preserve existing Ctrl+R contract

Current main already has the desired contextual shortcut:

WORKBENCH:
    Ctrl+R -> Resize Canvas

MOTION:
    Ctrl+R -> Reset Motion

text entry:
    Ctrl+R -> no app mutation

Do not restore Shift+R.

Retain the existing real Textual Pilot coverage for this behavior.

## Files expected to change

Primary:

- `custodian/tools/operator/ui/app.py`
- `custodian/tools/operator/ui/service.py`
- `custodian/tools/operator/ui/state.py`
- `custodian/tools/operator/ui/features/animations.py`
- `custodian/tools/validation/operator_workbench_ui_smoke.py`

Conditional:

- `custodian/tools/operator/ui/widgets/animation_tree.py`
  only if needed for silent programmatic selection

Docs:

- `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`
- `custodian/docs/ai_context/CURRENT_STATE.md`

The existing validation manifest already maps
`custodian/tools/operator/ui/**` to `operator_workbench_ui`.

Do not edit `validation_manifest.json` unless the implementation creates a new
owner outside that existing wildcard.

## Documentation contract

Update the active Workbench design document to state concisely:

- canonical source remains authoring authority;
- browser discovery is applied as an accepted snapshot;
- destructive source regressions receive bounded stability confirmation;
- search/superseded are presentation filters over accepted state;
- current selection survives refresh/filtering while its canonical identity
  remains valid;
- synchronized modular lower+upper clocks are required for browser COMPLETE;
- Ctrl+R remains contextual Resize/Reset behavior.

Add only a concise current-truth note to `CURRENT_STATE.md`.

Do not rewrite historical task packets.

## Explicit non-goals

Do NOT:

- change Fast 01/02/03/04 art;
- change animation timing or gameplay hit windows;
- change `operator.gd`;
- rebuild or reinterpret runtime combat behavior;
- modify reachability classifications;
- make runtime/catalog data authoring authority;
- use `reports/operator/operator_runtime_build_v2.json` as browser authority;
- redesign Workbench publish transactions in this slice;
- redesign Asset Pipeline V2;
- add polling or permanent background filesystem watchers;
- add a second browser cache;
- add broad per-frame telemetry;
- alter the newly fixed Ctrl+R behavior.

## Deferred architectural risk

Do not implement this in the current packet, but report if still present:

Canonical Workbench path-changing publication is not transactionally invisible
to arbitrary external filesystem readers because old paths are removed while a
multi-file replacement is being committed.

The generated runtime builder likewise performs ordinary file copies and direct
manifest/catalog writes.

The browser stabilization contract in this packet protects OPUI from these
short windows.

A repository-wide writer/reader publication boundary, if desired, is a
separate pipeline task because it must cover every canonical writer rather
than patch only Workbench publish.

## Validation order

Run the smallest useful test first:

    python3 custodian/tools/validation/operator_workbench_ui_smoke.py

It must include the new deterministic browser-race fixtures without depending
on real sleeps or mutating canonical production assets.

Then run:

    python3 custodian/tools/validation/run_validation.py --changed --json

Only if implementation changes `animation_workbench_model.source_index()` or
pipeline source-discovery semantics, additionally run:

    python3 custodian/tools/validation/operator_animation_contract_report.py --strict

Prefer not to alter `source_index()` in this slice.

## Acceptance

Complete when all are true:

[ ] worker-thread browser discovery has no mutable cache/UI side effects

[ ] latest refresh request always wins

[ ] transient Fast 02/03 disappearance cannot reach the visible tree

[ ] transient COMPLETE -> PARTIAL body migration cannot reach the visible tree

[ ] a genuine stable deletion still becomes visible after bounded confirmation

[ ] a refresh exception leaves the last usable browser intact

[ ] Search performs zero canonical source scans

[ ] Search + F5 cannot silently change the selected animation

[ ] superseded visibility has one mutable owner

[ ] reachability is parsed once per browser discovery

[ ] layer-level status cannot wrongly supersede action-level reachability

[ ] modular body clock mismatch is not reported COMPLETE

[ ] programmatic refresh restoration does not duplicate session loading

[ ] Ctrl+R Resize Canvas remains functional with AnimationTree/DataTable focus

[ ] Ctrl+R Motion Reset remains functional only in Motion mode

[ ] focused UI smoke passes

[ ] changed validation passes

## Completion report

Return only:

- files changed;
- final browser ownership/stabilization contract;
- focused smoke result;
- changed-validation result;
- docs updated;
- intentionally deferred item, if any;
- discovered architectural conflict/risk, if any;
- commit SHA.
