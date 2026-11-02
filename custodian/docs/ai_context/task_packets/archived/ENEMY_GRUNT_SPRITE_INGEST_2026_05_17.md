# Enemy Grunt Sprite Ingest 2026-05-17

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-17
- Created: 2026-05-17
- Last updated: 2026-05-17

## Task

Run the sprite ingest pipeline for pending `enemy_grunt` animation sheets, then wire the newly ingested runtime sheets into the active grunt animation loader.

## Outcome

Pending valid grunt inbox sheets are archived through the pipeline, runtime outputs exist under `res://content/sprites/enemies/enemy_grunt/`, Godot imports them, and `GruntAnimationLibrary` / `Enemy` can play the newly available directional run, melee, and melee-FX strips.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `custodian/content/sprites/_pipeline/README.md`, `custodian/tools/pipelines/README.md`, `design/02_features/animation/ENEMY_GRUNT_RUNTIME_WIRING.md`
- Active runtime/docs files: `custodian/game/enemies/procgen/grunt_animation_library.gd`, `custodian/game/actors/enemies/enemy.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: none

## Work Surface

- Files or folders expected to change: sprite pipeline inbox/archive/log/normalized/runtime outputs, grunt animation scripts, AI context docs.
- Files or folders expected to be read but not changed: existing enemy factory/wave wiring.
- Out-of-scope areas: enemy balance, final full directional art coverage, non-grunt animation systems.

## Constraints

- Determinism concerns: animation playback/wiring only; no simulation randomness changes.
- Simulation/UI boundary concerns: none.
- Asset requirements: only ingest currently available inbox sheets.
- Compatibility or migration concerns: preserve current live `grunt` enemy scene and spawn paths.
- Clarifying questions or assumptions: Treat the pending `enemy_grunt` inbox sheets as intended runtime art; skip stray invalid inbox debris such as hidden `.png`.

## Implementation Plan

1. Inspect pending inbox sheets and correct any clear frame-count filename mismatch.
2. Generate missing manifests and run targeted ingest for valid grunt sheets.
3. Update grunt animation runtime wiring to use newly saved sheets.
4. Run Godot import/headless validation and a targeted grunt animation smoke check.

## Acceptance

- Runtime behavior: `enemy_grunt` has runtime body/FX `SpriteFrames` for newly ingested sheets.
- Documentation: current state and file index reflect expanded grunt art coverage.
- Path/reference validation: runtime paths referenced by scripts exist after ingest.
- Manual validation: not required for this pipeline pass.
- Automated/headless validation: Godot checks and targeted smoke validation pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes, packet index.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Probably not unless runtime coverage changes materially.

## Completion Notes

- Implemented: Ingested the pending valid `enemy_grunt` inbox sheets into canonical runtime and compatibility paths; corrected the west melee body filename from `10f` to `11f` to match the actual source width; fixed `generate_inbox_manifests.py` so enemy/drone compatibility outputs preserve multi-frame strips instead of using invalid `copy` layout; expanded `GruntAnimationLibrary` to load `run_e`, `run_w`, `melee_e`, `melee_se`, `melee_w`, `melee_fx_e`, and `melee_fx_w`; updated `Enemy` to select covered grunt move/attack/FX directions without mirroring; added `grunt_animation_smoke.gd`.
- Validated: targeted manifest dry-run succeeded; direct Godot ingest processed all eight selected grunt manifests; runtime files and `.import` files exist under `content/sprites/enemies/enemy_grunt/`; `godot --headless --path custodian --check-only --script` passed for `grunt_animation_library.gd`, `enemy.gd`, and `grunt_animation_smoke.gd`; `python -m py_compile custodian/tools/pipelines/generate_inbox_manifests.py` passed; `godot --headless --path custodian --script res://tools/validation/grunt_animation_smoke.gd` passed; `godot --headless --path custodian --import --quit` exited 0; `godot --headless --path custodian --quit` exited 0.
- Deferred: The inbox still contains a stray hidden `.png`, a duplicate west-run `-sheet` PNG, and leftover inbox `.png.import` sidecars; they were not valid canonical manifest inputs for this pass. North-facing grunt art, full idle direction coverage, and west melee windup timing visual review remain future work.

## Next Steps

- Next action: Manually inspect grunt movement/attack readability in-game, especially west melee timing.
- Best starting files: `custodian/content/sprites/_pipeline/inbox/`, `custodian/game/enemies/procgen/grunt_animation_library.gd`
- Required context: sprite pipeline README and existing `ENEMY_GRUNT_RUNTIME_WIRING.md` packet.
- Validation to run: `godot --headless --path custodian --script res://tools/validation/grunt_animation_smoke.gd`, then `godot --headless --path custodian --quit`.
- Blockers or open questions: none.
