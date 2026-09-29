# PROCGEN SEMANTIC CANDIDATE GENERATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-semantic-candidate-generation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-candidate-semantic-model`
- Locks: `procgen-generation`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Generate evaluator-complete rejected candidates as semantic data without final runtime/presentation realization, while preserving candidate acceptance and world fingerprints.
- Completion boundary: Done when the contract attempt loop can produce and evaluate semantic candidates without creating final props, streaming setup, runtime collision, shadows, navigation, or other rejected-world realization, and S1 cases select the same winner.
- Current measured state: generation_evaluation_mode skips some final work but still builds substantial structural TileMap/terrain/road state for every attempted candidate.
- Evidence: S1 per-attempt timings; S2 evaluator; S3 semantic model; existing _fill_tilemaps phase timings and promotion smoke.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; semantic candidate model/evaluator; deterministic terrain/intent/route authorities.
- Work surface: ProcGen generation/construction path, semantic candidate builder, CustodianContractMap attempt loop, focused determinism and evaluation tests.
- Change: Add a semantics-first attempt path that computes only authoritative data needed by the candidate model/evaluator. Reuse existing pure/planning authorities rather than duplicating terrain/intent/route rules. Keep an explicit temporary parity/compatibility seam if needed so fixed cases can compare semantic versus legacy evaluation. Rejected attempts must not instantiate final presentation/streaming/nav/collision work.
- Preserve: Seed mapping, candidate ordering, evaluator outputs, required-cell/ingress/connectivity semantics, and accepted candidate identity.
- Non-goals: Do not yet delete the legacy live-candidate path; do not realize the winner through a new materializer in this packet; no visual changes.
- Acceptance: S1 fixed cases select identical winners/fingerprints; rejected attempts show zero final presentation/nav/collision/streaming realization and materially less rejected-attempt work in S1 metrics; parity diagnostics identify any semantic mismatch loudly.
- Validation: Semantic-vs-legacy parity smoke, rescue/connectivity/terrain smokes, S1 quick and one representative full comparison; changed-file closeout.
- Task overrides: `none`
- Deferred: Accepted-candidate runtime realization and legacy-path demolition follow.

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

- Next action: Land semantics-first attempt generation; procgen-accepted-candidate-materializer then becomes eligible.
- Best starting files: proc_gen_tilemap.gd generation phases; generation/ semantic builder; CustodianContractMap; S1 timing report.
- Blockers or open questions: None known at authoring time.
