# CORRECTION: OPERATOR WORKBENCH BROWSER / PREVIEW — CYCLE 2

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-workbench-browser-preview-refresh-hardening-review-corrections-1-review-corrections-2`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-operator-workbench-browser-preview-refresh-hardening-review-corrections-1`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, workflow`
- Paired review workstream: `review-operator-workbench-browser-preview-refresh-hardening-review-corrections-1-review-corrections-2`
- Review cycle: `2`
- Max automatic review cycles: `2`
- Reviewed main: `18d5f1f7392dc44ba1b70e4465e615866b7837ca`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Visual review: `none`
- Parent implementation: `operator-workbench-browser-preview-refresh-hardening`; `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_BROWSER_SNAPSHOT_HARDENING.md`
- Parent correction: `operator-workbench-browser-preview-refresh-hardening-review-corrections-1`; `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_BROWSER_PREVIEW_REFRESH_HARDENING_REVIEW_CORRECTIONS_1.md`
- Parent review: `review-operator-workbench-browser-preview-refresh-hardening-review-corrections-1`; `custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_WORKBENCH_BROWSER_PREVIEW_REFRESH_HARDENING_REVIEW_CORRECTIONS_1.md`
- Findings addressed: `R1-01, R0-04`
- Affected acceptance: Active editor document/result document/revision/output and originating UI ownership remain valid after each loader await and immediately before accepted state/widget application; all explicitly required selection/source/mode negative controls are durable.
- Goal: Reject obsolete editor-document preview results and close the retained ownership-proof gap.
- Completion boundary: Repair only live preview document ownership checks and missing deterministic controls; preserve cycle-1 fixes and existing publication/source/runtime authority.
- Current measured state: Pinned expanded UI smoke passes. Independent actual app debounce/controller/server-send/cause probe proves the generation fix, but blocking the live loader then switching active_document_path with revision 42 and UI generation 2 unchanged applies the old document result. Comparison/transition tests supersede only by generation bump and omit the requested selection/source/mode ownership matrix.
- Evidence: `REVIEW_OPERATOR_WORKBENCH_BROWSER_PREVIEW_REFRESH_HARDENING_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md` contains exact outputs and executable independent live reproduction; cycle-1 summary and archived acceptance remain the preserved contract.
- Task-specific authority: Archived parent/correction acceptance and `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`; UI accepted state is authoritative, Live Bridge is a detached projection, document/revision/output guards are mandatory.
- Work surface: `custodian/tools/operator/ui/app.py` live result and synchronous live-export preview loaders; `custodian/tools/validation/operator_workbench_ui_smoke.py`; matching design/current-state truth only if ownership documentation changes. Change controller/server only if the proven seam requires it; retain the cycle-1 command-cause generation protocol.
- Required correction: R1-01 validate active editor document ownership independently of event/result path at initial acceptance, after live export/load/comparison/transition awaits, and before mutation in `_apply_live_preview` and `_load_preview`'s synchronous live-export branch. Reject a result after document switch/disconnect even when revision and UI generation are unchanged, preserving all prior accepted preview/examiner/frame/widget state. R0-04 retain explicit barrier-controlled selection/source/mode supersession for comparison/transition plus wrong document/revision/path and active-document-switch controls through the real app issue-to-result route.
- Preserve: R0-01/R0-02/R0-03 cycle-1 fixes; one immutable accepted browser snapshot; stateless discovery/pure Search; stable deletion one fallback/event; last usable preview and play intent; dismissible exact-error modal/clock pause; all five modes/contextual Ctrl+R; source and publisher transaction ownership; pinned optional-dependency behavior; PUBLISH coalescing and tick controls.
- Non-goals: No art/gameplay, publisher/Git, layout, generic Workbench, renderer, or speculative crash diagnosis changes.
- Acceptance:
  - R1-01: Through real app debounce/controller/server send/cause result, issue a valid current export; hold the live loader, switch active editor document while preserving revision/UI generation, release. No preview/examiner/frame/widget application occurs. Repeat with document change during comparison/transition analysis awaits and a disconnected editor. Valid current same-document export still applies.
  - R1-01: Barrier synchronous live export/load in `_load_preview`, switch active editor document with equal revision, release. The former live document result cannot become accepted. Preserve the established saved-preview fallback behavior when it is valid for current UI selection.
  - R0-04: Wrong result document, wrong revision, wrong output path, missing/stale issue context each cause zero accepted mutation. Existing stale-generation rejection and valid-current acceptance remain green; ownership is captured before server send.
  - R0-04: For both comparison and transition loaders, independently supersede blocked results via actual selection, source, and mode changes; assert prior/current accepted preview/examiner/frame/widget state is not overwritten. Use explicit event barriers rather than elapsed sleeps for ordering.
  - Original parent and cycle-1 expanded browser, deletion, Search, duplicate-load, reachability, tick, modal, PUBLISH, and repeated-F5 assertions remain green.
- Validation: Run pinned `operator_workbench_ui_smoke.py` first with the new deterministic controls; replay the independent live reproduction as a rejection proof. Run animation Workbench smoke only if discovery projection changes. Run smallest changed-file closeout validation and `git diff --check`. No Moment Forge/renderer needed.
- Task overrides: `none`
- Deferred: Historic production crash requires actual traceback if it persists; FX adoption waits on clean paired review of this correction; optional polish stays excluded.

## Delta Rules

Address only R1-01 and remaining R0-04 proof; retain original finding IDs and previous dispositions. This is automatic correction cycle 2 of maximum 2. Its review must use `human_required` for unresolved correction-worthy findings rather than creating cycle 3.

## Execution Feedback

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Evidence: `_live_document_matches_selection` now requires both the active editor document and any supplied result path to match the selected Workbench. Async live results recheck document identity after live-image, comparison, and transition-analysis awaits and before accepted mutation. Synchronous F5 export/load captures document identity, rejects a switch during either export or image loading, and uses the saved Workbench fallback when still valid. Barrier-controlled tests cover the real app debounce/controller/server send/cause path, invalid document/revision/output/issue context, editor disconnect, document switches during live/comparison/transition awaits, synchronous export and load barriers, valid current results, saved fallback, and selection/source/examiner-mode supersession with preview, comparison, transition, frame, and control-widget preservation.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: The first synchronous-loader probe matched a replaced callable incorrectly; the barrier was moved into the service loader. Expanded Pilot runs also exposed a transient Textual shutdown timer error once; a clean rerun passed. The final code was then revalidated with the pinned UI environment and repository changed-file runner.
- Root cause / contributing factors: The application did not recheck active editor document identity after asynchronous work; reviewer evidence also had not isolated examiner-mode changes from preview generation changes. The system Python runner skips optional Textual coverage, so pinned-environment evidence is needed for the app-level race.
- Prevention / pipeline improvement: Check active document independently of the reported document path at every acceptance boundary; deterministic barriers now cover live export, live image, comparison, transition analysis, selection, source, examiner mode, and disconnect controls.
- Tooling / docs drift discovered: The repository changed-file runner's system-Python UI test reports `SKIP TEXTUAL PILOT`; pinned `/tmp/custodian-opui` is the authoritative app-level smoke environment. No specification/tooling mismatch was found.
- Follow-up: `review-operator-workbench-browser-preview-refresh-hardening-review-corrections-1-review-corrections-2`
- What worked: The real server send/cause route and explicit async barriers give deterministic stale-result proofs without renderer capture.

## Next Handoff
- Next workstream: review-operator-workbench-browser-preview-refresh-hardening-review-corrections-1-review-corrections-2
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab
- Refresh reason: none
- Next action: Land correction cycle 2, then claim the fresh paired review; if clean, surface the FX-adoption lane's exact live gate.
- Blockers or open questions: Unresolved correction-worthy findings at cycle-2 review require human decision; no cycle 3.
