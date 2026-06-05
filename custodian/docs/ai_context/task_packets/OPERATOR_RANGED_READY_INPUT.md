# Operator Ranged-Ready Input

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-04
- Created: 2026-06-04
- Last updated: 2026-06-04

## Task

Replace ranged secondary-as-fire behavior with a held ranged-ready/aim stance contract for the modular operator.

## Outcome

Secondary input holds the operator in ranged-ready, keeps movement available, makes the ranged weapon visible, faces aim direction, and only fires when primary is pressed while ranged-ready is active.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`, `design/02_features/animation/WEAPON_OWNED_ANIMATION_SYSTEM.md`
- Active runtime/docs files: `custodian/game/actors/operator/operator.gd`, `custodian/project.godot`, `custodian/docs/ai_context/*`
- Historical reference only: archived attack-input packets under `custodian/docs/ai_context/task_packets/archived/`

## Work Surface

- Files or folders expected to change: operator input/runtime script, carbine definition, input map, combat/animation docs, AI context pack, validation script.
- Files or folders expected to be read but not changed: operator scene, weapon frame resources.
- Out-of-scope areas: new production ranged modular art, quick-shot secondary tap, full upper/lower/cape/weapon/FX modular ranged pipeline.

## Constraints

- Determinism concerns: input handling remains local runtime state; projectile emission continues through the existing delayed shot path.
- Simulation/UI boundary concerns: no HUD prompt rewrite in this slice.
- Asset requirements: use existing ranged stance/fire body and weapon frames as fallback; track true modular ranged-ready/fire assets as future work if absent.
- Compatibility or migration concerns: right mouse moves from block to ranged-ready; block remains on `R`.
- Clarifying questions or assumptions: primary-alone remains close-combat/no ranged shot; primary plus held secondary is the only default ranged fire request.

## Implementation Plan

1. Add a ranged-ready state flag and helper methods to the operator.
2. Route secondary hold to ranged-ready, and primary-while-ready to the existing ranged shot path.
3. Update input bindings and carbine intent naming so secondary no longer maps to fire.
4. Update design/context docs and add a targeted smoke validation.

## Acceptance

- Runtime behavior: secondary held enters ranged-ready; primary fires only while ranged-ready; release exits ranged-ready.
- Documentation: design docs and AI context describe the new contract.
- Path/reference validation: changed docs reference live paths.
- Manual validation: not performed in editor.
- Automated/headless validation: run a focused Godot script plus project load.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? Yes.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes.

## Completion Notes

- Implemented: right mouse and Xbox LT `attack_secondary` now hold ranged-ready/aim, left mouse and Xbox RT `attack_primary` confirm fire, `R` remains block, carbine secondary intent maps to `ranged_ready`, and operator runtime state uses primary fire only while ranged-ready is active.
- Implemented: ranged-ready can temporarily present the carried ranged weapon from non-ranged loadouts without forcing a permanent loadout switch, faces aim direction, applies the ranged-ready move multiplier, and keeps lower-body locomotion available.
- Validated: `godot --headless --path custodian --script res://tools/validation/operator_ranged_ready_input_smoke.gd`.
- Validated: `godot --headless --path custodian --quit` completed after project load; Godot still reports existing exit resource-leak warnings.
- Deferred: true modular ranged-ready/fire upper-body, cape, weapon, muzzle-flash, and smoke production clips are tracked in `REQUIRED_ASSETS.md`; secondary tap quick-shot remains Phase 2 work.

## Next Steps

- Next action: author or ingest the true modular ranged-ready/fire art suite, then replace the fallback ranged stance/fire presentation with layered upper/cape/weapon/FX runtime playback.
- Best starting files: `custodian/game/actors/operator/operator.gd`, `custodian/project.godot`.
- Required context: modular operator layered runtime and current weapon-owned animation docs.
- Validation to run: `godot --headless --path custodian --script res://tools/validation/operator_ranged_ready_input_smoke.gd`; `godot --headless --path custodian --quit`.
- Blockers or open questions: production modular ranged-ready/fire assets are not present yet.
