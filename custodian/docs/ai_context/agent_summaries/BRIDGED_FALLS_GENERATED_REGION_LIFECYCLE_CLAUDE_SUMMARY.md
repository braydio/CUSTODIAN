# Bridged Falls Generated Region Lifecycle Foundation

Implemented `generated_region` as an additive `LevelDefinition` runtime kind.
The explicit request includes its ProcGen scene, profile ID, seed, dimensions,
room count, and the named route spawns declared by the level. `LevelLoader`
stages a disabled `GeneratedRegionLevel`, awaits `ProcGenTilemap` generation,
and checks the player spawn against the map's canonical main playable component
before the existing route commit transfers authority. Route traversal awaits
this stage for generated destinations, keeps the authored source as authority
until commit, and restores the source activation hooks on rollback.

The adapter owns only its generated map instance, named spawn positions, and a
serialization-safe profile/seed/settings snapshot. The existing procgen map
continues to own generation, walkability, navigation, collision, and streaming.
The focused fixture exercises authored → generated → authored, same-seed
regeneration after `destroy_on_exit`, Operator and shared-camera identity,
single active route authority, and a late missing-spawn rollback. The missing
spawn is the negative control: staging fails after map generation and the
authored source remains active.

## Validation

- `generated_region_route_lifecycle_smoke.gd`: PASS.
- `ash_bell_lower_quarter_route_smoke.gd`: PASS.
- `procgen_intent_graph_smoke.gd`: PASS.
- `route_forward_backtrack_smoke.gd`: PASS.
- `route_transition_rollback_smoke.gd`: PASS; controlled failures are expected.
- `route_registry_contract_smoke.gd`: PASS.
- `route_single_level_wrapper_smoke.gd`: PASS.
- `level_registry_contract_smoke.gd`: PASS.
- `contract_world_playable_region_spawn_validity_smoke.gd`: PASS.
- `sundered_keep_route_graph_smoke.gd`: FAILS at `Front Gate backtrack arrival guard was not armed`. Re-running the same command from the unmodified project-root checkout at `911e8871e` produced the same failure, so it predates this implementation. Other authored route backtrack and rollback smokes pass.
- Code-review graph initialization returned an empty graph and did not complete within the wait window. Exploration continued through the repository-directed `rg` fallback.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: low
- What went wrong: the Sundered Keep route graph smoke has a baseline arrival-guard failure, independently reproduced before the implementation diff.
- Root cause / contributing factors: the exact fixture/runtime disagreement is outside this slice and remains unisolated.
- Prevention / pipeline improvement: carry the baseline reproduction into paired review so it is not misattributed to generated-region staging.
- Tooling / docs drift discovered: the code-review graph was empty and timed out during initialization; `rg` fallback worked.
- Follow-up: manual-follow-up
- What worked: the focused regression proves deterministic staging and rollback without adding generated-region authority to the route manager.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c

## Next Handoff

- Next workstream: review-bridged-falls-generated-region-lifecycle
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Refresh reason: wait for this implementation packet to archive complete on main.
- Next action: run the paired review in a fresh reviewer context.
- Blockers or open questions: the Sundered Keep route graph smoke retains its reproduced baseline arrival-guard failure.
