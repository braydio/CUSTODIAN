# Paired Review Missing Archived Disposition Continuation V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-missing-archived-disposition-continuation-v1`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `paired-review-missing-archived-disposition-continuation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-missing-archived-disposition-continuation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `protected same-claim recovery changes the authority boundary for launching a fresh independent reviewer and accepting its durable verdict`
- Reviewed main: `f85ed085614260ffb3398d2594a61710867b5db2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad40d97-158c-83ea-ad70-d593bc628e6f?utm_source=chatgpt.com`
- Visual review: `none`
- Goal: Complete the currently preserved paired review after its first fresh continuation exited successfully but omitted the canonical archived disposition.
- Completion boundary: Add one fail-closed `continuation-02` path for the exact protected run `20261020T114129Z-536181b31d70`, then use it only after this implementation lands and its paired independent review passes. The same existing review claim, branch, and worktree must be used; no new dispatch claim is created.
- Current measured state: The original run `review-agent-paired-review-checkpoint-resume-merge-provenance-v1-review-corrections-1/20261020T114129Z-536181b31d70` is `post_exit_recovery`. Its `continuation-01/metadata.json` is `missing_archived_disposition` with `exit_code: 0`. The original worktree is `/home/braydenchaffee/Projects/.custodian-worktrees/review-agent-paired-review-checkpoint-resume-merge-provenance-v1-review-corrections-1-20261020T114134Z-a172e63d7d32`, on branch `agent/review-agent-paired-review-checkpoint-resume-merge-provenance-v1-review-corrections-1`, pinned to `20f982efb5dacd357bc0b24065762ef3d3a9dba2`. `continuation-01` contains immutable reviewer and coordinator evidence; the worktree has a modified active review packet and an untracked review summary, but no canonical archived review disposition. Earlier reviewer PASS messages are not canonical evidence and must not be transcribed or treated as a verdict.
- Evidence: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`; archived `AGENT_PAIRED_REVIEW_SAME_RUN_CONTINUATION_V1.md` and its paired review; exact local run metadata and continuation-01 evidence at `.git/custodian-review-runs/review-agent-paired-review-checkpoint-resume-merge-provenance-v1-review-corrections-1/20261020T114129Z-536181b31d70/`.
- Task-specific authority: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_SAME_RUN_CONTINUATION_V1.md`; `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_PAIRED_REVIEW_SAME_RUN_CONTINUATION_V1.md`.
- Work surface: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_paired_review_runner.py`; the bounded same-run recovery lifecycle note in `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Publication inputs: `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/test_paired_review_runner.py`, `custodian/tools/agent/review_outcome.py`, `custodian/tools/agent/review_receipt_delta.py`, `custodian/tools/agent/workstream.py`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`, `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_SAME_RUN_CONTINUATION_V1.md`, `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_PAIRED_REVIEW_SAME_RUN_CONTINUATION_V1.md`.
- Change:
  1. Add an explicitly authorized, exact-run-only mode that can create `continuation-02` only when the original run is in `post_exit_recovery`, `continuation-01` is present and is exactly `missing_archived_disposition` with reviewer `exit_code: 0`, and all original workstream, run, branch, worktree, pinned commit, claim receipt, packet, and validation identities match the preserved evidence. Require an explicit CLI authorization in addition to `--authorize-fresh-reviewer-context`.
  2. Permit exactly one child named `continuation-02`. Reject an absent or malformed prior continuation, any other phase (including a genuine archived PASS, `invalid_reviewer_disposition`, `reviewer_nonpassing`, interruption, or coordinator closeout), any pre-existing `continuation-02`, and every second attempt. Do not add a generic maximum-continuation count or relax ordinary `continuation-01` behavior.
  3. Before launching, verify the original run evidence against the original immutable manifest and record SHA-256 manifests for the complete original run and the complete `continuation-01`. Preserve both byte-for-byte during the new reviewer session and verify both manifests afterward. Hash and preserve all continuation-01 reviewer artifacts and coordinator records; do not rewrite either continuation metadata file.
  4. Launch only a new ephemeral independent reviewer on the exact same claim and worktree. Do not call the dispatcher, acquire a new claim, alter the pinned target implementation, copy prior PASS prose into new evidence, or fabricate reviewer files. The prompt must name exact paths for the active review packet, canonical archived review packet, pinned implementation target, its one review receipt, and the exact root review summary.
  5. Accept a verdict only when the fresh session produces a canonical archived review packet with one valid `custodian.review_outcome.v1` bound to the exact run, target, implementation commit, review cycle, and pinned main; the canonical archived implementation target gains exactly one valid receipt derived from that outcome; and the exact summary and packet archive artifacts pass the existing coordinator checks. A reviewer exit code of zero or a PASS in its last message is insufficient.
  6. On authentic PASS, use only the existing coordinator closeout and race-safe landing flow. On findings, human-required, malformed or missing artifacts, interruption, or coordinator failure, preserve the same claim, both earlier evidence sets, and all new continuation-02 evidence; never start another reviewer automatically.
- Preserve: The original run metadata, logs, claim receipt, validation report, coordinator report and hashes; all `continuation-01` files and hashes; the exact original claimed branch/worktree and its existing reviewer-authored changes; the pinned implementation commit `20f982efb5dacd357bc0b24065762ef3d3a9dba2`; every other workstream, claim and visual-review artifact.
- Non-goals: Changing `continuation-01`; replaying any other run or phase; changing the reviewed implementation; creating/releasing claims except existing coordinator closeout after verified PASS; accepting past reviewer messages as evidence; changing the separate Grunt review, art decision, or visual-review manifest; generic continuation replay or automated retries.
- Acceptance:
  1. A positive synthetic Git/worktree fixture and exact host-local preflight prove only the named run/phase can create `continuation-02`, preserving the exact branch/worktree/head and existing claim receipt without dispatcher calls.
  2. SHA-256 manifests cover every original-run and continuation-01 file before launch and remain byte-identical afterward; negative fault injection for changes, missing files, symlinks, mismatched identities, a forged claim, changed pinned report, or absent evidence refuses before launch or records a preserved failure state.
  3. `continuation-02` is exclusive and non-replayable. Wrong ID/workstream, prior phase, reviewer interruption/nonzero exit, an existing child, duplicate invocation, or any phase other than exact `missing_archived_disposition` fails closed and leaves existing evidence unchanged.
  4. Mocked fresh-reviewer success cannot close out without the exact canonical archived review packet, valid run-bound Review Outcome, exact single target receipt passing `verify_review_receipt_delta()`, and exact root review summary. Prior last-message PASS text alone, a coordinator report alone, missing/duplicate/wrong-path artifacts, inconsistent IDs, or a non-PASS outcome never lands or releases the claim.
  5. Existing ordinary continuation, host-validation recovery, invalid-disposition recovery, coordinator closeout, and same-run continuation tests remain green.
  6. Only after the new implementation is landed and independently accepted may the exact host run be continued. A real reviewer verdict and the coordinator's complete post-land identity/receipt verification are required before reporting the review as landed; otherwise retain the claim and report the precise phase.
- Validation: `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; `python3 -m py_compile custodian/tools/agent/paired_review_runner.py custodian/tools/agent/test_paired_review_runner.py`; `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`; `git diff --check`; temporary-repository negative tests for each identity, phase, manifest, and artifact failure; then a read-only preflight of the exact protected run. Execute the new continuation only after this implementation's own independent paired review passes.
- Task overrides:
  - `TASK OVERRIDE: Do not change, delete, reset, or recreate the protected reviewer worktree, branch, original run directory, continuation-01, claim, or visual-review evidence. The only permitted host-run mutation is creating the single authorized continuation-02 evidence directory after all exact guards pass.`
  - `TASK OVERRIDE: Do not launch a new dispatcher claim. The same-run reviewer continuation remains on the exact existing claim and worktree; claim cleanup is allowed only through coordinator closeout after authentic PASS and receipt verification.`
- Deferred: Running continuation-02 until this implementation's independent paired review accepts; any other blocked/failed review recovery; human art direction and raster visual approval.

## Next Handoff
- Next workstream: `review-agent-paired-review-missing-archived-disposition-continuation-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad40d97-158c-83ea-ad70-d593bc628e6f?utm_source=chatgpt.com`
- Refresh reason: `none`
- Next action: `Obtain a fresh-context independent review of the landed exact-run continuation guard; only after its PASS, authorize the single continuation-02 for 20261020T114129Z-536181b31d70.`
- Blockers or open questions: `The original host-local run and continuation-01 must still match the pinned metadata, claim and evidence hashes at execution time.`
