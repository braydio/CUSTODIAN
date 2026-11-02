# PROCGEN PRETERRAIN DIAGNOSTICS EXTRACTION

- Status: `complete`
- Authority: `design/02_features/procgen/TERRAIN_BUILDER_ELEVATION_INTEGRATION.md`
- Goal: Extract required-cell classification, pre-terrain diagnostics, component analysis, and authority repair from `ProcGenTilemap` without changing generation behavior or validation thresholds.
- Files: `game/world/procgen/proc_gen_tilemap.gd`, `game/world/procgen/diagnostics/*.gd`, procgen validation smokes, and AI context ownership docs.
- Constraints: Preserve all diagnostic keys/source labels, deterministic bridge ordering, repair caps, `pre_terrain_before_repair`, `pre_terrain_authority_repair_carved_cells`, strict rescue thresholds, and forced failure-safe behavior.
- Acceptance: Required-cell smoke, default procgen suite, and slow production rescue suite pass; `ProcGenTilemap` shrinks; docs identify the service ownership split.
- Completed: Added four context-driven diagnostic services; converted `ProcGenTilemap` collection, diagnostics, component, and repair functions into façade adapters; reduced the coordinator from 6,461 checked-in lines to 6,140; default and slow/full procgen suites pass. The production diagnostic accepted 33 candidates with worst/median baseline rescue 0 and verified forced failure emission plus runtime activation abort.
- Deferred: None currently.

## Ownership And Timing

- Owner: procgen/runtime
- Agent/session: Codex
- Created: 2026-07-08
- Last updated: 2026-07-08

## Work Surface

- Read: active procgen design docs, current state, file index, validation recipes, production rescue and required-cell smokes.
- Change: diagnostic service extraction, façade wiring, ownership docs, and validation evidence.
- Out of scope: generation behavior rewrites, threshold tuning, broad procgen folder reorganization, and movement of contract map/world loader/TerrainBuilder.

## Plan

1. Preserve inline behavior in focused context-driven services.
2. Keep stable `ProcGenTilemap` adapter methods and result keys.
3. Run focused, default, and slow production validations.

## Drift Review

- Primary authority: behavior remains consistent with the terrain/elevation procgen specs.
- `CURRENT_STATE.md`: update service ownership and production diagnostic status.
- `CONTEXT.md`: no working-model change required.
- `FILE_INDEX.md`: index all four service entrypoints.
- Local routing/readmes: no new local README required for this focused folder.

## Handoff

- Next action: None for this extraction.
- Best starting files: `game/world/procgen/proc_gen_tilemap.gd` and `game/world/procgen/diagnostics/`.
- Validation to run: `bash custodian/tools/validation/run_procgen_validation_suite.sh`; add `RUN_SLOW_PROCGEN=1` for production candidates.
- Blockers or open questions: None.
