# PROCGEN RUNTIME OPTIMIZATION PATH INDEX

**Program:** `procgen-runtime-optimization-v1`  
**Purpose:** Low-token execution map for exact repository paths most likely needed by the pre-authored procgen optimization packet series.  
**Status:** active  
**Last Updated:** 2026-09-29

## Usage Contract

Task packets should point here when a slice has a known, narrow file neighborhood.

Agents should:

1. start from the exact paths listed for the current packet;
2. search within those files for the named functions/symbols before broad repository search;
3. expand to direct callers/callees only when a concrete dependency requires it;
4. treat **Existing** paths as confirmed on the reviewed repository;
5. treat **Preferred new path** entries as the intended creation locations unless live-main conventions make the exact filename invalid;
6. record any necessary path deviation in the closing summary and update this index in the same landed change.

This index is a navigation aid, not a substitute for the current task packet's scope, acceptance, or validation contract.

---

## S2 / G1 — Candidate Evaluator Extraction

**Workstream:** `procgen-candidate-evaluator-extraction`  
**Task packet:** `custodian/docs/ai_context/task_packets/archived/PROCGEN_CANDIDATE_EVALUATOR_EXTRACTION.md` (complete)

### Primary implementation paths

| Role | Exact repo-relative path | Status | Expected use |
| --- | --- | --- | --- |
| Current selection-policy owner | `custodian/game/world/procgen/custodian_contract_map.gd` | Existing | **Primary read/edit target.** Move evaluator policy out while retaining seed/profile/attempt orchestration and final winner handoff. |
| Generation package contract | `custodian/game/world/procgen/generation/README.md` | Existing | Read first for ownership boundary. Update at closeout because S2 ends its current “scaffold only / candidate metrics still live in coordinator files” truth. |
| Candidate evaluator | `custodian/game/world/procgen/generation/candidate_evaluator.gd` | **Preferred new path** | New focused owner for metric extraction, accept/reject policy, score calculation, terrain-failure classification, degraded fallback eligibility, and fallback comparison. |
| Candidate evaluation result | `custodian/game/world/procgen/generation/candidate_evaluation_result.gd` | **Preferred new path** | Data-only result/contract if a typed result object materially improves API clarity. If a deterministic Dictionary contract is cleaner under live conventions, keep one evaluator file and document that choice rather than creating an empty wrapper class. |
| Runtime candidate source | `custodian/game/world/procgen/proc_gen_tilemap.gd` | Existing | **Read-mostly adjacent reference.** Use only to understand level-data/fingerprint inputs currently consumed by evaluator policy. S2 should not migrate construction/materialization behavior here. |
| Procgen scene fixture | `custodian/game/world/procgen/proc_gen_map.tscn` | Existing | Existing candidate-map fixture instantiated by diagnostics/tests. Usually no edit required. |

### Current symbols expected to move or delegate

Search these in `custodian/game/world/procgen/custodian_contract_map.gd` before reading broad ranges:

```text
_is_map_layout_acceptable
_score_map_layout
_is_terrain_failed_candidate
_is_better_fallback_candidate
_can_use_degraded_fallback
_get_map_layout_metrics
_flood_fill_walkable
_is_layout_walkable_tile
_find_nearest_walkable_layout_tile
_is_tile_inside_map
_format_layout_metric_debug
```

Likely ownership split:

```text
CustodianContractMap
    keep:
      generate_contract
      seed derivation
      map/profile application
      attempt ordering
      candidate lifecycle/disposal
      winner selection orchestration
      final handoff

CandidateEvaluator
    own:
      candidate metric extraction
      rejection reasons
      validity decision
      score
      terrain-failure classification
      degraded fallback eligibility
      deterministic fallback comparison
      evaluator-facing flood/connectivity helpers
```

Do not move a helper merely because it is adjacent. Move it only if it exists solely to support evaluator policy.

### Focused validation / fixture paths

| Role | Exact repo-relative path | Status | Expected use |
| --- | --- | --- | --- |
| New focused evaluator smoke | `custodian/tools/validation/procgen_candidate_evaluator_smoke.gd` | **Preferred new path** | Direct parity coverage for extracted API, deterministic result shape, score/reason/fallback behavior, and no Node ownership in the result contract. |
| Production-sized rescue diagnostic | `custodian/tools/validation/procgen_contract_rescue_diagnostic_smoke.gd` | Existing | High-value parity fixture. Currently calls `CustodianContractMap._get_map_layout_metrics()` directly and is therefore a likely migration/edit target. |
| Candidate promotion regression | `custodian/tools/validation/procgen_candidate_promotion_smoke.gd` | Existing | Verify evaluator extraction does not alter accepted-candidate promotion/winner semantics. Usually validation-only unless private helper migration forces fixture adaptation. |
| Terrain required-cell regression | `custodian/tools/validation/procgen_terrain_required_cells_smoke.gd` | Existing | Protect required-cell/connectivity facts used by candidate evaluation. |
| Playability regression | `custodian/tools/validation/procgen_playability_smoke.gd` | Existing | Protect gameplay-layout acceptance semantics adjacent to evaluator scoring. |
| Spatial/determinism regression | `custodian/tools/validation/procgen_spatial_normalization_smoke.gd` | Existing | Representative fixed-seed structural regression. Normally validation-only. |
| Procgen validation suite | `custodian/tools/validation/run_procgen_validation_suite.sh` | Existing | Contains the slow rescue diagnostic behind `RUN_SLOW_PROCGEN=1` / `--full`. Use targeted commands during iteration rather than running the entire suite repeatedly. |
| Validation registry | `custodian/tools/validation/validation_manifest.json` | Existing | Register the new evaluator smoke and exact changed-file ownership. |
| Validation runner | `custodian/tools/validation/run_validation.py` | Existing | Final changed-file sweep; no expected S2 code change. |

### S1 predecessor evidence paths

S2 depends on `procgen-performance-baseline-v1`. At execution time, prefer the landed S1 artifacts rather than reconstructing baseline facts.

| Role | Exact repo-relative path | Expected state when S2 starts |
| --- | --- | --- |
| Archived S1 packet | `custodian/docs/ai_context/task_packets/archived/PROCGEN_PERFORMANCE_BASELINE_V1.md` | Should exist after S1 closeout. |
| S1 closing summary | `PROCGEN_PERFORMANCE_BASELINE_V1_CLAUDE_SUMMARY.md` | Expected root summary under current workstream convention; if S1 used a different canonical summary location, follow the archived packet/roadmap evidence instead of searching broadly. |
| S1 benchmark harness | `custodian/tools/validation/procgen_performance_baseline_bench.gd` | Preferred path specified by S1; verify actual landed path before use. |
| S1 roadmap evidence | `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` | Canonical baseline/status reference. |
| Master status mirror | `design/00_meta/MASTER_ROADMAP.md` | Macro status only; do not use as implementation detail source. |

Runtime benchmark JSON under `user://performance/` is intentionally ephemeral. Use the S1 closing summary/roadmap for durable baseline numbers unless the active worktree has a fresh local benchmark run.

### Documentation / closeout paths

| Role | Exact repo-relative path | Expected S2 action |
| --- | --- | --- |
| Canonical procgen roadmap | `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` | Mark G1/S2 complete and record landed SHA/evidence. |
| Master roadmap | `design/00_meta/MASTER_ROADMAP.md` | Mirror macro S2 status. |
| Generation ownership README | `custodian/game/world/procgen/generation/README.md` | **Required drift fix when evaluator lands.** Replace scaffold-only/candidate-metrics-in-coordinator wording with actual owner paths. |
| Validation recipes | `custodian/docs/ai_context/VALIDATION_RECIPES.md` | Add focused evaluator command only if it becomes a durable canonical recipe; avoid duplicating manifest-only detail unnecessarily. |
| Global file index | `custodian/docs/ai_context/FILE_INDEX.md` | Index newly created evaluator/result/smoke owners at closeout. |
| Task packet | `custodian/docs/ai_context/task_packets/PROCGEN_CANDIDATE_EVALUATOR_EXTRACTION.md` | Complete/archive through normal lifecycle. |

### Files unlikely to require S2 edits

Do **not** open/edit these merely because they are procgen-adjacent unless a failing test proves a dependency:

```text
custodian/game/world/procgen/terrain/**
custodian/game/world/procgen/foliage/**
custodian/game/world/procgen/presentation/**
custodian/game/world/procgen/roads/**
custodian/game/world/procgen/authored_claims/**
custodian/game/systems/core/systems/contract_world_loader.gd
custodian/game/ui/**
```

S2 extracts selection/evaluation policy. It does not change candidate construction, final materialization, streaming, placement, or presentation.

---

## X1 / X2 — Generation Data Model Migration Prelude

### X1 — `procgen-generation-data-model-audit`

Start with these exact paths after D1/D2/D3 have landed:

| Role | Exact repo-relative path | Use |
| --- | --- | --- |
| Remaining generation host | `custodian/game/world/procgen/proc_gen_tilemap.gd` | Primary call-graph and TileMapLayer operation inventory. Search `_fill_tilemaps` and its direct helper calls first; do not whole-read by default. |
| Already-pure skeleton generator | `custodian/game/world/procgen/procgen.gd` | Boundary reference for what is already storage-independent. |
| Contract orchestration | `custodian/game/world/procgen/custodian_contract_map.gd` | Verify candidate construction/evaluation/materialization boundaries; read only relevant call sites. |
| Generation package ownership | `custodian/game/world/procgen/generation/README.md` | Reconcile generation package truth after D3 and before defining GenerationGrid ownership. |
| Semantic snapshot adapter | `custodian/game/world/procgen/generation/candidate_semantic_adapter.gd` | Existing Node/live-candidate to data snapshot boundary. |
| Snapshot evaluator | `custodian/game/world/procgen/generation/candidate_evaluator.gd` | Defines evaluator facts the future pure-data generation path must produce unchanged. |
| D1 contract | `custodian/docs/ai_context/task_packets/PROCGEN_ROAD_AUTHORITY_EXTRACTION.md` or its archived copy at execution | Use the landed summary/owner to avoid re-inventorying road code already extracted. |
| D2 contract | `custodian/docs/ai_context/task_packets/PROCGEN_AUTHORED_CLAIM_REGISTRY_EXTRACTION.md` or archived copy | Exclude/match authored-claim state already moved. |
| D3 contract | `custodian/docs/ai_context/task_packets/PROCGEN_GENERATION_STATE_EXTRACTION.md` or archived copy | Use final accepted-world state/export owner when classifying remaining working state. |
| Determinism baseline | `custodian/tools/validation/procgen_performance_baseline_bench.gd` | Existing fixed-seed/fingerprint contract, not a reason to run the full profile during audit. |
| Semantic parity | `custodian/tools/validation/procgen_candidate_semantic_model_smoke.gd` | Protect snapshot/evaluator facts. |
| Evaluator parity | `custodian/tools/validation/procgen_candidate_evaluator_smoke.gd` | Protect acceptance/score semantics. |
| Rescue corpus | `custodian/tools/validation/procgen_contract_rescue_diagnostic_smoke.gd` | Existing rejection/connectivity corpus; validation reference only during X1. |
| Spatial invariant | `custodian/tools/validation/procgen_spatial_normalization_smoke.gd` | Protect native 32px spatial semantics once migration packets are authored. |

Required X1 durable output should live under:

`design/02_features/procgen/`

Preferred filename:

`PROCGEN_GENERATION_DATA_MODEL_AUDIT.md`

If the execution agent chooses another exact name, it must update this index, FILE_INDEX, and the task packet in the same landed change.

### X2 — `procgen-generation-grid-foundation`

Preferred new implementation paths, subject to the reviewed X1 contract:

```text
custodian/game/world/procgen/generation/generation_grid.gd
custodian/game/world/procgen/generation/tilemap_generation_grid.gd
custodian/tools/validation/procgen_generation_grid_smoke.gd
```

These are **preferred**, not invented authority. If X1 proves a different package boundary or class split is necessary, follow X1 and update this index.

X2 should not broadly migrate `_fill_tilemaps()`. Its default work surface is:

```text
reviewed X1 audit
generation_grid.gd                 # new semantic contract
tilemap_generation_grid.gd         # compatibility backend
procgen_generation_grid_smoke.gd   # contract/parity proof
proc_gen_tilemap.gd                # minimal canary injection only if X1 proves one
candidate_semantic_model_smoke.gd  # regression
candidate_evaluator_smoke.gd       # regression
```

### X3 — migration series authoring

`procgen-generation-grid-migration-series-authoring` is documentation/coordination only.

Primary exact paths:

```text
design/02_features/procgen/PROCGEN_GENERATION_DATA_MODEL_AUDIT.md
design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md
custodian/game/world/procgen/generation/generation_grid.gd
custodian/docs/ai_context/task_packets/PROCGEN_TILEMAP_FACADE_CONTRACTION.md
custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md
custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md
custodian/docs/ai_context/task_packets/README.md
```

X3 must use the reviewed audit's measured migration clusters. It must **not** infer helper slices from the old pre-D-lane “~40 helpers / 147 operations” number.

---

## Future Sections

Add one section here only when a later packet benefits materially from exact-path guidance. Do not turn this file into a dump of every procgen file.

Packets currently using this index as a primary low-token navigation aid include:

- `procgen-candidate-evaluator-extraction`
- `procgen-generation-data-model-audit`
- `procgen-generation-grid-foundation`
- `procgen-generation-grid-migration-series-authoring`
