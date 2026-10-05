# CONTRACT WORLD INGRESS PLACEMENT EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `contract-world-ingress-placement-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `review-contract-world-placement-foundation-r1-r1`
- Locks: `contract-world-loader`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `76dac8bf6c`
- Goal: Move authored world-ingress/destination placement from ContractWorldLoader into the canonical world-placement layer while preserving transition ownership elsewhere.
- Completion boundary: Done when registered ingresses, Sundered Keep connection/frontage placement, ingress-adjacent spawn/edge projection, and related dressing-clearance placement policy are service-owned; loader delegates and transition systems still own entry/return behavior.
- Current measured state: Authored ingress/destination placement is still split between loader policy and focused ingress authorities. `custodian/game/systems/core/systems/contract_world_loader.gd` owns `_place_gothic_compound_connection`, `_place_sundered_keep_connection`, `_place_registered_world_ingresses`, Sundered Keep vista/debug gateway placement, gate-tile pickers, `_project_ingress_to_edge`, `_pick_ingress_adjacent_spawn_tile`, and compound-ingress direction/offset helpers. Canonical ingress spawning/validation already exists at `custodian/game/world/levels/world_ingress_spawner.gd`, with procgen ingress-site data under `custodian/game/world/procgen/ingress/world_ingress_site.gd`. `custodian/game/world/placement/` contains the landed read-only `WorldPlacementContext` foundation but no authored-ingress placement service yet.
- Evidence: live `custodian/game/systems/core/systems/contract_world_loader.gd`; `custodian/game/world/levels/world_ingress_spawner.gd`; `custodian/game/world/procgen/ingress/world_ingress_site.gd`; `custodian/tools/validation/sundered_keep_ingress_smoke.gd`; `custodian/tools/validation/world_ingress_spawner_smoke.gd`; `custodian/tools/validation/world_ingress_physics_reentry_smoke.gd`; `custodian/tools/validation/authored_level_ingress_return_smoke.gd`; P1 placement context.
- Task-specific authority: `custodian/game/world/placement/README.md`; `custodian/game/world/levels/world_ingress_spawner.gd`; `custodian/game/world/procgen/ingress/world_ingress_site.gd`; current world transition/return contract; P1 placement context.
- Work surface: `custodian/game/world/placement/authored_ingress_placement_service.gd` (or clearly equivalent placement-package file), loader delegation in `custodian/game/systems/core/systems/contract_world_loader.gd`, reuse of existing `world_ingress_spawner.gd` and `world_ingress_site.gd` rather than cloning them, placement README/index, and focused ingress/frontage/return tests.
- Change: Extract where/how ingresses are placed and registered on accepted procgen worlds. Continue using current ingress resolver/spawner authorities rather than cloning them. Transition, return-guard, fade, and authored-level lifecycle remain outside this service.
- Preserve: Fixed-seed ingress positions, frontage/clearance claims, Sundered Keep access/return behavior, debug gateway semantics, and the passed P0 ingress-spawn-clearance contract: registered structural ingresses and their canonical dressing-clearance claims are committed before static-sector/Operator placement, and both compound-candidate and `player_spawn` fallback selection reject ingress-clearance overlap.
- Non-goals: No new destinations, Hub/Twin routing, transition-manager redesign, or authored-level gameplay changes.
- Acceptance: Ingress/frontage smokes and fixed-seed placement match before extraction; `contract_world_ingress_spawn_clearance_smoke.gd` remains green and proves the extraction preserves registered-ingress-before-Operator ordering plus safe compound/fallback spawn selection; loader no longer owns destination placement policy beyond service invocation.
- Validation: Start with `res://tools/validation/contract_world_ingress_spawn_clearance_smoke.gd`, then `res://tools/validation/sundered_keep_ingress_smoke.gd`, `res://tools/validation/world_ingress_spawner_smoke.gd`, `res://tools/validation/world_ingress_physics_reentry_smoke.gd`, `res://tools/validation/authored_level_ingress_return_smoke.gd`, `res://tools/validation/world_contract_prewarm_smoke.gd`, then changed-file closeout. The recorded seed-0 Threadway sweep failure and `procgen_stuck_pocket_smoke.gd` failure are baseline/out-of-scope unless this extraction changes their owner paths.
- Task overrides: `none`
- Deferred: Other placement domains and final loader contraction.
- Foundation gate: Do not claim until PR1 recovery review `review-contract-world-placement-foundation-r1-r1` passes. At claim time, re-read the reviewed placement-context API and refresh this packet in place first if any work-surface/API assumption no longer matches the landed foundation.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Finish normally; loader contraction waits for all placement-domain dependents.
- Best starting files: ContractWorldLoader ingress helpers; WorldIngressSpawner/resolver; Sundered Keep ingress/frontage tests.
- Blockers or open questions: None known at authoring time.
## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search`
- Refresh instruction: After PR1 recovery review passes, bring its final context API and any placement-owner corrections back to this chat before changing this packet's service boundary. Preserve the already-passed ingress-spawn-clearance ordering contract.
