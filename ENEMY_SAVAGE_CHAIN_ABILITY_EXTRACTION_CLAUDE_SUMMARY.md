# Enemy Savage Chain Ability Extraction

- Workstream: `enemy-savage-chain-ability-extraction`
- Outcome: implementation complete; paired fresh-context review is next.
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d

## What changed

Moved Savage's two-hit chain lifecycle, committed direction, phase timer and six chain-only tuning values into actor-local `SavageChain` and typed `SavageChainConfig`. `Enemy` now retains the archetype toggle, generic attack cadence, first-hit damage/windup, standard melee contact geometry and narrow ability services. The Savage scene binds the default config. Diagnostics and presentation priority use the ability's read-only state; validation now enters the chain through its typed API.

The six defaults remain gap 0.10 s, second windup 0.16 s, second-hit damage 12, recovery 0.55 s, and guard pressure 10/22. First-hit damage remains host `damage=10`, first windup remains host `attack_windup_duration=0.26`. The chain checks the current target at each hit; its committed direction remains fixed. Pounce still gets first refusal and ticks before the chain.

## Verification and controls

Passed focused validations: `enemy_savage_pounce`, `savage_runtime`, `combat_exchange_commitment`, `enemy_hit_spatial_telemetry`, and `operator_guard_flow`. Coverage includes chain values/timing/hits/guard pressure, target-at-hit-time, miss, pounce decline fallback, pounce priority, presentation priority, ordinary LIGHT non-cancellation and stagger cancellation. `git diff --check` passed. The final changed-file sweep passed 31/31 selected checks with zero failures, timeouts, skips, infrastructure errors, or uncovered files. The sweep regenerated unrelated Operator reference `.import` sidecars; they were removed and are not part of this task.

Negative controls retained: a target outside the committed direction misses; the pounce-below-band case declines and then allows chain start; ordinary LIGHT damage leaves the chain committed, while parry/stagger interruption cancels it.

## Friction

The first focused run occurred before the fresh worktree had generated Godot import/class metadata, so project loading failed. A one-time headless editor import populated the local ignored cache; all focused gameplay validations then passed. The prior NPA-2 review workstream's changed-file sweep had separately exposed an unrelated `review_pairing_contract` failure for `living-world-abstract-activity-foundation`; this implementation did not alter that workstream.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Initial validation lacked fresh-worktree Godot import/class cache; the changed-file sweep regenerated unrelated Operator reference `.import` sidecars, which were removed.
- Root cause / contributing factors: Fresh isolated checkout had no generated import/class cache; the Godot editor import pass materialized reference sidecars outside the changed workstream.
- Prevention / pipeline improvement: Warm the editor cache once on fresh worktrees before focused gameplay validation and preserve unrelated sweep findings as external blockers.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: Focused machine-checkable regressions proved cadence and host/ability ownership without visual capture.

## Next Handoff
- Next workstream: review-enemy-savage-chain-ability-extraction
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d
- Refresh reason: none
- Next action: Land and archive this implementation, then claim the paired review when dispatch reports it eligible; use a fresh reviewer context.
- Blockers or open questions: none for implementation; paired review remains required.
