# CONTRACT WORLD PLACEMENT FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `contract-world-placement-foundation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `procgen-performance-baseline-v1`
- Locks: `contract-world-loader`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-contract-world-placement-foundation`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `735c8c691448ff23cdf9f607e3b7a090379dc162`
- Goal: Create the shared world-placement context/service seam so resource, vehicle, relay, encounter, and authored-ingress placement can leave ContractWorldLoader without duplicating map/anchor queries.
- Completion boundary: Done when one immutable/read-only placement context exposes only the accepted-map/level-data references, spawn/compound/region queries, deterministic seed/scoring primitives, and observability seam that multiple future placement services genuinely need; `ContractWorldLoader` remains world lifecycle/orchestration authority; no resource/vehicle/relay/encounter/ingress domain policy moves in P1; one focused context smoke proves the context cannot become a writable shadow world model; and the paired post-land review passes before any P2-P6 extraction becomes eligible.
- Current measured state: `custodian/game/world/placement/README.md` is still scaffold-only. Live placement authority remains `custodian/game/systems/core/systems/contract_world_loader.gd` at 2,001 lines / 98 functions. The loader still owns resource placement (`_position_tutorial_resource_nodes`, `_position_expedition_resource_nodes` and their candidate/score/preset helpers), vehicle placement (`_position_vehicles`, `_position_vehicle_nodes_on_tiles`), ARRN relay placement (`_position_arrn_relays`, `_pick_arrn_relay_tile`), encounter/ambient/Vaultwing marker placement, authored ingress/destination placement, plus generic world attach/rebind/activation. `contract_world_population_placement_smoke.gd` already proves semantic population-anchor transforms but deliberately disables the domain placements, so it is a useful foundation regression rather than evidence those domains are extracted.
- Evidence: `custodian/game/world/placement/README.md`; `custodian/game/systems/core/systems/contract_world_loader.gd`; `custodian/tools/validation/contract_world_population_placement_smoke.gd`; `custodian/tools/validation/contract_resource_node_smoke.gd`; `custodian/tools/validation/world_ingress_spawner_smoke.gd`; `custodian/tools/validation/world_contract_prewarm_smoke.gd`; `custodian/tools/validation/startup_world_entry_smoke.gd`; S1 baseline.
- Task-specific authority: `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`; `custodian/game/world/placement/README.md`; live `custodian/game/systems/core/systems/contract_world_loader.gd`; current world lifecycle/transition contracts.
- Work surface: Create the shared read-only placement context/interface under the existing scaffold `custodian/game/world/placement/` (prefer `world_placement_context.gd` unless implementation evidence establishes a better repository-conventional name), with only narrow construction/adaptation in `custodian/game/systems/core/systems/contract_world_loader.gd`. Update `custodian/game/world/placement/README.md` and `custodian/docs/ai_context/FILE_INDEX.md` when ownership becomes real. Do not move a domain policy in P1.
- Change: Define one placement context passed to focused services. Prefer plain immutable/copied values and narrow read-only accessors over exposing broad mutable loader/map internals. If a live object reference is unavoidable for a canonical query, expose only the smallest read surface and document why it is safe. Centralize only utilities proven shared by multiple placement domains; do not move scoring, candidate selection, placement order, spawning, transition behavior, or domain-specific presets into the foundation. Loader construction of the context must be deterministic and side-effect-free.
- Preserve: All current placement positions/order, world attach/rebind, camera/nav/operator positioning, Observatory event semantics.
- Non-goals: No resource/vehicle/relay/enemy/ingress policy move yet; no world-transition manager; no generation changes.
- Acceptance: (1) One placement-context owner exists under `custodian/game/world/placement/`; no duplicate loader/world-lifecycle authority is introduced. (2) The context is read-only by contract and implementation: consumers cannot mutate accepted map state, lifecycle state, level-data authority, spawn/compound/region authority, or Observatory ownership through the foundation API. (3) Context construction is deterministic for the same accepted world/level data and has no placement side effects. (4) Shared seed/scoring/query helpers have one implementation and no domain-specific policy leaks into P1. (5) Existing placement positions/order and world attach/rebind/camera/nav/operator behavior remain unchanged. (6) A focused context smoke plus existing population/resource/ingress/prewarm/startup smokes pass. (7) `custodian/game/world/placement/README.md` and `FILE_INDEX.md` describe the real new owner/API. (8) No P2-P6 domain extraction is performed early. (9) Paired review `review-contract-world-placement-foundation` must pass before P2-P6 become eligible.
- Validation: Create and run one focused placement-context smoke in this workstream covering deterministic construction, read-only/no-side-effect behavior, and the minimal shared query/seed surface; register it in `validation_manifest.json` once the path exists. Then run existing `res://tools/validation/contract_world_population_placement_smoke.gd`, `res://tools/validation/contract_resource_node_smoke.gd`, `res://tools/validation/world_ingress_spawner_smoke.gd`, `res://tools/validation/world_contract_prewarm_smoke.gd`, and `res://tools/validation/startup_world_entry_smoke.gd`, plus S1 quick and changed-file closeout. Do not add a nonexistent literal validation path before implementation creates it.
- Task overrides: `none`
- Deferred: Five domain extractions remain P2-P6 and may start only after the paired PR1 review passes; P7 loader contraction remains refresh-gated after those extractions.

## Series Contract

This packet belongs to the `procgen-runtime-optimization-v1` placement lane. On successful implementation, archive/land P1 normally and make `review-contract-world-placement-foundation` eligible. P2-P6 depend on that paired review, not directly on P1. Do not broaden P1 to absorb domain placement policy merely to unblock successors. After PR1 passes, re-check P2-P6 against the reviewed context API before execution; refresh a downstream packet in place if the landed API materially changes its assumptions.

## Handoff

- Next action: Claim and land the foundation, then run `review-contract-world-placement-foundation`. Only a passed PR1 review unlocks resource, vehicle, relay, encounter, and ingress extraction packets, still serialized by the shared `contract-world-loader` lock.
- Best starting files: contract_world_loader.gd; game/world/placement/README.md; population/ingress placement smokes.
- Blockers or open questions: None known at authoring time.
