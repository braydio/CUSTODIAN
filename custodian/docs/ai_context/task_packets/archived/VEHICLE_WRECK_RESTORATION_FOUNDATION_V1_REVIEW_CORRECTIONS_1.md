# CORRECTION: Vehicle Wreck Restoration Foundation V1 — Review Corrections 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vehicle-wreck-restoration-foundation-v1-review-corrections-1`
- Kind: `correction`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-vehicle-wreck-restoration-foundation-v1`
- Locks: `vehicle-runtime`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-vehicle-wreck-restoration-foundation-v1-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `ebf737b5111b7efa6db5e6ceaa6f50da44f0fee4`
- Parent implementation: `vehicle-wreck-restoration-foundation-v1` — `custodian/docs/ai_context/task_packets/archived/VEHICLE_WRECK_RESTORATION_FOUNDATION_V1.md`
- Parent review: `review-vehicle-wreck-restoration-foundation-v1` — `custodian/docs/ai_context/task_packets/archived/REVIEW_VEHICLE_WRECK_RESTORATION_FOUNDATION_V1.md`
- Findings addressed: `R0-01`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Goal: Make wreck restoration require a continuous four-second Interact hold and cancel free when the input is released or the interaction is otherwise interrupted.
- Completion boundary: Done when production input starts restoration only while Interact is held, release/interruption before completion cancels with no ResourceLedger mutation, and uninterrupted completion spends the exact configured cost once and restores the same vehicle.
- Current defect/evidence: Finding `R0-01` in the parent archived packet. `VehicleRestorationInteraction.interact()` starts an elapsed timer, and `_physics_process()` completes it without checking held input. The Operator interaction handler only dispatches `just_pressed`, and the current smoke simulates cancellation by directly calling `cancel_restoration()`.
- Evidence: `custodian/docs/ai_context/task_packets/archived/VEHICLE_WRECK_RESTORATION_FOUNDATION_V1.md` → `## Independent Review` → `R0-01`; `custodian/game/vehicles/vehicle_restoration_interaction.gd`; `custodian/game/actors/operator/operator.gd`; `custodian/tools/validation/vehicle_wreck_restoration_smoke.gd`.
- Task-specific authority: `design/02_features/vehicles/VEHICLES.md` world-spawn recovery rule; parent archived V1 acceptance and review finding `R0-01`.
- Work surface: `custodian/game/vehicles/vehicle_restoration_interaction.gd`; the narrow Operator/input seam needed to communicate Interact release; `custodian/tools/validation/vehicle_wreck_restoration_smoke.gd` and its validation manifest ownership if affected.
- Required correction: Track the Interact hold as a real input lifecycle. A press may start the operation, but it must cancel immediately when the same actor releases Interact, leaves range, loses the target, or otherwise interrupts. Payment must remain post-hold and exactly-once. Preserve direct scene and resolver behavior and do not introduce a parallel interaction authority.
- Preserve: Current profile values (12 ruin scrap, 6 structural alloy, 1 power component, four seconds, 40% health); resource refusal; same-instance restoration; restoration interaction availability; Operator's existing interaction ownership and input mapping.
- Non-goals: No economy tuning, vehicle class/art changes, persistence, new vehicle types, generic interaction-system redesign, or unrelated input refactor.
- Acceptance: (1) A real Interact press starts one restoration hold. (2) Releasing Interact before four seconds cancels and spends zero resources. (3) Moving out of range or losing target cancels and spends zero. (4) A continuous in-range four-second hold spends exactly the configured cost once and restores the same instance to 40 HP. (5) A second/reentrant completion cannot double-charge or double-restore. (6) Tests exercise the production input lifecycle; direct calls to cancellation alone are insufficient proof.
- Validation: Focused wreck-restoration smoke, `vehicle_runtime_lifecycle`, `vehicle_registry_contract`, and `vehicle_exit_clearance`; verify packet/artifact checks and `git diff --check`. Record exact results and any known warnings.
- Task overrides: `none`
- Deferred: Broader interaction architecture work beyond the narrow held-input seam.

## Independent Review

- Status: `passed`
- Reviewed main: `e56a75cfb`
- Reviewed implementation commit: `a5df0bb65` (`vehicle restoration, held input`).
- Findings: none; `R0-01` is fixed. No correction-2 created.
- Evidence: production Operator dispatch/update path tracks the real held-state contract; release, target loss, range exit, and interruptions cancel before payment. The interaction validates and pays once, then makes the vehicle operational and disables restoration before synchronous restoration signals can reenter. The focused smoke covers press/release, target loss, range refusal, uninterrupted hold, exact cost, same-instance restoration at 40 HP, and duplicate completion.
- Focused validation: `vehicle_wreck_restoration`, `vehicle_registry_contract`, `vehicle_runtime_lifecycle`, and `vehicle_exit_clearance` all passed (4 selected / 4 passed).
- Diagnostics: known restoration ObjectDB/resource shutdown leaks and deliberate blocked-exit warnings remained; all assertions passed.
- Diff check: `git diff --check a5df0bb65^ a5df0bb65` passed.
- Review-pairing guard: this vehicle pair was not reported; the repository-wide guard failed on unrelated metadata for three other active workstreams, recorded in the paired review packet and summary.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: Production `Operator._handle_interact_input()` now starts the restoration through its existing interaction target, and `_update_held_restoration_input()` sends current held state and target continuity to `VehicleRestorationInteraction` every simulation tick. The interaction cancels on release, target loss, range exit, and interruption; completion still validates and spends once before restoring the same vehicle. The `vehicle_wreck_restoration` smoke exercises the Operator press/release path, target loss, range refusal, uninterrupted hold, exact resource spend, same-instance restore, and reentrant completion refusal. `vehicle_registry_contract`, `vehicle_runtime_lifecycle`, and `vehicle_exit_clearance` also pass.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: The first claim command returned no receipt; `last-claim --json` recovered the verified claim. The cold worktree required a Godot import before validation.
- Root cause / contributing factors: The dispatcher response was lost at the tool boundary, and this fresh worktree had no imported `.godot` cache.
- Prevention / pipeline improvement: Use the documented read-only `last-claim` recovery when claim output is missing; initialize imports once in cold worktrees.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: `--tag vehicle` produced one green report covering all four packet validation IDs.

## Handoff

- Next workstream: `vehicle-field-scout-buggy-class-v1-recovery-1`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `Only landed API/path reconciliation unless the held-input correction changes the reviewed class seam.`
- Next action: Claim the Scout class recovery and reconcile its packet against current main.
- Blockers or open questions: `none`

## Independent Review

- Status: `passed`
- Review workstream: `review-vehicle-wreck-restoration-foundation-v1-review-corrections-1`
- Reviewed on main: `e56a75cfb`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Blocking defects: `0`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `R0-01 (fixed)`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_VEHICLE_WRECK_RESTORATION_FOUNDATION_V1_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `none`

R0-01 is fixed. The production Operator dispatch/update path observes press, held state, release, target loss, range exit, and interruption before completion. Cancellation leaves ResourceLedger unchanged. An uninterrupted hold pays the configured cost once and restores the same vehicle at 40% health; reentrant completion does not pay or emit a second restoration. The focused smoke, registry contract, lifecycle, and exit-clearance validations passed. The existing blocked-exit warnings and known restoration-shutdown leak warnings remain non-failing diagnostics.
