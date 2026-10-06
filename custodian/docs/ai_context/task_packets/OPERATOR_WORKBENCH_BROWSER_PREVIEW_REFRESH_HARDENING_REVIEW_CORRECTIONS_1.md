# CORRECTION: OPERATOR WORKBENCH BROWSER / PREVIEW REFRESH HARDENING — CYCLE 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-workbench-browser-preview-refresh-hardening-review-corrections-1`
- Status: `ready`
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
