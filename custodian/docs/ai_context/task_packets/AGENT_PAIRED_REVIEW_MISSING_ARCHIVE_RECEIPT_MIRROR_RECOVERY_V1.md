# Paired-review missing archived receipt mirror recovery

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-missing-archive-receipt-mirror-recovery-v1`
- Category: `agent-ops`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `review-agent-paired-review-archived-receipt-capture-recovery-v1`
- Locks: `agent-paired-review-archived-receipt-capture-recovery`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-missing-archive-receipt-mirror-recovery-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: A separately authorized exact-run recovery will make an already-authenticated reviewer PASS durably acceptable. Its source pins, evidence immutability, race safety and canonical closeout need fresh independent verification.
- Reviewed main: `c93d75d8cd57c2b36731cb640fac722faf6ccc2a`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af34a5d-ca7c-83ea-b267-382f1be560df
- Visual review: `none`
- Goal: Extend the existing archived receipt mirror recovery owner to one additional exact protected review run, without repeating its reviewer or introducing a parallel recovery system.
- Completion boundary: Add a separately pinned plan/apply profile for the exact resolver review run below, improve the coordinator's missing-versus-contradictory receipt diagnostic, cover the extension with synthetic adversarial tests, and document its authorization boundary. Do not execute recovery against the protected run in this workstream.
- Current measured state: Existing `recover-archived-receipt-capture` is source-pinned to the different run `review-agent-paired-review-dual-disposition-recovery-v1` / `20261031T005522Z-c70dd87f67a4`. The exact resolver run is `review-agent-review-archive-lifecycle-disambiguation-v1` / `20261110T191406Z-4b8aaffdcec9`, claim run `20261110T191414Z-c67e452fb747`, reviewed main `c93d75d8cd57c2b36731cb640fac722faf6ccc2a`, target `agent-review-archive-lifecycle-disambiguation-v1`, and implementation `781ecf984bec706849a37ad69e9bc7123afe62b1`. Its canonical Review Outcome is PASS; its target receipt strictly validates and agrees on every canonical field; only the redundant `## Independent Review` mirror is missing from the archived review packet. The exact validation report SHA-256 is `831af08ad6904e4409540b517f9794c280a5f0a6c730fac5d2cd09d9036e2eb4`; coordinator validation metadata SHA-256 is `35c3be2f0b439112d5198dfd4310a3463a234a80d5ed5a63416751e211560c99`. The preserved run, claim and worktree remain protected. The existing recovery owner and paired review for the earlier profile are active; this packet depends on that review's accepted completion and takes the same lock to prevent overlapping edits.
- Evidence: Existing implementation packet `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_ARCHIVED_RECEIPT_CAPTURE_RECOVERY_V1.md`; its active paired review; `paired_review_runner.py` exact-profile constants/planner/apply and `_coordinator_closeout`; preserved run metadata, coordinator report and archived packets described above. The `.git/custodian-review-runs/` evidence is host-local; the later plan must verify it from the original owner-controlled host and fail closed if any byte or identity differs.
- Task-specific authority: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/workflow_control.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/workstream.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Work surface: Extend the existing exact-run archived receipt capture recovery in `paired_review_runner.py`; add regression cases in `test_paired_review_runner.py`; document the second exact profile and separate plan/apply authorization in `AGENT_WORKSTREAM_LIFECYCLE.md`.
- Publication inputs: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/workflow_control.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/test_review_outcome.py`; `custodian/tools/agent/test_paired_review_findings_closeout.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_ARCHIVED_RECEIPT_CAPTURE_RECOVERY_V1.md`.
- Change:
  1. Extend the existing pinned archived-receipt recovery command with a second immutable profile for this exact workstream, run, claim run, reviewed-main SHA, target workstream, implementation commit, and host report/metadata digests. Preserve the existing profile byte-for-byte in behavior; reject all other run/profile combinations.
  2. Reuse the existing exact plan, lock, process/ref checks, source-pinned session authentication, run manifest, target receipt verifier, canonical Review Outcome parser, journal, coordinator provenance, and canonical landing/claim-release path. Bind every original artifact and proposed output into the plan digest. The profile may authorize only the missing archived receipt mirror.
  3. Keep reviewer-authored Review Outcome, reviewer target receipt, session output, validation report, metadata and all original evidence byte-identical. Do not synthesize a reviewer verdict. Label the appended receipt mirror `Authored by: coordinator`, derived only from the authenticated PASS and strictly matching target receipt.
  4. Distinguish an absent archived receipt mirror from a present but malformed, partial, duplicate, or contradictory mirror in coordinator closeout errors; acceptance rules remain strict and unchanged.
  5. Apply only after a separate exact-plan authorization, on the original protected run, after this implementation is landed and its fresh paired review is accepted. Implementation and its paired review must run tests only against synthetic repositories and never plan/apply to the preserved resolver run.
- Preserve: Existing recovery profile and tests; canonical target receipt/outcome validators; the resolver implementation; exact original claim, branch, lock, reviewer checkout, run evidence, reviewer outcome and target receipt; current main and all unrelated worktrees.
- Non-goals: Re-running the resolver reviewer; applying recovery during implementation or its paired review; changing generic receipt acceptance; adding a general configurable recovery interface; editing the original run, protected worktree, claim, branch or lock before the separately authorized apply; touching the Ash-Bell Lift review or unrelated packet queue entries.
- Acceptance:
  1. The new exact profile authenticates the full workstream/run/claim/main/target/implementation identity and pinned validation digests, while the existing profile continues to work and unknown or mixed identities fail closed.
  2. The read-only plan verifies fresh canonical PASS outcome, exact run binding, strict target receipt delta and field-for-field equivalence, missing-only archived receipt state, immutable evidence manifests, authenticated claim/worktree, host validation, held lock, process ownership, refs and non-supersession. It returns an immutable plan digest and proposed append without writing reviewer files.
  3. Apply requires the exact fresh plan digest and the separately recorded authorization; it revalidates all pins before mutation, writes only the coordinator-labeled missing mirror plus journal through the existing replay-safe procedure, then requires canonical review closeout and remote reachability before claim release. Repeating the same completed plan is idempotent.
  4. Any altered outcome, target receipt, report, session capture, metadata, worktree, lock/ref, identity, profile, journal, unexpected artifact, competing owner, accepted/superseding review, partial/duplicate receipt, or field mismatch is rejected. Existing profile behavior remains covered.
  5. Coordinator closeout reports missing-mirror and contradictory-mirror states distinctly; valid receipts still pass only through existing strict validators.
  6. Tests cover the second exact positive plan/apply path in synthetic fixtures, byte preservation, interruption/replay, changed main, all wrong-profile identities, all missing/malformed/contradictory evidence cases, ownership/ref races, and unchanged prior-profile behavior. No actual protected run is touched.
  7. Focused suites, canonical changed-file validation with complete coverage, packet authoring/category checks, and `git diff --check` pass.
- Validation: `python3 -m unittest custodian.tools.agent.test_paired_review_runner custodian.tools.agent.test_review_outcome custodian.tools.agent.test_paired_review_findings_closeout -v`; `python3 custodian/tools/validation/run_validation.py --changed --base <implementation-parent> --json`; targeted paired-packet authoring and category checks; `git diff --check`. Recovery plan/apply is expressly deferred until a post-review separate authorization.
- Task overrides: `none`
- Deferred: After accepted independent review, use the original host-local evidence owner to create a read-only exact-run plan; send its digest and proposed file delta to this authoring chat. Apply only after a separate exact-plan authorization. The Ash-Bell Lift review remains gated until the original resolver review is accepted and claim teardown is verified.

## Context Pack

- Repomix: `none`
- Purpose: The existing recovery owner, its tests and lifecycle contract form a bounded work surface.

## Handoff

- Next workstream: `review-agent-paired-review-missing-archive-receipt-mirror-recovery-v1`
- Next packet state: `dependency-gated until implementation lands and the existing archived-receipt recovery review is accepted`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af34a5d-ca7c-83ea-b267-382f1be560df
- Refresh reason: `none`
- Next action: After the existing recovery pair is accepted, claim this implementation, land and archive it, then run the new fresh-context paired review.
- Blockers or open questions: `none`
