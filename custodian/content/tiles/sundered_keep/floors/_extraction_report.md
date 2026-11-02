# Sundered Keep Floor Tile Extraction Report

- Generated: `2026-05-30T04:21:55+00:00`
- Source: `/home/braydenchaffee/Projects/CUSTODIAN/custodian/content/masters/sundered/sundered_floor_tiles.png`
- Output: `/home/braydenchaffee/Projects/CUSTODIAN/custodian/content/tiles/sundered_keep/floors`
- Extracted: `18` floor tiles
- Manifest: `/home/braydenchaffee/Projects/CUSTODIAN/custodian/content/metadata/game32/sundered_keep_floor_tiles.game32.json`

## Follow-up

- Verify the 32x32 outputs visually in Aseprite.
- In Godot import settings, disable filter/mipmaps for these PNGs.
- If the source sheet layout changes, rerun with `--overwrite`.
- If pale checker/white remains, rerun with lower `--bg-min`, e.g. `--bg-min 190 --bg-delta 70`.
