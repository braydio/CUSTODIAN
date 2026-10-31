# Multiple Main-Sync Source-Span Verification

Workstream: `agent-paired-review-multi-sync-source-span-verification-v1`

## Result

Implemented shared source-span verification for ordered histories containing multiple lifecycle-backed main synchronization merges. Each merge now requires exactly two correctly ordered parents, source-base/reviewed-main ancestry, a unique matching checkpoint, one matching resume or changed-sync witness (or the documented final no-op witness for the latest merge), strict ordered event consumption, and exact `git merge-tree --write-tree` output. Provenance records include each merge's parents, event identities, deterministic tree, and owned, inherited, and overlapping source paths. Workstream-authored paths remain the coverage inventory; unrelated paths imported from main do not.

The existing single-merge provenance fields remain in place. The generalized verifier supports sequential changed-sync and mixed checkpoint/resume histories. It fails closed on missing, duplicated, reused, conflicting, reordered, or mismatched witnesses, invalid parents, changed merge trees, and lost owned files.

## Validation

- Focused real-Git tests: 4 passed, including valid two-merge, mixed-witness, ordered path accounting, and missing/reused/reordered witness rejection.
- Full paired-review runner suite: `Ran 258 tests in 234.937s — OK`.
- Canonical changed-file validation: passed; selected `agent_workflow_contract` and `paired_review_runner_unit`, 2/2 passed, 0 timed out, complete coverage for both changed paths. The paired-review runner completed in 111.919s under its configured 120s limit.
- Packet authoring preflight: PASS for implementation/review pair.
- Packet category check: PASS (`agent-ops`).
- `python3 -m py_compile paired_review_host_validation.py test_paired_review_runner.py`: PASS.
- `git diff --check`: PASS.

## Preserved historical review boundary

Read-only resolution of the preserved correction-1 source span now gets past the blanket multi-merge rejection and stops at the next authentic-evidence check: `synchronization merge lacks a unique matching checkpoint`. The exact preserved run trace does not contain the checkpoint witness for the first merge. No recovery plan was generated or applied, and no original claim, worktree, report, lock, or run evidence was changed. This implementation does not invent missing lifecycle evidence; correction-1 and Procession remain held pending a supported evidence resolution.

## Files

- `custodian/tools/agent/paired_review_host_validation.py`
- `custodian/tools/agent/test_paired_review_runner.py`
- `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_MULTI_SYNC_SOURCE_SPAN_VERIFICATION_V1.md`
- `custodian/docs/ai_context/task_packets/README.md`
- `AGENT_PAIRED_REVIEW_MULTI_SYNC_SOURCE_SPAN_VERIFICATION_V1_CLAUDE_SUMMARY.md`

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `The prior resolver rejected all multi-merge source spans. The preserved correction run also lacks a unique checkpoint witness for its first merge, so its history remains unverifiable even after generic multi-merge support.`
- Root cause / contributing factors: `The resolver encoded a single-merge assumption; the preserved run's immutable lifecycle trace does not contain the required checkpoint event.`
- Prevention / pipeline improvement: `Keep lifecycle checkpoint/resume and main-sync witnesses in the authenticated run trace for every synchronization merge; never infer or reconstruct missing events from Git topology alone.`
- Tooling / docs drift discovered: `none`
- Follow-up: `manual-follow-up`
- What worked: `Disposable real-Git fixtures covered sequential, mixed-witness and adversarial multi-merge histories.`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f

## Handoff

- Next workstream: `review-agent-paired-review-multi-sync-source-span-verification-v1`
- Next packet state: `ready`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f
