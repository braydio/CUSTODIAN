# Review: Vehicle Wreck Restoration Foundation V1

## Result

Review outcome: **findings**. Landed `ebf737b5111b7efa6db5e6ceaa6f50da44f0fee4` implements the wreck-first lifecycle, restoration profile, resource gate/payment, same-instance restoration, and re-wreck flow. One blocking runtime defect prevents acceptance: restoration starts on a single Interact press and continues after release, so the required four-second hold is not enforced.

## Finding

- **R0-01 — blocking defect, runtime.** `VehicleRestorationInteraction.interact()` starts the timer, and `_physics_process()` completes it solely from elapsed time. The Operator forwards only `_input_frame.just_pressed(&"interact")`; no production path observes release or cancels the interaction. A tap therefore starts a full restore. The smoke's cancellation assertion invokes `cancel_restoration()` directly and does not validate real input release. The correction must prove press/release behavior through the production input lifecycle, along with free out-of-range/target-loss cancellation and exactly-once post-hold payment.
- The durable finding and its evidence are in `custodian/docs/ai_context/task_packets/archived/VEHICLE_WRECK_RESTORATION_FOUNDATION_V1.md` under `## Independent Review`.

## Evidence

- Fresh focused validation: `vehicle_wreck_restoration` PASS; `vehicle_registry_contract` PASS; `vehicle_runtime_lifecycle` PASS; `vehicle_exit_clearance` PASS.
- Wreck restoration smoke reports known Godot ObjectDB/resource shutdown leak warnings while assertions pass. Existing exit-path smokes emit the expected warning for deliberately blocked exits.
- `git diff --check ebf737b51^ ebf737b51`: PASS.
- Code and architecture review covered the active `VEHICLES.md` rule, archived V1 acceptance, registry/profile loading, resolver and direct scene fallback, lifecycle transitions, Operator dispatch, ResourceLedger payment path, and the focused restoration smoke.
- The review packet's `Reviewed main` field (`5020df4b88a2`) was stale. The actual landed target was verified as `ebf737b5111b7efa6db5e6ceaa6f50da44f0fee4` with parent `97262b6e8`; review scope used that exact commit.
- The implementation summary reports the broad changed-file sweep's `review_pairing_contract` failure reproduces on unchanged main. This review did not rerun that unrelated broad sweep; all four packet-required focused checks passed.

## Follow-up

Created `vehicle-wreck-restoration-foundation-v1-review-corrections-1` and its paired fresh review packet. The correction task is ready but dependency-gated on this review closing. Runtime implementation remains untouched in this review workstream.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b

## Next Handoff

- Next workstream: `vehicle-wreck-restoration-foundation-v1-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `none`
- Next action: Implement R0-01, then complete its paired review before claiming the Scout class recovery.
- Blockers or open questions: `Interact release must cancel the restoration hold without spending resources.`
