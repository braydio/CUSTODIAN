# Paired Review Failed Host Validation Import Recovery V1

Implemented the bounded recovery path for a coordinator validation that fails during Godot import before reviewer launch. The implementation preserves immutable original reports, authenticates the exact failed import failure, preserves and verifies new PNG import sidecars, runs fresh full validation into append-only attempt directories, and launches a reviewer only after a verified green result. Failed attempts remain failed and the fresh-validation budget is capped at two.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad40d97-158c-83ea-ad70-d593bc628e6f

## Evidence

- `PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -q` — 145 passed.
- `python3 custodian/tools/validation/run_validation.py --test paired_review_runner_unit --json` — passed, 30.8 seconds against the authorized 90-second bound.
- `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json` — passed 43/43, complete coverage, no timeout or infrastructure errors.
- `python3 -m py_compile custodian/tools/agent/paired_review_runner.py custodian/tools/agent/paired_review_host_validation.py custodian/tools/agent/test_paired_review_runner.py` — passed.
- `git diff --check` — passed.
- Regression assertion compares the full validation manifest bytes to claim baseline `030dbe986c0ced4e8b1dc2c816f466c81146b5f2`, with only `paired_review_runner_unit.timeout_sec` changed from 30 to 90.
- The changed-file validation created 12 untracked candidate `.png.import` sidecars. Each exact allowlisted path was checked against tracked PNG source paths and real Godot resource-path metadata, copied and hash-verified, then only those 12 paths were removed. No preexisting import companions or protected review artifacts were changed.

## Process Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: The original 30-second test timeout was too close to the suite runtime. Real Godot sidecar output also exposed a repo-path versus `res://` mismatch in verifier fixtures. An initial broad cleanup probe was interrupted before deletion when it would have considered preexisting tracked import companions.
- Root cause / contributing factors: The suite had grown beyond its validation budget. The verifier used repository-relative source paths where Godot records project-root paths, and used a filtered Git read for LFS-backed images.
- Prevention / pipeline improvement: Raised only the paired-review suite timeout to 90 seconds with a byte-exact manifest regression assertion. Aligned source-path validation with Godot's project root and used raw Git blob reads for LFS pointers. Fixtures cover the real resource-path form.
- Tooling / docs drift discovered: Ordinary validation may leave exact Grunt candidate import sidecars untracked; coordinator host validation now records and cleans admissible new sidecars on both success and failure.
- Follow-up: fixed-in-scope
- What worked: End-to-end positive, failure, tamper, and bounded-retry tests remain in the paired-review suite; all 43 changed-file checks passed.

The protected review run `20261020T165418Z-53992bd05f83`, its claim, original failed reports, and worktree were not modified or applied. The human visual-review decision remains separate.

## Next Handoff
- Next workstream: `review-agent-paired-review-failed-host-validation-import-recovery-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad40d97-158c-83ea-ad70-d593bc628e6f
- Refresh reason: `none`
- Next action: After independent PASS, run the held review's exact read-only recovery plan and inspect its digest and sidecar inventory; apply only with the separately authorized exact plan digest.
- Blockers or open questions: The protected review run remains held pending fresh independent review and same-run recovery.
