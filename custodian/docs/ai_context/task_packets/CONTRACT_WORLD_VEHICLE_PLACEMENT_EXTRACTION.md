# CONTRACT WORLD VEHICLE PLACEMENT EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `contract-world-vehicle-placement-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `review-contract-world-placement-foundation`
- Locks: `contract-world-loader`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `f7e84ae48a90ff9da0f968ef0c72ac9ba0c2c5ee`
- Goal: Move generated-world vehicle placement policy from ContractWorldLoader into a focused deterministic placement service.
- Completion boundary: Done when vehicle tile selection, positioning, scale/orientation/application, and fixed-seed placement results are service-owned and loader delegates through placement context.
- Current measured state: Generated-world vehicle placement is still owned by `custodian/game/systems/core/systems/contract_world_loader.gd` through `_position_vehicles`, `_position_vehicle_nodes_on_tiles`, `_get_parking_zone_tiles`, canonical tile/world transforms, and loader placement order. `custodian/game/world/placement/` remains scaffold-only; existing validation exercises world-loader flags/boot and vehicle runtime behavior but there is no dedicated extracted-service file yet.
- Evidence: `custodian/game/systems/core/systems/contract_world_loader.gd`; `custodian/game/world/placement/README.md`; `custodian/tools/validation/world_contract_prewarm_smoke.gd`; `custodian/tools/validation/vehicle_exit_clearance_smoke.gd`; `custodian/tools/validation/validate_vehicle_registry.gd`; P1 placement-context contract.
- Task-specific authority: world placement README; active vehicle runtime placement contract.
- Work surface: `custodian/game/world/placement/vehicle_placement_service.gd` (or clearly equivalent file in the placement package), loader delegation in `custodian/game/systems/core/systems/contract_world_loader.gd`, placement README/index, and a focused deterministic placement snapshot created in this workstream if existing boot coverage cannot prove exact locations.
- Change: Extract current vehicle placement without tuning counts/locations. Reuse placement-context walkability/region helpers and preserve deterministic node order. Vehicle simulation remains vehicle-owned after placement.
- Preserve: Spawn clearances, exact fixed-seed positions where tests assert them, vehicle identities/configuration, world attach order.
- Non-goals: No vehicle gameplay changes, controller work, new vehicles, or map-generation changes.
- Acceptance: Before/after fixed-seed placement snapshot matches; loader no longer owns vehicle-domain selection policy.
- Validation: `res://tools/validation/world_contract_prewarm_smoke.gd`, `res://tools/validation/vehicle_exit_clearance_smoke.gd`, `res://tools/validation/validate_vehicle_registry.gd`, plus an implementation-created fixed-seed vehicle-placement snapshot if required; then changed-file closeout. Do not name a nonexistent new script in packet metadata before claim.
- Task overrides: `none`
- Deferred: Remaining placement domains and final loader contraction.
- Foundation gate: Do not claim until PR1 `review-contract-world-placement-foundation` passes. At claim time, re-read the reviewed placement-context API and refresh this packet in place first if any work-surface/API assumption no longer matches the landed foundation.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Finish normally; loader contraction waits for all placement-domain dependents.
- Best starting files: _position_vehicles, _position_vehicle_nodes_on_tiles, vehicle placement tests, placement context.
- Blockers or open questions: None known at authoring time.
