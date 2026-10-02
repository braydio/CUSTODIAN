# OPERATOR GUARD / PARRY COMPOSITION POLISH

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-guard-parry-composition-polish`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-mobile-guard-composition`
- Locks: `operator-runtime`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `931b830d54f2a217d1b473109f708636ac89f21f`
- Goal: Extend the proven movement-permissive guard composition to the remaining defensive presentations that already allow movement, without weakening contact weight or converting committed reactions into generic locomotion composites.
- Completion boundary: Done when Vigil armed guard enter/hold/non-break recoil/exit uses movement-owned lower cadence whenever movement is legal; unarmed parry attempt/recovery uses movement-owned lower cadence where legal; any existing parry contact freeze/stop owns the brief planted contact beat rather than inventing a new simulation lock; lower cadence survives upper defensive phase changes without gratuitous restart; stationary/committed presentations keep their authored paired/full-body poses; and the behavior is owned by the semantic presentation layer rather than ad-hoc body-node manipulation in `operator.gd`.
- Current measured state: Action arbitration is complete and `OperatorPresentationController` is live. Unarmed mobile guard is separately queued as the proving slice. Vigil guard already owns complete E/W lower+upper+weapon semantic layers through the dedicated Vigil guard rig, but that rig takes complete body ownership for enter/loop/hit even though ordinary guard movement is not globally locked. Unarmed parry has canonical E/N/W lower+upper+FX attempt art and E/W lower+upper recovery art; `_play_modular_unarmed_parry()` currently replaces both body layers. Guard break, heavy knockdown, death, dodge and paired execution are committed actions and remain outside this packet.
- Evidence: `custodian/game/actors/operator/operator.gd` guard/parry presentation helpers and `_is_movement_locked()`; `custodian/game/actors/operator/combat/operator_guard_controller.gd`; `custodian/game/actors/operator/presentation/operator_presentation_controller.gd`; canonical generated Operator manifest; `operator_guard_flow_smoke.gd`, `operator_parry_presentation_smoke.gd`, `operator_modular_defense_ranged_smoke.gd`.
- Task-specific authority: `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`; `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`; `OperatorGuardController`; canonical Operator animation authority.
- Work surface: Guard/parry presentation coordination in `OperatorPresentationController` and the thinnest Operator facade calls; Vigil guard rig integration only where required; guard/parry focused validation. Do not move guard simulation/timing authority out of `OperatorGuardController`.
- Change:
  1. Reuse the movement-permissive composition seam established by `operator-mobile-guard-composition`; do not create a second guard-specific layer-composition system.
  2. For moving Vigil guard enter/hold/non-break hit recoil/exit, keep the lower layer on authoritative locomotion cadence and drive upper body + dagger weapon from the existing Vigil semantic defense action/facing. Stationary phases preserve the authored lower+upper+weapon defensive composition.
  3. Preserve weapon/body synchronization by using the existing canonical weapon identity and presentation clock rules. A missing required upper/weapon identity must fail closed to the complete authored Vigil guard composition, never a body with a floating/missing weapon.
  4. For moving unarmed parry attempt before contact, keep lower locomotion continuous while the upper body and parry FX present the defensive action. Stationary attempt keeps the authored lower+upper pair.
  5. On confirmed parry contact, use the already-existing contact/hit-stop/freeze window if it actually stops Operator displacement to show the strongest paired contact pose. Do not add a new movement lock merely for animation. If no existing simulation freeze covers the body, keep the lower locomotion composition and let contact FX/hit-stop provide weight.
  6. During parry recovery, resume/retain lower locomotion immediately when movement is legal while the upper recovery finishes. Preserve lower frame/progress across attempt -> contact/success -> recovery when the lower locomotion identity and direction are unchanged.
  7. Keep guard break / break recovery, heavy knockdown, dodge, critical execution, Falcon reversal and death committed/full-body. Modularity is not permission to dissolve authored whole-body actions.
  8. Keep lower direction movement-owned and upper/weapon direction contact/guard/aim-owned. Do not mirror canonical directional identities at runtime.
  9. Remove or shrink bespoke Vigil guard visibility/playback glue only when the shared semantic presentation path fully replaces it; do not leave two active defensive presentation authorities.
- Preserve: guard/parry timings, mitigation, posture/stamina, guard-break locks, release/repress semantics, parry success branching, critical/Falcon logic, attack interruption rules, weapon authority through the final presented frame, fixed-step simulation.
- Non-goals: No new art. No mobile guard break. No parry balance retuning. No generic attack/reload/Field Patch work. No head/cape reactivation. No conversion of committed full-body reactions to locomotion composites.
- Acceptance: Moving Vigil guard visibly strafes with lower cadence while upper+dagger maintain guard-facing; moving parry attempt/recovery retain lower cadence; stationary guard/parry preserve authored paired silhouettes; unchanged lower animation does not restart solely because the upper phase changes; confirmed contact uses only an existing real freeze for any planted beat; missing layer negative controls fall back to complete presentation; guard break remains movement-locked; existing critical/Falcon and guard/parry regressions remain green.
- Validation: Extend focused guard/parry smokes first, including opposed movement/guard direction, lower frame-progress continuity, Vigil weapon presence and missing-layer fallback. Run `operator_guard_flow_smoke.gd`, `operator_parry_presentation_smoke.gd`, `operator_modular_defense_ranged_smoke.gd`, `operator_vigil_dagger_smoke.gd`, and visual-ownership coverage. Use one tight Moment Forge guard/parry strafe scenario in `--capture-mode evidence` only after deterministic assertions pass; subjective baseline approval remains human-owned. Finish with one changed-file closeout.
- Task overrides: `none`
- Deferred: Dedicated guard-break body/FX belongs to `operator-guard-break-presentation`. Broader melee/ranged/loadout/recovery movement-permissive presentation belongs to their Slice F packets.

## Handoff

- Next action: Execute after mobile guard lands; reuse its semantic composition seam rather than re-deriving policy in the Vigil/parry helpers.
- Best starting files: `operator_presentation_controller.gd`; `operator.gd` guard/parry helpers; `operator_guard_controller.gd`; focused guard/parry smokes.
- Blockers or open questions: None.
