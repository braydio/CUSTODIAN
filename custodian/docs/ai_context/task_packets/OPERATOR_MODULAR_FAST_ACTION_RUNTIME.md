# OPERATOR MODULAR FAST ACTION RUNTIME

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-01
- Created: 2026-06-01
- Last updated: 2026-06-01

## Task

Create a dedicated operator action-runtime folder for modular unarmed fast attack assets, generate body/FX runtime strips from `content/sprites/operator/new_operator/modular/fast_attack/`, and wire the operator's unarmed fast intent to the generated modular action sheets through the existing SpriteFrames rebuild path.

## Outcome

The Operator keeps shared movement/action state ownership but can play modular-derived unarmed fast strike assets from a stable action runtime folder. Missing source art is tracked explicitly while this pass derives safe defaults from available modular sources.

## Authority

- Root routing: `/home/braydenchaffee/Projects/CUSTODIAN/AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/operator/UNARMED_TOGGLE.md`, `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`, `custodian/docs/ASSET_LAYOUT_CONVENTION.md`
- Active runtime/docs files: `custodian/game/actors/operator/operator.gd`, `custodian/game/actors/operator/unarmed_definition.tres`, `custodian/tools/pipelines/update_operator_curated_resources.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/content/sprites/operator/runtime/actions/unarmed/fast_attack/`
  - `custodian/tools/pipelines/update_operator_curated_resources.gd`
  - `custodian/game/actors/operator/unarmed_definition.tres`
  - `custodian/game/actors/operator/attacks/unarmed_fast_attack.tres`
  - `custodian/game/actors/operator/operator_runtime_frames.tres`
  - `custodian/game/actors/operator/operator_melee_overlay_frames.tres`
  - `REQUIRED_ASSETS.md`
  - `design/00_meta/REQUIRED_ASSETS.md`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
  - `custodian/docs/ai_context/task_packets/README.md`
- Files or folders expected to be read but not changed:
  - `custodian/content/sprites/operator/new_operator/modular/fast_attack/`
  - `custodian/game/actors/operator/animations/states/`
  - `design/02_features/operator/`
- Out-of-scope areas:
  - Building a fully new layered live-rendering operator rig.
  - Adding new attack states for windup/strike phases.
  - Deleting legacy operator runtime sheets.

## Constraints

- Determinism concerns: gameplay timing and hit resolution remain simulation-owned by attack profiles and the shared attack states.
- Simulation/UI boundary concerns: rendering assets and SpriteFrames change, but attack state ownership remains unchanged.
- Asset requirements: missing production art must be tracked in both `REQUIRED_ASSETS.md` copies.
- Compatibility or migration concerns: existing unarmed fast sheets remain available as fallback/legacy runtime assets.
- Clarifying questions or assumptions: derive missing north/south lower-body strike frames from available windup lower-body frames for this pass; skip windup FX at runtime until authored.

## Implementation Plan

1. Generate modular-derived runtime body and FX strips under `content/sprites/operator/runtime/actions/unarmed/fast_attack/`.
2. Wire `update_operator_curated_resources.gd` to rebuild `unarmed_fast_strike*` animations from the new action-runtime sheets.
3. Point the fists/unarmed fast animation map and attack profile at `unarmed_fast_strike`, with hit windows adjusted for 3-frame timing.
4. Track missing production lower-body strike and windup FX art in both required-asset trackers.
5. Regenerate SpriteFrames and run Godot validation.

## Acceptance

- Runtime behavior: unarmed fast attack resolves through the existing shared `attack_fast` state and plays `unarmed_fast_strike*` animations.
- Documentation: task packet, current state, file index, and required asset trackers are updated.
- Path/reference validation: generated runtime sheets live under the dedicated action runtime folder and are referenced by the rebuild script.
- Manual validation: inspect generated sheet dimensions for E/W `128px` frames and other directions `96px` frames.
- Automated/headless validation: run the operator SpriteFrames rebuild script, targeted animation-name scan, and Godot headless validation.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Required asset tracker update is enough for this slice.

## Completion Notes

- Implemented: created `content/sprites/operator/runtime/actions/unarmed/fast_attack/` with generated body/overlay strips; wired `unarmed_fast_strike*` body and FX animations through `update_operator_curated_resources.gd`; remapped Fists/unarmed fast intents to `unarmed_fast_strike`; adjusted the 3-frame hit window to frame `2`; tracked missing production modular lower-body and windup FX art in both required-asset trackers.
- Validated: generated sheet dimensions checked with Pillow; `REQUIRED_ASSETS.md` copies verified identical; `godot --headless --path custodian --import --quit`; `godot --headless --path custodian --script res://tools/pipelines/update_operator_curated_resources.gd`; targeted `rg` scan confirmed new animation names in runtime/body and overlay `SpriteFrames`; `godot --headless --path custodian --quit`; `content_asset_audit.py --limit 0`.
- Originally deferred in this slice: live layered rendering beyond baked strike playback, broader phase separation, windup FX coverage, and in-editor/playtest visual timing review.
- Supersession note, 2026-07-06: live modular layered rendering is now wired for unarmed fast windup, strike, and recovery body layers. Authored N/S lower-body strike sheets now exist and are registered. The remaining fast-windup FX tracker entry is narrowed to the optional missing south sheet because windup FX is not part of the current runtime fast-attack phase contract.

## Next Steps

- Next action: visually review Fists fast attack in-game and author the missing modular source art listed in `REQUIRED_ASSETS.md`.
- Best starting files: `custodian/tools/pipelines/update_operator_curated_resources.gd`, `custodian/game/actors/operator/unarmed_definition.tres`
- Required context: modular fast attack source coverage and existing shared unarmed attack state design.
- Validation to run: in-editor or recorded gameplay visual QA for all 8 fast-strike directions.
- Blockers or open questions: full live modular layering needs a later renderer/rig pass; fast windup remains staged as runtime body strips only until authored FX/state timing are approved.
