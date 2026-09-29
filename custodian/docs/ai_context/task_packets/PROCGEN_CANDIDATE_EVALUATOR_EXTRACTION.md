# PROCGEN CANDIDATE EVALUATOR EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-candidate-evaluator-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-performance-baseline-v1`
- Locks: `procgen-generation`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Move candidate acceptance, scoring, failure classification, fallback ranking, and layout metrics out of CustodianContractMap into one focused generation authority without changing which fixed-seed candidate wins.
- Completion boundary: Done when CustodianContractMap still owns seed/profile/attempt orchestration but delegates candidate measurement and selection policy to a focused evaluator; S1 fixed cases choose the same attempts with the same reasons/scores.
- Current measured state: CustodianContractMap owns _is_map_layout_acceptable, _score_map_layout, _is_terrain_failed_candidate, _is_better_fallback_candidate, _can_use_degraded_fallback, _get_map_layout_metrics, flood-fill helpers, and attempt orchestration in one 1,216-line coordinator.
- Evidence: S1 benchmark contract; live CustodianContractMap selection helpers; procgen_contract_rescue_diagnostic_smoke.gd; terrain-required/connectivity smokes.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; CustodianContractMap; current ingress/connectivity acceptance contracts.
- Work surface: Primary new owner under game/world/procgen/generation/ plus narrow CustodianContractMap delegation; focused candidate/rescue tests and validation_manifest ownership.
- Change: Create a data-only candidate-evaluation result and evaluator API. Move metric extraction, accept/reject reasons, score calculation, terrain-failure classification, degraded-fallback eligibility, and fallback comparison behind that API. Keep attempt order/seed derivation/final promotion in CustodianContractMap. Preserve current reason keys and diagnostics or provide an explicit compatibility mapping covered by tests.
- Preserve: Attempt cap, seed derivation, map-size bands, terrain/connectivity/ingress thresholds, fallback policy, deterministic tie ordering, accepted candidate identity, and S1 metrics schema.
- Non-goals: No semantics-only generation, no TileMap/materialization changes, no scoring retune, no fewer attempts, no map-size changes.
- Acceptance: S1 fixed contract cases produce identical accepted attempt/seed, score ordering, rejection-reason sets, degraded-fallback choice, and gameplay fingerprint; CustodianContractMap no longer owns evaluator-policy internals.
- Validation: Focused evaluator unit/smoke + procgen_contract_rescue_diagnostic + candidate promotion + S1 quick benchmark; then one --changed closeout and diff check.
- Task overrides: `none`
- Deferred: Candidate semantic data model and rejection-path optimization remain the next generation-lane packets.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` and the matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Land the evaluator extraction; procgen-candidate-semantic-model then becomes eligible.
- Best starting files: custodian_contract_map.gd; generation/; procgen_contract_rescue_diagnostic_smoke.gd; S1 benchmark outputs.
- Blockers or open questions: None known at authoring time.
