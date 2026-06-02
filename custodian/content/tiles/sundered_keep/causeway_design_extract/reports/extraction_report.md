# Sundered Keep Causeway Design Extract

- Source: `/home/braydenchaffee/Projects/CUSTODIAN/custodian/content/masters/sundered_keep/causeway_design_master.png`
- Asset count: 55
- Tile size: 32

## Domains

### edges

- `causeway_edge_w_01` — edge_w — 32x64 — layer `TerrainEdges` — collision `edge_blocker`
- `causeway_edge_e_01` — edge_e — 32x64 — layer `TerrainEdges` — collision `edge_blocker`
- `causeway_edge_w_broken_01` — edge_w_broken — 32x64 — layer `TerrainEdges` — collision `edge_blocker`
- `causeway_edge_e_broken_01` — edge_e_broken — 32x64 — layer `TerrainEdges` — collision `edge_blocker`
- `outer_landing_edge_n_01` — edge_n — 96x32 — layer `TerrainEdges` — collision `edge_blocker`
- `outer_landing_edge_w_01` — edge_w — 32x96 — layer `TerrainEdges` — collision `edge_blocker`
- `outer_landing_edge_e_01` — edge_e — 32x96 — layer `TerrainEdges` — collision `edge_blocker`
- `outer_landing_corner_nw_01` — corner_nw — 64x64 — layer `TerrainEdges` — collision `solid`
- `outer_landing_corner_ne_01` — corner_ne — 64x64 — layer `TerrainEdges` — collision `solid`
- `rampart_trim_underwall_01` — underwall_trim — 96x32 — layer `TerrainEdges` — collision `edge_blocker`

### floors

- `causeway_floor_center_01` — floor_center — 32x32 — layer `FloorDetail` — collision `none`
- `causeway_floor_center_worn_01` — floor_center — 32x32 — layer `FloorDetail` — collision `none`
- `causeway_floor_center_dark_01` — floor_center — 32x32 — layer `FloorDetail` — collision `none`
- `causeway_floor_cracked_01` — floor_center — 32x32 — layer `FloorDetail` — collision `none`
- `causeway_floor_threshold_01` — threshold_floor — 32x32 — layer `FloorDetail` — collision `none`
- `outer_landing_floor_center_01` — landing_floor — 32x32 — layer `FloorDetail` — collision `none`
- `outer_landing_floor_dark_01` — landing_floor_variant — 32x32 — layer `FloorDetail` — collision `none`
- `outer_landing_floor_trim_01` — landing_trim_floor — 32x32 — layer `FloorDetail` — collision `none`
- `gatehouse_entry_floor_01` — gatehouse_entry_floor — 32x32 — layer `FloorDetail` — collision `none`
- `gatehouse_threshold_floor_01` — gatehouse_threshold_floor — 32x32 — layer `FloorDetail` — collision `none`
- `forecourt_floor_center_01` — forecourt_floor — 32x32 — layer `FloorDetail` — collision `none`
- `forecourt_floor_variant_01` — forecourt_floor_variant — 32x32 — layer `FloorDetail` — collision `none`

### props

- `sundered_water_marker_post_01` — water_marker_post — 32x64 — layer `PropsStatic` — collision `none`
- `causeway_parapet_post_01` — post — 32x32 — layer `PropsBlocking` — collision `solid`
- `mooring_bollards_w_01` — bollards_w — 32x96 — layer `PropsStatic` — collision `partial`
- `mooring_bollards_e_01` — bollards_e — 32x96 — layer `PropsStatic` — collision `partial`
- `mooring_ring_w_01` — mooring_ring — 32x32 — layer `PropsStatic` — collision `none`
- `mooring_ring_e_01` — mooring_ring — 32x32 — layer `PropsStatic` — collision `none`
- `landing_grate_01` — grate — 64x64 — layer `PropsStatic` — collision `none`
- `landing_grate_alt_01` — grate — 64x64 — layer `PropsStatic` — collision `none`
- `gothic_torch_post_01` — torch_post — 32x64 — layer `PropsStatic` — collision `partial`
- `gothic_torch_post_alt_01` — torch_post — 32x64 — layer `PropsStatic` — collision `partial`
- `rubble_pile_01` — rubble — 64x64 — layer `PropsBlocking` — collision `solid`
- `rubble_pile_alt_01` — rubble — 64x64 — layer `PropsBlocking` — collision `solid`
- `metal_grate_floor_01` — metal_grate_floor — 96x96 — layer `PropsStatic` — collision `none`
- `small_square_stone_detail_01` — small_stone_detail — 32x32 — layer `PropsStatic` — collision `none`
- `small_square_stone_detail_02` — small_stone_detail — 32x32 — layer `PropsStatic` — collision `none`

### stairs

- `gatehouse_steps_n_01` — stairs_n — 96x32 — layer `Traversal` — collision `none`

### walls

- `causeway_buttress_w_01` — buttress_w — 64x96 — layer `WallsHigh` — collision `solid`
- `causeway_buttress_e_01` — buttress_e — 64x96 — layer `WallsHigh` — collision `solid`
- `causeway_buttress_w_low_01` — buttress_w_low — 64x64 — layer `WallsHigh` — collision `solid`
- `causeway_buttress_e_low_01` — buttress_e_low — 64x64 — layer `WallsHigh` — collision `solid`
- `outer_landing_side_tower_w_01` — side_tower_w — 64x96 — layer `WallsHigh` — collision `solid`
- `outer_landing_side_tower_e_01` — side_tower_e — 64x96 — layer `WallsHigh` — collision `solid`
- `gatehouse_side_pillar_w_01` — pillar_w — 96x96 — layer `WallsHigh` — collision `solid`
- `gatehouse_side_pillar_e_01` — pillar_e — 96x96 — layer `WallsHigh` — collision `solid`
- `gatehouse_wall_face_01` — wall_face — 96x64 — layer `WallsHigh` — collision `solid`
- `gatehouse_wall_face_alt_01` — wall_face_alt — 96x64 — layer `WallsHigh` — collision `solid`
- `gatehouse_wall_socket_01` — wall_socket — 32x64 — layer `WallsHigh` — collision `solid`
- `gatehouse_wall_socket_e_01` — wall_socket_e — 32x64 — layer `WallsHigh` — collision `solid`
- `rampart_corner_chunk_01` — rampart_corner — 96x96 — layer `WallsHigh` — collision `solid`
- `rampart_crenellation_s_01` — crenellation_s — 96x32 — layer `WallsHigh` — collision `solid`
- `rampart_wall_horizontal_01` — wall_horizontal — 96x64 — layer `WallsHigh` — collision `solid`

### water

- `sundered_water_dark_01` — water_base — 32x32 — layer `TerrainBase` — collision `water_blocker`
- `sundered_water_dark_ripple_01` — water_variant — 32x32 — layer `TerrainBase` — collision `water_blocker`

## Notes

- Crops are representative prototype slices from a composite mockup.
- The generated PNGs should be treated as runtime candidates, not final hand-authored source of truth.
- Use `_debug/crop_overlay.png` to tune source rects.
- Use `reports/extraction_contact_sheet.png` to quickly review outputs.
- Use `reports/causeway_reconstruct_plan.json` as a starter map-building recipe.
