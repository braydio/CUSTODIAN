# OPERATOR WORKBENCH BROWSER / PREVIEW REFRESH HARDENING

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-workbench-browser-preview-refresh-hardening`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-operator-workbench-publish-readiness-recovery`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, workflow`
- Paired review workstream: `review-operator-workbench-browser-preview-refresh-hardening`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `0c2a646ccd`
- Goal: Make Operator Workbench browser refresh and page-3 PREVIEW reload transactional from the user's perspective: repeated F5, source scans, live Workbench updates, mode changes, and asynchronous preview/comparison/transition loads must never expose a transient half-state, silently change the selected animation, apply an older result over a newer request, or crash the UI.
- Completion boundary: Replace mutable worker-thread browser discovery with one accepted canonical browser snapshot and latest-request-wins application; add generation/identity guards around asynchronous PREVIEW state; make F5 on page 3 retain the last usable preview until one coherent replacement is ready; preserve search/selection semantics across refresh; and add deterministic Textual/service regressions for the observed race classes. This packet owns UI/browser/preview orchestration only. It does not change Operator animation art, runtime combat behavior, canonical publication semantics, or the dedicated art-worktree Git transaction.
- Current measured state:
  - `custodian/tools/operator/ui/features/animations.py::AnimationFeature.refresh()` mutates feature-owned `_records` and is called through `asyncio.to_thread()`. Canceling/replacing the Textual worker does not stop the Python thread, so an older canceled refresh can still mutate that cache after a newer request exists.
  - `OperatorWorkbenchApp::_reload_browser()` awaits that worker scan, filters the result, immediately calls `AnimationTree.set_records()`, and, when the current selection is absent from the filtered result, falls back to the first visible record. There is no accepted/last-known-good unfiltered browser snapshot and no request generation guard.
  - Search currently reads `AnimationFeature._records`; therefore filesystem-discovery cache state and presentation filtering share one mutable owner.
  - Page 3 is PREVIEW. Entering it starts asynchronous `_load_preview()`; PREVIEW also has a 30 Hz `_preview_tick()`, optional asynchronous comparison and transition-examiner loads, Live Bridge preview export/result handling, and the one-second `_watch_selected()` session refresh.
  - `action_full_refresh()` starts `_reload_browser()` with Textual `exclusive=True`, but that only cancels/replaces the awaiting worker. It does not terminate a running `asyncio.to_thread()` source scan.
  - `_load_preview()`, `_load_preview_comparison()`, `_load_transition_examiner()`, and ordinary preview loads do not carry a common semantic/session generation token. They can complete after selection, mode, source, or session state has changed.
  - Live Bridge preview application already verifies current document path, revision, output path, and mode/source, which is a useful narrow guard, but it does not replace a common UI preview-generation contract for non-live worker results.
  - `_preview_tick()` assumes that the current `preview_view`, frame index, selection/session, and active preview mode belong to one coherent generation. During an overlapping browser/session/preview refresh, those fields can temporarily describe different requests.
  - `_watch_selected()` can reload the selected session and then refresh PREVIEW comparison/transition state while an F5 browser refresh or preview load is concurrently in flight.
  - User-observed production symptom on 2026-10-01: OPUI intermittently crashes/reloads poorly when F5/reload is used while on page 3 PREVIEW. The exact exception is not yet durably captured, so this packet must fix the confirmed stale-async/browser ownership defects and add deterministic race coverage without claiming a single unverified crash root cause.
  - A legacy packet at this same path already specified accepted-browser-snapshot, destructive-candidate stabilization, pure search, selection restoration, latest-request-wins browser refresh, and source-discovery consistency. It was not V2/indexed. This packet intentionally migrates and expands that same semantic task instead of creating a duplicate browser-hardening authority.
  - 2026-10-03 refresh: current main still has `AnimationFeature.refresh()` mutating feature-owned `_records`; no accepted browser generation or common preview generation exists, and the page-3/F5 ownership defect remains in scope. The recent block-hold import/LFS repairs do not supersede this packet. The unrelated stale real-repo UI-smoke wording assertion was corrected on main; this packet should not recreate that string-coupled assertion.
- Evidence:
  - `custodian/tools/operator/ui/app.py::{_reload_browser,_load_session,action_full_refresh,_set_mode,_load_preview,_load_preview_comparison,_load_transition_examiner,_apply_live_preview,_preview_tick,_watch_selected}`
  - `custodian/tools/operator/ui/features/animations.py::{refresh,build_navigation}`
  - `custodian/tools/operator/ui/state.py::WorkbenchUIState`
  - `custodian/tools/operator/ui/service.py::{browser_records,filter_records,session,preview,transition_candidates,transition_preview}`
  - `custodian/tools/operator/ui/widgets/animation_tree.py`
  - `custodian/tools/validation/operator_workbench_ui_smoke.py`
  - `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`
  - current Textual dependency contract in `custodian/tools/operator/ui/requirements.txt`
  - user-observed page-3 reload crashes on 2026-10-01
- Task-specific authority:
  - `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md` for shared-selection modes, PREVIEW semantics, canonical-source authority, saved/live Workbench preview behavior, and UI/backend ownership.
  - `custodian/tools/operator/ui/service.py` remains the UI/backend boundary; filesystem and canonical-source projection belongs below the Textual widgets.
  - `WorkbenchUIState` owns accepted UI/session/presentation state. Do not turn `AnimationTree` or `AnimationFeature` into a second state authority.
  - `AnimationTree` remains rendering/navigation only.
  - Existing Live Bridge revision/document guards remain authoritative for live Aseprite preview results and should be composed with, not replaced by, the new preview-generation guard.
  - The completed `operator-workbench-publish-readiness-recovery` workstream owns Git/publication readiness; this packet may coordinate F5 around active Publish mutation but must not redesign checkout/publish recovery.
- Work surface:
  - Primary owners: `custodian/tools/operator/ui/app.py`, `custodian/tools/operator/ui/state.py`, `custodian/tools/operator/ui/features/animations.py`, and `custodian/tools/operator/ui/service.py`.
  - Conditional widget touch: `custodian/tools/operator/ui/widgets/animation_tree.py` only if silent programmatic selection/event suppression cannot be achieved cleanly from the app layer.
  - Focused regression owner: `custodian/tools/validation/operator_workbench_ui_smoke.py`.
  - Supporting regression: `custodian/tools/validation/operator_animation_workbench_smoke.py` only where browser/session projections depend on source-plan behavior.
  - Docs: `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`, `custodian/docs/ai_context/CURRENT_STATE.md`, and `FILE_INDEX.md` only where live ownership/behavior changes.
- Change:
  1. Make filesystem/browser discovery side-effect free. A worker-thread discovery must return an immutable candidate value only. It must not mutate accepted browser records, search state, selection, tree contents, session state, or any feature-level cache later consumed by Search. Remove `AnimationFeature._records` as an independent authority or reduce `AnimationFeature` to a stateless provider facade.
  2. Add exactly one accepted, unfiltered canonical browser snapshot to UI state. Search and superseded visibility derive from that accepted snapshot. `AnimationTree` contents are a rendered view, not source state.
  3. Add monotonically increasing browser-refresh generation. Every asynchronous browser request captures its generation and, after each await/thread completion/stabilization delay, discards itself without mutation if it is no longer the newest request. Do not rely on Textual `exclusive=True` as thread cancellation.
  4. Preserve bounded destructive-candidate stabilization from the legacy packet. A candidate is destructive relative to the accepted snapshot when a previously accepted directional identity disappears, loses a previously accepted required body layer, or drops from truthful COMPLETE body presentation to PARTIAL/contract-mismatch. For destructive candidates:
     - initial candidate -> wait about 100 ms -> rescan;
     - if two consecutive semantic signatures agree, accept;
     - otherwise wait about 250 ms and perform one final scan;
     - accept only when two consecutive signatures agree; otherwise keep the previous accepted snapshot and report unstable canonical source.
     Tests must inject/fake timing rather than sleep in real time. Ordinary additive/non-destructive candidates may apply immediately.
  5. Candidate signatures must be semantic and deterministic: profile/group/action/direction, relevant presentation layer membership, and frame/body-clock contract needed to determine browser completeness. Do not use mtime, directory order, arbitrary glob recency, or rendered-tree state.
  6. Keep Search a pure presentation operation. Typing/clearing Search performs zero filesystem discovery, filters only the accepted snapshot, and never changes the actual Workbench/session selection merely because the selected row is hidden. Clearing Search restores the selected semantic leaf when it still exists.
  7. Preserve selection across accepted refreshes. If the current semantic identity still exists in the unfiltered accepted snapshot, keep it. Do not silently choose `filtered[0]` because Search hides the current row or because one transient scan omitted it. A deterministic fallback is allowed only after a stable confirmed deletion; emit one explicit activity event naming removed identity and replacement.
  8. Preserve reachability/browser completeness behavior from the legacy packet: read reachability once per discovery, prefer action-level status over layer-specific classifications, keep one mutable `show_superseded` owner in UI state, and report modular lower+upper COMPLETE only when their required body clocks are synchronized. Existing valid full-body presentation is COMPLETE; weapon/FX fragments remain PARTIAL as designed. Do not change reachability classifications.
  9. Add a separate monotonically increasing preview/session generation for asynchronous page-3 work. Increment/invalidate it whenever accepted semantic selection changes, PREVIEW is entered or left, preview source changes, or a browser/session refresh requires a replacement preview. Each async preview/comparison/transition result must carry enough identity to prove it still belongs to the active generation before mutating UI state.
  10. Apply the preview-generation guard to at least:
      - ordinary `_load_preview()` results;
      - `_load_preview_comparison()`;
      - `_load_transition_examiner()`;
      - delayed/debounced Workbench/live-preview export orchestration in addition to the existing document/revision guard;
      - any F5-triggered session reload path that schedules one of those loaders.
      An older completed thread/task must be silently discarded, not rendered or turned into a new selection.
  11. Make F5 on PREVIEW an atomic handoff:
      - capture whether preview playback was running;
      - pause advancement for the replacement handoff;
      - retain the current usable rendered preview/view state while browser/session replacement is in flight;
      - refresh and accept browser state using the rules above;
      - preserve semantic selection when valid;
      - reload the selected session only as needed;
      - request one replacement preview for the current generation;
      - atomically apply the coherent replacement;
      - restore prior play/pause intent only if the same semantic preview remains valid.
      Do not blank the preview or expose a partially reset frame/comparison state while replacement loads.
  12. Coalesce/defer F5 when this same OPUI instance is inside canonical PUBLISH mutation. Exactly one normal browser/session refresh runs when publication completes. Do not block unrelated preview playback, saved Workbench file watching, or Live Bridge events longer than required for the canonical mutation boundary.
  13. Harden the 30 Hz preview tick. It must no-op rather than index/render when the active preview generation is being replaced, the frame list is empty, the preview identity/source does not match active state, or frame state is not valid for the current generation. Clamp frame indices only against the active coherent view.
  14. Prevent duplicate session loads from programmatic selection restoration. One completed browser refresh with an unchanged selected identity must cause at most one intentional session projection/reload. Use the cleanest Textual seam available: silent tree selection or a bounded selection-event suppression guard. Do not create another selection authority.
  15. Preserve last-known-good state on refresh exceptions. Once an accepted snapshot/session/preview exists, a discovery/projection/preview replacement failure keeps that usable state and emits an actionable activity/error message; it must not clear the browser or replace it with an empty candidate.
  16. Keep the current contextual `Ctrl+R` contract intact: WORKBENCH -> Resize Canvas, MOTION -> Reset Motion, text entry -> no app mutation. F5 remains the global browser/session reload action and must be safe from all five modes.
- Preserve:
  - Canonical Operator source remains browser/authoring authority; runtime/catalog data does not become browser authority.
  - Existing PLAN, WORKBENCH, PREVIEW, TIMELINE, MOTION mode identities and key bindings.
  - Existing preview source choices, compare/diff/transition examiner semantics, REVIEW FPS, zoom, looping, timeline semantics, and motion-lab behavior.
  - Existing Live Bridge document/revision/output-path safety and unsaved Workbench preview behavior.
  - Existing Workbench context mismatch handling, saved-document publication boundary, and Publish transaction ownership.
  - Existing semantic animation selection and weapon/linked-profile context unless a canonical identity is stably confirmed removed.
  - Existing reachability source and classification authority.
  - The dedicated art checkout/publish readiness contract implemented by the predecessor packet.
- Non-goals:
  - Do not change Fast-chain or any other Operator art.
  - Do not change animation timing, gameplay hit windows, guard/combat logic, runtime selectors, or generated SpriteFrames behavior.
  - Do not redesign Workbench publication/Git recovery, Asset Pipeline V2, or the Aseprite authoring transaction.
  - Do not add filesystem polling/watch daemons; the existing explicit refresh/watch surfaces remain sufficient.
  - Do not add another persistent browser cache outside UI state.
  - Do not use runtime/catalog data as authoring/browser authority.
  - Do not hide the crash by disabling F5 in PREVIEW or by making PREVIEW non-interactive during ordinary operation.
  - Do not add broad per-frame telemetry or renderer capture for this logic task.
  - Do not reinterpret subjective art quality or create new visual baselines.
- Acceptance:
  - Worker-thread browser discovery is side-effect free; an intentionally delayed older scan completing after a newer scan cannot alter accepted records, Search results, selection, tree contents, or session.
  - The accepted unfiltered browser snapshot is the only browser-record state authority consumed by Search/superseded filtering.
  - Fast-chain transient-disappearance fixture: accepted `fast_01/e, fast_02/e, fast_03/e, fast_04/e`, with `fast_02/e` selected; first destructive candidate temporarily contains only Fast 01/04; recovery candidate restores all four. Fast 02/03 never disappear from the accepted rendered tree, Fast 02 remains the actual session selection, and no fallback session loads.
  - Stable-deletion fixture: two consecutive stable destructive candidates omit the same identity; the deletion is accepted after bounded confirmation, and if the deleted row was selected exactly one deterministic fallback + explicit activity event occurs.
  - Half-migration fixture: accepted synchronized lower+upper 6f COMPLETE; transient lower 7f / upper 6f candidate is not exposed as COMPLETE or accepted as stable current state; synchronized 7f/7f replacement is accepted once stable.
  - Reachability fixture proves one source parse per discovery and action-level LIVE is not overridden by layer-level ALTERNATE_LAYER/DORMANT metadata.
  - Search + F5 fixture: select Fast 02, filter to Fast 01, press F5. Fast 02 remains actual session selection while hidden; clearing Search performs zero filesystem scans and restores the Fast 02 tree leaf.
  - Out-of-order browser fixture: refresh A starts, refresh B starts later, B completes/accepts first, A completes afterward; A performs zero accepted/UI mutation.
  - Page-3 PREVIEW regression uses Textual's headless pilot or equivalent deterministic app harness: with PREVIEW loaded and playing, repeatedly issue F5 while browser discovery and preview loads are intentionally delayed/out-of-order. The app remains mounted, no exception escapes, the selected semantic identity remains correct, and the final preview belongs to the newest generation.
  - Atomic PREVIEW handoff fixture proves the previously rendered usable frame remains present until the coherent replacement is ready; playback does not advance a stale generation during the swap; prior play/pause intent is restored only for the current replacement.
  - Preview out-of-order fixture: an old ordinary preview/comparison/transition task completing after selection/source/mode generation changes cannot mutate `preview_view`, comparison/transition state, frame index, or widgets.
  - Live Bridge delayed result remains guarded by document/revision/output path and additionally cannot apply across a stale UI preview generation.
  - 30 Hz tick negative controls cover empty frames, replacement-in-progress, stale preview identity/source, and out-of-range stored frame index without crashing or rendering stale data.
  - Refresh exception fixture preserves accepted browser tree, selection, loaded session, and last usable PREVIEW while surfacing one useful error/activity message.
  - Programmatic selection restoration causes no duplicate `_load_session()` for unchanged identity.
  - F5 requested during PUBLISH mutation is coalesced/deferred; one refresh occurs after mutation completes and no canonical scan observes the in-flight path-changing publish window.
  - Existing contextual Ctrl+R Textual Pilot coverage remains green.
  - No renderer image/model-vision review is required: acceptance is deterministic UI state, worker ordering, selection/session identity, and exception behavior.
  - Active Workbench design/current-state docs describe accepted-snapshot and latest-generation behavior rather than mutable worker cache semantics.
- Validation:
  - Extend and run `python3 custodian/tools/validation/operator_workbench_ui_smoke.py` first. Use deterministic fake/barrier-controlled discovery and preview providers; do not use real sleeps for race correctness. Include the transient Fast 02/03 disappearance, stable deletion, half modular migration, out-of-order browser completion, Search+F5, page-3 repeated F5 while playing, stale preview/comparison/transition completion, refresh exception, publish-coalesced refresh, and duplicate-session-load cases.
  - Run the existing optional real Textual Pilot portion of `python3 custodian/tools/validation/operator_workbench_ui_smoke.py` when the repository's UI environment provides its pinned Textual dependencies; absence of the optional dependency must remain a truthful skip rather than a false pass.
  - Run `python3 custodian/tools/validation/operator_animation_workbench_smoke.py` if implementation changes source-discovery projection semantics below the UI service boundary; otherwise keep source-index behavior untouched.
  - Run `python3 custodian/tools/validation/run_validation.py --changed --json` once at closeout and `git diff --check`.
  - No Moment Forge, game renderer, full-motion capture, or model-vision review is required; the defect surface is UI concurrency/state ownership, and deterministic state assertions are stronger evidence.
- Task overrides: `none`
- Deferred:
  - Process-level crash dump/telemetry beyond deterministic Workbench activity/error state is deferred unless the new race fixtures fail to reproduce the user's symptom after the confirmed stale-async defects are removed. If crashes persist after this packet lands, create a narrow diagnostic follow-up from an actual traceback rather than speculating.
  - Repository-wide filesystem-reader/writer transactional publication remains outside OPUI; the predecessor publisher hardening owns only the Operator path.
  - New FX layer adoption and CREATE-capable publication remain in `operator-workbench-fx-layer-adoption`.
  - Broad shared-widget extraction for generic Asset Workbench remains owned by the Asset Workbench roadmap.

## Plan

1. Migrate browser discovery to side-effect-free candidate production and one accepted UI snapshot.
2. Add browser generation + destructive stabilization and prove selection/Search invariants.
3. Add preview/session generation and atomic PREVIEW replacement semantics.
4. Add F5/PUBLISH coalescing and 30 Hz tick guards.
5. Build deterministic race fixtures before relying on manual reproduction.
6. Reconcile Workbench design/current-state/index docs and close through the normal workstream lifecycle.

## Handoff

- Next action: Auto-claim `operator-workbench-browser-preview-refresh-hardening` after the publish-readiness paired review lands.
- Best starting files: `custodian/tools/operator/ui/app.py`, `custodian/tools/operator/ui/state.py`, `custodian/tools/operator/ui/features/animations.py`, `custodian/tools/validation/operator_workbench_ui_smoke.py`.
- Blockers or open questions: The exact historic page-3 crash traceback is not available. That does not block this packet because the stale worker-thread browser mutation, missing latest-request guard, silent filtered fallback, and unguarded async preview-result application are independently measurable defects. If crashes remain after those contracts are fixed, capture and packet the residual defect from concrete evidence.

## Completion Truth

Required before completion.

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes | no`
- Completion boundary satisfied: `yes | no`
- Acceptance satisfied: `yes | no`
- Superseded/legacy production path disposition: `removed`
- Evidence: fill with exact implementation paths and deterministic race/refresh validation results. `removed` means the legacy mutable `AnimationFeature._records`/direct-worker-to-tree authority described by the superseded pre-V2 packet no longer exists as production state authority.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `none` or concrete failures/near-misses
- Root cause / contributing factors: `none` or concise cause
- Prevention / pipeline improvement: `none` or smallest repeatable fix
- Tooling / docs drift discovered: `none` or exact stale/missing authority
- Follow-up: `none | fixed-in-scope | <workstream-id> | manual-follow-up`
- What worked: optional, one short line at most