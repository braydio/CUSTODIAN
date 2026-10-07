# REVIEW: VEHICLE WRECK RESTORATION FOUNDATION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-vehicle-wreck-restoration-foundation-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `vehicle-wreck-restoration-foundation-v1`
- Locks: `none`
- Review: `none`
- Review target workstream: `vehicle-wreck-restoration-foundation-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/VEHICLE_WRECK_RESTORATION_FOUNDATION_V1.md`
- Reviewed main: `5020df4b88a2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently prove that world-spawned pilotable vehicles are genuine recoverable wrecks rather than merely disabled pilotable vehicles, and that restoration/payment/destruction transitions are fail-closed and singular.
- Reviewed implementation acceptance: Verify every Acceptance clause from the archived restoration packet against landed main.
- Review evidence: Archived packet/summary, live registry/runtime/spawn resolver, ResourceLedger state, focused restoration smoke, and fresh hostile interaction probes.
- Correction threshold: Correction only for confirmed acceptance defects or material proof gaps; non-blocking tuning goes next-slice/deferred.
- Focused validation: Re-run the implementation-created wreck-restoration smoke plus registry validation, lifecycle smoke, and exit-clearance smoke.
- Review focus: Initial spawn must not fake a destruction event; wrecks must not leak into pilotable discovery; payment must be exactly-once and post-hold; cancellation must be free; restore must affect the same instance; lethal post-restoration damage must return to recoverable wreckage; direct scene and resolver spawn must agree.
- Acceptance: Publish a findings-first durable review with stable R0-NN IDs. Blocking defects/material evidence gaps create `vehicle-wreck-restoration-foundation-v1-review-corrections-1` plus paired review. Do not patch reviewed runtime.
- Non-goals: No economy retuning, class art judgment, new vehicle types, or implementation fixes.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `vehicle-field-scout-buggy-class-v1-recovery-1 if passed`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `Only landed API/path reconciliation unless review findings invalidate the class contract.`
- Next action: Review restoration independently, then release the Scout class recovery on pass.
- Blockers or open questions: `none`
