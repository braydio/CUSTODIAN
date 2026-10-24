# Paired Review Procession PASS Closeout Recovery

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-procession-pass-closeout-recovery-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `paired-review-pass-closeout-recovery`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture`
- Paired review workstream: `review-agent-paired-review-procession-pass-closeout-recovery-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `0c162bdde9de7baa177cc592f0df9c0e426c787e`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Close a verified, preserved independent Procession fixture-repair PASS through canonical coordinator authority, and prevent the same missing-target-receipt failure from stranding future verified PASS reviews.
- Completion boundary: Add a narrowly bounded coordinator-only recovery for the exact preserved Procession review run, including read-only SHA-pinned planning, separately authorized apply, append-only journaling, canonical receipt verification and ordinary serialized landing. Provide one coordinator-owned PASS receipt renderer that future direct-tail closeout can reuse. Do not modify or apply recovery to the protected run until this implementation and its fresh paired review are accepted.
- Current measured state: The Procession fixture repair landed at `7b82b9630e9a63c52e86f8b4805c577a85496aa5`, reviewed against `edaae65a308ef4a96916afb3b3cf653ff4969ae9`. Its paired review run `20261024T074548Z-1c9611762049` has complete green host validation (4/4 selected, 174 paired-review runner unit tests in the validation output) and a reviewer-authored PASS in `last-message.txt`. Coordinator closeout stopped because the reviewer archived the review packet but did not append the target receipt. Same-run continuation refuses because that preserved checkout has no active review packet. Current `origin/main` is `0c162bdde9de7baa177cc592f0df9c0e426c787e`.
- Evidence: `.git/custodian-review-runs/review-agent-paired-review-procession-test-fixture-repair-v1/20261024T074548Z-1c9611762049/{metadata.json,validation.json,coordinator-validation.json,last-message.txt,RECOVERY.md}`; preserved reviewer checkout `/home/braydenchaffee/Projects/.custodian-worktrees/review-agent-paired-review-procession-test-fixture-repair-v1-20261024T074609Z-f3f9a621ba72`; implementation packet `custodian/docs/ai_context/task_packets/archived/PROCESSION_TEST_FIXTURE_REPAIR_V1.md`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/review_receipt_delta.py`.
- Task-specific authority: `paired_review_runner.py` owns paired-review coordination and serialized closeout; `review_receipt_delta.py` owns canonical receipt delta verification; `review_outcome.py` owns canonical outcome parsing; `AGENT_WORKSTREAM_LIFECYCLE.md` owns review claim and landing lifecycle. Existing `recover-advanced-head-pass` code is a safety-pattern reference only and is not authorization for this run.
- Work surface: `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/review_receipt_delta.py` only if a reusable canonical renderer belongs there, `custodian/tools/agent/test_paired_review_runner.py`, narrowly relevant lifecycle documentation, this implementation/review packet pair, and required root closing summary. The protected Procession review checkout and run evidence are read-only until post-review recovery.
- Publication inputs: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/land_main.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/VALIDATION_RECIPES.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`.
- Change:
  1. Authenticate the protected exact run from host-local immutable evidence: original workstream/run/claim, branch and pinned reviewed main, implementation identity, full green host report pair and coverage, reviewer session provenance, canonical reviewer-authored PASS disposition, archived review packet and unchanged target baseline. Refuse contradictory outcomes, existing receipt, evidence drift, changed refs, foreign/occupied checkout, competing owner, consumed recovery or unrecognized state.
  2. Add read-only `--plan` and separately authorized SHA-pinned `--apply` for this exact run. Bind all identities, refs, evidence hashes, expected target bytes/delta, permitted paths/actions, reviewer outcome and journal state. Under the exact review supervisor lock, revalidate the complete plan before any write.
  3. Create a write-ahead append-only recovery journal. Render only the missing canonical PASS receipt from the verified reviewer-authored outcome and pinned implementation identity. Preserve original review packet, summary and run artifacts byte-identically. Verify the complete target delta with `verify_review_receipt_delta()` and the complete outcome identity before closeout.
  4. Permit coordinator-controlled closeout of the already archived review packet only for this authenticated post-exit state; stage only the target receipt, archived review packet lifecycle change, managed packet index if required, and durable summary. Land through normal serialized authority with no force push or history rewriting. Journal every stage and allow retry only when recorded hashes establish an unambiguous state.
  5. Expose a coordinator-owned canonical receipt renderer with strict identity/baseline checks so the existing direct-tail receipt-closeout implementation can reuse it. The renderer must never create, infer or reinterpret reviewer judgment.
- Preserve: Original claim, branch, reviewer worktree and all run evidence; exact pinned reviewed-main and implementation identities; original reviewer-authored PASS bytes and provenance; normal independent reviewer authority; receipt format and duplicate-receipt rejection; all existing findings, nonpass, host-validation and recovery flows.
- Non-goals: Launch another reviewer for the protected run; amend/rebase/force-push; synthesize a PASS; rewrite reports or review outcome; generalize arbitrary post-exit recovery; alter unrelated review claims/worktrees; implement the broader direct-tail packet; touch mapper/gameplay code.
- Acceptance:
  - Exact protected run is authenticated solely from preserved evidence; any missing, malformed, changed or contradictory required fact fails closed.
  - `--plan` is read-only and emits a deterministic digest binding original evidence hashes, refs, identities, expected file deltas and allowed actions.
  - `--apply` requires explicit authorization and exact digest, revalidates under the review lock, journals before mutation, and is idempotent only for the exact recorded continuation.
  - Receipt bytes are rendered canonically from a parsed reviewer-authored PASS and pinned identity; the target delta passes `verify_review_receipt_delta()`; no reviewer artifact/report is rewritten.
  - Positive real-Git fixture recreates the archived-review/missing-target-receipt state and proves plan, apply, accepted canonical receipt and safe replay.
  - Hostile fixtures reject forged or absent PASS, bad/partial validation, stale target, changed evidence, extra paths, changed refs, duplicate receipt, occupied/foreign checkout, active owner, altered journal, interrupted ambiguous state and replay with changed plan.
  - Existing review/host-validation/nonpass/invalid-disposition recovery behavior remains unchanged; full paired-review runner suite passes.
  - The fresh paired review is accepted through normal lifecycle before applying recovery to the protected Procession run.
- Validation: Run focused new real-Git cases first; `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; canonical `python3 custodian/tools/validation/run_validation.py --test paired_review_runner_unit --json`; changed-file validation with complete coverage; `check_ai_context.py --json`; `task_packet_index.py`; `validate_review_pairing.py`; Python compile checks for changed Python files; and `git diff --check`. Inspect protected run evidence read-only before and after; do not run the recovery apply until the paired review is accepted.
- Task overrides: `TASK OVERRIDE: coordinator may commit only the authenticated canonical receipt, archived review packet lifecycle metadata, generated packet index changes and bounded closing summary for the protected exact run after this implementation and its paired review are accepted. No other review evidence or worktree may be committed.`
- Deferred: Applying the accepted recovery plan to the protected Procession run; direct-tail packet execution and reuse of the renderer; primary pre-validation checkout recovery and host-import review.

## Next Handoff
- Next workstream: `review-agent-paired-review-procession-pass-closeout-recovery-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: Claim the implementation packet after automatic publication promotion and dispatcher eligibility; implement, validate, land and complete its fresh paired review before planning/applying the protected exact-run recovery.
- Blockers or open questions: `The protected recovery run must remain byte-identical until the independent paired review is accepted; no operator attestation substitutes for missing reviewer or host-validation evidence.`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `medium`
- What went wrong: `Coordinator rejected a genuine locally preserved PASS because target receipt omission was not repaired before the review packet was archived; existing continuation requires the active review packet.`
- Root cause / contributing factors: `Reviewer prompt allows receipt append, but coordinator verifies receipt delta only after reviewer exit and post-exit continuation does not cover this archived-packet PASS state.`
- Prevention / pipeline improvement: `Use a coordinator-owned canonical receipt renderer after authentic PASS verification and before lifecycle closeout, with exact-run recovery fencing.`
- Tooling / docs drift discovered: `Current same-run continuation cannot recover the exact preserved PASS state; the unrelated exact-run advanced-head recovery is not reusable authorization.`
- Follow-up: `fixed-in-scope`
- What worked: `Host validation and reviewer outcome remain intact and independently verifiable.`
