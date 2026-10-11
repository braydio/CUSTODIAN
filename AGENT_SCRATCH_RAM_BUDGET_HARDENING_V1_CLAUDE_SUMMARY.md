# Scratch RAM Budget Hardening V1

## Result

Moved the validation HOME under a configurable 0700 scratch root, defaulting to `~/.cache/custodian/`. Both validation tests and the import subprocess now use `<scratch>/godot-home`. Lock paths derive from the user cache namespace rather than TMPDIR, while `CUSTODIAN_GODOT_LOCK_PATH` remains the explicit per-project override.

Added a machine-wide counting semaphore with a default of two slots, configurable through `CUSTODIAN_GODOT_MAX_JOBS`. The runner acquires the slot alongside the existing per-project writer lock. It emits a wait message with holder details, recovers dead holders via flock, supports nested reentrancy, and passes lock descriptors into spawned checks so a surviving child retains the project and budget locks if its parent exits.

`workstream.py status` now reports scratch filesystem usage and registered worktrees on tmpfs/ramfs. It marks registered worktrees as protected and reports claimed, explicitly blocked, dirty, and unpushed/no-upstream reasons. The report performs no deletions. Its fixture verified a synthetic tmpfs worktree, protected reasons, unchanged files, zero deletions, and no scratch-directory creation.

Updated lifecycle/validation guidance, current state, active design command examples, the validation manifest, and the archived packet. Historical reports remain historical records.

## Validation

- `godot_project_lock_smoke.py`: PASS — independent processes with different TMPDIR resolve one lock path; N+1 waits; dead holder recovery; default two slots; project/budget layering; nested reentrancy; child descriptor retention and release; scratch mode 0700.
- `scratch_storage_report_smoke.py`: PASS — RAM-backed scratch/worktree detection, claimed/blocked/dirty/unpushed protection, zero deletion.
- `validation_runner_smoke.py`: PASS — test and import HOME resolve under configured scratch.
- `test_dispatch.py`: PASS, 80/80 after lazy-loading the status reporter dependency.
- `test_workstream_artifacts.py`: PASS, 13/13.
- Runner-focused `godot_project_lock` and `scratch_storage_report`: PASS.
- `check_ai_context.py --json`: PASS, zero findings.
- Packet index and review pairing: PASS (65 auto pairs).
- `git diff --check`: PASS.
- Final `run_validation.py --changed --base origin/main --json`: PASS, 33/33, complete coverage, no skips.

The first child-lifetime control found that explicit flock unlock released the slot before an inherited child exited; close-only release is now covered by a passing regression. The first changed sweep also found nine dispatch fixture errors caused by a top-level import from a helper those copied fixtures do not include. Lazy-loading fixed it, the direct dispatch suite passed, and the final changed sweep passed.

## Before / After Measurements

Captured on 2026-10-11 in this worktree. Godot process counts include the already-open editor.

| Metric | Before implementation | After final sweep |
| --- | ---: | ---: |
| MemAvailable | 10 GiB | 9.3 GiB |
| `/tmp` tmpfs | 238 MiB used / 16 GiB | 236 MiB used / 16 GiB |
| Project/cache ext4 | 703 GiB used, 166 GiB free | 705 GiB used, 165 GiB free |
| Godot processes at idle | 1 | 1 |
| Peak concurrent Godot processes during validation | 2 | 2 |
| Scratch root | Prior isolated HOME was 6.2 MiB under system temp | 4.5 MiB under user cache; Godot HOME is under this root |

The final sweep used one validation job plus the existing editor and stayed within the configured job ceiling. No worktrees, scratch, or evidence were deleted.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: The first child-lifetime negative control exposed an explicit-unlock bug. The first changed sweep exposed nine dispatch test errors from an eager import in isolated fixture copies. Both were fixed before the final green sweep.
- Root cause / contributing factors: flock locks are tied to a shared open file description; eager reporter import made copied workstream fixtures depend on an adjacent module.
- Prevention / pipeline improvement: Keep inherited descriptors open until children exit; load the storage reporter helper only when status reporting is invoked. Both conditions now have regression coverage.
- Tooling / docs drift discovered: Active commands still used the former fixed temporary HOME; updated them to the scratch-root convention.
- Follow-up: fixed-in-scope
- What worked: Separate lock, reporter, runner, and dispatch controls made failures attributable without relaxing validation.

Authoring chat: none

## Next Handoff

- Next workstream: review-agent-scratch-ram-budget-hardening-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: none
- Refresh reason: none
- Next action: Run the fresh-context paired review after this implementation lands and archives.
- Blockers or open questions: none
