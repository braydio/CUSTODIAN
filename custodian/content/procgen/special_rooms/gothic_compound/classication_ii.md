local ASSET_CLASSES = {
-- Base terrain: no collision, TileMap ground layer
terrain_ash_base_dark_a = {
category = "terrain_base",
collision = false,
layer = "BaseGroundLayer",
tags = { "ash", "dark", "repeatable", "wasteland" }
},

terrain_ash_base_dark_b = {
category = "terrain_base",
collision = false,
layer = "BaseGroundLayer",
tags = { "ash", "pebbles", "repeatable", "wasteland" }
},

terrain_ash_roots_cracked_a = {
category = "terrain_base_variant",
collision = false,
layer = "BaseGroundLayer",
tags = { "ash", "roots", "cracked", "dead_growth" }
},

terrain_ash_roots_dense_b = {
category = "terrain_base_variant",
collision = false,
layer = "BaseGroundLayer",
tags = { "ash", "roots", "dense", "dead_growth" }
},

terrain_rocky_ash_base_a = {
category = "terrain_base_variant",
collision = false,
layer = "BaseGroundLayer",
tags = { "ash", "rocks", "rough_ground" }
},

terrain_cracked_rock_base_a = {
category = "terrain_base",
collision = false,
layer = "BaseGroundLayer",
tags = { "cracked_rock", "stone", "wasteland" }
},

terrain_cracked_rock_base_b = {
category = "terrain_base",
collision = false,
layer = "BaseGroundLayer",
tags = { "cracked_rock", "stone", "wasteland" }
},

terrain_rocky_dirt_scatter_a = {
category = "terrain_base_variant",
collision = false,
layer = "BaseGroundLayer",
tags = { "dirt", "rocks", "scatter" }
},

terrain_rocky_dirt_scatter_b = {
category = "terrain_base_variant",
collision = false,
layer = "BaseGroundLayer",
tags = { "dirt", "gravel", "scatter" }
},

terrain_rocky_dirt_scatter_c = {
category = "terrain_base_variant",
collision = false,
layer = "BaseGroundLayer",
tags = { "dirt", "large_stones", "scatter" }
},

terrain_rocky_dirt_scatter_d = {
category = "terrain_base_variant",
collision = false,
layer = "BaseGroundLayer",
tags = { "dirt", "rocks", "rough_ground" }
},

terrain_stone_cracked_base_a = {
category = "terrain_base",
collision = false,
layer = "BaseGroundLayer",
tags = { "stone", "cracked", "courtyard" }
},

terrain_stone_cracked_base_b = {
category = "terrain_base",
collision = false,
layer = "BaseGroundLayer",
tags = { "stone", "cracked", "courtyard" }
},

terrain_stone_cracked_base_c = {
category = "terrain_base",
collision = false,
layer = "BaseGroundLayer",
tags = { "stone", "broken", "courtyard" }
},

-- Roads: no collision, path/road layer
road_straight_ew_long = {
category = "road",
collision = false,
layer = "RoadPathLayer",
connectors = { "east", "west" },
tags = { "road", "straight", "horizontal", "service_path" }
},

road_straight_ns_a = {
category = "road",
collision = false,
layer = "RoadPathLayer",
connectors = { "north", "south" },
tags = { "road", "straight", "vertical" }
},

road_straight_ns_b = {
category = "road",
collision = false,
layer = "RoadPathLayer",
connectors = { "north", "south" },
tags = { "road", "straight", "vertical", "variant" }
},

road_end_s_rounded = {
category = "road_end",
collision = false,
layer = "RoadPathLayer",
connectors = { "north" },
tags = { "road", "dead_end", "rounded_cap" }
},

road_corner_or_end_sw = {
category = "road_corner",
collision = false,
layer = "RoadPathLayer",
connectors = { "north", "east" },
tags = { "road", "corner", "rounded" }
},

road_corner_or_end_se = {
category = "road_corner",
collision = false,
layer = "RoadPathLayer",
connectors = { "north", "west" },
tags = { "road", "corner", "rounded" }
},

road_straight_ns_cracked = {
category = "road",
collision = false,
layer = "RoadPathLayer",
connectors = { "north", "south" },
tags = { "road", "straight", "vertical", "cracked" }
},

road_t_junction_s_a = {
category = "road_junction",
collision = false,
layer = "RoadPathLayer",
connectors = { "north", "east", "west" },
tags = { "road", "t_junction" }
},

road_t_junction_s_b = {
category = "road_junction",
collision = false,
layer = "RoadPathLayer",
connectors = { "north", "east", "west" },
tags = { "road", "t_junction", "variant" }
},

road_t_junction_s_c = {
category = "road_junction",
collision = false,
layer = "RoadPathLayer",
connectors = { "north", "east", "west" },
tags = { "road", "t_junction", "variant" }
},

road_t_junction_s_d = {
category = "road_junction",
collision = false,
layer = "RoadPathLayer",
connectors = { "north", "east", "west" },
tags = { "road", "t_junction", "variant" }
},

road_corner_inner_ne = {
category = "road_corner",
collision = false,
layer = "RoadPathLayer",
connectors = { "south", "west" },
tags = { "road", "corner", "inner" }
},

road_corner_inner_nw = {
category = "road_corner",
collision = false,
layer = "RoadPathLayer",
connectors = { "south", "east" },
tags = { "road", "corner", "inner" }
},

road_t_junction_s_cracked = {
category = "road_junction",
collision = false,
layer = "RoadPathLayer",
connectors = { "north", "east", "west" },
tags = { "road", "t_junction", "cracked" }
},

road_cross_intersection = {
category = "road_junction",
collision = false,
layer = "RoadPathLayer",
connectors = { "north", "east", "south", "west" },
tags = { "road", "cross", "intersection" }
},

-- Broken stone / transitions: mostly decals or terrain overlays
terrain_stone_broken_patch_a = {
category = "terrain_overlay",
collision = false,
layer = "DecalLayer",
tags = { "stone", "broken", "rubble_edge" }
},

terrain_stone_broken_patch_b = {
category = "terrain_overlay",
collision = false,
layer = "DecalLayer",
tags = { "stone", "broken", "rubble_edge" }
},

terrain_stone_broken_patch_c = {
category = "terrain_overlay",
collision = false,
layer = "DecalLayer",
tags = { "stone", "broken", "rubble_edge" }
},

terrain_stone_to_rubble_edge_e = {
category = "terrain_transition",
collision = false,
layer = "DecalLayer",
connectors = { "west" },
tags = { "stone", "rubble_transition", "edge" }
},

terrain_stone_to_rubble_edge_w = {
category = "terrain_transition",
collision = false,
layer = "DecalLayer",
connectors = { "east" },
tags = { "stone", "rubble_transition", "edge" }
},

terrain_stone_rubble_cap_s = {
category = "terrain_transition",
collision = false,
layer = "DecalLayer",
connectors = { "north" },
tags = { "stone", "rubble_transition", "cap" }
},

-- Road-to-dirt transitions
road_straight_ns_dirt_edge_a = {
category = "road_transition",
collision = false,
layer = "RoadPathLayer",
connectors = { "north", "south" },
tags = { "road", "dirt_edge", "vertical" }
},

road_straight_ns_dirt_edge_b = {
category = "road_transition",
collision = false,
layer = "RoadPathLayer",
connectors = { "north", "south" },
tags = { "road", "dirt_edge", "vertical", "variant" }
},

road_curve_dirt_transition_sw_a = {
category = "road_transition",
collision = false,
layer = "RoadPathLayer",
connectors = { "north", "east" },
tags = { "road", "curve", "dirt_transition" }
},

road_curve_dirt_transition_sw_b = {
category = "road_transition",
collision = false,
layer = "RoadPathLayer",
connectors = { "north", "east" },
tags = { "road", "curve", "dirt_transition", "variant" }
},

road_curve_dirt_transition_ne_a = {
category = "road_transition",
collision = false,
layer = "RoadPathLayer",
connectors = { "south", "west" },
tags = { "road", "curve", "dirt_transition" }
},

road_curve_dirt_transition_ne_b = {
category = "road_transition",
collision = false,
layer = "RoadPathLayer",
connectors = { "south", "west" },
tags = { "road", "curve", "dirt_transition", "variant" }
},

road_curve_dirt_transition_ne_c = {
category = "road_transition",
collision = false,
layer = "RoadPathLayer",
connectors = { "south", "west" },
tags = { "road", "curve", "dirt_transition", "variant" }
},

-- Dirt/path variants
terrain_ash_roots_patch_a = {
category = "terrain_base_variant",
collision = false,
layer = "BaseGroundLayer",
tags = { "ash", "roots", "dead_growth" }
},

terrain_ash_roots_patch_b = {
category = "terrain_base_variant",
collision = false,
layer = "BaseGroundLayer",
tags = { "ash", "roots", "dead_growth" }
},

terrain_ash_roots_patch_c = {
category = "terrain_base_variant",
collision = false,
layer = "BaseGroundLayer",
tags = { "ash", "roots", "dead_growth" }
},

terrain_ash_sparse_pebble_patch = {
category = "terrain_base_variant",
collision = false,
layer = "BaseGroundLayer",
tags = { "ash", "pebbles", "sparse" }
},

path_worn_dirt_vertical_a = {
category = "path",
collision = false,
layer = "RoadPathLayer",
connectors = { "north", "south" },
tags = { "dirt_path", "worn", "vertical" }
},

path_worn_dirt_vertical_b = {
category = "path",
collision = false,
layer = "RoadPathLayer",
connectors = { "north", "south" },
tags = { "dirt_path", "worn", "vertical", "variant" }
},

path_worn_dirt_vertical_c = {
category = "path",
collision = false,
layer = "RoadPathLayer",
connectors = { "north", "south" },
tags = { "dirt_path", "worn", "vertical", "variant" }
},

-- Utility/decal assets
grate_square_metal = {
category = "utility_tile",
collision = false,
layer = "DecalLayer",
tags = { "grate", "metal", "industrial" }
},

grate_round_metal = {
category = "utility_tile",
collision = false,
layer = "DecalLayer",
tags = { "grate", "round", "drain", "industrial" }
},

floor_sigil_stone_square = {
category = "floor_decal",
collision = false,
layer = "DecalLayer",
tags = { "sigil", "ritual", "stone", "objective_floor" }
},

decal_light_pool_amber = {
category = "light_decal",
collision = false,
layer = "LightDecalLayer",
tags = { "light_pool", "amber", "atmosphere" }
},

decal_shadow_smoke_dark = {
category = "shadow_decal",
collision = false,
layer = "ShadowDecalLayer",
tags = { "shadow", "smoke", "atmosphere" }
},
}
