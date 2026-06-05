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
- `runtime/placeholders/roads/` — current active procgen road decal pack. Files and manifest are intentionally named `PLACEHOLDER_*` while road art is reviewed.
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

This is deliberate. The placeholder pack makes road/path placement obvious in-game while the art and layout are evaluated. The production road/path packs under `runtime/roads/` and `runtime/paths/` are candidates for a later replacement pass, not the active defaults.

Focused validation:

```bash
cd custodian
godot --headless --script res://tools/validation/procgen_placeholder_roads_smoke.gd
```
