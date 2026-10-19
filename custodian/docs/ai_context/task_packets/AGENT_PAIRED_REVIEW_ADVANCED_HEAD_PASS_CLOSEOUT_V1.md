# AGENT PAIRED REVIEW ADVANCED HEAD PASS CLOSEOUT V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-advanced-head-pass-closeout-v1`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P0`
- Depends on: `none`
- Locks: `paired-review-advanced-head-pass-closeout`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-advanced-head-pass-closeout-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Review acceptance and race-safe landing are safety-critical; this recovery must prove reviewer-authored PASS without changing protected history.`
- Reviewed main: `f76854cf22aece96701bb17da14580df6ce879a2`
- Authoring chat: `not-recorded`
- Authoring handoff: `auto`
- Visual review: `none`
- Goal: Safely coordinator-verify and land one existing reviewer-authored PASS whose authorized review branch has advanced beyond its published claim tip.
- Completion boundary: Add a plan/apply coordinator recovery for only the exact parking review workstream and run. Verify the original evidence, reviewer-authored PASS, source and target identities, remote claim ancestry, local closeout commit ancestry, and bounded paths; add only the missing canonical Review Outcome; land through the existing race-safe workstream authority. The original run, claim identity, local closeout commit, reviewer summary, and existing target receipt remain preserved.
- Current measured state: `origin/main` is `f76854cf22aece96701bb17da14580df6ce879a2`. The exact review run is `20261019T164227Z-e6abe304ef6c`. Its remote review branch is pinned at `2a0352441abfae7ec174c1d614f675949f68922f`; its attached local review worktree contains reviewer-authored commit `94e2a8c76d37242803f9261673f3cb55356d2ee0`, a direct child of that tip. The local commit changes only the review summary, managed packet index, archived implementation packet receipt, and archived review packet. The canonical Review Outcome is missing, so coordinator closeout remains blocked.
- Evidence: `.git/custodian-review-runs/review-agent-paired-review-exact-claim-parking-v1/20261019T164227Z-e6abe304ef6c/{metadata.json,claim-receipt.json,validation.json,coordinator-validation.json,codex.jsonl,last-message.txt}`; protected worktree `/home/braydenchaffee/Projects/.custodian-worktrees/review-agent-paired-review-exact-claim-parking-v1-20261019T164232Z-f6ba03fc69a3`; reviewer commit `94e2a8c76d37242803f9261673f3cb55356d2ee0`; pinned review branch tip `2a0352441abfae7ec174c1d614f675949f68922f`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`.
- Task-specific authority: `paired_review_runner.py` remains the sole paired-review coordinator; `review_outcome.py` remains the canonical parser; `review_receipt_delta.py` remains the target receipt verifier; `workstream.py finish` remains the landing and cleanup authority. Recovery must not grant accepted-review status until all existing verification gates pass.
- Work surface: `custodian/tools/agent/paired_review_runner.py` (exact-run plan/apply and evidence journal); `custodian/tools/agent/test_paired_review_runner.py` (positive/negative recovery tests); `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md` (supported recovery procedure only if needed); root summary `AGENT_PAIRED_REVIEW_ADVANCED_HEAD_PASS_CLOSEOUT_V1_CLAUDE_SUMMARY.md`.
- Publication inputs: `none`
- Change: Add a read-only, SHA-pinned plan and checksum-guarded apply path restricted to the exact target workstream and run. Validate exact original run-file hashes, raw reviewer output and summary agreement on PASS/zero defects/zero material gaps, green validation provenance, target implementation identity and existing receipt delta, exact claim/worktree identity, remote claim tip, local HEAD ancestry including commit `94e2a8c76d37242803f9261673f3cb55356d2ee0`, and a complete changed-path manifest limited to the existing review artifact allowlist. Apply may append one canonical Review Outcome derived from the verified reviewer-authored decision; no other content may change. Preserve every existing commit and use ordinary non-force publication plus the existing race-safe landing authority. Every uncertain or contradictory condition must fail closed before write.
- Preserve: Original run files and hashes; original remote claim branch tip and ancestry; local commit `94e2a8c76d37242803f9261673f3cb55356d2ee0`; attached review worktree and reviewer-authored summary; existing target receipt bytes; reviewer's PASS wording and pinned identities; no reviewer relaunch, replacement claim, reset, rebase, force push, branch deletion, root sync, or live parking transition.
- Non-goals: General advanced-HEAD continuation support; recovery of another review/run; converting informal or contradictory review results to outcomes; changing parser/receipt rules; altering the reviewed implementation or target receipt; releasing claims or applying PARKED state; changing the disputed earlier review; running the historical recovery plan.
- Acceptance: (1) Read-only plan proves exact workstream/run/claim/target/implementation identities and emits a deterministic digest without changing run evidence, original worktree, remote refs, or local commits. (2) Apply requires that exact digest and rechecks all preconditions under an exclusive run lock. (3) Positive fixture preserves the complete ancestry through `94e2a8c7` and adds only the canonical Review Outcome. (4) Negative tests reject changed original evidence hashes, changed remote/local tip, unrelated or extra commits, reversed/missing ancestry, unauthorized paths, dirty/staged state, malformed or contradictory reviewer output, missing/changed target receipt, stale plan, and concurrent main/claim movement. (5) Canonical outcome parser, target receipt delta verifier, exact implementation resolver, host validation provenance checks, coordinator closeout preflight, and race-safe landing all pass before accepted review is reported. (6) No general continuation contract is loosened and no protected artifact is cleaned up by this recovery path.
- Validation: Focused `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; dedicated advanced-head plan/apply mutation tests with temporary repositories/remotes; `python3 custodian/tools/agent/validate_task_packet_authoring.py` on the implementation/review pair; `python3 custodian/tools/agent/task_packet_index.py`; `python3 custodian/tools/validation/run_validation.py --changed --json`; `git diff --check`. For the exact historical apply, require the post-land independent review and a fresh plan digest. The host-private original run is read-only evidence at the exact path above and must match the hashes captured in the plan; synthetic tests must not require or alter it.
- Task overrides: `none`
- Deferred: Applying the exact historical recovery until this tooling's independent review passes; any live PARKED transition until the original parking review has coordinator-verified PASS.

## Handoff

- Next workstream: `review-agent-paired-review-advanced-head-pass-closeout-v1`
- Next packet state: `ready/auto`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: After automatic packet promotion, claim the named implementation only if dispatcher audit reports it eligible; then implement, validate, land, and start its fresh-context paired review.
- Blockers or open questions: Exact host-local run evidence must remain byte-identical through planning and apply.
