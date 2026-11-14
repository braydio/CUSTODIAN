# INDEPENDENT REVIEW: Canonical excluded-file host-report authentication

- Packet schema: `custodian.task_packet.v2`
- Workstream: review-agent-paired-review-excluded-coverage-evidence-recovery-v1
- Category: `agent-ops`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: agent-paired-review-excluded-coverage-evidence-recovery-v1
- Locks: `agent-paired-review-excluded-coverage-evidence`
- Review: `none`
- Review target workstream: agent-paired-review-excluded-coverage-evidence-recovery-v1
- Review target packet: custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_EXCLUDED_COVERAGE_EVIDENCE_RECOVERY_V1.md
- Reviewed main: 14298756db4493ab6f52e0a886a911ed0e01c2c0
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae424b0-a48c-83ea-9c8e-68e3c48fa59d
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify the host-validation recovery coverage fix before any original held review is retried.
- Reviewed implementation acceptance: The failed-host authenticator and green host-report validator recognize only genuinely canonical manifest-excluded and hash-bound files as excluded; required source/test coverage and review outcomes are never relaxed.
- Review evidence: Actual pinned implementation diff and tests; `run_validation.py` `coverage_excludes` semantics; disposable historical fixtures including the excluded attestation JSON and ordinary covered Python files; original held review run ID `20261030T111515Z-d6cd006cd42d` (host-private, unmodified).
- Correction threshold: A fabricated excluded-file declaration accepted without proving canonical manifest exclusion, missing hash/source identity, missing or failed covered-file test owner, changed run evidence, ignored timeout, or a mutated original review claim is blocking. Use canonical findings IDs and material gap disposition.
- Focused validation: Independently regenerate coverage expected from the pinned trusted manifest; adversarially exercise included/excluded mismatch, policy changes, duplicate/extra paths, missing source, wrong Git hash, bogus report digest and timed-out test. Verify green `_validate_report()` matches the same exclusion contract. Run focused and canonical tests.
- Review focus: Correct trust boundary between hash inventory, changed-file coverage policy, and independent-review lifecycle. Avoid creating new workstream-specific carveouts.
- Acceptance: Fresh independent verdict with zero blocking defects/material proof gaps and canonical `passed` receipt for this repair. That does not grant PASS to either held administrator review or unlock the executor itself.
- Non-goals: No changes to the implementation under review or to the two older administrator review branches, immutable host run evidence, Procession claims, or unrelated files.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Procedure
Review with a fresh context from the archived implementation packet, committed diff, and canonical validation manifest. Check both predicates and negative cases; do not equate successful unit tests with independent approval. Use the ordinary paired-review runner and finish/teardown lifecycle.

## Handoff
- Next workstream: review-agent-persistent-task-administrator-review-scope-recovery-v1
- Next packet state: already-claimed host_validation_recovery (no second claim)
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae424b0-a48c-83ea-9c8e-68e3c48fa59d
- Refresh reason: none
- Next action: Use the preserved attestation review's exact run ID for read-only recovery plan, then fresh SHA-pinned apply only after this review is genuinely accepted.
- Blockers or open questions: Original administrator implementation review is still unaccepted and executor B/C are unstarted.
