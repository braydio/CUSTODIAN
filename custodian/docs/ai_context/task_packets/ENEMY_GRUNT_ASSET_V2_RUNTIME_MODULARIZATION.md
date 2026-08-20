# Enemy Grunt Asset V2 Migration + Runtime Modularization

- Status: `in_progress`
- Authority: `design/04_architecture/ASSET_PIPELINE_V2.md`, `design/02_features/animation/ENEMY_GRUNT_RUNTIME_WIRING.md`
- Goal: migrate the staged grunt batch through V2, replace concrete presentation wiring with semantic animation ownership, and extract the first special-ability module without changing strategic AI.
- Files: asset planner/transactions, grunt migration tooling/content, enemy presentation/ability runtime, focused validation, ownership/current-state docs.
- Constraints: preserve `EnemyBehaviorStateMachine`; preserve combat timing, Falcon reversal, critical execution, authored diagonals, and 156px material; never let FX own gameplay timing; preserve unrelated dirty work.
- Acceptance: consumer-safe plans, deterministic semantic presentation, checked inbox migration, no missing paths/duplicate identities, focused combat and asset validations.
- Completed: current-HEAD re-audit; V2.1 enemy schema/family confirmed; staged legacy vocabulary enumerated; stale task packets located under `task_packets/archived/`.
- Deferred: profile `.tres` migration unless the core slice is fully green; Marine/Savage extraction if it broadens risk.

## Ownership And Timing

- Owner: Codex
- Agent/session: current implementation session
- Created: 2026-08-20
- Last updated: 2026-08-20

## Work Surface

- Read: asset V2 architecture, grunt runtime wiring, current AI ownership, ability scaffold, staged/runtime assets and consumers.
- Change: V2 consumer safety, migration inventory/tool, semantic grunt presentation, Falcon Punch extraction where equivalence can be proven.
- Out of scope: strategic AI redesign, gameplay knockdown invention, Operator pipeline changes, art generation, profile migration unless low-risk.

## Plan

1. Produce a hash-backed staged/runtime migration inventory.
2. Block semantic supersession while concrete consumers remain.
3. Add semantic presentation resources/controller and migrate grunt consumers.
4. Migrate the checked source batch, ingest through V2, and clean only proven superseded outputs.
5. Extract Falcon Punch state machinery if focused equivalence tests remain controlled.
6. Validate, repair docs, review, and commit task-owned files.

## Drift Review

- Primary authority: V2.1 already supports enemy; the user brief's world-prop-only premise is stale.
- `CURRENT_STATE.md`: already reports V2.1 enemy support; must gain runtime migration status.
- `CONTEXT.md`: already routes non-Operator art through V2.1.
- `FILE_INDEX.md`: two grunt packet links omit the live `archived/` segment and must be repaired.
- Local routing/readmes: abilities README still says scaffold-only.

## Handoff

- Next action: implement consumer-safe semantic replacement planning.
- Best starting files: `asset_plan.py`, `asset_transaction.py`, `asset.py`, `grunt_animation_library.gd`.
- Validation to run: asset V2 smokes, grunt animation report, focused grunt/Falcon/parry smokes, Moment Forge selection.
- Blockers or open questions: generated asset catalog is concurrently dirty from another asset job; do not overwrite or stage it.
