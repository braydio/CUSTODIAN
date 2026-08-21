# Enemy Grunt Asset V2 Migration + Runtime Modularization

- Status: `complete`
- Authority: `design/04_architecture/ASSET_PIPELINE_V2.md`, `design/02_features/animation/ENEMY_GRUNT_RUNTIME_WIRING.md`
- Goal: migrate the staged grunt batch through V2, replace concrete presentation wiring with semantic animation ownership, and extract the first special-ability module without changing strategic AI.
- Files: asset planner/transactions, grunt migration tooling/content, enemy presentation/ability runtime, focused validation, ownership/current-state docs.
- Constraints: preserve `EnemyBehaviorStateMachine`; preserve combat timing, Falcon reversal, critical execution, authored diagonals, and 156px material; never let FX own gameplay timing; preserve unrelated dirty work.
- Acceptance: consumer-safe plans, deterministic semantic presentation, checked inbox migration, no missing paths/duplicate identities, focused combat and asset validations.
- Completed: current-HEAD re-audit; V2.1 enemy schema/family confirmed and expanded; hash-backed inbox migration; transactional 27-input/54-output ingest; semantic animation set/controller; deterministic attack and reaction presentation; consumer-safe supersession; strict runtime cleanup; first Falcon Punch ability seam; documentation repair.
- Follow-up: Marine/Savage extraction and profile `.tres` migration remain separate slices. Falcon phase/timer ownership moved fully into `GruntFalconPunch` on 2026-08-21 with typed configuration, captured target identity, token-stall recovery, semantic presentation, and equivalence validation.

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
5. Extract a bounded Falcon Punch authority seam while preserving the proven phase implementation.
6. Validate, repair docs, review, and commit task-owned files.

## Drift Review

- Primary authority: V2.1 already supports enemy; the user brief's world-prop-only premise is stale.
- `CURRENT_STATE.md`: already reports V2.1 enemy support; must gain runtime migration status.
- `CONTEXT.md`: already routes non-Operator art through V2.1.
- `FILE_INDEX.md`: two grunt packet links omit the live `archived/` segment and must be repaired.
- Local routing/readmes: abilities README still says scaffold-only.

## Final Evidence

- Asset job: `job_20260820T232800Z_6fb5a49d`; 27 authored inputs, 54 runtime outputs, Godot import successful, `enemy_runtime_import` executed, receipt and immutable archive retained.
- Asset/runtime validation: V2 smoke, schema smoke, strict enemy animation report, PNG audit, semantic presentation smoke, grunt animation smoke, Falcon Punch/reversal/parry smokes, behavior determinism/authority, architecture ownership, archive boundary, doctor, and changed-file validation passed.
- Runtime cleanup: zero invalid canonical names and zero duplicate semantic identities after hash/reference-backed cleanup. Authored diagonal attacks, critical/parry assets, and 156px Falcon material remain available.
- Moment Forge: `combat/parry_success` passed. `combat/light_hit_grunt` ran but its health assertion failed because Operator targeting committed with an empty target (`reliable_contact=false`) after the soft target was lost; no enemy damage event occurred, so this is recorded as a scenario/Operator-targeting issue rather than an animation-owned timing change.
- Concurrent worktree note: another session committed the shared worktree during the transaction. Its captured inbox/staging LFS pointers were reconciled as transaction artifacts. A subsequently appearing `idle_02` inbox asset was preserved untouched as unrelated pending user input.

## Handoff

- Completed architecture slice: Falcon owns its complete phase/timer/cadence/contact/telemetry machine; `Enemy` supplies narrow shared combat services and temporary debug compatibility accessors. Next compare this module with Marine Dash before introducing any generic ability base.
- Pending content: classify or add a family state for the separately arrived `idle_02` input before ingesting it.
- Moment follow-up: repair or retune `combat/light_hit_grunt` targeting setup; do not change enemy gameplay timing to satisfy the failed assertion.
