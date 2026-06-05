# Sundered Keep Gameplay Elevation Occlusion

## Packet Status

- Status: complete
- Owner: Codex
- Agent/session: Codex 2026-06-05
- Created: 2026-06-05
- Last updated: 2026-06-05

## Task

Implement `design/GAMEPLAY.md` for the current Sundered Keep slice: improve the authored bridge/lower-shore approach readability, preserve metadata-first elevation, add explicit underpass/shore metadata, and add a data-driven keep roof/ceiling cutaway for indoor readability.

## Outcome

The Sundered Keep front-gate JSON now declares lower-shore, underpass, and interior occlusion regions. `sundered_keep_map.gd` consumes those regions, renders shadowed underpass overlays and support/cliff dressing, keeps height/traversal truth in `ElevationMap`, and fades authored roof occluders when the Operator enters Great Hall interior regions.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/GAMEPLAY.md`, `design/ELEVATION.md`
- Active runtime/docs files: `custodian/game/world/sundered_keep/`, `custodian/content/levels/sundered_keep/`, `custodian/docs/ai_context/`
- Historical reference only: `python-sim/`

## Work Surface

- Files changed: Sundered Keep map runtime, Sundered Keep large front-gate JSON, Sundered Keep large-layout smoke, active AI context docs.
- Files read: elevation design, current state, file index, validation recipes, Sundered Keep task packets.
- Out-of-scope areas: new production art, true same-coordinate stacked elevation, TileSet/TileMapLayer conversion, save/load persistence.

## Constraints

- Determinism concerns: all new regions are authored JSON data; overlays are deterministic from region rectangles.
- Simulation/UI boundary concerns: `ElevationMap` remains the height/traversal authority; roof occluders and shadows are visual-only readers.
- Asset requirements: no new production art was created; current cliff/support/debris dressing uses existing Sundered Keep runtime assets.
- Compatibility or migration concerns: the current `ElevationMap` supports one height per tile, so true same-tile bridge-over-underpass traversal remains deferred.
- Clarifying questions or assumptions: implemented the underpass as connected lower height-0 shore lanes with explicit shadow/support treatment rather than a new stacked traversal model.

## Implementation Plan

1. Add authored `underpass_regions`, `shore_walk_regions`, and `interior_occlusion_regions` to the Sundered Keep front-gate JSON.
2. Extend `sundered_keep_map.gd` to parse those regions, render underpass shadow overlays, create roof occluders, and update roof opacity from the Operator's current authored interior region.
3. Strengthen the large-layout smoke to validate region metadata, height bands, underpass traversal, shadow/support placement, and roof cutaway/restoration.
4. Update active AI context references.

## Acceptance

- Runtime behavior: lower shore/underpass regions remain height 0, bridge deck remains height 1, ramp/stair transitions still control height changes, and Great Hall roof occluders cut away when the Operator enters interior regions.
- Documentation: current state, file index, and task packet index mention the implemented behavior.
- Path/reference validation: Sundered Keep JSON parses; changed GDScript files parse.
- Manual validation: not run in editor during this pass.
- Automated/headless validation: `sundered_keep_large_layout_smoke.gd` passes with new regression checks.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes, updated.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No workflow change.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes, updated.
- Does `custodian/AGENTS.md` need an update? No routing change.
- Do any design docs need an update? `design/GAMEPLAY.md` remains the implemented task authority.

## Completion Notes

- Implemented: authored underpass/shore/interior metadata, underpass shadow overlays, support/cliff dressing, data-driven roof occlusion, validation helpers, smoke coverage.
- Validated: JSON parse, Godot check-only for Sundered Keep map and smoke, targeted Sundered Keep large-layout smoke.
- Deferred: true same-tile stacked bridge traversal and final production roof/bridge art.

## Next Steps

- Next action: visually inspect the rendered/exported map and tune roof/shadow alpha values if needed.
- Best starting files: `custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json`, `custodian/game/world/sundered_keep/sundered_keep_map.gd`.
- Required context: `design/GAMEPLAY.md`, `design/ELEVATION.md`, this packet.
- Validation to run: `cd custodian && godot --headless --script res://tools/validation/sundered_keep_large_layout_smoke.gd`.
- Blockers or open questions: true stacked over/under traversal needs an `ElevationMap` model change before same-coordinate bridge and underpass can both be traversable.
