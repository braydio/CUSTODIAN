# Trusted Review Validator Recertification V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-validator-recertification-v1`
- Category: `agent-ops`
- Authoring handoff: `auto`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P0`
- Depends on: `none`
- Locks: `workstream-finish-sync-provenance`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-validator-recertification-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Source-span provenance is a security boundary for independent review; finish must not publish merge histories that the current verifier cannot authenticate.`
- Reviewed main: `ad42f092761ed222b8da2fb0d41a61388f70d5fc`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f
- Visual review: `none`
- Goal: Establish a new independently reviewable source identity for the current multi-sync validator and ensure the lifecycle producer cannot land a workstream containing an unauthenticated synchronization merge.
- Completion boundary: Add a fail-closed `workstream.py finish` pre-landing provenance check for every source-span main synchronization merge, with focused real-Git regressions. The paired review independently inspects the complete current source-span validator and its single/multi-merge behavior. Do not retroactively accept or close any prior review.
- Current measured state: At `origin/main@ad42f092761ed222b8da2fb0d41a61388f70d5fc`, `_finish_impl` checks the special archived-packet transition with `_archive_transition_tip_error`, then pushes the task branch before its final `sync_main` call and `main_sync` trace event. There is no general pre-push check that all earlier source-span main merges have unique lifecycle witnesses. Normal `resume` synchronizes before recording `worktree_resumed`; `finish` records `main_sync` after its own successful synchronization. The source-span verifier in `paired_review_host_validation.py` correctly fails closed on missing witnesses.
- Evidence: `custodian/tools/agent/workstream.py::sync_main`, `_finish_impl`, `_archive_transition_tip_error`, and `resume`; `custodian/tools/agent/workflow_control.py::RunTrace`; `custodian/tools/agent/paired_review_host_validation.py` source-span resolver; `custodian/tools/agent/test_workstream.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`. Historical finding evidence remains in preserved run `20261031T064202Z-609019f2578d`: reviewer packet SHA-256 `e9da89eff41917d779c035452e7938655e880be15f257cf908e42fd3e8fd6359`, summary SHA-256 `b31a612ee339afe894fbe8a0d923293f5e48343c917c38fe8a0fabf374768cca`.
- Task-specific authority: This packet; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; existing source-span validation and trace contracts in the evidence paths above.
- Work surface: Primary: `custodian/tools/agent/workstream.py`. Tests: `custodian/tools/agent/test_workstream.py` and relevant existing multi-sync coverage in `custodian/tools/agent/test_paired_review_runner.py`. Documentation only if current lifecycle wording is materially inaccurate.
- Publication inputs: `custodian/tools/agent/workstream.py`; `custodian/tools/agent/workflow_control.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_workstream.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/TASK_PACKET_CATEGORIES.json`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`
- Change:
  1. Before `finish` pushes or lands a task branch, inspect its source-bearing first-parent history from the authenticated claim base and identify every merge that imports main history.
  2. Require each such merge to have exactly one valid, ordered lifecycle witness supported by the existing source-span contract (the exact `main_sync(changed=true)` or checkpoint/resume form). Bind the event to the original workstream/run, branch, worktree, merge head and second parent; verify first-parent continuity, ancestry, deterministic merge tree, and event uniqueness. Reject missing, malformed, duplicated, reordered, reused, contradictory, or unsupported witnesses.
  3. Ensure the finish-generated synchronization records and durably publishes its exact witness before landing. If the event cannot be published or the provenance check fails, stop before main landing and preserve the branch and evidence for normal recovery.
  4. Keep main-inherited paths separate from workstream-authored paths. Reuse existing verifier contracts where possible; do not weaken or special-case the source-span validator.
  5. Add disposable real-Git positive and negative finish tests. Prove the ordinary single sync and supported resume path still work, while an unwitnessed pre-existing merge is rejected before branch publication/landing.
- Preserve: The current multi-sync validator and its historical fail-closed result; all existing single-merge, multi-merge, post-archive, and conflict-reconciliation behavior; the two preserved merge objects; the original multi-sync review claim/run/worktree and R0-01 evidence; the coverage-correction and Procession claims, worktrees, locks, plans and outcomes; all existing source-span policies and report identities.
- Non-goals: No validator rewrite; no historical lifecycle-event synthesis; no compatibility exception for the two old merges; no recovery plan application; no change to coverage policy, source ownership rules, review outcomes or claim locks; no Procession/gameplay changes; no new unrelated infrastructure.
- Acceptance:
  1. A disposable real-Git history with an unwitnessed source-span main merge is rejected by `finish` before its task branch is pushed or main is changed.
  2. A supported merge with its unique exact trace witness passes provenance preflight; finish-generated sync evidence is durably available before landing.
  3. Adversarial tests reject wrong parent order, unrelated second parent, wrong merge tree, missing/duplicate/reordered/reused event, wrong run/branch/worktree/head/main SHA, malformed trace, extra merge, and source paths falsely attributed to the task.
  4. Existing ordinary finish, single-sync, checkpoint/resume, multi-sync validator, inherited-path and archive-conflict tests remain green.
  5. The fresh paired reviewer independently inspects the complete current source-span validator, its relevant helper paths and adversarial tests, not only the producer diff. The reviewer confirms the new source identity does not turn the historical R0-01 into acceptance.
  6. The original findings packet and summary retain the hashes recorded above; all protected claims, worktrees, evidence, locks and reviewer outcomes remain unchanged.
  7. Canonical changed-file validation reports complete coverage and no hidden, skipped, failing or timed-out checks.
- Validation: Add focused real-Git regressions first. Run `python3 -m unittest custodian.tools.agent.test_workstream -v`; `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; canonical `python3 custodian/tools/validation/run_validation.py --changed --json` with complete coverage; targeted implementation/review packet authoring and category checks; and `git diff --check`. Record actual test counts and any timeouts.
- Task overrides: `none`
- Deferred: Any same-run recovery of the historical multi-sync review, coverage-correction review, or Procession review. A successful new review does not release or pass those claims; each requires a fresh ownership/dependency audit and its own supported continuation.

## Context Pack

- Repomix: `none`

## Handoff

- Next workstream: `review-agent-paired-review-validator-recertification-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f
- Refresh instruction: `Independently inspect the complete current source-span validator and the landed finish-time witness guard. Keep historical R0-01 unresolved.`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f
