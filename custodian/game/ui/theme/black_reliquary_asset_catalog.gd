class_name BlackReliquaryAssetCatalog
extends RefCounted

const ROOT := "res://content/ui/black_reliquary"

const PANEL_DARK_GOLD := ROOT + "/panels/ui_panel_9slice_dark_gold.png"
const PANEL_DEEP := ROOT + "/panels/ui_panel_9slice_deep.png"

const ICON_GATE_LOCKED := ROOT + "/icons/icon_gate_locked.png"
const ICON_GATE_OPEN := ROOT + "/icons/icon_gate_open.png"
const ICON_STAIRS_UP := ROOT + "/icons/icon_stairs_up.png"
const ICON_STAIRS_DOWN := ROOT + "/icons/icon_stairs_down.png"
const ICON_RETURN_MOORING := ROOT + "/icons/icon_return_mooring.png"
const ICON_KEY_ITEM := ROOT + "/icons/icon_key_item.png"
const ICON_CHOKE_POINT := ROOT + "/icons/icon_choke_point.png"
const ICON_HAZARD := ROOT + "/icons/icon_hazard.png"
const ICON_OBJECTIVE := ROOT + "/icons/icon_objective.png"
const COMPASS_ROSE_SMALL := ROOT + "/icons/compass_rose_small.png"

const MARKER_PLAYER := ROOT + "/markers/minimap_marker_player.png"
const MARKER_GATE_LOCKED := ROOT + "/markers/minimap_marker_gate_locked.png"
const MARKER_RETURN_MOORING := ROOT + "/markers/minimap_marker_return_mooring.png"
const MARKER_OBJECTIVE := ROOT + "/markers/minimap_marker_objective.png"
const MARKER_STAIR_UP := ROOT + "/markers/minimap_marker_stair_up.png"
const MARKER_STAIR_DOWN := ROOT + "/markers/minimap_marker_stair_down.png"

const MINIMAP_FILL_DARK := ROOT + "/minimap/minimap_fill_dark.png"
const MINIMAP_TITLE_PLAQUE := ROOT + "/minimap/minimap_title_plaque.png"
const MINIMAP_FRAME_EDGE_TOP := ROOT + "/minimap/minimap_frame_edge_top.png"
const MINIMAP_FRAME_EDGE_BOTTOM := ROOT + "/minimap/minimap_frame_edge_bottom.png"
const MINIMAP_FRAME_EDGE_LEFT := ROOT + "/minimap/minimap_frame_edge_left.png"
const MINIMAP_FRAME_EDGE_RIGHT := ROOT + "/minimap/minimap_frame_edge_right.png"
const MINIMAP_FRAME_CORNER_TL := ROOT + "/minimap/minimap_frame_corner_tl.png"
const MINIMAP_FRAME_CORNER_TR := ROOT + "/minimap/minimap_frame_corner_tr.png"
const MINIMAP_FRAME_CORNER_BL := ROOT + "/minimap/minimap_frame_corner_bl.png"
const MINIMAP_FRAME_CORNER_BR := ROOT + "/minimap/minimap_frame_corner_br.png"

const PROMPT_ROOT_A := ROOT + "/prompts"
const PROMPT_ROOT_B := ROOT + "/prompt"
const PROMPT_HEADER_A := PROMPT_ROOT_A + "/plaque_header_small.png"
const PROMPT_HEADER_B := PROMPT_ROOT_B + "/plaque_header_small.png"
const PROMPT_BODY_A := PROMPT_ROOT_A + "/plaque_body_small.png"
const PROMPT_BODY_B := PROMPT_ROOT_B + "/plaque_body_small.png"
const PROMPT_KEY_BADGE_A := PROMPT_ROOT_A + "/input_key_badge.png"
const PROMPT_KEY_BADGE_B := PROMPT_ROOT_B + "/input_key_badge.png"
const PROMPT_LOCK_BADGE_A := PROMPT_ROOT_A + "/lock_badge_small.png"
const PROMPT_LOCK_BADGE_B := PROMPT_ROOT_B + "/lock_badge_small.png"


static func first_existing(paths: Array[String]) -> String:
	for path in paths:
		if ResourceLoader.exists(path):
			return path
	return ""


static func prompt_header() -> String:
	return first_existing([PROMPT_HEADER_A, PROMPT_HEADER_B])


static func prompt_body() -> String:
	return first_existing([PROMPT_BODY_A, PROMPT_BODY_B])


static func prompt_key_badge() -> String:
	return first_existing([PROMPT_KEY_BADGE_A, PROMPT_KEY_BADGE_B])


static func prompt_lock_badge() -> String:
	return first_existing([PROMPT_LOCK_BADGE_A, PROMPT_LOCK_BADGE_B])
