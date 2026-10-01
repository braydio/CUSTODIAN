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
- Reviewed main: `7913903704aee8fdd2c645891df441fa31fb6cca`
- Goal: Move authored world-ingress/destination placement from ContractWorldLoader into the canonical world-placement layer while preserving transition ownership elsewhere.
- Completion boundary: Done when registered ingresses, Sundered Keep connection/frontage placement, ingress-adjacent spawn/edge projection, and related dressing-clearance placement policy are service-owned; loader delegates and transition systems still own entry/return behavior.
- Current measured state: Authored ingress/destination placement is still split between loader policy and focused ingress authorities. `custodian/game/systems/core/systems/contract_world_loader.gd` owns `_place_gothic_compound_connection`, `_place_sundered_keep_connection`, `_place_registered_world_ingresses`, Sundered Keep vista/debug gateway placement, gate-tile pickers, `_project_ingress_to_edge`, `_pick_ingress_adjacent_spawn_tile`, and compound-ingress direction/offset helpers. Canonical ingress spawning/validation already exists at `custodian/game/world/levels/world_ingress_spawner.gd`, with procgen ingress-site data under `custodian/game/world/procgen/ingress/world_ingress_site.gd`. `custodian/game/world/placement/` is still scaffold-only.
- Evidence: live `custodian/game/systems/core/systems/contract_world_loader.gd`; `custodian/game/world/levels/world_ingress_spawner.gd`; `custodian/game/world/procgen/ingress/world_ingress_site.gd`; `custodian/tools/validation/sundered_keep_ingress_smoke.gd`; `custodian/tools/validation/world_ingress_spawner_smoke.gd`; `custodian/tools/validation/world_ingress_physics_reentry_smoke.gd`; `custodian/tools/validation/authored_level_ingress_return_smoke.gd`; P1 placement context.
- Task-specific authority: `custodian/game/world/placement/README.md`; `custodian/game/world/levels/world_ingress_spawner.gd`; `custodian/game/world/procgen/ingress/world_ingress_site.gd`; current world transition/return contract; P1 placement context.
- Work surface: `custodian/game/world/placement/authored_ingress_placement_service.gd` (or clearly equivalent placement-package file), loader delegation in `custodian/game/systems/core/systems/contract_world_loader.gd`, reuse of existing `world_ingress_spawner.gd` and `world_ingress_site.gd` rather than cloning them, placement README/index, and focused ingress/frontage/return tests.
- Change: Extract where/how ingresses are placed and registered on accepted procgen worlds. Continue using current ingress resolver/spawner authorities rather than cloning them. Transition, return-guard, fade, and authored-level lifecycle remain outside this service.
- Preserve: Fixed-seed ingress positions, frontage/clearance claims, Sundered Keep access/return behavior, debug gateway semantics.
- Non-goals: No new destinations, Hub/Twin routing, transition-manager redesign, or authored-level gameplay changes.
- Acceptance: Ingress/frontage smokes and fixed-seed placement match before extraction; loader no longer owns destination placement policy beyond service invocation.
- Validation: `res://tools/validation/sundered_keep_ingress_smoke.gd`, `res://tools/validation/world_ingress_spawner_smoke.gd`, `res://tools/validation/world_ingress_physics_reentry_smoke.gd`, `res://tools/validation/authored_level_ingress_return_smoke.gd`, `res://tools/validation/world_contract_prewarm_smoke.gd`, then changed-file closeout.
- Task overrides: `none`
- Deferred: Other placement domains and final loader contraction.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Finish normally; loader contraction waits for all placement-domain dependents.
- Best starting files: ContractWorldLoader ingress helpers; WorldIngressSpawner/resolver; Sundered Keep ingress/frontage tests.
- Blockers or open questions: None known at authoring time.
