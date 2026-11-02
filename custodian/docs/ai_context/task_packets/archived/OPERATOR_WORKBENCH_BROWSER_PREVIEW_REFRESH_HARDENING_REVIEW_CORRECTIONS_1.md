# CORRECTION: OPERATOR WORKBENCH BROWSER / PREVIEW REFRESH HARDENING — CYCLE 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-workbench-browser-preview-refresh-hardening-review-corrections-1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-operator-workbench-browser-preview-refresh-hardening`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, workflow`
- Paired review workstream: `review-operator-workbench-browser-preview-refresh-hardening-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `83f5a9dcebf91df7e853a02fbaffbb652490b777`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Visual review: `none`
- Parent implementation: `operator-workbench-browser-preview-refresh-hardening`; `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_BROWSER_SNAPSHOT_HARDENING.md`
- Parent review: `review-operator-workbench-browser-preview-refresh-hardening`; `custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_WORKBENCH_BROWSER_SNAPSHOT_HARDENING.md`
- Findings addressed: `R0-01, R0-02, R0-03, R0-04`
- Affected acceptance: Older browser/session results cannot mutate accepted UI after supersession; failed refresh preserves coherent accepted browser/session/preview; delayed Live Bridge exports retain original UI generation; required deterministic negative controls prove the original contract.
- Goal: Close the independently reproduced browser-session ownership, failed-projection transaction, and delayed live-export generation defects, and supply the missing focused acceptance proofs.
- Completion boundary: Correct only the cited seams and tests; preserve parent architecture and successful acceptance behavior. Close with paired independent re-review.
- Current measured state: Green pinned smoke still permits stale generation-2 session acceptance while browser generation 3 is active; failed stable-deletion projection leaves accepted selected session absent from browser; generation-1 live export overwrites generation-2 preview. Parent required negative controls remain incomplete.
- Evidence: `REVIEW_OPERATOR_WORKBENCH_BROWSER_PREVIEW_REFRESH_HARDENING_CLAUDE_SUMMARY.md` contains exact findings, output values, and executable reproduction code.
- Task-specific authority: Parent archived packet acceptance and `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`; UI state remains accepted authority and Live Bridge document/revision/output guards remain mandatory.
- Work surface: `custodian/tools/operator/ui/app.py`, `state.py`, `live_bridge_controller.py` only where issue-to-result ownership needs it; `custodian/tools/validation/operator_workbench_ui_smoke.py`; `service.py`/tree only if needed for transactional projection; matching current-state/design docs only where corrected ownership changes.
- Required correction: R0-01 bind browser-owned session projection to its browser request before any accepted state/widget mutation. R0-02 stage or restore dependent browser/session projections on failure and emit fallback only for successful stable deletion. R0-03 carry originating UI generation/identity from live export command issue to result acceptance rather than assigning current generation on receipt. R0-04 add the focused end-to-end assertions below.
- Preserve: Single immutable accepted browser snapshot; stateless discovery; pure Search/superseded filtering; stabilized deletion; last usable preview; pinned error-dialog dismissal/literal message and clock pause; latest-preview guards; canonical source and publisher transaction ownership; document/revision/output-path safety; all five modes and contextual Ctrl+R.
- Non-goals: No Operator art/gameplay changes, publisher/Git redesign, layout polish, generic Asset Workbench extraction, screenshot capture, or speculation about the original crash.
- Acceptance:
  - R0-01: Barrier A in session projection, start B and block B in discovery, release A. A changes no accepted session/selection/tree/preview/widgets after B's browser generation exists. Direct selection races remain latest-request-wins.
  - R0-02: Stable deletion plus failed fallback session projection retains the prior accepted snapshot/tree/selection/session/usable preview and reports one useful error. Successful stable deletion still exposes deletion with exactly one fallback load and one removal event.
  - R0-03: Issue live export in generation A; prepare generation B for the same document/revision/path, then deliver A's result. It performs no accepted mutation. A valid current export still applies. Keep wrong-document/revision/path negative controls and document-switch checks during loader awaits.
  - R0-04: Assert transient Fast 02/03 disappearance preserves accepted tree and Fast 02 session with zero fallback loads; stable deletion asserts one fallback/event; Search hides Fast 02 while F5 runs, then clearing restores it with zero additional discovery; unchanged refresh causes at most one session projection.
  - R0-04: Delay comparison and transition results across selection/source/mode generations and assert no stale application; tick controls cover empty frames, replacement, stale identity/source and out-of-range index; barrier F5 during PUBLISH and assert no in-flight scan plus exactly one postmutation refresh; discovery reads reachability once and action LIVE takes precedence over layer classifications.
  - Original parent acceptance remains green; no worker/widget/provider browser authority is added.
- Validation: Run the expanded pinned `operator_workbench_ui_smoke.py` first using deterministic barriers/fake timing. Run `operator_animation_workbench_smoke.py` if discovery projection changes. Run the smallest changed-file validation and `git diff --check` at closeout. No renderer or Moment Forge needed.
- Task overrides: `none`
- Deferred: Residual production crash diagnosis requires an actual traceback if it persists; optional layout/messages remain excluded.

## Delta Rules

Address only R0-01 through R0-04. Preserve IDs for re-review dispositions. Re-review is cycle 1 of maximum 2; unresolved findings at the maximum cycle require human decision rather than another automatic cycle.

## Next Handoff

- Next workstream: `review-operator-workbench-browser-preview-refresh-hardening-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh reason: `none`
- Next action: Complete correction cycle 1, then claim its fresh independent paired review.
- Blockers or open questions: `none`


## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Evidence: R0-01 now carries browser generation into `_load_session` and validates it after the session/watch projection await but before accepted mutation. R0-02 resolves against the candidate and stages browser snapshot/tree commit until the selected session succeeds; fallback activity is emitted only after commit. R0-03 binds generation, semantic identity, and source to the issued Live Bridge command sequence before send, copies that context onto the result event, and rejects missing/stale ownership. `operator_workbench_ui_smoke.py` now asserts browser/session barriers, failed and successful stable deletion, direct selection latest-wins, transient Fast 02/03 recovery, Search-hidden F5, one session projection, stale/current live results, stale comparison/transition results, tick controls, PUBLISH coalescing, and reachability precedence.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: The first transactional deletion regression revealed selection resolution still consulted the accepted snapshot instead of the staged candidate; the end-to-end test caught and corrected that remaining defect. The first changed-file validation attempt lacked `websockets` in system Python; running the expanded optional Textual Pilot through the 20-second runner limit also timed out.
- Root cause / contributing factors: Browser/session generation ownership was checked only after session state had already committed, and Live Bridge result handling reconstructed ownership from receiver state instead of issue-time request context. The UI smoke's expanded Pilot duration exceeded its prior runner timeout.
- Prevention / pipeline improvement: Added event/barrier-controlled tests at the app/provider boundaries and issue-time command-cause context propagation. Increased only the `operator_workbench_ui` validation timeout to 60 seconds; final changed-file validation ran with the pinned UI environment.
- Tooling / docs drift discovered: The system Python does not provide the optional Operator UI/Live Bridge packages; the repository UI virtual environment supplies them.
- Follow-up: `review-operator-workbench-browser-preview-refresh-hardening-review-corrections-1`
- What worked: Deterministic probes reproduced each review finding and now pass as regression tests.

## Next Handoff
- Next workstream: `review-operator-workbench-browser-preview-refresh-hardening-review-corrections-1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh reason: `none`
- Next action: Claim the paired fresh-context re-review and independently verify R0-01 through R0-04.
- Blockers or open questions: none; the original production crash traceback remains unavailable and is not used to infer a crash root cause.

## Independent Review

- Status: `findings`
- Review workstream: `review-operator-workbench-browser-preview-refresh-hardening-review-corrections-1`
- Reviewed on main: `18d5f1f7392dc44ba1b70e4465e615866b7837ca`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, runtime, workflow`
- Blocking defects: `1`
- Material evidence gaps: `1`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Retained finding dispositions: `R0-01 fixed; R0-02 fixed; R0-03 fixed; R0-04 unresolved`
- Correction finding IDs: `R1-01, R0-04`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_OPERATOR_WORKBENCH_BROWSER_PREVIEW_REFRESH_HARDENING_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `operator-workbench-browser-preview-refresh-hardening-review-corrections-1-review-corrections-2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
