# Roads And Paths Tile Assets

This folder separates road/path source art from runtime procgen stamp exports.

## Layout

- `source/` — preserved source sheets and raw metadata.
  - `Pathways.json` describes the intended modular road/path roles.
  - `unprocessed_street_tilesheet.png` is the source for the raw road-piece export manifest.
  - `ancient_ruined_roads_and_paths.png` is the source/reference sheet for road and footpath visuals.
  - `road_piece_exports/` contains the raw sliced stamp PNGs plus `road_piece_manifest.json`.
- `tools/` — local processing scripts.
  - `normalize_road_pieces_game32.py` pads raw stamps to 32px game-grid canvases and can emit either road or path runtime manifests.
- `runtime/roads/surface/` — active procgen road base-decal pack. Its
  32×32 manifest uses filled-surface roles: center, cardinal edges, exterior
  corners, and interior corners. Procgen classifies these from the complete
  `_main_road_tiles` mask, not distance from the road centerline.
- `runtime/roads/lane/` — retired lane-offset presentation pack, retained as
  source/reference material. It is not an active runtime manifest.
- `runtime/placeholders/roads/` — retired high-contrast road placeholders,
  retained as fallback/reference assets.
- `runtime/placeholders/paths/` — current active procgen footpath/degraded-transition decal pack. Files and manifest are intentionally named `PLACEHOLDER_*` while path art is reviewed.
- `runtime/roads/` — generated candidate road stamp PNGs and manifests retained for production replacement review.
- `runtime/paths/` — generated candidate footpath/degraded-transition stamp PNGs and manifests retained for production replacement review.
- `legacy/` — previous generated/nested exports retained for reference only.

## Regeneration

Run from the repository root:

```bash
python custodian/content/tiles/roads_paths/tools/normalize_road_pieces_game32.py --manifest custodian/content/tiles/roads_paths/source/road_piece_exports/road_piece_manifest.json --pathways-json custodian/content/tiles/roads_paths/source/Pathways.json --output-root custodian/content/tiles/roads_paths/runtime/roads --surface roads
python custodian/content/tiles/roads_paths/tools/normalize_road_pieces_game32.py --manifest custodian/content/tiles/roads_paths/source/road_piece_exports/road_piece_manifest.json --pathways-json custodian/content/tiles/roads_paths/source/Pathways.json --output-root custodian/content/tiles/roads_paths/runtime/paths --surface paths
```

The procgen runtime currently reads:

- `runtime/roads/surface/road_surface_piece_manifest.game32.json`
- `runtime/placeholders/paths/PLACEHOLDER_path_piece_manifest.game32.json`

Road generation, connectivity, parking, foliage exclusion, and movement
bonuses remain separate semantic authority. Every generated road-surface tile
receives exactly one topology-classified base decal. Narrow footpaths continue
to use their separate connection-bitmask manifest.

Focused validation:

```bash
cd custodian
godot --headless --script res://tools/validation/procgen_road_surface_roles_smoke.gd
```
