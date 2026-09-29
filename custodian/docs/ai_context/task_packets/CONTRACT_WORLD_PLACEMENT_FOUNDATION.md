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
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Create the shared world-placement context/service seam so resource, vehicle, relay, encounter, and authored-ingress placement can leave ContractWorldLoader without duplicating map/anchor queries.
- Completion boundary: Done when one immutable/read-only placement context exposes the accepted map, level data, spawn/compound/region helpers, stable seed/scoring utilities, and observability hook needed by placement domains; no domain is moved yet.
- Current measured state: game/world/placement/README.md is scaffold-only while the 2,001-line ContractWorldLoader owns map attach plus every placement domain and repeated tile/region helper logic.
- Evidence: ContractWorldLoader placement functions; contract_world_population_placement_smoke.gd; world placement README; S1 baseline.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; game/world/placement/README.md; ContractWorldLoader lifecycle contract.
- Work surface: game/world/placement/ foundation context/interface plus narrow ContractWorldLoader construction/adaptation and tests.
- Change: Define one placement context passed to focused services. It may expose read-only map/level-data references and deterministic helper APIs, but must not become a second world loader or own generation. Centralize only truly shared placement utilities proven used by multiple domains; leave domain policy in loader until its extraction packet.
- Preserve: All current placement positions/order, world attach/rebind, camera/nav/operator positioning, Observatory event semantics.
- Non-goals: No resource/vehicle/relay/enemy/ingress policy move yet; no world-transition manager; no generation changes.
- Acceptance: Existing placement smokes remain bit/position equivalent; loader can construct one context and domain functions can optionally consume it without output changes; no duplicate source of map/world lifecycle truth.
- Validation: Placement foundation smoke + contract world population/ingress representative tests + S1 quick; changed-file closeout.
- Task overrides: `none`
- Deferred: Five independent domain extractions then loader contraction.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Land foundation; resource, vehicle, relay, encounter, and ingress extraction packets become eligible subject to the shared loader lock.
- Best starting files: contract_world_loader.gd; game/world/placement/README.md; population/ingress placement smokes.
- Blockers or open questions: None known at authoring time.
