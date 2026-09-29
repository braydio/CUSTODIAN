# CONTRACT WORLD VEHICLE PLACEMENT EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `contract-world-vehicle-placement-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `contract-world-placement-foundation`
- Locks: `contract-world-loader`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Move generated-world vehicle placement policy from ContractWorldLoader into a focused deterministic placement service.
- Completion boundary: Done when vehicle tile selection, positioning, scale/orientation/application, and fixed-seed placement results are service-owned and loader delegates through placement context.
- Current measured state: ContractWorldLoader owns _position_vehicles and _position_vehicle_nodes_on_tiles alongside generic world handoff.
- Evidence: live vehicle placement functions; vehicle/runtime placement tests selected by validation manifest; placement context.
- Task-specific authority: world placement README; active vehicle runtime placement contract.
- Work surface: game/world/placement/vehicle_placement_service.gd or equivalent, loader adapter, focused placement test.
- Change: Extract current vehicle placement without tuning counts/locations. Reuse placement-context walkability/region helpers and preserve deterministic node order. Vehicle simulation remains vehicle-owned after placement.
- Preserve: Spawn clearances, exact fixed-seed positions where tests assert them, vehicle identities/configuration, world attach order.
- Non-goals: No vehicle gameplay changes, controller work, new vehicles, or map-generation changes.
- Acceptance: Before/after fixed-seed placement snapshot matches; loader no longer owns vehicle-domain selection policy.
- Validation: Focused vehicle placement smoke + contract population/world loader smokes + changed-file closeout.
- Task overrides: `none`
- Deferred: Remaining placement domains and final loader contraction.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Finish normally; loader contraction waits for all placement-domain dependents.
- Best starting files: _position_vehicles, _position_vehicle_nodes_on_tiles, vehicle placement tests, placement context.
- Blockers or open questions: None known at authoring time.
