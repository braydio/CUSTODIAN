# PROCGEN ACCEPTED CANDIDATE MATERIALIZER

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-accepted-candidate-materializer`
- Status: `complete`
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

- Next action: Claim `procgen-candidate-runtime-path-demolition` (G5), now eligible after G4 lands.
- Best starting files: generation/; ProcGenTilemap generate/promote/finalization; CustodianContractMap final map handoff.
- Blockers or open questions: None known at authoring time.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: The S4 final-runtime realization caused the ambient real-world spawn integration test to exceed its 90-second timeout twice, after the test had completed most generation work.
- Root cause / contributing factors: The existing timeout covered evaluation and in-place promotion costs but not evaluation plus a fresh final realization.
- Prevention / pipeline improvement: Raised that single test's timeout to 180 seconds and verified its 106.3-second pass; kept S4 parity checks focused on authoritative topology and final runtime fingerprints.
- Tooling / docs drift discovered: The promotion smoke assumed two distinct maps must have identical streamed-paint counts; fresh materialization correctly starts with its own reveal progress. The focused parity smoke also lacked validation-manifest ownership and was registered before closeout.
- Follow-up: fixed-in-scope
- What worked: Semantic parity and repeated final-runtime fingerprints held across fresh maps.
