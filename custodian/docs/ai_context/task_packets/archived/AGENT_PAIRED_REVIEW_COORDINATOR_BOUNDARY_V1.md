# AGENT PAIRED REVIEW COORDINATOR BOUNDARY V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-coordinator-boundary-v1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
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
- Reviewed main: `2ffbbec13d55a939096750d059602ea56047cae3`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Visual review: `none`
- Summary backlink: Repeat exact Authoring chat URL in durable summaries and Next Handoff.
- Goal: Repair the existing paired-review runner's deterministic post-exit completion truth and coordinator/reviewer Git-metadata ownership, eliminating false-blocked landed reviews without accepting incomplete or unauthorized ones.
- Completion boundary: One correction to paired_review_runner.py and its focused tests: exact summary lookup, authoritative post-land result, restricted Git sandbox completion path, idempotent recovery, and immutable reviewed target check.
- Current measured state: Full 2026-10-11 Codex audit log repeatedly records `fatal: path 'origin/main:<summary>.md' does not exist`, `Codex exited 0 without durable review state`, and linked-worktree FETCH_HEAD permission errors. On current main, `git grep -l ... origin/main` yields revision-qualified names, while runner passes them into `git show origin/main:<name>`; broad text grep also does not verify a specific review's closing summary. `git fetch ... check=False` ignores fetch failure. Existing workstream.py finish and PF4 read-only preflight remain authoritative.
- Evidence: Uploaded 2026-10-11 Codex conversation audit (review PF1, PF2, PF3 and NPA Showcase incidents); custodian/tools/agent/paired_review_runner.py `run`, `packet_at_main`, `parse_claim_receipt`, and `launch_codex`; workstream.py `closing_summary_committed_for_workstream`, `preflight`, `finish`; tests for paired_review_runner and finish; archived prior NPA-7 and operator-baseline correction receipt.
- Task-specific authority: Reuse paired_review_runner.py, dispatch.py exact claim receipt, task_packet_contract.py, workstream.py finish, paired review packet bounded override and same fresh-context gate. Coordinator owns Git metadata/fetch/landing; reviewer authors bounded review evidence.
- Work surface: Edit custodian/tools/agent/paired_review_runner.py and focused tests; use existing workstream/dispatch helpers for exact-path review state and controlled coordinator post-review Git operations; adjust only directly affected workflow docs.
- Change: (A) Normalize Git grep matches to repository paths or, preferably, derive the expected exact closing-summary identity from the review workstream and inspect `origin/main:<path>` directly; never double-prefix a revision or select the first unrelated summary mentioning the slug. (B) After reviewer exits, fetch with explicit failure semantics and pin a single remote-main SHA; inspect exact archived review packet (workstream/status), exact root summary, required authoring-chat and review receipt plus reviewed implementation SHA, and permitted diff. (C) On successful landed result mark complete even if ephemeral reviewer workspace/branch has been torn down; on nonzero/absent/ambiguous receipt never label success. (D) Reproduce sandbox denied FETCH_HEAD and avoid asking restricted reviewer to fetch or finish shared .git when unauthorized: coordinator fetches/prepares reviewed refs; reviewer can emit only bounded evidence, coordinator verifies and performs allowed stage/commit/finish using existing lifecycle. No new finisher and no blanket Git write grant. (E) Persist run state plus recoverable branch/worktree/metadata idempotently and never double-claim after one valid claim. First add failing fixture reproductions. If the sandbox failure is no longer reproducible, do not expand privileges or introduce unnecessary handoff code.
- Preserve: Independent fresh reviewer context; no implementation edits from review, exact target SHA, no widened Git write permissions, no waived red validations, clean receipt provenance, original claim/trace/run directory after failure, no force/reclaim/reset.
- Non-goals: No dispatcher or land_main replacement, general global-next chaining change (separate packet), reusable validation cache (separate packet), credential plumbing or new review platform.
- Acceptance: 1) Negative fixture reproduces `origin/main:origin/main:<summary>` failure before and successful exact summary after; 2) multiple unrelated summaries mentioning the slug do not satisfy closeout; 3) genuinely complete archived review + matching exact summary + receipt returns COMPLETE on remote SHA even when worktree removed and Codex exit 0; 4) absent/mismatched/failed receipt or stale-fetch remote SHA remains BLOCKED; 5) read-only FETCH_HEAD fixture is recovered only with coordinator-owned authorized Git operations and reviewer path restrictions; 6) rerun after block never claims duplicate/reviews wrong SHA; 7) focused existing review/dispatch/workstream tests and repo authoring/paired index checks pass.
- Validation: Focused paired_review_runner test suite with isolated Git repos and injected fake codex processes, exact grep path/summary identity/archival/exit code/fetch failure/removal races/permissions/unauthorized diff cases; workstream finish and dispatch claim checks; python3 custodian/tools/agent/check_ai_context.py --json, validate_review_pairing.py, task_packet_index.py, run_validation.py --changed --base origin/main --json, git diff --check.
- Deferred: Distributed review runner, alternative reviewer auth, broad coordinator redesign and general next-task orchestration.

- Task overrides: `none`

## Audit-Resolved Promotion And Execution Gate

- Human authorization: User approved these pipeline fixes in the current CUSTODIAN authoring chat.
- Static cause confirmed: `git grep -l ... origin/main` output is a revision-prefixed path but the runner double-adds `origin/main:` before `git show`.
- Execution gate: Reproduce both exact-summary and restricted-Git failures in focused tests before modifying the runner; if the latter has already been fixed upstream, only repair observed residual causes.
- No user planning refresh is required to start this already scoped correction; incomplete runtime evidence is a fail-closed validation requirement, not a reason to silently widen review permissions.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Superseded/legacy production path disposition: `n/a`
- Evidence: The exact-summary and revision-prefix regressions, unrelated-summary negative control, failed-fetch fail-closed path, immutable target and receipt binding, bounded coordinator staging, and unauthorized-file rejection pass in isolated Git fixtures. Focused paired-review, dispatch, workstream, artifact, context, pairing, index, changed-file, and diff checks are recorded in the closing summary.

## Execution Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The first combined unittest invocation used module names without the agent-tools directory on Python's import path.
- Root cause / contributing factors: The runner test imports its sibling module by top-level name; the combined invocation omitted `PYTHONPATH`.
- Prevention / pipeline improvement: Set `PYTHONPATH=custodian/tools/agent` when grouping these suites by module name.
- Tooling / docs drift discovered: The old runner prompt assigned shared Git fetch and finish operations to the restricted reviewer process; lifecycle documentation now records coordinator ownership.
- Follow-up: none
- What worked: Isolated temporary Git remotes reproduced both exact-path and coordinator-write boundaries without touching live claims.

## Next Handoff

- Next workstream: `review-agent-paired-review-coordinator-boundary-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Refresh reason: `none`
- Next action: `After this implementation lands and archives, launch the exact paired review in a fresh reviewer context through paired_review_runner.py.`
- Blockers or open questions: `none`
