# Ash-Bell Forlorn-Ritualant Authority Reservation

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: codex-2026-06-12-authored-authority
- Created: 2026-06-12
- Last updated: 2026-06-12

## Task

Fix procgen authority clashes beneath authored/special-room scenes and wire the Ash-Bell dev spawner to reserve its canonical `35x27` room footprint before instantiation.

## Outcome

`ProcGenTilemap` exposes one reusable authored-footprint claim API that replaces procgen wall, collision, elevation, foliage, road-decal, and region authority with authored-scene floor authority; Ash-Bell uses it before becoming active.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/enemy_objective/FORLORN_RITUALANT_ENCOUNTER_DETAILED_SPEC.md`
- Active runtime/docs files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/game/world/events/ash_bell/ash_bell_dev_spawner.gd`
- Historical reference only: `custodian/docs/ai_context/task_packets/archived/ASH_BELL_FORLORN_RITUALANT.md`

## Work Surface

- Files or folders expected to change: procgen tilemap, Ash-Bell dev spawner, focused validation, AI context docs
- Files or folders expected to be read but not changed: Ash-Bell authored scene and special-room JSON
- Out-of-scope areas: changing authored Ash-Bell collision, generic special-room placement policy

## Constraints

- Determinism concerns: the claimed rectangle must derive only from explicit center, size, and margin inputs.
- Simulation/UI boundary concerns: procgen/elevation authority is cleared before authored-scene collision becomes active.
- Asset requirements: none.
- Compatibility or migration concerns: road wall clearing must retain road metadata while authored claims remove it.
- Clarifying questions or assumptions: the canonical room footprint is `35x27`.

## Implementation Plan

1. Add centralized authored-scene floor claim and authority report APIs to `ProcGenTilemap`.
2. Wire Ash-Bell dev placement to reserve authority before adding its scene.
3. Add focused smoke coverage and update current-state/index documentation.

## Acceptance

- Runtime behavior: claimed cells have floor visuals/metadata, no procgen wall/collision authority, walkable height-0 elevation, and authored region metadata.
- Documentation: current state, file index, and packet describe the live contract.
- Path/reference validation: indexed validation and runtime files exist.
- Manual validation: Ash-Bell room is enterable without invisible procgen blockers.
- Automated/headless validation: authored authority, roads, Ash-Bell, terrain, elevation, and full boot checks.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: Added `ProcGenTilemap.claim_procgen_floor_rect_for_authored_scene_world/tiles`, shared procgen wall-authority clearing, authored floor/elevation/region forcing, stale road-authority clearing, collision/overlay/shadow/navigation refresh, debug authority reporting, and Ash-Bell pre-instantiation reservation of its canonical `35x27` footprint.
- Validated: `procgen_authored_scene_authority_smoke.gd` passes against a real generated visible wall/runtime body; `procgen_placeholder_roads_smoke.gd` passes; `elevation_map_smoke.gd` passes; full headless boot passes and logs Ash-Bell placement followed by navigation rebuild; focused `git diff --check` passes.
- Deferred: Generic special-room insertion should call the new API. Existing `terrain_builder_smoke.gd` still reports its pre-existing missing TileSet source `32`. Existing `ash_bell_scene_smoke.gd` currently times out after calling the now-missing `ForlornRitualantSite.take_clapper()` method from unrelated current-worktree Ash-Bell changes.

## Next Steps

- Next action: use the reservation API from future generic special-room insertion.
- Best starting files: `custodian/game/world/procgen/proc_gen_tilemap.gd`
- Required context: this packet and the active Forlorn-Ritualant spec
- Validation to run: focused authored authority smoke and full boot
- Blockers or open questions: none
