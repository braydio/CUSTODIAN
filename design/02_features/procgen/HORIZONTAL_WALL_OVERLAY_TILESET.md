# Horizontal Wall Overlay Tileset

**Project:** CUSTODIAN  
**Status:** Complete  
**Updated:** 2026-04-08

## Goal

Add the new 4x3 ruined wall sheet to procgen so exposed horizontal wall runs can render with left cap, stretchable middle, and right cap visuals.

## Asset Contract

- Source sheet: `custodian/content/tiles/walls/marble_ruined_walls_3x4_96x96.png`
- Runtime atlas: `custodian/content/tiles/walls/runtime/marble_ruined_walls_runtime_3x4_96x96.png`
- Rows are style variants.
- Columns are:
  - column 0 = left cap
  - column 1 = continuous stretch section
  - column 2 = right cap
- Endcap source sheet: `custodian/content/tiles/walls/marble_ruined_walls_96x96_endcaps.png`
- Endcap runtime atlas: `custodian/content/tiles/walls/runtime/marble_ruined_walls_runtime_endcaps_7x1_96x96.png`

## Runtime Integration

- Procgen wall logic remains tile-based and collision-authoritative.
- A runtime overlay pass scans currently visible top-exposed wall runs.
- A companion pass can also skin left/right-exposed vertical runs by reusing the same wall sheet with rotated repeated segments.
- Collision can now expand upward and sideways on exposed rows/faces so the gameplay blocker matches the larger ruined wall mass more closely.
- Each run is rendered as:
  - left cap sprite at run start
  - repeated middle sprite segments across the interior
  - right cap sprite at run end
- Overlay rebuilds happen after full generation, streaming reveal changes, chunk unloads, and destructible wall breaches.
- Top-exposed wall collision is also extended upward to match the taller ruined wall presentation.
- Optional ruined endcaps now decorate the left and right terminals of exposed runs, including interior/corridor runs.
- Exposed vertical/corner-adjacent wall runs can now borrow the same ruined language so corridors do not collapse back to puny one-tile silhouettes.
- A toggleable runtime collision debug overlay can render the generated blocker footprints for tuning overblocking.
- The base tilemap wall visuals can be hidden for inspection so only the ruined overlay treatment and collision debug remain visible.
- Test mode can also restrict collision generation to only tiles that currently use the ruined overlay treatment, preventing hidden legacy wall collision from confusing inspection.
- Endcaps overlap the run by roughly 25% horizontally and can jitter upward slightly for broken silhouette variation.

## Non-Goals

- Replacing per-tile wall collision with sprite collision
- Changing procgen layout rules
- Replacing vertical wall-side visuals with this sheet
