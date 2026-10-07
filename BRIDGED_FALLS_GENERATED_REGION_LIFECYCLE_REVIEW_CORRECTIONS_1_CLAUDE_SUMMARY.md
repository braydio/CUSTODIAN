# Bridged Falls Generated Region Lifecycle Review Corrections 1

Implemented the R0-01 correction in the staging adapter. `GeneratedRegionLevel` checks that the map has its ProcGen owner and required floor/wall layers before generation, then awaits the existing `level_data_ready` signal directly instead of polling frames. A missing dependency becomes a staging failure consumed by the existing route rollback.

Added a deterministic fixture with no ProcGen owner. The expanded route lifecycle smoke proves that this failure resolves promptly with a useful reason and restores the same authored source, Operator identity and position, and shared camera binding. The successful generated traversal and late missing-spawn negative control remain green.

## Validation

- `generated_region_route_lifecycle_smoke.gd`: PASS after a fresh worktree import.
- `ash_bell_lower_quarter_route_smoke.gd`: PASS (`nodes=3 edges=6`).
- `procgen_intent_graph_smoke.gd`: PASS.
- `sundered_keep_route_graph_smoke.gd`: reproduces the documented baseline failure, `Front Gate backtrack arrival guard was not armed`.
- `run_validation.py --changed --json --base origin/main`: PASS, 7/7 tests with complete changed-file coverage. The generated-region lifecycle smoke is now registered in the manifest, and the two expected route rollback errors from its negative controls have exact known-warning patterns.
- An initial broader ProcGen sweep ran 31 checks, with 30 passing and `procgen_ambient_enemy_real_world_spawn` failing because seed `12345` produced no canonical safe spawn (72 main-component cells, zero safe cells). The same failure reproduced on clean project-root `main` at `9038f8eee`. The final narrower diff no longer changes `ProcGenTilemap`, so this unrelated check is not selected.
- `git diff --check`: PASS.
- Moment Forge: not run — this is a generated staging failure/rollback logic correction with deterministic state assertions; audiovisual presentation is not acceptance.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: The initial broad changed-file run selected an unrelated ProcGen ambient-spawn smoke that fails on clean main; the lifecycle smoke was missing from the manifest and its expected rollback errors were treated as fatal.
- Root cause / contributing factors: The fixed ambient seed produced a 72-cell accepted component with no safe spawn. The manifest lacked a generated-region owner entry and the warning registry did not classify the smoke's intentional route rollback errors.
- Prevention / pipeline improvement: Registered the focused test and added exact expected-error patterns; final changed-file validation now passes with complete coverage.
- Tooling / docs drift discovered: Generated-region lifecycle changed-file ownership and expected rollback classification were missing; fixed in-scope.
- Follow-up: review-bridged-falls-generated-region-lifecycle-review-corrections-1
- What worked: Dependency preflight lets the adapter await `level_data_ready` without polling and preserves the existing route rollback owner.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c

## Next Handoff

- Next workstream: `review-bridged-falls-generated-region-lifecycle-review-corrections-1`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Refresh reason: none
- Next action: After this correction lands and archives complete, claim the paired fresh-context review.
- Blockers or open questions: The documented Sundered Keep arrival-guard baseline failure and clean-main ambient-spawn smoke failure remain outside this correction.
