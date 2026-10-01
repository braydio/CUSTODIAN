# CONTRACT WORLD PLACEMENT FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `contract-world-placement-foundation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `procgen-performance-baseline-v1`
- Locks: `contract-world-loader`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `7913903704aee8fdd2c645891df441fa31fb6cca`
- Goal: Create the shared world-placement context/service seam so resource, vehicle, relay, encounter, and authored-ingress placement can leave ContractWorldLoader without duplicating map/anchor queries.
- Completion boundary: Done when one immutable/read-only placement context exposes the accepted map, level data, spawn/compound/region helpers, stable seed/scoring utilities, and observability hook needed by placement domains; no domain is moved yet.
- Current measured state: `custodian/game/world/placement/README.md` is still scaffold-only. Live placement authority remains `custodian/game/systems/core/systems/contract_world_loader.gd` at 2,001 lines / 98 functions. The loader still owns resource placement (`_position_tutorial_resource_nodes`, `_position_expedition_resource_nodes` and their candidate/score/preset helpers), vehicle placement (`_position_vehicles`, `_position_vehicle_nodes_on_tiles`), ARRN relay placement (`_position_arrn_relays`, `_pick_arrn_relay_tile`), encounter/ambient/Vaultwing marker placement, authored ingress/destination placement, plus generic world attach/rebind/activation. `contract_world_population_placement_smoke.gd` already proves semantic population-anchor transforms but deliberately disables the domain placements, so it is a useful foundation regression rather than evidence those domains are extracted.
- Evidence: `custodian/game/world/placement/README.md`; `custodian/game/systems/core/systems/contract_world_loader.gd`; `custodian/tools/validation/contract_world_population_placement_smoke.gd`; `custodian/tools/validation/contract_resource_node_smoke.gd`; `custodian/tools/validation/world_ingress_spawner_smoke.gd`; `custodian/tools/validation/world_contract_prewarm_smoke.gd`; `custodian/tools/validation/startup_world_entry_smoke.gd`; S1 baseline.
- Task-specific authority: `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`; `custodian/game/world/placement/README.md`; live `custodian/game/systems/core/systems/contract_world_loader.gd`; current world lifecycle/transition contracts.
- Work surface: Create the shared read-only placement context/interface under the existing scaffold `custodian/game/world/placement/` (prefer `world_placement_context.gd` unless implementation evidence establishes a better repository-conventional name), with only narrow construction/adaptation in `custodian/game/systems/core/systems/contract_world_loader.gd`. Update `custodian/game/world/placement/README.md` and `custodian/docs/ai_context/FILE_INDEX.md` when ownership becomes real. Do not move a domain policy in P1.
- Change: Define one placement context passed to focused services. It may expose read-only map/level-data references and deterministic helper APIs, but must not become a second world loader or own generation. Centralize only truly shared placement utilities proven used by multiple domains; leave domain policy in loader until its extraction packet.
- Preserve: All current placement positions/order, world attach/rebind, camera/nav/operator positioning, Observatory event semantics.
- Non-goals: No resource/vehicle/relay/enemy/ingress policy move yet; no world-transition manager; no generation changes.
- Acceptance: Existing placement smokes remain bit/position equivalent; loader can construct one context and domain functions can optionally consume it without output changes; no duplicate source of map/world lifecycle truth.
- Validation: Run existing `res://tools/validation/contract_world_population_placement_smoke.gd`, `res://tools/validation/contract_resource_node_smoke.gd`, `res://tools/validation/world_ingress_spawner_smoke.gd`, `res://tools/validation/world_contract_prewarm_smoke.gd`, and `res://tools/validation/startup_world_entry_smoke.gd` as directly affected regressions plus S1 quick and changed-file closeout. A new focused context smoke may be created during implementation, but do not put a not-yet-existing literal validation path into this ready packet before the dispatcher claim.
- Task overrides: `none`
- Deferred: Five independent domain extractions then loader contraction.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Land foundation; resource, vehicle, relay, encounter, and ingress extraction packets become eligible subject to the shared loader lock.
- Best starting files: contract_world_loader.gd; game/world/placement/README.md; population/ingress placement smokes.
- Blockers or open questions: None known at authoring time.
