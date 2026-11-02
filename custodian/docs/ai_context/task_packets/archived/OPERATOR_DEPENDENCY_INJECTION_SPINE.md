# OPERATOR DEPENDENCY INJECTION SPINE — SLICE F0

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-dependency-injection-spine`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `operator-runtime`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `03b6221adb01402b1cf4393b9a1773cdd519f6ae`
- Goal: Retire the remaining absolute scene-tree lookup debt before domain extraction so every later Operator controller receives explicit dependencies instead of rediscovering global services through `/root/...`.
- Completion boundary: Done when `operator.gd` and newly touched Operator-owned runtime helpers contain zero production absolute `/root/...` scene lookups; the actor/facade receives or binds the required services through one explicit integration seam; each domain can be extracted without importing global scene topology; behavior is unchanged; and `absolute_scene_lookups` moves 38 -> 0 in the architecture debt baseline.
- Current measured state: At the fresh claim head, the audit found 37 live `absolute_scene_lookups` in `operator.gd` (the older packet count of 38 was stale by one) and 3 mutable weapon-definition runtime fields. The lookups spanned InventoryManager/WeaponDefinitionFactory, CognitiveState, projectile/world containers, DevObservatory, heatmap/material intelligence, camera, NoiseEventBus, InputPromptService, WorldHistory/GameState, debug DevMode, build/terminal services and UI. Action arbitration/presentation are already extracted; six domain controllers are still absent. After F0, the audit reports zero absolute lookups and retains only the three weapon-state findings for F1.
- Evidence: `custodian/tools/validation/operator_architecture_debt_baseline.json`; exact `/root/` call sites in `custodian/game/actors/operator/operator.gd`; `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`; current game/world binding patterns.
- Task-specific authority: `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`; `design/04_architecture/INTEGRATION_CONTRACT_GLUE_LAYER.md`; architecture debt audit.
- Work surface: Operator scene/facade construction and the narrow existing world/binding seams that can supply dependencies; architecture audit; focused tests covering affected services. This packet does not extract melee/ranged/dodge/loadout/interaction/recovery behavior.
- Change:
  1. Characterize all 38 live absolute lookups on fresh main and group them by service/dependency before editing. The packet closes the measured debt family, not a remembered list.
  2. Introduce the smallest explicit dependency-binding seam that fits current Godot architecture. Prefer scene-assigned NodePaths/references, typed binders, or one actor dependency object supplied by the owning world/runtime composition root. Do not create a service locator that merely hides `/root/` strings behind another API.
  3. Convert each current lookup to an injected/bound reference with fail-closed behavior matching the old optional/required semantics. Optional telemetry/debug services stay optional; required world services must report a clear integration error instead of silently fabricating a substitute.
  4. Keep `operator.gd` as the sole `CharacterBody2D` movement owner. Dependency binding may shrink helper code but must not move domain state yet.
  5. Make the dependency seam directly consumable by later Slice F controllers so they can receive only what they need. Do not make future controllers reach back into the actor for global scene discovery.
  6. Update validation ownership so edits to the binding surface select a focused dependency/integration smoke.
  7. Refresh the debt baseline from fact after validation. Expected result is `absolute_scene_lookups: 38 -> 0` with the three weapon-definition runtime-state findings still present for the loadout slice.
- Preserve: gameplay timing, camera behavior, cognitive modifiers, projectile parenting, telemetry, world-history/death behavior, terminal/build/repair behavior, input prompts, debug-only services, all public Operator APIs/signals.
- Non-goals: No domain extraction. No weapon runtime-state migration. No feature/presentation retuning. No new art. No broad GameRoot/world architecture rewrite. No generic dependency-injection framework for unrelated actors.
- Acceptance: Architecture audit shows zero absolute Operator scene lookups and exactly the factual remaining debt; repository search finds no production Operator `get_node("/root/...")` or `get_node_or_null("/root/...")`; every replaced dependency has a deterministic positive and missing/optional behavior check where relevant; focused combat/ranged/build/death/input regressions remain green; later controller code can be passed explicit references without scene discovery.
- Validation: The dependency-binding smoke, architecture audit, fixed-tick/input/ranged/guard/death regressions, and powered-fabricator slice passed. The standalone Field Patch smoke failed the same attack-interrupt and fabrication assertions on this branch and untouched current main. The changed-file closeout selected 54 checks, with 15 passing, one failing, and 38 skipped after `review_pairing_contract` found five malformed bounded `TASK OVERRIDE` fields in unrelated current-main review packets (`review-contract-world-playable-region-spawn-validity-fix`, `review-isometric-2-5d-presentation-foundation`, `review-sundered-keep-overlook-alternate-art-polish`, `review-sundered-keep-overlook-alternate-vertical-slice`, `review-sundered-keep-overlook-runtime-integration-plan`). Re-running the pairing validator against fetched current `main` reproduced those errors. These unrelated packet defects remain unchanged and the changed-file closeout is not green. Moment Forge is not required because behavior/presentation should be unchanged.
- Task overrides: `none`
- Deferred: The three mutable weapon-definition fields move in `operator-loadout-domain-extraction`; domain logic leaves `operator.gd` in the six Slice F packets; final scene/shell cleanup belongs to Slice G.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `high`
- What went wrong: `the fresh worktree had no Godot global-class/import cache, the claim-time count was 37 rather than the packet's 38, Field Patch assertions fail on unchanged main, and changed-file validation is gated by five unrelated malformed review packets`
- Root cause / contributing factors: `workstream setup intentionally omits generated editor state; the audit baseline had not recorded one lookup already removed upstream; Field Patch assertions fail identically on current main; review-pairing unit validation rejects unrelated packet metadata before downstream changed-file tests run`
- Prevention / pipeline improvement: `the new binding smoke declares its import requirement so fresh worktrees initialize the class/resource cache; baseline and current-state docs use the measured zero-lookup state`
- Tooling / docs drift discovered: `the old absolute WeaponDefinitionFactory path named a World child, while the live main scene owns that factory under GameRoot; the binder resolves the existing composition-root placement`
- Follow-up: `manual-follow-up`
- What worked: `typed data-only bundle keeps lookup ownership at one facade seam and optional dependencies stay nullable`

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `operator_architecture_debt_audit.py --json` reports zero absolute scene lookups and exactly three weapon-definition runtime-state findings; operator dependency smoke and selected movement/input/ranged/death/build regressions pass. The changed-file run selected 54 checks but did not complete: 15 passed, `review_pairing_contract` failed on five unrelated current-main review packets, and 38 were skipped. This validation limitation is recorded; it is not represented as complete coverage.

## Handoff

- Next workstream: `operator-mobile-guard-composition`
- Next packet state: `ready`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: `Claim the independent movement-owned-lower/action-owned-upper guard composition packet; loadout extraction becomes eligible after that seam and F0 are both complete.`
- Blockers or open questions: `none`
