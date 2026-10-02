# OPERATOR RUNTIME SHELL COLLAPSE — SLICE G

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-runtime-shell-collapse`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-dependency-injection-spine, operator-loadout-domain-extraction, operator-melee-domain-extraction, operator-ranged-domain-extraction, operator-dodge-domain-extraction, operator-interaction-domain-extraction, operator-recovery-domain-extraction, operator-guard-parry-composition-polish, operator-ranged-static-weapon-socket-closeout`
- Locks: `operator-runtime`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `b252b5392aabaaa74f1203c3759a2584e6def726`
- Goal: Finish the Operator strangler migration by collapsing `operator.gd` and `operator.tscn` into a thin deterministic actor chassis over the extracted authorities, deleting temporary compatibility seams and making all Operator architecture audits hard-zero final gates.
- Completion boundary: Done when the actor retains only CharacterBody2D movement application, lifecycle/orchestration, stable public facade delegation and minimal scene-owned presentation nodes; melee/dodge/ranged/loadout/interaction/recovery state has one external owner each; temporary presentation/runtime compatibility seams have zero consumers and are removed; scene children are organized by current ownership; Knight/debug production-only construction residue is moved out where appropriate; and runtime-animation/path/architecture audits all pass `--final`.
- Current measured state: Slice E is complete, but `operator.gd` remains 14,587 lines / 711 functions on the reviewed pre-roadmap main and still contains the six future domain families plus 38 absolute scene lookups and three mutable weapon-definition runtime fields. F0 and F1-F6 packets now own those debts explicitly. `OperatorPresentationController`, `OperatorBodyPresenter`, `OperatorAnimationPlayer` and `OperatorAnimationSelector` already establish the presentation authority; Slice G must not recreate policy in the actor while cleaning the shell.
- Evidence: Operator runtime architecture; architecture debt baseline/audit; F0/F1-F6 packets; `operator.tscn`; final runtime animation/path audits; current FILE_INDEX/ownership map.
- Task-specific authority: `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`; `INTEGRATION_CONTRACT_GLUE_LAYER.md`; architecture/runtime path/animation authority audits.
- Work surface: `operator.gd`, `operator.tscn`, extracted Operator controller/presentation directories, validation ownership/index/current-state/architecture map. No feature redesign.
- Change:
  1. Re-measure live main after every dependency is archived complete. Do not carry this packet's line/function/debt counts forward as acceptance targets.
  2. Remove actor-local state/helpers now fully owned by extracted controllers. Keep thin facade methods/signals only when external consumers still use them; point them directly at the owning authority.
  3. Reorganize `operator.tscn` into clear controller/presentation/socket/hitbox/feedback ownership without changing world-space registration or gameplay root/collision.
  4. Remove temporary compatibility nodes, presentation aliases/seams and no-consumer helpers only after runtime reachability proves zero use. Full-body presentation remains first-class.
  5. Move Knight test-skin and any runtime-built debug frame/catalog residue out of production Operator authority where current design marks it development-only.
  6. Ensure each extracted controller receives explicit dependencies and none performs absolute scene lookup/service-locator discovery.
  7. Refresh `CURRENT_STATE.md`, `FILE_INDEX.md`, architecture ownership map and runtime architecture to the landed tree. Historical packets/summaries remain history.
  8. Run `operator_architecture_debt_audit.py --final`, `operator_runtime_path_audit.py --final` and `operator_runtime_animation_authority_smoke.py --final`; make final zero a default validation expectation.
- Preserve: public Operator APIs/signals used by the game, exact gameplay tuning/timing, movement root/collision, presentation pixels/timing from the preceding slices, campaign death/recovery behavior, deterministic fixed step.
- Non-goals: No new art. No combat/balance retuning. No optional guard-break or directional-art fulfillment requirement. No generic ECS/framework rewrite. No conversion of cinematic presentation rigs into gameplay controllers.
- Acceptance: Final audits are zero/green; no domain has duplicate actor/controller state authority; no production Operator behavior relies on deleted compatibility seams; one `move_and_slide()` owner remains the actor chassis; current presentation ownership invariants remain green; scene registration/collision/visual anchor is unchanged; focused domain regressions and one actor-tier closeout remain green.
- Validation: Run all three final audits first after structural edits, then focused facade/delegation smokes for touched domains and visual-anchor/ownership checks. Only one actor-tier broad sweep at closeout after checking resource budget. Moment Forge is unnecessary unless shell edits unexpectedly alter presentation ordering; if so, run only the affected existing scenario in evidence mode.
- Task overrides: `none`
- Deferred: `operator-guard-break-presentation` and `operator-modular-directional-coverage-closeout` are optional content/polish follow-ups and do not block architecture closure. Dormant head/cape remain preserved unless a future dedicated art/presentation pass reactivates them.

## Handoff

- Next action: Execute only after F0/F1-F6, guard/parry polish and static ranged socket closeout are archived complete; remeasure before deleting anything.
- Best starting files: `operator.gd`; `operator.tscn`; architecture debt/runtime path/runtime animation audits; extracted controller APIs.
- Blockers or open questions: None once dependencies complete.
