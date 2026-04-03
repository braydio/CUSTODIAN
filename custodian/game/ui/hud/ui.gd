extends CanvasLayer

const DEFAULT_TERMINAL_SERVICE_URL := "http://127.0.0.1:7331"
const TERMINAL_LOCAL_LINK := "LOCAL://GAME_STATE"
const TERMINAL_BOOT_LINES := [
	"[ SYSTEM POWER: UNSTABLE ]",
	"[ AUXILIARY POWER ROUTED ]",
	"",
	"CUSTODIAN NODE - ONLINE",
	"STATUS: DEGRADED",
	"",
	"> Running integrity check...",
	"> Memory blocks: 12% intact",
	"> Long-range comms: OFFLINE",
	"> Archive uplink: INACCESSIBLE",
	"> Automated defense grid: PARTIAL",
	"",
	"DIRECTIVE FOUND",
	"RETENTION MANDATE - ACTIVE",
	"",
	"WARNING:",
	"Issuing authority presumed defunct.",
	"",
	"Residual Authority accepted.",
	"",
	"Initializing Custodian Interface...",
]
const TERMINAL_COMPLETION_TOKENS := [
	"HELP", "HELP CORE", "HELP MOVEMENT", "HELP SYSTEMS", "HELP POLICY",
	"HELP FABRICATION", "HELP ASSAULT", "HELP STATUS", "HELP PREP", "STATUS", "STATUS FULL",
	"CONTRACT", "PLANET", "MAP",
	"START ASSAULT",
	"WAIT", "WAIT UNTIL", "DEPLOY", "MOVE", "RETURN", "FOCUS", "HARDEN",
	"REPAIR", "SCAVENGE", "SET", "SET FAB", "POLICY SHOW", "POLICY PRESET",
	"FORTIFY", "CONFIG DOCTRINE", "ALLOCATE DEFENSE", "SCAN RELAYS",
	"STABILIZE RELAY", "SYNC", "FAB ADD", "FAB QUEUE", "FAB CANCEL",
	"FAB PRIORITY", "REROUTE POWER", "BOOST DEFENSE", "DRONE DEPLOY",
	"DEPLOY DRONE", "LOCKDOWN", "PRIORITIZE REPAIR", "STATUS RELAY",
	"OVERLAY SHOW", "OVERLAY THREAT", "OVERLAY PATH", "OVERLAY POWER", "OVERLAY REPAIR", "OVERLAY CLEAR",
	"TURRET", "TURRET GUNNER", "TURRET BLASTER", "TURRET REPEATER", "TURRET SNIPER",
	"ALLOCATE_DEFENSE", "DEPLOY", "FOCUS",
]

const SECTOR_DISPLAY_NAMES := {
	"COMMAND": "Command Center",
	"POWER": "Power",
	"DEFENSE": "Defense Grid",
	"DEFENSE GRID": "Defense Grid",
	"ARCHIVE": "Archive",
	"STORAGE": "Storage",
	"FABRICATION": "Fabrication",
	"COMMS": "Communications",
	"HANGAR": "Hangar",
	"GATEWAY": "Gateway",
	"T_NORTH": "North Transit",
	"T_SOUTH": "South Transit",
	"INGRESS_N": "North Ingress",
	"INGRESS_S": "South Ingress",
}

@onready var power_label = get_node_or_null("PowerDisplay/Label")
@onready var power_bar = get_node_or_null("PowerDisplay/PowerBar")
@onready var contract_phase_label = get_node_or_null("ContractPhaseLabel")
@onready var lives_label = get_node_or_null("LivesLabel")
@onready var camera_follow_label = get_node_or_null("CameraFollowLabel")
@onready var camera_zoom_label = get_node_or_null("CameraZoomLabel")
@onready var time_scale_label = get_node_or_null("TimeScaleLabel")
@onready var aim_mode_label = get_node_or_null("AimModeLabel")
@onready var weapon_label = get_node_or_null("WeaponLabel")
@onready var primary_weapon_button = get_node_or_null("PrimaryWeaponButton")
@onready var ammo_label = get_node_or_null("AmmoLabel")
@onready var cooldown_bar = get_node_or_null("CooldownBar")
@onready var cooldown_label = get_node_or_null("CooldownLabel")
@onready var stamina_label = get_node_or_null("StaminaLabel")
@onready var stamina_bar = get_node_or_null("StaminaBar")
@onready var director_label = get_node_or_null("DirectorLabel")
@onready var supply_drop_label = get_node_or_null("SupplyDropLabel")
@onready var crosshair_label = get_node_or_null("Crosshair")
@onready var interaction_label = get_node_or_null("InteractionLabel")

@onready var terminal_panel = get_node_or_null("TerminalPanel")
@onready var terminal_header_eyebrow = get_node_or_null("TerminalPanel/Header/Eyebrow")
@onready var terminal_title_label = get_node_or_null("TerminalPanel/Header/Title")
@onready var terminal_activity_scroll = get_node_or_null("TerminalPanel/Body/CommandColumn/ActivityScroll")
@onready var terminal_output = get_node_or_null("TerminalPanel/Body/CommandColumn/ActivityScroll/TerminalOutput")
@onready var terminal_command_title = get_node_or_null("TerminalPanel/Body/CommandColumn/CommandTitle")
@onready var terminal_input = get_node_or_null("TerminalPanel/Body/CommandColumn/InputRow/TerminalInput")
@onready var terminal_status_label = get_node_or_null("TerminalPanel/Body/CommandColumn/Status")
@onready var terminal_target_label = get_node_or_null("TerminalPanel/Header/Target")
@onready var terminal_hint_label = get_node_or_null("TerminalPanel/Hint")
@onready var terminal_map_title_label = get_node_or_null("TerminalPanel/Body/MapColumn/MapTitle")
@onready var terminal_planet_title_label = get_node_or_null("TerminalPanel/Body/MapColumn/PlanetPreviewTitle")
@onready var terminal_map_preview_title_label = get_node_or_null("TerminalPanel/Body/MapColumn/MapPreviewTitle")
@onready var terminal_map_label = get_node_or_null("TerminalPanel/Body/MapColumn/MapOutput")
@onready var terminal_planet_preview = get_node_or_null("TerminalPanel/Body/MapColumn/PlanetPreview")
@onready var terminal_background = get_node_or_null("TerminalBackground")
@onready var terminal_map_preview = get_node_or_null("TerminalPanel/Body/MapColumn/MapPreview")
@onready var terminal_header_panel = get_node_or_null("TerminalPanel/Header")

@onready var terminal_command_request = get_node_or_null("TerminalCommandRequest")
@onready var terminal_snapshot_request = get_node_or_null("TerminalSnapshotRequest")
@onready var terminal_poll_timer = get_node_or_null("TerminalPollTimer")

@export var terminal_contract_node_path: NodePath = NodePath("/root/GameRoot/ContractMap")

var _last_follow_state: bool = false
var _last_auto_zoom_state: bool = false
var _last_contract_phase_text := ""
var _last_time_scale := -1.0
var _last_aim_mode := ""
var _last_primary_equipped: bool = false
var _last_primary_weapon_id := ""
var _last_loadout_mode := ""
var _last_ammo_text := ""
var _last_cooldown_pct := -1.0
var _last_cooldown_text := ""
var _last_director_text := ""

var _terminal_open := false
var _terminal_ready := false
var _terminal_boot_started := false
var _terminal_service_url := DEFAULT_TERMINAL_SERVICE_URL
var _terminal_lines: Array[String] = []
var _terminal_log_entries: Array[Dictionary] = []
var _terminal_history: Array[String] = []
var _terminal_history_index := 0
var _terminal_snapshot: Dictionary = {}
var _terminal_command_inflight := false
var _terminal_command_queue: Array[Dictionary] = []
var _terminal_command_queue_tick := 0.0
var _terminal_snapshot_inflight := false
var _terminal_completion_matches: Array[String] = []
var _terminal_completion_index := -1
var _terminal_completion_seed := ""
var _terminal_contract_snapshot: Dictionary = {}
var _terminal_contract_node: Node = null
var _terminal_latest_contract: Dictionary = {}
var _planet_preview_viewport: SubViewport = null
var _planet_preview_root: Node3D = null
var _planet_preview_globe: MeshInstance3D = null
var _planet_preview_camera: Camera3D = null
var _planet_preview_environment: WorldEnvironment = null
var _planet_preview_drag_active := false
var _planet_preview_drag_last_pos := Vector2.ZERO
var _planet_preview_rotation := Vector2.ZERO
var _planet_preview_spin_velocity := Vector2.ZERO
var _planet_preview_zoom_distance := 3.8
var _main_hud_hidden := false
var _placement_mode_active := false
var _last_crosshair_aim_dir := Vector2.ZERO
var _last_crosshair_screen_pos := Vector2.ZERO
var _terminal_panel_saved_position := Vector2.ZERO
var _terminal_panel_saved_size := Vector2.ZERO
var _terminal_output_saved_min_height := 0.0
var _terminal_highlight_sector := ""
var _terminal_overlay_flags := {
	"power": false,
	"path": false,
	"threat": true,
	"repair": false,
}
var _terminal_last_phase := ""
var _terminal_last_wave_number := -1
var _terminal_last_threat_band := ""
var _terminal_known_sector_states: Dictionary = {}
var _terminal_map_render_bounds := {}
var _terminal_map_hover_world_pos := Vector2.ZERO

const PLANET_PREVIEW_ZOOM_MIN := 2.7
const PLANET_PREVIEW_ZOOM_MAX := 6.2
const PLANET_PREVIEW_ZOOM_STEP := 0.3
const TERMINAL_LOG_LIMIT := 1000
const TERMINAL_COMMAND_QUEUE_INTERVAL := 0.12
const TERMINAL_MAP_PREVIEW_SIZE := 256
const CROSSHAIR_WORLD_DISTANCE := 110.0
const CROSSHAIR_SCREEN_MARGIN := 22.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_set_main_hud_hidden(false)
	if terminal_panel:
		terminal_panel.visible = false
	if terminal_input and not terminal_input.text_submitted.is_connected(_on_terminal_input_submitted):
		terminal_input.text_submitted.connect(_on_terminal_input_submitted)
	if terminal_input and not terminal_input.gui_input.is_connected(_on_terminal_input_gui_input):
		terminal_input.gui_input.connect(_on_terminal_input_gui_input)
	if terminal_input and not terminal_input.text_changed.is_connected(_on_terminal_input_text_changed):
		terminal_input.text_changed.connect(_on_terminal_input_text_changed)
	if terminal_output and terminal_output.has_signal("meta_clicked") and not terminal_output.meta_clicked.is_connected(_on_terminal_activity_meta_clicked):
		terminal_output.meta_clicked.connect(_on_terminal_activity_meta_clicked)
	if terminal_planet_preview and not terminal_planet_preview.gui_input.is_connected(_on_terminal_planet_preview_gui_input):
		terminal_planet_preview.gui_input.connect(_on_terminal_planet_preview_gui_input)
	if terminal_planet_preview:
		terminal_planet_preview.mouse_filter = Control.MOUSE_FILTER_STOP
	if terminal_map_preview and not terminal_map_preview.gui_input.is_connected(_on_terminal_map_preview_gui_input):
		terminal_map_preview.gui_input.connect(_on_terminal_map_preview_gui_input)
	if terminal_map_preview:
		terminal_map_preview.mouse_filter = Control.MOUSE_FILTER_STOP
	if terminal_poll_timer and not terminal_poll_timer.timeout.is_connected(_on_terminal_poll_timeout):
		terminal_poll_timer.timeout.connect(_on_terminal_poll_timeout)
	if primary_weapon_button and not primary_weapon_button.pressed.is_connected(_on_primary_weapon_button_pressed):
		primary_weapon_button.pressed.connect(_on_primary_weapon_button_pressed)
	_apply_terminal_theme()
	_init_terminal_previews()
	_ensure_terminal_contract_binding()
	_bind_wall_placer_ui()
	_bind_turret_placement_ui()

func _process(delta):
	_handle_terminal_shortcuts()
	_update_terminal_planet_spin(delta)
	_process_terminal_command_queue(delta)

	var power_system = get_node_or_null("/root/GameRoot/Power")
	if not _main_hud_hidden and power_system and power_label and power_bar:
		var status = power_system.get_power_status()
		power_label.text = "POWER: %d/%d (%.1f/s)" % [status.total, status.max, status.consumed * 60]
		if status.max > 0:
			power_bar.value = (status.total / status.max) * 100

	var game_state := _get_game_state()
	if not _main_hud_hidden and game_state and contract_phase_label:
		var phase_text := "CONTRACT PHASE: %s" % game_state.get_phase_name().replace("_", " ")
		if phase_text != _last_contract_phase_text:
			contract_phase_label.text = phase_text
			_last_contract_phase_text = phase_text
		match game_state.current_phase:
			GameState.Phase.CONTRACT_BRIEFING:
				contract_phase_label.modulate = Color(0.9, 0.85, 0.45, 1.0)
			GameState.Phase.FREE_ROAM_PREP:
				contract_phase_label.modulate = Color(0.45, 0.95, 0.55, 1.0)
			GameState.Phase.ASSAULT_ACTIVE:
				contract_phase_label.modulate = Color(0.95, 0.4, 0.35, 1.0)
			GameState.Phase.POST_ASSAULT:
				contract_phase_label.modulate = Color(0.7, 0.8, 1.0, 1.0)
			GameState.Phase.EXFIL:
				contract_phase_label.modulate = Color(0.85, 0.85, 0.95, 1.0)
	if not _main_hud_hidden and lives_label:
		var total_lives := 3
		var remaining := 3
		if game_state != null:
			total_lives = max(1, int(game_state.total_lives))
			remaining = max(0, int(game_state.lives_remaining))
		lives_label.text = "LIVES: %d/%d" % [remaining, total_lives]

	var cam = get_node_or_null("/root/GameRoot/World/Camera2D")
	if not _main_hud_hidden and cam and camera_follow_label and camera_zoom_label and "auto_zoom_enabled" in cam and "follow_enabled" in cam:
		var follow_enabled: bool = bool(cam.follow_enabled)
		var auto_zoom_enabled: bool = bool(cam.auto_zoom_enabled)
		if follow_enabled != _last_follow_state or auto_zoom_enabled != _last_auto_zoom_state or camera_follow_label.text.is_empty() or camera_zoom_label.text.is_empty():
			camera_follow_label.text = "CAMERA: %s (C)" % ("TRACKING" if follow_enabled else "FREE")
			camera_zoom_label.text = "ZOOM: %s (Z)" % ("AUTO" if auto_zoom_enabled else "LOCKED")
			_last_follow_state = follow_enabled
			_last_auto_zoom_state = auto_zoom_enabled

	if not _main_hud_hidden and time_scale_label and Engine.time_scale != _last_time_scale:
		time_scale_label.text = "TIME SCALE: %.1fX (T)" % Engine.time_scale
		_last_time_scale = Engine.time_scale

	var operator = get_node_or_null("/root/GameRoot/World/Operator")
	if not _main_hud_hidden and operator and aim_mode_label:
		if operator.has_method("get_weapon_status"):
			var aim_ws = operator.get_weapon_status()
			var aim_mode := str(aim_ws.get("aim_mode", "mouse"))
			if aim_mode != _last_aim_mode or aim_mode_label.text.is_empty():
				aim_mode_label.text = "AIM: %s (V TOGGLE, ARROWS)" % aim_mode.to_upper()
				_last_aim_mode = aim_mode

	if not _main_hud_hidden and operator and weapon_label:
		if operator.has_method("get_weapon_status"):
			var ws = operator.get_weapon_status()
			var equipped := bool(ws.get("equipped", false))
			var primary_weapon_id := str(ws.get("primary_weapon_id", ""))
			var loadout_mode := str(ws.get("loadout_mode", "holstered"))
			if equipped != _last_primary_equipped or primary_weapon_id != _last_primary_weapon_id or loadout_mode != _last_loadout_mode or weapon_label.text.is_empty():
				var primary_label := "HOLSTERED"
				if loadout_mode == "melee":
					primary_label = "MELEE"
				elif equipped:
					primary_label = str(ws.get("weapon_name", "CARBINE"))
				var block_label := "ACTIVE" if bool(ws.get("blocking", false)) else "R/M2"
				weapon_label.text = "LOADOUT: %s (Q RANGED, E MELEE) | ATTACK: F/M1 | BLOCK: %s | RELOAD: X" % [primary_label, block_label]
				_last_primary_equipped = equipped
				_last_primary_weapon_id = primary_weapon_id
				_last_loadout_mode = loadout_mode
			if primary_weapon_button:
				primary_weapon_button.text = "UNEQUIP CARBINE" if equipped and primary_weapon_id == "carbine_rifle" else "EQUIP CARBINE"
			if ammo_label:
				var magazine_size = int(ws.get("ammo_standard_magazine_size", 0))
				var loaded = int(ws.get("ammo_standard_loaded", 0))
				var reserve = int(ws.ammo_standard)
				var reloading = bool(ws.get("reloading", false))
				
				var ammo_text = "AMMO: %d/%d +%d" % [loaded, magazine_size, reserve]
				if reloading:
					ammo_text += " [RELOADING...]"
				
				if ammo_text != _last_ammo_text:
					ammo_label.text = ammo_text
					_last_ammo_text = ammo_text
			if cooldown_bar and cooldown_label:
				var total = max(0.001, float(ws.cooldown_total))
				var remaining = max(0.0, float(ws.cooldown_remaining))
				var pct = clamp((remaining / total) * 100.0, 0.0, 100.0)
				if abs(pct - _last_cooldown_pct) > 0.1:
					cooldown_bar.value = pct
					_last_cooldown_pct = pct
				var cd_text = "COOLDOWN: READY" if remaining <= 0.001 else "COOLDOWN: %.2fs" % remaining
				if cd_text != _last_cooldown_text:
					cooldown_label.text = cd_text
					_last_cooldown_text = cd_text
		if operator.has_method("get_sprint_status"):
			var ss = operator.get_sprint_status()
			if stamina_label:
				var sprint_state = "EXHAUSTED" if bool(ss.get("sprint_exhausted", false)) else ("SPRINT" if bool(ss.get("is_sprinting", false)) else "JOG")
				var stamina_pct = (float(ss.get("stamina", 0.0)) / max(1.0, float(ss.get("stamina_max", 1.0)))) * 100.0
				stamina_label.text = "STAMINA: %d%% (%s, CTRL)" % [int(round(stamina_pct)), sprint_state]
			if stamina_bar:
				stamina_bar.value = clamp((float(ss.get("stamina", 0.0)) / max(1.0, float(ss.get("stamina_max", 1.0)))) * 100.0, 0.0, 100.0)

	if not _main_hud_hidden and director_label:
		var director_status = _get_local_director_status()
		if not director_status.is_empty():
			var line = "DIRECTOR W%s | TH %.1f | %s | %s" % [
				str(director_status.get("wave", 0)),
				float(director_status.get("threat", 0.0)),
				str(director_status.get("lane", "NONE")).to_upper(),
				str(director_status.get("objective", "NONE")).to_upper(),
			]
			if line != _last_director_text:
				director_label.text = line
				_last_director_text = line
			director_label.visible = true
		else:
			director_label.visible = false

	if crosshair_label:
		crosshair_label.visible = false

	if not _main_hud_hidden and supply_drop_label:
		var supply_manager = get_node_or_null("/root/GameRoot/SupplyDropManager")
		if supply_manager and supply_manager.has_method("get_status"):
			var status = supply_manager.get_status()
			if status.get("active", false):
				var next_drop = status.get("next_drop_in", -1.0)
				var drops = status.get("drops_queued", 0)
				if next_drop > 0:
					supply_drop_label.text = "SUPPLY DROP: %.0fs (%d queued)" % [next_drop, drops]
					supply_drop_label.visible = true
				elif drops > 0:
					supply_drop_label.text = "SUPPLY DROP: INCOMING (%d)" % drops
					supply_drop_label.visible = true
				else:
					supply_drop_label.visible = false
			else:
				supply_drop_label.visible = false

	if _main_hud_hidden:
		if power_label:
			power_label.visible = false
		if power_bar:
			power_bar.visible = false
		if contract_phase_label:
			contract_phase_label.visible = false
		if camera_follow_label:
			camera_follow_label.visible = false
		if camera_zoom_label:
			camera_zoom_label.visible = false
		if time_scale_label:
			time_scale_label.visible = false
		if weapon_label:
			weapon_label.visible = false
		if primary_weapon_button:
			primary_weapon_button.visible = false
		if ammo_label:
			ammo_label.visible = false
		if cooldown_bar:
			cooldown_bar.visible = false
		if cooldown_label:
			cooldown_label.visible = false
		if stamina_bar:
			stamina_bar.visible = false
		if stamina_label:
			stamina_label.visible = false
		if director_label:
			director_label.visible = false
		if supply_drop_label:
			supply_drop_label.visible = false

	if interaction_label:
		var prompt = ""
		var gs = game_state
		if gs and bool(gs.get("game_over")):
			prompt = "GAME OVER: %s" % str(gs.get("game_over_reason"))
			interaction_label.visible = true
			interaction_label.text = prompt
			return
		var operator_ref = get_node_or_null("/root/GameRoot/World/Operator")
		if operator_ref and operator_ref.has_method("get_interaction_prompt"):
			prompt = str(operator_ref.get_interaction_prompt())
		if _terminal_open:
			if _terminal_ready:
				prompt = "TERMINAL ACTIVE: TYPE COMMANDS | ESC CLOSE"
			else:
				prompt = "TERMINAL BOOTING..."
		interaction_label.visible = not prompt.is_empty()
		if interaction_label.visible:
			interaction_label.text = prompt

	_update_crosshair()


func _update_crosshair() -> void:
	if not crosshair_label:
		return
	if _main_hud_hidden or _terminal_open or _placement_mode_active:
		crosshair_label.visible = false
		return
	var operator_ref = get_node_or_null("/root/GameRoot/World/Operator")
	if operator_ref == null or not operator_ref.has_method("get_weapon_status"):
		crosshair_label.visible = false
		return
	var weapon_status = operator_ref.get_weapon_status()
	var aim_mode = str(weapon_status.get("aim_mode", "mouse"))
	if aim_mode != "arrows":
		crosshair_label.visible = false
		return
	var aim_dir = Vector2(weapon_status.get("aim_direction", Vector2.RIGHT))
	var normalized_aim = Vector2.RIGHT
	if aim_dir.length_squared() > 0.0001:
		normalized_aim = aim_dir.normalized()
	var camera = get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera == null:
		crosshair_label.visible = false
		return
	var player_pos = Vector2(weapon_status.get("player_position", operator_ref.global_position))
	var crosshair_world_pos = player_pos + normalized_aim * CROSSHAIR_WORLD_DISTANCE
	var viewport_rect = get_viewport().get_visible_rect()
	var screen_center = viewport_rect.size * 0.5
	var camera_pos = camera.global_position
	var camera_zoom = Vector2(camera.zoom.x, camera.zoom.y)
	var local = (crosshair_world_pos - camera_pos) * camera_zoom
	var screen_pos = screen_center + local + camera.offset
	var margin = CROSSHAIR_SCREEN_MARGIN
	screen_pos.x = clamp(screen_pos.x, margin, max(margin, viewport_rect.size.x - margin))
	screen_pos.y = clamp(screen_pos.y, margin, max(margin, viewport_rect.size.y - margin))

	if _last_crosshair_screen_pos == Vector2.ZERO:
		_last_crosshair_screen_pos = screen_pos

	var smoothed_screen_pos = _last_crosshair_screen_pos.lerp(screen_pos, 0.32)
	_last_crosshair_screen_pos = smoothed_screen_pos
	smoothed_screen_pos.x = clamp(smoothed_screen_pos.x, margin, max(margin, viewport_rect.size.x - margin))
	smoothed_screen_pos.y = clamp(smoothed_screen_pos.y, margin, max(margin, viewport_rect.size.y - margin))

	var crosshair_size = Vector2.ZERO
	if crosshair_label.texture:
		crosshair_size = crosshair_label.texture.get_size()
	crosshair_label.position = smoothed_screen_pos - crosshair_size * 0.5
	crosshair_label.visible = true
	crosshair_label.modulate = operator_ref.aim_crosshair_color
	_last_crosshair_aim_dir = normalized_aim


func _get_main_hud_nodes() -> Array:
	return [
		power_label,
		power_bar,
		contract_phase_label,
		lives_label,
		camera_follow_label,
		camera_zoom_label,
		time_scale_label,
		aim_mode_label,
		weapon_label,
		primary_weapon_button,
		ammo_label,
		cooldown_bar,
		cooldown_label,
		stamina_bar,
		stamina_label,
		director_label,
		supply_drop_label,
		crosshair_label,
		get_node_or_null("ControlsHintLabel"),
	]


func _set_main_hud_hidden(hidden: bool) -> void:
	_main_hud_hidden = hidden
	for node in _get_main_hud_nodes():
		if node:
			node.visible = not hidden
	if crosshair_label:
		crosshair_label.visible = false

func enter_placement_mode_ui() -> void:
	if _placement_mode_active:
		return
	_placement_mode_active = true
	_set_main_hud_hidden(true)
	if terminal_hint_label and _terminal_open:
		terminal_hint_label.text = "TACTICAL BUILD MODE // CLICK MINIMAP TO PLACE // RIGHT-CLICK OR ESC CANCELS"
		return
	
	if terminal_panel:
		_terminal_panel_saved_position = terminal_panel.position
		_terminal_panel_saved_size = terminal_panel.size
		var viewport_size := get_viewport().get_visible_rect().size
		terminal_panel.visible = true
		terminal_panel.position = Vector2(0, viewport_size.y - 120.0)
		terminal_panel.size = Vector2(viewport_size.x, 120.0)
	
	if terminal_header_panel:
		terminal_header_panel.visible = false
	
	if terminal_output:
		_terminal_output_saved_min_height = terminal_output.custom_minimum_size.y
		terminal_output.custom_minimum_size.y = 80
	
	print("[UI] Entered placement mode UI")


func exit_placement_mode_ui() -> void:
	if not _placement_mode_active:
		return
	_placement_mode_active = false
	_set_main_hud_hidden(false)
	if terminal_hint_label and _terminal_open:
		terminal_hint_label.text = "Type directly into the command line. Drag globe to inspect. Click tactical minimap to place while building. Esc closes."
		return
	
	if terminal_panel:
		terminal_panel.position = _terminal_panel_saved_position
		terminal_panel.size = _terminal_panel_saved_size
		if not _terminal_open:
			terminal_panel.visible = false
	if terminal_header_panel:
		terminal_header_panel.visible = true
	if terminal_output:
		terminal_output.custom_minimum_size.y = _terminal_output_saved_min_height
	
	print("[UI] Exited placement mode UI")

func open_command_terminal(service_url: String = ""):
	if not service_url.strip_edges().is_empty():
		_terminal_service_url = service_url.strip_edges()
	_terminal_open = true
	if terminal_panel:
		terminal_panel.visible = true
		terminal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if terminal_background:
		terminal_background.visible = true
		terminal_background.initialize()
		terminal_background.generate_new()
	if terminal_target_label:
		terminal_target_label.text = "SIM: %d TPS | THREAT: STABLE | POWER: -- | LINKING" % Engine.physics_ticks_per_second
	if not _terminal_ready:
		_terminal_ready = true
		_terminal_boot_started = true
		_terminal_lines.clear()
		_terminal_log_entries.clear()
		_terminal_command_queue.clear()
		_terminal_command_queue_tick = 0.0
		_append_terminal_line("CUSTODIAN COMMAND INTERFACE", "success")
		_append_terminal_line("LOCAL SNAPSHOT MODE ACTIVE", "info")
		_append_terminal_line("Type HELP for local commands.", "info")
	_set_terminal_input_enabled(true)
	_refresh_snapshot()
	if terminal_poll_timer:
		terminal_poll_timer.start()

func close_command_terminal():
	if _placement_mode_active:
		if not _cancel_active_placement_mode():
			exit_placement_mode_ui()
		return
	_terminal_open = false
	_terminal_command_queue.clear()
	_terminal_command_queue_tick = 0.0
	_set_terminal_input_enabled(false)
	if terminal_panel:
		terminal_panel.visible = false
	if terminal_background:
		terminal_background.visible = false
	if terminal_poll_timer:
		terminal_poll_timer.stop()

func is_terminal_open() -> bool:
	return _terminal_open

func _handle_terminal_shortcuts():
	if not _terminal_open:
		return
	_ensure_terminal_input_focus()
	if Input.is_action_just_pressed("ui_cancel"):
		if _placement_mode_active:
			if not _cancel_active_placement_mode():
				exit_placement_mode_ui()
			return
		close_command_terminal()

func _input(event: InputEvent) -> void:
	if not _terminal_open or terminal_planet_preview == null:
		return
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if not _planet_preview_contains_screen_point(button_event.position):
			return
		if button_event.button_index == MOUSE_BUTTON_WHEEL_UP and button_event.pressed:
			_planet_preview_zoom_distance = max(PLANET_PREVIEW_ZOOM_MIN, _planet_preview_zoom_distance - PLANET_PREVIEW_ZOOM_STEP)
			_apply_terminal_planet_zoom()
			terminal_input.grab_focus()
			get_viewport().set_input_as_handled()
			return
		if button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and button_event.pressed:
			_planet_preview_zoom_distance = min(PLANET_PREVIEW_ZOOM_MAX, _planet_preview_zoom_distance + PLANET_PREVIEW_ZOOM_STEP)
			_apply_terminal_planet_zoom()
			terminal_input.grab_focus()
			get_viewport().set_input_as_handled()
			return
		if button_event.button_index == MOUSE_BUTTON_LEFT:
			_planet_preview_drag_active = button_event.pressed
			_planet_preview_drag_last_pos = button_event.position
			if button_event.pressed:
				terminal_input.grab_focus()
			else:
				_planet_preview_spin_velocity.x = clamp(_planet_preview_spin_velocity.x, -2.2, 2.2)
				_planet_preview_spin_velocity.y = clamp(_planet_preview_spin_velocity.y, -4.2, 4.2)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _planet_preview_drag_active:
		var motion_event := event as InputEventMouseMotion
		var delta_pos := motion_event.position - _planet_preview_drag_last_pos
		_planet_preview_drag_last_pos = motion_event.position
		_planet_preview_rotation.x = clamp(_planet_preview_rotation.x - delta_pos.y * 0.005, -0.9, 0.9)
		_planet_preview_rotation.y += delta_pos.x * 0.012
		_planet_preview_spin_velocity.x = -delta_pos.y * 0.03
		_planet_preview_spin_velocity.y = delta_pos.x * 0.07
		_apply_terminal_planet_rotation()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not _terminal_open or not _terminal_ready or terminal_input == null or not terminal_input.editable:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed:
			terminal_input.grab_focus()
		return
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.ctrl_pressed or key_event.alt_pressed or key_event.meta_pressed:
		return
	var viewport := get_viewport()
	var focus_owner := viewport.gui_get_focus_owner() if viewport != null else null
	if focus_owner == terminal_input:
		return
	var typed_text := key_event.as_text_key_label()
	if typed_text.is_empty():
		return
	terminal_input.grab_focus()
	if typed_text.length() == 1:
		var next_text: String = terminal_input.text + typed_text
		terminal_input.text = next_text
		terminal_input.caret_column = next_text.length()
		terminal_input.accept_event()

func _set_terminal_input_enabled(enabled: bool):
	if terminal_input == null:
		return
	terminal_input.editable = enabled
	terminal_input.placeholder_text = "ENTER COMMAND" if enabled else "TERMINAL INPUT LOCKED"
	if enabled and _terminal_open:
		terminal_input.grab_focus()


func _ensure_terminal_input_focus():
	if terminal_input == null:
		return
	if not _terminal_open or not _terminal_ready:
		return
	if not terminal_input.editable:
		return
	var viewport := get_viewport()
	if viewport != null and viewport.gui_get_focus_owner() == terminal_input:
		return
	terminal_input.grab_focus()

func _update_terminal_planet_spin(delta: float) -> void:
	if _planet_preview_root == null or not is_instance_valid(_planet_preview_root):
		return
	if _planet_preview_drag_active:
		return
	if _planet_preview_spin_velocity.length_squared() < 0.0001:
		return
	_planet_preview_rotation.x = clamp(_planet_preview_rotation.x + _planet_preview_spin_velocity.x * delta, -0.9, 0.9)
	_planet_preview_rotation.y += _planet_preview_spin_velocity.y * delta
	_apply_terminal_planet_rotation()
	_planet_preview_spin_velocity = _planet_preview_spin_velocity.move_toward(Vector2.ZERO, 2.8 * delta)

func _apply_terminal_planet_rotation() -> void:
	if _planet_preview_root == null or not is_instance_valid(_planet_preview_root):
		return
	_planet_preview_root.rotation = Vector3(_planet_preview_rotation.x, _planet_preview_rotation.y, 0.0)

func _apply_terminal_planet_zoom() -> void:
	if _planet_preview_camera == null or not is_instance_valid(_planet_preview_camera):
		return
	_planet_preview_camera.position = Vector3(0.0, 0.06, _planet_preview_zoom_distance)

func _apply_terminal_theme():
	if terminal_panel:
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color(0.025, 0.035, 0.04, 0.975)
		panel_style.border_color = Color(0.34, 0.56, 0.48, 0.95)
		panel_style.set_border_width_all(2)
		panel_style.set_corner_radius_all(8)
		panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
		panel_style.shadow_size = 14
		terminal_panel.add_theme_stylebox_override("panel", panel_style)
		terminal_panel.modulate = Color(1, 1, 1, 1)

	if terminal_header_panel:
		var header_style := StyleBoxFlat.new()
		header_style.bg_color = Color(0.055, 0.08, 0.09, 0.98)
		header_style.border_color = Color(0.26, 0.5, 0.42, 1.0)
		header_style.set_border_width_all(1)
		header_style.set_corner_radius_all(5)
		terminal_header_panel.add_theme_stylebox_override("panel", header_style)

	for label in [terminal_header_eyebrow, terminal_command_title, terminal_map_title_label, terminal_planet_title_label, terminal_map_preview_title_label]:
		if label == null:
			continue
		label.add_theme_color_override("font_color", Color(0.63, 0.83, 0.74, 0.92))
		label.add_theme_font_size_override("font_size", 12)

	if terminal_title_label:
		terminal_title_label.add_theme_color_override("font_color", Color(0.93, 0.98, 0.95, 1.0))
		terminal_title_label.add_theme_font_size_override("font_size", 22)

	if terminal_target_label:
		terminal_target_label.add_theme_color_override("font_color", Color(0.76, 0.92, 0.86, 0.95))
		terminal_target_label.add_theme_font_size_override("font_size", 13)

	for output in [terminal_output, terminal_map_label]:
		if output == null:
			continue
		var output_style := StyleBoxFlat.new()
		output_style.bg_color = Color(0.012, 0.02, 0.024, 0.99)
		output_style.border_color = Color(0.18, 0.3, 0.28, 1.0)
		output_style.set_border_width_all(1)
		output_style.set_corner_radius_all(6)
		output.add_theme_stylebox_override("normal", output_style)
		output.add_theme_color_override("font_color", Color(0.82, 0.92, 0.88, 1.0))
		output.add_theme_font_size_override("font_size", 14)
		if output is RichTextLabel:
			output.scroll_following = true
			output.bbcode_enabled = true
	if terminal_activity_scroll:
		var scroll_style := StyleBoxFlat.new()
		scroll_style.bg_color = Color(0.012, 0.02, 0.024, 0.99)
		scroll_style.border_color = Color(0.18, 0.3, 0.28, 1.0)
		scroll_style.set_border_width_all(1)
		scroll_style.set_corner_radius_all(6)
		terminal_activity_scroll.add_theme_stylebox_override("panel", scroll_style)

	if terminal_input:
		var input_style := StyleBoxFlat.new()
		input_style.bg_color = Color(0.035, 0.08, 0.065, 0.995)
		input_style.border_color = Color(0.4, 0.78, 0.62, 1.0)
		input_style.set_border_width_all(2)
		input_style.set_corner_radius_all(6)
		terminal_input.add_theme_stylebox_override("normal", input_style)
		terminal_input.add_theme_stylebox_override("focus", input_style)
		terminal_input.add_theme_color_override("font_color", Color(0.9, 1.0, 0.94, 1.0))
		terminal_input.add_theme_color_override("font_placeholder_color", Color(0.56, 0.76, 0.68, 0.75))
		terminal_input.add_theme_font_size_override("font_size", 16)
	if terminal_status_label:
		terminal_status_label.add_theme_color_override("font_color", Color(0.64, 0.88, 0.78, 0.96))
		terminal_status_label.add_theme_font_size_override("font_size", 13)
	if terminal_hint_label:
		terminal_hint_label.add_theme_color_override("font_color", Color(0.54, 0.72, 0.68, 0.88))
		terminal_hint_label.add_theme_font_size_override("font_size", 12)
	if primary_weapon_button:
		var button_style := StyleBoxFlat.new()
		button_style.bg_color = Color(0.08, 0.12, 0.10, 0.92)
		button_style.border_color = Color(0.28, 0.68, 0.46, 1.0)
		button_style.set_border_width_all(1)
		button_style.set_corner_radius_all(3)
		primary_weapon_button.add_theme_stylebox_override("normal", button_style)
		primary_weapon_button.add_theme_stylebox_override("hover", button_style)
		primary_weapon_button.add_theme_stylebox_override("pressed", button_style)
		primary_weapon_button.add_theme_color_override("font_color", Color(0.88, 1.0, 0.92, 1.0))

func _append_terminal_line(line: String, level: String = "info", sector: String = ""):
	_terminal_lines.append(line)
	var entry := {
		"time": Time.get_time_string_from_system(),
		"line": line,
		"level": level,
		"sector": sector,
	}
	_terminal_log_entries.append(entry)
	if _terminal_log_entries.size() > TERMINAL_LOG_LIMIT:
		_terminal_log_entries = _terminal_log_entries.slice(_terminal_log_entries.size() - TERMINAL_LOG_LIMIT, _terminal_log_entries.size())
	_render_terminal_output()

func _render_terminal_output():
	if terminal_output == null:
		return
	var chunks: PackedStringArray = []
	for entry in _terminal_log_entries:
		var timestamp := str(entry.get("time", "--:--:--"))
		var line := str(entry.get("line", ""))
		var level := str(entry.get("level", "info"))
		var sector := str(entry.get("sector", ""))
		var level_color := _get_terminal_log_color(level)
		var rendered_line := _escape_bbcode(line)
		if not sector.is_empty():
			var sector_label := _display_sector_name(sector).to_upper()
			rendered_line += " [url=sector:%s][color=#8AD0FF]%s[/color][/url]" % [sector, _escape_bbcode(sector_label)]
		chunks.append("[color=#6FAE9C][%s][/color] [color=%s]%s[/color]" % [timestamp, level_color, rendered_line])
	if terminal_output is RichTextLabel:
		terminal_output.clear()
		terminal_output.append_text("\n".join(chunks))
	else:
		terminal_output.text = "\n".join(chunks)
	call_deferred("_scroll_terminal_output_to_bottom")

func _scroll_terminal_output_to_bottom():
	if terminal_output == null:
		return
	if terminal_output is RichTextLabel:
		terminal_output.scroll_to_line(max(0, terminal_output.get_line_count() - 1))

func _get_terminal_log_color(level: String) -> String:
	match level:
		"success":
			return "#7DDE9B"
		"warning":
			return "#E8C86D"
		"critical":
			return "#F07A7A"
		"command":
			return "#9EDBFF"
		"queued":
			return "#B7B6FF"
		_:
			return "#D7E8E1"

func _escape_bbcode(value: String) -> String:
	return value.replace("[", "[lb]").replace("]", "[rb]")

func _on_terminal_activity_meta_clicked(meta: Variant) -> void:
	var meta_text := str(meta)
	if not meta_text.begins_with("sector:"):
		return
	_terminal_highlight_sector = meta_text.trim_prefix("sector:")
	_append_terminal_line("FOCUS SHIFTED TO %s" % _display_sector_name(_terminal_highlight_sector).to_upper(), "success", _terminal_highlight_sector)
	_refresh_snapshot()

func _render_terminal_status(text: String):
	if terminal_status_label:
		terminal_status_label.text = text

func _run_terminal_boot_sequence() -> void:
	_set_terminal_input_enabled(false)
	for idx in range(TERMINAL_BOOT_LINES.size()):
		if not _terminal_open:
			return
		_append_terminal_line(TERMINAL_BOOT_LINES[idx])
		var delay = _boot_delay_for_line(idx)
		await get_tree().create_timer(delay).timeout

	if not _terminal_open:
		return
	await _clear_terminal_animated()
	if not _terminal_open:
		return

	_terminal_ready = true
	_append_terminal_line("")
	_append_terminal_line("--- COMMAND INTERFACE ACTIVE ---")
	_append_terminal_line("Awaiting directives.")
	_append_terminal_line("Type HELP for available commands.")
	_render_terminal_status("LINK ESTABLISHED")
	_set_terminal_input_enabled(true)
	_refresh_snapshot()
	if terminal_poll_timer:
		terminal_poll_timer.start()

func _boot_delay_for_line(idx: int) -> float:
	if idx == 0:
		return 0.9
	if idx == TERMINAL_BOOT_LINES.size() - 2:
		return 1.8
	if idx == TERMINAL_BOOT_LINES.size() - 1:
		return 2.6
	return randf_range(0.10, 0.24)

func _clear_terminal_animated() -> void:
	var passes = min(64, _terminal_log_entries.size())
	for _i in range(passes):
		if _terminal_log_entries.is_empty():
			break
		_terminal_log_entries.remove_at(_terminal_log_entries.size() - 1)
		_render_terminal_output()
		await get_tree().create_timer(0.018).timeout

func _on_terminal_input_submitted(raw_text: String) -> void:
	if not _terminal_open or not _terminal_ready:
		return
	if terminal_input == null:
		return
	var command = raw_text.strip_edges()
	if command.is_empty():
		return
	terminal_input.text = ""
	_reset_completion_state()
	_queue_terminal_command(command)

func _on_terminal_input_text_changed(new_text: String) -> void:
	_reset_completion_state()
	_update_terminal_input_validation(new_text)

func _on_terminal_input_gui_input(event: InputEvent) -> void:
	if terminal_input == null or not terminal_input.editable:
		return
	if not _terminal_open or not _terminal_ready:
		return
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_UP:
			_recall_history_previous()
			terminal_input.accept_event()
		KEY_DOWN:
			_recall_history_next()
			terminal_input.accept_event()
		KEY_TAB:
			if _autocomplete_terminal_input(key_event.shift_pressed):
				terminal_input.accept_event()

func _recall_history_previous():
	if _terminal_history.is_empty():
		return
	_terminal_history_index = max(0, _terminal_history_index - 1)
	_set_terminal_input_text(_terminal_history[_terminal_history_index])

func _recall_history_next():
	if _terminal_history.is_empty():
		return
	_terminal_history_index = min(_terminal_history.size(), _terminal_history_index + 1)
	if _terminal_history_index >= _terminal_history.size():
		_set_terminal_input_text("")
		return
	_set_terminal_input_text(_terminal_history[_terminal_history_index])

func _set_terminal_input_text(value: String):
	if terminal_input == null:
		return
	terminal_input.text = value
	terminal_input.caret_column = value.length()

func _autocomplete_terminal_input(reverse: bool) -> bool:
	if terminal_input == null:
		return false
	var seed = terminal_input.text.strip_edges().to_upper()
	if seed.is_empty():
		return false

	if _terminal_completion_seed != seed or _terminal_completion_matches.is_empty():
		_terminal_completion_seed = seed
		_terminal_completion_matches.clear()
		for token in TERMINAL_COMPLETION_TOKENS:
			if token.begins_with(seed):
				_terminal_completion_matches.append(token)
		_terminal_completion_index = -1
		if _terminal_completion_matches.is_empty():
			return false

	var count = _terminal_completion_matches.size()
	if reverse:
		_terminal_completion_index = (_terminal_completion_index - 1 + count) % count
	else:
		_terminal_completion_index = (_terminal_completion_index + 1) % count

	var suggestion = _terminal_completion_matches[_terminal_completion_index]
	_set_terminal_input_text("%s " % suggestion)
	return true

func _reset_completion_state():
	_terminal_completion_matches.clear()
	_terminal_completion_index = -1
	_terminal_completion_seed = ""

func _queue_terminal_command(command: String) -> void:
	var parsed := _parse_terminal_command(command)
	var cmd_upper := str(parsed.get("normalized", command.to_upper()))
	_terminal_history.append(cmd_upper)
	_terminal_history_index = _terminal_history.size()
	_terminal_command_queue.append(parsed)
	_append_terminal_line("> %s" % cmd_upper, "command")
	_append_terminal_line("QUEUED FOR SIM BUFFER", "queued")
	_render_terminal_status("QUEUE %d | VALIDATING" % _terminal_command_queue.size())

func _process_terminal_command_queue(delta: float) -> void:
	if not _terminal_open or not _terminal_ready:
		return
	if _terminal_command_inflight or _terminal_command_queue.is_empty():
		return
	_terminal_command_queue_tick += delta
	if _terminal_command_queue_tick < TERMINAL_COMMAND_QUEUE_INTERVAL:
		return
	_terminal_command_queue_tick = 0.0
	var parsed: Dictionary = _terminal_command_queue.pop_front()
	_execute_terminal_command_buffered(parsed)

func _execute_terminal_command_buffered(parsed: Dictionary) -> void:
	_terminal_command_inflight = true
	_set_terminal_input_enabled(false)
	var cmd_upper := str(parsed.get("normalized", ""))
	_render_terminal_status("EXECUTING %s" % cmd_upper)
	var handled := _execute_local_terminal_command(parsed)
	if handled:
		_append_terminal_line("COMMAND ACCEPTED", "success")
		_render_terminal_status("QUEUE %d | LINK STABLE" % _terminal_command_queue.size())
	else:
		_append_terminal_line("UNKNOWN LOCAL COMMAND", "warning")
		_append_terminal_line("VALID: HELP STATUS PREP ENEMIES WAVE SECTORS CONTRACT PLANET MAP WALL START ASSAULT CLEAR OVERLAY", "warning")
		_render_terminal_status("COMMAND REJECTED")
	_set_terminal_input_enabled(true)
	_terminal_command_inflight = false
	if _should_refresh_snapshot(cmd_upper):
		_refresh_snapshot()

func _parse_terminal_command(command: String) -> Dictionary:
	var normalized := command.strip_edges().to_upper()
	var tokens := normalized.split(" ", false)
	var verb := tokens[0] if not tokens.is_empty() else ""
	var args: Array[String] = []
	var params: Dictionary = {}
	for i in range(1, tokens.size()):
		var token := str(tokens[i])
		if token.contains("="):
			var parts := token.split("=", false, 1)
			if parts.size() == 2:
				params[str(parts[0]).to_lower()] = str(parts[1])
		else:
			args.append(token)
	return {
		"raw": command,
		"normalized": normalized,
		"verb": verb,
		"args": args,
		"params": params,
	}

func _update_terminal_input_validation(raw_text: String) -> void:
	if terminal_status_label == null:
		return
	var parsed := _parse_terminal_command(raw_text)
	var verb := str(parsed.get("verb", ""))
	if verb.is_empty():
		terminal_status_label.text = "READY // COMMAND BAR ACTIVE"
		return
	var valid_verbs := {
		"HELP": true, "STATUS": true, "ENEMIES": true, "WAVE": true, "SECTORS": true,
		"CONTRACT": true, "PLANET": true, "MAP": true, "CLEAR": true, "WALL": true,
		"START": true, "OVERLAY": true, "ALLOCATE_DEFENSE": true, "DEPLOY": true, "FOCUS": true,
	}
	if valid_verbs.has(verb):
		terminal_status_label.text = "VALIDATING // %s" % verb
	else:
		terminal_status_label.text = "UNKNOWN VERB // %s" % verb

func _should_refresh_snapshot(command_upper: String) -> bool:
	var verb = command_upper.split(" ", false, 1)[0]
	return verb in [
		"STATUS", "ENEMIES", "WAVE", "SECTORS", "CONTRACT", "PLANET", "MAP",
		"START", "WALL", "TURRET",
		"WAIT", "RESET", "REBOOT", "SET", "FAB", "CONFIG",
		"ALLOCATE", "FOCUS", "HARDEN", "SCAVENGE", "REPAIR", "DEPLOY",
		"MOVE", "RETURN", "SYNC", "LOCKDOWN", "OVERLAY", "ALLOCATE_DEFENSE",
	]

func _on_terminal_poll_timeout():
	if _terminal_open and _terminal_ready:
		_refresh_snapshot()

func _refresh_snapshot() -> void:
	_ensure_terminal_contract_binding()
	_terminal_snapshot = _build_local_snapshot()
	_record_terminal_snapshot_events(_terminal_snapshot)
	_render_terminal_header(_terminal_snapshot)
	_render_map_output(_terminal_snapshot)
	_refresh_contract_previews()
	_render_terminal_status("LOCAL SNAPSHOT LIVE")

func _render_terminal_header(snapshot: Dictionary) -> void:
	var contract: Dictionary = snapshot.get("contract", {})
	var contract_seed := int(contract.get("contract_seed", -1)) if contract is Dictionary else -1
	var planet_key := str(contract.get("planet_key", "NO CONTRACT")).to_upper() if contract is Dictionary else "NO CONTRACT"
	var phase_text := str(snapshot.get("contract_phase", "UNKNOWN")).replace("_", " ").to_upper()
	if terminal_header_eyebrow:
		terminal_header_eyebrow.text = "CUSTODIAN NODE // %s" % ("CONTRACT ACTIVE" if contract_seed >= 0 else "OFFLINE LINK")
	if terminal_title_label:
		terminal_title_label.text = "%s // %s" % [planet_key, "CONTRACT-%04d" % contract_seed if contract_seed >= 0 else "NO CONTRACT LOCK"]
	if terminal_target_label:
		var threat_value := float(snapshot.get("threat_raw", 0.0))
		var power_pct := float(snapshot.get("power_pct", 0.0))
		var threat_label := _get_threat_band(threat_value)
		var threat_color := _get_threat_color(threat_label)
		terminal_target_label.text = "SIM: %d TPS | THREAT: %s | POWER: %d%% | %s" % [Engine.physics_ticks_per_second, threat_label, int(round(power_pct)), phase_text]
		terminal_target_label.add_theme_color_override("font_color", Color(threat_color))

func _record_terminal_snapshot_events(snapshot: Dictionary) -> void:
	var phase_text := str(snapshot.get("contract_phase", "UNKNOWN"))
	if _terminal_last_phase != phase_text:
		if not _terminal_last_phase.is_empty():
			_append_terminal_line("PHASE SHIFT -> %s" % phase_text.replace("_", " ").to_upper(), "warning")
		_terminal_last_phase = phase_text

	var threat_value := float(snapshot.get("threat_raw", 0.0))
	var threat_band := _get_threat_band(threat_value)
	if _terminal_last_threat_band != threat_band:
		if not _terminal_last_threat_band.is_empty():
			_append_terminal_line("THREAT BAND -> %s (%.1f)" % [threat_band, threat_value], "warning")
		_terminal_last_threat_band = threat_band

	var wave: Dictionary = snapshot.get("wave", {})
	if wave is Dictionary:
		var wave_number := int(wave.get("wave_number", 0))
		if _terminal_last_wave_number >= 0 and wave_number != _terminal_last_wave_number:
			_append_terminal_line("ASSAULT WAVE %d ACTIVE" % wave_number, "critical")
		_terminal_last_wave_number = wave_number

	var sectors = snapshot.get("sectors", [])
	if sectors is Array:
		for sector in sectors:
			if not (sector is Dictionary):
				continue
			var sector_name := str(sector.get("name", "SECTOR"))
			var status := str(sector.get("status", "UNKNOWN")).to_upper()
			var previous_status := str(_terminal_known_sector_states.get(sector_name, ""))
			if not previous_status.is_empty() and previous_status != status:
				var level := "warning"
				if status.find("BREACH") >= 0 or status.find("DAMAGED") >= 0 or status.find("CRITICAL") >= 0:
					level = "critical"
				_append_terminal_line("%s STATUS -> %s" % [_display_sector_name(sector_name).to_upper(), status], level, sector_name)
			_terminal_known_sector_states[sector_name] = status

func _get_threat_band(threat_value: float) -> String:
	if threat_value >= 7.5:
		return "CRITICAL"
	if threat_value >= 4.0:
		return "ELEVATED"
	return "STABLE"

func _get_threat_color(threat_band: String) -> String:
	match threat_band:
		"CRITICAL":
			return "#F07A7A"
		"ELEVATED":
			return "#E8C86D"
		_:
			return "#7DDE9B"

func _on_primary_weapon_button_pressed() -> void:
	var operator = get_node_or_null("/root/GameRoot/World/Operator")
	if operator == null:
		return
	if operator.has_method("toggle_primary_carbine"):
		operator.toggle_primary_carbine()

func _render_map_output(snapshot: Dictionary):
	if terminal_map_label == null:
		return
	var lines: Array[String] = []
	if snapshot.is_empty():
		lines.append("[color=#7DAF9D]PHASE[/color]    NO LINK")
		lines.append("[color=#7DAF9D]THREAT[/color]   --")
		lines.append("[color=#7DAF9D]ASSAULT[/color]  --")
		lines.append("[color=#7DAF9D]HOSTILES[/color] --")
		lines.append("[color=#7DAF9D]MATERIAL[/color] --")
		terminal_map_label.text = "\n".join(lines)
		return

	var local_director := _get_local_director_status()
	var threat_value = snapshot.get("threat", "?")
	var assault_value = snapshot.get("assault", "?")
	if threat_value == "?" and not local_director.is_empty():
		threat_value = "%.1f" % float(local_director.get("threat", 0.0))
	if assault_value == "?" and not local_director.is_empty():
		assault_value = "%s/%s" % [
			str(local_director.get("lane", "none")).to_upper(),
			str(local_director.get("objective", "none")).to_upper(),
		]
	var wave = snapshot.get("wave", {})
	var wave_text := "--"
	if wave is Dictionary and not wave.is_empty():
		var wn = int(wave.get("wave_number", 0))
		var wmax = int(wave.get("max_wave", 0))
		var pending = int(wave.get("pending_spawns", 0))
		wave_text = "%d/%d P%d" % [wn, wmax, pending]
	var enemies = snapshot.get("enemies", {})
	var hostile_text := "--"
	if enemies is Dictionary and not enemies.is_empty():
		hostile_text = "%d | D%d F%d H%d" % [
			int(enemies.get("total", 0)),
			int(enemies.get("drone", 0)),
			int(enemies.get("fast", 0)),
			int(enemies.get("heavy", 0)),
		]
	var contract = snapshot.get("contract", {})
	if contract is Dictionary and not contract.is_empty():
		lines.append("[color=#7DAF9D]PHASE[/color]    %s" % str(snapshot.get("contract_phase", "UNKNOWN")).replace("_", " ").to_upper())
		lines.append("[color=#7DAF9D]THREAT[/color]   %s" % str(threat_value))
		lines.append("[color=#7DAF9D]ASSAULT[/color]  %s" % str(assault_value))
		lines.append("[color=#7DAF9D]HOSTILES[/color] %s" % hostile_text)
		lines.append("[color=#7DAF9D]MATERIAL[/color] %s" % str(snapshot.get("materials", 0)))
		lines.append("[color=#7DAF9D]DEFENSE[/color]  %s" % str(snapshot.get("defense_rating", 0.0)))
		lines.append("[color=#7DAF9D]WAVE[/color]     %s" % wave_text)
		lines.append("")
		lines.append("[color=#7DAF9D]PLANET[/color]   %s" % str(contract.get("planet_key", "UNKNOWN")).to_upper())
		lines.append("[color=#7DAF9D]CONTRACT[/color] #%d" % int(contract.get("contract_seed", -1)))
		lines.append("[color=#7DAF9D]MAP[/color]      %s" % str(contract.get("map_seed", "?")))
		lines.append("[color=#7DAF9D]ROOMS[/color]    %d" % int(contract.get("room_count", 0)))
		lines.append("[color=#7DAF9D]SPAWNS[/color]   %d" % int(contract.get("corridor_spawn_count", 0)))
	else:
		lines.append("[color=#7DAF9D]PHASE[/color]    %s" % str(snapshot.get("contract_phase", "UNKNOWN")).replace("_", " ").to_upper())
		lines.append("[color=#7DAF9D]THREAT[/color]   %s" % str(threat_value))
		lines.append("[color=#7DAF9D]ASSAULT[/color]  %s" % str(assault_value))
		lines.append("[color=#7DAF9D]HOSTILES[/color] %s" % hostile_text)
		lines.append("[color=#7DAF9D]MATERIAL[/color] %s" % str(snapshot.get("materials", 0)))
		lines.append("[color=#7DAF9D]DEFENSE[/color]  %s" % str(snapshot.get("defense_rating", 0.0)))
		lines.append("[color=#7DAF9D]WAVE[/color]     %s" % wave_text)
		lines.append("")
		lines.append("[color=#7DAF9D]PLANET[/color]   NO CONTRACT")

	var sectors = snapshot.get("sectors", [])
	if sectors is Array and not sectors.is_empty():
		lines.append("")
		lines.append("[color=#7DAF9D]SECTORS[/color]")
		for sector in sectors:
			if not (sector is Dictionary):
				continue
			var raw_name = str(sector.get("name", sector.get("id", "SECTOR")))
			var display = _display_sector_name(raw_name)
			var status = str(sector.get("status", "UNKNOWN"))
			var prefix := "•"
			if _terminal_highlight_sector == raw_name:
				prefix = "▶"
			lines.append("%s %s  %s" % [prefix, display.to_upper(), status.to_upper()])

	lines.append("")
	lines.append("[color=#7DAF9D]OVERLAYS[/color] PWR:%s PATH:%s THREAT:%s REPAIR:%s" % [
		"ON" if bool(_terminal_overlay_flags.get("power", false)) else "OFF",
		"ON" if bool(_terminal_overlay_flags.get("path", false)) else "OFF",
		"ON" if bool(_terminal_overlay_flags.get("threat", false)) else "OFF",
		"ON" if bool(_terminal_overlay_flags.get("repair", false)) else "OFF",
	])

	if terminal_map_label is RichTextLabel:
		terminal_map_label.clear()
		terminal_map_label.append_text("\n".join(lines))
	else:
		terminal_map_label.text = "\n".join(lines)

func _build_local_snapshot() -> Dictionary:
	var sectors = _collect_sector_snapshot()
	var enemies = _collect_enemy_snapshot()
	var wave = _collect_wave_snapshot()
	var director = _get_local_director_status()
	var contract = _collect_contract_snapshot()
	var game_state = _get_game_state()
	var power_pct := _get_terminal_power_utilization_pct()
	return {
		"time": str(Time.get_time_string_from_system()),
		"threat": "%.1f" % float(director.get("threat", 0.0)) if not director.is_empty() else "?",
		"threat_raw": float(director.get("threat", 0.0)) if not director.is_empty() else 0.0,
		"assault": "%s/%s" % [
			str(director.get("lane", "none")).to_upper(),
			str(director.get("objective", "none")).to_upper(),
		] if not director.is_empty() else "?",
		"player_mode": "LIVE",
		"contract_phase": game_state.get_phase_name() if game_state != null else "UNKNOWN",
		"materials": int(game_state.materials) if game_state != null else 0,
		"defense_rating": snapped(float(game_state.defense_rating), 0.1) if game_state != null else 0.0,
		"sectors": sectors,
		"enemies": enemies,
		"wave": wave,
		"contract": contract,
		"power_pct": power_pct,
		"tactical_entities": _collect_tactical_entities(),
	}

func _collect_sector_snapshot() -> Array[Dictionary]:
	var sectors: Array[Dictionary] = []
	for node in get_tree().get_nodes_in_group("structure"):
		if not (node is Node2D):
			continue
		var entry: Dictionary = {}
		entry["name"] = str(node.get("sector_name") if "sector_name" in node else node.name)
		entry["status"] = str(node.get("state") if "state" in node else "unknown")
		entry["world_pos"] = node.global_position
		if "current_health" in node and "max_health" in node:
			var hp = float(node.get("current_health"))
			var hp_max = max(1.0, float(node.get("max_health")))
			entry["hp_pct"] = int(round((hp / hp_max) * 100.0))
		sectors.append(entry)
	sectors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("name", "")) < str(b.get("name", ""))
	)
	return sectors

func _collect_enemy_snapshot() -> Dictionary:
	var summary := {"total": 0, "drone": 0, "fast": 0, "heavy": 0}
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == null or not is_instance_valid(enemy):
			continue
		summary["total"] = int(summary["total"]) + 1
		var name = str(enemy.get("enemy_name") if "enemy_name" in enemy else enemy.name).to_upper()
		if name.find("FAST") >= 0:
			summary["fast"] = int(summary["fast"]) + 1
		elif name.find("HEAVY") >= 0:
			summary["heavy"] = int(summary["heavy"]) + 1
		else:
			summary["drone"] = int(summary["drone"]) + 1
	return summary

func _collect_tactical_entities() -> Dictionary:
	var entities := {
		"operator": [],
		"turrets": [],
		"enemies": [],
	}
	var operator = get_node_or_null("/root/GameRoot/World/Operator")
	if operator and operator is Node2D:
		entities["operator"].append({"pos": operator.global_position})
	for turret in get_tree().get_nodes_in_group("turret"):
		if turret is Node2D:
			entities["turrets"].append({
				"pos": turret.global_position,
				"health": turret.get("health") if turret.has_method("get") else null,
			})
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node2D:
			entities["enemies"].append({
				"pos": enemy.global_position,
				"type": str(enemy.get("enemy_name") if "enemy_name" in enemy else enemy.name),
			})
	return entities

func _get_terminal_power_utilization_pct() -> float:
	var power_system = get_node_or_null("/root/GameRoot/Power")
	if power_system == null or not power_system.has_method("get_power_status"):
		return 0.0
	var status: Dictionary = power_system.get_power_status()
	var total := float(status.get("total", 0.0))
	var max_value := float(status.get("max", 0.0))
	if max_value <= 0.001:
		return 0.0
	return clampf((total / max_value) * 100.0, 0.0, 100.0)

func _collect_wave_snapshot() -> Dictionary:
	var wave_manager = get_node_or_null("/root/GameRoot/WaveManager")
	if wave_manager and wave_manager.has_method("get_wave_status"):
		var status = wave_manager.call("get_wave_status")
		if status is Dictionary:
			return status
	return {}

func _execute_local_terminal_command(parsed: Dictionary) -> bool:
	var cmd_upper := str(parsed.get("normalized", ""))
	var verb := str(parsed.get("verb", ""))
	var args: Array[String] = parsed.get("args", [])
	var params: Dictionary = parsed.get("params", {})
	if cmd_upper == "STATUS FULL" or cmd_upper == "STATUS":
		_refresh_snapshot()
		var wave = _collect_wave_snapshot()
		var enemies = _collect_enemy_snapshot()
		var contract = _collect_contract_snapshot()
		var game_state = _get_game_state()
		_append_terminal_line("SNAPSHOT REFRESHED", "success")
		if game_state != null:
			_append_terminal_line("CONTRACT PHASE=%s | MATERIALS=%d | DEFENSE=%.1f" % [
				game_state.get_phase_name(),
				int(game_state.materials),
				float(game_state.defense_rating),
			], "info")
		_append_terminal_line("WAVE %d/%d | IN_PROGRESS=%s | PENDING=%d" % [
			int(wave.get("wave_number", 0)),
			int(wave.get("max_wave", 0)),
			"YES" if bool(wave.get("in_progress", false)) else "NO",
			int(wave.get("pending_spawns", 0)),
		], "info")
		_append_terminal_line("ENEMIES TOTAL=%d DRONE=%d FAST=%d HEAVY=%d" % [
			int(enemies.get("total", 0)),
			int(enemies.get("drone", 0)),
			int(enemies.get("fast", 0)),
			int(enemies.get("heavy", 0)),
		], "info")
		if not contract.is_empty():
			_append_terminal_line("CONTRACT #%d | PLANET=%s | MAP=%s" % [
				int(contract.get("contract_seed", -1)),
				str(contract.get("planet_key", "UNKNOWN")).to_upper(),
				str(contract.get("map_seed", "?")),
			], "info")
		else:
			_append_terminal_line("CONTRACT NONE", "warning")
		return true
	if cmd_upper == "START ASSAULT":
		var game_state := _get_game_state()
		if game_state == null:
			_append_terminal_line("CONTRACT STATE UNAVAILABLE", "warning")
			return true
		if game_state.start_assault():
			_append_terminal_line("ASSAULT INITIATED. DEFEND THE COMPOUND.", "critical")
		else:
			_append_terminal_line("ASSAULT NOT AVAILABLE IN PHASE %s" % game_state.get_phase_name(), "warning")
		return true
	if cmd_upper == "HELP ASSAULT":
		_append_terminal_line("ASSAULT COMMANDS: STATUS FULL, WAVE, ENEMIES, SECTORS, START ASSAULT", "info")
		_append_terminal_line("START ASSAULT is only valid during FREE_ROAM_PREP.", "info")
		return true
		if cmd_upper == "HELP PREP":
			_append_terminal_line("PREP COMMANDS: STATUS, CONTRACT, MAP, SECTORS, WALL, TURRET <TYPE>, START ASSAULT", "info")
			_append_terminal_line("FREE_ROAM_PREP keeps waves inactive until you trigger the assault.", "info")
			_append_terminal_line("WALL and TURRET placement can be driven from the tactical minimap.", "info")
			return true
	if cmd_upper == "HELP STATUS":
		_append_terminal_line("STATUS: quick snapshot refresh.", "info")
		_append_terminal_line("STATUS FULL: contract phase + snapshot + wave + enemy summary lines.", "info")
		_append_terminal_line("CONTRACT/PLANET/MAP: active contract metadata.", "info")
		return true

	match verb:
		"HELP":
			_append_terminal_line("LOCAL COMMANDS: HELP STATUS PREP ENEMIES WAVE SECTORS CONTRACT PLANET MAP START ASSAULT WALL TURRET CLEAR OVERLAY", "info")
			_append_terminal_line("BUFFERED COMMANDS: ALLOCATE_DEFENSE sector=COMMAND weight=HIGH | DEPLOY turret_sniper x=14 y=22 | FOCUS relay_network priority=stability", "info")
			return true
		"ENEMIES":
			var enemies = _collect_enemy_snapshot()
			_append_terminal_line("ENEMIES TOTAL=%d DRONE=%d FAST=%d HEAVY=%d" % [
				int(enemies.get("total", 0)),
				int(enemies.get("drone", 0)),
				int(enemies.get("fast", 0)),
				int(enemies.get("heavy", 0)),
			], "info")
			return true
		"WAVE":
			var wave = _collect_wave_snapshot()
			_append_terminal_line("WAVE %d/%d | IN_PROGRESS=%s | PENDING=%d" % [
				int(wave.get("wave_number", 0)),
				int(wave.get("max_wave", 0)),
				"YES" if bool(wave.get("in_progress", false)) else "NO",
				int(wave.get("pending_spawns", 0)),
			], "info")
			return true
		"SECTORS":
			for sector in _collect_sector_snapshot():
				_append_terminal_line("%s | %s | HP %s%%" % [
					str(sector.get("name", "SECTOR")),
					str(sector.get("status", "unknown")).to_upper(),
					str(sector.get("hp_pct", "?")),
				], "info", str(sector.get("name", "")))
			return true
		"CONTRACT":
			var contract = _collect_contract_snapshot()
			if contract.is_empty():
				_append_terminal_line("NO ACTIVE CONTRACT", "warning")
			else:
				_append_terminal_line("CONTRACT #%d" % int(contract.get("contract_seed", -1)), "info")
				_append_terminal_line("PLANET=%s | PLANET_SEED=%s" % [
					str(contract.get("planet_key", "UNKNOWN")).to_upper(),
					str(contract.get("planet_seed", "?")),
				], "info")
				_append_terminal_line("MAP_SEED=%s | ROOMS=%d | SPAWNS=%d" % [
					str(contract.get("map_seed", "?")),
					int(contract.get("room_count", 0)),
					int(contract.get("corridor_spawn_count", 0)),
				], "info")
			return true
		"PLANET":
			var planet_contract = _collect_contract_snapshot()
			if planet_contract.is_empty():
				_append_terminal_line("NO ACTIVE PLANET CONTRACT", "warning")
			else:
				_append_terminal_line("PLANET %s (seed=%s)" % [
					str(planet_contract.get("planet_key", "UNKNOWN")).to_upper(),
					str(planet_contract.get("planet_seed", "?")),
				], "info")
			return true
		"MAP":
			var map_contract = _collect_contract_snapshot()
			if map_contract.is_empty():
				_append_terminal_line("NO ACTIVE MAP CONTRACT", "warning")
			else:
				_append_terminal_line("MAP seed=%s rooms=%d spawns=%d random_tiles=%d" % [
					str(map_contract.get("map_seed", "?")),
					int(map_contract.get("room_count", 0)),
					int(map_contract.get("corridor_spawn_count", 0)),
					int(map_contract.get("random_floor_tiles_count", 0)),
				], "info")
			return true
		"CLEAR":
			_terminal_lines.clear()
			_terminal_log_entries.clear()
			_render_terminal_output()
			return true
		"WALL":
			var wall_placer = get_node_or_null("/root/GameRoot/World/WallPlacer")
			if wall_placer == null:
				_append_terminal_line("WALL PLACEMENT UNAVAILABLE", "warning")
				return true
			if wall_placer.get_placement_active():
				wall_placer.exit_placement_mode()
				_append_terminal_line("WALL PLACEMENT EXITED", "success")
			else:
				wall_placer.enter_placement_mode()
				_append_terminal_line("WALL PLACEMENT MODE ACTIVE", "success")
				_append_terminal_line("1=BARRICADE 2=WALL 3=REINFORCED 4=DOUBLE | CLICK TACTICAL MINIMAP TO PLACE | TAB ROTATES", "info")
			return true
		"TURRET":
			var turret_placement = get_node_or_null("/root/GameRoot/World/TurretPlacement")
			if turret_placement == null:
				_append_terminal_line("TURRET PLACEMENT UNAVAILABLE", "warning")
				return true
			if args.is_empty():
				_append_terminal_line("TURRETS: GUNNER(10) BLASTER(15) REPEATER(20) SNIPER(25)", "info")
				_append_terminal_line("USE: TURRET GUNNER", "info")
				return true
			var turret_type := str(args[0]).to_lower()
			if not turret_placement.has_method("enter_placement_mode"):
				_append_terminal_line("TURRET PLACEMENT API MISSING", "warning")
				return true
			if turret_placement.call("enter_placement_mode", turret_type):
				_append_terminal_line("TURRET PLACEMENT ACTIVE // %s" % turret_type.to_upper(), "success")
				_append_terminal_line("CLICK TACTICAL MINIMAP TO PLACE // Q OR ESC TO EXIT", "info")
			else:
				_append_terminal_line("TURRET PLACEMENT FAILED // CHECK MATERIALS OR CAP", "warning")
			return true
		"OVERLAY":
			var overlay_name := str(args[0]).to_lower() if not args.is_empty() else "show"
			if overlay_name == "show":
				_append_terminal_line("OVERLAYS PWR=%s PATH=%s THREAT=%s REPAIR=%s" % [
					"ON" if bool(_terminal_overlay_flags.get("power", false)) else "OFF",
					"ON" if bool(_terminal_overlay_flags.get("path", false)) else "OFF",
					"ON" if bool(_terminal_overlay_flags.get("threat", false)) else "OFF",
					"ON" if bool(_terminal_overlay_flags.get("repair", false)) else "OFF",
				], "info")
				return true
			if overlay_name == "clear":
				for key in _terminal_overlay_flags.keys():
					_terminal_overlay_flags[key] = false
				_append_terminal_line("ALL MAP OVERLAYS DISABLED", "success")
				return true
			if _terminal_overlay_flags.has(overlay_name):
				_terminal_overlay_flags[overlay_name] = not bool(_terminal_overlay_flags.get(overlay_name, false))
				_append_terminal_line("%s OVERLAY %s" % [overlay_name.to_upper(), "ENABLED" if bool(_terminal_overlay_flags[overlay_name]) else "DISABLED"], "success")
				return true
			_append_terminal_line("UNKNOWN OVERLAY", "warning")
			return true
		"ALLOCATE_DEFENSE":
			var sector_name := str(params.get("sector", "COMMAND")).to_upper()
			var weight := str(params.get("weight", "MEDIUM")).to_upper()
			_terminal_highlight_sector = sector_name
			_append_terminal_line("DEFENSE ALLOCATION BUFFERED sector=%s weight=%s" % [sector_name, weight], "success", sector_name)
			return true
		"DEPLOY":
			var deploy_type := str(args[0]).to_upper() if not args.is_empty() else "ASSET"
			_append_terminal_line("DEPLOY BUFFERED %s x=%s y=%s" % [
				deploy_type,
				str(params.get("x", "?")),
				str(params.get("y", "?")),
			], "success")
			return true
		"FOCUS":
			var focus_target := str(args[0]).to_upper() if not args.is_empty() else "SYSTEM"
			var priority := str(params.get("priority", "NORMAL")).to_upper()
			_append_terminal_line("FOCUS BUFFERED target=%s priority=%s" % [focus_target, priority], "success")
			return true
		_:
			return false

func _get_game_state() -> Node:
	return get_node_or_null("/root/GameState")

func _get_local_director_status() -> Dictionary:
	var director = get_node_or_null("/root/GameRoot/EnemyDirector")
	if director and director.has_method("get_director_status"):
		var status = director.call("get_director_status")
		if status is Dictionary:
			return status
	return {}

func _collect_contract_snapshot() -> Dictionary:
	_ensure_terminal_contract_binding()
	if _terminal_contract_snapshot.is_empty():
		return {}
	return _terminal_contract_snapshot.duplicate(true)

func _init_terminal_previews() -> void:
	if _planet_preview_viewport != null and is_instance_valid(_planet_preview_viewport):
		return

	_planet_preview_viewport = SubViewport.new()
	_planet_preview_viewport.name = "TerminalPlanetPreviewViewport"
	_planet_preview_viewport.size = Vector2i(768, 768)
	_planet_preview_viewport.transparent_bg = false
	_planet_preview_viewport.disable_3d = false
	_planet_preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_planet_preview_viewport)

	_planet_preview_root = Node3D.new()
	_planet_preview_root.name = "Root"
	_planet_preview_viewport.add_child(_planet_preview_root)

	_planet_preview_globe = MeshInstance3D.new()
	_planet_preview_globe.name = "TerminalGlobe"
	var sphere := SphereMesh.new()
	sphere.radial_segments = 96
	sphere.rings = 48
	sphere.radius = 1.0
	sphere.height = 2.0
	_planet_preview_globe.mesh = sphere
	_planet_preview_root.add_child(_planet_preview_globe)

	var light := DirectionalLight3D.new()
	light.rotation = Vector3(deg_to_rad(-24.0), deg_to_rad(28.0), 0.0)
	light.light_energy = 2.4
	_planet_preview_viewport.add_child(light)

	_planet_preview_environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.02, 0.03, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.62, 0.7, 1.0)
	env.ambient_light_energy = 0.45
	_planet_preview_environment.environment = env
	_planet_preview_viewport.add_child(_planet_preview_environment)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 0.06, _planet_preview_zoom_distance)
	camera.fov = 34.0
	camera.near = 0.05
	camera.far = 20.0
	camera.current = true
	_planet_preview_viewport.add_child(camera)
	_planet_preview_camera = camera

	if terminal_planet_preview:
		terminal_planet_preview.texture = _planet_preview_viewport.get_texture()

func _refresh_contract_previews() -> void:
	if terminal_map_preview == null:
		return

	var contract = _collect_contract_snapshot()
	if contract.is_empty():
		terminal_map_preview.texture = _build_placeholder_preview("NO MAP CONTRACT")
		if terminal_planet_preview:
			terminal_planet_preview.texture = _build_placeholder_preview("NO PLANET CONTRACT")
		return

	if terminal_planet_preview:
		_render_planet_preview()
	terminal_map_preview.texture = _build_map_preview_texture(_terminal_latest_contract, _terminal_snapshot)

func _render_planet_preview() -> void:
	if _planet_preview_globe == null or not is_instance_valid(_planet_preview_globe):
		return
	if terminal_planet_preview and _planet_preview_viewport:
		terminal_planet_preview.texture = _planet_preview_viewport.get_texture()

	var planet: Dictionary = _terminal_latest_contract.get("planet", {})
	if not (planet is Dictionary):
		terminal_planet_preview.texture = _build_placeholder_preview("NO PLANET DATA")
		return

	var planet_key := str(planet.get("key", "terran_dry"))
	var planet_seed := int(planet.get("planet_seed", -1))
	_planet_preview_globe.material_override = _build_terminal_planet_globe_material(planet_key, planet_seed)
	_planet_preview_rotation = Vector2(0.14, -0.36)
	_planet_preview_spin_velocity = Vector2.ZERO
	_planet_preview_zoom_distance = 3.8
	_apply_terminal_planet_zoom()
	_apply_terminal_planet_rotation()

func _on_terminal_planet_preview_gui_input(event: InputEvent) -> void:
	if not _terminal_open or terminal_planet_preview == null:
		return
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.button_index == MOUSE_BUTTON_WHEEL_UP and button_event.pressed:
			_planet_preview_zoom_distance = max(PLANET_PREVIEW_ZOOM_MIN, _planet_preview_zoom_distance - PLANET_PREVIEW_ZOOM_STEP)
			_apply_terminal_planet_zoom()
			terminal_planet_preview.accept_event()
			return
		if button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and button_event.pressed:
			_planet_preview_zoom_distance = min(PLANET_PREVIEW_ZOOM_MAX, _planet_preview_zoom_distance + PLANET_PREVIEW_ZOOM_STEP)
			_apply_terminal_planet_zoom()
			terminal_planet_preview.accept_event()
			return
		if button_event.button_index == MOUSE_BUTTON_LEFT:
			_planet_preview_drag_active = button_event.pressed
			_planet_preview_drag_last_pos = button_event.position
			if button_event.pressed:
				terminal_input.grab_focus()
			else:
				_planet_preview_spin_velocity.x = clamp(_planet_preview_spin_velocity.x, -2.2, 2.2)
				_planet_preview_spin_velocity.y = clamp(_planet_preview_spin_velocity.y, -4.2, 4.2)
			terminal_planet_preview.accept_event()
	elif event is InputEventMouseMotion and _planet_preview_drag_active:
		var motion_event := event as InputEventMouseMotion
		var delta_pos := motion_event.position - _planet_preview_drag_last_pos
		_planet_preview_drag_last_pos = motion_event.position
		_planet_preview_rotation.x = clamp(_planet_preview_rotation.x - delta_pos.y * 0.005, -0.9, 0.9)
		_planet_preview_rotation.y += delta_pos.x * 0.012
		_planet_preview_spin_velocity.x = -delta_pos.y * 0.03
		_planet_preview_spin_velocity.y = delta_pos.x * 0.07
		_apply_terminal_planet_rotation()
		terminal_planet_preview.accept_event()

func _planet_preview_contains_screen_point(point: Vector2) -> bool:
	if terminal_planet_preview == null or not is_instance_valid(terminal_planet_preview):
		return false
	return terminal_planet_preview.get_global_rect().has_point(point)


func _on_terminal_map_preview_gui_input(event: InputEvent) -> void:
	if not _terminal_open or terminal_map_preview == null:
		return
	if _terminal_map_render_bounds.is_empty():
		return
	if event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		var world_pos := _terminal_map_local_to_world(motion_event.position)
		_terminal_map_hover_world_pos = world_pos
		_update_terminal_map_placement_preview(world_pos)
		terminal_map_preview.accept_event()
		return
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		var world_pos := _terminal_map_local_to_world(button_event.position)
		_terminal_map_hover_world_pos = world_pos
		if button_event.button_index == MOUSE_BUTTON_LEFT and button_event.pressed:
			if _apply_terminal_map_placement(world_pos):
				_refresh_snapshot()
			terminal_input.grab_focus()
			terminal_map_preview.accept_event()
			return
		if button_event.button_index == MOUSE_BUTTON_RIGHT and button_event.pressed:
			if _cancel_active_placement_mode():
				_append_terminal_line("PLACEMENT CANCELLED", "info")
				terminal_input.grab_focus()
				terminal_map_preview.accept_event()
			return


func _update_terminal_map_placement_preview(world_pos: Vector2) -> void:
	var handled := false
	var wall_placer = get_node_or_null("/root/GameRoot/World/WallPlacer")
	if wall_placer and wall_placer.has_method("get_placement_active") and wall_placer.get_placement_active():
		wall_placer.call("set_preview_world_position", world_pos)
		handled = true
	var turret_placement = get_node_or_null("/root/GameRoot/World/TurretPlacement")
	if turret_placement and turret_placement.has_method("is_placing") and turret_placement.is_placing():
		turret_placement.call("set_preview_world_position", world_pos)
		handled = true
	if handled:
		_refresh_contract_previews()


func _apply_terminal_map_placement(world_pos: Vector2) -> bool:
	var wall_placer = get_node_or_null("/root/GameRoot/World/WallPlacer")
	if wall_placer and wall_placer.has_method("get_placement_active") and wall_placer.get_placement_active():
		var placed := bool(wall_placer.call("place_blueprint_at", world_pos))
		if placed:
			_append_terminal_line("WALL BLUEPRINT PLACED", "success")
		return placed
	var turret_placement = get_node_or_null("/root/GameRoot/World/TurretPlacement")
	if turret_placement and turret_placement.has_method("is_placing") and turret_placement.is_placing():
		var placed_turret := bool(turret_placement.call("attempt_place_turret_at", world_pos))
		if placed_turret:
			_append_terminal_line("TURRET DEPLOYED", "success")
		else:
			_append_terminal_line("INVALID TURRET PLACEMENT", "warning")
		return placed_turret
	return false


func _terminal_map_local_to_world(local_pos: Vector2) -> Vector2:
	if _terminal_map_render_bounds.is_empty():
		return Vector2.ZERO
	var image_size: Vector2 = Vector2(
		float(_terminal_map_render_bounds.get("image_width", TERMINAL_MAP_PREVIEW_SIZE)),
		float(_terminal_map_render_bounds.get("image_height", TERMINAL_MAP_PREVIEW_SIZE))
	)
	var control_size: Vector2 = terminal_map_preview.size
	if control_size.x <= 0.001 or control_size.y <= 0.001:
		return Vector2.ZERO
	var draw_scale: float = min(control_size.x / image_size.x, control_size.y / image_size.y)
	var used_size: Vector2 = image_size * draw_scale
	var pad: Vector2 = (control_size - used_size) * 0.5
	var normalized: Vector2 = (local_pos - pad) / max(draw_scale, 0.001)
	normalized.x = clampf(normalized.x, 0.0, image_size.x - 1.0)
	normalized.y = clampf(normalized.y, 0.0, image_size.y - 1.0)
	var min_x := float(_terminal_map_render_bounds.get("min_x", 0.0))
	var min_y := float(_terminal_map_render_bounds.get("min_y", 0.0))
	var scale := float(_terminal_map_render_bounds.get("scale", 1.0))
	var draw_offset: Vector2 = _terminal_map_render_bounds.get("draw_offset", Vector2.ZERO)
	return Vector2(
		((normalized.x - draw_offset.x) / max(scale, 0.001)) + min_x,
		((normalized.y - draw_offset.y) / max(scale, 0.001)) + min_y
	)

func _build_terminal_planet_globe_material(planet_key: String, planet_seed: int) -> Material:
	var image := _generate_terminal_planet_globe_image(planet_key, planet_seed)
	var texture := ImageTexture.create_from_image(image)
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.roughness = 1.0
	material.metallic = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material

func _generate_terminal_planet_globe_image(planet_key: String, planet_seed: int) -> Image:
	var width := 1024
	var height := 512
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var palette := _get_terminal_planet_palette(planet_key)

	var base_noise := FastNoiseLite.new()
	base_noise.seed = planet_seed
	base_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	base_noise.frequency = 2.4
	base_noise.fractal_octaves = 5
	base_noise.fractal_lacunarity = 2.0
	base_noise.fractal_gain = 0.52

	var detail_noise := FastNoiseLite.new()
	detail_noise.seed = planet_seed + 911
	detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	detail_noise.frequency = 6.5
	detail_noise.fractal_octaves = 3
	detail_noise.fractal_gain = 0.45

	for y in range(height):
		var v := float(y) / float(height - 1)
		var latitude := (v - 0.5) * PI
		var lat_norm := cos(latitude)
		for x in range(width):
			var u := float(x) / float(width - 1)
			var nx := cos(u * TAU) * lat_norm
			var ny := sin(u * TAU) * lat_norm
			var nz := sin(latitude)
			var terrain := base_noise.get_noise_3d(nx, ny, nz)
			var detail := detail_noise.get_noise_3d(nx, ny, nz) * 0.35
			var value := terrain + detail
			image.set_pixel(x, y, _sample_terminal_planet_color(planet_key, value, latitude, palette))

	return image

func _get_terminal_planet_palette(planet_key: String) -> Dictionary:
	match planet_key:
		"terran_wet":
			return {
				"water": Color("275d8f"),
				"shore": Color("7bb08a"),
				"land": Color("4d8e4f"),
				"highland": Color("2f5e34"),
				"ice": Color("d7eef7"),
			}
		"islands":
			return {
				"water": Color("1f6a9a"),
				"shore": Color("d0c184"),
				"land": Color("5c9f63"),
				"highland": Color("33644a"),
				"ice": Color("d7eef7"),
			}
		"ice_world":
			return {
				"water": Color("4d7ea8"),
				"shore": Color("bfd6e5"),
				"land": Color("ddeff7"),
				"highland": Color("a4becd"),
				"ice": Color("f4fbff"),
			}
		"lava_world":
			return {
				"water": Color("2c1310"),
				"shore": Color("6b271d"),
				"land": Color("b33f1f"),
				"highland": Color("ff922b"),
				"ice": Color("ffd36e"),
			}
		"gas_giant":
			return {
				"water": Color("8c6942"),
				"shore": Color("c4935d"),
				"land": Color("e7c287"),
				"highland": Color("7f4f3b"),
				"ice": Color("f7ebcb"),
			}
		_:
			return {
				"water": Color("6a6d42"),
				"shore": Color("a99a69"),
				"land": Color("8c7d43"),
				"highland": Color("5e4d2d"),
				"ice": Color("d8ddd0"),
			}

func _sample_terminal_planet_color(planet_key: String, value: float, latitude: float, palette: Dictionary) -> Color:
	if planet_key == "gas_giant":
		var bands := sin(latitude * 14.0 + value * 2.0)
		if bands > 0.45:
			return palette["ice"]
		if bands > 0.1:
			return palette["land"]
		if bands > -0.25:
			return palette["shore"]
		return palette["highland"]

	if value < -0.18:
		return palette["water"]
	if value < -0.04:
		return palette["shore"]
	if value < 0.35:
		return palette["land"]
	if abs(latitude) > 1.18:
		return palette["ice"]
	return palette["highland"]

func _build_map_preview_texture(contract: Dictionary, snapshot: Dictionary = {}) -> Texture2D:
	var map_data = contract.get("map", {})
	if not (map_data is Dictionary):
		_terminal_map_render_bounds.clear()
		return _build_placeholder_preview("NO MAP DATA")
	var level_data = map_data.get("level_data", {})
	if not (level_data is Dictionary):
		_terminal_map_render_bounds.clear()
		return _build_placeholder_preview("NO LEVEL DATA")

	var image := Image.create(TERMINAL_MAP_PREVIEW_SIZE, TERMINAL_MAP_PREVIEW_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.04, 0.07, 0.06, 1.0))

	var points: Array[Vector2] = []
	var room_points: Array = level_data.get("rooms", [])
	var corridor_points: Array = level_data.get("corridor_spawns", [])
	var floor_points: Array = level_data.get("random_floor_tiles", [])
	var player_spawn = level_data.get("player_spawn", Vector2i.ZERO)

	for p in room_points:
		if p is Vector2i:
			points.append(Vector2(p))
	for p in corridor_points:
		if p is Vector2i:
			points.append(Vector2(p))
	for p in floor_points:
		if p is Vector2i:
			points.append(Vector2(p))
	if player_spawn is Vector2i:
		points.append(Vector2(player_spawn))

	if points.is_empty():
		_terminal_map_render_bounds.clear()
		return _build_placeholder_preview("EMPTY MAP")

	var min_x: float = points[0].x
	var min_y: float = points[0].y
	var max_x: float = points[0].x
	var max_y: float = points[0].y
	for p in points:
		min_x = min(min_x, p.x)
		min_y = min(min_y, p.y)
		max_x = max(max_x, p.x)
		max_y = max(max_y, p.y)

	var pad: float = 8.0
	var width: float = max(1.0, max_x - min_x)
	var height: float = max(1.0, max_y - min_y)
	var scale: float = min((float(TERMINAL_MAP_PREVIEW_SIZE) - pad * 2.0) / width, (float(TERMINAL_MAP_PREVIEW_SIZE) - pad * 2.0) / height)
	var draw_offset := Vector2(pad, pad)
	_terminal_map_render_bounds = {
		"min_x": min_x,
		"min_y": min_y,
		"max_x": max_x,
		"max_y": max_y,
		"scale": scale,
		"draw_offset": draw_offset,
		"image_width": image.get_width(),
		"image_height": image.get_height(),
	}

	var draw_point = func(v: Vector2i, color: Color, radius: int) -> void:
		var mapped = Vector2((v.x - min_x) * scale, (v.y - min_y) * scale) + draw_offset
		var cx := int(round(mapped.x))
		var cy := int(round(mapped.y))
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var px := cx + dx
				var py := cy + dy
				if px < 0 or py < 0 or px >= image.get_width() or py >= image.get_height():
					continue
				image.set_pixel(px, py, color)

	_draw_preview_path_lines(image, corridor_points, min_x, min_y, scale, draw_offset)
	for p in floor_points:
		if p is Vector2i:
			draw_point.call(p, Color(0.17, 0.21, 0.20, 1.0), 1)
	for p in room_points:
		if p is Vector2i:
			draw_point.call(p, Color(0.16, 0.66, 0.60, 1.0), 2)
	for p in corridor_points:
		if p is Vector2i:
			draw_point.call(p, Color(0.52, 0.78, 0.94, 0.95), 1)
	if player_spawn is Vector2i:
		draw_point.call(player_spawn, Color(0.9, 0.95, 0.25, 1.0), 2)

	var sectors = snapshot.get("sectors", [])
	if sectors is Array:
		for sector in sectors:
			if not (sector is Dictionary):
				continue
			var hp_pct := int(sector.get("hp_pct", 100))
			if hp_pct >= 100:
				continue
			var sector_pos = sector.get("world_pos", null)
			if sector_pos is Vector2:
				var tint := Color(0.85, 0.24, 0.24, 0.65 if hp_pct < 70 else 0.32)
				_draw_preview_world_marker(image, Vector2(sector_pos), tint, 5, points, min_x, min_y, scale, draw_offset)
			if _terminal_highlight_sector == str(sector.get("name", "")) and sector_pos is Vector2:
				_draw_preview_world_ring(image, Vector2(sector_pos), Color(0.95, 0.96, 0.38, 0.95), 7, points, min_x, min_y, scale, draw_offset)

	var tactical_entities = snapshot.get("tactical_entities", {})
	if tactical_entities is Dictionary:
		for turret in tactical_entities.get("turrets", []):
			if turret is Dictionary and turret.get("pos", null) is Vector2:
				var turret_color := Color(0.44, 0.88, 0.72, 1.0)
				_draw_preview_world_marker(image, turret["pos"], turret_color, 3, points, min_x, min_y, scale, draw_offset)
			for enemy in tactical_entities.get("enemies", []):
				if enemy is Dictionary and enemy.get("pos", null) is Vector2:
					var enemy_color := Color(0.96, 0.38, 0.34, 1.0)
					_draw_preview_world_marker(image, enemy["pos"], enemy_color, 2, points, min_x, min_y, scale, draw_offset)
			for operator_entry in tactical_entities.get("operator", []):
				if operator_entry is Dictionary and operator_entry.get("pos", null) is Vector2:
					_draw_preview_world_marker(image, operator_entry["pos"], Color(0.98, 0.98, 0.46, 1.0), 3, points, min_x, min_y, scale, draw_offset)

	var wall_placer = get_node_or_null("/root/GameRoot/World/WallPlacer")
	if wall_placer and wall_placer.has_method("get_blueprints"):
		for blueprint in wall_placer.get_blueprints():
			if blueprint == null or not is_instance_valid(blueprint):
				continue
			_draw_preview_world_ring(image, blueprint.global_position, Color(0.86, 0.78, 0.34, 0.95), 5, points, min_x, min_y, scale, draw_offset)
	if wall_placer and wall_placer.has_method("get_placement_active") and wall_placer.get_placement_active() and wall_placer.has_method("get_preview_world_position"):
		var wall_preview_pos: Vector2 = wall_placer.get_preview_world_position()
		_draw_preview_world_ring(image, wall_preview_pos, Color(0.95, 0.96, 0.52, 0.98), 7, points, min_x, min_y, scale, draw_offset)

	var turret_placement = get_node_or_null("/root/GameRoot/World/TurretPlacement")
	if turret_placement and turret_placement.has_method("is_placing") and turret_placement.is_placing() and turret_placement.has_method("get_preview_world_position"):
		var turret_preview_pos: Vector2 = turret_placement.get_preview_world_position()
		var preview_color := Color(0.42, 0.94, 0.70, 0.95) if bool(turret_placement.get_placement_valid()) else Color(0.95, 0.34, 0.34, 0.95)
		_draw_preview_world_marker(image, turret_preview_pos, preview_color, 4, points, min_x, min_y, scale, draw_offset)

	if bool(_terminal_overlay_flags.get("path", false)):
		_draw_preview_path_lines(image, corridor_points, min_x, min_y, scale, draw_offset)
	if bool(_terminal_overlay_flags.get("threat", false)):
		_draw_preview_threat_heat(image, tactical_entities.get("enemies", []), points, min_x, min_y, scale, draw_offset)
	if bool(_terminal_overlay_flags.get("repair", false)):
		for sector in sectors:
			if sector is Dictionary and int(sector.get("hp_pct", 100)) < 100 and sector.get("world_pos", null) is Vector2:
				_draw_preview_world_ring(image, sector["world_pos"], Color(0.79, 0.86, 1.0, 0.9), 4, points, min_x, min_y, scale, draw_offset)

	return ImageTexture.create_from_image(image)

func _draw_preview_world_marker(image: Image, world_pos: Vector2, color: Color, radius: int, fallback_points: Array[Vector2], min_x: float, min_y: float, scale: float, draw_offset: Vector2) -> void:
	var mapped := Vector2((world_pos.x - min_x) * scale, (world_pos.y - min_y) * scale) + draw_offset
	var cx := int(round(mapped.x))
	var cy := int(round(mapped.y))
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if dx * dx + dy * dy > radius * radius:
				continue
			var px := cx + dx
			var py := cy + dy
			if px < 0 or py < 0 or px >= image.get_width() or py >= image.get_height():
				continue
			image.set_pixel(px, py, color)

func _draw_preview_world_ring(image: Image, world_pos: Vector2, color: Color, radius: int, fallback_points: Array[Vector2], min_x: float, min_y: float, scale: float, draw_offset: Vector2) -> void:
	var mapped := Vector2((world_pos.x - min_x) * scale, (world_pos.y - min_y) * scale) + draw_offset
	var cx := int(round(mapped.x))
	var cy := int(round(mapped.y))
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var dist_sq := dx * dx + dy * dy
			if dist_sq < (radius - 1) * (radius - 1) or dist_sq > radius * radius:
				continue
			var px := cx + dx
			var py := cy + dy
			if px < 0 or py < 0 or px >= image.get_width() or py >= image.get_height():
				continue
			image.set_pixel(px, py, color)

func _draw_preview_path_lines(image: Image, corridor_points: Array, min_x: float, min_y: float, scale: float, draw_offset: Vector2) -> void:
	for i in range(max(0, corridor_points.size() - 1)):
		var a = corridor_points[i]
		var b = corridor_points[i + 1]
		if not (a is Vector2i and b is Vector2i):
			continue
		var from := Vector2((a.x - min_x) * scale, (a.y - min_y) * scale) + draw_offset
		var to := Vector2((b.x - min_x) * scale, (b.y - min_y) * scale) + draw_offset
		var steps := int(max(abs(to.x - from.x), abs(to.y - from.y)))
		for step in range(steps + 1):
			var t: float = float(step) / max(1.0, float(steps))
			var p := from.lerp(to, t)
			var px := int(round(p.x))
			var py := int(round(p.y))
			if px < 0 or py < 0 or px >= image.get_width() or py >= image.get_height():
				continue
			image.set_pixel(px, py, Color(0.48, 0.74, 0.92, 0.72))

func _draw_preview_threat_heat(image: Image, enemy_entries: Array, fallback_points: Array[Vector2], min_x: float, min_y: float, scale: float, draw_offset: Vector2) -> void:
	for enemy in enemy_entries:
		if not (enemy is Dictionary) or not (enemy.get("pos", null) is Vector2):
			continue
		var mapped := Vector2((enemy["pos"].x - min_x) * scale, (enemy["pos"].y - min_y) * scale) + draw_offset
		var cx := int(round(mapped.x))
		var cy := int(round(mapped.y))
		for dx in range(-6, 7):
			for dy in range(-6, 7):
				var dist_sq := float(dx * dx + dy * dy)
				if dist_sq > 36.0:
					continue
				var px := cx + dx
				var py := cy + dy
				if px < 0 or py < 0 or px >= image.get_width() or py >= image.get_height():
					continue
				var existing := image.get_pixel(px, py)
				var alpha: float = max(0.0, 0.28 - dist_sq * 0.006)
				image.set_pixel(px, py, existing.lerp(Color(0.82, 0.16, 0.16, 1.0), alpha))

func _build_placeholder_preview(label: String) -> Texture2D:
	var image := Image.create(TERMINAL_MAP_PREVIEW_SIZE, TERMINAL_MAP_PREVIEW_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.02, 0.03, 0.03, 1.0))
	for x in range(0, TERMINAL_MAP_PREVIEW_SIZE):
		image.set_pixel(x, 0, Color(0.15, 0.26, 0.2, 1.0))
		image.set_pixel(x, TERMINAL_MAP_PREVIEW_SIZE - 1, Color(0.15, 0.26, 0.2, 1.0))
	for y in range(0, TERMINAL_MAP_PREVIEW_SIZE):
		image.set_pixel(0, y, Color(0.15, 0.26, 0.2, 1.0))
		image.set_pixel(TERMINAL_MAP_PREVIEW_SIZE - 1, y, Color(0.15, 0.26, 0.2, 1.0))

	var hash: int = int(abs(label.hash()))
	for i in range(24):
		var px: int = 8 + ((hash + i * 29) % (TERMINAL_MAP_PREVIEW_SIZE - 16))
		var py: int = 8 + ((hash + i * 43) % (TERMINAL_MAP_PREVIEW_SIZE - 16))
		image.set_pixel(px, py, Color(0.25, 0.45, 0.35, 1.0))
	return ImageTexture.create_from_image(image)

func _ensure_terminal_contract_binding() -> void:
	if _terminal_contract_node != null and is_instance_valid(_terminal_contract_node):
		return

	var contract_node = get_node_or_null(terminal_contract_node_path)
	if contract_node == null:
		contract_node = get_node_or_null("/root/GameRoot/World/ContractMap")
	if contract_node == null:
		return
	if not contract_node.has_signal("contract_generated"):
		return

	_terminal_contract_node = contract_node
	var callback = Callable(self, "_on_terminal_contract_generated")
	if not contract_node.is_connected("contract_generated", callback):
		contract_node.connect("contract_generated", callback)
	if contract_node.has_method("get_latest_contract"):
		var latest = contract_node.call("get_latest_contract")
		if latest is Dictionary and not latest.is_empty():
			_on_terminal_contract_generated(latest)


func _bind_wall_placer_ui() -> void:
	var wall_placer = get_node_or_null("/root/GameRoot/World/WallPlacer")
	if wall_placer == null:
		return
	if not wall_placer.has_signal("placement_mode_changed"):
		return
	var callback := Callable(self, "_on_wall_placement_mode_changed")
	if not wall_placer.is_connected("placement_mode_changed", callback):
		wall_placer.connect("placement_mode_changed", callback)


func _bind_turret_placement_ui() -> void:
	var turret_placement = get_node_or_null("/root/GameRoot/World/TurretPlacement")
	if turret_placement == null:
		return
	if not turret_placement.has_signal("placement_mode_changed"):
		return
	var callback := Callable(self, "_on_turret_placement_mode_changed")
	if not turret_placement.is_connected("placement_mode_changed", callback):
		turret_placement.connect("placement_mode_changed", callback)


func _on_wall_placement_mode_changed(active: bool) -> void:
	if active:
		enter_placement_mode_ui()
	else:
		exit_placement_mode_ui()


func _on_turret_placement_mode_changed(active: bool) -> void:
	if active:
		enter_placement_mode_ui()
	else:
		exit_placement_mode_ui()


func _cancel_active_placement_mode() -> bool:
	var handled := false
	var wall_placer = get_node_or_null("/root/GameRoot/World/WallPlacer")
	if wall_placer and wall_placer.has_method("get_placement_active") and wall_placer.get_placement_active():
		if wall_placer.has_method("clear_preview_world_override"):
			wall_placer.clear_preview_world_override()
		wall_placer.exit_placement_mode()
		handled = true
	var turret_placement = get_node_or_null("/root/GameRoot/World/TurretPlacement")
	if turret_placement and turret_placement.has_method("is_placing") and turret_placement.is_placing():
		if turret_placement.has_method("clear_preview_world_override"):
			turret_placement.clear_preview_world_override()
		turret_placement.exit_placement_mode()
		handled = true
	return handled

func _on_terminal_contract_generated(contract: Dictionary) -> void:
	_terminal_latest_contract = contract
	var summarized: Dictionary = {}
	summarized["contract_seed"] = int(contract.get("contract_seed", -1))

	var planet = contract.get("planet", {})
	if planet is Dictionary:
		summarized["planet_key"] = str(planet.get("key", "unknown"))
		summarized["planet_seed"] = int(planet.get("planet_seed", -1))

	var map = contract.get("map", {})
	if map is Dictionary:
		summarized["map_seed"] = int(map.get("map_seed", -1))
		var level_data = map.get("level_data", {})
		if level_data is Dictionary:
			summarized["room_count"] = int((level_data.get("rooms", []) as Array).size())
			summarized["corridor_spawn_count"] = int((level_data.get("corridor_spawns", []) as Array).size())
			summarized["random_floor_tiles_count"] = int((level_data.get("random_floor_tiles", []) as Array).size())

	_terminal_contract_snapshot = summarized
	_refresh_contract_previews()

func _display_sector_name(raw_name: String) -> String:
	var key = raw_name.strip_edges().to_upper()
	if SECTOR_DISPLAY_NAMES.has(key):
		return str(SECTOR_DISPLAY_NAMES[key])
	return raw_name.replace("_", " ").capitalize()

func _request_json(requester: HTTPRequest, path: String, method: int, payload: Variant = null) -> Dictionary:
	if requester == null:
		return {"ok": false, "error": "REQUEST NODE MISSING"}
	var base = _terminal_service_url.strip_edges()
	if base.is_empty():
		base = DEFAULT_TERMINAL_SERVICE_URL
	if base.ends_with("/"):
		base = base.substr(0, base.length() - 1)
	var url = "%s%s" % [base, path]
	var headers = PackedStringArray(["Content-Type: application/json"])
	var body = ""
	if method == HTTPClient.METHOD_POST:
		body = JSON.stringify(payload if payload != null else {})
	var err = requester.request(url, headers, method, body)
	if err != OK:
		return {"ok": false, "error": "REQUEST START FAILED", "code": err}
	var result = await requester.request_completed
	var response_code = int(result[1])
	var bytes: PackedByteArray = result[3]
	var text = bytes.get_string_from_utf8()
	var parsed = JSON.parse_string(text)
	if response_code < 200 or response_code >= 300:
		return {"ok": false, "status": response_code, "data": parsed if parsed is Dictionary else {}}
	if parsed is Dictionary:
		return {"ok": true, "status": response_code, "data": parsed}
	return {"ok": true, "status": response_code, "data": {}}
