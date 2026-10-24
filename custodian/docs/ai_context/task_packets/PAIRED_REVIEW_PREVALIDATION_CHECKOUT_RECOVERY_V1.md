# Paired Review Pre-Validation Checkout Recovery V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-prevalidation-checkout-recovery-v1`
- Authoring handoff: `auto`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `paired-review-prevalidation-checkout-recovery`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-prevalidation-checkout-recovery-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `reconstructing an absent claimed review checkout changes a protected host-validation trust boundary`
- Reviewed main: `1f739afebc7cbbba0b90820f69e0c9fc10565d06`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Restore an exactly pinned reviewer checkout after a proven pre-validation interruption so the original claim can receive fresh host validation and, only after it passes, one fresh independent review.
- Completion boundary: Add a fail-closed missing-checkout recovery class to the existing paired-review host-validation planner/apply path. Support the exact protected run `20261022T052405Z-1ce687862e23` and equivalent future runs only when all general pre-validation predicates below are authenticated. Preserve the original claim, branch, run evidence and pinned reviewed main. Do not apply this recovery to the protected run until this implementation is independently accepted.
- Current measured state: At `origin/main@1f739afebc7cbbba0b90820f69e0c9fc10565d06`, `paired_review_runner.py` can plan a pre-validation interruption only when the receipt's worktree exists, except for a separate exact Carrow recovery. The protected host-import review is claimed on branch `agent/review-agent-paired-review-failed-host-validation-import-recovery-v1`, pinned at `6e75b57ea828f5d90679ae737052a4acdefce361`; its recorded checkout is absent, no validation report pair exists, and the fresh planner stops at `dispatcher worktree/branch identity could not be verified`.
- Evidence: `.git/custodian-review-runs/review-agent-paired-review-failed-host-validation-import-recovery-v1/20261022T052405Z-1ce687862e23/`; diagnostic trace run `20261022T052415Z-57e5cf803c6e`; current exact `dispatch.py audit --json`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`.
- Task-specific authority: `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md`; current claim receipt, immutable run evidence and diagnostic trace; existing host-recovery plan/apply contract in `paired_review_runner.py`.
- Work surface: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/paired_review_host_validation.py` only if needed; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; root summary `AGENT_PAIRED_REVIEW_PREVALIDATION_CHECKOUT_RECOVERY_V1_CLAUDE_SUMMARY.md`.
- Publication inputs: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/run_trace.py`; `custodian/tools/agent/validation_manifest.json`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md`.
- Change:
  1. Authenticate a missing-checkout pre-validation interruption from one exact held claim, its immutable run metadata and receipt, the unique matching published trace, the original clean `worktree_published` event at the pinned baseline, current exact local/remote branch heads, absence of an attached or foreign worktree, and absence of reviewer launch, validation reports, prior continuation, or previous recovery journal.
  2. Prove the stop occurred before host validation could mutate the reviewer checkout. If the lifecycle trace, run stage, worktree state, process ownership, or evidence inventory leaves uncertainty about unique local-only data, refuse planning/apply unless the exact supported operator attestation is supplied and recorded. Do not infer absence from a missing directory or exclusive human ownership alone.
  3. Keep ordinary claim-receipt verification strict. Permit a missing receipt worktree only inside the host-recovery planner after the complete eligibility proof succeeds. Preserve the original absolute worktree path, branch, pinned reviewed main, target implementation identity, source-span witness, original evidence hashes, remote refs and owner/process checks in the plan.
  4. Make `--plan` read-only and SHA-256 pinned. Under the existing per-review supervisor mutex, `--apply` must revalidate every predicate and exact plan digest, write an exclusive append-only recovery journal before filesystem mutation, reject symlinks/occupied/foreign destinations, and refuse journal replay or partial prior reconstruction.
  5. Recreate only the exact original worktree path and existing branch at the pinned reviewed-main commit. Do not call ordinary `workstream.py resume`, synchronize the branch to newer main, create a new claim, or move either branch ref. Verify repository common-dir identity, branch, HEAD, and clean state before running canonical host validation.
  6. Put new host-validation reports and provenance in an append-only continuation; preserve every original file byte-for-byte. Launch at most one fresh independent reviewer only after full canonical validation genuinely passes with complete required coverage. A failed/partial recovery remains preserved and cannot replay automatically.
  7. Keep this class separate from the Carrow missing-worktree exception and failed-import sidecar recovery. Do not generalize missing-worktree allowance in normal receipt parsing or allow post-validation/post-review runs through this path.
  8. Add real temporary-Git positive and hostile fixtures for exact run/claim/trace, mismatched receipt or SHA, moved branch, missing trace, active reviewer/supervisor, occupied/symlink/foreign destination, competing branch checkout, uncertain unique evidence, report-pair partiality, existing continuation/journal, plan digest change, partial reconstruction, retry, and unchanged historical bytes.
- Preserve: All original claims, refs, worktrees, reports, source spans, reviewer outcomes and archived packet identities; exact-run Carrow recovery behavior; exact failed-import authorization and sidecar allowlist; existing ordinary and continuation recovery flows; fail-closed race-safe host validation.
- Non-goals: No duplicate claim, branch reset/rebase/force-push, synthetic lifecycle event, fabricated reviewer outcome, historical report rewrite, generic missing-worktree bypass, code changes to mapper/runtime/art, or application to the protected run before independent accepted review.
- Acceptance:
  - A1: Exact protected pre-validation run can produce a read-only plan only when every claim, trace, branch, path, process, report, continuation, and pinned-source predicate is verified.
  - A2: Ambiguous unique evidence, unknown owner, mismatched or changed refs, missing/forged trace, reviewer launch, occupied/foreign/symlink destination, altered evidence, partial report pair, previous attempt, or plan replay fails before mutation.
  - A3: Apply reconstructs only the exact original checkout path and branch at the exact pinned SHA without changing branch refs or original run files; the journal is created before checkout mutation and partial recovery fails closed.
  - A4: A successful continuation records complete report/evidence hashes and launches no reviewer before full canonical validation is green; a second launch or implicit retry is rejected.
  - A5: Ordinary claim receipt parsing remains strict, Carrow and failed-import routes retain their exact scope, and failed/post-validation/post-review runs cannot use this class.
  - A6: Canonical focused and changed-file validation, hostile real-Git fixtures, pairing checks, and diff checks pass; independent review accepts the implementation before the protected run is touched.
- Validation: Add negative tests first. Run `PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; focused run-trace/dispatch/workstream tests as changed; `python3 custodian/tools/validation/run_validation.py --test paired_review_runner_unit --json`; `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`; `python3 custodian/tools/agent/check_ai_context.py --json`; `python3 custodian/tools/agent/task_packet_index.py`; `python3 custodian/tools/agent/validate_review_pairing.py`; Python compile checks and `git diff --check`. Do not apply the protected recovery before the paired review is accepted.
- Task overrides: `none`
- Deferred: Apply to protected run `20261022T052405Z-1ce687862e23` only after the paired implementation review is accepted and a fresh exact plan proves all predicates. If evidence about unique lost data remains uncertain, preserve the claim and stop for a specific operator attestation.

## Next Handoff
- Next workstream: `review-agent-paired-review-prevalidation-checkout-recovery-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: `After implementation lands, run the fresh-context paired review; apply the new recovery only after independent acceptance and a fresh exact plan.`
- Blockers or open questions: `The protected host-import claim and run must remain unchanged until the new implementation review is accepted.`
