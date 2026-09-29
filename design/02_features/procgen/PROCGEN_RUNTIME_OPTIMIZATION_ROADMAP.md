# PROCGEN RUNTIME OPTIMIZATION ROADMAP

**Project:** CUSTODIAN  
**Program ID:** `procgen-runtime-optimization`  
**Roadmap:** Cross-cutting Procgen Runtime Optimization  
**Status:** in_progress  
**Priority:** P1  
**Reviewed main:** `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`  
**Last Updated:** 2026-09-29  
**Depends on:** none for measurement; slice dependencies below

## Purpose

Make contract-world generation and traversal materially cheaper, smoother, and easier to extend without changing deterministic world output, hiding cost by shrinking maps, or replacing one procgen god file with a cloud of tightly coupled helper files.

This roadmap owns the optimization/decomplexification program for:

- contract candidate generation and rejection cost;
- accepted-candidate materialization;
- streaming reveal and chunk lifecycle;
- collision, shadow, boundary, and navigation mutation batching;
- pause behavior for background world preparation;
- `ProcGenTilemap` coordinator decomposition;
- generated-world placement decomposition;
- renderer/node-count reduction after measurement;
- end-to-end fixed-seed performance regression evidence.

It does not own Hub/Twin Solaria access, campaign-world transitions, authored-level route design, combat tuning, or content/art production.

## Current Measured State

Reviewed on `main@4dcbe371`:

| Authority | Current size | Current role |
| --- | ---: | --- |
| `custodian/game/world/procgen/proc_gen_tilemap.gd` | 11,221 lines / 581 funcs / 439,746 chars | Procgen façade/state host plus construction orchestration, roads, terrain integration, foliage/props, streaming, runtime collision/mutation, presentation, authored claims, portals, diagnostics, and export |
| `custodian/game/world/procgen/custodian_contract_map.gd` | 1,216 lines / 35 funcs | Contract seed/profile creation, up-to-12 candidate loop, acceptance/scoring, fallback selection, final promotion |
| `custodian/game/systems/core/systems/contract_world_loader.gd` | 2,001 lines / 98 funcs | Runtime world attach/rebind plus resources, vehicles, relays, encounters, ingresses, authored destinations, camera/navigation handoff |

Current generation/runtime contracts include:

- candidate evaluation already skips some final decoration and promotes the accepted structural candidate in place;
- candidate evaluation is **not** semantics-only and still constructs substantial structural TileMap/terrain/road state before rejection;
- normal contract generation allows up to `12` candidate attempts;
- generated maps are typically `160x160` through `224x224`;
- streaming reveal defaults to `16x16` chunks, immediate radius `1`, active radius `2`, `96` tiles/frame, and `0.15 s` derived-visual rebuild cadence;
- distant chunk unload remains disabled by default;
- pause sets `SceneTree.paused = true`; procgen reveal work currently runs from ordinary `ProcGenTilemap._process()`, so live reveal/streaming processing stops while paused;
- runtime performance work has already added deferred reveal rebuilds, compact wall bodies, bounded foliage work, shared foliage materials, and mutation gauges;
- existing Observatory captures show approximately `10.8k` total nodes, `1,276` procgen nodes, `2.8k` rendered objects, and about `696-699` draw calls in one production-size capture;
- the same capture recorded a navigation rebuild around `257,894 usec` (~258 ms), while runtime wall sync was around `1.4 ms` and a walkable-boundary rebuild around `13.2 ms`.

Those captures are useful evidence, not a controlled benchmark baseline. Slice 1 creates that baseline.

## Program Invariants

Every slice must preserve these unless a later design authority explicitly changes them:

1. **Determinism first.** Same seed + same config must retain the same gameplay-authoritative result.
2. **Do not optimize by reducing the game.** Do not lower map sizes, candidate-attempt caps, required connectivity, ingress requirements, route safety, or content density merely to make timing numbers smaller.
3. **Semantics before presentation.** Candidate rejection should eventually operate on the cheapest authoritative semantic representation that can prove acceptance.
4. **One mechanic, one owner.** Extract coherent stateful authorities with narrow APIs. Do not spray stateless helpers that depend on dozens of `ProcGenTilemap` private fields.
5. **No gameplay authority from presentation.** Rendering, camera visibility, chunk visuals, and pause-menu state may not decide walkability, combat, routing, or persistence.
6. **Background preparation is not background simulation.** Pause-time work may prepare deterministic world data, but enemies, player discovery, destructible topology mutation, and gameplay clocks remain frozen.
7. **Profile before structural optimization.** Every performance slice must compare against the Slice 1 benchmark contract where applicable.
8. **Focused validation first.** Full benchmark profiles are opt-in/slow and must not make normal changed-file validation unreasonably expensive.

## V1 Full-Auto Packet Series

**Series ID:** `procgen-runtime-optimization-v1`  
**Packet count:** 26 implementation packets including S1/S11, plus 1 whole-series review and 1 next-series-authoring handoff.  
**Dispatch contract:** every packet is pre-authored on `main`, `Status: ready`, and `Dispatch: auto`. Dependencies and locks, not future chat authoring, gate eligibility.

This is a dependency DAG, not one giant workstream. Each packet lands independently. Multiple agents may execute independent eligible siblings in parallel; one agent may also run the serial order below.

### Dependency Graph

```text
S1  procgen-performance-baseline-v1
│
├─ GENERATION LANE
│  G1 procgen-candidate-evaluator-extraction
│   └─ G2 procgen-candidate-semantic-model
│       └─ G3 procgen-semantic-candidate-generation
│           └─ G4 procgen-accepted-candidate-materializer
│               └─ G5 procgen-candidate-runtime-path-demolition
│
├─ RUNTIME / STREAMING LANE
│  M1 procgen-derived-rebuild-scheduler-foundation
│   └─ M2 procgen-runtime-mutation-scheduler-cutover
│       └─ M3 procgen-pause-aware-streaming
│           └─ M4 procgen-chunk-lifecycle-state-machine
│               └─ M5 procgen-chunk-payload-cache
│                   └─ M6 procgen-distant-chunk-unload
│
└─ PLACEMENT LANE
   P1 contract-world-placement-foundation
    ├─ P2 contract-world-resource-placement-extraction
    ├─ P3 contract-world-vehicle-placement-extraction
    ├─ P4 contract-world-relay-placement-extraction
    ├─ P5 contract-world-encounter-placement-extraction
    └─ P6 contract-world-ingress-placement-extraction
         \____________________________________________
                                                      \
P2 + P3 + P4 + P5 + P6 ──────────────────────────────> P7 contract-world-loader-contraction

G5 + M6
├─ D1 procgen-road-authority-extraction
├─ D2 procgen-authored-claim-registry-extraction
└─ D3 procgen-generation-state-extraction
     \________________________________
                                      \
D1 + D2 + D3 ─────────────────────────> D4 procgen-tilemap-facade-contraction

D4 + P7
└─ V1 procgen-render-attribution-v1
    └─ V2 procgen-render-load-consolidation
        └─ F1 procgen-performance-soak-v1
            └─ Q1 review-procgen-runtime-optimization-series-v1
                └─ A1 procgen-runtime-optimization-v2-series-authoring
```

### Single-Agent Serial Auto-Run Order

When the user has authorized one agent/session to run this full series unattended, use this deterministic traversal after each successful `workstream.py finish`:

```text
S1
G1 -> G2 -> G3 -> G4 -> G5
M1 -> M2 -> M3 -> M4 -> M5 -> M6
P1 -> P2 -> P3 -> P4 -> P5 -> P6 -> P7
D1 -> D2 -> D3 -> D4
V1 -> V2 -> F1 -> Q1 -> A1
```

After finishing a packet, return to the coordination checkout and explicitly claim the next packet in this order using the same agent identity. Do not use an unrelated `claim-next` result to wander into another project task. If the next packet is already complete because another agent landed it, advance to the next unmet item whose dependencies are complete. Stop the unattended chain only for:

- failed required validation;
- a packet becoming semantically invalid against live main;
- an unresolved merge/dirty-worktree safety condition;
- a `human_required` review decision;
- or exhaustion of A1.

This contract does not create a worker daemon. It makes the packet series self-contained and safe for an already-authorized agent to continue across workstreams without returning to chat for new packet authoring.

### Macro-Slice Mapping

| Roadmap slice | Packet(s) |
| --- | --- |
| S1 Baseline | S1 |
| S2 Evaluator extraction | G1 |
| S3 Semantics-only candidates | G2 + G3 |
| S4 Accepted materialization | G4 + G5 |
| S5 Runtime mutation scheduler | M1 + M2 |
| S6 Pause-aware streaming | M3 |
| S7 Chunk lifecycle/cache | M4 + M5 + M6 |
| S8 ProcGenTilemap decomplexification | D1 + D2 + D3 + D4 |
| S9 Contract-world placement extraction | P1 + P2 + P3 + P4 + P5 + P6 + P7 |
| S10 Renderer/node-load work | V1 + V2 |
| S11 Final soak/budgets | F1 |
| Whole-series review | Q1 |
| Next-series generation | A1 |

## Packet Status

| Code | Workstream | Status | Depends on |
| --- | --- | --- | --- |
| S1 | `procgen-performance-baseline-v1` | **complete** | none |
| G1 | `procgen-candidate-evaluator-extraction` | queued | S1 |
| G2 | `procgen-candidate-semantic-model` | queued | G1 |
| G3 | `procgen-semantic-candidate-generation` | queued | G2 |
| G4 | `procgen-accepted-candidate-materializer` | queued | G3 |
| G5 | `procgen-candidate-runtime-path-demolition` | queued | G4 |
| M1 | `procgen-derived-rebuild-scheduler-foundation` | queued | S1 |
| M2 | `procgen-runtime-mutation-scheduler-cutover` | queued | M1 |
| M3 | `procgen-pause-aware-streaming` | queued | M2 |
| M4 | `procgen-chunk-lifecycle-state-machine` | queued | M3 |
| M5 | `procgen-chunk-payload-cache` | queued | M4 |
| M6 | `procgen-distant-chunk-unload` | queued | M5 |
| P1 | `contract-world-placement-foundation` | queued | S1 |
| P2 | `contract-world-resource-placement-extraction` | queued | P1 |
| P3 | `contract-world-vehicle-placement-extraction` | queued | P1 |
| P4 | `contract-world-relay-placement-extraction` | queued | P1 |
| P5 | `contract-world-encounter-placement-extraction` | queued | P1 |
| P6 | `contract-world-ingress-placement-extraction` | queued | P1 |
| P7 | `contract-world-loader-contraction` | queued | P2+P3+P4+P5+P6 |
| D1 | `procgen-road-authority-extraction` | queued | G5+M6 |
| D2 | `procgen-authored-claim-registry-extraction` | queued | G5+M6 |
| D3 | `procgen-generation-state-extraction` | queued | G5+M6 |
| D4 | `procgen-tilemap-facade-contraction` | queued | D1+D2+D3 |
| V1 | `procgen-render-attribution-v1` | queued | D4+P7 |
| V2 | `procgen-render-load-consolidation` | queued | V1 |
| F1 | `procgen-performance-soak-v1` | queued | V2 |
| Q1 | `review-procgen-runtime-optimization-series-v1` | queued | F1 |
| A1 | `procgen-runtime-optimization-v2-series-authoring` | queued | Q1 |

Per-packet completion evidence is written into the roadmap during execution. A packet is not considered closed merely because code landed.

## Roadmap Maintenance Contract

This file is the program tracker for this workstream family.

Every procgen optimization slice must update this roadmap in the same landed change that completes the slice:

1. set the slice status to `complete`, `blocked`, or the truthful current state;
2. replace `TBD` completion evidence with the landed main SHA, closing summary, and high-signal before/after metric;
3. update the **Current Program Position** section;
4. do not author ordinary V1 successor packets: the complete V1 DAG is already published; update only truthful status/evidence unless a contract is proven invalid;
5. mirror the same macro-slice outcome into the `Cross-cutting Procgen Runtime Optimization` table in `design/00_meta/MASTER_ROADMAP.md`; map detailed `queued` to master `planned` until an implementation is actually in progress;
6. add newly discovered V1 work only when it is independently necessary and cannot be owned by an existing packet; otherwise carry it to Q1/A1 for V2 series authoring;
7. never rewrite historical slice evidence to make later results look cleaner.

A slice packet is not considered fully closed until this roadmap agrees with live runtime truth.

If an independent review creates a correction packet, keep the original slice `complete` as implementation truth but add the review/correction state in its evidence cell until the review cycle passes.

## Current Program Position

**Current packet:** G1 `procgen-candidate-evaluator-extraction` (next in serial order)
**State:** S1 landed; G1, M1, and P1 are now dependency-eligible.
**Next gate:** extract candidate metrics/acceptance/scoring/terrain-fallback policy out of `CustodianContractMap` into a focused generation authority (G1), matching S1's fixed-seed baseline unchanged.
**After S1:** G1, M1, and P1 became eligible. The serial full-auto traversal takes G1 first; parallel agents may claim independent eligible siblings subject to locks.

---

## S1 - Performance Baseline + Budget Contract

### Goal

Create a deterministic, reproducible, structured benchmark contract before changing performance behavior.

Measure:

- contract total generation time;
- candidate count and per-candidate timing;
- generation phase timing;
- candidate acceptance/rejection reason;
- accepted-candidate promotion timing;
- streaming queue/throughput;
- chunk reveal counts;
- navigation, wall, boundary, and shadow rebuild timing/counts;
- node/procgen-node/rendered-object/draw-call counts where available;
- frame-time samples for scripted runtime traversal/mutation cases.

The baseline is initially threshold-free. Performance is host/build dependent; S1 establishes repeatable cases and schema, not fake universal FPS gates.

### Exit

S1 exits when fixed seeds produce structured JSON, same-seed gameplay fingerprints remain unchanged, quick validation is cheap enough for focused use, a full opt-in benchmark profile is documented, and this roadmap records the first measured baseline.

### Completion Evidence

- **Landed main SHA:** `e8cb14e0b` (`procgen performance baseline v1, S1 structured fixed-seed benchmark`).
- **Benchmark:** `custodian/tools/validation/procgen_performance_baseline_bench.gd`, schema `custodian.procgen_performance_baseline.v1`, JSON to `user://performance/procgen_performance_baseline_v1.json`. Reuses timing already owned by `ProcGenTilemap` (`get_last_generation_timing_snapshot`, `get_last_promotion_timing_snapshot`, `get_runtime_health_snapshot`) and `CustodianContractMap` (`get_last_contract_generation_report`, newly accumulated per-attempt candidate-loop timing) via a narrow `custodian/game/world/procgen/diagnostics/procgen_performance_snapshot.gd` normalizer. No generation work is duplicated to measure it.
- **Quick profile (48x48, seed 420777):** two same-seed runs produced identical fingerprint (`determinism_ok: true`); generation `total_ms` ~2.6s (`fill_tilemaps` ~2.56s dominated by `props_visual` ~1.0s, `compound_interior_spawn` ~0.56s, `terrain_elevation`/`terrain_apply_builder` ~0.4s each); one contract case accepted on attempt 1/12 (`t_generate_ms` 18001, `t_metrics_ms` 6081, `total_candidate_loop_duration_ms` 24086, `final_promotion_duration_ms` 14933); runtime case (64x64) averaged ~6.8 ms/frame over 60 sampled frames after generation, 25 chunks revealed, streaming-reveal queue peak 1466.
- **Full profile (fixed matrix, opt-in `--full`, Godot 4.7.2-stable arch_linux, debug build, headless):** all 9 direct-generation cases and all 3 contract cases produced valid schema-stable output; `determinism_ok: true`. Generation `total_ms` scaled from ~25-30s (160x160) to ~31-40s (192x192) to ~35-46s (224x224) across seeds, dominated by `fill_tilemaps`. All 3 contract cases accepted on attempt 1/12 with `total_candidate_loop_duration_ms` 12637-32399 and `final_promotion_duration_ms` 8676-18536. Runtime case (192x192, seed 420777) averaged ~7.0 ms/frame over 60 sampled frames, 25 chunks revealed, streaming-reveal queue peak 362. JSON evidence not committed (ephemeral per task-packet convention); these are the first measured numbers on this host/build and are not pass/fail budgets.
- **Validation:** `procgen_runtime_health_smoke.gd` and `procgen_spatial_normalization_smoke.gd` pass unchanged. `procgen_candidate_promotion_smoke.gd` fails on a pre-existing, unrelated assertion (`Promotion exposed additional streamed floor cells`) reproduced identically with S1's diff fully removed; root cause is `_prepare_streaming_reveal()` clearing and re-priming only the immediate-radius chunk window around spawn during promotion, which the smoke test's `== painted_before` equality assertion does not account for. Zero commits touched `proc_gen_tilemap.gd` between the packet's reviewed SHA (`6a11a14e`) and this landing, so this is not a regression introduced by S1 or by other landed work in this window; it is a latent defect in the smoke test's assertion. Tracked as follow-up, not fixed here (streaming reveal behavior is explicitly out of S1's scope).

---

## S2 - Candidate Evaluator Extraction

### Goal

Move candidate metrics, acceptance policy, scoring, terrain-failure classification, degraded-fallback comparison, and ingress-validation adaptation out of `CustodianContractMap` into a focused generation authority.

### Target boundary

`CustodianContractMap` should own seed/profile selection and winner orchestration. A generation service should own evaluation data and policy.

### Exit

Fixed-seed candidate selection is identical to S1, candidate acceptance/rejection reasons are unchanged, and selection code no longer requires construction internals inside the contract coordinator.

---

## S3 - Semantics-Only Candidate Generation

### Goal

Stop building rejected candidates as near-runtime worlds.

Introduce a gameplay-authoritative candidate representation sufficient for:

- floor/blocker topology;
- regions;
- routes/roads required for acceptance;
- terrain/elevation viability;
- compound/spawn anchors;
- required ingress viability;
- story/faction reservations;
- connectivity/playability metrics.

Rejected attempts should die as data without final TileMap painting, runtime nodes, props, streaming setup, shadows, collision bodies, or navigation realization.

### Exit

Accepted seed/world fingerprints remain authoritative and deterministic while rejected-candidate wall time and node churn materially drop against S1.

---

## S4 - Accepted-Candidate Materializer

### Goal

Make the winner transition explicit:

```text
ProcgenCandidate
    -> accepted
    -> materialize structural runtime
    -> final presentation
```

Only the accepted candidate receives runtime TileMap realization, final visual clusters, macro presentation, dressing, props/foliage, wall overlays, shadows, streaming preparation, and navigation.

### Exit

Candidate selection no longer depends on a live near-final `ProcGenTilemap` instance, final worlds match authoritative S1 fingerprints, and accepted-world realization has its own benchmark phase.

---

## S5 - Runtime Mutation Scheduler

### Goal

Coalesce expensive derived-world rebuilds behind one dirty-region transaction authority.

Producers request dirty state for:

- topology;
- collision;
- walkable boundary;
- navigation;
- shadows;
- derived presentation.

They do not independently trigger full rebuilds.

### Exit

One logical mutation batch causes at most one required expensive rebuild per derived system, wall destruction remains exact to the contacted tile, and the ~258 ms navigation hitch class is measurable and reduced or amortized without weakening path correctness.

---

## S6 - Pause-Aware Streaming Prepare / Commit

### Goal

Define explicit procgen pause semantics.

While paused:

- gameplay simulation remains frozen;
- player-driven discovery does not advance;
- enemy/world interaction does not advance;
- already-requested deterministic world preparation may continue through an explicitly pause-capable scheduler;
- gameplay-authoritative topology commits are deferred or explicitly bounded.

On resume, prepared work commits under frame budgets.

### Exit

Pausing never advances gameplay state, but pre-approved background preparation can make the world more ready. Tests prove both halves of the contract.

---

## S7 - Chunk Lifecycle + Cache

### Goal

Replace reveal-only bookkeeping with an explicit deterministic chunk lifecycle:

```text
UNSEEN -> QUEUED -> PREPARED -> VISIBLE -> DORMANT -> UNLOADED
```

Cache reusable chunk payloads such as structural tile data, prop/foliage plans, collision descriptors, and derived-dirty bounds.

### Exit

Reveal/unload/re-reveal is deterministic, avoids recomputing immutable chunk semantics, and distant unload can be enabled only after lifecycle correctness is proven.

---

## S8 - ProcGenTilemap Decomplexification

### Goal

Hollow `ProcGenTilemap` toward a façade/runtime state host after S4 and S7 establish stable seams.

Priority coherent authorities:

1. road generation/repair/surface semantics;
2. authored claims / clearances / reservations;
3. generation level-data/export state.

V1 is already split into D1 road authority, D2 authored-claim registry, D3 generation-state extraction, and D4 façade contraction. D1-D3 are dependency siblings gated by G5+M6 and serialized by the shared procgen-runtime lock; D4 waits for all three.

### Exit

`ProcGenTilemap` materially shrinks, each extracted authority has a narrow API and focused validation, and no extraction changes deterministic output merely to hit a line-count target.

---

## S9 - Contract-World Placement Extraction

### Goal

Reduce `ContractWorldLoader` from world attach + every generated placement policy into lifecycle orchestration plus focused placement services.

V1 is already split into P1 placement foundation; P2 resource, P3 vehicle, P4 ARRN relay, P5 encounter, and P6 authored-ingress sibling extractions; then P7 loader contraction. The siblings share one loader lock and may land in any order after P1. Coordinate with the separate world-lifecycle program so this roadmap does not invent a competing transition manager.

### Exit

Loader owns attach/rebind/activation orchestration, placement services own their domains, and fixed-seed population/ingress placement remains unchanged.

---

## S10 - Renderer / Node-Load Consolidation

### Goal

Use S1/S11-compatible evidence to attack actual procgen presentation cost after generation and streaming architecture are stable.

V1 is split into V1 render attribution and V2 render-load consolidation. Attribution first ranks actual presentation owners; consolidation then touches only the highest-cost compatible presentation-only owners. Candidate techniques include batching/MultiMesh, chunk-level containers, lazy realization, or removal of hidden-but-instantiated presentation, but the attribution report chooses the target rather than this roadmap guessing.

### Exit

Measured node/render/draw pressure materially improves without moving gameplay authority into visibility or presentation systems.

---

## S11 - End-to-End Performance Soak + Regression Budget Gate

### Goal

Run a deterministic production-size sequence covering:

```text
generate
-> accept/materialize
-> spawn
-> traverse/reveal
-> pause/unpause
-> mutate/destruct walls
-> enter/return from authored ingress
-> traverse/re-reveal
```

Compare against the S1 schema on the same class of host/build.

### Exit

The program has durable before/after evidence for generation, runtime hitches, streaming behavior, node/render load, deterministic fingerprints, and relevant focused regressions. Only at this point should stable performance budgets become pass/fail gates.

## Documentation Drift Owned By This Program

The audit that created this roadmap found active documentation drift:

- `custodian/docs/ARCHITECTURE.md` still reports approximate coordinator sizes around `~6000+`, `~800+`, and `~600+`; current measured sizes are 11,221 / 1,216 / 2,001 lines.
- `custodian/docs/ai_context/CONTEXT.md` still says no runtime architecture code has moved, despite live terrain, intent, foliage, diagnostics, presentation, and other focused procgen services.
- `design/02_features/procgen/STREAMING_PROCGEN_REVEAL.md` predates later compact wall bodies, deferred rebuilds, runtime-blocker hardening, and explicit pause-design discussion.

Do not perform a broad prose rewrite in S1. Each implementation slice must correct the statements it makes stale, and S11 must leave architecture/current-state/streaming docs converged with live runtime.

## Historical Work To Preserve

`custodian/docs/ai_context/task_packets/RUNTIME_STUTTER_PERFORMANCE_PASS.md` is completed work, not a replacement for this roadmap. Preserve its successful contracts:

- no periodic global Observatory scans while hidden;
- deferred streaming derived rebuilds;
- shared/bounded foliage work;
- dormant simulation suppression;
- compact runtime wall bodies with exact contacted-tile destruction;
- reduced atmosphere work.

This roadmap begins from those gains rather than reimplementing them.
