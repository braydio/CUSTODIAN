# PROCGEN GAMEPLAY FEEL INTENT ZONES

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-13
- Created: 2026-05-13
- Last updated: 2026-05-13

## Task

Review `custodian/game/world/procgen/CODEX_INSTRUCT.md` and `CODEX_IMPLEMENT.md`, apply the recommended procgen runtime changes, and create the new project-level `REQUIRED_ASSETS.md` tracker.

## Outcome

`ProcGenTilemap` now emits semantic gameplay-feel intent zones for spawn clearings, soft paths, portal plazas, compound approaches, cover anchors, room identities, foliage cover, and destroyed-wall debris. Streaming reveal uses those zones for priority, downstream systems can query `get_intensity_at_tile(tile)`, and required production assets are tracked in the new root `REQUIRED_ASSETS.md`.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Runtime instruction docs: `custodian/game/world/procgen/CODEX_INSTRUCT.md`, `custodian/game/world/procgen/CODEX_IMPLEMENT.md`
- Runtime files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/game/world/procgen/portal_teleporter.gd`
- Tracking/docs: `REQUIRED_ASSETS.md`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`

## Work Surface

- Runtime: procgen tilemap semantic generation, portal teleporter compatibility alias.
- Docs/tracking: required assets tracker, current state, file index, task packet index.
- Out of scope: authoring the missing production assets, full in-editor visual tuning, enemy/loot consumers for intensity.

## Constraints

- Determinism: all new zone placement uses existing deterministic tile hashes and generated tile state.
- Streaming: late portal plaza/path edits update `_generated_floor_cells` / `_generated_wall_cells` so reveal reloads stay aligned.
- Compatibility: `PortalTeleporter` keeps `ramp_side_block_height` as a legacy alias while procgen writes `ramp_side_block_extra_height`.

## Implementation Plan

1. Compare instruction docs against current `proc_gen_tilemap.gd`.
2. Add intent-zone exports and generation order hooks.
3. Implement spawn clearing, soft paths, compound ingress decoration, room zone tagging, portal plaza/path updates, destroyed wall terrain, foliage cover tags, streaming priority, and intensity API.
4. Apply portal commitment defaults and platform teleporter property mapping.
5. Create `REQUIRED_ASSETS.md` and update context docs.
6. Run targeted Godot script checks.

## Acceptance

- Runtime behavior: procgen emits region tags for authored-feeling traversal and landmark semantics.
- Runtime behavior: destroyed walls emit `destroyed_wall_floor` terrain updates.
- Runtime behavior: streaming reveal prioritizes high-interest terrain and keeps generated wall state stable.
- API: downstream systems can query `get_intensity_at_tile(tile)`.
- Tracking: missing procgen and cross-system assets are recorded in `REQUIRED_ASSETS.md`.
- Validation: targeted Godot checks pass for changed procgen scripts.

## Completion Notes

- Implemented: gameplay-feel exports, spawn clearing, soft paths, compound ingress tags, deterministic room zones, portal plazas, portal approach paths, portal commitment defaults, platform arrival offset, operator freeze during portal activation commitment, destroyed-wall debris tags, foliage cover tags, semantic streaming reveal priority, intensity API, level-data intent flag, required-assets tracker, and docs/index updates.
- Validated: `godot --headless --path custodian --check-only --script res://game/world/procgen/proc_gen_tilemap.gd`; `godot --headless --path custodian --check-only --script res://game/world/procgen/portal_teleporter.gd`; `godot --headless --path custodian --check-only --script res://game/actors/operator/operator.gd`; `git diff --check`.
- Deferred: in-editor visual review and asset production for debris floors, portal plaza dressing, compound cover, room-specific props, tactical foliage variants, and vehicle/combat art gaps.

## Next Steps

- Next action: run an in-editor procgen map smoke test to verify spawn clearing, portal plazas, soft paths, and streaming reveal feel.
- Best starting files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `REQUIRED_ASSETS.md`
- Required context: `custodian/game/world/procgen/CODEX_INSTRUCT.md`, `custodian/game/world/procgen/CODEX_IMPLEMENT.md`
- Validation to run: full Godot scene boot and visual traversal check.
- Blockers or open questions: production art/audio assets listed in `REQUIRED_ASSETS.md`.
