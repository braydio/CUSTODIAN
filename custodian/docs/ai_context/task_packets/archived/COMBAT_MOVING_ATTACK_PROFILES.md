# COMBAT MOVING ATTACK PROFILES

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-08
- Created: 2026-05-08
- Last updated: 2026-05-08

## Task

Implement the moving-attack combat changes described in `design/COMBAT_FEATURE_CHANGES.md`.

## Outcome

Operator attacks modify movement through phase/profile multipliers instead of hard-locking normal movement for every melee attack. Fast/unarmed attacks stay mobile, heavy attacks are committed, and ranged firing keeps controlled strafing.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/COMBAT_FEATURE_CHANGES.md`, `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`
- Active runtime/docs files: `custodian/game/actors/operator/operator.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/game/actors/operator/operator.gd`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/task_packets/README.md`
  - this packet
- Files or folders expected to be read but not changed:
  - `custodian/game/actors/operator/animations/`
- Out-of-scope areas:
  - rewriting animation layering
  - new combat art
  - replacing existing melee damage/hit-window logic

## Constraints

- Determinism concerns: movement multipliers should be deterministic and local to existing combat state.
- Simulation/UI boundary concerns: operator runtime only, no UI authority.
- Asset requirements: none.
- Compatibility or migration concerns: keep existing primary/secondary intents and existing melee hitbox damage behavior.
- Clarifying questions or assumptions: use the current melee animation/hit-window system as the damage authority; add attack phases primarily for movement and facing control.

## Implementation Plan

1. Add attack phase/profile state to `operator.gd`.
2. Replace normal melee hard movement locks with phase movement multipliers.
3. Lock heavy attack facing to the attack-start direction while allowing fast attacks to remain mobile.
4. Update docs and validate.

## Acceptance

- Runtime behavior: operator can move during unarmed/fast melee attacks.
- Runtime behavior: heavy melee is strongly slowed/rooted during active frames but not frozen for the whole animation.
- Runtime behavior: ranged firing still allows controlled strafing.
- Runtime behavior: melee hitbox direction remains locked to attack start.
- Documentation: current state and task packet reflect the change.
- Automated/headless validation: operator script parse and game scene boot pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: added `AttackPhase` state and movement profiles for unarmed fast, melee fast, melee/unarmed heavy, and ranged fire; removed normal melee attacks from the hard movement lock; applied attack movement multipliers in operator physics; disabled sprint while an attack movement profile is active; preserved locked melee hitbox direction and heavy-facing lock.
- Validated: `godot --headless --check-only --script res://game/actors/operator/operator.gd`; `godot --headless --quit --scene res://scenes/game.tscn`.
- Deferred: deeper animation-layer refactor so moving attacks can use locomotion body frames plus weapon/FX overlays instead of sliding full-body attack frames.

## Next Steps

- Next action: playtest attack movement feel and tune profile values.
- Best starting files: `custodian/game/actors/operator/operator.gd`
- Required context: existing melee state, ranged fire movement, animation state machine.
- Validation to run: Godot script check and scene boot.
- Blockers or open questions: none.
