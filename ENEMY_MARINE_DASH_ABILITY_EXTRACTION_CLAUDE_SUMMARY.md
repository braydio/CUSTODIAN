# Marine Dash Ability Extraction

Implemented on `agent/enemy-marine-dash-ability-extraction`, claimed from
`main@735c8c6914`. **Checkpoint only: not landed.** Required changed-file
closeout is blocked by two pre-existing repository unit gates. The packet stays
blocked/manual and active; it is not falsely marked complete or archived.

## Landing Retry

Resumed through `workstream.py` and merged latest `origin/main@e49c8452f`
without conflicts (merge `ff94ff32e`). No Enemy/ability/Marine/ambush runtime
files changed through this synchronization. Both blocker gates were rerun:
`agent_workflow_contract` and `review_pairing_contract` still fail for the same
removed expiry-workflow and eight unrelated packet validation-path findings.
Reports are `/tmp/marine-retry-workflow.json` and
`/tmp/marine-retry-pairing.json`. Landing remains blocked; the synchronized
branch and this refreshed receipt are checkpointed for recovery. Runtime tests
were not repeated because the runtime changed set is identical and the two
required unit gates still prevent successful closeout.

## Change

- `MarineDash` owns the complete windup/travel/impact/recovery machine, clocks,
  charge selection/budget, one-shot predictive direction, contact bookkeeping,
  spatial/terminal telemetry, attacker freeze, alternating reset and cadence.
- `MarineDashConfig` preserves all 26 original actor defaults; the scene-bound
  `marine_dash_default.tres` preserves all 26 Marine scene values exactly,
  including 32 damage, 105 knockback and 1.1s cooldown. Config is duplicated per
  actor, following the established Falcon resource convention.
- Enemy supplies shared target qualification, hit resolution, facing/movement,
  animation, hitstop, camera and observability services. Its original fixed-step
  ability priority and shared attack-ID sequence remain intact. Host-target
  queries deliberately remain dynamic, as before; no new captured-target policy
  or generic ability base was introduced.
- The ambush uses `request_marine_dash`; typed ability/snapshot validation
  replaces actor-private state/helper inspection. Source searches find no old
  Marine phase/timer/reset fields or private phase helper callers in live code.
- `enemy.gd` shrinks from 4,958 to 4,615 lines: **343 lines removed net**.
  Focused validation ownership follows the new module/config. Consequence-driven
  design/current-state/index/ownership docs describe the extracted boundary.

## Verification

- Godot import preflight: PASS, no checked-out LFS pointers. Project import: PASS.
- Static exact-value comparison: all 26 actor defaults and 26 scene values match
  pre-extraction source; `time` is renamed `travel_time` without changing value.
- Focused Marine smoke: PASS. Covers quick/charged ratios, original clocks,
  prediction before/after the 62% lock boundary, no re-lock/steering, travel
  timeout, impact/recovery, no recovery hitbox, alternating/too-close reset,
  cadence gating, immutable snapshot, static-wall termination and movement stop.
- Spatial smoke: PASS. Stable actor attack IDs/context and single hit/whiff
  terminals remain; repeated contact is consumed once. Damage, dodge, parry,
  failed-parry block-hitreact and ordinary block retain original impact and
  next-attack bias. Ordinary block still applies impact, matching baseline.
- New focused production-map ambush smoke: PASS. Covers actual staged Marine,
  original 1.4s authored initial cadence credit, scene tuning, explicit start,
  charge animation/telegraph, shared AI handoff and idle/active/complete restore.
- Required `run_validation.py --changed --json`: **FAIL**, 21 selected checks:
  8 unit checks passed, 2 failed, 11 runtime checks skipped by tier gating.
- Separate selected runtime tiers: **8/8 actor PASS, 3/3 integration PASS**:
  `authored_vault_grunt_loot_marine`, `combat_exchange_commitment`,
  `enemy_grunt_behavior_presentation`, `enemy_grunt_notice_and_attack_cadence`,
  `enemy_hit_spatial_telemetry`, `enemy_patrol_navigation`, `grunt_falcon_punch`,
  `grunt_falcon_reversal`, `carrow_yard_interior`, `dev_observatory_audit`, and
  `sundered_keep_marine_ambush`.
- Changed-file coverage: no uncovered files. `git diff --check`: PASS.
- Moment Forge: not run — extraction timing/presentation requests are unchanged
  and structured equivalence tests prove this slice; no pixel acceptance.

Validation JSON remains ephemeral under `/tmp/marine-*`; the durable evidence
receipt is this summary and the committed focused tests. Expected headless
navigation warnings remain in fixtures without a NavigationSystem.

## What Prevented Landing

1. `agent_workflow_contract` reads the removed
   `.github/workflows/expire-lfs-degraded-mode.yml` and unconditionally expects
   the retired temporary procgen-routing block. The unchanged baseline smoke
   and absent workflow prove this predates the extraction.
2. `review_pairing_contract` rejects eight unrelated ready packets' validation
   references: seven workstreams use project-relative `tools/validation/...`
   paths; Operator registration explicitly says to **add/run** a new smoke
   which the guard demands already exist. This requires a bounded packet/path
   policy repair, not edits to Marine or another agent's implementation.
3. Exploratory legacy `sundered_keep_large_layout_smoke.gd` (unregistered on
   baseline) fails five preservation assertions: shore_walk_regions,
   return_mooring_origin_tile, key_pickup_tile, SunderedGateKeyPickup and
   MainGateInteraction. Restoring pre-extraction Enemy/Marine/ambush files and
   rerunning reproduces exactly the same five errors; its ambush assertions
   pass in both runs. New focused ambush coverage is registered instead of
   coupling Marine edits to historical layout drift. No level data changed.

`check_ai_context.py` additionally reports 11 unrelated pre-existing packet/
README inconsistencies. `task_packet_index.py` reports the documented absence
of a managed block; the recipe explicitly defers initializing that broad index
migration. Neither finding was silently rewritten as routine cleanup.

The graph in the coordination checkout is stale, and the ephemeral worktree
has no indexed nodes. Graph tools were attempted first; their empty impact/test
results were not treated as proof. Exact source searches and scoped diff review
provided the extraction/caller checks.

Two test-authoring errors (indentation and Variant boolean inference) were
caught by focused Godot runs and fixed before green runtime validation.

## Resume / Deferred

- Resume the existing workstream after `agent-validation-baseline-repair` fixes
  required unit gates; rerun changed-file closeout, refresh receipts, mark the
  packet complete/archive, commit, and `workstream.py finish` with a green report.
- `sundered-keep-large-layout-smoke-refresh` is a separate draft/manual follow-up
  requiring current authored-layout authority before changing preservation checks.
- Savage extraction, generic ability abstractions, and new Marine art/audio remain
  outside this slice. No main landing or project-root sync was attempted while
  required validation was red.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: required closeout failed pre-existing workflow/queue gates and skipped runtime tiers; exploratory legacy layout smoke also failed baseline metadata checks; two new test parse errors were corrected.
- Root cause / contributing factors: expired temporary-routing assertions, validation-path guard versus project-relative/planned-new-test packet semantics, and historical layout preservation drift.
- Prevention / pipeline improvement: registered focused Marine/ambush ownership, proved layout failures on baseline, and authored bounded draft repair packets rather than changing unrelated runtime or weakening guards.
- Tooling / docs drift discovered: removed expiry workflow still required by smoke; eight unrelated ready-packet validation references rejected; 11 pre-existing context/index findings; graph stale/empty; unmanaged task index is documented deferred state.
- Follow-up: agent-validation-baseline-repair
- What worked: all 11 selected runtime gates and exact tuning comparison passed.
