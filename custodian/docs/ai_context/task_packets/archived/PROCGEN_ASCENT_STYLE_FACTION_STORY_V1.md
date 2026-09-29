# Procgen Ascent Style Faction Story V1

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: codex-2026-06-12
- Created: 2026-06-12
- Last updated: 2026-06-12

## Task

Implement the metadata-first distance progression, uphill ascent route, faction ambient activity, and environmental story-room V1 described in `pre-design/WORLDGEN_EXTENDING.md`.

## Outcome

Procgen deterministically exports gradual world-style progression, a connectivity-safe ascent route, faction activity anchors, and story-room candidates; behavior-driven enemies can use ambient anchors.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/procgen/WORLD_ASCENT_STYLE_TRANSITION.md`
- Active runtime/docs files: procgen terrain/elevation, enemy behavior, AI context pack
- Historical reference only: legacy Python runtime/docs

## Work Surface

- Files or folders expected to change: procgen progression/faction/story modules, terrain builder, procgen tilemap, enemy behavior, validation, AI context docs
- Files or folders expected to be read but not changed: placeholder art manifest, existing terrain/elevation validation
- Out-of-scope areas: full story-room geometry, pathfinding elevation costs, production art

## Constraints

- Determinism concerns: all selection and placement must derive from stable seed/cell/profile inputs.
- Simulation/UI boundary concerns: progression and activity sites are metadata; placeholder markers are presentation only.
- Asset requirements: use `custodian/content/placeholder_art/placeholder_walls_floors_stairs.png` for debug markers.
- Compatibility or migration concerns: preserve existing procgen and enemy behavior defaults.
- Clarifying questions or assumptions: `pre-design/WORLDGEN_EXTENDING.md` is the intended requested file.

## Implementation Plan

1. Add profile, ascent, faction, story, and ambient-anchor modules.
2. Integrate modules into terrain/procgen/enemy behavior.
3. Add focused smoke validation and update active docs.

## Acceptance

- Runtime behavior: profile loads; ascent, sites, anchors, and story markers generate.
- Documentation: design spec and AI context reflect the live V1.
- Path/reference validation: all indexed paths exist.
- Manual validation: deferred unless headless validation exposes visual/runtime issues.
- Automated/headless validation: focused new smokes, terrain/elevation smokes, headless boot.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? Yes.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, new active spec.

## Completion Notes

- Implemented: distance profile, gradual ascent field/route, faction sites, runtime ambient anchors, story-room candidates/markers, enemy ambient state, and level-data export.
- Validated: new focused smokes pass; elevation and enemy-behavior smokes pass; full headless boot passes with ascent active and connectivity intact.
- Deferred: full story-room geometry, production marker art, and actor elevation path costs. The previously noted `terrain_builder_smoke.gd` TileSet source-id 32 assertion was resolved by restoring the terrain TileSet source registrations.

## Next Steps

- Next action: convert metadata-only story rooms into reserved authored geometry.
- Best starting files: `game/world/procgen/story/`, `game/world/procgen/proc_gen_tilemap.gd`
- Required context: this packet and active design spec
- Validation to run: focused procgen smokes and headless boot
- Blockers or open questions: none
