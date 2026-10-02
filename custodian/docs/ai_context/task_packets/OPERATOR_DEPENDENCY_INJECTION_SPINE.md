# OPERATOR DEPENDENCY INJECTION SPINE — SLICE F0

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-dependency-injection-spine`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `operator-runtime`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `03b6221adb01402b1cf4393b9a1773cdd519f6ae`
- Goal: Retire the remaining absolute scene-tree lookup debt before domain extraction so every later Operator controller receives explicit dependencies instead of rediscovering global services through `/root/...`.
- Completion boundary: Done when `operator.gd` and newly touched Operator-owned runtime helpers contain zero production absolute `/root/...` scene lookups; the actor/facade receives or binds the required services through one explicit integration seam; each domain can be extracted without importing global scene topology; behavior is unchanged; and `absolute_scene_lookups` moves 38 -> 0 in the architecture debt baseline.
- Current measured state: Latest main has 41 architecture-debt findings: 38 `absolute_scene_lookups` in `operator.gd` and 3 mutable weapon-definition runtime fields. The 38 lookups span InventoryManager/WeaponDefinitionFactory, CognitiveState, projectile/world containers, DevObservatory, heatmap/material intelligence, camera, NoiseEventBus, InputPromptService, WorldHistory/GameState, debug DevMode, build/terminal services and UI. Action arbitration/presentation are already extracted; six domain controllers are still absent.
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
- Validation: Run the architecture audit before/after, add one focused dependency-binding smoke, and run only the directly affected existing service regressions first: fixed-tick/input, melee/ranged projectile presentation, camera/ranged aim, Field Patch, build/terminal and death handoff as selected by the changed dependency set. Finish with one changed-file closeout. Moment Forge is not required because behavior/presentation should be unchanged.
- Task overrides: `none`
- Deferred: The three mutable weapon-definition fields move in `operator-loadout-domain-extraction`; domain logic leaves `operator.gd` in the six Slice F packets; final scene/shell cleanup belongs to Slice G.

## Handoff

- Next action: Land this before broad domain extraction so every controller starts with explicit dependencies.
- Best starting files: `operator.gd`; `operator.tscn`; current world binding/integration helpers; architecture debt audit/baseline.
- Blockers or open questions: None.
