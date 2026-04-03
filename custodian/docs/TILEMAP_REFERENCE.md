# TILEMAP REFERENCE — dungeon_tileset.tres

**Source File:** `custodian/content/tiles/tilesets/dungeon_tileset.tres`
**Atlas:** `atlas_walls_low-16x16.png`
**Total Tiles:** 48 (12 rows × 4 columns)

---

## Legend

| Code | Meaning |
|------|---------|
| `P` | Playable ground |
| `W` | Wall |
| `H` | Hole |
| `C` | Connector |

---

## Bitmask Rules

| Direction | Bit |
|----------|-----|
| North | 1 |
| East | 2 |
| South | 4 |
| West | 8 |

**Mask calculation:** Sum of directions. E.g., N+S = 1+4 = 5, N+E+S+W = 15

---

## Tile Index Reference

### Row 0 — Vertical Walls

| Index | Name | Mask | Connects | Cells |
|-------|------|------|----------|-------|
| [0,0] | vertical_wall_slice | 5 | N, S | P W P / P W P / P W P |
| [0,1] | vertical_wall_slice_variant | 5 | N, S | P W P / P W P / P W P |
| [0,2] | vertical_wall_terminal_door_support | 5 | N, S | P W P / P W P / P C P |
| [0,3] | horizontal_wall_cap_top | 10 | E, W | C C C / W W W / W W W |

### Row 1 — Corners & T-Junctions

| Index | Name | Mask | Connects | Cells |
|-------|------|------|----------|-------|
| [1,0] | inner_corner_br_open_left | 7 | N, E, S | P C C / P W W / P W W |
| [1,1] | t_junction_right_open_left | 7 | N, E, S | P C C / P W W / P C W |
| [1,2] | inner_corner_tr_open_left | 7 | N, E, S | P C C / P W W / P C W |
| [1,3] | vertical_terminal_right_open_left | 7 | N, E, S | P C C / P W W / P W W |

### Row 2 — Crosses & Horizontals

| Index | Name | Mask | Connects | Cells |
|-------|------|------|----------|-------|
| [2,0] | t_top_cross_open_left | 15 | N, E, S, W | P C C / P W W / P W W |
| [2,1] | t_top_cross_open_left_variant | 15 | N, E, S, W | P C C / P W W / P W W |
| [2,2] | top_horizontal_connector_cap | 10 | E, W | C C C / W W W / P W P |
| [2,3] | horizontal_wall_cap_variant | 10 | E, W | C C C / W W W / W W W |

### Row 3 — Right-Side Corners

| Index | Name | Mask | Connects | Cells |
|-------|------|------|----------|-------|
| [3,0] | inner_corner_bl_open_right | 11 | N, W, S | C C P / W W P / W W P |
| [3,1] | t_junction_left_open_right | 13 | N, W, S | C C P / W W P / W C P |
| [3,2] | inner_corner_tl_open_right | 11 | N, W, S | C C P / W W P / W C P |
| [3,3] | horizontal_terminal_left_open_right | 8 | W | C W P / W W P / W W P |

### Row 4 — T-Junctions with Support

| Index | Name | Mask | Connects | Cells |
|-------|------|------|----------|-------|
| [4,0] | t_top_cross_center_supported | 15 | N, E, S, W | P C C / P C W / P W W |
| [4,1] | t_junction_right_hole_variant | 7 | N, E, S | P C C / P W W / P C H |
| [4,2] | vertical_hole_corridor_corner | 7 | N, E, S | P C C / P H W / P H W |
| [4,3] | vertical_hole_terminal_variant | 7 | N, E, S | P C C / P H W / P H W |

### Row 5 — Holes Top Row

| Index | Name | Mask | Connects | Cells |
|-------|------|------|----------|-------|
| [5,0] | t_top_cross_with_bottom_holes | 15 | N, E, S, W | P C C / P W W / H W H |
| [5,1] | inner_corner_tl_hole_field | 9 | N, W | C C H / W H H / W H H |
| [5,2] | inner_corner_bl_hole_right | 11 | N, W, S | C C H / W W H / W W H |
| [5,3] | top_horizontal_connector_cap_variant_2 | 10 | E, W | C C C / W W W / P W P |

### Row 6 — Holes Middle Row

| Index | Name | Mask | Connects | Cells |
|-------|------|------|----------|-------|
| [6,0] | t_top_cross_with_bottom_holes_flip | 15 | N, E, S, W | C C P / W W P / H W H |
| [6,1] | inner_corner_tr_hole_field | 3 | N, E | H C C / H H W / H H W |
| [6,2] | inner_corner_br_hole_left | 7 | N, E, S | H C C / H W W / H W W |
| [6,3] | top_horizontal_connector_cap_variant_3 | 10 | E, W | C C C / W W W / P W P |

### Row 7 — Holes & Junctions

| Index | Name | Mask | Connects | Cells |
|-------|------|------|----------|-------|
| [7,0] | t_top_cross_center_supported_variant | 15 | N, E, S, W | P C C / P C W / P W W |
| [7,1] | t_junction_left_hole_variant | 13 | N, W, S | C C P / W W P / H C P |
| [7,2] | vertical_hole_corridor_corner_flip | 11 | N, W, S | C C P / W H P / W H P |
| [7,3] | vertical_hole_terminal_variant_flip | 11 | N, W, S | C C P / W H P / W H P |

### Row 8 — Mixed Holes

| Index | Name | Mask | Connects | Cells |
|-------|------|------|----------|-------|
| [8,0] | inner_corner_br_hole_right_open_left | 7 | N, E, S | P C C / P W H / P W H |
| [8,1] | vertical_wall_slice_hole_right | 5 | N, S | P W H / P W H / P W H |
| [8,2] | vertical_hole_corridor_corner_flip_hole_right | 11 | N, W, S | C C H / W H H / W H H |
| [8,3] | vertical_terminal_right_open_left_variant | 7 | N, E, S | P C C / P W W / P W W |

### Row 9 — Bottom Holes

| Index | Name | Mask | Connects | Cells |
|-------|------|------|----------|-------|
| [9,0] | top_horizontal_connector_cap_hole_bottom | 10 | E, W | C C C / W W W / H W H |
| [9,1] | vertical_hole_terminal_variant_flip | 11 | N, W, S | C C P / W H P / W H P |
| [9,2] | all_holes | 0 | — | H H H / H H H / H H H |
| [9,3] | horizontal_wall_cap_full | 10 | E, W | C C C / W W W / W W W |

### Row 10 — Floor Variants

| Index | Name | Mask | Connects | Cells |
|-------|------|------|----------|-------|
| [10,0] | horizontal_wall_cap_hole_bottom | 10 | E, W | C C C / W W W / H H H |
| [10,1] | all_playable_floor | 0 | — | P P P / P P P / P P P |
| [10,2] | vertical_hole_terminal_variant_flip_duplicate | 11 | N, W, S | C C P / W H P / W H P |
| [10,3] | t_top_cross_center_supported_repeat | 15 | N, E, S, W | P C C / P C W / P W W |

### Row 11 — Edge Cases

| Index | Name | Mask | Connects | Cells |
|-------|------|------|----------|-------|
| [11,0] | inner_corner_bl_hole_left_open_right | 11 | N, W, S | C C P / H W P / H W P |
| [11,1] | vertical_hole_corridor_corner_flip | 7 | N, E, S | H C C / H H W / H H W |
| [11,2] | vertical_wall_slice_hole_left | 5 | N, S | H W P / H W P / H W P |
| [11,3] | vertical_terminal_left_open_right_variant | 11 | N, W, S | C C P / W W P / W W P |

---

## Tile Categories

| Category | Tiles | Description |
|----------|-------|-------------|
| **Vertical Walls** | [0,0]–[0,3], [1,3], [3,3], [8,3], [11,3] | Straight wall segments |
| **Inner Corners** | [1,0], [1,2], [3,0], [3,2], [5,1], [5,2], [6,1], [6,2], [8,0], [11,0] | 90° corners with floor inside |
| **T-Junctions** | [1,1], [4,0], [4,1], [5,0], [6,0], [7,0], [7,1], [10,3] | T-shaped connections |
| **Crosses** | [2,0], [2,1], [7,0] | 4-way intersections |
| **Horizontals** | [0,3], [2,2], [2,3], [3,3], [5,3], [6,3], [9,3], [10,0] | Horizontal wall caps |
| **Terminals** | [0,2], [1,3], [3,3], [4,3], [7,3], [8,3], [11,3] | Dead ends |
| **Hole Tiles** | [4,1]–[11,2] | Tiles with holes (H) |
| **All Holes** | [9,2] | Full hole tile |
| **All Floor** | [10,1] | Full playable floor |

---

## Tile Flags

| Flag | Used By | Description |
|------|---------|-------------|
| `supports_door_below` | [0,2] vertical_wall_terminal_door_support | Has connector below for door |

---

## Usage

Load via Godot tilemap:
```gdscript
var tileset = load("res://content/tiles/tilesets/dungeon_tileset.tres")
$TileMap.tileset = tileset
```

Autotile connection mapping based on bitmask rules. The `cells` field shows the 3×3 neighborhood pattern:
- `P` = Playable (floor)
- `W` = Wall
- `H` = Hole
- `C` = Connector (transition tile)
