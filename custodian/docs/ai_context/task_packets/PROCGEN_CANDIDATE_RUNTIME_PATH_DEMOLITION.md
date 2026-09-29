# PROCGEN CANDIDATE RUNTIME PATH DEMOLITION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-candidate-runtime-path-demolition`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-accepted-candidate-materializer`
- Locks: `procgen-generation`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Remove the superseded near-runtime candidate evaluation/promotion path after semantic generation and accepted-candidate materialization are proven canonical.
- Completion boundary: Done when rejected candidates cannot instantiate the retired runtime-evaluation path, obsolete promotion compatibility code is removed, and generation has one semantic-evaluate then materialize-winner authority chain.
- Current measured state: Migration temporarily retains legacy evaluation/promotion seams for parity while S3/S4 land.
- Evidence: S3 semantic parity tests; S4 materializer parity; S1 baseline and post-S4 timings.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; reviewed semantic generator/materializer behavior.
- Work surface: CustodianContractMap, ProcGenTilemap legacy evaluation/promotion branches, generation compatibility adapters, related tests/docs.
- Change: Delete dead duplicate candidate-runtime construction, obsolete evaluation-mode branches that no longer have a live consumer, and compatibility promotion adapters proven unnecessary. Keep diagnostic modes only when they exercise the canonical pipeline rather than reviving the old one.
- Preserve: All accepted-world output, evaluator reasons/scores, benchmark schema, debug reproducibility, and direct production generation entrypoints.
- Non-goals: No road/claim/state extraction yet; no runtime streaming work.
- Acceptance: No production candidate-selection path constructs a live rejected map; one canonical semantic->evaluate->winner->materialize chain remains; S1 fixed cases and materializer tests stay green.
- Validation: Search/authority smoke for retired path + S1 quick + candidate/materializer/determinism suite + changed-file closeout.
- Task overrides: `none`
- Deferred: Generation-lane migration is complete; ProcGenTilemap structural extractions wait for runtime lane convergence.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` and the matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Generation lane closes. Decomplexification packets unlock only after runtime chunk lane also completes.
- Best starting files: CustodianContractMap; ProcGenTilemap generation_evaluation_mode/promote paths; generation/ adapters.
- Blockers or open questions: None known at authoring time.
