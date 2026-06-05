# OPERATOR MODULAR LAYERED RUNTIME RIG

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-02
- Created: 2026-06-02
- Last updated: 2026-06-02

## Task

Wire the operator scene for a first true upper/lower modular locomotion rig using the existing modular run/walk/idle assets where available, while preserving the current single-body SpriteFrames path for attacks, portal arrival, ranged stance, and non-modular fallbacks.

## Outcome

The operator has dedicated lower-body and upper-body `AnimatedSprite2D` layers with separate modular SpriteFrames resources. Fists idle/walk/run can display the modular layers when available, and missing modular source art is tracked explicitly.

## Authority

- Root routing: `/home/braydenchaffee/Projects/CUSTODIAN/AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`, `design/features/implementation/UNARMED_TOGGLE.md`
- Active runtime/docs files: `custodian/game/actors/operator/operator.gd`, `custodian/game/actors/operator/operator.tscn`, `custodian/tools/pipelines/build_operator_modular_runtime.py`, `custodian/tools/pipelines/update_operator_curated_resources.gd`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/game/actors/operator/operator.gd`
  - `custodian/game/actors/operator/operator.tscn`
  - `custodian/game/actors/operator/operator_modular_lower_body_frames.tres`
  - `custodian/game/actors/operator/operator_modular_upper_body_frames.tres`
  - `custodian/tools/pipelines/build_operator_modular_runtime.py`
  - `custodian/tools/pipelines/update_operator_curated_resources.gd`
  - `custodian/content/sprites/operator/runtime/modules/new_operator/`
  - `REQUIRED_ASSETS.md`
  - `design/00_meta/REQUIRED_ASSETS.md`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
- Files or folders expected to be read but not changed:
  - `custodian/content/sprites/operator/new_operator/modular/`
  - `custodian/game/actors/operator/operator_runtime_frames.tres`
- Out-of-scope areas:
  - Rewriting melee/ranged attack playback into independent upper-body action layers.
  - Removing legacy single-body animation support.

## Constraints

- Determinism concerns: this changes only visual layer playback; movement/combat timing remains existing operator logic.
- Simulation/UI boundary concerns: modular layers must not own gameplay state or attack windows.
- Asset requirements: upper idle/walk, complete upper run, and lower `action_01` sources are not complete yet.
- Compatibility or migration concerns: legacy body sprite must remain authoritative for attacks and non-modular states.
- Clarifying questions or assumptions: for missing upper-body locomotion directions, temporary runtime fallbacks may reuse available upper run or transparent placeholder sheets until production art exists.

## Implementation Plan

1. Extend the modular runtime builder to emit upper-body locomotion module strips alongside lower-body locomotion.
2. Add separate modular lower/upper SpriteFrames resources and rebuild them from the module folders.
3. Add optional lower/upper `AnimatedSprite2D` layers to the operator scene.
4. Sync layer playback from existing locomotion animation resolution, hiding layers during attacks, portal arrival, reloads, ranged states, and non-modular fallback states.
5. Update docs and required asset trackers with the remaining modular build list.

## Acceptance

- Runtime behavior: Fists idle/walk/run can play lower and upper modular layers independently when the layer animations exist.
- Documentation: current state, file index, and task packet describe the layered state and remaining asset gaps.
- Path/reference validation: scene references the new modular SpriteFrames resources and those resources reference runtime module paths.
- Manual validation: exact SpriteFrames animation presence is checked for lower and upper layer locomotion names.
- Automated/headless validation: modular builder, Godot import, resource rebuild, targeted resource scan, and Godot headless exit.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Required asset tracker updates are enough for this slice.

## Completion Notes

- Implemented: added upper-body locomotion module generation to `build_operator_modular_runtime.py`; fixed lower idle source resolution so authored N/E/SE/S/SW/W lower idle sheets are consumed; added `operator_modular_lower_body_frames.tres` and `operator_modular_upper_body_frames.tres`; added `ModularLowerBodySprite` and `ModularUpperBodySprite` to `operator.tscn`; synced modular unarmed idle/walk/run layers from `operator.gd` while preserving the legacy body sprite for timing, attacks, portal arrival, ranged states, and fallbacks; updated module README, current state, file index, and required asset trackers.
- Validated: generated 72 modular runtime sheets; checked lower/upper module dimensions are all `480x96`; ran Godot import; rebuilt operator curated resources; verified lower/upper modular SpriteFrames contain representative idle/walk/run 8-way animations; ran `godot --headless --path custodian --quit`.
- Deferred: production upper-body idle/walk sheets, upper-body run NE/NW, lower-body `action_01`, upper-body `action_01`, lower-body walk non-E/W, lower-body idle NE/NW, live layered attack upper/lower separation, and in-editor visual QA.

## Next Steps

- Next action: visually test Fists idle/walk/run in-game across 8 directions and replace generated fallback upper/lower sheets as production art arrives.
- Best starting files: `custodian/game/actors/operator/operator.gd`, `custodian/game/actors/operator/operator.tscn`, `custodian/tools/pipelines/build_operator_modular_runtime.py`.
- Required context: modular locomotion layers are presentation-only; attack windows and action timing still use the existing body sprite and shared attack state.
- Validation to run: modular builder, Godot import, operator curated resource rebuild, targeted SpriteFrames scan, and in-editor 8-direction locomotion QA.
- Blockers or open questions: full action layering needs authored upper/lower action suites beyond current fast-strike composites.
