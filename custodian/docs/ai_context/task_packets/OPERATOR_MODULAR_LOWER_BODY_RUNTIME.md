# OPERATOR MODULAR LOWER BODY RUNTIME

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-01
- Created: 2026-06-01
- Last updated: 2026-06-01

## Task

Create a robust runtime home and ingest/build path for the new modular operator lower-body modules, make modular lower-body idle/walk/run the default Fists movement source through the existing operator SpriteFrames rebuild, and correct stale east/west fast-strike `128px` slicing after the source canvas was revised toward `96px`.

## Outcome

The modular operator source suite can be rebuilt into stable runtime module folders without ad hoc copying. Fists movement defaults to modular lower-body `idle_01`, `walk_01`, and `run_01` where available, with explicit fallbacks and missing source art tracked.

## Authority

- Root routing: `/home/braydenchaffee/Projects/CUSTODIAN/AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/operator/UNARMED_TOGGLE.md`, `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`, `custodian/docs/ASSET_LAYOUT_CONVENTION.md`
- Active runtime/docs files: `custodian/tools/pipelines/update_operator_curated_resources.gd`, `custodian/game/actors/operator/operator_runtime_frames.tres`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/tools/pipelines/build_operator_modular_runtime.py`
  - `custodian/content/sprites/operator/runtime/modules/new_operator/`
  - `custodian/content/sprites/operator/runtime/actions/unarmed/fast_attack/`
  - `custodian/tools/pipelines/update_operator_curated_resources.gd`
  - `custodian/game/actors/operator/operator_runtime_frames.tres`
  - `custodian/game/actors/operator/operator_melee_overlay_frames.tres`
  - `REQUIRED_ASSETS.md`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
  - `custodian/docs/ai_context/task_packets/README.md`
- Files or folders expected to be read but not changed:
  - `custodian/content/sprites/operator/new_operator/modular/`
  - `custodian/game/actors/operator/operator.gd`
  - `custodian/game/actors/operator/operator.tscn`
- Out-of-scope areas:
  - A full live upper/lower-body layered operator scene rig.
  - Rewriting the generic manifest ingest path for every sprite domain.

## Constraints

- Determinism concerns: movement input and attack timing remain runtime/gameplay-owned; this changes only presentation assets.
- Simulation/UI boundary concerns: lower-body modules are consumed by the current single body `AnimatedSprite2D` until a layered rig exists.
- Asset requirements: missing `action_01`, directional idle, and directional walk lower-body source art must be tracked.
- Compatibility or migration concerns: legacy unarmed movement sheets remain available as fallback assets.
- Clarifying questions or assumptions: `action_01` is treated as the explicit lower-body fallback target, but no such source exists yet; until authored, the builder falls back to available `run_01` or existing legacy runtime sheets.

## Implementation Plan

1. Add a modular operator runtime builder that writes stable module assets under `content/sprites/operator/runtime/modules/new_operator/`.
2. Generate lower-body locomotion module strips for idle/walk/run with per-direction fallback policy, and regenerate fast-strike body/FX runtime strips with `96px` frame metadata where appropriate.
3. Wire the operator SpriteFrames rebuild to use the lower-body module strips for Fists movement defaults.
4. Track missing production source sheets in both required-asset trackers.
5. Regenerate SpriteFrames and run targeted validation.

## Acceptance

- Runtime behavior: Fists idle/walk/run SpriteFrames are rebuilt from modular lower-body runtime modules where module assets exist.
- Documentation: task packet, current state, file index, and required asset trackers are updated.
- Path/reference validation: module runtime assets live under `content/sprites/operator/runtime/modules/new_operator/` and are referenced by the rebuild script.
- Manual validation: generated dimensions show `96px` frame canvases for corrected fast-strike east/west runtime outputs.
- Automated/headless validation: run modular builder, Godot import, operator SpriteFrames rebuild, targeted animation scan, and Godot headless.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Required asset tracker update is enough for this slice.

## Completion Notes

- Implemented: added `build_operator_modular_runtime.py`; created `content/sprites/operator/runtime/modules/new_operator/` with lower-body locomotion modules and local README; generated 8-way lower-body `idle_01`, `walk_01`, and `run_01` runtime strips; regenerated modular fast-action body/FX strips; updated `update_operator_curated_resources.gd` so Fists movement defaults are rebuilt from module paths and fast-strike east/west body/FX slice as `96x96`; tracked missing `action_01`, directional idle, and directional walk source assets in both required-asset trackers.
- Validated: builder generated 48 runtime sheets; generated dimensions checked with Pillow; `REQUIRED_ASSETS.md` copies verified identical; `godot --headless --path custodian --import --quit`; `godot --headless --path custodian --script res://tools/pipelines/update_operator_curated_resources.gd`; targeted scans confirmed module paths and 8-way movement names in `operator_runtime_frames.tres`; exact atlas-region check confirmed fast-strike body/FX right/left use `96x96`; `godot --headless --path custodian --quit`.
- Deferred: full layered upper/lower-body operator rig, authored lower-body `action_01`, true non-south idle source sheets, true non-east/west walk source sheets, and in-editor visual QA.

## Next Steps

- Next action: visually review Fists movement and fast strike in-game; author missing modular lower-body source sheets listed in `REQUIRED_ASSETS.md`.
- Best starting files: `custodian/tools/pipelines/update_operator_curated_resources.gd`, `custodian/content/sprites/operator/new_operator/modular/`
- Required context: current operator is still a single body sprite plus overlays; lower-body modules are an interim presentation source.
- Validation to run: in-editor or recorded gameplay visual QA for all 8 Fists movement directions and fast-strike east/west.
- Blockers or open questions: `modular_lower_body action_01` source does not exist yet, and the current operator scene still uses one body sprite rather than a live layered rig.
