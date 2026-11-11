# Contract World Ingress Spawn Clearance Review — Codex Summary

## Review result

Passed with no correction-worthy findings. Independent review confirms the
registered ingress spawner places the real Ash Bell/Ritualant ingress and
commits its canonical dressing-clearance claim before the loader positions
sectors and the Operator. Compound and fallback spawn choices both consult the
existing map clearance authority; the deterministic overlap fixture proves
the old preferred tile intersects real authored collision and that the
replacement remains floor-walkable and clear to a 96px-class capsule query.

`WorldPlacementContext` retains the live map instance and snapshots only level
data, so constructing it before ingress placement does not freeze map geometry.
Camera refresh and navigation rebuild remain after final positioning.

## Validation

- Passed independently: `contract_world_ingress_spawn_clearance`,
  `world_ingress_spawner`, `ash_bell_lift_ingress_presentation`,
  `contract_world_population_placement_smoke.gd`, and
  `camera_presentation_subject_constraint`.
- The bounded one-seed `required_ritualant_ingress_contract_sweep.gd` placed the
  required ingress and passed required-ingress validation/presence, then
  reproduced the previously recorded seed-0 Threadway failures: the approach
  is already reachable before eligibility and the committed plan has zero
  cells. These assertions do not exercise the reviewed loader ordering.
- `procgen_stuck_pocket_smoke.gd` reproduced its existing line-70 assertion
  after reporting one cleared collision owner. Its SceneTree did not quit after
  the assertion, so the review terminated it with a 45-second timeout. The
  path is unchanged by the reviewed commits.
- No renderer evidence was needed; acceptance is collision, map-clearance,
  deterministic selection, and call-order behavior with direct machine
  assertions.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: A concurrent broad validation run occupied the shared
  machine-wide Godot slot initially; the reviewer waited and then ran focused
  checks serially. Two previously recorded ancillary test failures reproduced.
- Root cause / contributing factors: The required-ingress sweep couples
  ingress placement proof with seed-specific Threadway checks and expensive
  full contract generation; the stuck-pocket assertion leaves a headless
  SceneTree alive.
- Prevention / pipeline improvement: Keep spawn-clearance acceptance focused
  and treat the unrelated Threadway/stuck-pocket failures as their own follow-up.
- Tooling / docs drift discovered: none
- Follow-up: manual-follow-up
- What worked: Real presentation collision, canonical clearance claims, and
  focused spawner/Ash Bell tests gave direct evidence without visual recapture.

## Next Handoff

- Next workstream: none
- Next packet state: none
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7
- Refresh reason: none
- Next action: No correction packet is required; the hotfix review passed.
- Blockers or open questions: none
