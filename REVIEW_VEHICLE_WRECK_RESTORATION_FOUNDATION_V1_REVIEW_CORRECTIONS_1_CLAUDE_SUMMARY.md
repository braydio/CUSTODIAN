# Review: Vehicle Wreck Restoration Foundation V1 — Review Corrections 1

## Result

Review outcome: **passed; no findings and no correction-2**. Correction commit `a5df0bb65` was reviewed on live `main@e56a75cfb`. The production Operator lifecycle starts restoration from the existing interaction target, tracks the current Interact hold each simulation tick, and cancels on release, target loss, range exit, or interruption before payment. Completion spends once and restores the same vehicle at 40% health.

## Findings

None. `R0-01` is fixed. The interaction becomes unavailable as the vehicle transitions out of wreckage before `vehicle_restored` emits, so a synchronous reentrant completion fails validation before a second payment.

## Evidence

- The focused smoke exercises press dispatch, release cancellation, target loss, out-of-range refusal, uninterrupted hold, exact configured resource spend, same-instance restoration, and duplicate completion. It also retains resolver and direct-scene coverage.
- `python3 custodian/tools/validation/run_validation.py --tag vehicle --json`: PASS, 4 selected / 4 passed — `vehicle_wreck_restoration`, `vehicle_registry_contract`, `vehicle_runtime_lifecycle`, `vehicle_exit_clearance`.
- `git diff --check a5df0bb65^ a5df0bb65`: PASS.
- Existing diagnostics: blocked-exit warnings in lifecycle/exit-clearance checks and known ObjectDB/resource shutdown leaks in wreck-restoration smoke. All assertions passed.
- Graph review did not map the changed GDScript nodes; the review used the exact implementation diff and targeted live-source inspection.
- The repository-wide review-pairing guard did not report this vehicle pair but failed on unrelated active packet metadata for three other workstreams. Those packets were outside this review's authorized artifact scope and were left untouched.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: code-review-graph did not map the changed GDScript nodes; the repository-wide review-pairing guard exposed unrelated active packet drift.
- Root cause / contributing factors: the graph index had no structural entries for these files at the reviewed commit; three other active packet pairs have stale or malformed metadata.
- Prevention / pipeline improvement: use graph orientation, then inspect focused source when graph coverage is absent; route unrelated pairing drift to its packet owners.
- Tooling / docs drift discovered: review-pairing guard currently fails on unrelated packet metadata for three active workstreams.
- Follow-up: none
- What worked: the focused vehicle validation reproduced all four required green checks.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b

## Next Handoff

- Next workstream: vehicle-field-scout-buggy-class-v1-recovery-1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b
- Refresh reason: Only landed API/path reconciliation unless the held-input correction changes the reviewed class seam.
- Next action: Claim the Scout class recovery and reconcile its packet against current main.
- Blockers or open questions: none
