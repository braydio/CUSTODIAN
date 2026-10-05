# CONTRACT WORLD RELAY PLACEMENT EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `contract-world-relay-placement-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `review-contract-world-placement-foundation-r1-r1`
- Locks: `contract-world-loader`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `76dac8bf6c`
- Goal: Move ARRN relay tile selection and placement from ContractWorldLoader into the world-placement layer.
- Completion boundary: Done when relay candidate picking, spacing/sector semantics, and node placement are service-owned while ARRN state/simulation remains ARRN-owned.
- Current measured state: ARRN relay positioning is still loader-owned in `custodian/game/systems/core/systems/contract_world_loader.gd` through `_position_arrn_relays` and `_pick_arrn_relay_tile`; ARRN simulation/state remains under `custodian/game/systems/core/systems/arrn/`. `custodian/game/world/placement/` contains the landed read-only `WorldPlacementContext` foundation but no relay service yet.
- Evidence: `custodian/game/systems/core/systems/contract_world_loader.gd`; `custodian/game/systems/core/systems/arrn/`; `custodian/game/world/placement/README.md`; `custodian/tools/validation/world_contract_prewarm_smoke.gd`; P1 placement-context contract.
- Task-specific authority: world placement README; ARRN current runtime ownership; placement context.
- Work surface: `custodian/game/world/placement/relay_placement_service.gd` (or clearly equivalent placement-package file), loader delegation, existing ARRN runtime owner untouched, placement README/index, and focused relay placement validation.
- Change: Extract deterministic relay placement policy and any relay-only candidate logic. Service receives current relay nodes/config plus placement context; it must not own ARRN stabilization/state/tick logic.
- Preserve: Relay count/identity, fixed-seed positions, sector/clearance constraints, ARRN state initialization.
- Non-goals: No ARRN redesign, benefit/tick tuning, asset changes, or generation changes.
- Acceptance: Existing relay placements and state handoff match pre-extraction fixed-seed results; loader contains only service invocation for relay positioning.
- Validation: `res://tools/validation/world_contract_prewarm_smoke.gd` plus the current ARRN-focused validation selected by `custodian/tools/validation/validation_manifest.json`; add a deterministic relay-placement snapshot inside this workstream if exact position parity is otherwise unproved; then changed-file closeout.
- Task overrides: `none`
- Deferred: Other placement domains and loader contraction.
- Foundation gate: Do not claim until PR1 recovery review `review-contract-world-placement-foundation-r1-r1` passes. At claim time, re-read the reviewed placement-context API and refresh this packet in place first if any work-surface/API assumption no longer matches the landed foundation.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Finish normally; loader contraction waits for all placement-domain dependents.
- Best starting files: _position_arrn_relays, _pick_arrn_relay_tile, ARRN runtime tests, placement context.
- Blockers or open questions: None known at authoring time.