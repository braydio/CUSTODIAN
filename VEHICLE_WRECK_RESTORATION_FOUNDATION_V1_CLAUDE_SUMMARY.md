# Vehicle Wreck Restoration Foundation V1

## Result

Implemented the wreck-first vehicle lifecycle from the current packet. The Scout archetype now resolves `field_scout_recovery_light`: 12 `ruin_scrap`, 6 `structural_alloy`, 1 `power_components`, a 4-second hold, and restoration to 40% health.

Resolver-spawned and direct-scene fallback vehicles enter at zero health in the disabled/destroyed lifecycle without emitting `vehicle_destroyed`. Wrecks retain generic vehicle identity but leave `pilotable_vehicles` and the parent `interactable` group. One child interaction handles range, cancellation, resource checks, payment, and restoration. The same vehicle instance returns to operational groups at 40 HP and emits `vehicle_restored`; later lethal damage removes operational groups and reactivates the same recovery interaction.

The registry schema and loader now carry and validate restoration-profile identity/data. The resolver no longer overrides lifecycle-owned pilotable-group membership. The lifecycle and exit test fixtures now explicitly construct unprofiled vehicles where they are testing generic safe-exit behavior.

## Evidence

- `vehicle_registry_contract`: PASS.
- `vehicle_runtime_lifecycle`: PASS.
- `vehicle_exit_clearance`: PASS.
- `vehicle_wreck_restoration`: PASS, covering resolver/direct-scene parity, initial state and groups, no fake destruction, insufficient resources, interrupted and out-of-range holds, exact payment, actual vehicle entry, lethal re-wreck, and repeat restoration.
- Focused `run_validation.py --changed --json`: PASS, 8 selected / 8 passed, complete coverage.
- Final post-archive `run_validation.py --changed --json`: 15 selected, 10 passed, 1 failed, and 4 skipped, with complete coverage. Its sole failure is `review_pairing_contract`, which reproduces on clean `origin/main` with the same six unrelated packet-metadata defects.
- `git diff --check`: PASS.

The existing safe-exit tests intentionally print a blocked-exit warning in their pathological cases. The new restoration smoke reports the repository’s known SceneTree shutdown leak warning; its assertions pass.

## Workstream transition

The previous healthy-spawn class implementation was superseded by the wreck-first design. Donor commit `b3b40921f1fd08c6aff529cbe0b39953587bbb85` was preserved under remote tag `archive/agent-vehicle-field-scout-buggy-class-v1-20261007`; the superseded agent branch was retired through `branch_hygiene.py --retire-approved` before this packet was claimed. No donor implementation was merged into this workstream.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: The fresh worktree needed a full Godot editor import before headless scripts could resolve global classes and imported resources. The final changed-file sweep also selected a repository-wide review-pairing test that fails on six unrelated packet-metadata defects, reproduced on clean `origin/main`.
- Root cause / contributing factors: No `.godot` import cache existed in the new worktree; the runtime restoration smoke did not prove schema-validation behavior; current main contains unrelated paired-review metadata drift.
- Prevention / pipeline improvement: Initialize Godot imports in cold worktrees, give schema/registry-validator changes a dedicated manifest test, and route packet-pairing drift to its owning workstreams.
- Tooling / docs drift discovered: `review_pairing_contract` fails on unchanged `origin/main` with six packet-metadata errors; `check_ai_context` reports ten unrelated packet grammar/required-field findings.
- Follow-up: manual-follow-up
- What worked: One focused runtime smoke proved both spawn routes and the entire payment, cancellation, restoration, and re-wreck cycle.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b

## Next Handoff

- Next workstream: `review-vehicle-wreck-restoration-foundation-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `none`
- Next action: `Finish this implementation, then claim the paired fresh-context review when eligible.`
- Blockers or open questions: `none`
