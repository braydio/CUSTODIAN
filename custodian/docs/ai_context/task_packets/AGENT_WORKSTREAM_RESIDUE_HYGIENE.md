# AGENT WORKSTREAM RESIDUE HYGIENE

- Workstream: `agent-workstream-residue-hygiene`
- Kind: `correction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `review-agent-review-pipeline, workstream-finish-landed-closeout-hardening`
- Locks: `agent-workflow`
- Review: `none`
- Goal: Perform one conservative cleanup pass over stale agent workstream branches and task-packet index residue left by pre-hardened lifecycle runs, without disturbing any genuinely active or uniquely recoverable work.
- Current measured state: task-packet README still contains a large `Recently Complete (awaiting archive)` section from older runs, while remote branches include historical `agent/twin-solaria-runtime-v1`, `agent/awakening-connector-04-05`, `agent/operator-fast-chain-continuity`, and `agent/workstream-artifact-finalization` alongside the currently active `agent/agent-review-pipeline`. New finish hardening will prevent future residue but does not retroactively classify this backlog.
- Task-specific authority: `branch_hygiene.py`, `workstream.py`, task-packet archive rules, current `origin/main`, and each candidate's landed/archived evidence.
- Change: Audit existing residue; archive/remove only packets proven complete; retire only branches whose complete content is already reachable from main or whose unique history is first preserved by the existing archive-tag mechanism; repair README/index truth.
- Preserve: active branches/worktrees; unique unlanded work; dirty user checkout; recovery branches; current review-pipeline work; no force deletion.
- Non-goals: No feature implementation; no automatic deletion based on age/name alone; no rewrite of historical packet prose; no broad branch purge outside the candidate agent-workstream residue.
- Acceptance: every audited candidate has a recorded disposition; proven complete packet residue is archived/index-clean; stale branches are retired only with ancestry/archival proof; active/ambiguous work remains untouched with reason.

## Candidate Branches

Audit current remote state at execution time. Initial known candidates:

- `agent/twin-solaria-runtime-v1`
- `agent/awakening-connector-04-05`
- `agent/operator-fast-chain-continuity`
- `agent/workstream-artifact-finalization`

Explicitly exclude any branch with an active claimed packet/worktree, including current review-pipeline work.

Do not hardcode deletion solely from this list; refresh remote state first.

## Packet Residue

Audit every item currently under:

`Recently Complete (awaiting archive)`

For each:

1. locate active packet;
2. inspect packet status/completion notes;
3. verify required closing summary if the packet uses the workstream lifecycle;
4. verify landed implementation is reachable from `origin/main`;
5. verify no active matching worktree/branch is still legitimately in use.

Then classify:

- `ARCHIVE_SAFE`
- `STILL_ACTIVE`
- `INCOMPLETE_CLOSEOUT`
- `AMBIGUOUS`

Only `ARCHIVE_SAFE` moves to `task_packets/archived/` and leaves the active index.

Do not mark incomplete packets complete merely to make the index smaller.

## Branch Retirement

Use existing `branch_hygiene.py` disposition logic.

Rules:

- if branch head is ancestor of main and no active worktree/claim exists, safe retire;
- if branch has unique commits, create the existing archival tag/evidence before retirement if branch-hygiene policy supports it;
- if unique history cannot be classified as obsolete, leave it;
- never force-delete active work;
- never alter the user's dirty persistent main checkout.

## Documentation Drift

Update packet README and FILE_INDEX only to reflect actual dispositions.

Do not churn archived packet content.

## Validation

- branch-hygiene focused tests;
- agent workflow contract;
- AI-context validator if it has landed by execution time;
- `git diff --check`.

Closing summary must include a table of every branch/packet candidate and final disposition.

## Completion

Archive this packet, write
`AGENT_WORKSTREAM_RESIDUE_HYGIENE_CLAUDE_SUMMARY.md`, and land normally.
