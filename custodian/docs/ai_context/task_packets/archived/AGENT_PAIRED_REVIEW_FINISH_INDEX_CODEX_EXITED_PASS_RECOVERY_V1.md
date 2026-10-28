# Exact-Run Finish-Index Reviewer PASS Closeout Recovery

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-finish-index-codex-exited-pass-recovery-v1`
- Status: `complete`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `workstream-finish-index-conflict-recovery-v1`
- Locks: `paired-review-finish-index-closeout`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-finish-index-codex-exited-pass-recovery-v1`
- Review cycle: `0`
- Max automatic review cycles: `1`
- Review rationale: `Protected agent review-verdict acceptance and lifecycle change; requires focused independent falsification`
- Reviewed main: `3b1d45b9ad025a459bd6e297dacfb50b96e5b947`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Safely complete the exact stranded finish-index independent PASS as a truthful canonical review closeout, without rerunning its reviewer, inventing a verdict, or opening a generic codex_exited bypass.
- Completion boundary: Implement a single read-only plan plus explicit SHA-256-bound apply for original review `review-workstream-finish-index-conflict-recovery-v1`, paired-review run `20261027T113425Z-50d9c7adf7a0`. Its dispatcher claim run `20261027T113443Z-6f08c7ced9a2` is a separate identity. The original run must remain untouched until THIS correction implementation lands, passes its own independent review, and owner explicitly authorizes original-run apply. Also correct the normal missing-archived-review `FileNotFoundError` to a controlled recoverable `RunnerError`.
- Current measured state: At implementation start, `origin/main` was `ad974b35a7e11b0e89c5648a80947182d82db85d`. The original review remains at branch tip `c233fefa94f887bcc87989e2740c493ab84c2920` and dispatcher claim `20261027T113443Z-6f08c7ced9a2`; its separate paired-review run is `20261027T113425Z-50d9c7adf7a0`. The implementation's read-only exact-run plan authenticated the original fresh session (five messages, one completed turn, final message agreement), reviewer artifacts, 9/9 pinned host validation, target identity and no local reviewer owner. The plan returned `80b01ce7aa37de71d04023110d7b9fe0dcac05023b038a2ce4c62c7c8b5ce157` with intended output digests and left `HEAD`, `origin/main`, and `FETCH_HEAD` unchanged. No original-run apply was performed.
- Evidence: Private original artifacts `.git/custodian-review-runs/review-workstream-finish-index-conflict-recovery-v1/20261027T113425Z-50d9c7adf7a0/{metadata.json,claim-receipt.json,codex.jsonl,last-message.txt,validation.json,coordinator-validation.json}`; original claim trace `agent-diagnostics/review-workstream-finish-index-conflict-recovery-v1/20261027T113443Z-6f08c7ced9a2`; immutable report digests `e6d94ebbca87e36b832c1cc93a41754eccfe2eb94950f5c1918f9bc5de67a244` and `dd20a24b49c68d8ac136b784cc6b76d6e0ad77ec08ece53b3358ee14d97d0ec0`; read-only plan digest above; focused disposable-Git archive/receipt/index fixture; final validation JSON report and changed-file coverage are retained in the workstream run.
- Task-specific authority: `custodian/tools/agent/paired_review_runner.py` (`coordinator_finish_review`, `_verified_reviewer_pass`, `recover-closeout`, exact PASS recovery precedents); `review_outcome.py`; `review_receipt_delta.py`; `workstream.py`; `AGENT_WORKSTREAM_LIFECYCLE.md`; exact pinned run and original reviewer checkout.
- Work surface: Prefer focused `custodian/tools/agent/paired_review_finish_index_pass_recovery.py` plus a minimal entrypoint in `custodian/tools/agent/paired_review_runner.py` rather than further enlarging its authority; `custodian/tools/agent/test_paired_review_runner.py` and/or focused new test; minimal `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; required implementation summary.
- Publication inputs: `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/test_paired_review_runner.py`, `custodian/tools/agent/review_outcome.py`, `custodian/tools/agent/review_receipt_delta.py`, `custodian/tools/agent/workstream.py`, `custodian/tools/agent/dispatch.py`, `custodian/tools/validation/run_validation.py`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`, `custodian/docs/ai_context/task_packets/REVIEW_WORKSTREAM_FINISH_INDEX_CONFLICT_RECOVERY_V1.md`, `custodian/docs/ai_context/task_packets/archived/WORKSTREAM_FINISH_INDEX_CONFLICT_RECOVERY_V1.md`, `WORKSTREAM_FINISH_INDEX_CONFLICT_RECOVERY_V1_CLAUDE_SUMMARY.md`.
- Change: (1) Implement exact-run `--plan` with no writes to refs, `FETCH_HEAD`, worktrees, index or evidence. Authenticate claim receipt, review/dispatch run IDs, pinned reviewed main and implementation SHA, local/remote branch tip, clean coordinator, original checkout inventory, no active process/supervisor, original host report and coordinator digests/complete coverage and all original run-file SHA-256. Require current main descended from pinned main; do not fail merely because unrelated design commits advanced main. Compute and display a digest-binding all intended mutations. (2) Authenticate one real reviewer turn with exactly one `turn.completed`; accept multiple progress `agent_message` records ONLY for this exact run if its final agent message matches the captured final message, session event order is valid, and no earlier contradictory or ambiguous verdict appears. Require the exact review identity and explicit Passed, zero blockers/gaps in reviewer-authored final and findings-first summary; reject any evidence of findings/human_required or uncertain identity. Never globally weaken `_verified_reviewer_pass`. (3) Reconstruct and verify pinned target baseline and host source span; reject all out-of-scope dirty files, changed SHA, absent/mismatched claim, tampered bytes, symlinks, extra continuation, active owner, stale remote or incomplete host validation. The PASS receipt in the ACTIVE review packet is not already a canonical target receipt. (4) For owner-approved apply, acquire the exact review supervisor mutex and compare a fresh plan SHA; preserve original dirty/untracked reviewer packet/summary byte-for-byte using create-only SHA-bound copies and append-only journal BEFORE any modifications. Build the canonical `Review Outcome: passed` and independent receipt using only proven reviewer-authored verdict, pinned target identity and official renderers. Archive the exact review packet, append precisely one verified target `## Independent Review` receipt, add truthful summary Next Handoff without rewriting findings, validate completion, and land using the original claim's supported serialized `workstream.py finish` contract; an isolated checkout cannot implicitly inherit claim authority. Replays must be idempotent or fail closed without duplicates. Do not modify original run metadata, raw session, final message, report pair, or governance worktree. (5) In the ordinary `coordinator_finish_review` path, test archive existence BEFORE reading its bytes and before appending a receipt; return `RunnerError` so normal runner records recoverable phase. No generic codex_exited continuation is added.
- Preserve: Reviewer judgment and all original run/claim evidence; byte-exact prewrite original reviewer artifacts; normal PASS/findings/human_required contract; original governance and owner exception workstreams; exact project-authorized validation, provenance, claim and worktree safeguards.
- Non-goals: No new reviewer invocation for the original run, no change to original phase by hand, no direct GitHub landing, no reset/stash/force-push, no new claim for the old reviewer, no review acceptance based on green tests alone, no broad policy simplification or unrelated Procession recovery. Original-run apply is NOT permitted as part of implementing this packet.
- Acceptance: The original-shape read-only plan succeeds and verifies all exact evidence without updating refs or `FETCH_HEAD`; a disposable Git packet-tree fixture produces the canonical archived PASS, exactly one target receipt, exact summary handoff, and current managed index, then rejects a repeated closeout without duplicate output. Session tests reject contradictory earlier verdicts, multiple completed turns, wrong run identity, and final-message mismatch. The missing-archive path returns controlled `RunnerError` before target modification whether a target receipt is absent or already present. The original live run remains plan-only and its complete evidence manifest is unchanged.
- Validation: New focused real-Git fixtures first; `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; `python3 custodian/tools/validation/run_validation.py --test paired_review_runner_unit --json`; `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`; `python3 custodian/tools/agent/validate_review_pairing.py`; `python3 custodian/tools/agent/task_packet_index.py` index check; `python3 custodian/tools/agent/check_ai_context.py`; `git diff --check`. Verify local supported CLI flags rather than assume optional ones.
- Task overrides: `TASK OVERRIDE: The original historical review may receive an exact SHA-pinned owner-approved coordinator-only PASS closeout after this code is independently accepted; no other review or claim is authorized.`
- Deferred: Original governance `workstream.py preflight/resume/finish`; `owner-review-exception-lane-v1`; unrelated historical review cleanup.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `AGENT_PAIRED_REVIEW_FINISH_INDEX_CODEX_EXITED_PASS_RECOVERY_V1_CLAUDE_SUMMARY.md`; original exact-run plan digest `80b01ce7aa37de71d04023110d7b9fe0dcac05023b038a2ce4c62c7c8b5ce157`; changed-file validation report; disposable Git closeout and replay-negative test; 203 passing paired-review runner tests. Original reviewer evidence remains unchanged and the owner-only apply is deferred.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: The initial exact-run plan implementation had to distinguish the coordinator's current main from the review's older pinned main and correctly treat progress messages separately from reviewer disposition. No original evidence was changed.
- Root cause / contributing factors: The original runner's ordinary verifier accepts exactly one agent message, while the authenticated original session contains four progress messages followed by its final PASS.
- Prevention / pipeline improvement: Keep the stricter ordinary verifier unchanged; route only this exact historical run through a read-only, digest-bound coordinator plan and owner-authorized apply. Check for the archived packet before any receipt recovery.
- Tooling / docs drift discovered: The packet's direct unittest module command requires `PYTHONPATH=custodian/tools/agent` in this checkout; the canonical validation harness supplies the correct import environment. The workstream documents the supported recovery CLI.
- Follow-up: `review-agent-paired-review-finish-index-codex-exited-pass-recovery-v1`
- What worked: Full run manifest pinning, actual `origin` comparison without fetch, host-validation provenance reuse, and a disposable Git artifact fixture gave concrete evidence without touching the protected original run.

## Handoff

- Next workstream: `review-agent-paired-review-finish-index-codex-exited-pass-recovery-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Next action: Run the fresh-context paired review for this landed correction. After its accepted PASS, rerun the exact original-run plan and obtain the project owner's separate authorization before applying it.
- Blockers or open questions: The original review remains unclosed until its separate owner-authorized apply; governance simplification and the owner-exception lane remain deferred.
