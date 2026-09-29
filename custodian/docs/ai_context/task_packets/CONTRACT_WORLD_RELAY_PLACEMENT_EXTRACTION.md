# CONTRACT WORLD RELAY PLACEMENT EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `contract-world-relay-placement-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `contract-world-placement-foundation`
- Locks: `contract-world-loader`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Move ARRN relay tile selection and placement from ContractWorldLoader into the world-placement layer.
- Completion boundary: Done when relay candidate picking, spacing/sector semantics, and node placement are service-owned while ARRN state/simulation remains ARRN-owned.
- Current measured state: ContractWorldLoader owns _position_arrn_relays and _pick_arrn_relay_tile in the same coordinator as world attach and unrelated placement domains.
- Evidence: ARRN relay runtime/placement tests; loader functions; placement foundation.
- Task-specific authority: world placement README; ARRN current runtime ownership; placement context.
- Work surface: world/placement/relay_placement_service.gd or equivalent, loader delegation, ARRN placement regressions.
- Change: Extract deterministic relay placement policy and any relay-only candidate logic. Service receives current relay nodes/config plus placement context; it must not own ARRN stabilization/state/tick logic.
- Preserve: Relay count/identity, fixed-seed positions, sector/clearance constraints, ARRN state initialization.
- Non-goals: No ARRN redesign, benefit/tick tuning, asset changes, or generation changes.
- Acceptance: Existing relay placements and state handoff match pre-extraction fixed-seed results; loader contains only service invocation for relay positioning.
- Validation: ARRN focused tests + world population placement + service snapshot test + changed-file closeout.
- Task overrides: `none`
- Deferred: Other placement domains and loader contraction.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Finish normally; loader contraction waits for all placement-domain dependents.
- Best starting files: _position_arrn_relays, _pick_arrn_relay_tile, ARRN runtime tests, placement context.
- Blockers or open questions: None known at authoring time.
