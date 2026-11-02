# Procgen Wall Passage Visibility

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-04
- Created: 2026-05-04
- Last updated: 2026-05-04

## Task

Make generated wall passage tiles visible in live procgen maps after the fixed-grid wall atlas bridge added passage
art only to rare hole/void-adjacent buckets.

## Outcome

`ProcGenTilemap` exposes a dedicated passage wall coordinate bucket and can select passage-looking cells on ordinary
horizontal wall runs without changing wall placement, wall collision, or destructible wall behavior.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/features/implementation/PROCGEN_WALL_TILE_BRIDGE.md`
- Active runtime/docs files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/game/world/procgen/proc_gen_map.tscn`, `custodian/docs/ai_context/CURRENT_STATE.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files changed: `proc_gen_tilemap.gd`, `proc_gen_map.tscn`, wall bridge design doc, AI context docs, this packet.
- Files read but not changed: generated mapping JSON and wall bridge builder script.
- Out-of-scope areas: collision carving, destructible wall logic, actual traversable doorway generation, gameplay map topology.

## Constraints

- Determinism concerns: passage choice must derive from `_tile_noise_hash` and procgen seed.
- Simulation/UI boundary concerns: art selection only; no floor/wall simulation authority changes.
- Asset requirements: use existing `reference_passage_wall_coords` from generated mapping JSON.
- Compatibility or migration concerns: keep existing hole-adjacent buckets intact.
- Clarifying questions or assumptions: passage art is currently visual-only; true walkable openings should be a separate map-topology feature.

## Implementation Plan

1. Add exported passage controls and `reference_passage_wall_coords` to `ProcGenTilemap`.
2. Populate scene arrays from `procgen_wall_tiles_32.mapping.json`.
3. Select at most one passage-looking cell per eligible horizontal wall run with deterministic chance.
4. Update docs and validate headless boot.

## Acceptance

- Runtime behavior: normal horizontal wall runs can display passage art.
- Documentation: wall bridge design doc and AI context mention the visibility bridge.
- Path/reference validation: scene contains the generated passage coordinate bucket.
- Manual validation: inspect scene/script wiring with `rg`.
- Automated/headless validation: Godot headless boot exits `0`.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No path ownership change.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, `PROCGEN_WALL_TILE_BRIDGE.md`.

## Completion Notes

- Implemented: explicit passage bucket and deterministic visual passage selection on horizontal runs.
- Validated: `python3 tools/tiles/build_procgen_wall_atlas.py --help`; `godot --headless --path custodian --quit`.
- Deferred: actual traversable passage/door carving and collision changes.

## Next Steps

- Next action: playtest a generated map and tune `wall_passage_spawn_chance` if too sparse or too frequent.
- Best starting files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/game/world/procgen/proc_gen_map.tscn`.
- Required context: generated atlas/mapping under `custodian/content/tiles/walls/generated/`.
- Validation to run: `godot --headless --path custodian --quit`, then an interactive playtest.
- Blockers or open questions: whether passage art should become actual walkable openings later.
