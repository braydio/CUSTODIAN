# Terrain Gameplay Pack Direction Review

Generated: 2026-07-08

Purpose: lightweight semantic review queue for the Connector, Ascent, and Chasm+Bridge terrain gameplay packs before production placement. These tiles are ingested and registered as TileSet atlas sources, but their directional/corner semantics still need manual visual confirmation before TerrainBuilder or ProcGenTilemap place them broadly.

## Connector Corners

| Category | Tile ID | Preview filename | Review note |
|---|---|---|---|
| outer corner | `terrain_connector_outer_corner_ne_32` | `terrain_connector_outer_corner_ne_256.png` | Confirm NE convex/outer corner orientation. |
| outer corner | `terrain_connector_outer_corner_nw_32` | `terrain_connector_outer_corner_nw_256.png` | Confirm NW convex/outer corner orientation. |
| outer corner | `terrain_connector_outer_corner_se_32` | `terrain_connector_outer_corner_se_256.png` | Confirm SE convex/outer corner orientation. |
| outer corner | `terrain_connector_outer_corner_sw_32` | `terrain_connector_outer_corner_sw_256.png` | Confirm SW convex/outer corner orientation. |
| inner corner | `terrain_connector_inner_corner_ne_32` | `terrain_connector_inner_corner_ne_256.png` | Confirm NE concave/inner corner orientation. |
| inner corner | `terrain_connector_inner_corner_nw_32` | `terrain_connector_inner_corner_nw_256.png` | Confirm NW concave/inner corner orientation. |
| inner corner | `terrain_connector_inner_corner_se_32` | `terrain_connector_inner_corner_se_256.png` | Confirm SE concave/inner corner orientation. |
| inner corner | `terrain_connector_inner_corner_sw_32` | `terrain_connector_inner_corner_sw_256.png` | Confirm SW concave/inner corner orientation. |

Flag: manual review required for inner/outer naming before these are used for pre-terrain authority-repair connector visuals.

## Ascent Directions

| Category | Direction | Tile ID | Preview filename | Review note |
|---|---|---|---|---|
| wide ramp | north | `ramp_north_wide_32` | `ramp_north_wide_256.png` | Confirm travel/read direction. |
| wide ramp | south | `ramp_south_wide_32` | `ramp_south_wide_256.png` | Confirm travel/read direction. |
| wide ramp | east | `ramp_east_wide_32` | `ramp_east_wide_256.png` | Confirm travel/read direction. |
| wide ramp | west | `ramp_west_wide_32` | `ramp_west_wide_256.png` | Confirm travel/read direction. |
| broken ramp | north | `ramp_north_broken_32` | `ramp_north_broken_256.png` | Confirm travel/read direction and broken variant readability. |
| broken ramp | south | `ramp_south_broken_32` | `ramp_south_broken_256.png` | Confirm travel/read direction and broken variant readability. |
| broken ramp | east | `ramp_east_broken_32` | `ramp_east_broken_256.png` | Confirm travel/read direction and broken variant readability. |
| broken ramp | west | `ramp_west_broken_32` | `ramp_west_broken_256.png` | Confirm travel/read direction and broken variant readability. |
| stone stair | north | `stair_north_stone_32` | `stair_north_stone_256.png` | Confirm stair direction. |
| stone stair | south | `stair_south_stone_32` | `stair_south_stone_256.png` | Confirm stair direction. |
| stone stair | east | `stair_east_stone_32` | `stair_east_stone_256.png` | Confirm stair direction. |
| stone stair | west | `stair_west_stone_32` | `stair_west_stone_256.png` | Confirm stair direction. |
| metal stair | north | `stair_north_metal_32` | `stair_north_metal_256.png` | Confirm stair direction. |
| metal stair | south | `stair_south_metal_32` | `stair_south_metal_256.png` | Confirm stair direction. |
| metal stair | east | `stair_east_metal_32` | `stair_east_metal_256.png` | Confirm stair direction. |
| metal stair | west | `stair_west_metal_32` | `stair_west_metal_256.png` | Confirm stair direction. |

Flag: manual review required before replacing the existing stable TerrainBuilder ascent/elevation mapping.

## Chasm Edges And Corners

| Category | Direction | Tile ID | Preview filename | Review note |
|---|---|---|---|---|
| edge | north | `chasm_edge_n_32` | `chasm_edge_n_256.png` | Confirm ledge faces the expected side. |
| edge | south | `chasm_edge_s_32` | `chasm_edge_s_256.png` | Confirm ledge faces the expected side. |
| edge | east | `chasm_edge_e_32` | `chasm_edge_e_256.png` | Confirm ledge faces the expected side. |
| edge | west | `chasm_edge_w_32` | `chasm_edge_w_256.png` | Confirm ledge faces the expected side. |
| outer corner | NE | `chasm_outer_corner_ne_32` | `chasm_outer_corner_ne_256.png` | Confirm convex/outer corner orientation. |
| outer corner | NW | `chasm_outer_corner_nw_32` | `chasm_outer_corner_nw_256.png` | Confirm convex/outer corner orientation. |
| outer corner | SE | `chasm_outer_corner_se_32` | `chasm_outer_corner_se_256.png` | Confirm convex/outer corner orientation. |
| outer corner | SW | `chasm_outer_corner_sw_32` | `chasm_outer_corner_sw_256.png` | Confirm convex/outer corner orientation. |
| inner corner | NE | `chasm_inner_corner_ne_32` | `chasm_inner_corner_ne_256.png` | Confirm concave/inner corner orientation. |
| inner corner | NW | `chasm_inner_corner_nw_32` | `chasm_inner_corner_nw_256.png` | Confirm concave/inner corner orientation. |
| inner corner | SE | `chasm_inner_corner_se_32` | `chasm_inner_corner_se_256.png` | Confirm concave/inner corner orientation. |
| inner corner | SW | `chasm_inner_corner_sw_32` | `chasm_inner_corner_sw_256.png` | Confirm concave/inner corner orientation. |

Flag: manual review required before any live chasm placement; chasm tiles are non-walkable by symbolic resolution.

## Bridge Starts

| Category | Direction | Tile ID | Preview filename | Review note |
|---|---|---|---|---|
| stone bridge start | north | `bridge_stone_start_n_32` | `bridge_stone_start_n_256.png` | Confirm start direction and intended attachment side. |
| stone bridge start | south | `bridge_stone_start_s_32` | `bridge_stone_start_s_256.png` | Confirm start direction and intended attachment side. |
| stone bridge start | east | `bridge_stone_start_e_32` | `bridge_stone_start_e_256.png` | Confirm start direction and intended attachment side. |
| stone bridge start | west | `bridge_stone_start_w_32` | `bridge_stone_start_w_256.png` | Confirm start direction and intended attachment side. |

Flag: manual review required before bridges are used for deterministic component bridges or chasm crossings.

## Deferred Runtime Integration

- Connector visuals for `pre_terrain_required_connector` remain a future runtime integration pass.
- Bridge placement over deterministic component bridges/chasm gaps remains deferred.
- Ascent pack usage for logical elevation transitions remains deferred; current generation should keep using the stable existing TerrainBuilder mapping until the dedicated integration pass.
