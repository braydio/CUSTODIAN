# Owner Review Exception Lane V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `owner-review-exception-lane-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `workflow-governance-simplification-v1`
- Locks: `agent-workflow`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-owner-review-exception-lane-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Protected governance: changes live dependency/review eligibility and therefore needs independent falsification even while ordinary work defaults Review:none`
- Reviewed main: `8ef7e4e0b82a865552c47b4f1dc9e48a8e74480d`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Let the project owner knowingly accept one mechanically verified workstream despite a blocked, defective or nonpassing independent review, and continue safe landing/dependency execution without falsifying reviewer judgment.
- Completion boundary: Add one exact-workstream, exact-commit owner-exception decision path with a read-only plan, authenticated explicit per-case owner approval, audit-visible disposition and fail-closed dispatcher dependency consumption. Existing review outcomes remain byte-identical and are never rewritten to PASS. Preserve ordinary implementation validation and all claim/worktree safety.
- Current measured state: At `main@8ef7e4e0b82a865552c47b4f1dc9e48a8e74480d`, `review_outcome.py` recognizes passed/findings/human_required and only an authentic PASS accepts the implementation. `dispatch.py` checks complete archived dependencies and rejects non-accepted review outcomes. Existing review runs such as Procession are stuck in protected host-validation recovery; `workstream.py resume` cannot bypass their preservation gate. The independent `workflow-governance-simplification-v1` packet is already authored to relax new Standard task defaults; it deliberately makes no runtime changes or retrospective waiver.
- Evidence: `custodian/tools/agent/dispatch.py` (`_review_gate`, `_decision`, `audit`), `custodian/tools/agent/review_outcome.py` (`review_acceptance`), `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/workstream.py`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Task-specific authority: Current root/custodian AGENTS and workstream lifecycle; `task_packet_contract.py`, `dispatch.py`, `review_outcome.py`, authoritative validation reports and owner approval provenance. No new gameplay, art or independent review judge.
- Work surface: Focused new `custodian/tools/agent/owner_review_exception.py` or existing narrower owner-decision authority; `custodian/tools/agent/dispatch.py`; exact new/adjacent tests, `custodian/tools/validation/validation_manifest.json`; minimum lifecycle/authoring docs necessary. Touch `workstream.py` or `task_packet_contract.py` only if a proved acceptance invariant requires it.
- Publication inputs: `custodian/tools/agent/dispatch.py`, `custodian/tools/agent/review_outcome.py`, `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/workstream.py`, `custodian/tools/agent/task_packet_contract.py`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`, `custodian/tools/validation/validation_manifest.json`.
- Change: 
  1. Implement read-only `plan` showing exact target implementation/review workstream, pinned implementation/main SHA, currently blocking review run/outcome, applicable tests and baseline evidence, dependent workstreams, held claims/locks, and specific consequences. No writes on plan.
  2. Implement one structured, durable `owner_exception` decision with `owner_accepted_with_review_exception` or an equivalent clearly non-PASS administrative disposition; exact workstream/SHA, reason, review/report references and hashes, mechanical validation evidence, explicit acknowledged findings or uncertainty, approving identity, and time. Authentic owner authorization must derive from a trusted owner-only approval surface or existing verified authority, not a caller-supplied `--yes`, agent-edited Markdown, author spoofing or a generic flag. If no authentic source exists, fail closed and report one bounded prerequisite.
  3. Require focused behavior checks and canonical changed-file validation to be genuinely green for the implementation under exception. Review-infrastructure failures may be attributed separately with preserved red evidence, never retagged as green. Missing proof, unresolved serious data-loss/security/claim-integrity/asset-provenance issues, unaccepted source/art approval or changed SHA cannot be accepted by an ordinary exception.
  4. Teach the dispatcher to recognize this exact verified owner decision as a SEPARATE reason to satisfy only the named review dependency, even if the review outcome is findings, human_required or the historical review was unable to launch. `review_outcome.review_acceptance` must still report original truth. Expose decision and review status separately in `dispatch.py audit --json`; never emit a synthetic PASS or silently rewrite archived implementation/review packets.
  5. Treat active claimed review branches, worktrees, remote refs, locks and host-private evidence as independently protected. A dependency waiver must not implicitly free execution locks, mark a review complete, erase a claim, or clean worktrees. If that protection prevents the exact successor claim, report the separate owner-controlled claim-retirement gate rather than inventing another bypass.
  6. For implementation not yet on main, ordinary validated `workstream.py finish` remains the merge authority; no direct `land_main.py`, forced merge, reset, or arbitrary CI disable. For an already landed post-land implementation, an owner exception may unblock its specific successor/dependency, not re-land its code. Idempotent no-op on identical approved decision; conflicting decisions fail closed.
- Preserve: Valid reviewer PASS/findings/human_required receipts; all prelaunch host-validation reports, claim/run identity and recovered-worktree evidence; truthful Complete/Review lifecycle; focus/change coverage, dispatch locks and protected core work; existing publication and Asset Pipeline V2 contracts. Do not alter the in-flight `workflow-governance-simplification-v1` claim or files.
- Non-goals: No blanket `--force` review acceptance, self-approval, automatic override based on model confidence, mass migration of historical review statuses, general claim parking/reset, CI suppression, bypass of missing source assets/approval, or changes to gameplay.
- Acceptance: A1: Exact owner-approved fixture unblocks only named review dependency without marking its reviewer passed. A2: Wrong owner, missing/forged signature or approval, stale SHA, copied receipt, mismatched target, insufficient mechanical tests and altered evidence all reject. A3: Findings remain queryable and auditable; wrong unrelated successor stays blocked. A4: Active review claim/lock remains held, with no branch/evidence mutations. A5: A real passing paired review continues to work normally. A6: `plan` is byte-for-byte read-only; `apply` uses digest-bound revalidation under the existing coordination mutex and writes only bounded authorized records. A7: Focused tests, dispatcher/review-pairing regressions, changed-file validation, packet checks and `git diff --check` pass.
- Validation: New focused disposable-Git positive and negative fixtures for owner approval and dependency consumption; `python3 -m unittest custodian.tools.agent.test_dispatch custodian.tools.agent.test_task_packet_contract -v`; existing review acceptance/regression tests; `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`; `python3 custodian/tools/agent/check_ai_context.py --json`; `python3 custodian/tools/agent/task_packet_index.py`; `python3 custodian/tools/agent/validate_review_pairing.py` (verify current CLI); `git diff --check`.
- Task overrides: `none`
- Deferred: Automated retirement of already-claimed failed review processes/branches, broad legacy waiver conversion, review-economy Pass B/C, unverified current Procession case override, and changes to outstanding human visual/canon approvals.

## Execution order

Complete `workflow-governance-simplification-v1` first, then claim this separate protected workstream through the normal dispatcher only when the independent review packet is promoted. Do not touch its existing claimed checkout, policy work surface or authoring SHA. Reconcile source and evidence at claim time; do not assume a concurrent worker is idle. On protected-authority conflict, preserve both workstreams and report precisely.

## Handoff

- Next workstream: `review-owner-review-exception-lane-v1`
- Next packet state: `draft/manual; auto authoring handoff after publication checks`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Next action: Prove the narrow owner-decision exception end-to-end, land normal implementation, then independent review.
- Blockers or open questions: Authentic owner approval source must be verified before implementation; do not fake authority with an agent-entered flag.
- Current blocker / Recovery handoff: [Godot cache-access review forensic handoff](../RECOVERY_HANDOFF_GODOT_CACHE_ACCESS_REVIEW_20261031.md). This preserves unresolved review truth; it does not satisfy the dependency, release the lock, or authorize an owner exception.
