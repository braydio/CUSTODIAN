# Enemy Animation Stability And Pipeline

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-07
- Created: 2026-05-07
- Last updated: 2026-05-07

## Task

Review the current Shrumb and wolf enemy animation state, fix immediate animation-direction problems, and establish the next enemy animation input pipeline direction.

## Outcome

Shrumb flee movement no longer retargets every physics frame, wolf procedural variants use directional rows from the wolf sheets instead of forcing row 0, and the enemy animation pipeline direction is recorded for follow-up implementation.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/ENEMY_VARIANT_SYSTEM.md`
- Active runtime/docs files: `custodian/game/actors/enemies/enemy.gd`, `custodian/game/enemies/procgen/wolf_animation_library.gd`, `custodian/tools/pipelines/README.md`
- Historical reference only: legacy Python runtime docs

## Work Surface

- Files or folders expected to change: enemy movement/animation script, wolf animation library, pipeline docs/context
- Files or folders expected to be read but not changed: current wolf and Shrumb source sheets, generic sprite ingest pipeline
- Out-of-scope areas: full new enemy state machine, full Aseprite baker, new authored animation assets

## Constraints

- Determinism concerns: animation selection should follow movement state and avoid frame-to-frame retarget noise.
- Simulation/UI boundary concerns: animation fixes must not change damage, health, wave counts, or targeting rules.
- Asset requirements: no new art required for this slice.
- Compatibility or migration concerns: keep existing `idle_east`, `run_east`, `bite_east`, `death_east`, and `howl_east` names available as aliases.
- Clarifying questions or assumptions: wolf rows are interpreted as south, west, east, north based on visual inspection of the current 4-row sheets.

## Implementation Plan

1. Stop passive Shrumb flee mode from replacing its flee target every frame.
2. Build directional wolf clips from the current 4-row sheets and preserve old east clip aliases.
3. Route procedural wolf animation choice through dominant movement direction with horizontal flip for west.
4. Document the enemy pipeline gap and next slice.
5. Validate scripts and boot.

## Acceptance

- Runtime behavior: Shrumb flee animation does not thrash between directional clips every frame.
- Runtime behavior: wolf running/idle uses the movement-facing row rather than hardcoded row 0.
- Documentation: current state and task packet reflect animation state and pipeline status.
- Path/reference validation: current wolf sheet paths still resolve.
- Automated/headless validation: relevant script checks and headless game boot.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No unless new pipeline files are added.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes if a pipeline spec is added or changed.

## Completion Notes

- Implemented: added passive Shrumb flee retarget throttling, changed wolf SpriteFrames construction to build directional clips from the current 4-row sheets, routed procedural wolf animation by dominant movement direction, added `enemy_runtime_import` post-process support, added an example wolf manifest, and documented the enemy animation input pipeline.
- Validated: `enemy.gd`, `wolf_animation_library.gd`, `ingest_runtime.gd`, and `ui.gd` check-only; standalone Shrumb scene load; full game boot.
- Deferred: full enemy SpriteFrames resource rebuild equivalent to `operator_curated_resources`; visual QA may still need row-order tuning if the current wolf sheet differs from the inferred `south/west/east/north` row order.

## Next Steps

- Next action: patch immediate animation stability and wolf direction fixes.
- Best starting files: `enemy.gd`, `wolf_animation_library.gd`
- Required context: existing generic sprite ingest can output enemy strips, but enemy-specific SpriteFrames rebuild is not yet equivalent to operator post-process.
- Validation to run: parse checks, Shrumb scene load, full game boot.
- Blockers or open questions: full enemy animation pipeline needs a dedicated baker/rebuild slice.
