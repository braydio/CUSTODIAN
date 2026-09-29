# Operator Twin-Stick Dodge Input

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-05
- Created: 2026-06-05
- Last updated: 2026-06-05

## Task

Wire the full keyboard/mouse and Xbox control scheme for movement, aim, ranged hold/fire, dodge/backstep, interaction, inventory, reload, quick item, cycle item, pause, and map actions.

## Outcome

The operator can move with WASD or left stick, aim with mouse or right stick, hold aim with RMB/LT, fire with LMB/RT, and dodge with Space/B using movement-first direction and idle aiming hop-back behavior.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`, `design/02_features/animation/WEAPON_OWNED_ANIMATION_SYSTEM.md`
- Active runtime/docs files: `custodian/project.godot`, `custodian/game/actors/operator/operator.gd`, `custodian/docs/ai_context/*`
- Historical reference only: archived input packets under `custodian/docs/ai_context/task_packets/archived/`

## Work Surface

- Files or folders expected to change: project input map, operator runtime script, focused validation script, combat/input docs, AI context.
- Files or folders expected to be read but not changed: existing operator scene/resources and dodge source art.
- Out-of-scope areas: production-authored directional dodge suite, quick item inventory behavior beyond reserving input, production pause/menu redesign.

## Constraints

- Determinism concerns: dodge direction must resolve from current input state and existing facing/aim vectors without nondeterministic side effects.
- Simulation/UI boundary concerns: input map changes should preserve existing consumers through compatibility aliases where reasonable.
- Asset requirements: only one north-facing dodge body/FX strip exists; V1 can mirror/rotate via direction/facing fallback but must not pretend a full directional suite exists.
- Compatibility or migration concerns: existing code listens for `attack_primary`, `attack_secondary`, `reload_weapon`, `toggle_inventory`, `toggle_minimap`, and `pause`; new canonical names should alias rather than strand current systems.
- Clarifying questions or assumptions: RT primary outside aim may quick panic-shot for ranged loadout/fallback; melee/unarmed primary remains profile attack.

## Implementation Plan

1. Normalize InputMap actions and aliases for keyboard/mouse plus Xbox controls.
2. Add controller right-stick aim source and movement/facing priority in `operator.gd`.
3. Add dodge/backstep runtime movement and fallback animation playback using available dodge strip.
4. Extend focused smoke coverage and update active docs/context.

## Acceptance

- Runtime behavior: left stick moves, right stick aims, LT/RMB holds ranged-ready, RT/LMB fires, Space/B dodges with movement-first and idle-aim hop-back logic.
- Documentation: active docs and AI context describe the new bindings and dodge rule.
- Path/reference validation: dodge asset path and input action names resolve.
- Manual validation: user will test with Xbox controller.
- Automated/headless validation: focused input smoke plus project load.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? Maybe.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes.

## Completion Notes

- Implemented: InputMap aliases for the requested keyboard/mouse and Xbox scheme; right-stick aim and left-stick movement in `operator.gd`; held ranged-ready LT/RMB with RT/LMB fire; ranged loadout panic shot when not aiming; Space/B dodge with movement-first, idle aiming backstep, and idle facing fallback; runtime injection of the existing dodge body/FX strips.
- Validated: `godot --headless --path custodian --script res://tools/validation/operator_ranged_ready_input_smoke.gd`; `godot --headless --path custodian --quit`.
- Follow-up: dodge FX now plays on a dedicated `DodgeFXBackSprite` behind/under the Custodian body, synchronized from frame 0 with the body dodge strip and offset opposite the dodge direction. The runtime still uses the existing north FX strip as a fallback.
- Deferred: full directional dodge body/FX production suite, true modular ranged-ready/fire upper/cape/weapon/FX assets, quick-item inventory behavior, and production reticle polish.

## Next Steps

- Next action: test LT/RT/right-stick feel on an Xbox controller and tune `dodge_speed`, `dodge_duration`, `dodge_cooldown`, and `ranged_ready_move_multiplier` if the feel is too sharp or too slow.
- Best starting files: `custodian/project.godot`, `custodian/game/actors/operator/operator.gd`.
- Required context: existing ranged-ready input packet and operator modular runtime docs.
- Validation to run: `godot --headless --path custodian --script res://tools/validation/operator_ranged_ready_input_smoke.gd`; `godot --headless --path custodian --quit`.
- Blockers or open questions: no runtime blocker; only one dodge direction asset exists, and the missing directional body/FX suite is tracked in `REQUIRED_ASSETS.md`.
