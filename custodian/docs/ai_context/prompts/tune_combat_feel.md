# Tune Combat Feel

Read `custodian/AGENTS.md` first.
Then read `CURRENT_STATE.md`, `FILE_INDEX.md`, and the linked design doc.

## Task
Tune combat feel for: **[weapon_type or enemy_type]**

## Rules
- Preserve deterministic fixed-step simulation.
- Keep rendering/UI separate from simulation authority.
- Create or update a task packet for non-trivial work.
- Update `CURRENT_STATE.md` if behavior changes.
- Update `FILE_INDEX.md` if ownership or entrypoints change.
- Follow `custodian/docs/ai_context/VALIDATION_RECIPES.md`.

## Context Files
- `custodian/AGENTS.md` — Local routing and working rules
- `custodian/docs/ai_context/CURRENT_STATE.md` — Live runtime state
- `custodian/docs/ai_context/FILE_INDEX.md` — File ownership map
- `custodian/docs/ai_context/CONTEXT.md` — Full context overview
- `custodian/docs/ai_context/VALIDATION_RECIPES.md` — Validation command guide
- Combat design: `design/[combat_design].md` — Combat specifications

## Combat Systems to Reference
- **Player controller**: `custodian/game/systems/core/player_controller.gd`
- **Operator actor**: `custodian/game/actors/operator/operator.gd`
- **Enemy base**: `custodian/game/actors/enemies/enemy.gd`
- **Weapon definitions**: `custodian/game/actors/operator/operator_weapon_definition.gd`
- **Animation state machine**: `custodian/game/actors/operator/animations/`

## Cognitive State Modifiers (Phase B Integration)
Check `custodian/game/systems/cognitive/cognitive_state_system.gd` for:
- `get_move_speed_multiplier()` — Player movement speed
- `get_attack_recovery_multiplier()` — Attack recovery time
- `get_player_accuracy_bonus()` — Player attack accuracy
- `get_enemy_accuracy_bonus()` — Enemy tracking/accuracy
- `get_input_delay_variance()` — Input delay for discrete actions

## Tuning Notes
- Use `custodian/game/actors/operator/operator_weapon_definition.gd` for the weapon profile schema and concrete `*.tres` profile resources such as `custodian/game/actors/operator/unarmed_definition.tres`
- Test in `custodian/scenes/game.tscn`
- Consider cognitive state effects from Forest Shrumb items
- Check `custodian/game/actors/effects/` for hit/spark effects
- Validate with different cognitive states (DRIFT, FLOW, ALIGNMENT, MIXED)
