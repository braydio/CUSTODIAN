# OPERATOR WORKBENCH UX V1 - STATE HIERARCHY AND SHELL

> **REFRESH REQUIRED BEFORE IMPLEMENTATION**
>
> This remains a refresh-gated planning packet originally based on `main@330422023f9a92362915af46b9658585e7c1d450`; the background-sync addendum below was re-reviewed against `main@09706b79318aa627ea5474205884a8d8e53d8292`.
> Do not claim or implement it yet. Request a fresh OPUI repository/interface
> review after `review-operator-workbench-animation-creation` is complete and
> archived. Remove this banner only after the packet is reconciled against
> current main and explicitly signed off for execution.

- Packet schema: `custodian.task_packet.v2`
- Series: `operator-workbench-ux-hierarchy-v1`
- Workstream: `operator-workbench-ux-state-hierarchy`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-operator-workbench-animation-creation`
- Locks: `operator-workbench-ui`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `09706b79318aa627ea5474205884a8d8e53d8292`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search`
- Background-sync addendum chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6a8afb3b-5934-83ea-a84a-4c7a4b7778fb`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Roadmap: `design/02_features/animation/OPERATOR_WORKBENCH_UX_HIERARCHY_ROADMAP.md`
- Goal: Replace OPUI's debug-first global chrome with one artist-facing workflow hierarchy that makes the selected animation's publication state, live-save state, and main readiness immediately understandable while keeping full diagnostics available on demand.
- Completion boundary: Deliver the UX1 shell only: workflow-state projection, artist-facing status bar, user-facing mode labels, compact Activity behavior, and Tier-3 diagnostic disclosure. Do not redesign WORKBENCH layout, PLAN/QUEUE content, Publish modal, or deep PREVIEW behavior in this slice.
- Current measured state:
  - Recent Workbench incidents also proved the UI needs first-class projection for `LAND PENDING`/receipt reconciliation, sparse/LFS readiness, frame-contract mismatch/reconciliation, and `RECOVERY_REQUIRED`. These are backend-owned states from the prerequisite hardening packet; UX1 must display them without parsing logs or blocking read-only startup.
  - `ui/widgets/status_bar.py::WorkbenchStatusBar.set_status()` currently emphasizes branch, generic dirty/clean state, Aseprite availability, Live Bridge state, V2 marker, and a raw checkout label across three lines.
  - `ui/screens/main.py` permanently reserves a 10-row Activity pane under every mode.
  - `ui/widgets/animation_detail.py` exposes raw `Workbench: EDITED`, source/workspace/document frame counts, migration, dependency status, workspace path, and Aseprite path as primary information.
  - `ui/state.py::SessionView` already carries `workbench_state`, `contract_state`, `dependency_status`, frame counts, layers, completeness, workspace, Aseprite and canvas.
  - `ui/state.py::PublishView` already carries publication operations and basic enable/block state.
  - The landed publish-readiness authority owns structured checkout/main/dirty/LFS/stale/recovery readiness. The new `operator-workbench-background-base-sync` prerequisite owns bounded launch-time reconciliation of an ahead-zero checkout whose dirt is provably Workbench-owned, including exact-byte preservation across an FF-only base advance.
  - A checkout label such as `behind 256` is repository-history distance from `origin/main`, not 256 animation changes. Sparse checkout constrains materialized paths, not commit ancestry. UX1 must never present that number as an artist workload or imply hundreds of animation edits.
  - After safe background reconciliation succeeds, primary state is simply `MAIN READY`; an unsafe preserve/sync case is `MAIN BLOCKED` with one concise actionable reason. Raw branch/ahead/behind/sparse detail remains Tier-3 diagnostics.
  - This slice must consume the backend reconciliation/readiness projection instead of parsing Git or reproducing synchronization/recovery checks.
  - The prerequisite browser-snapshot packet owns accepted browser refresh state. This slice must not introduce another browser cache.
  - Live Aseprite modified state remains owned by the existing Live Bridge/UI controller; it should be projected, not reimplemented.
- Evidence:
  - `custodian/tools/operator/ui/state.py`
  - `custodian/tools/operator/ui/service.py`
  - `custodian/tools/operator/ui/app.py`
  - `custodian/tools/operator/ui/screens/main.py`
  - `custodian/tools/operator/ui/widgets/status_bar.py`
  - `custodian/tools/operator/ui/widgets/context_key_bar.py`
  - `custodian/tools/operator/ui/widgets/animation_detail.py`
  - `custodian/tools/operator/ui/widgets/activity_log.py`
  - `OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY.md`
  - `OPERATOR_WORKBENCH_BACKGROUND_BASE_SYNC.md`
  - `OPERATOR_WORKBENCH_BROWSER_SNAPSHOT_HARDENING.md`
  - `OPERATOR_WORKBENCH_FX_LAYER_ADOPTION.md`
- Task-specific authority:
  - The landed publish-readiness result owns publication readiness/recovery; `operator-workbench-background-base-sync` owns bounded launch-time art-checkout base reconciliation and its structured current/synced-preserved/blocked/recovery state.
  - The landed browser snapshot is the only authority for accepted browser state.
  - Workbench V2 remains source/workspace/publication authority.
  - Live Bridge remains current in-memory Aseprite connection/modified-state authority.
  - This slice owns presentation vocabulary and hierarchy only.
- Work surface:
  - `custodian/tools/operator/ui/state.py`
  - `custodian/tools/operator/ui/service.py`
  - `custodian/tools/operator/ui/app.py`
  - `custodian/tools/operator/ui/screens/main.py`
  - `custodian/tools/operator/ui/widgets/status_bar.py`
  - `custodian/tools/operator/ui/widgets/context_key_bar.py`
  - Activity widget/dialog files as required by current main
  - `custodian/tools/validation/operator_workbench_ui_smoke.py`
  - active Workbench design/current-state docs only where behavior changes
- Change:
  - Include compact artist-facing mappings for at least `PUBLISH BLOCKED`, `LAND PENDING`, `RECEIPT RECONCILIATION REQUIRED`, `FRAME CONTRACT MISMATCH`, `RECOVERY REQUIRED`, and `READY`. A blocked publish state must not visually imply the whole app is unusable; show the single next recovery action while browser/review remains accessible.
  1. Add one immutable artist-facing workflow projection. Exact private class/enum names may follow refreshed main, but the projection must distinguish:
     - `PUBLISHED / NO LOCAL CHANGES`;
     - `MODIFIED · READY TO PUBLISH`;
     - `MODIFIED · CONTRACT CHANGE`;
     - `REFRESH REQUIRED`;
     - `PUBLISH BLOCKED`;
     - `LANDING PENDING`;
     - `RECOVERY REQUIRED`.
  2. Keep live editor save state orthogonal to publication state. Project at least:
     - Aseprite connected;
     - matching live document has unsaved changes;
     - publication/review will use last saved state.
     Do not collapse an unsaved editor warning into generic repository dirt.
  3. Project main readiness through the prerequisite structured readiness/reconciliation authority:
     - `MAIN READY` after current or successfully reconciled launch state;
     - `UPDATING WORKBENCH` only while a bounded reconciliation is actually in flight, if that transient state is exposed;
     - `MAIN BLOCKED` with one concise reason for unsafe/failed reconciliation.
     Do not present `behind N` as pending animation work or require the artist to trigger a routine safe sync manually. Raw branch/sparse/ahead-behind counts belong in diagnostics unless a true unsafe condition directly blocks the current action.
  4. Establish explicit precedence so blockers are never hidden by less important status. Recovery and blocked/stale states outrank ordinary modified/clean states. Unsaved Aseprite state remains an independent visible warning.
  5. Rewrite `WorkbenchStatusBar` around artist-critical state. Normal healthy presentation should center selected animation identity/status, main readiness, and Aseprite connection. Do not lead with branch name or sparse-profile text.
  6. Preserve all previous technical status data behind an expandable diagnostics/detail surface. Include exact branch/checkout identity, main relation, sparse profile, workspace path, Aseprite executable, dependency status and other current low-level status there rather than deleting observability.
  7. Collapse the permanent Activity pane into a compact latest-event surface by default. Keep the full existing Activity history expandable without losing events. ERROR/WARN events may temporarily elevate or expand. Normal INFO traffic must not consume ten rows continuously.
  8. Change user-facing mode names only:
     - PLAN -> QUEUE;
     - PREVIEW -> REVIEW;
     - TIMELINE -> SEQUENCE;
     - WORKBENCH and MOTION remain.
     Internal mode keys may remain `plan/workbench/preview/timeline/motion` to minimize churn.
  9. Update `ContextKeyBar` and help text to use the new user-facing vocabulary. Do not change established shortcuts merely to match labels.
  10. Remove raw `Workbench: EDITED` style wording from always-visible primary chrome once the artist-facing projection exists. Keep raw backend state in diagnostics.
  11. Update the UX roadmap during implementation if prerequisite packets land a materially different readiness/session seam.
- Preserve:
  - Preserve the landed dismissible error-dialog contract and exact backend-error visibility; the hierarchy redesign must not replace recoverable errors with undismissable modal traps.
  - All Workbench V2 source/publish semantics.
  - Existing Live Bridge ownership and behavior.
  - Existing browser accepted-snapshot behavior from the prerequisite.
  - Exact Activity history and error messages.
  - Existing keyboard actions.
  - Page 2, Page 1 and Publish modal structure until later slices.
- Non-goals:
  - No WORKBENCH preview-first layout yet.
  - No browser workflow badges yet.
  - No PLAN/QUEUE content redesign.
  - No Publish dialog redesign.
  - No new Git commands, readiness parsing or auto-sync behavior.
  - No FX adoption implementation.
  - No animation/runtime/art changes.
- Acceptance:
  - A clean selected animation visibly reads `PUBLISHED / NO LOCAL CHANGES` without exposing branch/sparse details in the primary header.
  - A saved Workbench pixel edit visibly reads `MODIFIED · READY TO PUBLISH`.
  - A pending frame/canvas migration visibly reads `MODIFIED · CONTRACT CHANGE`.
  - A canonical freshness failure visibly reads `REFRESH REQUIRED`.
  - A prerequisite-readiness blocker visibly reads `PUBLISH BLOCKED` with one concise reason.
  - LAND PENDING and RECOVERY_REQUIRED remain distinct visible states.
  - A matching modified live Aseprite document produces a separate unsaved warning.
  - The default Activity surface is compact but the complete previous log remains accessible.
  - Branch, sparse, checkout, paths and dependency internals remain available in diagnostics; raw `ahead N / behind N` is diagnostic repository history and is never labeled as animation-change count or artist workload.
  - A safely reconciled behind checkout reads `MAIN READY` without requiring an artist sync action; an unsafe preserve/sync case reads `MAIN BLOCKED` with one concise backend-provided reason.
  - User-facing mode labels are QUEUE, WORKBENCH, REVIEW, SEQUENCE, MOTION while existing mode shortcuts continue to work.
  - No new Git/browser/workbench authority is introduced.
- Validation:
  - Extend `operator_workbench_ui_smoke.py` with fixtures for every artist-facing publication state, independent unsaved-live state, healthy/behind/blocked main projection, Activity collapse/expand, and user-facing mode labels.
  - Run the prerequisite focused background-base-sync/readiness/browser UI smokes selected by validation ownership after refresh.
  - Run `python3 custodian/tools/validation/run_validation.py --changed --json`.
  - Run `git diff --check`.
- Task overrides: `none`
- Deferred:
  - UX2 dominant WORKBENCH preview/compact inspector/layers/browser badges.
  - UX3 Publish decision modal.
  - UX4 actionable work queue.
  - UX5 final consistency/accessibility/responsive closeout.

## Execution Feedback

Complete only after the refresh banner has been removed and implementation is actually executed.

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `pending`
- Friction severity: `none`
- What went wrong: `pending`
- Root cause / contributing factors: `pending`
- Prevention / pipeline improvement: `pending`
- Tooling / docs drift discovered: `pending`
- Follow-up: `pending`
- What worked: `pending`

## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search`
- Refresh instruction: Bring the landed predecessor/review evidence and any material live-main drift back to this conversation. Re-derive the packet here with the user before promoting it to implementation-ready; do not let the execution agent silently reinterpret architecture, scope, sequencing, or acceptance.

## Handoff

- Next action: after prerequisite review lands, request the mandated refresh and reconcile this packet before changing it to ready.
- Best starting files: `ui/state.py`, `ui/widgets/status_bar.py`, `ui/screens/main.py`, `ui/widgets/context_key_bar.py`, and the landed publish-readiness projection.
- Blockers or open questions: implementation is intentionally blocked until refresh/sign-off.