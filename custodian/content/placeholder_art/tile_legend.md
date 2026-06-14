CUSTODIAN Placeholder Tile Atlases (32x32)
===========================================

Purpose:
- Uniform runtime-ready placeholder atlases for Codex and manual testing.
- Every tile includes a visible 'PH' watermark to clearly indicate placeholder status.

---

## Atlas 1: Walls, Floors, Stairs — `placeholder_walls_floors_stairs.png`

Files:
- `placeholder_walls_floors_stairs.png` : runtime atlas (128x96, 4x3 grid)
- `atlas_manifest.json` : atlas manifest

Tile list:
- [00] placeholder_wall_solid (WS) @ atlas (0, 0) - Full wall / solid blocker
- [01] placeholder_wall_end (WE) @ atlas (1, 0) - Wall end cap / terminal segment
- [02] placeholder_wall_vertical (WV) @ atlas (2, 0) - Vertical wall segment
- [03] placeholder_wall_corner (WC) @ atlas (3, 0) - Corner wall segment
- [04] placeholder_floor_walkable (FW) @ atlas (0, 1) - Walkable floor tile
- [05] placeholder_floor_edge (FE) @ atlas (1, 1) - Floor edge / transition tile
- [06] placeholder_void (VO) @ atlas (2, 1) - Void / impassable tile
- [07] placeholder_cliff_edge (CE) @ atlas (3, 1) - Cliff or drop edge tile
- [08] placeholder_stairs (ST) @ atlas (0, 2) - Stair / ascent tile
- [09] placeholder_doorway (DR) @ atlas (1, 2) - Doorway / opening tile
- [10] placeholder_obstacle (OB) @ atlas (2, 2) - Obstacle / pillar / cover
- [11] placeholder_prop_marker (PM) @ atlas (3, 2) - Generic prop marker tile

---

## Atlas 2: Events, Nodes, Portals — `placeholder_events_nodes_portals.png`

Files:
- `placeholder_events_nodes_portals.png` : runtime atlas (128x96, 4x3 grid)
- `extras_manifest.json` : atlas manifest

Tile list (elevation):
- [00] placeholder_elevation_ramp_up (ER) @ atlas (0, 0) - Elevation ramp up tile
- [01] placeholder_elevation_ramp_down (ED) @ atlas (1, 0) - Elevation ramp down tile
- [02] placeholder_elevation_platform (EP) @ atlas (2, 0) - Elevated platform tile
- [03] placeholder_elevation_void (EV) @ atlas (3, 0) - Elevation void / impassable blocker

Tile list (harvesting nodes):
- [04] placeholder_node_harvestable (NH) @ atlas (0, 1) - Harvestable resource node
- [05] placeholder_node_depleted (ND) @ atlas (1, 1) - Depleted resource node
- [06] placeholder_node_rare (NR) @ atlas (2, 1) - Rare / expedition resource node
- [07] placeholder_node_artifact (NA) @ atlas (3, 1) - Archive / artifact node

Tile list (portals):
- [08] placeholder_portal_ring (PR) @ atlas (0, 2) - Portal ring base tile
- [09] placeholder_portal_active (PA) @ atlas (1, 2) - Active portal tile
- [10] placeholder_portal_target (PT) @ atlas (2, 2) - Portal target / destination marker
- [11] placeholder_portal_pedestal (PP) @ atlas (3, 2) - Portal platform / pedestal tile
