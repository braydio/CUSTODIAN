# CONTRACT WORLD LOADER CONTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `contract-world-loader-contraction`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `contract-world-resource-placement-extraction, contract-world-vehicle-placement-extraction, contract-world-relay-placement-extraction, contract-world-encounter-placement-extraction, contract-world-ingress-placement-extraction`
- Locks: `contract-world-loader`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `76dac8bf6c`
- Goal: Collapse ContractWorldLoader back to world attach/rebind/activation orchestration after all placement domains have migrated.
- Completion boundary: REFRESH-GATED. Do not execute contraction from this packet until P2-P6 have landed. At that point, re-audit the live loader and placement package, then rewrite this same packet in place to the exact surviving lifecycle/adapter residue. Done will mean `ContractWorldLoader` owns accepted-map attach/rebind/activation, static/operator/spawn/camera/navigation/UI handoff, ordered placement-service invocation, failure cleanup, and no duplicated domain placement policy.
- Current measured state: P1 `WorldPlacementContext` is landed under `custodian/game/world/placement/`, and the independent P0 ingress-spawn-clearance hotfix/review has passed, establishing registered-ingress-before-Operator ordering plus ingress-clearance-aware compound/fallback spawn selection. P2-P6 domain services have **not** migrated yet, so `ContractWorldLoader` still owns resource, vehicle, relay, encounter/Vaultwing, authored-ingress, and world-lifecycle/orchestration policy together. This packet remains intentionally blocked until all five extraction siblings land and are reviewed as required.
- Evidence: current `custodian/game/world/placement/README.md`; current 2,001-line `custodian/game/systems/core/systems/contract_world_loader.gd`; P1-P6 packet contracts; `custodian/tools/validation/startup_world_entry_smoke.gd`; `custodian/tools/validation/world_contract_prewarm_smoke.gd`; `custodian/tools/validation/contract_world_population_placement_smoke.gd`.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; world placement README; RUNTIME_WORLD_AND_CAMERA_STABILIZATION.md; world transition contract.
- Work surface: Intentionally not frozen while blocked. After P2-P6 land, re-measure `custodian/game/systems/core/systems/contract_world_loader.gd`, inventory actual remaining service adapters/lifecycle methods, update `custodian/game/world/placement/README.md`, `custodian/game/world/lifecycle/README.md` if lifecycle ownership changes, `custodian/docs/ai_context/FILE_INDEX.md`, and exact focused loader tests. Do not move lifecycle code merely to hit a line count.
- Change: None while blocked. Refresh this packet in place from the landed P2-P6 surface. The refreshed contraction must delete zero-consumer migrated helpers, centralize service construction/invocation order, preserve explicit lifecycle/rebind/failure handling, and update ownership docs/tests. No speculative helper deletion before the domain services exist.
- Preserve: Map attach, static sectors, Operator/spawn, camera, navigation, UI/world anchors, failure recovery and service ordering. In particular, preserve the passed ingress-clearance ordering contract: canonical registered ingresses/clearance claims must exist before static-sector and Operator placement, and spawn fallback may not re-enter authored ingress clearance.
- Non-goals: No new WorldTransitionManager, no gameplay-placement retune, no procgen generation changes.
- Acceptance: Not implementation-ready. Before returning to `ready`, the refreshed packet must list the exact surviving loader functions, exact migrated service files, and measurable zero-duplicate-policy checks. Final acceptance must include all placement regressions green, fixed-seed startup unchanged, and no resource/vehicle/relay/encounter/ingress candidate/scoring policy remaining in the loader beyond bounded adapter/orchestration code.
- Validation: Not implementation-ready. Re-derive after P2-P6 using the live service files. Expected closeout set includes `startup_world_entry_smoke.gd`, `world_contract_prewarm_smoke.gd`, `contract_world_population_placement_smoke.gd`, resource/vehicle/relay/ambient/ingress focused tests, and changed-file closeout.
- Task overrides: `none`
- Deferred: Renderer/node-load work still waits for this contraction and ProcGenTilemap contraction to converge.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Placement lane closes; procgen-render-attribution-v1 waits for this and ProcGenTilemap facade contraction.
- Best starting files: ContractWorldLoader; world/placement services; architecture ownership docs.
- Blockers or open questions: None known at authoring time.