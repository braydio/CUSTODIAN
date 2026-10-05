# CONTRACT WORLD RESOURCE PLACEMENT EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `contract-world-resource-placement-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `review-contract-world-placement-foundation-r1`
- Locks: `contract-world-loader`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `76dac8bf6c`
- Goal: Move tutorial and expedition resource-node placement policy out of ContractWorldLoader into one deterministic placement service.
- Completion boundary: Done when resource candidate building, scoring, spacing, presets, instantiation/positioning, and placement telemetry are service-owned; loader only invokes the service through the placement context.
- Current measured state: Resource placement is still entirely live in `custodian/game/systems/core/systems/contract_world_loader.gd`: `_position_tutorial_resource_nodes`, `_position_expedition_resource_nodes`, `_instantiate_generated_resource_node`, tutorial/expedition candidate builders, fallback eligibility, stable score/pickers, spacing, preset tables, preset application, and excluded-region checks. `custodian/game/world/placement/` contains the landed read-only `WorldPlacementContext` foundation but no resource placement service yet.
- Evidence: `custodian/game/systems/core/systems/contract_world_loader.gd`; `custodian/game/world/placement/README.md`; `custodian/tools/validation/contract_resource_node_smoke.gd`; `custodian/tools/validation/contract_world_population_placement_smoke.gd`; P1 placement-context contract.
- Task-specific authority: world placement README; resource-node current behavior; placement foundation.
- Work surface: `custodian/game/world/placement/resource_placement_service.gd` (or a clearly equivalent resource-domain file inside that existing directory), `custodian/game/systems/core/systems/contract_world_loader.gd` delegation only, `custodian/game/world/placement/README.md`, and focused resource-placement validation.
- Change: Extract current resource placement as-is, preserving stable score/tie semantics and tutorial/expedition separation. Service requests placement through context and emits the same observability payloads; it does not own map generation or inventory/resource-node simulation.
- Preserve: Exact fixed-seed positions/presets/counts, spawn/compound clearances, current missing-candidate fallback behavior.
- Non-goals: No resource-economy redesign, node art changes, extraction loop, or power/logistics changes.
- Acceptance: Fixed-seed resource placement snapshots equal pre-extraction results and loader contains no resource-domain candidate/scoring policy beyond service invocation.
- Validation: `res://tools/validation/contract_resource_node_smoke.gd` first, then `res://tools/validation/contract_world_population_placement_smoke.gd`, `res://tools/validation/world_contract_prewarm_smoke.gd`, any implementation-created resource service snapshot/unit smoke after it exists, and changed-file closeout.
- Task overrides: `none`
- Deferred: Other placement domains remain independent packets.
- Foundation gate: Do not claim until PR1 recovery review `review-contract-world-placement-foundation-r1` passes. At claim time, re-read the reviewed placement-context API and refresh this packet in place first if any work-surface/API assumption no longer matches the landed foundation.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Finish normally; loader contraction waits for all placement-domain dependents.
- Best starting files: ContractWorldLoader resource helpers; resource placement smokes; placement context.
- Blockers or open questions: None known at authoring time.