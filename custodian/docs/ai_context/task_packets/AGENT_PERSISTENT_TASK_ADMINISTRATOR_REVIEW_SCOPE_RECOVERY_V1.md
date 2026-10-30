# P0 — Recover the original Persistent Task Administrator review source-scope gate

- Packet schema: custodian.task_packet.v2
- Workstream: agent-persistent-task-administrator-review-scope-recovery-v1
- Category: agent-ops
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: auto
- Priority: P0
- Depends on: none
- Locks: paired-review-source-provenance
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, workflow
- Paired review workstream: review-agent-persistent-task-administrator-review-scope-recovery-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: An immutable historical source-scope admission changes an independent review's trusted host-validation boundary and must be independently falsified.
- Reviewed main: 1ea8acc6a95866c04c4cfd3957e897a1d831a0dc
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae424b0-a48c-83ea-9c8e-68e3c48fa59d
- Visual review: none
- Goal: Unblock the **already-claimed** `review-agent-persistent-task-administrator-v1` by authenticating the ONE omitted implementation source path, while preserving its exact original reviewed-main SHA, source/packet Git identities, original claim/worktree, private run files, validation coverage and independent reviewer authority.
- Completion boundary: Publish and validate one independently review-gated exact historical source-scope attestation; ensure `paired_review_runner.py --recover-host-validation --plan`, fresh `--apply`/coordinator validation and post-review verification all recognize the same later-approved correction without repinning the original review or editing its evidence. This correction's implementation may land before its review, but the exception MUST stay ineffective until THIS pair's independent accepted PASS.
- Current measured state: Administrator slice A is landed on `main@1ea8acc6a95866c04c4cfd3957e897a1d831a0dc`. The archived implementation packet at `custodian/docs/ai_context/task_packets/archived/AGENT_PERSISTENT_TASK_ADMINISTRATOR_V1.md` has Git blob `3387dd7346b12aa41ea4fd496f0b162d245cc8a9` and omits `custodian/tools/agent/task_administrator_service.py`. The omitted regular source is mode `100644`, blob `326e0b074d0b84dbfe35cde7714de852dbbb91af` at the original pinned implementation. The original review `review-agent-persistent-task-administrator-v1` is claimed, has failed prelaunch host-validation evidence, no reviewer verdict, and a protected worktree. The persistent coordination root is not to be overwritten. The run ID and implementation archive commit must be read from the original host evidence, not guessed.
- Evidence: `main@1ea8acc6a95866c04c4cfd3957e897a1d831a0dc`, above two Git blobs and mode, the existing review branch `agent/review-agent-persistent-task-administrator-v1`, and host-private `.git/custodian-review-runs/review-agent-persistent-task-administrator-v1/<original-run-id>/`. Existing Procession and Grunt exact post-hoc attestation gates are reference behavior, NOT new authorizations.
- Task-specific authority: `AGENTS.md`, `custodian/AGENTS.md`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`, `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/review_outcome.py`, `custodian/tools/agent/review_receipt_delta.py`.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/test_paired_review_runner.py` and narrowly relevant existing host-validation tests, NEW `custodian/docs/ai_context/review_scope_attestations/agent_persistent_task_administrator_service_scope_v1.json`, `custodian/tools/validation/validation_manifest.json` only if required to cover changed tests/attestation, this packet's narrowly factual handoff. No edits to the original archived administrator packet, original review packet/branch, or host-private evidence.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/test_paired_review_runner.py`, `custodian/tools/agent/review_outcome.py`, `custodian/tools/agent/review_receipt_delta.py`, `custodian/docs/ai_context/review_scope_attestations/road_procession_p1_recipe_scope_v1.json`, `custodian/docs/ai_context/task_packets/archived/AGENT_PERSISTENT_TASK_ADMINISTRATOR_V1.md`, `custodian/docs/ai_context/task_packets/REVIEW_AGENT_PERSISTENT_TASK_ADMINISTRATOR_V1.md`.
- Change: Use the existing post-hoc historical-scope approval contract, not a new dispatcher/recovery subsystem. Derive and assert the **exact original changed source-path inventory**; attest ONLY the omitted `task_administrator_service.py` (no inferred second omissions). Bind the original archived packet path/blob, original canonical archive implementation commit/parent/tree provenance as actually resolved, original reviewed main `1ea8acc6a95866c04c4cfd3957e897a1d831a0dc`, source file path/mode/blob and an independently accepted correction review receipt. Reject before independently accepted PASS or if the source inventory differs. In the original review's host-recovery planner, separate immutable `reviewed_main` from newly fetched, verified `approval_main`; the latter is ONLY for validating this post-hoc acceptance. Bind the approval commit and attestation identity into the plan digest, fail if it advances between plan and apply (re-plan rather than silently substituting). Ensure `run_coordinator_validation` and `_verify_host_validation_at_commit` reproduce the *same* authority while validating actual source against the preserved original reviewed-main tree. The existing `origin/main`-ancestry/independent-PASS gates remain required. No unrestricted `Work surface` edits, `-m` overrides, source path glob permission, review PASS fabrication or generic recovery bypass.
- Preserve: All original implementation and review Git blobs, original exact reviewer claim/branch/worktree, original failed host reports and immutable metadata, existing review-run ID, existing process/owner locks, detached/dirty coordination checkouts, independent review outcome truth and subsequent B/C admission gates. Do not create another claim for the original review.
- Non-goals: No audit/migration of other workstreams; no revised executor design; no B/C implementation; no host worktree deletion; no credential/model budget changes; no new source-scope exceptions for Procession, OR1, Grunt, ES1 or Carrow; no altering unrelated root changes or production runtime.
- Acceptance: Preapproval original reviewed-main scope still fails. After this correction has **genuine independent accepted PASS**, the existing original review plan/host validation succeeds for the exact one previously omitted source and unchanged source coverage. Negative cases (wrong run/main, branch, old packet blob, source filename, extra missing file, altered mode/blob, unapproved JSON, forged/expired/moved approval main, wrong PASS receipt, changed host evidence, changed root, duplicate continuation) fail closed. Same-run `review-agent-persistent-task-administrator-v1` remains NOT passed until its own fresh reviewer actually runs and returns canonical accepted PASS.
- Validation: Disposable Git-history tests reproducing original administrator archive, preapproval failure and postapproval exact one-path authorization; negative tests for every above key; focused paired-review runner/host-validation tests, `validate_task_packet_authoring.py` for this pair, `validate_review_pairing.py`, `run_validation.py --changed --base origin/main --json` with full changed-file coverage; `git diff --check`. Do not call a future attestation accepted without an independently verified review receipt.
- Task overrides: none
- Deferred: After the correction's independent PASS, the original administrator reviewer must be recovered **as the same claim** with the original host-private run ID. A clean detached coordinator at the *then-current* `origin/main` sharing Git common dir may be created only if necessary; the preexisting dirty/behind root stays untouched.

## Exact Codex execution and stop boundary

1. Claim THIS correction workstream through `dispatch.py claim agent-persistent-task-administrator-review-scope-recovery-v1 --agent codex` if eligible; implement in its new isolated checkout. Do not resume, start or mutate `review-agent-persistent-task-administrator-v1` during the correction.
2. Inspect the original archived packet and pinned implementation history. Compare the immutable full source-path inventory and source Git blobs, not just the reported first validator error. If more than the one authorized omitted path exists, stop and report actual additional paths; never silently widen.
3. Extend the *existing* post-hoc approval validation so the host recovery planner can consult a separately pinned newer `origin/main` ONLY for this accepted attestation, without changing original `reviewed_main`. Ensure planning, apply/validation and completion verification match. Keep existing contracts as the owners.
4. Run focused and canonical validation; land via `workstream.py finish` and then launch THIS correction's genuine paired review. Do not self-approve.
5. After genuine independent PASS and main publication, print the original-review same-run recovery `--plan` command and the exact prerequisites; do not run it inside this correction checkout. Do not start Phase B or C.

## Handoff

- Next workstream: review-agent-persistent-task-administrator-review-scope-recovery-v1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae424b0-a48c-83ea-9c8e-68e3c48fa59d
- Refresh reason: none
- Next action: Land independently review-gated source-scope fix, then re-plan the existing original administrator review from a clean coordinator using its original run ID.
- Blockers or open questions: Original reviewer remains unaccepted; host-private original run metadata and no-conflicting-owner proof are needed only at same-run recovery time.
