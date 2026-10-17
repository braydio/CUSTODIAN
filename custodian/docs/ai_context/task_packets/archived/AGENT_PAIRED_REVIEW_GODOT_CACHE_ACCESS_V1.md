# AGENT PAIRED REVIEW GODOT CACHE ACCESS V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-godot-cache-access-v1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `agent-workflow`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-godot-cache-access-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `sandbox permission changes around machine-wide Godot concurrency controls require independent workflow review`
- Reviewed main: `075025f41a6a7f6bafb6df13a816d54a23dc87af`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Goal: Let restricted paired-review Codex sessions run ordinary Godot validation through the existing shared CUSTODIAN cache/job-budget namespace without granting Git metadata write access or bypassing concurrency protection.
- Completion boundary: `paired_review_runner.py` exposes only the existing CUSTODIAN scratch/cache namespace required by `run_validation.py` and `GodotJobBudget` to the reviewer sandbox, while shared Git metadata remains restricted; focused tests prove the reviewer can acquire the real machine-wide job slot/project lock and use the isolated Godot HOME, and cannot write repository Git metadata.
- Current measured state: Restricted reviewers are launched with writable access to the claimed worktree and review run directory only. `GodotJobBudget` stores its machine-wide slots under the user cache namespace (normally `~/.cache/custodian/locks`) and validation uses the CUSTODIAN scratch root for isolated Godot HOME. Multiple real reviews, including Loot Toast and `review-procgen-ambient-real-world-spawn-recovery-v1`, reached otherwise-valid review evidence but could not start required validation because this cache namespace was outside the sandbox. The ambient review is preserved in protected `post_exit_recovery`; this packet fixes future launches, not that run's historical reviewer context.
- Evidence: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/godot_project_lock.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/validation/godot_project_lock_smoke.py`; archived paired-review coordinator-boundary receipts documenting read-only lock failures; current ambient review recovery evidence.
- Task-specific authority: `paired_review_runner.py` owns reviewer sandbox launch; `godot_project_lock.py` owns the real per-project lock and machine-wide job budget; `run_validation.py` owns validation execution. Do not create a second lock namespace or disable either lock.
- Work surface: `custodian/tools/agent/paired_review_runner.py`; its focused tests; only the smallest documentation note required in `AGENT_WORKSTREAM_LIFECYCLE.md` / `VALIDATION_RECIPES.md` if behavior changes.
- Change: Resolve the canonical CUSTODIAN scratch/cache root from the same authority used by `godot_project_lock.py`, ensure the coordinator creates the required directory before launch, and add that exact directory as an additional writable `codex exec --add-dir` sandbox path for paired reviewers. Preserve the existing run-evidence `--add-dir`. Prefer the narrow CUSTODIAN cache root, not the user's whole home or `.git`. The reviewer must therefore share the same machine-wide `GodotJobBudget` slots and per-project lock namespace as all other validation runs while gaining access to the isolated Godot HOME.
- Preserve: Fresh reviewer context; read-only shared Git metadata; prohibition on reviewer fetch/push/add/commit/checkpoint/finish; coordinator-only landing; real machine-wide max-jobs behavior; per-project writer lock; existing `CUSTODIAN_SCRATCH_DIR`, `XDG_CACHE_HOME`, `CUSTODIAN_GODOT_LOCK_PATH` semantics; existing run evidence; all gameplay code.
- Non-goals: No `--no-godot-lock`; no sandbox-wide home access; no alternate project-local job-budget namespace; no reviewer Git writes; no automatic recovery of existing `post_exit_recovery` runs; no gameplay changes.
- Acceptance: (1) synthetic restricted-review launch includes exactly the worktree, run-evidence directory and canonical CUSTODIAN cache/scratch root as writable paths; (2) focused fixture can acquire/release the same `GodotJobBudget` slot visible to a coordinator process; (3) per-project Godot lock remains enforced; (4) isolated Godot HOME is writable; (5) a probe attempting shared `.git/FETCH_HEAD` or index mutation remains denied by the reviewer contract/sandbox; (6) no lock disable env is injected; (7) existing paired-review runner, job-budget and coordinator-boundary tests remain green; (8) changed-file validation and `git diff --check` pass.
- Validation: Add focused unit fixtures around paired-review argv/path construction and cache-root resolution; run `python3 -m unittest test_paired_review_runner` from `custodian/tools/agent`; run `python3 custodian/tools/validation/godot_project_lock_smoke.py` or its registered manifest owner; run affected workflow tests, changed-file validation, AI-context/pair/index checks, and `git diff --check`.
- Task overrides: `none`
- Deferred: A generic paired-review `recover` CLI for already-protected runs remains owned by the existing orphan/recovery roadmap; this slice only fixes future sandbox validation access.

## Completion Truth
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `The initial claim command outlived its short tool wait; the dispatcher kept its lock until the verified claim completed. One test fixture initially read the default HOME outside its configured environment block; the assertion was corrected and rerun.`
- Root cause / contributing factors: `The first claim call did not preserve its long-running session handle in the displayed result; the fixture's HOME assertion was outside the environment override scope.`
- Prevention / pipeline improvement: `Allow sufficient wait for dispatcher claims and retain the returned process session; keep environment-dependent assertions inside their configured environment scope.`
- Tooling / docs drift discovered: `Paired-review launches previously exposed only run evidence, leaving Godot validation's shared cache/job-budget paths outside the sandbox.`
- Follow-up: `fixed-in-scope`
- What worked: `The lock module now supplies the job-budget root used by both validation and paired-review sandbox setup.`

## Handoff
- Next workstream: `review-agent-paired-review-godot-cache-access-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `none`
- Next action: `Launch the exact fresh paired review through paired_review_runner.py after this implementation lands.`
- Blockers or open questions: `none`
