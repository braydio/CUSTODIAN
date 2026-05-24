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
- `runtime/roads/` — generated road stamp PNGs and `road_piece_manifest.game32.json`.
- `runtime/paths/` — generated footpath/degraded-transition stamp PNGs and `path_piece_manifest.game32.json`.
- `legacy/` — previous generated/nested exports retained for reference only.

## Regeneration

Run from the repository root:

```bash
python custodian/content/tiles/roads_paths/tools/normalize_road_pieces_game32.py --manifest custodian/content/tiles/roads_paths/source/road_piece_exports/road_piece_manifest.json --pathways-json custodian/content/tiles/roads_paths/source/Pathways.json --output-root custodian/content/tiles/roads_paths/runtime/roads --surface roads
python custodian/content/tiles/roads_paths/tools/normalize_road_pieces_game32.py --manifest custodian/content/tiles/roads_paths/source/road_piece_exports/road_piece_manifest.json --pathways-json custodian/content/tiles/roads_paths/source/Pathways.json --output-root custodian/content/tiles/roads_paths/runtime/paths --surface paths
```

The procgen runtime reads the generated manifests under `runtime/roads/` and `runtime/paths/`.
