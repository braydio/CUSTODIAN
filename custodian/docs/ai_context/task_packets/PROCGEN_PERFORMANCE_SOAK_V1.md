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
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Run the complete optimized procgen stack through a deterministic production-size soak, compare it to the S1 baseline, and establish stable regression budgets for future work.
- Completion boundary: Done when fixed generation cases and a scripted generate->spawn->traverse->reveal->pause/unpause->mutate->ingress/return->re-reveal sequence have durable before/after JSON, deterministic correctness remains green, and evidence-backed performance budgets are written into the benchmark contract/roadmap.
- Current measured state: All V1 optimization branches have converged: semantics-only candidate generation/materialization, rebuild scheduling, pause-aware chunk streaming/cache/unload, coordinator/loader extraction, and measured render consolidation.
- Evidence: S1 baseline JSON/schema and every landed V1 slice summary; S10b attribution/consolidation metrics.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; S1 benchmark schema; active deterministic/streaming/ingress contracts.
- Work surface: Benchmark/soak harness and only small diagnostics/budget config needed to formalize regression gates; runtime code changes are bug fixes only if required to make existing V1 contracts pass.
- Change: Add one deterministic soak profile using production-size fixed seeds and scripted traversal/mutation/ingress lifecycle. Compare generation attempt cost, accepted realization, derived rebuild p50/p95/worst, streaming queue/cache/unload, pause behavior, node/render load, frame-time samples and authoritative fingerprints to S1. Establish host-relative or fixed-environment budgets with explicit headroom from repeated optimized runs; do not invent universal FPS thresholds.
- Preserve: All gameplay/content semantics, map sizes/attempts, deterministic output, pause gameplay freeze, ingress/return behavior.
- Non-goals: No new optimization initiative beyond small correctness fixes; no new content/art; no changing benchmark cases to make results look better.
- Acceptance: Complete soak passes determinism and lifecycle assertions; report quantifies S1->V1 changes for every roadmap target; stable budgets are documented with environment and tolerance; no V1 slice's targeted metric is silently worse without an explained accepted tradeoff.
- Validation: Run full soak repeatedly enough to derive stable budgets, all critical focused procgen suites, one changed-file closeout, and diff check; avoid overlapping broad Godot sweeps.
- Task overrides: `none`
- Deferred: Whole-series independent review and dependency-chain audit are the next packet.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, and finish normally so dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Land final V1 soak/budgets; review-procgen-runtime-optimization-series-v1 becomes eligible.
- Best starting files: S1 benchmark harness/report; V1 roadmap evidence; S10 attribution/consolidation report; ingress/streaming/runtime mutation tests.
- Blockers or open questions: None known at authoring time.
