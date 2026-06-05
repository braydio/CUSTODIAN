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
- `runtime/placeholders/roads/` — current active procgen road decal pack. The manifest now uses the road-lane contract `center`, `left_1`, `left_2`, `right_1`, and `right_2` so future 32x32 road artwork can be swapped in by lane offset from the generated centerline. Current lane-role entries intentionally alias existing high-contrast `PLACEHOLDER_roads_mask_*` PNGs until production lane art lands.
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

- `runtime/placeholders/roads/PLACEHOLDER_road_piece_manifest.game32.json`
- `runtime/placeholders/paths/PLACEHOLDER_path_piece_manifest.game32.json`

This is deliberate. The placeholder pack makes road/path placement obvious in-game while the art and layout are evaluated. Road decals are selected by signed perpendicular offset from the nearest road centerline: `center`, `left_1`, `left_2`, `right_1`, and `right_2`. Path decals still use connection bitmasks. The production road/path packs under `runtime/roads/` and `runtime/paths/` are candidates for a later replacement pass, not the active defaults.

Focused validation:

```bash
cd custodian
godot --headless --script res://tools/validation/procgen_placeholder_roads_smoke.gd
```
