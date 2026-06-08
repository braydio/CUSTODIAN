# Sundered Keep Cosmic Ocean Runtime Mapping

## Packet Status

- Status: in_progress
- Owner: agent
- Agent/session: codex-2026-06-07-sundered-keep-cosmic-ocean
- Created: 2026-06-07
- Last updated: 2026-06-07

## Task

Map the cosmic ocean game32 art pack into the live Sundered Keep ocean runtime so the keep uses the cosmic shoreline and void fill art in-game without changing the existing Sundered Keep asset ids or map logic.

## Outcome

- The live Sundered Keep ocean runtime resolves to cosmic ocean art.
- The existing `ocean_*` runtime ids still work for `sundered_keep_map.gd`.
- The missing east shoreline orientation is handled deterministically, not by ad hoc manual edits.
- Documentation explains the mapping and any remaining art constraints.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/world_expansion/THE_SUNDERED_KEEP_LEVEL_SET.md`
- Active runtime/docs files: `custodian/content/runtime/sundered_keep/`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/content/runtime/sundered_keep/terrain/ocean/`
  - `custodian/content/runtime/sundered_keep/sundered_keep_game32_assets.gd`
  - `custodian/content/runtime/sundered_keep/game32_manifest.json`
  - `custodian/content/runtime/sundered_keep/terrain/terrain_manifest.game32.json`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
  - `design/02_features/world_expansion/THE_SUNDERED_KEEP_LEVEL_SET.md`
  - optionally `custodian/tools/art/` if a deterministic remap helper is needed
- Files or folders expected to be read but not changed:
  - `custodian/content/tiles/terrain/cosmic_ocean/game32/`
  - `custodian/game/world/sundered_keep/sundered_keep_map.gd`
  - `custodian/tools/validation/sundered_keep_asset_smoke.gd`
- Out-of-scope areas:
  - Sundered Keep layout geometry
  - player combat / inventory changes
  - unrelated runtime asset packs

## Constraints

- Determinism concerns: the mapping must be reproducible and stable across reruns.
- Simulation/UI boundary concerns: this is a content/runtime asset remap, not simulation logic.
- Asset requirements: do not introduce new production asset ids unless absolutely necessary.
- Compatibility or migration concerns: keep the `ocean_*` ids and map calls unchanged.
- Clarifying questions or assumptions: assume the east-facing shoreline variant can be produced as a mirrored derivative of a west-facing cosmic shoreline asset if no native east source exists.

## Implementation Plan

1. Choose the smallest stable mapping from the cosmic ocean pack to the existing Sundered Keep ocean runtime ids.
2. Copy or generate the runtime PNGs and matching sidecars into `custodian/content/runtime/sundered_keep/terrain/ocean/`.
3. Update docs and validate the existing Sundered Keep runtime still resolves and loads the remapped art.

## Acceptance

- Runtime behavior: Sundered Keep ocean tiles show cosmic ocean art without changing existing runtime ids.
- Documentation: current state and file index note the mapping.
- Path/reference validation: all referenced runtime files exist and remain loadable.
- Manual validation: source-to-runtime mapping is clear from the copied assets and notes.
- Automated/headless validation: Sundered Keep asset smoke passes.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? yes
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? probably not
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? yes
- Does `custodian/AGENTS.md` need an update? no
- Do any design docs need an update? yes

## Completion Notes

- Implemented: pending
- Validated: pending
- Deferred: any new art beyond the current cosmic pack

## Next Steps

- Next action: patch the runtime ocean assets from the cosmic source pack
- Best starting files: `custodian/content/runtime/sundered_keep/terrain/ocean/`
- Required context: current runtime ocean asset ids and cosmic source variants
- Validation to run: Sundered Keep asset smoke plus a file existence check
- Blockers or open questions: none
