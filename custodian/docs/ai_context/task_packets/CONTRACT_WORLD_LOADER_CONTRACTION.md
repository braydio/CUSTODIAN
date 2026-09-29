# CONTRACT WORLD LOADER CONTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `contract-world-loader-contraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `contract-world-resource-placement-extraction, contract-world-vehicle-placement-extraction, contract-world-relay-placement-extraction, contract-world-encounter-placement-extraction, contract-world-ingress-placement-extraction`
- Locks: `contract-world-loader`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Collapse ContractWorldLoader back to world attach/rebind/activation orchestration after all placement domains have migrated.
- Completion boundary: Done when loader owns accepted-map attach, Operator/spawn/static-sector positioning, camera/navigation/UI rebind, service invocation, activation/failure cleanup, and no duplicated domain placement policy remains.
- Current measured state: Five placement domains have moved to world/placement, but loader still contains migration adapters/obsolete helpers and may retain duplicated policy unless explicitly demolished.
- Evidence: All placement service summaries/tests; S1 baseline; loader function inventory.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; world placement README; RUNTIME_WORLD_AND_CAMERA_STABILIZATION.md; world transition contract.
- Work surface: ContractWorldLoader cleanup, world placement README/docs, validation ownership and loader lifecycle tests.
- Change: Delete zero-consumer migrated helpers, centralize service construction/invocation order, keep lifecycle operations explicit, and document the final loader API. Do not move lifecycle code merely to hit a line target. Update architecture coordinator size/current ownership truth.
- Preserve: Map attach, static sectors, Operator/spawn, camera, navigation, UI/world anchors, failure recovery and service ordering.
- Non-goals: No new WorldTransitionManager, no gameplay-placement retune, no procgen generation changes.
- Acceptance: All placement regressions green; loader has zero domain-specific candidate/scoring helpers for migrated services; architecture docs identify placement services as owners; fixed-seed world startup unchanged.
- Validation: World loader/population/ingress/resource/vehicle/relay/ambient focused suite + startup world/contract handoff where selected + changed-file closeout.
- Task overrides: `none`
- Deferred: Rendering/node-load work waits for ProcGenTilemap contraction as well.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Placement lane closes; procgen-render-attribution-v1 waits for this and ProcGenTilemap facade contraction.
- Best starting files: ContractWorldLoader; world/placement services; architecture ownership docs.
- Blockers or open questions: None known at authoring time.
