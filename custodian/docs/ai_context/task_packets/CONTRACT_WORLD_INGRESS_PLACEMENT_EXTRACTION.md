# CONTRACT WORLD INGRESS PLACEMENT EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `contract-world-ingress-placement-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `contract-world-placement-foundation`
- Locks: `contract-world-loader`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Move authored world-ingress/destination placement from ContractWorldLoader into the canonical world-placement layer while preserving transition ownership elsewhere.
- Completion boundary: Done when registered ingresses, Sundered Keep connection/frontage placement, ingress-adjacent spawn/edge projection, and related dressing-clearance placement policy are service-owned; loader delegates and transition systems still own entry/return behavior.
- Current measured state: Loader owns _place_gothic_compound_connection, _place_sundered_keep_connection, _place_registered_world_ingresses, vista/gateway debug placement, _project_ingress_to_edge, _pick_ingress_adjacent_spawn_tile and ingress direction helpers.
- Evidence: sundered_keep_ingress_smoke.gd; world ingress spawner/resolver; WORLD_TRANSITION_SYSTEM.md; placement README.
- Task-specific authority: world placement README; WorldIngressSpawner/placement resolver; world transition system; placement context.
- Work surface: world/placement/authored_ingress_placement_service.gd or equivalent, loader delegation, ingress/frontage tests.
- Change: Extract where/how ingresses are placed and registered on accepted procgen worlds. Continue using current ingress resolver/spawner authorities rather than cloning them. Transition, return-guard, fade, and authored-level lifecycle remain outside this service.
- Preserve: Fixed-seed ingress positions, frontage/clearance claims, Sundered Keep access/return behavior, debug gateway semantics.
- Non-goals: No new destinations, Hub/Twin routing, transition-manager redesign, or authored-level gameplay changes.
- Acceptance: Ingress/frontage smokes and fixed-seed placement match before extraction; loader no longer owns destination placement policy beyond service invocation.
- Validation: sundered_keep_ingress + procgen frontage/world ingress smokes + population placement + changed-file closeout.
- Task overrides: `none`
- Deferred: Other placement domains and final loader contraction.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Finish normally; loader contraction waits for all placement-domain dependents.
- Best starting files: ContractWorldLoader ingress helpers; WorldIngressSpawner/resolver; Sundered Keep ingress/frontage tests.
- Blockers or open questions: None known at authoring time.
