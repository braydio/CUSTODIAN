# AGENT SCRATCH RAM BUDGET HARDENING V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-scratch-ram-budget-hardening-v1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `agent-validation-failure-attribution-v1`
- Locks: `validation-infrastructure, agent-workflow`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-scratch-ram-budget-hardening-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Lock-namespace and concurrency-budget changes need independent negative-control review`
- Reviewed main: `19d466e7817cc15c5a07ffef67054e5c45215b02`
- Authoring chat: `none`
- Visual review: `none`
- Summary backlink: No Authoring chat URL is recorded; state `Authoring chat: none` in summaries.
- Goal: Keep heavy disposable agent scratch on disk and bound concurrent expensive Godot work across worktrees so parallel agent sessions cannot exhaust RAM.
- Completion boundary: Disk-backed configurable scratch root for the Godot validation home and large scratch, a machine-wide Godot job budget layered on the existing per-project lock, a stale-scratch/worktree report that never deletes protected state, measurements before and after, focused tests and docs.
- Current measured state: On 2026-10-10 `/tmp` was a 16 GB tmpfs with 12.2 GB used and 2.5 GB RAM available (31 GB total, no swap). The load was two agent-created clean detached worktrees (`/tmp/custodian-coordination-82d0`, `/tmp/custodian-main-validation-f6831452`, ~12 GB), removed by hand; no repo code creates those names. Official worktrees live on ext4 under `~/Projects/.custodian-worktrees` (65 GB, not RAM). `run_validation.py` previously set one fixed system-temp HOME at both the test and import call sites (6 MB). `godot_project_lock.lock_path_for` derives the lock file from `tempfile.gettempdir()`, so a per-agent TMPDIR would split the lock namespace; `CUSTODIAN_GODOT_LOCK_PATH` already exists. The lock is per project directory, so separate worktrees can run Godot concurrently with no machine-wide cap. About 82 tool modules use `tempfile.TemporaryDirectory`.
- Evidence: custodian/tools/validation/run_validation.py; custodian/tools/godot_project_lock.py; godot_project_lock_smoke.py; AGENT_WORKSTREAM_LIFECYCLE.md; AGENT_PROCESS_FEEDBACK_LEDGER_V1_CLAUDE_SUMMARY.md; the 2026-10-10 `findmnt`, `free`, `du` and `git worktree list` measurements above.
- Task-specific authority: Existing godot_project_lock.py and workstream.py/AGENT_WORKSTREAM_LIFECYCLE.md remain the lock and worktree authorities; extend them, no second lock manager or scheduler.
- Work surface: godot_project_lock.py (shared budget slot primitive and scratch-root resolver), run_validation.py (use resolver and budget around Godot launches), a read-only scratch/worktree reporter inside the existing workstream.py status/gc surface, focused smokes, validation manifest owners, AGENT_WORKSTREAM_LIFECYCLE.md and VALIDATION_RECIPES.md.
- Change: 1) Add one resolver for a scratch root: `CUSTODIAN_SCRATCH_DIR`, default `~/.cache/custodian/`, created 0700. 2) Replace both fixed system-temp HOME overrides with `<scratch>/godot-home`, preserving isolation. 3) Pin lock files to a fixed namespace independent of TMPDIR (derive from the user runtime/cache dir, honor `CUSTODIAN_GODOT_LOCK_PATH`), and keep small locks and lightweight fixtures on the system temp dir. 4) Add a machine-wide counting budget (default 2 concurrent expensive Godot imports/sweeps, `CUSTODIAN_GODOT_MAX_JOBS`) acquired in addition to, never instead of, the per-project writer lock, with a stale-holder (dead PID) takeover and a clear wait message. 5) Add a read-only report of tmpfs-resident worktrees and scratch, flagging any git worktree registered under a RAM-backed mount. It lists protected entries (claimed, blocked, dirty, unpushed) and removes nothing. 6) Record before/after: disk, MemAvailable, peak concurrent Godot processes.
- Preserve: Per-project writer lock semantics and re-entrancy env, existing worktrees under `.custodian-worktrees`, durable evidence, other sessions' dirty files, validation results and manifest ownership.
- Non-goals: No automatic deletion of any worktree, scratch or evidence; no migration of existing worktrees; no new cache manager or scheduler; no global TMPDIR override; no rewrite of the ~82 TemporaryDirectory call sites; no Godot runtime changes.
- Acceptance: 1) The runner contains no fixed system-temp HOME literal and Godot home resolves under the scratch root; 2) lock path is identical for two processes with different TMPDIR; 3) with budget N, process N+1 waits and a dead holder is reclaimed; 4) budget does not bypass or replace the project lock, and re-entrant nested runs do not deadlock; 5) reporter flags a worktree on tmpfs, lists protected entries and performs zero deletions (tested by fixture); 6) before/after measurements recorded in the summary; 7) docs describe the env vars and defaults.
- Validation: Focused godot_project_lock_smoke extensions (TMPDIR split, budget wait, stale holder, re-entrancy), reporter fixture, run_validation.py focused runs for touched manifest checks, then `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`; check_ai_context.py --json; validate_review_pairing.py; task_packet_index.py; git diff --check.
- Deferred: Auto-cleanup policy for stale scratch, per-agent memory cgroup limits, migrating TemporaryDirectory call sites, and a tmpfs size cap in system configuration (host-level, outside the repo).

- Task overrides: `none`

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: Configurable 0700 scratch root resolves isolated Godot HOME under `godot-home`; lock paths are stable across TMPDIR and the two-slot machine budget waits, re-enters, layers with the per-project lock, and reclaims dead holders. The reporter identifies tmpfs scratch/worktrees and protected claimed, blocked, dirty, and unpushed state without deleting. Focused runner, lock, reporter, workstream-artifact, metadata, and final changed-file validation all pass. Before/after storage, available-memory, and Godot concurrency measurements are in the closing summary.

## Execution Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: The first child-lifetime negative control exposed that an explicit flock unlock released the shared job slot while a spawned child was still running. The first changed-file sweep then caught nine dispatch-test errors because fake copied workstreams could not import the new top-level helper. Both were fixed in-scope; the focused dispatch suite passed 80/80 and the final changed-file sweep passed 33/33. The first scratch smoke also found outdated fixed-HOME commands in active design examples, which were updated.
- Root cause / contributing factors: `flock` is associated with the shared open file description, so explicit unlock in the parent bypassed the inherited child hold. Importing the storage helper at module load made isolated dispatch fixtures depend on an adjacent file they intentionally do not copy.
- Prevention / pipeline improvement: Pass project and budget lock descriptors to launched checks and release them only by closing the final descriptor; smoke covers parent-exit retention and child-exit release. Load the storage helper only when the real status report is requested.
- Tooling / docs drift discovered: Active validation examples used the previous fixed temporary HOME; aligned them with the configurable scratch root.
- Follow-up: fixed-in-scope
- What worked: Separate two-process TMPDIR probes, lock contention/death tests, and injected-mount reporter fixtures kept each acceptance claim falsifiable without launching extra Godot sweeps.

## Next Handoff
- Next workstream: review-agent-scratch-ram-budget-hardening-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: none
- Refresh reason: none
- Next action: After implementation lands and archives, run the paired fresh-context review.
- Blockers or open questions: none
