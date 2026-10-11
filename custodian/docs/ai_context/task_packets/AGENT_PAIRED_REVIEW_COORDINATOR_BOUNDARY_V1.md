# AGENT PAIRED REVIEW COORDINATOR BOUNDARY V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-coordinator-boundary-v1`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `none`
- Locks: `agent-workflow`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-coordinator-boundary-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Security-sensitive reviewer/coordinator privilege separation warrants independent review`
- Reviewed main: `4b5ba4c4f88f25cbde281ca6f148da58cd5648b2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Visual review: `none`
- Summary backlink: Repeat exact Authoring chat URL in durable summaries and Next Handoff.
- Goal: Safely recover independent reviews when their sandbox cannot write common Git metadata, with coordinator-only lifecycle mutations and strict review scope.
- Completion boundary: Only after current-main repro validates the need, isolate immutable reviewed refs and authorized Git writes in paired_review_runner.py coordinator while the reviewer remains read-only to implementation; prove recoverable failure handling.
- Current measured state: NPA-7 review closeout recorded permission-denied shared .git/FETCH_HEAD and trace state; prior H4 review recorded LFS-temp restrictions. Current paired_review_runner.py already streams durable evidence and preserves blocked claims, but the exact residual failure has not been reproduced after recent runner changes.
- Evidence: custodian/tools/agent/paired_review_runner.py; workstream.py; NPA_7_REVIEW_CLOSEOUT_CORRECTION_CLAUDE_SUMMARY.md; REVIEW_HUB_CROWN_TRANSFER_TWIN_SOLARIA_CLAUDE_SUMMARY.md.
- Task-specific authority: paired_review_runner.py for reviewer isolation; workstream.py and land_main.py for Git lifecycle; canonical review bounded TASK OVERRIDE and fresh provenance.
- Work surface: Conditional change to paired_review_runner.py coordinator boundary and narrow temporary-Git/sandbox fixtures. No new scheduler or game code.
- Change: First reproduce read-only shared-Git write restriction against the current runner and determine whether its write-authorized coordinator already handles it. If still present, prefetch immutable target refs and LFS state in coordinator, permit reviewer evidence only in authorized review area, and have coordinator verify reviewed SHA, provenance, allowlisted artifact paths and receipts before committing/finishing. Preserve exact original branch, worktree, logs and claim if blocked. If already solved, report evidence and request packet supersession instead of duplicate orchestration.
- Preserve: Same-agent fresh-context or different-agent reviewer independence, no implementation edits, bounded review override, no force push, no duplicate claim or root changes.
- Non-goals: No broad Git permissions granted to reviewer, no replacement land_main, auth-token leakage or automatic review acceptance.
- Acceptance: 1) Live repro justifies boundary; 2) read-only FETCH_HEAD case fails before and succeeds after; 3) reviewer cannot mutate implementation; 4) coordinator enforces exact target SHA/allowlist/provenance; 5) failures preserve logs and claim without duplicate replay.
- Validation: Focused read-only common-Git integration fixtures and existing paired_review_runner, dispatch and workstream contract tests; check_ai_context.py --json, validate_review_pairing.py, task_packet_index.py, changed-file runner and git diff --check.
- Deferred: Distributed reviewer leases and new external review service.

- Task overrides: `none`

## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Refresh instruction: `Re-audit paired_review_runner.py against newest main and a real read-only common-Git fixture; promote pair together to ready/auto only if the defect is reproducible and the coordinator correction is still needed.`

## Handoff

- Next workstream: `review-agent-paired-review-coordinator-boundary-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Refresh reason: `The original shared-Git failure may already be addressed by newer runner fixes.`
- Next action: `Present current-main sandbox reproduction in the authoring chat before promotion and claiming; review remains gated by implementation.`
- Blockers or open questions: `conditional live-runner audit not yet established`
