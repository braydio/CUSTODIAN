# PROCGEN PERFORMANCE SOAK V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-performance-soak-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-render-load-consolidation`
- Locks: `procgen-runtime, contract-world-loader`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `7913903704aee8fdd2c645891df441fa31fb6cca`
- Goal: Run the complete optimized procgen stack through a deterministic production-size soak, compare it to the S1 baseline, and establish stable regression budgets for future work.
- Completion boundary: Done when fixed generation cases and a scripted generate->spawn->traverse->reveal->pause/unpause->mutate->ingress/return->re-reveal sequence have durable before/after JSON, deterministic correctness remains green, and evidence-backed performance budgets are written into the benchmark contract/roadmap.
- Current measured state: V1 has **not** converged yet. S1, G1-G5, M1-M3 are complete; M4 is active; M5/M6 are refresh-gated; placement extraction has not started; D1-D3 are refresh-gated; GenerationGrid migration has not begun; D4/P7/render consolidation are future. This packet remains dependency-gated behind `procgen-render-load-consolidation`; its soak contract is intentionally end-state-oriented rather than evidence that the end state exists today.
- Evidence: S1 baseline/schema; live procgen roadmap packet states; completed G/M summaries; current M/P/D/X/V packet contracts. At execution time, use every landed V1 closing summary plus V1/V2 render evidence rather than this pre-convergence inventory.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; S1 benchmark schema; active deterministic/streaming/ingress contracts.
- Work surface: Existing benchmark/diagnostics stack (`custodian/tools/validation/procgen_performance_baseline_bench.gd`, `custodian/game/world/procgen/diagnostics/procgen_performance_snapshot.gd`) plus the smallest new soak driver/fixtures and budget metadata required after V2. Runtime implementation changes are bug fixes only when a failing V1 contract proves one is needed.
- Change: Once dependency-eligible, re-read the final V1 architecture and run a deterministic production-size sequence covering generation/candidate acceptance, spawn, streaming traversal, pause/resume, runtime mutation/destruction, authored ingress/return, re-entry/re-reveal and measured render load. Compare against S1 using the final lifecycle/cache/unload/placement/generation/render telemetry names that actually landed; do not hard-code stale pre-M4 metric keys.
- Preserve: All gameplay/content semantics, map sizes/attempts, deterministic output, pause gameplay freeze, ingress/return behavior.
- Non-goals: No new optimization initiative beyond small correctness fixes; no new content/art; no changing benchmark cases to make results look better.
- Acceptance: Complete soak passes determinism and lifecycle assertions; report quantifies S1->V1 changes for every roadmap target; stable budgets are documented with environment and tolerance; no V1 slice's targeted metric is silently worse without an explained accepted tradeoff.
- Validation: Run the final soak repeatedly enough to establish environment/tolerance, then the critical focused suites named by the landed M/P/D/X/V summaries, one changed-file closeout and diff check. Respect the repository broad-Godot-sweep memory budget and do not overlap broad runs.
- Task overrides: `none`
- Deferred: Whole-series independent review and dependency-chain audit are the next packet.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, and finish normally so dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Land final V1 soak/budgets; review-procgen-runtime-optimization-series-v1 becomes eligible.
- Best starting files: S1 benchmark harness/report; V1 roadmap evidence; S10 attribution/consolidation report; ingress/streaming/runtime mutation tests.
- Blockers or open questions: None known at authoring time.
