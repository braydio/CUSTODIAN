# REVIEW: OPERATOR WORKBENCH BROWSER / PREVIEW REFRESH HARDENING

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-workbench-browser-preview-refresh-hardening`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `operator-workbench-browser-preview-refresh-hardening`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Review: `none`
- Review target workstream: `operator-workbench-browser-preview-refresh-hardening`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_BROWSER_SNAPSHOT_HARDENING.md`
- Reviewed main: `4df3611c`
- Review modes: `code, architecture, runtime, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the landed browser/PREVIEW hardening makes F5 and asynchronous refresh latest-request-wins without creating a second state authority, hiding genuine deletions, weakening Live Bridge safety, or converting page-3 crashes into silent stale-state corruption.
- Reviewed implementation acceptance: Review the archived implementation packet's complete acceptance contract, especially side-effect-free discovery, one accepted unfiltered browser snapshot, destructive-candidate stabilization, pure Search, confirmed-deletion fallback only, browser/preview generations, atomic page-3 replacement while playing, stale async result rejection, F5/PUBLISH coalescing, 30 Hz tick guards, error preservation, and no duplicate session loads.
- Review evidence: Reuse the implementation's deterministic barrier/fake-provider race fixtures, Textual Pilot results, state-transition assertions, worker-generation traces where retained, changed-file validation report, and closing summary. Recapture no renderer media because this packet's acceptance is UI state/concurrency rather than visual composition.
- Correction threshold: Create correction work for any confirmed stale-result application, silent selection change on transient/filter state, preview-generation mix, escaped page-3 refresh exception, duplicate session load violating acceptance, browser authority duplication, or evidence gap that prevents confidence in those guarantees. Optional messaging/layout polish is non-blocking.
- Focused validation: Inspect ownership in `app.py`, `state.py`, `features/animations.py`, and `service.py`; rerun `python3 custodian/tools/validation/operator_workbench_ui_smoke.py` with its deterministic race fixtures and available Textual Pilot coverage. Run `python3 custodian/tools/validation/operator_animation_workbench_smoke.py` only if the landed implementation touched source-discovery semantics below the UI boundary. Finish with the smallest changed-file validation needed to verify findings.
- Review focus:
  - No mutable browser cache may be owned by worker/provider code after the accepted snapshot becomes UI authority.
  - `exclusive=True` must not be mistaken for thread cancellation; every stale completion needs an explicit generation/identity rejection path.
  - Search must not mutate canonical selection, and F5 must not use a filtered view to infer deletion.
  - Stable deletion must still become visible after confirmation; hardening must not freeze stale browser state forever.
  - PREVIEW replacement must preserve the last usable view until the newest coherent view is ready and must not let the 30 Hz tick bridge generations.
  - Live Bridge's document/revision/output guards must remain intact and be strengthened, not duplicated or bypassed.
  - One refresh should not recursively trigger duplicate selection/session work.
  - Publish coordination may defer/coalesce F5 but must not broaden this review into Git transaction redesign.
- Acceptance: Produce a findings-first independent review of live `main`. Record a `passed` receipt or concrete findings. Give each finding a stable cycle-scoped ID (`R<cycle>-<NN>`) and the required class, domain, affected acceptance, evidence, disposition, and rationale. Blocking defects and material acceptance-proof gaps create `operator-workbench-browser-preview-refresh-hardening-review-corrections-<n>` plus its paired review packet. Do not patch reviewed implementation code.
- Non-goals: Do not redesign Operator art/runtime behavior, publication Git recovery, generic Asset Workbench, or Textual layout. Do not require screenshots or subjective visual judgment for deterministic state/concurrency acceptance.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after the implementation dependency is complete and archived on `origin/main`.
2. Read root/local AGENTS, the archived implementation packet and closing summary, current Workbench design, and the landed UI orchestration.
3. Start from deterministic race tests rather than manually mashing F5.
4. Verify old-browser and old-preview completions are provably unable to mutate accepted state after a newer generation exists.
5. Verify a genuine stable deletion still advances state and that Search-hidden selection remains session authority.
6. Verify page-3 repeated F5 while playing remains mounted and coherent with no escaped exception and no stale render/session application.
7. Verify exception handling retains the previous usable state rather than swallowing a corrupted partial refresh.
8. Record receipt/findings and scaffold correction work only when the correction threshold is met.
9. Complete/archive through normal paired-review lifecycle.

## Human Decision Gate

No subjective visual/art-direction decision is expected. If a residual crash cannot be reproduced by the deterministic harness and only a user terminal traceback can distinguish causes, record an evidence gap and request that exact traceback rather than guessing.

## Handoff

- Next action: Claim after `operator-workbench-browser-preview-refresh-hardening` completes.
- Blockers or open questions: None for ordinary review; a genuinely unreproduced residual process crash may require user-provided traceback evidence.
