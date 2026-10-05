# Operator Workbench UX Hierarchy V1 Roadmap

**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search
**Background-sync addendum chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6a8afb3b-5934-83ea-a84a-4c7a4b7778fb

> **REFRESH REQUIRED BEFORE IMPLEMENTATION**
>
> Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search
>
> This roadmap and every packet in this series are planning drafts based on
> `main@330422023f9a92362915af46b9658585e7c1d450`.
> Do not claim or implement any slice yet. Before implementation, request a
> fresh repository/interface review after the prerequisite Operator Workbench
> hardening and FX-adoption series have landed. Remove this banner only after
> the refreshed roadmap has been reconciled to current main and explicitly
> signed off for execution.

**Status:** planned / blocked pending refresh  
**Series:** `operator-workbench-ux-hierarchy-v1`  
**UI lock:** `operator-workbench-ui`  
**Area:** Operator Workbench / OPUI  
**Baseline reviewed main:** `330422023f9a92362915af46b9658585e7c1d450`  
**Last updated:** 2026-10-01

## Purpose

Rework OPUI's information hierarchy around the artist's workflow rather than
giving implementation/debug state equal visual weight.

The finished cockpit should answer, in order:

1. What animation am I working on?
2. What does it look like right now?
3. Has it changed?
4. Is the change saved?
5. Is it ready to publish?
6. If publication is blocked, what single condition blocks it?
7. What should I work on next?
8. Where can I inspect deep technical detail if I actually need it?

This program is a UI/projection redesign. It must not create parallel Git,
browser-snapshot, publication, animation, or Aseprite authorities.

## Relationship to existing Operator work

This series intentionally waits for the already-authored Operator Workbench
hardening chain:

```text
sparse checkout correction + review
        ↓
publish readiness/recovery + review
        ↓
browser/PREVIEW snapshot hardening + review
        ↓
FX layer adoption + review
        ↓
new animation creation + review
        ↓
UX HIERARCHY V1
```

Those preceding packets own backend correctness:

- `OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY.md` owns structured checkout,
  origin/main relation, dirty-state classification, safe preparation,
  LAND PENDING, stale-source readiness, local LFS readiness, and recovery.
- `OPERATOR_WORKBENCH_BROWSER_SNAPSHOT_HARDENING.md` owns accepted browser
  snapshots, latest-request-wins refresh, selection preservation, F5/PREVIEW
  concurrency, and race protection.
- `OPERATOR_WORKBENCH_FX_LAYER_ADOPTION.md` owns saved Aseprite unbound
  `vfx`/`fx` discovery, explicit adoption, CREATE/REPLACE publication, and
  binding-set drift.
- `OPERATOR_WORKBENCH_ANIMATION_CREATION.md` owns the first human-authored
  entirely-new semantic animation flow: identity/template plan, blank/reference-backed
  Workbench, direct CREATE publication through the specialized Operator backend,
  rollback, runtime/catalog/import/validation, and truthful dormant/unwired state.
- The sparse-checkout correction/review chain owns historical closure of the
  `block_hold_01` FX import defect. Current main already has valid east/west
  remaps plus the 588-texture SpriteFrames import guard; UX work must treat that
  defect as repaired rather than a current backend prerequisite.

UX V1 consumes the structured state those packets land. It must not reproduce
their backend logic in Textual.

Recovery-integrity addendum (2026-10-03): the publish-readiness prerequisite also
owns the failure classes observed during current Workbench use: startup blocked
by pending/diverged/sparse state, pending receipt commit-ID drift, saved-document
versus pending frame-migration mismatch, LFS/import rollback residue, preservation
of the primary transaction error, and proof-gated recovery-marker clearing.
The already-landed dismissible stale-error modal remains a regression contract.
UX1 should project these states clearly after the backend lands; it must not
reimplement their recovery logic.

2026-10-03 prerequisite audit: publish-readiness/recovery remains the next
substantial backend slice; its local-only LFS contract now explicitly permits a
verified hydrated coordination-checkout donor when the shared LFS cache lacks
the exact object. Browser/PREVIEW hardening, FX adoption, and the newly authored
New Animation creation packet remain prerequisites. UX1-UX5 should refresh only
after those reviewed backend capabilities land so the UX can expose them rather
than recreate their logic.

## Existing UI baseline

As of the reviewed baseline:

- OPUI has five modes: PLAN, WORKBENCH, PREVIEW, TIMELINE, MOTION.
- `MainScreen` permanently renders a 3-line technical status bar, a 10-row
  activity pane, and mode-specific content.
- WORKBENCH mode allocates approximately 25% navigation / 35% AnimationDetail /
  40% LayerTable. The selected animation itself is not the visual center.
- `AnimationDetail` exposes raw source/workspace/document counts, migration,
  dependency status, workspace path, and Aseprite path at primary visual weight.
- `LayerTable` exposes layer/live/contract/canvas plus owner/profile/role
  detail and consumes 40% of the default workspace.
- PREVIEW already has the proven raster canvas, filmstrip, playback controls,
  comparison mode, diff metrics, transition review, and source selection.
- PLAN is a table of authored rank, priority, state, computed coverage, profile,
  and animation. The human-authored implementation plan JSON remains the only
  animation-priority authority.
- The Publish modal currently gives DIRECT and MIRROR tables, including
  UNCHANGED rows, similar visual weight to the actual publication decision.
- `WorkbenchStatusBar` currently emphasizes branch, repository dirty state,
  checkout identity, sparse profile, Aseprite availability, Live Bridge state,
  and V2 marker.
- `SessionView` already carries source/workspace/document frame counts,
  Workbench state, contract state, dependency status, layer projections,
  completeness, context, and canvas.
- `PublishView` already carries direct/mirror operations, contract change,
  timing, publishing layers, dependency audit, compatibility preflight,
  checkout publish enablement, and LAND PENDING state.
- `WorkbenchService.animation_plan()` projects
  `OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json` through current catalog
  coverage.

## Information hierarchy lock

### Tier 1 - artist-critical, always visible when relevant

- selected semantic animation + direction;
- publication state;
- unsaved live Aseprite state;
- frame count / FPS / loop;
- primary presentation layers;
- main/publication readiness;
- blocking condition if one exists.

### Tier 2 - contextual workflow information

- pending frame/canvas migration;
- source changed / refresh required;
- safe main synchronization available;
- LAND PENDING;
- unbound/adoptable FX layer after the prerequisite feature lands;
- incomplete/partial directional coverage.

### Tier 3 - diagnostics, hidden by default

- full workspace paths;
- canonical/runtime paths;
- exact source/workspace/publish contract triples;
- hashes;
- branch SHA / sparse-profile internals;
- dependency trace details;
- compatibility-resource internals;
- retired contracts;
- low-level LFS/materialization evidence.

Failures and warnings may promote themselves out of Tier 3 when they directly
block the current action.

## Artist-facing workflow vocabulary

The UI should converge on a compact vocabulary. Exact internal enum/class names
are not prescribed.

Primary publication state:

```text
PUBLISHED / NO LOCAL CHANGES
MODIFIED · READY TO PUBLISH
MODIFIED · CONTRACT CHANGE
REFRESH REQUIRED
PUBLISH BLOCKED
LANDING PENDING
RECOVERY REQUIRED
```

Live-editor state is independent and may overlay the publication state:

```text
ASEPRITE CONNECTED
UNSAVED ASEPRITE CHANGES
USING LAST SAVED STATE
```

Main/readiness state:

```text
MAIN READY
MAIN UPDATE AVAILABLE / SAFE SYNC
MAIN BLOCKED
```

Do not reduce distinct recovery/blocking states to a single generic "dirty"
label.

## User-facing mode vocabulary

Internal mode keys may remain unchanged to minimize code churn, but the cockpit
should present:

```text
1 QUEUE       What should I work on?
2 WORKBENCH   What am I editing, and does it look right?
3 REVIEW      Why does this frame/source/transition differ?
4 SEQUENCE    Does it flow with adjacent animations?
5 MOTION      Does it read correctly in spatial motion?
```

The existing `OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json` remains animation
implementation-order authority. This roadmap owns OPUI UX implementation order
only.

## Expected packet count

Exactly **5 implementation slices** are planned for UX Hierarchy V1.

Packet files:

```text
UX1  custodian/docs/ai_context/task_packets/OPERATOR_WORKBENCH_UX_STATE_HIERARCHY.md
UX2  custodian/docs/ai_context/task_packets/OPERATOR_WORKBENCH_UX_WORKBENCH_HOME.md
UX3  custodian/docs/ai_context/task_packets/OPERATOR_WORKBENCH_UX_PUBLISH_DECISION.md
UX4  custodian/docs/ai_context/task_packets/OPERATOR_WORKBENCH_UX_WORK_QUEUE.md
UX5  custodian/docs/ai_context/task_packets/OPERATOR_WORKBENCH_UX_CONSISTENCY_CLOSEOUT.md
```

| Slice | Execution workstream | Status | Focus |
|---|---|---|---|
| UX1 | `operator-workbench-ux-state-hierarchy` | blocked / refresh required | Artist-facing workflow state, global shell, debug disclosure, compact activity |
| UX2 | `operator-workbench-ux-workbench-home` | blocked / refresh required | Page 2 preview-first workspace, compact inspector/layers, browser workflow badges |
| UX3 | `operator-workbench-ux-publish-decision` | blocked / refresh required | Changes-first Publish modal, no-op clarity, mirror consequence, readiness presentation |
| UX4 | `operator-workbench-ux-work-queue` | blocked / refresh required | Replace weak PLAN table with actionable authored-rank work queue and direction coverage |
| UX5 | `operator-workbench-ux-consistency-closeout` | blocked / refresh required | Cross-mode consistency, responsive/focus/help/accessibility pass, final UX regression closure |

## UX1 - State Hierarchy + Shell

Establish one artist-facing projection over the structured backend truth that
already exists or is landed by prerequisite packets. Replace low-level Git and
Workbench terms in the default chrome with concise workflow states. Collapse
the permanent activity log into a compact latest-event surface with expandable
history. Retain full diagnostics on demand.

This slice does not redesign Page 2's three-column layout yet.

## UX2 - Workbench Home + Always-On Preview

Make WORKBENCH the visual home of animation authoring. Replace the current
metadata-heavy center/right panels with a dominant lightweight preview and a
compact inspector/layer surface. Reuse the existing preview provider and raster
widgets rather than adding a second renderer.

Deep comparison remains in REVIEW.

## UX3 - Publish Decision Surface

Redesign Publish around the decision actually being made:

- what changed;
- what will be written;
- whether timing/contract changes;
- whether main is ready;
- what mirroring will do;
- whether publication is a no-op.

Hide unchanged rows and technical paths by default. Consume publish-readiness
state rather than duplicating Git checks.

## UX4 - Work Queue / Planning Revamp

Replace the spreadsheet-like PLAN presentation with an actionable work queue
that preserves authored rank/priority/state from
`OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json` while projecting computed
direction/layer coverage, modified work waiting to publish, partial/missing
states, and the plan item's authored reason.

The UI may explain the next action but may not mutate or silently reorder the
human-authored plan.

## UX5 - Consistency + UX Closeout

Perform the final cross-mode pass only after UX1-4 land:

- consistent mode language;
- keyboard/context hints;
- focus behavior;
- responsive pane sizing;
- loading/empty/error states;
- warning prominence;
- debug disclosure consistency;
- accessibility without color-only meaning;
- Activity behavior;
- FX-adoption state presentation if landed;
- full focused regression and docs closeout.

This slice must not turn into a backend feature grab bag.

## Series execution contract

Every slice must:

1. remain `blocked/manual` while its refresh banner exists;
2. request a fresh repo/interface review before implementation;
3. remove its refresh banner only after reconciliation and explicit sign-off;
4. update `Reviewed main`, current measured state, dependencies, exact work
   surface, acceptance, and validation before becoming `ready`;
5. update this roadmap in the same workstream when scope or later-slice
   assumptions change;
6. preserve the prior slice's UI behavior unless the packet explicitly replaces
   it;
7. use the existing backend authority rather than parsing strings from rendered
   UI or duplicating Git/workbench state;
8. keep technical diagnostics available even when demoted from the default
   surface;
9. end with a compact implementation/validation receipt and update the roadmap.

## Non-goals for the full series

- No animation art changes.
- No gameplay/runtime animation changes.
- No replacement of Operator Workbench backend authority.
- No replacement of Asset Pipeline V2.
- No new Git synchronization implementation outside the publish-readiness
  authority.
- No new browser discovery/cache authority outside the browser-snapshot
  hardening.
- No new FX adoption or CREATE semantics.
- No mutation of animation-plan authored rank/priority/state from the UI.
- No speculative generic Workbench framework extraction.

## Planned files / likely surface

Primary current UI files:

```text
custodian/tools/operator/ui/app.py
custodian/tools/operator/ui/state.py
custodian/tools/operator/ui/service.py
custodian/tools/operator/ui/screens/main.py
custodian/tools/operator/ui/widgets/status_bar.py
custodian/tools/operator/ui/widgets/context_key_bar.py
custodian/tools/operator/ui/widgets/animation_tree.py
custodian/tools/operator/ui/widgets/animation_detail.py
custodian/tools/operator/ui/widgets/layer_table.py
custodian/tools/operator/ui/widgets/plan_table.py
custodian/tools/operator/ui/widgets/preview_canvas.py
custodian/tools/operator/ui/widgets/preview_controls.py
custodian/tools/operator/ui/widgets/preview_filmstrip.py
custodian/tools/operator/ui/dialogs/publish.py
custodian/tools/validation/operator_workbench_ui_smoke.py
```

The refresh may identify renamed/extracted files. Preserve the behavioral
contract rather than forcing stale private symbols.

## Roadmap change log

| Date | Main | Change |
|---|---|---|
| 2026-10-01 | `3304220` | Initial five-packet UX Hierarchy V1 plan authored from current OPUI and ready prerequisite packet chain. |