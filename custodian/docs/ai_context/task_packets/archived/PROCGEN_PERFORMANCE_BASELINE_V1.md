# PROCGEN PERFORMANCE BASELINE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-performance-baseline-v1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `procgen-runtime`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Establish the first reproducible, structured, threshold-free procgen generation + runtime-streaming performance baseline so every later optimization in `PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` can be measured against the same fixed-seed contract.
- Completion boundary: This slice is complete when a deterministic headless benchmark produces schema-stable JSON for fixed generation and runtime cases, existing generation timing data is exposed structurally rather than only through console logs, a cheap focused/quick profile is available without burdening normal validation, a documented opt-in full profile captures the program baseline, same-seed authoritative fingerprints remain unchanged, and the procgen roadmap records S1 as complete with landed SHA + high-signal baseline evidence. No performance behavior is optimized in this slice.
- Current measured state: On reviewed main, `proc_gen_tilemap.gd` is 11,221 lines / 581 funcs and already computes local phase timing marks while printing generation/promotion timing to stdout; `custodian_contract_map.gd` is 1,216 lines and permits up to 12 candidate attempts while printing instantiate/generate/metrics/total attempt timing; `contract_world_loader.gd` is 2,001 lines. Streaming defaults are 16x16 chunks, immediate radius 1, active radius 2, 96 reveal tiles/frame, 0.15 s visual rebuild interval, distant unload disabled. Existing non-controlled Observatory captures show roughly 10.8k total nodes, 1,276 procgen nodes, 2.8k rendered objects, 696-699 draw calls, ~1.4 ms visible-wall sync, ~13.2 ms walkable-boundary rebuild, and one ~257.9 ms navigation rebuild. These are diagnostic observations, not the baseline this task must create.
- Evidence: `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`; live `proc_gen_tilemap.gd` generation `_marks` and promotion timing; live `CustodianContractMap.generate_contract()` attempt timing; `procgen_runtime_health_smoke.gd`; `procgen_candidate_promotion_smoke.gd`; `NO_LOOT_BEACON` / `WITH_LOOT_BEACON` Observatory captures; `RUNTIME_STUTTER_PERFORMANCE_PASS.md`; existing performance benchmark conventions in `ambient_enemy_full_actor_perf_bench.gd` and `enemy_runtime_attribution_perf_bench.gd`.
- Task-specific authority: `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`; `custodian/docs/ai_context/VALIDATION_RECIPES.md`; `custodian/docs/ai_context/task_packets/RUNTIME_STUTTER_PERFORMANCE_PASS.md`; live procgen generation/runtime authorities.
- Work surface: Primary new owner is a focused benchmark/metrics surface under `custodian/tools/validation/` and, only where required to expose already-computed measurements, a narrow diagnostic metrics helper under `custodian/game/world/procgen/diagnostics/`. Expected minimal integration touches are `proc_gen_tilemap.gd`, `custodian_contract_map.gd`, `validation_manifest.json`, `VALIDATION_RECIPES.md`, `FILE_INDEX.md`, current-state docs only if runtime-observability truth changes, and the procgen optimization roadmap. Do not add benchmark orchestration to gameplay/autoload code.
- Change:
  1. Add a structured procgen performance snapshot contract. Reuse timing boundaries already present in `ProcGenTilemap` and `CustodianContractMap`; do not duplicate generation work merely to measure it. A focused diagnostics helper may normalize snapshots, but gameplay coordinators remain the source of timing events they already own.
  2. Generation snapshot must include, at minimum: seed/config identity; map dimensions; generation mode; total generation time; named phase timings already measured inside `_fill_tilemaps()`; accepted-candidate promotion timings; authoritative floor/wall counts; final fingerprint/identity fields needed to prove same-seed output stability.
  3. Contract snapshot must include, at minimum: contract seed; attempt limit; attempts run; accepted attempt; per-attempt seed; instantiate/generate/metrics/total duration; acceptance result; score; rejection reasons; required-ingress result; terrain rescue/failure facts; degraded-fallback state when applicable; total candidate-loop duration; final promotion duration where available.
  4. Runtime snapshot must consume existing runtime-health/Observatory facts rather than start a second telemetry system. Capture at minimum streaming queue peak/current, revealed/queued chunk counts where exposed, reveal throughput/count, runtime wall/boundary/navigation/shadow rebuild count + duration, procgen/runtime blocker counts, node/procgen-node counts, rendered-object/draw-call engine monitors when available, and frame-time samples for the scripted runtime case.
  5. Add a dedicated headless benchmark, preferably `custodian/tools/validation/procgen_performance_baseline_bench.gd`, with two execution profiles:
     - **quick**: small deterministic verification used for focused development. It must complete in bounded time and prove schema, determinism, and benchmark mechanics without running the entire full matrix.
     - **full**: opt-in baseline capture. Use fixed sizes `160x160`, `192x192`, and `224x224` across fixed seeds `420777`, `420779`, and `771923` for controlled direct-generation cases. Also include fixed contract-level cases using the normal candidate-attempt policy so candidate-loop cost is represented. If a fixed seed becomes invalid because an intentional later authority change makes it unrepresentative, update the roadmap and benchmark contract explicitly rather than silently replacing it.
  6. The benchmark writes JSON to `user://performance/procgen_performance_baseline_v1.json` (or a single clearly documented equivalent stable filename) and prints a compact human-readable summary. Runtime output is ephemeral and is not committed as a generated artifact. The committed closing summary and roadmap record the first baseline's high-signal medians/ranges plus execution environment.
  7. Define a schema/version field and case identity so later slices can compare like-for-like. Record Godot version/build mode and benchmark profile. If exact Git SHA is not safely discoverable from runtime, accept it as a CLI-provided optional metadata field rather than shelling out from gameplay code.
  8. Keep S1 threshold-free for absolute performance. Do **not** invent universal millisecond/FPS pass gates from one host. The pass/fail contract for S1 is benchmark reproducibility, schema completeness, deterministic world fingerprints, and no behavior regression. S11 owns final stable regression budgets after repeated before/after evidence.
  9. Avoid per-frame event spam. Sample frame/engine statistics through the benchmark harness or existing observability surfaces; do not add noisy permanent per-frame logging to `ProcGenTilemap`.
  10. Update `VALIDATION_RECIPES.md` with exact quick/full invocation and the warning that the full matrix is intentionally slow/resource-heavy. Register only the cheap focused proof in `validation_manifest.json`; do not make every procgen edit run the full benchmark.
  11. At completion, update `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`: S1 -> `complete`, add landed main SHA, closing summary, and baseline evidence, and mirror the result into `design/00_meta/MASTER_ROADMAP.md`. Do not author later V1 packets during this task: the complete V1 series is already published on `main`, and dependency metadata will make the next eligible packets claimable automatically.
  12. Reconcile documentation drift touched by this implementation only. Do not spend S1 rewriting the entire architecture. If metrics ownership or validation entrypoints change, update the applicable index/current-state statements. The roadmap already records stale coordinator line-count and streaming-doc debt for later convergence.
- Preserve: Contract seed determinism; candidate acceptance/scoring behavior; normal map dimensions and attempt cap; terrain/road/playability/ingress requirements; accepted-candidate in-place promotion; current streaming reveal behavior; runtime wall destruction/collision correctness; navigation correctness; existing Observatory metric names/semantics; current gameplay content density; all presentation output.
- Non-goals: Do not implement semantics-only candidates, change candidate scoring, reduce candidate attempts, change map sizes, extract candidate evaluation, optimize navigation, change pause processing, change chunk lifecycle/unload defaults, decompose `ProcGenTilemap` or `ContractWorldLoader`, batch render nodes, alter visual assets, or tune gameplay.
- Acceptance:
  - A clean checkout can run the documented quick benchmark headlessly and obtain valid schema-versioned JSON plus a compact summary.
  - The opt-in full profile runs the documented fixed-size/fixed-seed matrix and fixed contract cases without relying on randomized seeds.
  - Repeated same-case runs produce the same gameplay-authoritative fingerprint/count contract even if wall-clock timings differ.
  - Benchmark generation does not invoke duplicate generation solely for timing; accepted-candidate promotion remains the current in-place path.
  - Structured output contains candidate-loop timing/acceptance data, named generation/promotion phases, and runtime streaming/derived-rebuild metrics sufficient to evaluate S2-S7.
  - No new permanent per-frame telemetry flood or gameplay autoload is introduced.
  - Existing `procgen_candidate_promotion_smoke.gd`, `procgen_runtime_health_smoke.gd`, relevant deterministic procgen smoke(s), and contract generation checks remain green.
  - Normal changed-file validation does not automatically execute the slow full benchmark.
  - `PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` is updated in the landed implementation with S1 completion evidence and truthful next-slice statuses.
- Validation: First run the new quick benchmark/schema/determinism proof. Then run `procgen_candidate_promotion_smoke.gd`, `procgen_runtime_health_smoke.gd`, one representative fixed-seed generation determinism smoke such as `procgen_spatial_normalization_smoke.gd`, and any focused test selected for touched diagnostics code. Run the full benchmark once for durable closeout evidence, not inside every edit loop. Then run one `python3 custodian/tools/validation/run_validation.py --changed --json` closeout sweep and `git diff --check`. Honor the broad-sweep memory budget in root `AGENTS.md`.
- Task overrides: `none`
- Deferred: S2 candidate evaluator extraction; S3 semantics-only candidates; S4 materializer boundary; S5 mutation scheduler; S6 pause-aware streaming; S7 chunk lifecycle/cache; S8 coordinator decomplexification; S9 placement extraction; S10 renderer/node consolidation; S11 final soak and stable performance budgets.

## Full-Auto Series Contract

This packet is the root of the pre-authored `procgen-runtime-optimization-v1` packet DAG.

No human packet-authoring step is required after S1. All implementation packets, the final whole-series review, and the V2-series-authoring handoff already exist on `main` with `Status: ready`, `Dispatch: auto`, and explicit dependencies.

After this workstream is archived complete:

- `procgen-candidate-evaluator-extraction`
- `procgen-derived-rebuild-scheduler-foundation`
- `contract-world-placement-foundation`

become eligible according to dispatcher priority/locks. Subsequent packets unlock only when their declared prerequisites are archived complete.

Do not absorb later slices into this workstream and do not rewrite their contracts merely because implementation details differ locally. If S1 proves a downstream packet impossible or materially unsafe, mark that contradiction in the roadmap/summary and leave the affected dependent blocked for the final chain review rather than silently changing the program architecture.

The repository packet chain provides unattended eligibility, not a new continuous-worker implementation. This task must not add a worker daemon.

When this packet is being executed inside a user-authorized full-series agent session, successful `workstream.py finish` is also the handoff into the roadmap's **Single-Agent Serial Auto-Run Order**. Return to the coordination checkout and explicitly claim the next unmet workstream in that order with the same agent identity. Continue packet-by-packet without returning for packet authoring. If that workstream is already complete because another agent landed it, advance to the next unmet item. Stop only for failed required validation, a semantically invalid downstream contract, unsafe Git/worktree state, a `human_required` decision, or completion of the final V2-series-authoring handoff.

The serial order is:

```text
S1
G1 -> G2 -> G3 -> G4 -> G5
M1 -> M2 -> M3 -> M4 -> M5 -> M6
P1 -> P2 -> P3 -> P4 -> P5 -> P6 -> P7
D1 -> D2 -> D3 -> D4
V1 -> V2 -> F1 -> Q1 -> A1
```

The exact code-to-workstream mapping is canonical in `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`.

## Handoff

- Next action: Claim `procgen-performance-baseline-v1`, capture the fixed-seed baseline without changing world behavior, update the roadmap, and close normally; the pre-authored dependent packets then become auto-dispatch eligible.
- Best starting files: `custodian/game/world/procgen/proc_gen_tilemap.gd`; `custodian/game/world/procgen/custodian_contract_map.gd`; `custodian/tools/validation/procgen_candidate_promotion_smoke.gd`; `custodian/tools/validation/procgen_runtime_health_smoke.gd`; existing enemy perf benches for output conventions.
- Blockers or open questions: None. Absolute pass/fail performance thresholds are intentionally deferred until S11.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `high`
- What went wrong: the worktree environment was non-functional for any procgen validation before this task began (LFS pointer stubs breaking compilation of `custodian_contract_map.gd`'s dependency chain); a real signal-race bug in the new bench script caused it to hang indefinitely; a pre-existing, unrelated smoke-test assertion (`procgen_candidate_promotion_smoke.gd`) remains red and could not be fixed within S1's scope.
- Root cause / contributing factors: (1) the repo's active temporary Git-LFS bandwidth-degraded mode left binary assets unmaterialized in this specific worktree though fully cached locally; (2) `Signal.emit()` inside a synchronous GDScript call chain fires before the caller's next line runs, so `await signal` placed after the call that emits it is a classic missed-emission race; GDScript lambda closures also capture by value, not reference, defeating a first attempted fix; (3) `_prepare_streaming_reveal()`'s clear-and-reprime behavior does not preserve `procgen_candidate_promotion_smoke.gd`'s `painted_before == painted_after` invariant, and this predates S1 (verified via `git log` and diff-revert reproduction; see `PROCGEN_PERFORMANCE_BASELINE_V1_CLAUDE_SUMMARY.md` for full detail).
- Prevention / pipeline improvement: when a headless Godot script needs to know a synchronous call has finished, do not `await` a signal it may have already emitted — either avoid the await entirely once synchronicity is confirmed, or connect a listener *before* calling and check a mutable-by-reference container (Array/Dictionary), never a plain local `var`, since GDScript lambdas snapshot locals by value.
- Tooling / docs drift discovered: `procgen_candidate_promotion_smoke.gd`'s streamed-floor-cell equality assertion appears to be a latent defect independent of any recent landed work; needs its own investigation/fix packet. Two interior-prop PNGs fail to load despite real materialized content on disk after full LFS checkout and two re-import passes; root cause not identified.
- Follow-up: manual-follow-up (a fix packet for `procgen_candidate_promotion_smoke.gd`'s streaming-reveal floor-cell assertion; this program's packet-authoring restriction means it is not authored here)
