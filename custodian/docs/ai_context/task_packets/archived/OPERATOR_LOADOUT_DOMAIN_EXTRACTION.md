# OPERATOR LOADOUT DOMAIN EXTRACTION — SLICE F1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-loadout-domain-extraction`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-dependency-injection-spine, operator-mobile-guard-composition`
- Locks: `operator-runtime`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `03b6221adb01402b1cf4393b9a1773cdd519f6ae`
- Goal: Make loadout/weapon-selection runtime state a focused authority, remove mutable instance state from `OperatorWeaponDefinition`, and use the established modular presentation seam for movement-permissive draw/sheathe transitions without changing weapon-selection semantics.
- Completion boundary: Done when weapon selection, pending switch, carried/equipped weapon coordination and per-weapon mutable runtime state live behind an `OperatorLoadoutController`-class authority (exact local shape may differ); `OperatorWeaponDefinition` is immutable definition data with no `current_magazine/is_reloading/reload_timer`; existing public Operator loadout APIs delegate; moving draw/sheathe keeps authoritative lower cadence while upper/weapon transition; stationary transitions keep authored paired poses; and the three `weapon_definition_runtime_state` architecture findings are zero.
- Current measured state: `operator.gd` is 14,587 lines / 711 functions on reviewed main. `OperatorWeaponDefinition` still exports exactly three runtime fields: `current_magazine`, `is_reloading`, `reload_timer`. No `OperatorLoadoutController` or `OperatorWeaponRuntimeState` exists. Equip/sheathe arbitration is already owned by `OperatorActionController`, while presentation/start-complete logic and pending selection commit remain in the actor. `_is_movement_locked()` does not lock equip/sheathe, so current paired lower draw/sheathe can slide while the actor moves.
- Evidence: `operator_weapon_definition.gd`; Operator loadout/switch/equip/sheathe functions; `operator_action_controller.gd`; `operator_melee_sheathe_smoke.gd`; `operator_melee_switch_chain_smoke.gd`; architecture debt baseline.
- Task-specific authority: Operator runtime architecture; weapon data/definition authority; existing equip/sheathe transaction tests; semantic presentation authority.
- Work surface: New loadout/runtime-state authority under `game/actors/operator/loadout/` (or closest existing operator boundary); Operator facade delegation; weapon definition/resource use; equip/sheathe presentation request integration; focused loadout/switch validation.
- Change:
  1. Extract weapon selection/equipped identity/pending switch/carried weapon coordination from the actor into one loadout authority while preserving the Operator's public methods/signals as thin delegates.
  2. Introduce `OperatorWeaponRuntimeState` as mutable per-equipped/per-carried runtime state. Move magazine/reload mutable values out of `OperatorWeaponDefinition`; definitions remain reusable immutable tuning/data resources.
  3. Preserve existing weapon-switch transaction semantics exactly: old weapon remains authority through final sheathe frame, pending selection commits exactly once, draw occurs only when the resulting loadout requires it, and melee->unarmed/ranged/sidearm cases do not fabricate an extra draw.
  4. Keep reload/ammo/heat behavior owned by the current actor/ranged path for now, but make it read/write through the runtime-state seam so `operator-ranged-domain-extraction` can take that behavior without mutating definitions.
  5. Route draw/sheathe semantic presentation through `OperatorPresentationController`. When movement is legal and nonzero, preserve the lower locomotion identity/direction/progress and play the authored upper+weapon draw or sheathe transition; when stationary, preserve the existing authored lower+upper+weapon transition.
  6. Missing upper/weapon transition art must fail closed to the complete authored paired transition or existing safe fallback, never a lower-only/upper-only body or missing weapon.
  7. Remove superseded actor-local loadout state/helpers once delegation is proven. Do not keep parallel selection/runtime-state truth.
  8. Refresh architecture debt baseline; expected `weapon_definition_runtime_state: 3 -> 0`.
- Preserve: action arbitration priorities, inventory/progression semantics, P-9 unlock/equip behavior, weapon IDs, definition tuning, melee posture grace, existing sidearm/primary priority, fixed-tick timing, public API/signals.
- Non-goals: No ammo/heat/reload controller extraction yet. No melee/ranged combat retuning. No new draw/sheathe art. No generic inventory rewrite. No weapon registration/persistent-death semantics beyond consuming whatever the active recovery roadmap has already landed.
- Acceptance: Definitions contain zero mutable runtime fields; runtime state survives weapon switches exactly as current behavior requires; every existing switch-chain/sheathe scenario still passes; moving draw/sheathe visibly keeps lower cadence while upper+weapon transitions; stationary transition remains authored paired; lower cadence does not restart unless locomotion identity/direction changes; architecture debt is reduced by three with no new category.
- Validation: Focused loadout/sheathe/switch tests first, plus weapon-specific dagger/cleaver/sidearm/ranged readiness regressions affected by runtime-state access. Add moving draw/sheathe continuity assertions and one tight evidence capture only if deterministic layer/frame checks cannot establish the visual handoff. Run architecture audit and one changed-file closeout.
- Task overrides: `none`
- Deferred: Ranged owns ammo/heat/reload behavior extraction. Melee owns READY/RELAXED combat-posture and moving-attack presentation. Persistent armament registration remains owned by its separate roadmap.

## Handoff

- Next action: Extract immutable-vs-runtime weapon state first, then migrate draw/sheathe presentation onto the shared mobile composition seam inside the same workstream.
- Best starting files: `operator_weapon_definition.gd`; `operator.gd` loadout/equip/sheathe functions; action/presentation controllers; sheathe/switch smokes.
- Blockers or open questions: None.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `OperatorLoadoutController` and `OperatorWeaponRuntimeState` are live under `custodian/game/actors/operator/loadout/`; the three definition runtime fields are removed; focused loadout/sheathe/switch regressions and the 85-test changed-file report passed; the architecture debt audit reports zero findings.
- The loadout controller now owns selected weapon identity, pending selection, selection snapshots, and switch transaction sequencing. Operator public selection methods remain compatibility delegates.
- `OperatorWeaponRuntimeState` owns per-weapon loaded magazine and reload clocks. `OperatorWeaponDefinition` contains no mutable magazine/reload fields, and factory initialization no longer mutates definitions.
- Draw and sheathe requests use `OperatorPresentationController.present_defensive_composition`; moving requests retain the active lower locomotion identity and progress while upper/weapon transitions play. Stationary sheathe remains an authored paired transition.
- Architecture debt audit reports zero `weapon_definition_runtime_state` findings.
- Focused validation passed: `operator_melee_sheathe` (including moving cadence assertion), `operator_melee_switch_chain`, `operator_runtime_spine_immutable`, `operator_sword_cleaver`, `operator_ranged_ready_input`, and `operator_weapon_socket`.
- Changed-file validation passed: 85 selected, 85 passed, zero uncovered files.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: Initial changed-file validation found `weapon_definition_factory.gd` had no test owner; one earlier cleaver smoke also exposed an overlay registration conflict while the composition refactor was being iterated.
- Root cause / contributing factors: Factory code lives outside the Operator directory glob; the generic body presenter treats registered overlays differently from the legacy melee weapon overlay path.
- Prevention / pipeline improvement: Added the factory path to the existing Operator runtime-path audit's owner list; retained explicit preflight of weapon overlay art and routed only the body pair through the composition seam.
- Tooling / docs drift discovered: Changed-file coverage omitted the factory from all owners.
- Follow-up: none
- What worked: Focused transaction and presentation smokes caught both issues before the final 85-test sweep.

## Next Handoff
- Next workstream: operator-ranged-domain-extraction
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Claim the F3 ranged extraction after this packet archives complete; it now has the stable `OperatorWeaponRuntimeState` seam.
- Blockers or open questions: none
