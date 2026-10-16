# REVIEW CARROW INTERIOR SCALE CALIBRATION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-carrow-interior-scale-calibration-v1`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `carrow-interior-scale-calibration-v1`
- Locks: `carrow-yard-route`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review target workstream: `carrow-interior-scale-calibration-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/CARROW_INTERIOR_SCALE_CALIBRATION_V1.md`
- Reviewed main: `200fb5ba3`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc3bfd-cf88-83ea-9156-be4e5c2851c0`
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Goal: Independently prove that three exact native-scale Carrow debug variants are reproducible, technically correct and cannot change the live three-interior runtime.
- Reviewed implementation acceptance: `A1-A6` of archived `CARROW_INTERIOR_SCALE_CALIBRATION_V1.md`; objective size/geometry/control/camera/resource evidence only.
- Review evidence: Pinned implementation SHA, screenshot viewport metadata for 9 images, three fixture JSONs plus numeric-only comparison JSON, check of actual Operator collision/camera data, explicit base-vs-landed runtime hash/diff, focused preexisting Carrow regression tests, new negative fixture cases inside the fixture smoke, AI-context validation and clean diff checks. Changed-file selection was empty because the review only touched excluded documentation.
- Correction threshold: Wrong dimensions/floor count, altered scale/viewport, wrong collision shape, invalid doorway/aisle, missing registered asset or storage, unstaged room mutation, stale evidence, false test pass or main route/production change is blocking; aesthetics are not a technical failure.
- Focused validation: Rerun new authored debug fixture tests plus existing `custodian/tools/validation/carrow_yard_interior_smoke.gd`, `custodian/tools/validation/carrow_operations_house_interior_smoke.gd`, `custodian/tools/validation/carrow_backdrop_isolation_smoke.gd`, and the applicable West/generator fixture discovered in live tree. Compare screenshot numeric metadata, verify nine 768×576 captures, unchanged production files, then changed-file routed suite and `git diff --check`. No subjective size judgments.
- Review focus: Stable per-scene config isolation, real Operator/camera source, 4-cell door, geometry/physical clearance, strict fixed art anchors, no duplicate Operator/room router, JSON provenance and same-input output repeatability.
- Acceptance: Fresh-context findings-first independent code/runtime review. A valid PASS proves only technical readiness of the three scenes for the user's hands-on size evaluation, **not** that any candidate is appealing, modern or chosen for production. Record IDs for real defects; never select a winning size.
- Non-goals: Modify reviewed implementation, resize production room, approve new art, alter Carrow's route migration, implement Gatehouse/Gantry, or make a design preference recommendation.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Pin exact target implementation and current source fixtures; review both code and launched native-viewport scenes.
2. Verify numeric metadata and every declared collision/waypoint region against actual runtime; no graph-paper-only PASS.
3. Prove unchanged East/West/Operations production file hashes and passes for all existing focused Carrow regressions.
4. Publish the three debug entrypoints and evidence identifiers back to the supplied authoring chat without deciding the human scale gate.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Evidence: `Fresh-context review reconstructed the implementation from the archived packet, landed source, generated reports and direct validation. The new fixture smoke passed 1/1; existing Carrow yard (including West), Operations House and backdrop isolation regressions passed. Nine independently regenerated captures were exactly 768x576 and matched three passing geometry reports and the numeric comparison. The production map and door authorities were byte-identical to the pinned base, and no production Carrow files were changed. No blocking findings, material evidence gaps, non-blocking issues or optional improvements remain.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `Fresh worktree required a first editor import; Godot emitted three unrelated untracked UID cache files, which were removed after validation.`
- Root cause / contributing factors: `The review worktree started without an imported Godot project cache.`
- Prevention / pipeline improvement: `No change required; first import was isolated and generated files were explicitly classified.`
- Tooling / docs drift discovered: `none`
- Follow-up: `none`
- What worked: `Pinned base comparisons, independent fixture smoke, actual renderer output, and existing named regressions provided separate checks for source boundaries, scene data, and runtime behavior.`

## Next Handoff

- Next workstream: `none`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc3bfd-cf88-83ea-9156-be4e5c2851c0`
- Refresh reason: `The user must choose a production Machine House size after trying the three fixed candidates, or request more candidates.`
- Next action: `Launch the 24x18, 30x22 and 36x26 debug scenes listed in the implementation summary; report the selected size (or requested additional variants) in the authoring chat.`
- Blockers or open questions: `Human-owned production size decision; no technical review blockers.`
