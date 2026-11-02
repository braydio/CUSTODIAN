# CUSTODIAN — Enemy Objective System

**Status:** implemented-v1; coherence pass active
**Last updated:** 2026-08-20
**Content canon authority:** `design/03_world/GAME_PROTOCOLS_AND_WORLD_LORE.md`

## Purpose

Enemy objectives create readable pressure beyond direct pursuit: agents may
investigate, engage the Operator, steal from storage, sabotage storage, escape
with loot, patrol a camp territory, or perform ambient routines. This is a
small deterministic finite-state behavior layer, not GOAP or a behavior tree.

## Runtime Ownership

```text
Enemy.gd
    combat execution, special attacks, reactions, locomotion implementation
    legacy behavior fallback only

EnemyBehaviorStateMachine
    authoritative behavioral state and goal selection

EnemyPerceptionComponent
    sight, hearing, and detection authority

EnemyObjectiveSensor
    strategic candidate scoring only

EnemyBlackboard
    agent working memory

EnemyBehaviorProfile
    behavior tuning

NavigationSystem
    path selection

ProcGenTilemap + ElevationMap
    terrain traversal authority
```

When `behavior_state_machine_enabled` is true, `EnemyBehaviorStateMachine`
owns strategic behavior and movement goals. `enemy.gd` continues to execute
combat, special attacks, reactions, and requested locomotion. Its
`AssaultState` and direct structure-priority loop are retained only as legacy
fallback for content that explicitly disables the state machine.

## Immediate Interrupts and Strategic Scoring

Perception writes alert, visibility, hearing, investigation, and last-known
position facts to the blackboard. Operator detection/close awareness, existing
alerts, valid investigations, panic/flee, carried-loot escape, forced state,
and objective invalidation interrupt immediately without strategic scoring.

`EnemyObjectiveSensor.choose_objective()` is a scorer except for its diagnostic
score snapshot. It returns `{type, score, target, scores}` and must not mutate
the current objective, target storage, alert state, seen state, or behavior
state. The state machine evaluates it on the idle rescore cadence (default
`0.65` seconds), not every behavior update.

The state machine owns acceptance. A valid current strategic objective remains
until a different candidate exceeds its freshly scored value by
`objective_switch_margin` (default `18`). Same-type candidates retain a valid
current target. Invalid targets and hard interrupts bypass hysteresis.

## Determinism and Observability

Authoritative choices use world seed, stable spawn ordinal, camp ID, home
position, decision channel, and event ordinal. Patrol, ambient activity, and
damage-loot rolls consume independent blackboard ordinals. Wall-clock time,
frame count, render delta, and state duration never seed choices.

Blackboard snapshots expose current score, evaluation/switch counts, and all
decision ordinals. Developer Observatory counters
`enemy_objective_evaluations` and `enemy_objective_switches` expose cadence and
thrashing.

## Vault Objectives

Human-style enemies may score theft and sabotage. Theft removes resources only
after open/steal timers finish. Carrying loot immediately begins escape.
Reaching an enemy/vault exit commits loss; death or an eligible damage event
drops a recoverable payload.

## Validation

```bash
cd custodian
godot --headless --path . --script res://tools/validation/enemy_behavior_determinism_smoke.gd
godot --headless --path . --script res://tools/validation/enemy_objective_cadence_smoke.gd
godot --headless --path . --script res://tools/validation/enemy_behavior_authority_smoke.gd
godot --headless --path . --script res://tools/validation/enemy_behavior_vault_smoke.gd
```

## Next Agent Slice

Tune profile weights only after determinism, cadence, hysteresis, perception
interrupt, and navigation correctness smokes pass. Do not duplicate behavior,
perception, navigation, elevation, or spawning authorities.
