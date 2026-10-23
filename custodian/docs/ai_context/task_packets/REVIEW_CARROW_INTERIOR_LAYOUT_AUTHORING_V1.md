# REVIEW CARROW INTERIOR LAYOUT AUTHORING V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-carrow-interior-layout-authoring-v1`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `carrow-interior-layout-authoring-v1`
- Locks: `carrow-yard-route`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review target workstream: `carrow-interior-layout-authoring-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/CARROW_INTERIOR_LAYOUT_AUTHORING_V1.md`
- Reviewed main: `0d51fdba1da51b7cd3af4960b93e2dc6b4066b66`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc3bfd-cf88-83ea-9156-be4e5c2851c0`
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Independently verify the three fixed-size Carrow mapper drafts and no unintended Carrow production geometry changes, not approve gameplay look or the user's layout.
- Reviewed implementation acceptance: `A1-A5` of archived `CARROW_INTERIOR_LAYOUT_AUTHORING_V1.md`.
- Review evidence: Pinned implementation SHA, three editor layout configuration records, round-trip JSON hashes, one actual Operator/camera test per room, negative invalid-floor/missing-asset/overlap/door tests, diff proving `gothic_compound_map.gd` unchanged and all Carrow regressions green.
- Correction threshold: False acceptance of invalid collision/portal/source, unable to author/move/delete sprites or collision, different room dimensions, stale draft data, noncanonical export, tampered production content, invented automatic art placement, or missing runtime evidence blocks PASS. Layout taste is a user gate.
- Focused validation: Rerun new Carrow authoring smoke plus `custodian/tools/validation/carrow_machine_house_scale_calibration_smoke.gd`, `carrow_yard_interior_smoke.gd`, `carrow_operations_house_interior_smoke.gd`, `carrow_backdrop_isolation_smoke.gd`, authored level mapper framework smoke, changed-file route and `git diff --check`. Verify no new production asset registration.
- Acceptance: Findings-first fresh independent technical review; PASS only for working authoring tooling and verified safety. No fabricated receipt, no choosing a room layout or off-map rendering approach.
- Non-goals: Edit implementation, create art, author prop decisions or convert production rooms.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Next Handoff

- Next workstream: `none`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc3bfd-cf88-83ea-9156-be4e5c2851c0`
- Refresh reason: `User needs to author three room layouts and collision, and decide whether to use the off-map method in production after a distinct visual comparison.`
- Next action: Deliver editor launch path and controls to the user; approve exact layout JSON per room before any production Carrow resizing packet.
- Blockers or open questions: `No subjective visual requirement blocks the mapper itself.`
