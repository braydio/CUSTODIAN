# OPERATOR RANGED DOMAIN EXTRACTION — SLICE F3

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-ranged-domain-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-loadout-domain-extraction, operator-dependency-injection-spine, operator-mobile-guard-composition`
- Locks: `operator-runtime`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `03b6221adb01402b1cf4393b9a1773cdd519f6ae`
- Goal: Extract primary-ranged/sidearm combat state into one ranged authority and make all movement-permissive ranged presentation use the same lower-locomotion + upper/weapon action contract that already works during primary fire.
- Completion boundary: Done when ammo/heat/reload/fire-ready/pending-shot/sidearm phase state is owned behind an `OperatorRangedController`-class authority using `OperatorWeaponRuntimeState`; Operator public ranged APIs remain delegates; primary raise/ready/fire/recover/lower and sidearm draw/held/fire/recover express legal movement without frozen/sliding lower-body poses; movement-locked reload remains committed; and current ballistic/socket authority is preserved for a later static-weapon closeout.
- Current measured state: Primary ranged ready movement already composes movement-owned lower cadence with aim-owned upper+weapon stance, and primary fire already keeps lower locomotion while upper/weapon/FX fire. The 5-frame primary `aim_01` raise and reverse lower currently replace both lower and upper despite movement remaining legal, while its partial-progress reverse logic is already robust. Sidearm draw/fire uses four-diagonal 5-frame lower+upper+weapon+FX stacks; held state freezes every layer on the final draw frame, so moving with the sidearm held can display frozen legs. Sidearm fire similarly owns the lower body. Reload is explicitly movement-locked and uses a complete committed presentation. Frame-aware Carbine sockets are live for the phase-1 supported sectors.
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

- Next action: Extract ranged state against F1 runtime-state APIs, then replace the remaining movement-permissive lower-body action ownership with the shared presentation seam.
- Best starting files: ranged/sidearm sections of `operator.gd`; weapon runtime state; presentation controller; ranged/sidearm focused smokes.
- Blockers or open questions: None.
