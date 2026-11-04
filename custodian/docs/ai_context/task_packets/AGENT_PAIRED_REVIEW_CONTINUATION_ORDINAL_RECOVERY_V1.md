# Paired-Review Continuation Ordinal Recovery

- Packet schema: custodian.task_packet.v2
- Workstream: agent-paired-review-continuation-ordinal-recovery-v1
- Category: agent-ops
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: auto
- Priority: P1
- Depends on: none
- Locks: paired-review-continuation-ordinal-recovery
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, workflow
- Paired review workstream: review-agent-paired-review-continuation-ordinal-recovery-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: Exact-run reviewer provenance reconstruction is security-sensitive; independent review must validate the evidence boundary and adversarial rejection behavior.
- Reviewed main: 461cf501ca467e5492426f8e402d68c018d28da2
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae98bea-2dfc-83e8-a5ff-863e52d79ac0
- Visual review: none
- Goal: Correct host-validation continuation metadata and provide a fail-closed, exact-run recovery path that can authenticate the completed reviewer session without relaunching it or rewriting historical evidence.
- Completion boundary: Implement and validate the future continuation ordinal fix and exact-run plan/apply provenance recovery for run 20261104T054548Z-c093caae7466, claim 20261104T054620Z-3f933cddc532. Produce a read-only SHA-bound plan and an apply path that accepts only the exact authenticated run and never launches a reviewer. Historical apply is deferred until this implementation has landed and its paired independent review is archived complete.
- Current measured state: The exact review run is in coordinator_closeout after host-validation recovery attempt 2 passed. Its only continuation is continuation-01, reviewer_launch_count is 1, and the fresh reviewer process exited 0 with a saved PASS message. The strict verifier rejects the session because continuation metadata omits continuation_number. Original metadata and reviewer evidence are preserved; no accepted receipt or landing exists.
- Evidence: The pinned implementation at main 461cf501ca467e5492426f8e402d68c018d28da2 demonstrates that the recover_host_validation initializer omits continuation_number while _parse_redacted_final_session requires continuation_number == 1. Exact-run evidence is under .git/custodian-review-runs/review-agent-paired-review-source-bearing-executable-mode-v1/20261104T054548Z-c093caae7466/ with continuation-01/metadata.json, codex.jsonl, last-message.txt, host-validation/attempt-02 reports, preserved-reviewer-files, and review-artifacts. This host-private evidence is owned by the local CUSTODIAN host; the executor must verify it at that exact path and fail closed if absent, changed, or inconsistent. Do not copy it into Git or alter it.
- Task-specific authority: custodian/tools/agent/paired_review_runner.py; custodian/tools/agent/workflow_control.py; custodian/tools/agent/review_outcome.py; custodian/tools/agent/review_receipt_delta.py; custodian/tools/agent/paired_review_host_validation.py; custodian/tools/agent/workstream.py; custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md; the exact protected review packet and original run evidence named above.
- Work surface: custodian/tools/agent/paired_review_runner.py; custodian/tools/agent/test_paired_review_runner.py; narrowly scoped recovery journal/plan support only if the runner cannot safely own the operation; relevant validation and lifecycle tests.
- Publication inputs: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/workflow_control.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/land_main.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/legacy_claim_quarantine.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/task_packets/REVIEW_AGENT_PAIRED_REVIEW_SOURCE_BEARING_EXECUTABLE_MODE_V1.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_SOURCE_BEARING_EXECUTABLE_MODE_V1.md`; `custodian/docs/ai_context/task_packets/REVIEW_AGENT_WIRE_OBSERVATION_EXPORT_V1.md`
- Change:
  1. Record continuation_number: 1 in the ordinary first host-validation-recovery continuation metadata before reviewer launch. Preserve special continuation numbering for every other continuation mode and retain the strict session ordinal check.
  2. Add an exact-run-only read-only plan and conditional apply using the runner's established recovery architecture. It must authenticate the run, claim, remote branch, attached checkout, reviewed main, implementation commit, reviewer target, original host_validation_recovery phase, both attempts, successful attempt-02 validation hashes, sole continuation-01 topology, absence of continuation-02, reviewer_launch_count == 1, successful reviewer process, exact ephemeral invocation, one completed unique session, sanitized final-message correspondence, preserved reviewer artifacts, packet, root summary, source writer omission, and unchanged original run manifest.
  3. Derive only continuation_number: 1, and only when every pinned identity and session gate proves that ordinal. Supply an authenticated in-memory metadata view to the existing strict reviewer-session and outcome verification path. Preserve the original metadata bytes and digest; append a separate create-only recovery journal under the shared Git metadata directory containing derivation, source identity, session hashes, evidence identities, and plan digest.
  4. Use existing strict archived-outcome, receipt-delta, summary, source-identity, and reviewer-worktree checks. Never accept PASS from prose alone or synthesize a verdict. Generate a missing canonical receipt only if the existing strict receipt-delta contract explicitly allows that exact authenticated change.
  5. Provide a SHA-256-bound read-only plan and apply that rechecks all evidence immediately before mutation, rejects conflicting or repeated state, and cannot invoke a reviewer. Inspect coordinator_finish_review and workstream.py finish behavior. If the dirty persistent root requires a sync deferral, implement only an exact-run authenticated deferral bound to the plan, journal, accepted outcome, and immutable host evidence, with explicit root-sync-pending reporting.
- Preserve: Original review run, claim, branch, worktree, metadata bytes, raw reviewer session, attempt reports, source identity, reviewer-authored packet/summary artifacts, and all unrelated claims. Preserve the three existing dirty WIRE files in the persistent root. Do not change the original WIRE review or implementation.
- Non-goals: Any reviewer relaunch; any new claim or replacement workstream; broad provenance exceptions; editing original continuation metadata; treating reviewer prose as a verdict; changing validation selectors; quarantine transport optimization; automatic recovery of the original WIRE review.
- Acceptance:
  - Future host-validation recovery writes ordinal 1 before launch; tests prove other continuation modes retain their established ordinals and the strict verifier remains unchanged.
  - The exact-run plan is read-only and authenticates every listed run, claim, branch, worktree, source, attempt, session, and artifact identity. It rejects other run IDs, conflicting ordinals, missing or changed evidence, absent claim authority, active reviewer ownership, multiple or duplicate sessions, altered output, contradictory verdicts, and continuation-02.
  - The derived in-memory metadata view is available only for the exact proven run; the source metadata file remains byte-identical. The append-only journal is create-only, hash-bound, and rejects replay, partial writes, symlinks, conflicting prior state, and changed evidence.
  - Existing canonical session, archived outcome, receipt-delta, source, summary, and reviewer-worktree verifiers pass without weakening their rules. The code does not infer PASS from last-message text.
  - The plan states original evidence digests, ordinal proof, session result, PASS artifact result, bounded changes, root-sync disposition, disk preflight, and whether apply can proceed without a reviewer launch.
  - Apply is impossible before the paired independent review is archived complete; apply revalidates the plan digest and all inputs and never starts a reviewer. Any missing acceptance artifact or unsafe root-sync condition stops before landing or teardown.
  - Exact root-sync deferral applies only to this run and preserves the dirty root byte-for-byte while reporting synchronization pending. No generic review exception is introduced.
- Validation: Focused positive and adversarial real-Git fixtures for the exact missing-ordinal case, ordinary future continuation, malformed/conflicting metadata, altered output, duplicate launches, missing claim, changed validation evidence, changed source/run IDs, false PASS, replay/partial journal, and unauthorized root-sync deferral. Run python3 -m unittest custodian.tools.agent.test_paired_review_runner -v; canonical paired_review_runner_unit validation; canonical changed-file validation with complete coverage; check_packet_categories.py; validate_review_pairing.py; validate_task_packet_authoring.py for this pair; task_packet_index.py validation; check_ai_context.py; documentation-drift validation; python compile checks; and git diff --check. Exercise the live exact-run plan only after the implementation and paired review are accepted. Do not apply historical recovery until the independent review archive is complete.
- Task overrides: none
- Deferred: Historical exact-run apply until this implementation lands and its paired review is independently archived complete; original WIRE recovery remains separate and protected.

## Handoff

- Next workstream: none
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae98bea-2dfc-83e8-a5ff-863e52d79ac0
- Refresh instruction: none
- Next action: After this implementation lands and its paired review archives complete, use the exact-run plan and conditional apply to authenticate and close only the named correction review. Do not relaunch its reviewer.
- Blockers or open questions: The original reviewer PASS is unauthenticated and must remain unaccepted until the new strict recovery plan authenticates the complete original evidence.
