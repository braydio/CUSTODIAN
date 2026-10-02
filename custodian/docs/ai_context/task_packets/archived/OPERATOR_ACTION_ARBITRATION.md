# OPERATOR ACTION ARBITRATION — SLICE E

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-action-arbitration`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-runtime-compatibility-residue`
- Locks: `operator-runtime`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `96b0fd4f9d10f6c7518bf930f20a9c556f91924f`
- Goal: Replace the Operator's reflection-driven animation state machine with an explicit action-arbitration authority and semantic presentation controller, so interruption/priority/lifecycle decisions no longer live in animation-state objects or reach back into `operator.gd` dynamically.
- Completion boundary: This slice is complete when `OperatorActionController` is the sole action-arbitration authority for attack, guard, equip/sheathe, damage reaction and death; locomotion is no longer modeled as action state; no Operator action state reaches back through `actor.has_method()/call()`; the legacy `AnimationStateMachine` and obsolete state-shell runtime path have zero production consumers and are removed; semantic presentation requests pass through an `OperatorPresentationController` without adding gameplay/action semantics to `OperatorBodyPresentationPlan`; and existing combat timing/domain behavior remains owned where it is today for later Slice F extraction.
- Current measured state:
  - Live `operator.gd` is still 14,850 lines / 709 functions on reviewed main; C2b.2/C2b.3 are queued but not started.
  - `operator_architecture_debt_baseline.json` currently records 34 `animation_state_actor_glue` violations, all in six files: `attack_fast_state.gd` 4, `attack_heavy_state.gd` 4, `block_state.gd` 4, `equip_weapon_state.gd` 4, `hit_recoil_state.gd` 12, and `sheathe_weapon_state.gd` 6.
  - `AnimationStateMachine` owns current-state strings, transition priority, re-entry and enter/exit signals, but behavior is implemented by reflection into the Operator. It holds `actor`, `sprite` and playback references even though the architecture plan says the action authority must hold no sprite reference.
  - `idle_state.gd`, `walk_state.gd`, and `sprint_state.gd` are empty locomotion shells. Real locomotion presentation already derives from velocity/sprint facts elsewhere in the Operator, so these shells create a second axis masquerading as action state.
  - Attack states only delegate `start_attack()` / `is_attack_state_complete()`; BlockState only delegates `start_block()` / `update_block_state()`; equip/sheathe states delegate the existing presentation lifecycle and pending-selection commit; HitRecoilState delegates damage-reaction duration, selection, modular/fallback presentation, FX, completion and cleanup. Those domain functions remain live and are not being extracted in this slice.
  - `DeathState` is terminal and plays canonical death presentation through the state machine, while `operator.gd::die()` still also contains direct death-presentation fallback logic. Preserve one terminal death action and remove duplicate arbitration/presentation responsibility after prerequisite animation cleanup establishes the current canonical death path.
  - Current request sites use explicit priorities: ordinary attack request 10, block 8, equip/sheathe 5, damage reaction 20/24, paired-execution idle reset 100, and death request 20. Preserve observed interruption outcomes rather than merely copying numbers if the new authority can express them more clearly.
  - The body/presentation layer is already separated: `OperatorBodyPresenter` owns WHO may draw, `OperatorAnimationPlayer` owns HOW a resolved clip plays, and `OperatorAnimationSelector` owns WHICH canonical identity is selected. `OperatorBodyPresentationPlan` intentionally contains only owner/body layers/overlays and must remain free of semantic action fields.
- Evidence: `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`; `custodian/docs/ai_context/task_packets/OPERATOR_RUNTIME_DECOMPOSITION.md` Slice E; live `operator.gd`; `animations/animation_state_machine.gd`; the six glue-bearing state files; empty idle/walk/sprint state files; `presentation/operator_body_presenter.gd`; `presentation/operator_body_presentation_plan.gd`; `presentation/operator_animation_player.gd`; `operator_architecture_debt_audit.py` and baseline.
- Task-specific authority: `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md` action/presentation ownership; `OperatorBodyPresenter`, `OperatorAnimationPlayer`, and `OperatorAnimationSelector` for the already-established presentation split; existing melee/guard/damage/loadout runtime behavior in `operator.gd` and `OperatorGuardController`.
- Work surface: new focused `OperatorActionController` and `OperatorPresentationController` under the Operator runtime; `operator.gd` integration/orchestration; legacy `animations/animation_state_machine.gd` + `animations/states/*`; validation manifest/architecture baseline and focused attack, guard, damage-reaction, weapon-switch, death/respawn regressions. Do not move melee/dodge/ranged/loadout/recovery domain state into the new action controller.
- Change:
  1. Introduce an `OperatorActionController` that owns only action arbitration: current action, priority/interruption/re-entry policy, terminal death state, and enter/exit/transition lifecycle. It must not hold an `AnimatedSprite2D`, SpriteFrames, animation selector, or gameplay-domain state.
  2. Replace dynamic `actor.has_method()/call()` behavior with explicit integration. Prefer requests into the controller plus explicit transition/lifecycle results or signals consumed by the Operator. Small typed callbacks/adapters are acceptable if they keep dependency direction explicit; do not recreate reflection under a different spelling.
  3. Model locomotion as a separate axis. Remove `idle_state.gd`, `walk_state.gd`, and `sprint_state.gd` from action arbitration; idle/walk/sprint presentation continues to derive from current movement facts through the existing presentation/locomotion paths.
  4. Preserve these action families and outcomes:
     - fast/heavy melee action request, re-entry/buffering behavior and completion;
     - guard/block entry and non-interruptible hold semantics already owned by `OperatorGuardController`;
     - equip/sheathe sequencing, including “old weapon remains authority through final sheathe frame”, pending selection commit exactly once, and draw only when the resulting loadout requires it;
     - light/heavy damage reaction preemption, re-entry on repeated hits, exact reaction-duration contract, modular/fallback presentation, shared incoming-damage package exactly once, and cleanup;
     - death as terminal action until respawn explicitly resets arbitration.
  5. Introduce `OperatorPresentationController` as the semantic presentation coordinator. It may translate a request such as an action/body composition into the existing selector/player/presenter mechanisms, but it does not own combat timing, action priority, input, damage, ammunition or weapon-selection state. Keep `OperatorBodyPresentationPlan` mechanical: owner + body layers + overlays only.
  6. Migrate the production request sites currently calling `AnimationStateMachine.request()` to the action controller, including attack, block, equip, sheathe, damage reactions, death, forced neutralization for paired execution, and respawn reset. Preserve portal/arrival locking behavior and existing fixed-tick ordering.
  7. Remove the legacy `AnimationStateMachine`, `AnimationState`, and concrete Operator state files once production consumers reach zero. If a tiny generic compatibility type is still required by a test/tool outside production, prove that consumer and keep it outside the Operator behavioral path; do not leave two runtime arbiters.
  8. Keep domain methods such as melee timeline, guard controller, damage-reaction implementation and weapon-selection commit in their current owner for now. Operator may retain small facade/orchestration methods so later Slice F packets can move one complete domain at a time.
  9. Update validation ownership so edits to the new action/presentation controllers select focused Operator action tests. Extend the architecture audit so action arbitration cannot regress into reflection/state-to-actor glue or a second behavioral state machine.
  10. Refresh the architecture baseline from the actual post-prerequisite main. Expected migration effect is `animation_state_actor_glue: 34 -> 0`. If C2b.2 lands as specified and C2b.3 adds no architecture-debt categories, total audited debt should move `75 -> 41` (38 absolute scene lookups + 3 mutable weapon-definition runtime fields). Do not force those totals if prerequisite implementation changed the measured ledger; emit and commit the factual baseline.
  11. Reconcile active docs that still describe `AnimationStateMachine` as current Operator behavioral authority. Preserve historical summaries/packets as history.
- Preserve: fixed-tick simulation ordering; input routing; melee hit windows/cadence/buffering/fast-chain behavior; guard/parry semantics and release/repress rule; equip/sheathe timing and weapon authority; damage/knockdown timings and hit-stop package; paired executions/reversals; ranged/dodge behavior; body visibility firewall; canonical animation selection; weapon definition tuning; current signals/observability unless a direct replacement is required.
- Non-goals: No Slice F domain extraction. Do not move melee timeline, dodge state, ranged/ammo/heat/reload, loadout inventory, interaction/build/repair, recovery, or mutable weapon runtime state into the action controller. No combat retuning. No animation/art changes. No absolute-scene-lookup cleanup. No new input model. No body-plan semantic fields. No generic “state machine framework” intended for enemies or unrelated actors.
- Acceptance:
  - `operator_architecture_debt_audit.py --emit-baseline` reports zero `animation_state_actor_glue`; committed baseline matches the measured state.
  - No production Operator code uses `AnimationStateMachine`, `AnimationState`, or concrete `animations/states/*` behavioral objects after migration.
  - `OperatorActionController` owns action arbitration and holds no sprite/frames/playback/selector reference.
  - `OperatorPresentationController` contains no gameplay timing or action-priority authority, and `OperatorBodyPresentationPlan` still exposes only owner/body layers/overlays.
  - Locomotion continues while no action owns the actor; movement never becomes an action-controller state.
  - Fast/heavy attack requests, action buffering/re-entry and completion preserve current cadence.
  - Block/parry, equip/sheathe, damage reaction, death and respawn preserve current observable behavior and priority/preemption outcomes.
  - A repeated damage reaction can re-enter correctly; death remains terminal until explicit respawn; respawn returns to no active action without fabricating an idle action state.
  - Pending weapon selection commits exactly once after sheathe; melee-to-melee still draws the new weapon, while switches to unarmed/ranged do not spuriously draw.
  - Existing body/presentation ownership tests remain green; the new action controller cannot directly show/hide/play a sprite.
  - Validation manifest ownership no longer points focused action tests at deleted state files.
- Validation: Add a focused `operator_action_arbitration_smoke.gd` (or equivalent) covering priority/preemption, same-action re-entry, terminal death/reset, locomotion independence and zero presentation references in the action controller. Then run the directly affected existing tests: `operator_attack_phase_cadence`, `operator_modular_fast_attack`, `operator_guard_flow`, `operator_parry_presentation`, `operator_melee_sheathe`, `operator_melee_switch_chain`, `operator_melee_posture`, modular/light/heavy damage-reaction/knockdown coverage, fixed-tick spine, and death/respawn tests selected by current manifest. Run architecture debt after each migration cluster, then one `run_validation.py --changed --json` closeout. Do not begin with a broad repository sweep.
- Task overrides: `none`
- Deferred: Slice F remains six domain-focused packets: melee timeline/drive, dodge, ranged/ammo/heat/reload, loadout + `OperatorWeaponRuntimeState`, interactions/build/repair, and recovery. Absolute scene dependencies leave `operator.gd` with those domain extractions, not here. Slice G performs final scene/shell collapse and hard zero-debt gate.

## Completion Truth

- Completion schema: `custodian.task_completion_truth.v1`
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Superseded/legacy production path disposition: removed
- Evidence: Operator action arbitration smoke and ten focused combat/action regressions passed. Debt audit reports zero `animation_state_actor_glue` and 41 factual remaining violations (38 absolute scene lookups + 3 mutable weapon-definition fields). The changed-file closeout was attempted and exposed an unrelated failing `review_pairing_contract` check in `review-procgen-distant-chunk-unload`; focused relevant validation remains green.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: partial
- Friction severity: low
- What went wrong: changed-file closeout selected an unrelated repository-wide review-packet contract check that fails on an existing malformed bounded override.
- Root cause / contributing factors: the review packet predates this task and is outside the Operator workstream.
- Prevention / pipeline improvement: repair or refresh the `review-procgen-distant-chunk-unload` packet's bounded override in its owning workstream.
- Tooling / docs drift discovered: task packet was still queued behind already-landed prerequisites; current live baseline differed from its reviewed-main measurements.
- Follow-up: manual-follow-up
- What worked: focused action and combat regression selection gave fast, relevant coverage.

## Handoff

- Next action: None; implementation is complete and archived.
- Blockers or open questions: None.
