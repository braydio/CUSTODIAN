# Operator Modular Idle And Ingest

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-05
- Created: 2026-06-05
- Last updated: 2026-06-05

## Task

Fix the modular Operator Fists path so upper-body idle renders with lower-body idle, enforce the modular contract where lower body resolves movement direction and upper body resolves action/aim direction, and verify whether modular Operator animations placed in the sprite ingest pipeline can reach the live game.

## Outcome

Fists idle prefers the modular lower/upper layer stack over the legacy authored body idle. Modular locomotion sync now takes separate lower/upper directions, allowing lower movement north while upper aim/action faces south. Modular Operator inbox PNGs route into `content/sprites/operator/new_operator/modular/`, rebuild stable runtime module sheets, and refresh the live modular `SpriteFrames` resources.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/03_architecture/SPRITE_PIPELINE_SYSTEM.md`
- Active runtime/docs files: `custodian/game/actors/operator/operator.gd`, `custodian/tools/pipelines/`, `custodian/content/sprites/operator/runtime/modules/new_operator/README.md`
- Historical reference only: legacy Python runtime

## Work Surface

- Files changed: Operator runtime animation precedence, modular runtime builder, inbox manifest generator, ingest runtime post-process, focused validation, sprite/module docs, AI context.
- Files read but not changed: Operator scene/resources, sprite pipeline README, current AI context/index.
- Out-of-scope areas: New production animation art and non-Operator sprite ingest domains.

## Constraints

- Determinism concerns: No simulation authority changed.
- Simulation/UI boundary concerns: Rendering-layer selection only; attack timing and hit windows remain on the existing legacy timing sprite.
- Asset requirements: No new production art created.
- Compatibility or migration concerns: Existing manually authored manifests still work; generated modular manifests now use the live modular source path.
- Clarifying questions or assumptions: User means the modular Operator idle/ingest path for Fists/unarmed locomotion.

## Implementation Plan

1. Reproduce the modular idle layer state with a focused headless smoke.
2. Move unarmed modular idle precedence ahead of authored melee stance fallback.
3. Route generated modular inbox manifests to live modular source folders and add a rebuild post-process.
4. Update docs and run focused validation.

## Acceptance

- Runtime behavior: Headless smoke proves lower and upper modular idle are visible/playing and legacy body is hidden.
- Documentation: Modular runtime README and AI context mention the ingest path.
- Path/reference validation: Manifest generation maps modular files to `operator/new_operator/modular/...`.
- Manual validation: Not performed in editor.
- Automated/headless validation: Godot script checks and focused smoke pass.

## Drift Review

- `custodian/docs/ai_context/CURRENT_STATE.md`: updated.
- `custodian/docs/ai_context/CONTEXT.md`: not needed.
- `custodian/docs/ai_context/FILE_INDEX.md`: updated.
- `custodian/AGENTS.md`: not needed.
- Design docs: not needed for this narrow runtime/pipeline fix.

## Completion Notes

- Implemented: Modular Fists idle precedence, decoupled lower movement direction from upper action/aim direction, modular ingest routing/post-process, upper idle source compatibility, focused smoke.
- Validated: Python compile, Godot script checks, modular layer smoke proving `lower=unarmed_walk_up` with `upper=unarmed_walk_down`, manifest route check.
- Deferred: Editor/playtest visual confirmation and production replacement art.

## Next Steps

- Next action: Drop modular Operator PNGs into `custodian/content/sprites/_pipeline/inbox/` and run the manifest generator/ingest command.
- Best starting files: `custodian/content/sprites/operator/runtime/modules/new_operator/README.md`, `custodian/tools/pipelines/generate_inbox_manifests.py`
- Required context: Use canonical modular names such as `operator__modular_upper_body__unarmed__idle_01__s__5f__96.png`.
- Validation to run: `godot --headless --path custodian --script res://tools/validation/operator_modular_layers_smoke.gd`
- Blockers or open questions: None.
