# MOB FOLIAGE OCCLUSION

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-08
- Created: 2026-05-08
- Last updated: 2026-05-08

## Task

Extend foliage transparency occlusion so nearby enemies, ambient Shrumbs, and other mob-like actors also reveal through tree/shrub canopies when they are close to the Custodian.

## Outcome

Foliage occlusion remains driven by the procgen foliage presentation layer, but it can feed multiple actor bubble centers into the shader each frame. Existing player occlusion behavior should remain intact.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/`
- Active runtime/docs files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/game/world/procgen/foliage_occlusion_bubble.gdshader`, `custodian/docs/ai_context/CURRENT_STATE.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/game/world/procgen/proc_gen_tilemap.gd`
  - `custodian/game/world/procgen/foliage_occlusion_bubble.gdshader`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - this packet
- Files or folders expected to be read but not changed:
  - `custodian/game/actors/enemies/enemy.gd`
  - `custodian/AGENTS.md`
- Out-of-scope areas:
  - enemy AI behavior
  - collision behavior
  - production art changes

## Constraints

- Determinism concerns: this is visual-only and must not affect fixed-step simulation state.
- Simulation/UI boundary concerns: procgen presentation gathers actor positions without writing gameplay state.
- Asset requirements: none.
- Compatibility or migration concerns: keep existing single-player foliage occlusion parameters working.
- Clarifying questions or assumptions: mobs are discovered through existing enemy/ambient groups and only considered within a configurable range of the player.

## Implementation Plan

1. Add multi-bubble support to the foliage occlusion shader.
2. Add procgen exports for mob occlusion range, groups, offsets, and maximum bubble count.
3. Collect nearby mob actors once per foliage update and apply per-sprite active bubble centers.
4. Update docs and run headless validation.

## Acceptance

- Runtime behavior: player foliage occlusion still works; enemies/Shrumbs near the player can also fade foliage when behind canopy.
- Documentation: current state and packet reflect the new behavior.
- Path/reference validation: touched paths remain under active `custodian/` runtime.
- Manual validation: not required for this code slice.
- Automated/headless validation: run Godot script parse and game scene boot checks where feasible.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No new design authority needed for this visual extension.

## Completion Notes

- Implemented: `ProcGenTilemap` now gathers the player plus nearby grouped mob actors and applies active foliage fade centers per sprite. The foliage shader now supports up to eight fixed fade bubbles while preserving the legacy single-bubble uniforms.
- Validated: `godot --headless --check-only --script res://game/world/procgen/proc_gen_tilemap.gd`; `godot --headless --quit --scene res://scenes/game.tscn`.
- Deferred: no manual viewport tuning was done; mob offset/range exports can be tuned in-scene after playtesting.

## Next Steps

- Next action: playtest actor readability around dense foliage and tune exported range/offsets if needed.
- Best starting files: `custodian/game/world/procgen/proc_gen_tilemap.gd`
- Required context: existing enemy group names in `custodian/game/actors/enemies/enemy.gd`
- Validation to run: Godot headless parse and scene boot.
- Blockers or open questions: none.
