# OPERATOR RANGED DOMAIN EXTRACTION — SLICE F3

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-ranged-domain-extraction`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-loadout-domain-extraction, operator-dependency-injection-spine, operator-mobile-guard-composition, review-operator-chassis-authority-seal-v1`
- Locks: `operator-runtime`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `03b6221adb01402b1cf4393b9a1773cdd519f6ae`
- Goal: Extract primary-ranged/sidearm combat state into one ranged authority and make all movement-permissive ranged presentation use the same lower-locomotion + upper/weapon action contract that already works during primary fire.
- Completion boundary: Done when ammo/heat/reload/fire-ready/pending-shot/sidearm phase state is owned behind an `OperatorRangedController`-class authority using `OperatorWeaponRuntimeState`; Operator public ranged APIs remain delegates; primary raise/ready/fire/recover/lower and sidearm draw/held/fire/recover express legal movement without frozen/sliding lower-body poses; movement-locked reload remains committed; and current ballistic/socket authority is preserved for a later static-weapon closeout.
- Current measured state: Ranged phase/ammo/heat/reload/ready/fire and sidearm action state are delegated to the ranged controller. Primary raise/lower, sidearm held/fire/recovery, and movement-permissive primary fire preserve movement-owned lower cadence while upper/weapon/FX follow action state. Reload remains movement-locked and committed. Canonical runtime publication now has 588 animations and every SpriteFrames texture reference resolves; ballistic and frame-aware Carbine socket authority remains covered.
- Evidence: ranged/sidearm functions in `operator.gd`; `operator_weapon_runtime_state` seam from F1; `operator_ranged_ready_input_smoke.gd`; `operator_primary_ranged_modular_fire_smoke.gd`; `operator_sidearm_canonical_smoke.gd`; `operator_ranged_ballistic_aim_smoke.gd`; `operator_weapon_socket_smoke.gd`; hybrid socket design.
- Task-specific authority: ranged combat/balance docs; `design/02_features/operator_modular_weapon/HYBRID_WEAPON_SOCKET_SYSTEM.md`; Operator runtime architecture; canonical animation authority.
- Work surface: New ranged authority under `game/actors/operator/combat/`; actor facade; weapon runtime state; semantic presentation controller; primary/sidearm focused validation. Do not absorb loadout selection, melee or dodge lifecycle.
- Change:
  1. Move ranged ready/aim phase, pending shot, cooldown/ammo consumption, heat/overheat, reload lifecycle and sidearm action phase/buffer state into one ranged controller with explicit dependencies and runtime-state access.
  2. Keep accepted player aim, ballistic solution, projectile/muzzle origin and frame-aware socket metadata authoritative exactly where they are semantically owned; extraction must not move simulation authority into presentation.
  3. Primary ranged raise: while movement is legal, keep lower idle/walk/run cadence from movement facts and play `ranged_2h/cosmetic/aim_01` on upper + weapon only. Stationary raise may use lower idle cadence rather than an action lower if that yields the same registered silhouette; do not keep a planted action lower merely because it exists.
  4. Primary ranged lower: preserve the existing asymmetric lower duration and partial-progress reverse behavior, but reverse only the upper+weapon aim transition while lower locomotion/idle continues. An interrupted partial raise must lower from its actual progress, not restart.
  5. Preserve current ready movement and primary fire composition: lower movement-owned, upper/weapon aim/action-owned, FX independent. Make `fire_recover` an explicit presentation phase/semantic outcome even if it uses the trailing frames of the existing fire strip; gameplay timing remains controller-owned.
  6. Sidearm held: stop freezing the lower body on the final draw frame. Keep lower idle/walk/run cadence while upper+weapon retain the held sidearm pose. Lower direction follows movement; upper/weapon follow aim/accepted sidearm sector.
  7. Sidearm fire: keep lower locomotion continuous while upper+weapon recoil and fire FX play. Add an explicit presentation recovery phase before held; reuse existing trailing fire frames only if deterministic frame review and runtime-scale evidence show a clean settle. If the strip cannot provide a visually clean recovery, record the required `recover_sidearm_01` asset and fail/defer that sub-acceptance rather than accepting a snap/tween shortcut.
  8. Keep reload movement-locked and whole-body/committed. Do not force a locomotion lower under reload simply to maximize modular usage. Dedicated sidearm reload art remains separate if still absent.
  9. Preserve complete-stack fallback. Missing upper/weapon/FX must never produce half a body or floating gun; use the last complete valid presentation/fallback and emit the existing structured failure telemetry.
  10. Remove duplicated actor-local ranged phase/ammo/heat state after controller ownership is complete and update validation ownership.
- Preserve: fire rate, ammo counts, heat tuning, reload timing, 0.70 aim-ready threshold, 0.22/0.12 raise/lower timing unless data authority already differs, ballistic/obstruction rules, muzzle/ejection socket authority, camera aim feedback ownership, sidearm progression/equip gating, fixed tick.
- Non-goals: No new ranged art by default. No static weapon-node migration in this packet; that is `operator-ranged-static-weapon-socket-closeout`. No sidearm reload design. No spread/recoil/balance retune. No movement grant to reload.
- Acceptance: One ranged controller owns ammo/heat/reload/ready/fire/sidearm phase state; definitions remain immutable; primary raise/lower no longer commandeer moving legs and preserve reverse progress; primary fire/ready movement remain unchanged; sidearm held movement shows live lower cadence; sidearm firing preserves lower cadence and cleanly returns through an explicit recovery semantic phase; reload stays movement-locked; missing-layer controls fail closed; all ballistic/socket/ammo/sidearm regressions pass.
- Validation: Add controller-focused state tests plus lower/upper frame-progress continuity checks for raise/lower and sidearm held/fire/recover. Run ranged-ready, primary modular fire, ballistic aim, ammo reconciliation, sidearm canonical, weapon socket, fixed-tick and visual ownership smokes. Use one compact primary strafe-raise/fire/lower and one sidearm strafe-fire Moment Forge evidence capture after deterministic checks because body cadence + aim-facing readability is the actual user-visible acceptance. Finish with one changed-file closeout.
- Task overrides: `none`
- Deferred: Static per-sector weapon node/source-marker/socket authoring closure is `operator-ranged-static-weapon-socket-closeout`. Missing direction/cardinal art goes to `operator-modular-directional-coverage-closeout`.

## Handoff

- Next action: Complete normal lifecycle closeout for this validated implementation, then let the dispatcher evaluate newly available Operator work.
- Best starting files: n/a; F3 implementation and validation are complete.
- Blockers or open questions: none identified in F3 validation; finish/preflight remains to be executed.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: F3 controller and presentation acceptance is covered by seven focused passing checks and 61/61 canonical changed-file tests with complete coverage. Both authored Moment Forge scenarios passed. The stale generated runtime references were removed by canonical publication; all 588 SpriteFrames textures resolve.
- Ranged phase, ammo, heat, reload, pending-shot and sidearm action state are owned by the ranged controller; public Operator APIs delegate through that authority. Movement-permissive primary raise/lower and sidearm held/fire/recovery preserve the movement-owned lower cadence; reload remains committed and movement-locked. Existing ballistic and frame-aware socket behavior remains covered.
- The stale deleted north relaxed-sheet reference was removed from generated runtime manifest and SpriteFrames through the canonical publication pipeline. The generated SpriteFrames contain 588 animations and all 588 texture references resolve to runtime PNGs.
- Focused validation passed: `operator_modular_defense_ranged`, `operator_ranged_ballistic_aim`, `operator_fixed_tick_spine`, `operator_primary_ranged_modular_fire`, `operator_ranged_ready_input`, `operator_sidearm_canonical`, and `operator_weapon_socket` (7/7). Initial cold-import failures were rerun successfully after the canonical Godot import; the first cold `operator_weapon_socket` attempt also failed once before its passing rerun.
- Both authored Moment Forge scenarios passed their assertions and keyframe/telemetry checks: primary `f3-final-primary` and sidearm `f3-final-sidearm`. Their evidence is preserved outside Git at `/home/braydenchaffee/Projects/.custodian-preserved/operator-ranged-domain-extraction/f3-final-evidence-db5bbe4a/`; capture manifests report `partial_media` because the optional audio source is unavailable. No scenario assertion or capture failed.
- Canonical changed-file validation against `origin/main@735b7170f03f89f438f96538dafef741d3288ea0` passed 62/62 tests on the final archived tree, with zero skipped, failed, timed out, or infrastructure-error tests. Coverage is complete for all 14 changed paths; uncovered files: none. This includes both registered Moment Forge scenarios, `operator_2_5d_cohort_dependency_closure`, and `npa_showcase_existing_enemy`. The archived-tree report is preserved externally with SHA-256 `2174e47b816b0bf2fb3b0666ff57b221192102eba559836c07f6c45f5de85d3d`; the earlier 61-test receipt is retained separately.
- Thirteen untracked Godot `.import` sidecars from the validation run were copied and SHA-256 verified outside Git before removing those exact generated files. The validation manifest change remains the only tracked local change before closeout edits.



## Execution Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: stale generated SpriteFrames survived the intentional source deletion until canonical runtime publication was rerun. The first changed-file attempt exposed the independently owned unavailable-source-strip assertion; that correction is now landed. Cold-import focused checks initially failed and passed after canonical import. A first archive-verifier decision depended on incidental administrative commit ordering; the source-strip correction preserved-history fix is landed and its paired review remains separate.
- Root cause / contributing factors: generated SpriteFrames were not synchronized with the runtime manifest, and source evidence availability had been conflated with hash mismatch. The F3 validation manifest initially omitted its two authored Moment Forge scenarios and shared driver ownership; this packet now registers them explicitly.
- Prevention / pipeline improvement: keep generated manifest and SpriteFrames in the canonical publication cycle; distinguish unavailable authoring evidence from tampered bytes; register scenario inputs and driver ownership so changed-file coverage is complete.
- Tooling / docs drift discovered: Godot import does not repair stale SpriteFrames resource paths. First-time cold imports can cause transient false negatives until the canonical import pass completes. The archive verifier correction accepts the legitimate renamed summary and managed-index-only sync based on preserved Git object identity and tree checks. `operator_input_frame` retains single-tick press semantics; ammo reconciliation still lacks a dedicated manifest test ID.
- Follow-up: none
- What worked: existing claim and worktree continued in place under the updated continuity rule; the `2eeb1eb1` source-strip checkpoint and its history were preserved; the correction landed at `735b7170`; canonical publication rebuilt 588 animations with all references resolving; seven focused checks, both authored scenarios, and changed-file validation passed.

## Next Handoff
- Next workstream: none
- Next packet state: none
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: execute the existing F3 preflight and finish lifecycle; then verify `operator-runtime` release and let ordinary dispatch recalculate eligibility.
- Blockers or open questions: finish lifecycle and independent paired-review ordering remain to be verified. Do not claim lock release before a successful finish/audit.
