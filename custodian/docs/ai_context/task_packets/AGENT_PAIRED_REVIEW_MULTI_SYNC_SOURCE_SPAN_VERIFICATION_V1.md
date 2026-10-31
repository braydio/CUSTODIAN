# Multiple Main-Sync Source-Span Verification

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-multi-sync-source-span-verification-v1`
- Category: `agent-ops`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `paired-review-multi-sync-source-span`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-multi-sync-source-span-verification-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Source-span authentication gates independent reviews and must correctly verify repeated lifecycle-backed synchronization without widening source coverage or admitting forged history.`
- Reviewed main: `4693df7b1fa6184b6ea4596f5a672d0f60c123b0`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f
- Visual review: `none`
- Goal: Authenticate multiple legitimate main synchronization merges in one implementation source span while preserving exact implementation scope and review provenance.
- Completion boundary: Replace the split-source-span resolver's single-merge assumption with ordered, per-merge lifecycle and deterministic-tree verification; add real-Git positive and adversarial regression coverage; land one correction and obtain its fresh paired review. Do not recover or apply the preserved coverage or Procession plans in this workstream.
- Current measured state: At `main@4693df7b1fa6184b6ea4596f5a672d0f60c123b0`, `custodian/tools/agent/paired_review_host_validation.py` rejects more than one merge in `_split_landing_source_span`. The archived lifecycle contract requires individually witnessed synchronization merges. The preserved correction history includes the two-parent merges `d66faed6ea9a267d8c227a352a42e214419e19d8` and `10d8fc2a6fe6e08d32002e012795da00361f0f4a`; both are ordinary workstream-to-main synchronizations. The prior correction review remains held before reviewer launch and is not modified by this task.
- Evidence: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/workflow_control.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; preserved Git merge objects named above.
- Task-specific authority: This packet; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`, especially paired-review source provenance and main-sync witnesses; current source-span and lifecycle trace implementations named under Evidence.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; focused real-Git fixtures in `custodian/tools/agent/test_paired_review_runner.py`; any directly required trace-schema helper in `custodian/tools/agent/workstream.py` or `custodian/tools/agent/workflow_control.py`.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/test_paired_review_runner.py`, `custodian/tools/agent/workstream.py`, `custodian/tools/agent/workflow_control.py`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`, `custodian/tools/validation/run_validation.py`, `custodian/tools/validation/validation_manifest.json`, `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`, `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`, `custodian/docs/ai_context/TASK_PACKET_CATEGORIES.json`, `custodian/docs/ai_context/TASK_PACKET_CATEGORY_AUTHORING.md`
- Change:
  1. Authenticate every source-span merge in first-parent order. Require exactly two parents, the expected prior first-parent, a second parent descended from the recorded source base and contained in the reviewed main, and a deterministic `git merge-tree --write-tree` match.
  2. Bind each merge to its own unique, authenticated lifecycle event set: checkpoint/resume or `main_sync(changed=true)` as appropriate, plus the exact no-op witness where required by the existing lifecycle contract. Enforce strict event order, run/branch/worktree identity, unique event consumption, and rejection of missing, repeated, reused, reordered, or conflicting witnesses.
  3. Keep workstream-authored paths separate from paths inherited from synchronized main. Preserve source paths touched on both sides in implementation coverage, while excluding unrelated inherited main paths. Preserve exact source path inventory, file modes, hashes, source-base ancestry, archived packet identity, pinned reviewed-main identity, and report accounting.
  4. Preserve current single-merge and post-archive source-follow-up behavior. Emit a complete ordered per-merge provenance record for multi-merge spans without changing the historical review identity or introducing a Procession-specific exception.
  5. Reject octopus/wrong-parent/forked merges, nondeterministic or unauthorized conflict-resolution trees, untraced merges, and any source path or lifecycle event that cannot be authenticated under existing rules.
- Preserve: Existing single-merge, checkpoint/resume, post-archive follow-up, Procession attestation, pinned-manifest, validation selection, report hashing, source-scope and canonical review lifecycle behavior. Preserve all held review claims, branches, worktrees, reports, locks, run metadata and evidence byte-for-byte.
- Non-goals: Do not change Procession gameplay/runtime code, coverage policy, source attestations, reviewed implementation acceptance criteria, recovery plans, or reviewer outcomes. Do not apply either original held recovery plan, release any protected lock, reclaim or duplicate `agent-paired-review-merged-source-validation-isolation-v1`, alter historical evidence, or add a special-case exception for the prior correction.
- Acceptance:
  1. A disposable real-Git history with two sequential lifecycle-backed main-sync merges and an implementation commit between them resolves with exact source paths and two ordered provenance records.
  2. The same behavior is demonstrated against the preserved two-merge topology when its authenticated trace is available from repository evidence; the test does not depend on private untracked review-run files.
  3. Main changes inherited through either merge do not enter implementation coverage unless the workstream independently authored the same path; overlapping source paths remain covered.
  4. Existing single-merge and post-archive source-follow-up fixtures continue to pass unchanged.
  5. Adversarial fixtures reject a missing/untraced merge, octopus merge, wrong or forked parents, wrong second-parent ancestry, mismatched deterministic merge tree, unsupported conflict resolution, absent/duplicate/reordered/reused/conflicting trace witnesses, incorrect checkpoint/resume identity, inherited-main path misclassified as authored, omitted changed implementation source, undocumented/out-of-scope path, and altered modes or source hashes.
  6. Existing report, claim, run, reviewed-main, packet identity, selected-test ownership, complete-coverage, failed/timeout non-PASS, and protected-evidence checks remain unchanged and green.
  7. The original held review claims and evidence are unchanged. This workstream does not apply their plans or claim their reviews are accepted.
- Validation: Run the focused new real-Git tests; `python3 -m unittest custodian.tools.agent.test_paired_review_runner`; canonical changed-file validation against the exact landed source span with full coverage; `python3 custodian/tools/agent/validate_task_packet_authoring.py` on the implementation/review pair; `python3 custodian/tools/agent/check_packet_categories.py` on the pair; and `git diff --check`. Preserve actual failures and timings; do not modify global validation policy merely to force a pass.
- Task overrides: `none`
- Deferred: Same-run host-validation recovery for `review-agent-paired-review-excluded-coverage-evidence-recovery-v1-review-corrections-1`, the original coverage review, and Procession. Each requires its own exact run, fresh plan, authorization and normal independent review/closeout sequence after this correction's independent PASS.

## Context Pack

- Repomix: `none`

## Handoff

- Next workstream: `review-agent-paired-review-multi-sync-source-span-verification-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f
- Refresh instruction: `Use the exact landed correction and durable test evidence; independently inspect the per-merge lifecycle bindings and adversarial coverage.`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f
