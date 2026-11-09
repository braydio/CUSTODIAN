# Turn-Scoped Dispatcher V2 (candidate)

**Status:** opt-in implementation candidate, not a live replacement for dispatch.py or current AGENTS.md policy.

**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af12561-89a4-83ea-bc7f-c896ec89bed0

## Contract

Two acquisition modes use one task-packet ID and one remote agent branch.

- **Normal:** Requires a ready/auto task packet. Creates the remote agent branch from advertised origin/main if absent. Builds a disposable checkout and performs Git LFS hydration.
- **Historical:** Accepts a previously worked, non-draft packet and requires its existing remote agent branch. If an old checkout is attached, inspect it before proceeding. Unique dirty/ignored content blocks deletion; do not forcibly remove it. A clean old checkout still requires its original-owner retirement route. After that, rehydrate from the remote branch and committed handoff.

No persistent session locks and no dispatcher dependency-chain eligibility blockers. A task's real implementation prerequisites become scoped tasks listed in the handoff, not an excuse for indefinite parked work. Git atomic remote-branch creation and non-force push are still required to avoid duplicate history or overwriting concurrent work. A human-owned design refresh (draft packet) remains a gate.

**Every turn ends with a checkpoint** which stages tracked modifications and enumerated nonignored untracked source, verifies a minimum handoff, commits, pushes, verifies the advertised remote SHA and removes the turn checkout using non-forced git worktree remove. If unsafe secrets, ignored data, broken LFS, dirty post-commit state, or remote disagreement is detected, it fails closed and preserves the checkout. There is no blanket rm -rf.

The mandatory handoff is a Markdown file containing:

- Original goal:
- Implemented:
- Remaining:
- Validation:
- Resume:

The durable handoff path is custodian/docs/ai_context/turn_handoffs/<workstream>.md. Include exact branch SHA, task packet, acceptance criteria, source/master locations, evidence, remaining steps, and design decisions in the content. A newer turn rehydrates from the branch and reads this file.

## CLI examples

From the repository root:

    python3 custodian/tools/agent/turn_dispatcher_v2.py inspect my-workstream --mode normal
    python3 custodian/tools/agent/turn_dispatcher_v2.py begin my-workstream --mode normal
    python3 custodian/tools/agent/turn_dispatcher_v2.py begin my-workstream --mode historical

After performing work and writing a local handoff file:

    python3 custodian/tools/agent/turn_dispatcher_v2.py checkpoint my-workstream --checkout ~/Projects/.custodian-turns/turn-my-workstream --handoff /tmp/my-workstream-handoff.md --message "task progress and handoff"

The default turn pool is ~/Projects/.custodian-turns, distinct from the historical .custodian-worktrees directory.

## Integration gates still outstanding

1. Independently validate the exact published implementation in isolated Git fixtures, including real LFS hydration, concurrent first claim, failure midway through checkout and push, hostile symlinks, private source and ignored data preservation.
2. The normal acquisition currently reads the local checkout's packet snapshot. Before cutover, authenticate the packet bytes against the advertised main and add a remote concurrency safety gate for simultaneous writers. The existing remote branch is not an exclusive lease.
3. Historical mode currently refuses to auto-destroy a preexisting legacy checkout. Implement exact clean-owner migration and rehydration under an independently verified preservation gate. Never force-remove a dirty old checkout.
4. Explicitly identify and handle cached Git LFS source data not retrievable from remote, secret scanners, file size caps, task-specific non-Git evidence, submodules and worktree output outside Git.
5. Migrate root AGENTS.md, custodian/AGENTS.md, workstream/dispatcher integration, review handoffs, packet index and service launchers in a separately validated cutover. Old dispatcher remains operative until then.
6. Run full repository validation and host smoke. Only then consider replacing dispatch.py; never use this candidate to perform an actual worktree cleanup until the preservation and cutover gates pass.

## Current scope

The opt-in candidate adds only a new CLI, isolated tests and this design note. It does not mutate the current dispatcher, delete worktrees, rewrite task packets, remove refs, repair the legacy ref store or land source changes.
