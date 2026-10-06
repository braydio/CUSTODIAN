# PROCGEN RUNTIME OPTIMIZATION ROADMAP

**Project:** CUSTODIAN  
**Program ID:** `procgen-runtime-optimization`  
**Roadmap:** Cross-cutting Procgen Runtime Optimization  
**Status:** in_progress  
**Priority:** P1  
**Reviewed main:** `efce0c069a5b0fd2ce07013b9a248cde08d26e56`  
**Last Updated:** 2026-10-03  
**Depends on:** none for measurement; slice dependencies below
**Planning refresh chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7

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

D1 measured from `origin/main@047e827f8` (baseline authority snapshot):

| Authority | Current size | Current role |
| --- | ---: | --- |
| `custodian/game/world/procgen/proc_gen_tilemap.gd` | 11,854 lines / 617 funcs / 475,877 chars after D1 | Procgen façade and TileMap-backed generation host; physical road realization and presentation remain here |
| `custodian/game/world/procgen/roads/procgen_road_authority.gd` | 260 lines / 33 funcs / 7,677 chars | Canonical generated road/path/parking/Road Semantics state and graph/component/repair/pruning decisions |
| `custodian/game/world/procgen/custodian_contract_map.gd` | 1,068 lines / 29 funcs / 41,241 chars | Contract seed/profile creation, candidate orchestration, semantic snapshot evaluation, fallback selection, final materialization handoff |
| `custodian/game/systems/core/systems/contract_world_loader.gd` | 2,001 lines / 98 funcs / 79,340 chars | Runtime world attach/rebind plus resource, vehicle, relay, encounter/Vaultwing, ingress, camera/navigation/UI placement orchestration pending P-lane extraction |

Current generation/runtime contracts include:

- candidate orchestration in `custodian/game/world/procgen/custodian_contract_map.gd` evaluates deterministic semantic snapshots of live TileMap-backed candidates through `generation/candidate_evaluator.gd`; the selected candidate is validated by `generation/procgen_candidate_materializer.gd` and realized as a fresh final runtime map rather than reusing the evaluation node;
- candidate evaluation is **not** semantics-only at construction time: rejected attempts still instantiate substantial `ProcGenTilemap`/TileMap/terrain/road working state before the data-only evaluator scores them, which is the GenerationGrid initiative's remaining S3 target;
- normal contract generation allows up to `12` candidate attempts;
- generated maps are typically `160x160` through `224x224`;
- streaming reveal defaults to `16x16` chunks, immediate radius `1`, active radius `2`, `96` tiles/frame, and `0.15 s` derived-visual rebuild cadence;
- distant chunk unload (M6) is now enabled by default: DORMANT-only, distance-hysteretic, protected-anchor-aware, bounded to `1` chunk unloaded per frame, unloading painted presentation/M5 cache residency only while canonical semantics/collision/navigation/foliage identity remain authoritative;
- pause still freezes gameplay/world commits, but M3 `custodian/game/world/procgen/streaming/procgen_pause_aware_streaming.gd` now runs `PROCESS_MODE_ALWAYS` and may PREPARE already-requested reveal records while paused; authoritative TileMap/collision/foliage/navigation COMMIT remains frozen until resume;
- runtime performance work now includes M2 `derived_rebuild_scheduler.gd` request/commit coalescing, M3 pause-aware PREPARE/COMMIT, deferred reveal rebuilds, compact wall bodies, bounded foliage work, shared foliage materials, and mutation gauges;
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

## V1 Dependency-Gated Packet Series

**Series ID:** `procgen-runtime-optimization-v1`  
**Packet series:** stable V1 workstream identities plus three GenerationGrid prelude implementation packets and three paired reviews. Architecture-dependent downstream packets are now explicitly refresh-gated instead of asserting predecessor output before it exists; the measured migration packet count remains deferred to X3 after X1/X2 establish the reviewed post-D surface.  
Architecture/design-sensitive refreshes in this V1 procgen program return to the recorded Planning refresh chat above with the landed predecessor summary/review evidence before the blocked packet is rewritten in place. Execution agents report live drift but do not silently reinterpret those packet boundaries.

**Dispatch contract:** the V1 DAG identities are pre-authored, but packets whose exact implementation contract depends on not-yet-landed measured architecture may be held `blocked` / `manual` until their prerequisite implementation and review establish the real seam. `ready` / `auto` means executable from current live evidence; dependencies, reviews, refresh gates, and locks jointly control eligibility.

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
│               └─ MR4 review-procgen-chunk-lifecycle-state-machine
│                   └─ M5 procgen-chunk-payload-cache
│                       └─ MR5 review-procgen-chunk-payload-cache
│                           └─ M6 procgen-distant-chunk-unload
│                               └─ MR6 review-procgen-distant-chunk-unload [findings]
│                                   └─ M6C1 procgen-distant-chunk-unload-review-corrections-1
│                                       └─ MR6R1 review-procgen-distant-chunk-unload-review-corrections-1
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

G5 + MR6R1
├─ D1 procgen-road-authority-extraction
├─ D2 procgen-authored-claim-registry-extraction
└─ D3 procgen-generation-state-extraction
     \________________________________
                                      \
D1 + D2 + D3
  └─ X1 procgen-generation-data-model-audit
      └─ XR1 review-procgen-generation-data-model-audit
          └─ X2 procgen-generation-grid-foundation
              └─ XR2 review-procgen-generation-grid-foundation
                  └─ X3 procgen-generation-grid-migration-series-authoring
                      └─ XR3 review-procgen-generation-grid-migration-series-authoring
                          └─ [measured migration DAG authored by X3]
                              └─ [reviewed convergence workstream]
                                  └─ D4 procgen-tilemap-facade-contraction

D4 + P7
└─ V1 procgen-render-attribution-v1
    └─ V2 procgen-render-load-consolidation
        └─ F1 procgen-performance-soak-v1
            └─ Q1 review-procgen-runtime-optimization-series-v1
                └─ A1 procgen-runtime-optimization-v2-series-authoring
```

**Correction edge (added by `task-packet-pipeline-execution-hardening-v1`,
landed by `procgen-semantic-candidate-generation-correction-1`):**
`G3 procgen-semantic-candidate-generation` did not fully close S3's Exit
condition (see the G3 Completion Evidence correction note below).
`procgen-semantic-candidate-generation-correction-1` re-derived the true gap
(much larger than a bounded correction — see the active Semantics-First
Generation Data Model Migration entry below) and landed a docs-only correction
rather than the original, infeasible-as-scoped code fix. M2's `Depends on`
reads `M1 + G3-fix`; G3-fix is complete, so M2 is eligible/resumed. The actual
generation-data migration that would fully close S3 is a separate post-D1/D2/D3
initiative and is not an M-lane dependency.

### Single-Agent Serial Auto-Run Order

When the user has authorized one agent/session to run this full series unattended, use this deterministic traversal after each successful `workstream.py finish`:

```text
S1
G1 -> G2 -> G3 -> G4 -> G5
M1 -> M2 -> M3 -> M4 -> MR4 -> M5 -> MR5 -> M6 -> MR6
P1 -> PR1 -> P2 -> P3 -> P4 -> P5 -> P6 -> [refresh P7] -> P7
[refresh D1/D2/D3 after MR6] -> D1 -> D2 -> D3
X1 -> XR1 -> [refresh X2] -> X2 -> XR2 -> [refresh X3] -> X3 -> XR3
[generated measured migration series] -> [refresh D4 to final reviewed convergence] -> D4
V1 -> [refresh V2 from attribution] -> V2 -> F1 -> Q1 -> A1
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
| S7 Chunk lifecycle/cache | M4 + MR4 + M5 + MR5 + M6 + MR6 + M6C1 + MR6R1 |
| S8 ProcGenTilemap decomplexification | D1 + D2 + D3 + X1/XR1 + X2/XR2 + X3/XR3 + measured generated migration DAG + D4 |
| S9 Contract-world placement extraction | P1 + P2 + P3 + P4 + P5 + P6 + P7 |
| S10 Renderer/node-load work | V1 + V2 |
| S11 Final soak/budgets | F1 |
| Whole-series review | Q1 |
| Next-series generation | A1 |

## Packet Status

| Code | Workstream | Status | Depends on |
| --- | --- | --- | --- |
| S1 | `procgen-performance-baseline-v1` | **complete** | none |
| G1 | `procgen-candidate-evaluator-extraction` | **complete** | S1 |
| G2 | `procgen-candidate-semantic-model` | **complete** | G1 |
| G3 | `procgen-semantic-candidate-generation` | **complete** (narrower than originally claimed; see G3 Completion Evidence correction) | G2 |
| G3-fix | `procgen-semantic-candidate-generation-correction-1` | **complete** (docs-only re-derivation; real rewrite is now packetized as the post-D1/D2/D3 X1→XR1→X2→XR2→X3→XR3 GenerationGrid initiative, with measured migration implementation packets intentionally deferred to X3) | review-task-packet-pipeline-execution-hardening-v1 |
| G4 | `procgen-accepted-candidate-materializer` | **complete** | G3 |
| G5 | `procgen-candidate-runtime-path-demolition` | **complete** | G4 |
| M1 | `procgen-derived-rebuild-scheduler-foundation` | **complete** | S1 |
| M2 | `procgen-runtime-mutation-scheduler-cutover` | **complete** | M1 + G3-fix |
| M3 | `procgen-pause-aware-streaming` | **complete** | M2 |
| M4 | `procgen-chunk-lifecycle-state-machine` | **complete** | M3 |
| MR4 | `review-procgen-chunk-lifecycle-state-machine` | **complete — passed, non-blocking-only** | M4 |
| M5 | `procgen-chunk-payload-cache` | **complete** | MR4 |
| MR5 | `review-procgen-chunk-payload-cache` | **complete — passed, optional-improvement-only** | M5 |
| M6 | `procgen-distant-chunk-unload` | **complete — implementation landed** | MR5 |
| MR6 | `review-procgen-distant-chunk-unload` | **complete — findings: R0-01 blocking + R0-02..R0-05 evidence gaps** | M6 |
| M6C1 | `procgen-distant-chunk-unload-review-corrections-1` | **complete — coalescing correction + proof expansion landed** | MR6 |
| MR6R1 | `review-procgen-distant-chunk-unload-review-corrections-1` | **complete — passed; 0 blocking / 0 material gaps; S7 closed** | M6C1 |
| HOTFIX | `contract-world-ingress-spawn-clearance-fix` | **complete / reviewed passed — Operator/Ash-Bell spawn collision fixed** | independent |
| HOTFIX | `contract-world-playable-region-spawn-validity-fix` | **complete / reviewed passed — final Operator spawn must belong to canonical accepted playable component** | prerequisite satisfied; R0-03 full-path proof carried into AR3 validation |
| P1 | `contract-world-placement-foundation` | **complete — accepted-world read context landed** | S1 |
| PR1 | `review-contract-world-placement-foundation-r1` | **ready / auto post-land review** | P1 |
| P2 | `contract-world-resource-placement-extraction` | queued | PR1 |
| P3 | `contract-world-vehicle-placement-extraction` | queued | PR1 |
| P4 | `contract-world-relay-placement-extraction` | queued | PR1 |
| P5 | `contract-world-encounter-placement-extraction` | queued | PR1 |
| P6 | `contract-world-ingress-placement-extraction` | queued | PR1 |
| P7 | `contract-world-loader-contraction` | **blocked / manual refresh gate** | P2+P3+P4+P5+P6 |
| D1 | `procgen-road-authority-extraction` | **implementation complete; paired post-land review next** | G5+MR6R1 |
| D2 | `procgen-authored-claim-registry-extraction` | **blocked / manual refresh gate** | G5+MR6R1 |
| D3 | `procgen-generation-state-extraction` | **blocked / manual refresh gate** | G5+MR6R1 |
| X1 | `procgen-generation-data-model-audit` | queued | D1+D2+D3 |
| XR1 | `review-procgen-generation-data-model-audit` | queued | X1 |
| X2 | `procgen-generation-grid-foundation` | **blocked / manual refresh gate** | XR1 |
| XR2 | `review-procgen-generation-grid-foundation` | queued | X2 |
| X3 | `procgen-generation-grid-migration-series-authoring` | **blocked / manual refresh gate** | XR2 |
| XR3 | `review-procgen-generation-grid-migration-series-authoring` | queued | X3 |
| D4 | `procgen-tilemap-facade-contraction` | **blocked / manual final-convergence gate** | XR3 + future final reviewed migration convergence authored by X3 |
| V1 | `procgen-render-attribution-v1` | queued | D4+P7 |
| V2 | `procgen-render-load-consolidation` | **blocked / manual refresh gate** | V1 |
| F1 | `procgen-performance-soak-v1` | queued | V2 |
| Q1 | `review-procgen-runtime-optimization-series-v1` | queued | F1 |
| A1 | `procgen-runtime-optimization-v2-series-authoring` | queued | Q1 |

Per-packet completion evidence is written into the roadmap during execution. A packet is not considered closed merely because code landed.

## Post-MR6 Presentation Work (separate from the optimization DAG)

The following packets consume the reviewed M6 seam but are **not** part of S7/S8 completion accounting:

- `procgen-region-frame-presentation-foundation` -> paired review: data-driven Region Frame + true exterior CHASM underlay seam.
- Alpine continuation authority: `design/02_features/procgen/ALPINE_PLATEAU_PRESENTATION_ASSET_MANIFEST.md`. AP1 `procgen-alpine-plateau-underlay-assets` is complete/landed. AP2 `procgen-alpine-cliff-presentation-v1` is ready/auto from the registered `alpine-cliff-source-family-v1` Dropbox source-master batch and produces final Gate B at closeout. AP3 `procgen-alpine-surface-plates-v1` remains blocked behind AP2 + Gate C; AP4 `procgen-alpine-environment-cohesion-v1` remains dependency-gated behind AP1-AP3 and adds no new image-art gate.
- `procgen-archive-resolve-presentation-spine` (AR1) -> paired AR1 review -> AR2 shader -> AR3 semantic echo/spawn/reacquisition.

RF1/RFR1 are complete/passed and Region Frame is reviewed-stable. AP1's reviewed Alpine underlay is complete/landed. AP2 now consumes the approved durable source-master batch registered under `CUSTODIAN/asset_batches/_registry/`; its final 26-state Gate B is an AP2 output/closeout receipt. AP3 remains asset-blocked behind Gate C and AP2; AP4 waits on AP1-AP3. AR1/ARR1 are complete/passed. AR2 implementation `085a38a5`, renderer recovery `49e9e1410`, human Dropbox visual approval, and paired review `1cf768f7a` are complete/passed with 0 blocking defects / 0 material evidence gaps; S1 remains `1773840677`. AR3 has now been refreshed in the recorded planning chat and is `ready/auto`. The separate playable-region spawn-validity implementation + fresh review are complete/passed, so AR3's dependency gate is satisfied. Spawn-review R0-03 (no full `_on_contract_generated()` real-compound/registered-ingress proof) is carried into AR3 as an explicit end-to-end integration validation requirement; AR3 may only present an already-valid final runtime spawn and may not re-query/copy spawn validity.

## Roadmap Maintenance Contract

This file is the program tracker for this workstream family.

Every procgen optimization slice must update this roadmap in the same landed change that completes the slice:

1. set the slice status to `complete`, `blocked`, or the truthful current state;
2. replace `TBD` completion evidence with the landed main SHA, closing summary, and high-signal before/after metric;
3. update the **Current Program Position** section;
4. preserve the published V1 workstream identities, but re-derive a downstream packet in place when its prior measured-state assumptions depend on architecture that has not landed yet; do not create duplicate `_v2` packet authorities;
5. mirror the same macro-slice outcome into the `Cross-cutting Procgen Runtime Optimization` table in `design/00_meta/MASTER_ROADMAP.md`; map detailed `queued` to master `planned` until an implementation is actually in progress;
6. add newly discovered V1 work only when it is independently necessary and cannot be owned by an existing packet; otherwise carry it to Q1/A1 for V2 series authoring;
7. never rewrite historical slice evidence to make later results look cleaner.

A slice packet is not considered fully closed until this roadmap agrees with live runtime truth.

If an independent review creates a correction packet, keep the original slice `complete` as implementation truth but add the review/correction state in its evidence cell until the review cycle passes.

## Current Program Position

**Current packet:** RF1/RFR1, AP1, AR1/ARR1, AR2/recovery/review, and the playable-region spawn-validity implementation/review are complete/passed. Alpine AP2 is ready/auto from the registered `alpine-cliff-source-family-v1` Dropbox source-master batch; AP2 produces/verifies final Gate B at closeout. AP3 remains blocked behind AP2 + Gate C; AP4 remains dependency-gated behind AP1-AP3. AR3 is refreshed/ready-auto and claimable now. Placement and decomplexification remain independent lanes.
**State:** S1, G1-G5, M1-M6, MR4, MR5, MR6, M6C1, MR6R1, RF1/RFR1, AP1, AR1/ARR1, AR2/recovery/review, and playable-region spawn validity/review are complete/passed. Alpine Region Frame and underlay are stable; AP2 may proceed from the exact registered source-master batch while AP3/AP4 remain downstream-gated. AR3 planning refresh is complete and its dependencies are satisfied. D1 implementation is complete; D2/D3 remain blocked/manual pending their live refreshes. Placement proceeds independently.
**Next gate:** Claim `procgen-archive-resolve-semantic-echo` now. AR3 must close spawn-review R0-03 with a real `_on_contract_generated()` integration proof, then complete real-renderer/Dropbox human game-feel approval before its paired review. Alpine may proceed independently.
**After G5:** the original generation lane (S2-S4) is closed only for the narrower scope G3 actually delivered. S3's full semantics-first Exit condition is now owned by the packetized post-D1/D2/D3 GenerationGrid initiative above. G5+MR6R1 dependencies are satisfied for D1-D3; D1 implementation is complete and its paired review follows landing, while D2/D3 still require refreshes. Once all three are reviewed/landed, X1→XR1→X2→XR2→X3→XR3 runs. D4 is explicitly blocked/manual until X3's measured migration DAG reaches reviewed convergence.

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

### Completion Evidence

- **Landed main SHA:** `41fde2780` (`procgen candidate evaluator, G1 extraction`).
- **Closing summary:** `PROCGEN_CANDIDATE_EVALUATOR_EXTRACTION_CLAUDE_SUMMARY.md`.
- `CandidateEvaluator` now owns candidate measurement, acceptance/rejection, score, ingress validation, terrain-failure classification, fallback eligibility/ranking, connectivity helpers, and layout debug formatting. `CustodianContractMap` retains deterministic attempt orchestration and winner lifecycle; the metric dictionary schema and reason keys are preserved.
- **Validation:** focused evaluator smoke PASS; rescue diagnostic PASS across 36 candidates and forced-failure abort; terrain-required-cells smoke PASS; S1 quick benchmark PASS; changed-file closeout PASS (7/7 selected tests); `git diff --check` clean.
- **Known independent failure:** candidate-promotion smoke still stops at its previously documented streamed-floor-cell equality assertion (`Promotion exposed additional streamed floor cells`), unchanged in the S1 closeout evidence and outside G1's scope.
- **Next:** G2 `procgen-candidate-semantic-model` is eligible.

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

### G2 Completion Evidence

G2 is the data-only candidate model and adapter seam; it does not by itself
stop constructing near-runtime candidates (that is G3's job, deferred). S3's
own Exit condition above is not yet met until G3 lands.

- **Landed main SHA:** `bd72df6a4` (`procgen candidate semantic model, G2 data-only snapshot + evaluator parity`).
- `custodian/game/world/procgen/generation/candidate_semantic_adapter.gd` builds a `custodian.procgen_candidate_semantic_model.v1` snapshot (walkable-cell topology, elevation-blocked edges, level-data pass-through, pre-computed required-ingress facts, seed identity, stable fingerprint) from an already-generated candidate. `CandidateEvaluator` gained snapshot-mirrored `evaluate_snapshot()`/`measure_snapshot()` functions with identical acceptance/score/terrain-failure policy; the legacy live-Node `evaluate_candidate()`/`measure_candidate()` remain unchanged for comparison. `CustodianContractMap`'s candidate loop now builds the snapshot once per attempt and calls `evaluate_snapshot()`; no evaluator call in that path takes a Node/TileMap reference. Live candidate construction is unchanged (no materializer yet, per non-goals).
- **Validation:** new `procgen_candidate_semantic_model_smoke.gd` PASS across S1 fixed seeds 420777/420779/771923 — snapshot fingerprints stable across two independent builds of the same candidate, and `evaluate_snapshot()` results (accepted, score, terrain_failed, full metrics dict including rejection reasons and required-ingress facts) match `evaluate_candidate()` exactly for every seed. G1's `procgen_candidate_evaluator_smoke.gd`, `procgen_contract_rescue_diagnostic_smoke.gd` (36/36 seeds), and `procgen_terrain_required_cells_smoke.gd` all PASS unchanged. S1 `procgen_performance_baseline_quick` PASS, `determinism_ok: true`. Changed-file closeout PASS (4/4 selected tests); `git diff --check` clean.
- **Known independent failure:** `procgen_candidate_promotion_smoke.gd` still fails on the same pre-existing streamed-floor-cell equality assertion documented in S1/G1; unrelated to and unchanged by this diff.
- **Next:** G3 `procgen-semantic-candidate-generation` is eligible.

### G3 Completion Evidence

> **Correction (`task-packet-pipeline-execution-hardening-v1` postmortem):**
> the line below overstated what G3 actually closed. G3 gates three
> *presentation/collision rebuild* functions behind `generation_evaluation_mode`
> inside an already-instantiated `ProcGenTilemap`; it does **not** stop
> production from instantiating a live `ProcGenTilemap` for every rejected
> candidate attempt before the semantic snapshot is built. S3's Exit condition
> is therefore **not yet met**.
>
> **Second, deeper correction (`procgen-semantic-candidate-generation-correction-1`
> re-derivation):** the first correction above still understated the gap.
> Direct inspection of `custodian_contract_map.gd` and `proc_gen_tilemap.gd`
> found that `ProcGenTilemap._fill_tilemaps()` — the function every candidate
> attempt runs, gated or not — is not a thin presentation layer over a
> separate pure-data generator. Its ~40 helper functions (substrate fill,
> compound/interior/spawn layout, road carving, terrain/elevation building,
> biome classification, macro-presentation planning, dressing clusters) use
> the `floor_tilemap`/`walls_tilemap` `TileMapLayer` nodes as the generation
> algorithm's own working data structure: 147 direct TileMapLayer
> cell-operation call sites across an 11,325-line file. (`ProcGen` itself,
> `procgen.gd`'s room/corridor/cellular-automaton algorithm, genuinely is
> already pure-data and TileMap-free — it only produces the room/corridor
> skeleton; everything that turns that skeleton into the walkable/route/
> terrain/region facts `CandidateEvaluator` actually scores happens inside
> `_fill_tilemaps()` against live TileMapLayer cells.) True semantics-first
> candidate construction therefore requires extracting that generation
> pipeline's working representation from TileMapLayer cell operations to a
> plain data grid throughout — a rewrite comparable in scope to the entire
> G1-G5 generation lane already completed, not a narrow correction. See
> **Future Program Entry: Semantics-First Generation Pipeline Rewrite**
> below, where this is now tracked as its own properly-sized future
> initiative rather than a bounded correction.
>
> `procgen-semantic-candidate-generation-correction-1`
> (`PROCGEN_SEMANTIC_CANDIDATE_GENERATION_CORRECTION_1.md`) itself is
> docs-only and complete: it performed this re-derivation and recorded it
> here rather than attempting the rewrite. `procgen-runtime-mutation-
> scheduler-cutover` (M2) depends on that workstream's completion (not on
> the rewrite itself landing) so the gap stays visible in the serial run
> rather than silently skipped. The original (overstated) G3 claim is
> preserved below for history.

#### Active Program Entry: Semantics-First Generation Data Model Migration

**Status:** packetized through the point current evidence supports. **Not an
M-lane dependency.** This initiative now sits inside the S8 decomplexification
path after D1/D2/D3 and before D4.

The architecture ruling from `procgen-semantic-candidate-generation-correction-1`
remains authoritative:

- pre-D-lane `ProcGenTilemap._fill_tilemaps()` and roughly 40 helpers used
  `floor_tilemap` / `walls_tilemap` `TileMapLayer` nodes as generation
  working memory, with 147 direct cell-operation call sites across the then
  11,325-line file;
- `procgen.gd` is already pure-data for the initial room/corridor/automaton
  skeleton;
- G2's semantic model/evaluator is already Node-free after the snapshot exists;
- therefore true semantics-first candidate construction requires replacing the
  downstream generation working representation, not merely skipping final
  presentation/collision calls.

**Architecture ordering:** D1 roads, D2 authored claims, and D3 accepted
generation-state/export extraction run first. Their purpose is to remove known
coherent domains before this rewrite sizes the remaining generation core.
D4 is no longer allowed to follow D1/D2/D3 directly.

**Published packets:**

1. `procgen-generation-data-model-audit` — re-measure the post-D1/D2/D3
   `_fill_tilemaps()` call graph, account for every remaining generation-time
   TileMapLayer cell operation, classify semantic vs presentation/runtime state,
   and define the minimum GenerationGrid contract and coherent migration graph.
2. `review-procgen-generation-data-model-audit` — independently verify the
   inventory is complete and non-speculative.
3. `procgen-generation-grid-foundation` — implement the reviewed neutral
   GenerationGrid contract and a behavior-preserving TileMap-backed compatibility
   backend, with only the smallest safe canary integration if the audit proves one.
4. `review-procgen-generation-grid-foundation` — verify the seam is semantic,
   minimal, deterministic, and not a TileMap API in disguise.
5. `procgen-generation-grid-migration-series-authoring` — use those two reviewed
   artifacts to author the remaining helper-cluster migration DAG, pure-data
   backend/parity, production rejected-candidate cutover, legacy-path demolition,
   and final rejection-heavy convergence.
6. `review-procgen-generation-grid-migration-series-authoring` — verify one
   owner per audited cluster and keep D4 blocked until the generated reviewed
   convergence workstream completes.

**Why packet authoring intentionally stops there today:** the exact post-D1/D2/D3
helper clusters do not yet exist as measured facts. Pre-authoring their
implementation packets now would repeat the same mistake that created the
over-scoped G3 correction. X3 is the bounded handoff that authors those packets
only after X1/X2 establish the real post-extraction surface.

**D4 gate:** `procgen-tilemap-facade-contraction` is now `blocked/manual`.
X3/XR3 must update D4 with the final reviewed convergence workstream dependency
and restore it to ready/auto only after the generated migration DAG is fully
specified. The migration series itself must keep D4 blocked until convergence
actually lands.


G3 lands S3's Exit condition: rejected eval-mode candidates no longer pay
for final-presentation/collision realization; accepted seed/world
fingerprints remain authoritative and deterministic.

- **Landed main SHA:** `3f729650d` (`procgen semantic candidate generation, G3 skip eval-mode realization`).
- Three purely presentation/collision phases inside `_fill_tilemaps()` — `_rebuild_runtime_wall_collision()` (O(map_size) physics-body creation, only reachable when `build_runtime_wall_collision` is true, which candidate attempts never override), `_rebuild_nonwalkable_surface_visuals()` (ocean/shoreline decal + coastline-presentation node instantiation), and `_rebuild_runtime_walkable_boundary()` (physics boundary body) — are now gated behind `not generation_evaluation_mode`, so every rejected attempt in `CustodianContractMap`'s candidate loop skips them entirely. None of the three ever wrote to `level_data` or any field `CandidateEvaluator` reads (verified by direct function-body inspection), so evaluation and acceptance are unaffected. `_apply_sundered_keep_frontage_floor_visuals()` was investigated as a fourth candidate but reverted to unconditional: it repaints existing floor cells' tile source/atlas/alternative, which is part of the accepted-candidate floor fingerprint contract `procgen_candidate_promotion_smoke.gd` enforces, and deferring it changed that fingerprint (caught immediately by that smoke, see Process Feedback below). The accepted winner still receives `_rebuild_nonwalkable_surface_visuals()` and `_rebuild_runtime_walkable_boundary()` via new calls added to `promote_evaluated_candidate_to_final()`; it already received wall collision through `_prepare_streaming_reveal()`'s own `_sync_runtime_wall_collision_with_visible_walls()` mechanism (streaming reveal defaults on and is never disabled for candidates), which was previously redundant with the eval-mode `_rebuild_runtime_wall_collision()` call this change removes.
- **Validation:** `procgen_candidate_semantic_model_smoke.gd` (G2), `procgen_candidate_evaluator_smoke.gd`, `procgen_contract_rescue_diagnostic_smoke.gd` (36/36 seeds, ok), and `procgen_terrain_required_cells_smoke.gd` all PASS unchanged. S1 quick and full benchmarks PASS, `determinism_ok: true`; all 3 full-profile contract cases still accept on attempt 1/12 with loop/promotion timings within normal host variance of the S1/G2 baseline (24550/31267/11741 ms loop vs S1's 25201/32399/12637 ms). Changed-file closeout PASS (14/14 selected tests); `git diff --check` clean.
- **Rejected-attempt timing evidence:** the S1 fixed-seed corpus and `procgen_contract_rescue_diagnostic_smoke.gd`'s 36 seeds accept almost every candidate on attempt 1/12, so genuine multi-attempt rejection inside a single contract is rare in the existing test corpus. The one available same-seed before/after data point (the diagnostic's forced max-attempts=1 rejection case, 176x176) shows `generate` time dropping from 21.4s (G2 baseline) to 20.8s (this change), a modest ~2.8% reduction consistent with removing O(map_size) collision/boundary work; the stronger, architecture-level guarantee is that the three functions above provably do not execute at all during any rejected eval-mode attempt, regardless of map size or wall count, which is the acceptance contract this packet actually specifies ("rejected attempts show zero final presentation/nav/collision/streaming realization"). A future soak (S11) with a rejection-heavy fixed corpus would make the aggregate wall-time delta more visible than this test suite currently can.
- **Known independent failure:** `procgen_candidate_promotion_smoke.gd` still fails on the same pre-existing streamed-floor-cell equality assertion documented in S1/G1/G2; unrelated to and unchanged by this diff (confirmed identical failure message/line before and after).
- **Next:** G4 `procgen-accepted-candidate-materializer` is eligible.

### G4 Completion Evidence

G4 lands S4's explicit accepted-candidate handoff. The candidate loop retains
only the selected semantic snapshot, evaluation, acceptance mode, deterministic
seed/profile/configuration, and materialization settings. It disposes each
evaluation map, then creates a fresh final map and calls the materializer once.
The materializer verifies the accepted semantic fingerprint against the final
runtime snapshot and records its S1-compatible runtime fingerprint, floor/wall
counts, ordered generation phases, timings, and invocation count.

- **Landed main SHA:** `b2e4d9409` (`procgen accepted candidate materializer, G4 handoff`).
- **Closing summary:** `PROCGEN_ACCEPTED_CANDIDATE_MATERIALIZER_CLAUDE_SUMMARY.md`.
- **S1 quick:** PASS, `determinism_ok: true`; duplicate 48x48 seed-420777
  generation fingerprints were both `1773840677`. The contract case accepted
  attempt 0 and materialized final runtime fingerprint `2884730602`.
- **S1 full:** PASS, `determinism_ok: true`; all nine 160/192/224 fixed-size
  seed cases completed with stable fingerprints and their authoritative
  floor/wall counts. Three contract cases accepted attempt 0/12 and each
  recorded one materialization invocation, a verified semantic fingerprint,
  and a final runtime fingerprint: seed 420777 `2884730602` (10212 floors,
  951 walls), 420779 `392435093` (10372 floors, 805 walls), and 771923
  `1672459047` (6317 floors, 1058 walls). Full materialization durations were
  39837, 51489, and 20333 ms. Runtime case: 192x192 seed 420777, 7.006 ms
  average over 60 samples, 25 chunks revealed, queue peak 362.
- **Parity smoke:** PASS; accepted semantic topology, terrain, ocean/chasm
  semantics, and final floor/wall positions match. A second fresh materializer
  run reproduced the S1 runtime fingerprint. Runtime invocation and structural
  materialization counts were both exactly one per output map.
- **Validation:** candidate evaluator, semantic model, spatial normalization,
  terrain required cells, road semantics v2, ingress spawner, S1 quick, and the
  materializer parity smoke all PASS. Changed-file closeout PASS (19/19 tests,
  complete ownership coverage). The ambient real-world spawn case exceeded its
  former 90-second timeout while completing the new final realization; its
  timeout was raised to 180 seconds and the full sweep passed in 106.6 seconds.
  `git diff --check` clean.
- **Process feedback:** the repeatable medium-severity validation timeout was
  corrected in `validation_manifest.json`; changed-file validation also found
  that the new parity smoke/materializer lacked an owner mapping, so the focused
  smoke was registered and the final coverage-complete sweep passed. The
  promotion smoke's obsolete cross-map streamed-paint count assumption was
  removed because fresh maps legitimately begin at different reveal progress.
  See the closing summary.
- **Next:** G5 `procgen-candidate-runtime-path-demolition` is eligible.

---

## S4 - Accepted-Candidate Materializer

**G4 status:** complete. **G5 status:** complete. S4 is fully landed.

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

### G5 Completion Evidence

- **Landed main SHA:** `38acd2a8c` (`procgen candidate runtime path demolition, G5 retire in-place promotion`).
- Deleted the superseded in-place promotion path entirely: `ProcGenTilemap.promote_evaluated_candidate_to_final()` (public compatibility wrapper) and `_finalize_accepted_candidate_to_final()` (its ~100-line body) are removed. `materialize_accepted_candidate()` — G4's fresh-generation materializer entry point — is now the only accepted-candidate realization path; `CustodianContractMap.generate_contract()` already routed through it before this packet, so no production call site changed.
- Migrated the deleted function's last two callers to the canonical pipeline: `tools/validation/procgen_dressing_cluster_review.gd` now builds a semantic snapshot from its eval-mode candidate and materializes onto a fresh second `ProcGenTilemap` instance (matching `CustodianContractMap`'s own flow) instead of promoting the candidate in place; `tools/validation/procgen_macro_presentation_smoke.gd`'s `_validate_pipeline_order()` now proves the macro -> dressing-clusters -> foliage phase ordering once, inside `_fill_tilemaps()`'s own final-mode branches, instead of re-checking it inside the now-deleted promotion function's separate source block.
- Left the small `get_last_promotion_timing_snapshot()` alias in place (delegates to G4's `get_last_materialization_timing_snapshot()`) rather than deleting it: it is load-bearing for the `custodian.procgen_performance_baseline.v1` benchmark schema's `"promotion"` field, and this packet's own Preserve clause covers benchmark schema.
- **Validation:** `procgen_candidate_promotion_smoke.gd`, `procgen_candidate_semantic_model_smoke.gd`, `procgen_candidate_evaluator_smoke.gd`, `procgen_macro_presentation_smoke.gd` (edited), `procgen_contract_rescue_diagnostic_smoke.gd` (36/36 seeds), and `procgen_terrain_required_cells_smoke.gd` all PASS. S1 quick and full benchmarks PASS, `determinism_ok: true`; all 3 full-profile contract cases reproduced G4's exact documented fingerprints byte-for-byte (`2884730602`, `392435093`, `1672459047`), proving the deletion changed no accepted-world output. Changed-file closeout PASS (17/17 selected tests); `git diff --check` clean. `procgen_dressing_cluster_review.gd`'s baseline capture pass fails under plain `--headless` (no rendering device for `viewport.get_texture()`); this is a pre-existing limitation of that non-gating review tool unrelated to this change — it fails before reaching the migrated code, and the tool is not a `validation_manifest.json` entry.
- **Next:** Generation lane (G1-G5) is fully closed. The runtime/streaming lane is currently at ready M6 followed by MR6, while placement proceeds independently from P1/PR1. D1-D3 wait on G5+MR6; D4 remains downstream of the reviewed GenerationGrid convergence.

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

### M1 Foundation — Complete

`ProcGenDerivedRebuildScheduler` is the shared dirty-request ledger for topology,
collision, walkable boundary, navigation, shadows, and presentation. Requests
carry stable reason and region data, coalesce repeated requests by explicit
logical batch, and report requested/coalesced/committed counts plus cumulative
commit duration. `ProcGenTilemap` adapters register the existing rebuilds and
preserve their commit timing; rebuild implementations remain in their original
owners. Navigation retains its existing deferred flush and batch identity.

- **Landed main SHA:** `fd8c6241b` (`procgen derived rebuild scheduler, M1 foundation`).
- **Closing summary:** `PROCGEN_DERIVED_REBUILD_SCHEDULER_FOUNDATION_CLAUDE_SUMMARY.md`.
- **Evidence:** scheduler smoke proves duplicate collision requests in one batch coalesce to one deterministic region with sorted reasons (2 requested, 1 coalesced, 1 committed); runtime-health smoke proves connector topology, boundary, navigation, shadow, and presentation requests/commits and durations are exposed. `runtime_wall_collision_compaction_smoke.gd`, `navigation_elevation_smoke.gd`, and S1 quick pass; S1 reports `determinism_ok=true` with matching 48x48 seed-420777 fingerprints (`1773840677`). No performance reduction is claimed at M1 because rebuild commit timing was deliberately preserved.
- **Next:** M2 `procgen-runtime-mutation-scheduler-cutover` is eligible; broader producer cutover and commit batching remain there.

### M2 Cutover — Complete

`_rebuild_runtime_walkable_boundary` and `_refresh_shadows` now mirror
navigation's existing dirty-flag/`call_deferred` pattern: a request marks the
scheduler batch dirty and only the first request in a batch schedules the
actual rebuild, so repeated producers (connector commits, streaming-reveal
flushes) within one engine frame collapse into a single rebuild and a single
scheduler commit. `_claim_isolated_world_overlook_pocket` opts into an
explicit `flush_now` synchronous path because its caller queries walkability
on the pocket the instant the call returns (proven by
`ash_bell_threadway_causeway_smoke.gd`'s pre-Knot frontier check). Shadow
regeneration itself was already coalesced inside `shadow_system.gd`
(`_regeneration_queued` + its own deferred call); the cutover only makes the
scheduler ledger's commit count match that existing coalescing instead of
reporting one commit per caller. Full wall-collision rebuild
(`_rebuild_runtime_wall_collision`) was measured to have exactly one call site
(initial generation) with no second producer to coalesce against, so it is
left synchronous and unmigrated — there is no batching opportunity there yet.

- **Landed main SHA:** `0ca95441d` (`procgen runtime mutation scheduler cutover, batch walkable boundary and shadow rebuilds`).
- **Closing summary:** `PROCGEN_RUNTIME_MUTATION_SCHEDULER_CUTOVER_CLAUDE_SUMMARY.md`.
- **Evidence:** `procgen_derived_rebuild_scheduler_smoke.gd`, `procgen_walkable_boundary_smoke.gd`, `procgen_runtime_health_smoke.gd`, `ash_bell_threadway_causeway_smoke.gd`, `ash_bell_threadway_generation_contract_smoke.gd` (seeds=16), `runtime_wall_collision_compaction_smoke.gd` (19 bodies/443 shapes, matches M1 baseline), `procgen_stuck_pocket_smoke.gd`, `navigation_elevation_smoke.gd`, `compound_wall_smoke.gd`, `compound_road_wall_smoke.gd`, `procgen_authored_scene_authority_smoke.gd`, and `procgen_road_surface_roles_smoke.gd` all pass. S1 quick pass reports `determinism_ok=true` with the same 48x48 seed-420777 fingerprint (`1773840677`) as M1, confirming no deterministic-output regression. S1's runtime-streaming case shows real request>commit coalescing for the first time: `shadows`/`presentation` 5 requested → 1 committed (4 coalesced), `navigation` 2 requested → 1 committed (1 coalesced, unchanged from M1); `walkable_boundary`/`collision`/`topology` were not exercised by that particular scripted scenario (0 or 1 requested, no repeat caller in-batch).
- **Next:** M3 `procgen-pause-aware-streaming` is eligible.

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

### M3 Pause-Aware Streaming — Complete

`ProcGenPauseAwareStreaming` (`custodian/game/world/procgen/streaming/procgen_pause_aware_streaming.gd`)
is the single PREPARE/COMMIT owner for already-requested streaming-reveal
work. `ProcGenTilemap` keeps owning tile/world semantics (TileMap cells,
foliage, collision, decals) and the shared `_streaming_reveal_queue` field;
it delegates queueing/draining to the new authority through two narrow
Callables (a pure build-record lookup, a mutating commit-record
application). While `SceneTree.paused` is true, the authority's own
`PROCESS_MODE_ALWAYS` tick budgets deterministic build-record calls for
tiles already queued before pause, without mutating live
TileMap/collision/navigation/foliage state and without enqueueing new
player-driven discovery (the only producer already lives in
`ProcGenTilemap`'s own pause-gated `_process`; a defense-in-depth guard was
also added directly to `_update_streaming_chunks`). On resume,
`drain_commit` applies prepared records first in original order, then any
remaining queued tiles, under the existing per-frame reveal budget --
identical to the pre-M3 unpaused path whenever nothing was ever prepared, so
normal (never-paused) streaming is unchanged. M2's explicit `flush_now`
synchronous exception for `_claim_isolated_world_overlook_pocket` was left
untouched.

- **Landed main SHA:** `7c2749508` (`procgen pause aware streaming, M3 PREPARE/COMMIT authority`).
- **Closing summary:** `PROCGEN_PAUSE_AWARE_STREAMING_CLAUDE_SUMMARY.md`.
- **Evidence:** New `procgen_pause_aware_streaming_smoke.gd` proves, in one scenario: authoritative floor topology, navigation completion count, walkable-boundary rebuild count, and wall rebuild count are all unchanged across 6 paused ticks; PREPARE's `prepared` counter advances for already-queued tiles while paused with zero duplication/loss against the queue; COMMIT stays at zero while paused; resume commits a bounded (<= `streaming_reveal_tiles_per_frame`) slice on its first unpaused frame, takes multiple frames to fully drain, records the resume transition exactly once, and ends with `requested == committed` (no duplicate/missing commits); the M2 navigation scheduler shows a small coalesced commit count relative to drained frames, not one-per-tile. `procgen_derived_rebuild_scheduler_smoke.gd`, `procgen_walkable_boundary_smoke.gd`, `procgen_runtime_health_smoke.gd`, and `ash_bell_threadway_causeway_smoke.gd` (the `flush_now` regression) all pass unchanged. S1 quick reports `determinism_ok=true` with the same 48x48 seed-420777 fingerprint (`1773840677`) as M1/M2, confirming no deterministic-output regression. `procgen_candidate_promotion_smoke.gd` was run informationally only (per this packet's explicit non-gate instruction) and passed.
- **Process note:** `dispatch.py`'s structural validation-reference gate initially deadlocked this claim because this packet's own `Work surface` required authoring the exact smoke script the gate also required to already exist on `origin/main`; a user-approved placeholder stub unblocked the claim, then the real smoke replaced it inside the workstream. The gate behavior itself is unchanged and will reproduce for any future packet introducing a brand-new validation script — see this packet's archived `Execution Feedback` for the open follow-up.
- **Next:** M4 `procgen-chunk-lifecycle-state-machine` is eligible.

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

### M4 Chunk Lifecycle State Machine — Complete + MR4 Passed

`ProcGenChunkLifecycle` (`custodian/game/world/procgen/streaming/procgen_chunk_lifecycle.gd`)
is the single owner of per-chunk lifecycle state: `UNSEEN -> QUEUED ->
PREPARED -> REVEALING -> VISIBLE -> DORMANT -> UNLOADED`. It replaces
`_revealed_chunks`/`_queued_chunks`, which were not truthful: they marked a
chunk "revealed" the instant its tiles were enumerated for queueing, before
any tile actually committed. `ProcGenTilemap`'s chunk adapters
(`_queue_chunk_for_reveal`, `_reveal_chunk_immediately`, `_update_streaming_chunks`,
`_unload_chunk`) now register/query chunk state through this authority instead
of the old dictionaries, and `_get_chunk_tiles()` is pure enumeration with no
side effects. `ProcGenPauseAwareStreaming` (M3) gained two narrow optional
progress callbacks (`on_tile_prepared`/`on_tile_committed`) so the lifecycle
authority learns tile-level PREPARE/COMMIT progress without M3 knowing
anything about chunk semantics, and without a second tile queue. `_is_tile_
currently_visible()` was repaired to query canonical painted-cell TileMap
state directly (exact per-tile truth even while its chunk is REVEALING)
instead of chunk-level membership. Production automatic unload stays
disabled (`streaming_unload_distant_chunks` defaults false); `UNLOADED` is
reachable only through that already-gated path; re-requesting an `UNLOADED` chunk is already a valid mechanism, while M6
owns the real reload policy.

- **Landed main SHA:** `6588093c2` (`procgen chunk lifecycle state machine, M4 ProcGenChunkLifecycle authority`).
- **Closing summary:** `PROCGEN_CHUNK_LIFECYCLE_STATE_MACHINE_CLAUDE_SUMMARY.md`.
- **Evidence:** New `procgen_chunk_lifecycle_smoke.gd` proves deterministic state progression for queued unpaused reveal, pause PREPARE -> resume commit, immediate reveal, a zero-content chunk, active-radius exit to DORMANT and re-entry to VISIBLE without duplicate work, and the debug-only UNLOADED seam, plus illegal-transition detection and idempotent re-requests. `procgen_pause_aware_streaming_smoke.gd`, `procgen_candidate_promotion_smoke.gd` (restored to required regression status -- its obsolete strict streamed-floor assertion is gone), `procgen_runtime_health_smoke.gd`, `procgen_walkable_boundary_smoke.gd`, `procgen_macro_presentation_smoke.gd`, and `procgen_road_semantics_v2_smoke.gd` all pass unchanged (the last required one small fix: it used to poke `_revealed_chunks` directly to fake residency before testing unload/re-reveal, now calls the real `_reveal_chunk_immediately` adapter instead). S1 quick reports `determinism_ok=true` with the same fixed-seed fingerprint as M1-M3, confirming no deterministic-output regression. `procgen_performance_baseline_bench.gd`'s and `procgen_performance_snapshot.gd`'s external `_revealed_chunks`/`_queued_chunks` telemetry reads were migrated to the new `ProcGenTilemap.get_resident_chunk_count()`/`get_pending_chunk_count()` public API.
- **Next:** MR4 passed; M5 and MR5 are now complete. M6 is refreshed and ready, with MR6 required after M6 lands.

### M5 Chunk Payload Cache — Complete + MR5 Passed

`ProcGenChunkPayloadCache` (`custodian/game/world/procgen/streaming/procgen_chunk_payload_cache.gd`)
is a plain-data, generation-scoped, invalidatable `RefCounted` cache behind
`ProcGenTilemap`'s existing chunk-membership enumeration and tile PREPARE-
record construction. `ProcGenTilemap` still owns canonical floor/wall
semantics, M3 (`ProcGenPauseAwareStreaming`) still owns the only tile queue/
PREPARE-COMMIT lifecycle, and M4 (`ProcGenChunkLifecycle`) still owns the only
chunk lifecycle; the cache only accelerates reusable derived reads. Chunk
tile membership (`_get_chunk_tiles()`'s own deterministic order) and per-tile
floor/wall PREPARE records are lazily cached and reused on repeated/re-reveal
access; live `_streaming_reveal_priority()` is never cached, so queued order
is still always recomputed from the current `center_tile`. Exact invalidation
was derived from a full inventory of every live write/erase of
`_generated_floor_cells`/`_generated_wall_cells`: a true generation/streaming-
reset boundary does a full cache reset (`_prepare_streaming_reveal()`), and
every post-cache semantic mutation -- wall destruction (`damage_wall_tile`),
neighbor wall repaint (`_refresh_wall_neighbors`), authored-scene/world-
overlook claims, and the handful of shared low-level floor/wall authority
setters every write site (including late-generation finalization passes that
run after streaming priming) funnels through -- precisely invalidates only
its own tile's chunk. A PREPARE record is stamped with the generation/chunk-
revision identity it was built under, so `_commit_tile_reveal_record()`
revalidates it immediately before authoritative mutation and rebuilds it from
canonical state if it went stale after PREPARE but before COMMIT, even if
M3's `_prepared` queue is still holding the old Dictionary. COMMIT-time
dynamic effects (road/surface decals, dressing/foliage, runtime wall
collision, overlays/shadows/navigation/macro visibility) are never cached.
Deterministic telemetry (cached chunk/record counts, hit/miss/invalidation/
stale-refresh counts, reset/generation id) is exposed through
`ProcGenTilemap.get_runtime_health_snapshot()` and a new
`debug_get_chunk_payload_cache_snapshot()` seam. M5 implements no eviction/
unload/hysteresis policy; `streaming_unload_distant_chunks` stays false and
M6 is not unblocked by this packet alone.

- **Landed main SHA:** `91ea694f4` (`procgen chunk payload cache, M5 ProcGenChunkPayloadCache authority`).
- **Closing summary:** `PROCGEN_CHUNK_PAYLOAD_CACHE_CLAUDE_SUMMARY.md`.
- **Evidence:** New `procgen_chunk_payload_cache_smoke.gd` proves (against a live `ProcGenTilemap`): lazy population (an untouched chunk has no entry until first access); miss->hit reuse for both chunk membership and per-tile PREPARE records; dynamic reveal order recomputed from a live `center_tile` over reused cached membership; a debug unload/re-reveal round trip producing cache hits with zero rebuilds when no semantic mutation occurred; wall-destruction invalidation (`damage_wall_tile`) restoring the destroyed floor and never resurrecting the wall across unload/re-reveal; authored-scene floor-claim invalidation reloading the new region truth; a stale PREPARE record (captured before a wall was destroyed, exactly like one still sitting in M3's `_prepared` queue) being detected and refreshed immediately before COMMIT instead of resurrecting the destroyed wall; presentation/telemetry-only reads never spuriously invalidating; and generation-scoped reset separating cache state across a regeneration. `procgen_chunk_lifecycle`, `procgen_pause_aware_streaming`, `procgen_runtime_health`, `procgen_walkable_boundary`, `runtime_wall_collision_compaction`, `procgen_candidate_materializer_parity`, `procgen_macro_presentation`, `procgen_road_semantics_v2`, and `procgen_dressing_clusters` all pass unchanged via `run_validation.py --test`; `procgen_authored_scene_authority_smoke.gd` passes via direct invocation (still unregistered in the manifest). S1 quick reports `determinism_ok=true` with the same fixed-seed fingerprint (`1773840677`) as M1-M4, confirming no deterministic-output regression. A full `run_validation.py --changed` sweep (25 selected tests) and `git diff --check` are both clean.
- **Next:** MR5 passed with 0 blocking defects / 0 material evidence gaps and one optional cache-memory-shape finding (`R0-01`) folded into M6. M6 `procgen-distant-chunk-unload` is now refreshed/ready; paired MR6 is the next runtime correctness gate after implementation.

### M6 Distant Chunk Unload — Complete, MR6 Pending

`ProcGenChunkResidencyPolicy` (`custodian/game/world/procgen/streaming/procgen_chunk_residency_policy.gd`)
is a new plain-data `RefCounted` that owns only an eviction-candidate
coordinate queue and telemetry counters. It never touches TileMap/Node/
collision/foliage state and never calls into M4's lifecycle or M5's cache
directly: `ProcGenTilemap` supplies an already-DORMANT-filtered chunk list
and a protected-chunk set on every player-chunk transition
(`refresh_candidates()`), drains at most `streaming_unload_chunks_per_frame`
(default `1`) farthest-first/coordinate-stable candidates per frame
(`take_candidates()`), and revalidates each one's live state/distance/
protection immediately before actually unloading it -- a candidate that
fails revalidation (player returned, chunk left DORMANT, or it became
protected) is reported cancelled rather than evicted. `_unload_chunk()` is
now a pure presentation/cache residency adapter: it erases painted Floor/
Walls cells, streaming-hides (never destroys/rerolls) existing foliage nodes
via two tiny new helpers (`_hide_foliage_for_unload()`/
`_show_foliage_if_hidden()`) that preserve exact node identity, trunk
collision, and runtime-blocker registration, removes deterministic road/path
decal nodes, and evicts the M5 cache's new `evict_chunk()` (closing MR5's
`R0-01` memory-shape finding via a per-chunk reverse tile-record index,
without bumping cache generation/revision since eviction is not a semantic
event). Canonical `_generated_floor_cells`/`_generated_wall_cells`, wall
health, region/elevation/road semantics, runtime prop blockers, and world
mutations all remain untouched by unload.

Wall collision is no longer tied to presentation:
`_sync_runtime_wall_collision_with_visible_walls()`'s cleanup pass now
removes a shape only when canonical `_generated_wall_cells` no longer
contains that tile, never merely because the wall is unpainted, so collision
survives visual unload and only genuine semantic wall destruction removes
it. Navigation authority for a previously-revealed chunk now also survives
unload: `ProcGenChunkLifecycle.get_unloaded_chunks()` plus two new
`ProcGenTilemap` provider methods (`get_runtime_navigation_floor_cells()`,
`is_runtime_navigation_walkable()`, both delegating to existing canonical/
runtime-blocker authority, never painted visibility) let
`NavigationSystem._build_navigation_graph()`/`_is_walkable()` use the
provider when available and fall back to the old TileMap-used-cells path
otherwise. A narrow streaming-paint guard (the pre-existing
`_is_tile_currently_visible()` helper, already correctly inert during
initial generation via its `enable_streaming_reveal` check) was threaded
through every M5-inventoried shared floor/wall mutation setter so semantic
writes (including `damage_wall_tile()` now recognizing canonical wall
authority instead of requiring the tile to be painted) still occur on an
UNLOADED tile but its visual repaint is deferred to reload COMMIT, which
already revalidates/repaints from canonical state. Protected chunks (player
spawn, portal-teleporter endpoints, compound-ingress chunks, and world-
ingress dressing-clearance chunks) are excluded from eviction entirely.
`streaming_unload_distant_chunks` now defaults `true`.

- **Landed main SHA:** `9fe8cd4d6` (`procgen distant chunk unload, M6 ProcGenChunkResidencyPolicy authority`).
- **Closing summary:** `PROCGEN_DISTANT_CHUNK_UNLOAD_CLAUDE_SUMMARY.md`.
- **Evidence:** New `procgen_distant_chunk_unload_smoke.gd` proves the pure policy's eligibility/ordering/protection/cancellation fixture, plus a live `ProcGenTilemap` round trip: bounded per-frame eviction, protected-chunk rejection, stale-candidate cancellation when the player returns, M5 cache-record eviction, wall-collision retention through unload, navigation floor-cell/walkability preservation for an unloaded previously-revealed chunk (and correct UNSEEN exclusion), foliage node identity/visibility parity across hide/show, road-decal unload/reload parity, safe wall destruction and authored-scene claim mutation while UNLOADED with no premature repaint, and correct reload materialization with nothing stale resurrected. `procgen_chunk_payload_cache`, `procgen_chunk_lifecycle`, `procgen_pause_aware_streaming`, `procgen_walkable_boundary`, `runtime_wall_collision_compaction`, `procgen_candidate_promotion_smoke` (`procgen_candidate_materializer_parity`), `procgen_macro_presentation`, `procgen_road_semantics_v2`, `procgen_dressing_clusters`, `navigation_elevation_smoke`, and `procgen_authored_scene_authority_smoke` all pass with the new `streaming_unload_distant_chunks = true` default exercised live (none of them override the flag). S1 quick reports `determinism_ok=true` at the same fixed-seed fingerprint (`1773840677`) as M1-M5, confirming no deterministic-output regression. The one required M5-test behavior change (a debug unload/re-reveal round trip now rebuilds instead of reusing its cache entry, since M6 intentionally evicts on unload) was updated in `procgen_chunk_payload_cache_smoke.gd` alongside the implementation.
- **Next:** Run MR6 against this landed commit. Only a clean/non-blocking-only MR6 pass closes S7 and makes D1-D3 refresh-eligible.

---

## S8 - ProcGenTilemap Decomplexification

### Goal

Hollow `ProcGenTilemap` toward a façade/runtime state host after S4 and S7 establish stable seams.

Priority coherent authorities:

1. road generation/repair/surface semantics;
2. authored claims / clearances / reservations;
3. generation level-data/export state.

V1 is already split into D1 road authority, D2 authored-claim registry, D3 generation-state extraction, and D4 façade contraction. D1-D3 are dependency siblings gated by G5+MR6 and serialized by the shared procgen-runtime lock; after those extractions, the reviewed GenerationGrid migration initiative must converge before D4 becomes executable.

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
