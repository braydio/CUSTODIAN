# PROCGEN RUNTIME OPTIMIZATION ROADMAP

**Project:** CUSTODIAN  
**Program ID:** `procgen-runtime-optimization`  
**Roadmap:** Cross-cutting Procgen Runtime Optimization  
**Status:** in_progress  
**Priority:** P1  
**Reviewed main:** `4dcbe371086eb63746df8a6a0a6d96ba3092569c`  
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

## Dependency Graph

```text
S1  Performance baseline + benchmark contract
├── S2  Candidate evaluator extraction
│   └── S3  Semantics-only candidate generation
│       └── S4  Accepted-candidate materializer
│
├── S5  Runtime mutation scheduler
│   └── S6  Pause-aware streaming prepare/commit
│       └── S7  Chunk lifecycle + cache
│
└── S9  Contract-world placement extraction (may proceed after S1 when locks permit)

S4 + S7
   └── S8  ProcGenTilemap decomplexification

S4 + S7 + S8 + S9
   └── S10 Renderer/node-load consolidation
       └── S11 End-to-end soak + regression budget gate
```

S2-S4 and S5-S7 are intentionally separate lanes after S1 so generation work and runtime-streaming work can proceed independently when repository locks/worktrees permit.

## Roadmap Status

| Slice | Workstream | Status | Depends on | Completion evidence |
| --- | --- | --- | --- | --- |
| **S1 Performance Baseline V1** | `procgen-performance-baseline-v1` | **queued** | none | Packet: `custodian/docs/ai_context/task_packets/PROCGEN_PERFORMANCE_BASELINE_V1.md` |
| **S2 Candidate Evaluator Extraction** | `procgen-candidate-evaluator-extraction` | planned | S1 | TBD |
| **S3 Semantics-Only Candidate Generation** | `procgen-semantic-candidate-generation` | planned | S2 | TBD |
| **S4 Accepted-Candidate Materializer** | `procgen-accepted-candidate-materializer` | planned | S3 | TBD |
| **S5 Runtime Mutation Scheduler** | `procgen-runtime-mutation-scheduler` | planned | S1 | TBD |
| **S6 Pause-Aware Streaming** | `procgen-pause-aware-streaming` | planned | S5 | TBD |
| **S7 Chunk Lifecycle + Cache** | `procgen-chunk-lifecycle-cache` | planned | S6 | TBD |
| **S8 ProcGenTilemap Decomplexification** | `procgen-tilemap-decomplexification` | planned | S4, S7 | TBD |
| **S9 Contract-World Placement Extraction** | `contract-world-placement-extraction` | planned | S1 | TBD; coordinate with world-lifecycle work |
| **S10 Renderer / Node-Load Consolidation** | `procgen-render-load-consolidation` | planned | S4, S7, S8, S9 | TBD |
| **S11 End-to-End Performance Soak** | `procgen-performance-soak-v1` | planned | S10 | TBD |

## Roadmap Maintenance Contract

This file is the program tracker for this workstream family.

Every procgen optimization slice must update this roadmap in the same landed change that completes the slice:

1. set the slice status to `complete`, `blocked`, or the truthful current state;
2. replace `TBD` completion evidence with the landed main SHA, closing summary, and high-signal before/after metric;
3. update the **Current Program Position** section;
4. promote the next executable slice from `planned` to `queued` only when its implementation contract is actually ready;
5. mirror the same slice outcome into the `Cross-cutting Procgen Runtime Optimization` table in `design/00_meta/MASTER_ROADMAP.md`; map detailed `queued` to master `planned` until an implementation is actually in progress;
6. add newly discovered work only when it is independently necessary and not already owned by another slice;
7. never rewrite historical slice evidence to make later results look cleaner.

A slice packet is not considered fully closed until this roadmap agrees with live runtime truth.

If an independent review creates a correction packet, keep the original slice `complete` as implementation truth but add the review/correction state in its evidence cell until the review cycle passes.

## Current Program Position

**Current slice:** S1 Performance Baseline V1  
**State:** queued  
**Next gate:** land a reproducible structured generation + streaming benchmark with no gameplay/world-output changes.  
**After S1:** S2 and S5 become the first high-value optimization lanes; S9 may proceed independently if world-lifecycle locks are clear.

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

If those prove independently landable during packet authoring, split S8 into bounded child packets while keeping S8 as the roadmap umbrella.

### Exit

`ProcGenTilemap` materially shrinks, each extracted authority has a narrow API and focused validation, and no extraction changes deterministic output merely to hit a line-count target.

---

## S9 - Contract-World Placement Extraction

### Goal

Reduce `ContractWorldLoader` from world attach + every generated placement policy into lifecycle orchestration plus focused placement services.

Candidate services:

- resources;
- vehicles;
- ARRN relays;
- encounter markers/population;
- authored world ingresses.

Coordinate with the separate world-lifecycle program so this roadmap does not invent a competing transition manager.

### Exit

Loader owns attach/rebind/activation orchestration, placement services own their domains, and fixed-seed population/ingress placement remains unchanged.

---

## S10 - Renderer / Node-Load Consolidation

### Goal

Use S1/S11-compatible evidence to attack actual procgen presentation cost after generation and streaming architecture are stable.

Potential targets are evidence-driven, not preselected:

- unnecessary Sprite2D/node proliferation;
- compatible batching or MultiMesh use;
- hidden-but-instantiated presentation;
- chunk-level presentation containers;
- repeated overlay/material state;
- distant macro-presentation realization.

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
