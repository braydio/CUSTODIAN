# AGENT PAIRED REVIEW FINDINGS CLOSEOUT V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-findings-closeout-v1`
- Authoring handoff: `auto`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `agent-workflow`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-findings-closeout-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `review acceptance, dependency truth and original-run preservation require independent review`
- Reviewed main: `31232596e9d3201371c69aa1880b886b3f8d9b0b`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Allow a real independent paired review to conclude administratively with passed, findings, or human_required, without passing an unaccepted implementation or stranding its execution claim indefinitely.
- Completion boundary: Implement the canonical pinned administrative review-outcome contract, a strictly gated findings/human closeout, explicit accepted-review dependency semantics and crash-idempotent existing-run recovery preparation. Keep the original R0-01 review branch/worktree untouched until this infrastructure change passes independent review.
- Current measured state: `review_receipt_delta.py:verify_review_receipt_delta` enforces status passed and zero blocking defects/gaps on an exact-byte appended target receipt. `paired_review_runner.py:coordinator_finish_review` requires green reviewer report and this target receipt, and `landed_review_state` expects passing target provenance. `workstream.py:closeout_preflight/_finish_impl` requires green closeout and target receipt. `dispatch.py:_decision/audit` treats every archived complete packet as dependency-satisfying without checking a review verdict. The genuine claimed `review-agent-next-execution-boundary-v1` contains R0-01 with unique review evidence and two untracked Godot UID sidecars; no supported findings closeout currently exists. MC1's remote claim was retired, so current LF1 lock holder is the original review, not MC1.
- Evidence: `custodian/tools/agent/{review_receipt_delta.py,paired_review_runner.py,workstream.py,dispatch.py,task_packet_contract.py}`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/AGENT_ORPHAN_RECOVERY_SUPERVISOR_V1.md`; active `REVIEW_AGENT_NEXT_EXECUTION_BOUNDARY_V1.md` and its pinned archived implementation; durable R0-01 and original run metadata reported by the existing reviewer. Observed worktree/PID state is historical: verify freshly before any recovery.
- Task-specific authority: Existing paired reviewer and exact-byte receipt delta remain sole PASS authority; workstream/land_main retain landing and teardown authority; dispatcher retains canonical claim, dependency and lock eligibility; OR1/OR2 define protected original-run fencing but are not substitutes for this migration.
- Work surface: `custodian/tools/agent/{review_receipt_delta.py,paired_review_runner.py,workstream.py,dispatch.py,task_packet_contract.py}` and their existing focused test modules; minimal documented outcome schema and lifecycle wording in `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md` and review template. No gameplay code, actor assets or unrelated packet mutation.
- Change:
  1. Add exactly one durable administrative review outcome `passed|findings|human_required` on the **review** closeout, bound to review workstream, target workstream, pinned reviewed-main SHA, immutable implementation SHA, fresh reviewer provenance, exact originating run ID/evidence directory and stable cycle-scoped finding IDs. Reject malformed, duplicate, stale, conflicting or ungrounded records. A missing or unknown outcome fails closed.
  2. Preserve unchanged the existing `passed` path: exact target-packet append-only receipt, correct immutable implementation identity, zero blocking defects/material gaps, independently green structured validation, and all pre/post-sync/provenance checks. Nonpassing reviews must NEVER append/modify a target acceptance receipt, rewrite target bytes, or inherit an old PASS.
  3. Provide a narrowly scoped nonpassing coordinator path. Verify exact run/reviewer/target identity, evidence paths/findings/disposition and archive/summary integrity; require a **green integrity/closeout validation report** of those checks, not a green result for the defective behavior under review. Preserve failing-behavior logs as findings evidence. Do not suppress existing failing tests or falsify the validation report.
  4. Correct dependency authority in both `dispatch.py:_decision` and `audit` and any shared queue/closeout validator. An archived paired review is accepted-review-satisfying **only** with a verified `passed` outcome and its canonical target receipt. `complete+findings`, `complete+human_required`, missing/invalid outcome, legacy ambiguity and orphaned closeout never release an ordinary accepted-review dependency. An explicitly identified bounded correction may depend on a concluded findings review only after verifying its cycle/IDs/target correction lineage; do not globally redefine complete as acceptance.
  5. Add journaled recovery for an existing review run: prepare exact pinned state and outcome intent before writes, verify any landed outcome and branch refs after landing, record committed completion and return the identical result on retries. Never relaunch a duplicate claim or receipt, silently delete an original agent branch, rewrite archive history, or recover based on PID absence alone.
  6. Keep the existing review's dirty original worktree and both untracked `.gd.uid` sidecars immutable. Any recovery of that review is a later separately gated operation in an **isolated checkout at the exact published review branch tip** with source path/hash/owner/run evidence and protected snapshots. Do not call ordinary `finish` on a dirty original or weaken clean-worktree/green integrity closeout. If safe landing and lock release cannot be independently verified, leave owner protected and stop.
  7. Maintain real cross-clone and current-main protection. Do not bypass/rename `agent-workflow` to dispatch this maintenance; do not modify the blocked reviewer to create room. Since normal dispatch cannot claim a repair requiring that lock, prepare an explicit isolated, owner-authorized maintenance run outside normal claim selection, and record the exception in its summary. If no such procedure is authorized/safe, stop with exact instructions rather than faking claimability.
- Preserve: Original R0-01 finding and five unique review commits, target implementation bytes, exact PASS receipt verifier, existing claim/branch and UID files, coordination checkout `operator.gd`, current review independence, bounded correction cycles, workstream finishing gates, OR1/OR2 planned fencing semantics and all other active ownership.
- Non-goals: Correcting R0-01 itself, concluding the original review before this repair is independently accepted, retiring its unique branch, making all archived reviews pass, replacing dispatcher, modifying game code, launching an unsupervised review session, or claiming LF1 merely because a lock changes.
- Acceptance:
  - A1. Accepted PASS remains byte-exact and provenance/green-validation strict; target-byte changes, wrong pins and duplicate PASS are rejected.
  - A2. A genuine findings or human_required review can be administratively archived, grounded in stable findings and the exact run, with **zero new target receipt bytes** and a green validation result for closeout-integrity checks only.
  - A3. Downstream accepted-review dependencies remain ineligible for findings/human/absent/forged outcomes in real dispatcher decision AND audit; a correctly accepted PASS unlocks them.
  - A4. Only an explicitly linked bounded correction can consume concluded findings as correction authority; wrong cycle/target/findings and ordinary successors fail closed.
  - A5. Interrupted/repeated same-run closeout converges to one journal/outcome, one branch landing and no extra claim, with no ref or artifact damage.
  - A6. Dirty original worktree, all tracked/untracked bytes/hashes, remote branch, ownership evidence and original R0-01 survive unchanged. No unstated lock exception or forced deletion.
  - A7. Tests falsify negative cases: forged/edited receipt, stale target SHA, missing evidence, failed behavior evidence, dirty original, review still active, ambiguous/foreign owner, race and interrupted landing.
- Validation: Existing focused paired-review runner, review-receipt-delta, workstream, dispatch and task-packet contract unit suites, plus deterministic isolated two-repository Git fixtures for passed/findings/human dependencies, correction lineage, journal retry and dirty UID exact-hash protection. Run one changed-file routed validation and AI-context/pair/index checks after focused tests; `git diff --check`. Describe new fixture scripts generically until implemented.
- Task overrides: `none`
- Deferred: Actual legacy review R0-01 closeout and scoped general-next correction/re-review occur only after this migration independently passes and its original run is verified safe.

## Execution boundary

Published `ready/auto` means the **authoring preflight passed**, not that the P0 maintenance is claimable during the existing `agent-workflow` lock. A fresh dispatcher audit decides eligibility. If blocked, an operator-authorized, isolated maintenance procedure must be reviewed and documented separately; no direct `claim-next`, lock removal or same-branch takeover is authorized by this packet alone. Do not use `workstream.py finish` on the original dirty review worktree.

## Next Handoff

- Next workstream: `review-agent-paired-review-findings-closeout-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: Independent fresh-context review of A1–A7 before recovering the original R0-01 review.
- Blockers or open questions: `Original next-execution-boundary reviewer holds agent-workflow until supported truthful recovery; do not bypass its preserved claim.`
