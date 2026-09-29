# CONTRACT WORLD RESOURCE PLACEMENT EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `contract-world-resource-placement-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `contract-world-placement-foundation`
- Locks: `contract-world-loader`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Move tutorial and expedition resource-node placement policy out of ContractWorldLoader into one deterministic placement service.
- Completion boundary: Done when resource candidate building, scoring, spacing, presets, instantiation/positioning, and placement telemetry are service-owned; loader only invokes the service through the placement context.
- Current measured state: ContractWorldLoader owns _position_tutorial_resource_nodes, _position_expedition_resource_nodes, candidate builders, stable scoring/pickers, resource spacing, presets, and resource node creation.
- Evidence: contract_resource_node_smoke.gd; EXPEDITION_RESOURCE_PLACEMENT_STEP_1.md; placement foundation.
- Task-specific authority: world placement README; resource-node current behavior; placement foundation.
- Work surface: game/world/placement/resource_placement_service.gd (or equivalent), loader delegation, resource placement tests/manifest.
- Change: Extract current resource placement as-is, preserving stable score/tie semantics and tutorial/expedition separation. Service requests placement through context and emits the same observability payloads; it does not own map generation or inventory/resource-node simulation.
- Preserve: Exact fixed-seed positions/presets/counts, spawn/compound clearances, current missing-candidate fallback behavior.
- Non-goals: No resource-economy redesign, node art changes, extraction loop, or power/logistics changes.
- Acceptance: Fixed-seed resource placement snapshots equal pre-extraction results and loader contains no resource-domain candidate/scoring policy beyond service invocation.
- Validation: contract_resource_node_smoke + population placement smoke + new service unit/snapshot test + changed-file closeout.
- Task overrides: `none`
- Deferred: Other placement domains remain independent packets.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Finish normally; loader contraction waits for all placement-domain dependents.
- Best starting files: ContractWorldLoader resource helpers; resource placement smokes; placement context.
- Blockers or open questions: None known at authoring time.
