# PROCGEN CANDIDATE EVALUATOR EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-candidate-evaluator-extraction`
- Status: `complete`
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
- Task-specific authority: `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`; `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_PATH_INDEX.md` section `S2 / G1 — Candidate Evaluator Extraction`; `custodian/game/world/procgen/custodian_contract_map.gd`; current ingress/connectivity acceptance contracts.
- Work surface: Use `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_PATH_INDEX.md#s2--g1--candidate-evaluator-extraction` as the primary exact-path navigation index. Most likely edits/creates are `custodian/game/world/procgen/custodian_contract_map.gd`, `custodian/game/world/procgen/generation/candidate_evaluator.gd`, optional `custodian/game/world/procgen/generation/candidate_evaluation_result.gd`, `custodian/game/world/procgen/generation/README.md`, `custodian/tools/validation/procgen_candidate_evaluator_smoke.gd`, `custodian/tools/validation/procgen_contract_rescue_diagnostic_smoke.gd`, and `custodian/tools/validation/validation_manifest.json`. Treat `custodian/game/world/procgen/proc_gen_tilemap.gd`, `procgen_candidate_promotion_smoke.gd`, `procgen_terrain_required_cells_smoke.gd`, `procgen_playability_smoke.gd`, and `procgen_spatial_normalization_smoke.gd` as read/validation references unless a concrete failing dependency requires an edit.
- Change: Create a data-only candidate-evaluation result and evaluator API. Move metric extraction, accept/reject reasons, score calculation, terrain-failure classification, degraded-fallback eligibility, and fallback comparison behind that API. Keep attempt order/seed derivation/final promotion in CustodianContractMap. Preserve current reason keys and diagnostics or provide an explicit compatibility mapping covered by tests.
- Preserve: Attempt cap, seed derivation, map-size bands, terrain/connectivity/ingress thresholds, fallback policy, deterministic tie ordering, accepted candidate identity, and S1 metrics schema.
- Non-goals: No semantics-only generation, no TileMap/materialization changes, no scoring retune, no fewer attempts, no map-size changes.
- Acceptance: S1 fixed contract cases produce identical accepted attempt/seed, score ordering, rejection-reason sets, degraded-fallback choice, and gameplay fingerprint; CustodianContractMap no longer owns evaluator-policy internals.
- Validation: Focused evaluator unit/smoke + procgen_contract_rescue_diagnostic + candidate promotion + S1 quick benchmark; then one --changed closeout and diff check.
- Task overrides: `none`
- Deferred: Candidate semantic data model and rejection-path optimization remain the next generation-lane packets.

## Exact Path Reminder

Before any broad repository search, open:

`design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_PATH_INDEX.md`

and use its **S2 / G1 — Candidate Evaluator Extraction** section as the most-likely reference for exact implementation, fixture, validation, predecessor-evidence, and closeout paths. Search within those named files for the listed evaluator symbols first. Expand beyond the index only when a concrete compile/test/dependency failure demonstrates that another path is involved. If live main requires a different new-file path, record the deviation and update the path index in the same landed change.

## Context Economy / Low-Token Execution

This is a deliberate follow-up reminder for long-running Sonnet/Codex execution. Optimize context use without weakening correctness:

- treat this packet's Goal, Completion boundary, Change, Preserve, Acceptance, Validation, and Handoff as primary context;
- read the immediate predecessor closing summary and benchmark/roadmap evidence instead of rereading completed packets;
- do not re-audit the whole repository unless a packet assumption fails or a required dependency cannot be resolved;
- for very large files, especially `proc_gen_tilemap.gd`, search for the named functions/state first and read only the relevant ranges plus immediate callers/callees; do not load the full file by default;
- reuse landed S1 benchmark artifacts, prior slice summaries, and existing validation evidence rather than rediscovering established facts;
- inspect only the current authority, direct consumers, and direct dependencies needed for this slice;
- during iteration run focused validation only; run one normal changed-file closeout sweep after focused work is green;
- do not dump full logs, full diffs, or large source excerpts into progress/final responses; summarize failures and evidence compactly;
- do not restate this packet or narrate broad architecture before implementation unless a contradiction requires a decision;
- keep the closing summary factual and compact while still recording required evidence, drift, and handoff state.

Context economy is subordinate to correctness: expand scope only when a concrete failed assumption, test, or dependency proves that more repository context is required.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` and the matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Continue with G2 `procgen-candidate-semantic-model`, which becomes eligible after this workstream lands.
- Best starting files: `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_PATH_INDEX.md` first; then the exact S2/G1 paths it lists, beginning with `custodian/game/world/procgen/custodian_contract_map.gd`, `custodian/game/world/procgen/generation/README.md`, `custodian/tools/validation/procgen_contract_rescue_diagnostic_smoke.gd`, and landed S1 benchmark evidence.
- Blockers or open questions: None known at authoring time.

## Execution Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: LFS skip-smudge initially blocked Godot validation; the first evaluator smoke revision had a floating-point equality assertion and an invalid `RefCounted.free()` call.
- Root cause / contributing factors: workstream checkouts honor the temporary LFS degraded mode; Godot needed cached binaries materialized and a fresh editor scan before its class cache and imports were usable.
- Prevention / pipeline improvement: check local LFS object availability and materialize cached objects before Godot import; the repository primer documents this sequence.
- Tooling / docs drift discovered: none; the candidate-promotion assertion is an already documented independent follow-up.
- Follow-up: manual-follow-up
- What worked: one cached LFS checkout and fresh import restored validation; fixed-seed diagnostics retained the previous selection metrics and reasons.
