# CONTENT DIRECTORY STABILIZATION

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-31
- Created: 2026-05-31
- Last updated: 2026-05-31

## Task

Stabilize `res://content/` organization so asset sources, runtime files, legacy copies, generated files, and quarantine/unregistered files have clear homes and repeatable audit coverage.

## Outcome

`custodian/content/` has a documented layout contract, duplicate handling rules, and a non-destructive audit command that reports unstable loose files and exact duplicate groups before any risky asset moves happen.

## Authority

- Root routing: `/home/braydenchaffee/Projects/CUSTODIAN/AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `custodian/docs/ASSET_LAYOUT_CONVENTION.md`
- Active runtime/docs files: `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`, `custodian/docs/ai_context/VALIDATION_RECIPES.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/content/README.md`
  - `custodian/content/levels/hub/Road_of_Witnesses_Tilemap.png`
  - `custodian/content/levels/hub/Road_of_Witnesses_Tilemap.png.import`
  - `custodian/content/props/gothic/vault_dressing/source/unregistered/*`
  - `custodian/content/sprites/enemies/enemy_scout/source/*`
  - `custodian/content/sprites/environment/props/terminal/source/*`
  - `custodian/content/sprites/operator/source/operator_reloadign.png`
  - `custodian/content/tiles/source/ashen_forum/*`
  - `custodian/content/tiles/source/compound_ashen/*`
  - `custodian/content/tiles/source/gothic_compound/*`
  - `custodian/content/tiles/source/ninth_ritualant/*`
  - `custodian/content/tiles/source/roads_paths/*`
  - `custodian/content/tiles/source/tiled_sessions/*`
  - `custodian/docs/ASSET_LAYOUT_CONVENTION.md`
  - `custodian/game/world/hub/road_of_witnesses_prototype.gd`
  - `custodian/scenes/hub_road_of_witnesses_prototype.tscn`
  - `custodian/tools/aseprite/slice_compound_gothic_sheet.lua`
  - `custodian/tools/validation/content_asset_audit.py`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
  - `custodian/docs/ai_context/task_packets/README.md`
- Files or folders expected to be read but not changed:
  - `custodian/content/**`
  - `custodian/game/**`
  - `custodian/scenes/**`
  - `design/**`
- Out-of-scope areas:
- Broad duplicate consolidation or runtime asset deletions.
  - Reimporting all Godot assets.
  - Rewriting active scene or runtime texture paths.

## Constraints

- Determinism concerns: no simulation behavior changes in this pass.
- Simulation/UI boundary concerns: none; content audit is offline and read-only.
- Asset requirements: do not invent or remove production art assets.
- Compatibility or migration concerns: `_pipeline/archive/`, source trees, generated `legacy/` folders, and compatibility copies can be exact duplicates by design and must not be deleted without a consumer-specific migration.
- Clarifying questions or assumptions: assume the safest first step is to document and audit before moving files because the content tree has active `.import` sidecars and pre-existing user edits.

## Cleanup Plan

1. Lock behavior with a read-only content/reference scan and add a repeatable content audit command.
2. Document canonical content domains and duplicate-handling policy.
3. Update AI context docs so future agents route content work through the new layout and audit.
4. Move only the verified Road of Witnesses loose-root map into a level-owned folder because both runtime references pointed at a missing content path.
5. Move remaining loose sprite/tile-domain source files into owner-specific `source/` folders, patching sidecars and tool references.
6. Move `content/unregistered/` vault art into the gothic vault dressing source quarantine so it is owned by the vault prop domain without becoming runtime authority.
7. Defer broad duplicate consolidation until each duplicate group has consumer-specific reference proof.

## Implementation Plan

1. Add `custodian/content/README.md` as the local layout map for root content domains.
2. Extend `custodian/docs/ASSET_LAYOUT_CONVENTION.md` with the content-domain contract and duplicate safety rules.
3. Add a stdlib-only audit script under `custodian/tools/validation/`.
4. Update AI context file index/current state and task packet index.
5. Move the Road of Witnesses prototype map from loose content root into `res://content/levels/hub/` and update references.
6. Move loose sprite/tile source files and vault quarantine files into owner-specific source folders.
7. Run Python compile, reference scan, audit validation, and Godot headless validation.

## Acceptance

- Runtime behavior: unchanged.
- Documentation: content layout and duplicate rules are documented in both local content docs and the global asset convention.
- Path/reference validation: audit reports loose root files, unregistered files, loose domain files, and exact duplicate groups.
- Manual validation: reference scan reviewed before moving anything.
- Automated/headless validation: `python3 -m py_compile custodian/tools/validation/content_asset_audit.py`; `python3 custodian/tools/validation/content_asset_audit.py --limit 20`.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No runtime behavior changed.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No runtime/design behavior changed.

## Completion Notes

- Implemented: Added `res://content/README.md`, expanded `docs/ASSET_LAYOUT_CONVENTION.md`, added `tools/validation/content_asset_audit.py`, moved the Road of Witnesses prototype map into `res://content/levels/hub/`, moved loose terminal/operator/enemy-scout/tiles source files into owner-specific `source/` folders, moved vault quarantine PNGs into `res://content/props/gothic/vault_dressing/source/unregistered/`, updated scene/script/import/tool references, and updated AI context indexes.
- Validated: `python3 -m py_compile custodian/tools/validation/content_asset_audit.py`; `python3 custodian/tools/validation/content_asset_audit.py --limit 8`; `python3 custodian/tools/validation/content_asset_audit.py --limit 0 | sed -n '1,18p'`; targeted stale-path `rg` scans; `godot --headless --path custodian --quit`.
- Deferred: Exact duplicate consolidation remains deferred to separate consumer-specific passes. Historical change-control bundles still mention old paths as archived evidence.

## Next Steps

- Next action: review duplicate groups flagged as `needs-review`, starting with operator runtime/curated/live_review repeats and compatibility portal/terminal copies.
- Best starting files: `custodian/tools/validation/content_asset_audit.py`, `custodian/content/sprites/operator/runtime/`, `custodian/content/sprites/operator/runtime/curated/`, `custodian/content/sprites/operator/runtime/live_review/`
- Required context: content hash duplicate findings, reference scan output, `ASSET_LAYOUT_CONVENTION.md`.
- Validation to run: content audit plus targeted reference scans before each duplicate group move.
- Blockers or open questions: duplicate consolidation needs runtime consumer proof because many exact duplicates are intentional archive/source/compatibility copies.
