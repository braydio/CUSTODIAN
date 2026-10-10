# OPERATOR BASELINE VALIDATION REHABILITATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-baseline-validation-rehabilitation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-mobile-guard-composition`
- Locks: `operator-runtime, operator-validation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, workflow`
- Paired review workstream: `review-operator-baseline-validation-rehabilitation`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `three unrelated Operator baseline failures block the already-implemented stealth-perception workstream; repairs must distinguish stale fixtures from real runtime regressions and preserve test strength`
- Reviewed main: `03a584ee436cba35cc5f350bfc2e6e557a289fab`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Restore trustworthy validation for the ranged parry-counter, unarmed-chain carry, and Vigil Dagger camera-contact contracts without weakening combat behavior or its regression assertions.
- Completion boundary: Complete when the three named Operator validation checks pass on current imported `origin/main`, each test establishes valid runtime/fixture preconditions and fails when its protected contract is broken, and the full changed-file sweep is green. Fix fixture setup where the test is stale; change production behavior only if a traced runtime defect is proven against current design authority. Do not modify the stealth-perception implementation.
- Current measured state: The three checks failed on a clean imported `origin/main@5e7c8e58a4b67dc8c29e85d4ab952e5f3fc07178` with these assertions: `operator_ranged_ready_input` expected a buffered counter strike after parry-success release; `operator_unarmed_fast_chain` found no live carry before interruption/collision; `operator_vigil_dagger` did not resolve its impact probe through the Operator camera dependency. Current `origin/main` is `03a584ee436cba35cc5f350bfc2e6e557a289fab`; its LFS preflight currently reports 15 unrelated Awakening image pointers, so import and current-main reproduction must first hydrate those files in the claimed worktree and rerun the preflight. `operator-runtime` is held by the active `operator-mobile-guard-composition` workstream; this packet depends on it and will remain auto-gated until that workstream archives complete.
- Evidence: `custodian/tools/validation/operator_ranged_ready_input_smoke.gd` (`_validate_offhand_parry_guard`); `custodian/game/actors/operator/combat/operator_guard_controller.gd` (`tick`, parry phase transitions); `custodian/game/actors/operator/operator.gd` (`_try_queue_parry_counter_from_block`, `guard_enter_post_parry_neutral`, `_request_attack_state`); `custodian/tools/validation/operator_unarmed_fast_chain_smoke.gd` (`_install_live_carry`, interruption and wall-truncation cases); attack-drive handoff state in `operator.gd`; `custodian/tools/validation/operator_vigil_dagger_smoke.gd` (`_create_operator`, `_validate_multi_target_and_miss`); `custodian/game/actors/operator/operator_runtime_dependencies.gd`; `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`; `design/02_features/combat_feel/OPERATOR_MELEE_ATTACK_DRIVE.md`; `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`.
- Task-specific authority: `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md` owns the typed runtime dependency boundary; `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md` owns guard/parry input and counter timing semantics; `design/02_features/combat_feel/OPERATOR_MELEE_ATTACK_DRIVE.md` owns chain carry behavior and collision truncation.
- Work surface: The three named Operator smoke fixtures, only the directly implicated Operator runtime methods/controllers if state tracing proves a production defect, the narrowest validation manifest ownership needed for those tests, and consequence-driven test documentation. Leave the stealth branch and its files untouched.
- Change:
  1. Reproduce all three failures on clean current `origin/main` after the LFS preflight passes and project import completes. Record the exact failing assertion and live state before selecting a fix.
  2. For `operator_ranged_ready_input`, trace the buffered attack, parry-success phase/recovery, counter-window timer, guard release, `_request_attack_state`, and fixed-tick progression. Assert the strike at the authoritative lifecycle boundary: immediately if the current contract starts it immediately, or after the exact required fixed update if the runtime contract schedules it. Confirm the attack starts once and that the no-buffer control does not start one. Do not add timing or weaken the state assertion without source-backed evidence.
  3. For `operator_unarmed_fast_chain`, make the setup use a valid authored chain-step handoff. Before each interruption and collision assertion, prove the carry was genuinely installed with nonzero direction, speed, remaining distance, and time under an incoming drive delay. Add a negative control showing an invalid/non-successor handoff does not install carry. Preserve the existing damage/block/dodge clearing and blocked-versus-clear collision comparisons; repair the fixture only if live production carry semantics are correct.
  4. For `operator_vigil_dagger`, provide the impact probe through the canonical `OperatorRuntimeDependencies`/world composition setup before Operator `_ready()` binds dependencies. Assert `_get_world_camera()` is that exact probe, confirmed contacts call it exactly once with authored values, and misses do not call it. Do not add legacy absolute scene-path lookup or post-ready rediscovery to production code.
  5. Change production gameplay only if the trace demonstrates a real contract violation and the correction preserves authored combat values, fixed-step ownership, and dependency architecture. Keep tests behavior-sensitive; do not delete assertions, broaden tolerances to mask errors, or suppress diagnostics.
- Preserve: Existing counter-window and parry timings, attack start/commit semantics, chain drive distance/speed/time budgets, interruption cancellation, wall collision truncation, camera feedback values and exactly-once contact ownership, dependency injection, fixed-step simulation, and the separate stealth-perception implementation.
- Non-goals: No combat rebalance, parry/riposte feature work, chain-drive redesign, camera architecture migration, test-suite quarantine, generic assertion weakening, visual baseline update, or NPA/Vaultwing/stealth code change.
- Acceptance:
  1. `operator_ranged_ready_input` proves a buffered parry counter starts exactly once at the valid post-release/fixed-step boundary and a no-buffer control starts none.
  2. `operator_unarmed_fast_chain` proves a real valid carry exists before it is interrupted/truncated, validates its positive live fields, and includes an invalid-handoff no-carry control.
  3. `operator_vigil_dagger` injects the camera probe through the canonical dependency composition before `_ready()`, proves the Operator resolves that identity, preserves authored camera feedback values, and makes miss/no-contact produce no call.
  4. Each regression fails if its protected behavior is intentionally removed or its required fixture precondition is absent; no protected assertion is deleted or weakened.
  5. Production changes, if any, are limited to a source-proven bug necessary for the packet contracts and preserve actual combat tuning/ownership.
  6. `python3 custodian/tools/validation/run_validation.py --test operator_ranged_ready_input --json`, `--test operator_unarmed_fast_chain --json`, and `--test operator_vigil_dagger --json` pass on imported current main.
  7. `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json` passes with complete file coverage; `git diff --check`, `check_ai_context.py --json`, and `validate_review_pairing.py` pass.
  8. No changed path belongs to stealth-perception.
- Validation: First inspect `free -h` and existing Godot processes; run `python3 custodian/tools/pipelines/godot_import_preflight.py --project-dir custodian` in the claimed worktree. If it reports LFS pointers, hydrate LFS files in that worktree, rerun preflight, and import only after it passes. Reproduce the three focused failures on clean current main before editing. Trace the three fixture/runtime states, apply the narrow repair, then run each focused test serially. Finish with one `--changed --base origin/main --json` sweep, `git diff --check`, `python3 custodian/tools/agent/check_ai_context.py --json`, and `python3 custodian/tools/agent/validate_review_pairing.py`. Do not overlap Godot sweeps with other Godot runs.
- Task overrides: `none`
- Deferred: Any separate Operator gameplay redesign proven necessary by the investigation; stealth-perception finish/review remains its own preserved branch and must be resumed only after this repair lands.

## Context Pack

- Repomix: `recommended`
- Include: `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md,design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md,design/02_features/combat_feel/OPERATOR_MELEE_ATTACK_DRIVE.md,custodian/game/actors/operator/combat/operator_guard_controller.gd,custodian/game/actors/operator/operator_runtime_dependencies.gd,custodian/tools/validation/operator_ranged_ready_input_smoke.gd,custodian/tools/validation/operator_unarmed_fast_chain_smoke.gd,custodian/tools/validation/operator_vigil_dagger_smoke.gd`
- Purpose: Bound the three regression contracts, fixed-tick parry state flow, chain carry ownership, and canonical Operator dependency setup.
