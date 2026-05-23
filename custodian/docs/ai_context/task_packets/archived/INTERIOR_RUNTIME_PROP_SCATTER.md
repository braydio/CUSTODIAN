# Interior Runtime Prop Scatter

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-05
- Created: 2026-05-05
- Last updated: 2026-05-05

## Task

Scatter runtime interior prop sprites named `props_*.png` from `custodian/content/tiles/interiors/runtime/` into constructed procgen interiors.

## Outcome

Constructed interiors should visibly include deterministic decorative props without relying on the outdoor ruin prop system.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/procgen/INDOOR_OUTDOOR_PROCGEN_REGIONS.md`
- Active runtime files: `custodian/game/world/procgen/proc_gen_tilemap.gd`

## Work Surface

- Files expected to change: `custodian/game/world/procgen/proc_gen_tilemap.gd`, interior tile README, active docs/context.
- Out-of-scope areas: collision/loot interaction for props, prop-specific gameplay, outdoor ruin prop art tuning.

## Constraints

- Determinism concerns: prop picks, placement order, jitter, and transforms must derive from stable tile hashes.
- Rendering/UI boundary concerns: decorative Sprite2D nodes only; no simulation authority.
- Asset requirements: runtime props are PNGs prefixed `props_`.

## Implementation Plan

1. Load `props_*.png` textures from the interior runtime folder at startup.
2. Build candidate tiles from constructed interior floor metadata.
3. Scatter Sprite2D props under `PropLayer` with deterministic spacing and bottom-center anchoring.
4. Document that outdoor ruin props already exist but are excluded from indoor tiles.

## Acceptance

- Runtime behavior: constructed interiors place visible decorative props when matching textures exist.
- Documentation: naming convention and relation to ruin props are documented.
- Automated/headless validation: `cd custodian && godot --headless --quit`.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No, existing interior runtime entry covers the folder.
- Do any design docs need an update? Yes.

## Completion Notes

- Implemented: `ProcGenTilemap` loads `props_*.png` and `prop_*.png` runtime textures, scatters them as decorative bottom-centered `Sprite2D` nodes on deterministic interior floor candidates, and keeps them separate from outdoor ruin props.
- Validated: `godot --headless --quit`.
- Deferred: collision, interaction, loot hooks, and visual in-editor density tuning.
