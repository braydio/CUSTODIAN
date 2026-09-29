# PROCGEN ACCEPTED CANDIDATE MATERIALIZER

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-accepted-candidate-materializer`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-semantic-candidate-generation`
- Locks: `procgen-generation`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Create one explicit authority that turns the accepted semantic candidate into the production ProcGenTilemap/runtime world exactly once.
- Completion boundary: Done when only the accepted semantic candidate receives structural TileMap realization, final presentation, props/foliage, collision/streaming setup, shadows, and navigation preparation through one materializer seam.
- Current measured state: The accepted candidate is currently a partially realized ProcGenTilemap promoted in place; semantics-first rejected candidates remove the assumption that the winner is already a live near-final map.
- Evidence: S1 promotion timings/fingerprints; semantic candidate model/generator; current promote_evaluated_candidate_to_final behavior and promotion smoke.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; accepted semantic candidate contract; existing terrain/presentation/foliage/runtime authorities.
- Work surface: New generation/materialization authority plus ProcGenTilemap realization entrypoint and CustodianContractMap winner handoff.
- Change: Add a focused materializer that accepts the canonical semantic candidate and creates/applies structural runtime state in deterministic order, then invokes existing final-only presentation, audit, shadow, streaming, collision, and navigation setup once. Preserve current final level-data keys and expose phase timings into the S1 schema.
- Preserve: Final world gameplay fingerprint, floor/wall topology, terrain/roads/regions, props/foliage determinism, spawn/ingress data, runtime collision/nav correctness.
- Non-goals: No renderer batching, pause changes, runtime streaming redesign, or deletion of legacy candidate code yet.
- Acceptance: S1 fixed winners materialize to the same authoritative fingerprints and required counts; candidate loop creates final runtime realization exactly once; promotion/materialization phases are structurally observable.
- Validation: Materializer parity smoke + candidate promotion + spatial/terrain/road/ingress representative smokes + S1 quick/full comparison; changed-file closeout.
- Task overrides: `none`
- Deferred: Legacy live-candidate compatibility path cleanup is the next packet.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` and the matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Land materializer parity; procgen-candidate-runtime-path-demolition then becomes eligible.
- Best starting files: generation/; ProcGenTilemap generate/promote/finalization; CustodianContractMap final map handoff.
- Blockers or open questions: None known at authoring time.
