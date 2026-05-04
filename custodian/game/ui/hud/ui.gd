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
@onready var terminal_nav_title = get_node_or_null("TerminalPanel/Body/NavRail/NavTitle")
@onready var terminal_action_title = get_node_or_null("TerminalPanel/Body/NavRail/ActionTitle")
@onready var terminal_activity_scroll = get_node_or_null("TerminalPanel/Body/CommandColumn/ActivityScroll")
@onready var terminal_output = get_node_or_null("TerminalPanel/Body/CommandColumn/ActivityScroll/TerminalOutput")
@onready var terminal_command_title = get_node_or_null("TerminalPanel/Body/CommandColumn/CommandTitle")
@onready var terminal_input = get_node_or_null("TerminalPanel/Body/CommandColumn/InputRow/TerminalInput")
@onready var terminal_status_label = get_node_or_null("TerminalPanel/Body/CommandColumn/Status")
@onready var terminal_target_label = get_node_or_null("TerminalPanel/Header/Target")
@onready var terminal_hint_label = get_node_or_null("TerminalPanel/Hint")
@onready var terminal_map_column = get_node_or_null("TerminalPanel/Body/MapColumn")
@onready var terminal_map_title_label = get_node_or_null("TerminalPanel/Body/MapColumn/MapTitle")
@onready var terminal_page_summary_label = get_node_or_null("TerminalPanel/Body/MapColumn/PageSummary")
@onready var terminal_planet_title_label = get_node_or_null("TerminalPanel/Body/MapColumn/PlanetPreviewTitle")
@onready var terminal_map_preview_title_label = get_node_or_null("TerminalPanel/Body/MapColumn/MapPreviewTitle")
@onready var terminal_map_label = get_node_or_null("TerminalPanel/Body/MapColumn/MapOutput")
@onready var terminal_planet_preview = get_node_or_null("TerminalPanel/Body/MapColumn/PlanetPreview")
@onready var terminal_background = get_node_or_null("TerminalBackground")
@onready var terminal_map_preview = get_node_or_null("TerminalPanel/Body/MapColumn/MapPreview")
@onready var terminal_header_panel = get_node_or_null("TerminalPanel/Header")
@onready var terminal_widget_stack = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack")
@onready var terminal_overview_widgets = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets")
@onready var terminal_sectors_widgets = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/SectorsWidgets")
@onready var terminal_power_widgets = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets")
@onready var terminal_defense_widgets = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets")
@onready var terminal_sensors_widgets = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets")
@onready var terminal_incidents_widgets = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/IncidentsWidgets")
@onready var terminal_archive_widgets = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets")
@onready var terminal_recon_widgets = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/ReconWidgets")
@onready var terminal_contracts_widgets = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/ContractsWidgets")
@onready var terminal_history_widgets = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/HistoryWidgets")
@onready var terminal_status_widgets = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets")
@onready var terminal_settings_widgets = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets")
@onready var terminal_overview_operational_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewTopRow/OverviewOperationalPanel/Margin/Content/Body")
@onready var terminal_overview_power_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewTopRow/OverviewPowerPanel/Margin/Content/Body")
@onready var terminal_overview_assault_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewTopRow/OverviewAssaultPanel/Margin/Content/Body")
@onready var terminal_overview_priority_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewBottomRow/OverviewPriorityPanel/Margin/Content/Body")
@onready var terminal_overview_contract_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewBottomRow/OverviewContractPanel/Margin/Content/Body")
@onready var terminal_sector_list_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/SectorsWidgets/SectorListPanel/Margin/Content/Body")
@onready var terminal_sector_detail_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/SectorsWidgets/SectorDetailPanel/Margin/Content/Body")
@onready var terminal_power_global_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets/PowerTopRow/PowerGlobalPanel/Margin/Content/Body")
@onready var terminal_power_preset_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets/PowerTopRow/PowerPresetPanel/Margin/Content/Body")
@onready var terminal_power_allocation_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/PowerWidgets/PowerAllocationPanel/Margin/Content/Body")
@onready var terminal_defense_readiness_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets/DefenseTopRow/DefenseReadinessPanel/Margin/Content/Body")
@onready var terminal_defense_modes_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets/DefenseTopRow/DefenseModesPanel/Margin/Content/Body")
@onready var terminal_defense_coverage_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/DefenseWidgets/DefenseCoveragePanel/Margin/Content/Body")
@onready var terminal_sensors_fidelity_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets/SensorsTopRow/SensorsFidelityPanel/Margin/Content/Body")
@onready var terminal_sensors_prediction_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets/SensorsTopRow/SensorsPredictionPanel/Margin/Content/Body")
@onready var terminal_sensors_activity_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/SensorsWidgets/SensorsActivityPanel/Margin/Content/Body")
@onready var terminal_incidents_filter_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/IncidentsWidgets/IncidentsFilterPanel/Margin/Content/Body")
@onready var terminal_incidents_table_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/IncidentsWidgets/IncidentsTablePanel/Margin/Content/Body")
@onready var terminal_archive_integrity_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets/ArchiveTopRow/ArchiveIntegrityPanel/Margin/Content/Body")
@onready var terminal_archive_categories_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets/ArchiveTopRow/ArchiveCategoriesPanel/Margin/Content/Body")
@onready var terminal_archive_detail_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/ArchiveWidgets/ArchiveDetailPanel/Margin/Content/Body")
@onready var terminal_recon_hypothesis_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/ReconWidgets/ReconHypothesisPanel/Margin/Content/Body")
@onready var terminal_recon_targets_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/ReconWidgets/ReconTargetsPanel/Margin/Content/Body")
@onready var terminal_contracts_slot_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/ContractsWidgets/ContractsTopRow/ContractsSlotPanel/Margin/Content/Body")
@onready var terminal_contracts_coupling_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/ContractsWidgets/ContractsTopRow/ContractsCouplingPanel/Margin/Content/Body")
@onready var terminal_history_log_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/HistoryWidgets/HistoryLogPanel/Margin/Content/Body")
@onready var terminal_status_raw_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets/StatusTopRow/StatusRawPanel/Margin/Content/Body")
@onready var terminal_status_parsed_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets/StatusTopRow/StatusParsedPanel/Margin/Content/Body")
@onready var terminal_status_fidelity_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/StatusWidgets/StatusFidelityPanel/Margin/Content/Body")
@onready var terminal_settings_display_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets/SettingsTopRow/SettingsDisplayPanel/Margin/Content/Body")
@onready var terminal_settings_input_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets/SettingsTopRow/SettingsInputPanel/Margin/Content/Body")
@onready var terminal_settings_map_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/SettingsWidgets/SettingsMapPanel/Margin/Content/Body")
@onready var terminal_overview_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtons/OverviewButton")
@onready var terminal_status_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtons/StatusButton")
@onready var terminal_sectors_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtons/SectorsButton")
@onready var terminal_power_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtons/PowerButton")
@onready var terminal_defense_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtons/DefenseButton")
@onready var terminal_sensors_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtons/SensorsButton")
@onready var terminal_incidents_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtons/IncidentsButton")
@onready var terminal_archive_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtons/ArchiveButton")
@onready var terminal_recon_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtons/ReconButton")
@onready var terminal_contracts_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtons/ContractsButton")
@onready var terminal_history_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtons/HistoryButton")
@onready var terminal_settings_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtons/SettingsButton")
@onready var terminal_wait_button = get_node_or_null("TerminalPanel/Body/NavRail/ActionButtons/WaitButton")
@onready var terminal_wait_10x_button = get_node_or_null("TerminalPanel/Body/NavRail/ActionButtons/Wait10xButton")
@onready var terminal_focus_button = get_node_or_null("TerminalPanel/Body/NavRail/ActionButtons/FocusButton")
@onready var terminal_harden_button = get_node_or_null("TerminalPanel/Body/NavRail/ActionButtons/HardenButton")
@onready var terminal_reset_button = get_node_or_null("TerminalPanel/Body/NavRail/ActionButtons/ResetButton")
@onready var terminal_reboot_button = get_node_or_null("TerminalPanel/Body/NavRail/ActionButtons/RebootButton")
@onready var terminal_help_button = get_node_or_null("TerminalPanel/Body/NavRail/ActionButtons/HelpButton")

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
var _terminal_current_page := "OVERVIEW"
var _terminal_page_buttons: Dictionary = {}
var _terminal_nav_buttons: Array = []
var _terminal_action_buttons: Array = []
var _terminal_main_scroll: ScrollContainer = null
var _terminal_fabrication_queue: Array[String] = []
var _terminal_policy_preset := "BALANCED"
var _terminal_activity_autofollow := true

const PLANET_PREVIEW_ZOOM_MIN := 2.7
const PLANET_PREVIEW_ZOOM_MAX := 6.2
const PLANET_PREVIEW_ZOOM_STEP := 0.3
const TERMINAL_LOG_LIMIT := 1000
const TERMINAL_COMMAND_QUEUE_INTERVAL := 0.12
const TERMINAL_MAP_PREVIEW_SIZE := 256
const CROSSHAIR_WORLD_DISTANCE := 110.0
const CROSSHAIR_SCREEN_MARGIN := 22.0
const TERMINAL_ACTIVITY_SCROLL_FOLLOW_MARGIN := 24.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_set_main_hud_hidden(false)
	_create_debug_panel()
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
	_terminal_page_buttons = {
		"OVERVIEW": terminal_overview_button,
		"STATUS": terminal_status_button,
		"SECTORS": terminal_sectors_button,
		"POWER": terminal_power_button,
		"DEFENSE": terminal_defense_button,
		"SENSORS": terminal_sensors_button,
		"INCIDENTS": terminal_incidents_button,
		"ARCHIVE": terminal_archive_button,
		"RECON": terminal_recon_button,
		"CONTRACTS": terminal_contracts_button,
		"HISTORY": terminal_history_button,
		"SETTINGS": terminal_settings_button,
	}
	_terminal_nav_buttons = [
		terminal_overview_button,
		terminal_status_button,
		terminal_sectors_button,
		terminal_power_button,
		terminal_defense_button,
		terminal_sensors_button,
		terminal_incidents_button,
		terminal_archive_button,
		terminal_recon_button,
		terminal_contracts_button,
		terminal_history_button,
		terminal_settings_button,
	]
	_terminal_action_buttons = [
		terminal_wait_button,
		terminal_wait_10x_button,
		terminal_focus_button,
		terminal_harden_button,
		terminal_reset_button,
		terminal_reboot_button,
		terminal_help_button,
	]
	for page_name in _terminal_page_buttons.keys():
		var button: BaseButton = _terminal_page_buttons[page_name]
		if button != null and not button.pressed.is_connected(_on_terminal_page_button_pressed.bind(page_name)):
			button.pressed.connect(_on_terminal_page_button_pressed.bind(page_name))
	if terminal_wait_button and not terminal_wait_button.pressed.is_connected(_on_terminal_action_button_pressed.bind("WAIT")):
		terminal_wait_button.pressed.connect(_on_terminal_action_button_pressed.bind("WAIT"))
	if terminal_wait_10x_button and not terminal_wait_10x_button.pressed.is_connected(_on_terminal_action_button_pressed.bind("WAIT 10X")):
		terminal_wait_10x_button.pressed.connect(_on_terminal_action_button_pressed.bind("WAIT 10X"))
	if terminal_focus_button and not terminal_focus_button.pressed.is_connected(_on_terminal_action_button_pressed.bind("FOCUS POWER")):
		terminal_focus_button.pressed.connect(_on_terminal_action_button_pressed.bind("FOCUS POWER"))
	if terminal_harden_button and not terminal_harden_button.pressed.is_connected(_on_terminal_action_button_pressed.bind("HARDEN COMMAND")):
		terminal_harden_button.pressed.connect(_on_terminal_action_button_pressed.bind("HARDEN COMMAND"))
	if terminal_reset_button and not terminal_reset_button.pressed.is_connected(_on_terminal_action_button_pressed.bind("RESET")):
		terminal_reset_button.pressed.connect(_on_terminal_action_button_pressed.bind("RESET"))
	if terminal_reboot_button and not terminal_reboot_button.pressed.is_connected(_on_terminal_action_button_pressed.bind("REBOOT")):
		terminal_reboot_button.pressed.connect(_on_terminal_action_button_pressed.bind("REBOOT"))
	if terminal_help_button and not terminal_help_button.pressed.is_connected(_on_terminal_action_button_pressed.bind("HELP")):
		terminal_help_button.pressed.connect(_on_terminal_action_button_pressed.bind("HELP"))
	_setup_terminal_main_scroll()
	_apply_terminal_theme()
	_init_terminal_previews()
	_ensure_terminal_contract_binding()
	_bind_wall_placer_ui()
	_bind_turret_placement_ui()
	_refresh_terminal_page_buttons()

func _create_debug_panel() -> void:
	# Create debug panel for inventory and cognitive state
	var debug_panel := VBoxContainer.new()
	debug_panel.name = "DebugPanel"
	debug_panel.visible = false  # Hidden by default, toggle with debug key
	debug_panel.position = Vector2(10, 10)
	debug_panel.add_theme_stylebox_override("panel", _create_debug_panel_style())
	
	# Inventory section
	var inv_label := Label.new()
	inv_label.name = "InventoryLabel"
	inv_label.text = "INVENTORY"
	inv_label.add_theme_font_size_override("font_size", 14)
	debug_panel.add_child(inv_label)
	
	var inv_display := Label.new()
	inv_display.name = "InventoryDisplay"
	inv_display.text = "Loading..."
	inv_display.autowrap_mode = 2
	debug_panel.add_child(inv_display)
	
	# Cognitive state section
	var cog_label := Label.new()
	cog_label.name = "CognitiveLabel"
	cog_label.text = "COGNITIVE STATE"
	cog_label.add_theme_font_size_override("font_size", 14)
	cog_label.add_theme_constant_override("margin_top", 10)
	debug_panel.add_child(cog_label)
	
	var cog_display := Label.new()
	cog_display.name = "CognitiveDisplay"
	cog_display.text = "Loading..."
	cog_display.autowrap_mode = 2
	debug_panel.add_child(cog_display)
	
	# Add to scene
	if get_tree().current_scene:
		get_tree().current_scene.call_deferred("add_child", debug_panel)
	
	# Store references
	set_meta("debug_panel", debug_panel)
	set_meta("inv_display", inv_display)
	set_meta("cog_display", cog_display)


func _create_debug_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.5, 0.8, 0.6)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style


func _setup_terminal_main_scroll() -> void:
	if terminal_map_column == null:
		return
	var content_nodes: Array = [
		terminal_planet_title_label,
		terminal_planet_preview,
		terminal_map_preview_title_label,
		terminal_map_preview,
		terminal_widget_stack,
		terminal_map_label,
	]
	var has_content := false
	for node in content_nodes:
		if node != null:
			has_content = true
			break
	if not has_content:
		return
	_terminal_main_scroll = terminal_map_column.get_node_or_null("MainContentScroll")
	var content_column: VBoxContainer = null
	if _terminal_main_scroll == null:
		_terminal_main_scroll = ScrollContainer.new()
		_terminal_main_scroll.name = "MainContentScroll"
		_terminal_main_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_terminal_main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_terminal_main_scroll.follow_focus = true
		terminal_map_column.add_child(_terminal_main_scroll)
		var insert_index := terminal_map_column.get_child_count() - 1
		if terminal_page_summary_label and terminal_page_summary_label.get_parent() == terminal_map_column:
			insert_index = terminal_page_summary_label.get_index() + 1
		terminal_map_column.move_child(_terminal_main_scroll, insert_index)
		content_column = VBoxContainer.new()
		content_column.name = "Content"
		content_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content_column.add_theme_constant_override("separation", 8)
		_terminal_main_scroll.add_child(content_column)
	else:
		content_column = _terminal_main_scroll.get_node_or_null("Content")
		if content_column == null:
			content_column = VBoxContainer.new()
			content_column.name = "Content"
			content_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			content_column.add_theme_constant_override("separation", 8)
			_terminal_main_scroll.add_child(content_column)
	if content_column == null:
		return
	for node in content_nodes:
		if node == null:
			continue
		if node.get_parent() != content_column:
			var previous_parent := node.get_parent()
			if previous_parent != null:
				previous_parent.remove_child(node)
			content_column.add_child(node)


func _update_debug_panel() -> void:
	var debug_panel = get_meta("debug_panel", null)
	if debug_panel == null:
		return
	
	# Toggle debug panel with F12 (or your preferred key)
	if Input.is_action_just_pressed("debug_toggle"):
		debug_panel.visible = not debug_panel.visible
	
	if not debug_panel.visible:
		return
	
	# Update inventory display
	var inv_display = get_meta("inv_display", null)
	if inv_display != null:
		var inventory = get_node_or_null("/root/InventoryManager")
		if inventory != null:
			var items = inventory.get_all_items()
			var text = ""
			if items.keys().size() == 0:
				text = "Empty"
			else:
				for item_id in items.keys():
					var count = items[item_id]
					var display_name = item_id.capitalize()
					match String(item_id):
						&"faint_recollection":
							display_name = "Faint Recollection"
						&"residual_instinct":
							display_name = "Residual Instinct"
						&"ancient_bearing":
							display_name = "Ancient Bearing"
					text += "%s: %d\n" % [display_name, count]
			inv_display.text = text if text != "" else "Empty"
		else:
			inv_display.text = "No InventoryManager"
	
	# Update cognitive state display
	var cog_display = get_meta("cog_display", null)
	if cog_display != null:
		var cognitive = get_node_or_null("/root/CognitiveState")
		if cognitive != null:
			if cognitive.has_method("get_weights"):
				var weights = cognitive.call("get_weights")
				var dominant = cognitive.call("get_dominant_state") if cognitive.has_method("get_dominant_state") else "UNKNOWN"
				cog_display.text = "Recollection: %.2f\nInstinct: %.2f\nBearing: %.2f\n\nDominant: %s" % [
					float(weights.get("recollection", 0.0)),
					float(weights.get("instinct", 0.0)),
					float(weights.get("bearing", 0.0)),
					String(dominant)
				]
			else:
				cog_display.text = "CognitiveState: incomplete API"
		else:
			cog_display.text = "No CognitiveState"


func _process(delta):
	_handle_terminal_shortcuts()
	_update_terminal_planet_spin(delta)
	_process_terminal_command_queue(delta)
	_update_debug_panel()

	var power_system = get_node_or_null("/root/GameRoot/Power")
	if not _main_hud_hidden and power_system and power_label and power_bar:
		var status: Dictionary = power_system.get_power_status()
		var total_power: float = float(status.get("total", 0.0))
		var max_power_value: float = float(status.get("max", 0.0))
		var generated_per_second: float = float(status.get("generated", 0.0)) * 60.0
		var consumed_per_second: float = float(status.get("consumed", 0.0)) * 60.0
		var net_per_second: float = float(status.get("net", 0.0)) * 60.0
		power_label.text = "POWER: %d/%d | GEN %.0f/s | DRAW %.0f/s | NET %+0.0f/s" % [int(round(total_power)), int(round(max_power_value)), generated_per_second, consumed_per_second, net_per_second]
		if max_power_value > 0.0:
			power_bar.value = (total_power / max_power_value) * 100.0
		if total_power <= 10.0:
			power_label.modulate = Color(0.95, 0.35, 0.35, 1.0)
		elif total_power <= 50.0:
			power_label.modulate = Color(0.95, 0.8, 0.35, 1.0)
		else:
			power_label.modulate = Color(0.85, 0.92, 1.0, 1.0)

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
				var reserve = int(ws.get("ammo_standard", 0))
				var reloading = bool(ws.get("reloading", false))
				
				var ammo_text = "AMMO: %d/%d +%d" % [loaded, magazine_size, reserve]
				if reloading:
					ammo_text += " [RELOADING...]"
				
				if ammo_text != _last_ammo_text:
					ammo_label.text = ammo_text
					_last_ammo_text = ammo_text
			if cooldown_bar and cooldown_label:
				var cooldown_total = max(0.001, float(ws.get("cooldown_total", 0.001)))
				var cooldown_remaining = max(0.0, float(ws.get("cooldown_remaining", 0.0)))
				var pct = clamp((cooldown_remaining / cooldown_total) * 100.0, 0.0, 100.0)
				var cd_text = "COOLDOWN: READY" if cooldown_remaining <= 0.001 else "COOLDOWN: %.2fs" % cooldown_remaining
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
			var supply_status = supply_manager.get_status()
			if supply_status.get("active", false):
				var next_drop = supply_status.get("next_drop_in", -1.0)
				var drops = supply_status.get("drops_queued", 0)
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
		var player_controller = get_node_or_null("/root/GameRoot/World/PlayerController")
		if player_controller and player_controller.has_method("should_show_prompt") and bool(player_controller.should_show_prompt()):
			if player_controller.has_method("get_interaction_prompt"):
				prompt = str(player_controller.get_interaction_prompt())
		else:
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
		terminal_hint_label.text = "Type directly into the command line. Drag globe to inspect. Left click in the world to place while building. Esc closes."
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
	_set_terminal_page(_terminal_current_page if _terminal_page_buttons.has(_terminal_current_page) else "OVERVIEW")
	if terminal_panel:
		terminal_panel.visible = true
		terminal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if terminal_background:
		terminal_background.visible = true
		terminal_background.initialize()
		terminal_background.generate_new()
	if terminal_target_label:
		terminal_target_label.text = "SIM: %d TPS | THREAT: STABLE | POWER: -- | LINKING" % Engine.physics_ticks_per_second
	if not _terminal_boot_started:
		_terminal_ready = false
		_terminal_boot_started = true
		_terminal_lines.clear()
		_terminal_log_entries.clear()
		_terminal_command_queue.clear()
		_terminal_command_queue_tick = 0.0
		_run_terminal_boot_sequence()
	else:
		_terminal_ready = true
		_append_terminal_line("LOCAL SNAPSHOT MODE ACTIVE", "info")
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
	var world_terminal := get_node_or_null("/root/GameRoot/World/CommandTerminal")
	if world_terminal != null and world_terminal.has_method("deactivate_visual_after_ui_close"):
		world_terminal.call("deactivate_visual_after_ui_close")

func is_terminal_open() -> bool:
	return _terminal_open

func _handle_terminal_shortcuts():
	if not _terminal_open:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		if _placement_mode_active:
			if not _cancel_active_placement_mode():
				exit_placement_mode_ui()
			return
		close_command_terminal()
		return
	_ensure_terminal_input_focus()
	if terminal_input == null or not terminal_input.editable:
		return
	var viewport := get_viewport()
	var focus_owner := viewport.gui_get_focus_owner() if viewport != null else null
	if Input.is_action_just_pressed("ui_up"):
		if focus_owner == terminal_input:
			_focus_terminal_button_group(_terminal_action_buttons, false)
		else:
			_move_terminal_button_focus(-1)
		return
	if Input.is_action_just_pressed("ui_down"):
		if focus_owner == terminal_input:
			_focus_terminal_button_group(_terminal_nav_buttons, true)
		else:
			_move_terminal_button_focus(1)
		return
	if Input.is_action_just_pressed("ui_accept") and focus_owner is BaseButton:
		(focus_owner as BaseButton).pressed.emit()
		return

func _input(event: InputEvent) -> void:
	if not _terminal_open or terminal_planet_preview == null:
		return
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if not _planet_preview_contains_screen_point(button_event.position):
			return
		if button_event.button_index == MOUSE_BUTTON_WHEEL_UP and button_event.pressed:
			if button_event.ctrl_pressed:
				_planet_preview_zoom_distance = max(PLANET_PREVIEW_ZOOM_MIN, _planet_preview_zoom_distance - PLANET_PREVIEW_ZOOM_STEP)
				_apply_terminal_planet_zoom()
			else:
				_scroll_terminal_main_by(-96)
			get_viewport().set_input_as_handled()
			return
		if button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and button_event.pressed:
			if button_event.ctrl_pressed:
				_planet_preview_zoom_distance = min(PLANET_PREVIEW_ZOOM_MAX, _planet_preview_zoom_distance + PLANET_PREVIEW_ZOOM_STEP)
				_apply_terminal_planet_zoom()
			else:
				_scroll_terminal_main_by(96)
			get_viewport().set_input_as_handled()
			return
		if button_event.button_index == MOUSE_BUTTON_LEFT:
			_planet_preview_drag_active = button_event.pressed
			_planet_preview_drag_last_pos = button_event.position
			if button_event.pressed:
				if terminal_input:
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
			if terminal_input:
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
	if terminal_input:
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
		if terminal_input:
			terminal_input.grab_focus()


func _ensure_terminal_input_focus():
	if terminal_input == null:
		return
	if not _terminal_open or not _terminal_ready:
		return
	if not terminal_input.editable:
		return
	var viewport := get_viewport()
	var focus_owner := viewport.gui_get_focus_owner() if viewport != null else null
	if focus_owner == terminal_input:
		return
	if focus_owner != null and terminal_panel != null and terminal_panel.is_ancestor_of(focus_owner):
		return
	if terminal_input:
		terminal_input.grab_focus()


func _focus_terminal_button_group(buttons: Array[BaseButton], forward: bool) -> void:
	var indexes: Array[int] = []
	for idx in range(buttons.size()):
		indexes.append(idx)
	if not forward:
		indexes.reverse()
	for idx in indexes:
		var button := buttons[idx]
		if button == null or not is_instance_valid(button) or button.disabled:
			continue
		button.grab_focus()
		return
	if terminal_input and terminal_input.editable:
		terminal_input.grab_focus()


func _move_terminal_button_focus(step: int) -> void:
	var viewport := get_viewport()
	var focus_owner := viewport.gui_get_focus_owner() if viewport != null else null
	if not (focus_owner is BaseButton):
		return
	var ordered_buttons: Array[BaseButton] = []
	for button in _terminal_nav_buttons:
		if button != null:
			ordered_buttons.append(button)
	for button in _terminal_action_buttons:
		if button != null:
			ordered_buttons.append(button)
	var current_index := ordered_buttons.find(focus_owner)
	if current_index < 0 or ordered_buttons.is_empty():
		return
	var total := ordered_buttons.size()
	for offset in range(1, total + 1):
		var next_index := (current_index + (step * offset) + total) % total
		var next_button := ordered_buttons[next_index]
		if next_button == null or not is_instance_valid(next_button) or next_button.disabled:
			continue
		next_button.grab_focus()
		return

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

	for label in [terminal_header_eyebrow, terminal_nav_title, terminal_action_title, terminal_command_title, terminal_map_title_label, terminal_planet_title_label, terminal_map_preview_title_label]:
		if label == null:
			continue
		label.add_theme_color_override("font_color", Color(0.63, 0.83, 0.74, 0.92))
		label.add_theme_font_size_override("font_size", 11)
	if _terminal_main_scroll:
		var main_scroll_style := StyleBoxFlat.new()
		main_scroll_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		main_scroll_style.set_border_width_all(0)
		_terminal_main_scroll.add_theme_stylebox_override("panel", main_scroll_style)

	if terminal_title_label:
		terminal_title_label.add_theme_color_override("font_color", Color(0.93, 0.98, 0.95, 1.0))
		terminal_title_label.add_theme_font_size_override("font_size", 18)

	if terminal_target_label:
		terminal_target_label.add_theme_color_override("font_color", Color(0.76, 0.92, 0.86, 0.95))
		terminal_target_label.add_theme_font_size_override("font_size", 11)
	if terminal_page_summary_label:
		terminal_page_summary_label.add_theme_color_override("font_color", Color(0.62, 0.78, 0.72, 0.92))
		terminal_page_summary_label.add_theme_font_size_override("font_size", 11)

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
			output.fit_content = false
			output.scroll_active = true
			output.scroll_following = true
			output.bbcode_enabled = true
	if terminal_widget_stack:
		var widget_panel_style := StyleBoxFlat.new()
		widget_panel_style.bg_color = Color(0.012, 0.02, 0.024, 0.99)
		widget_panel_style.border_color = Color(0.18, 0.3, 0.28, 1.0)
		widget_panel_style.set_border_width_all(1)
		widget_panel_style.set_corner_radius_all(6)
		for panel in terminal_widget_stack.find_children("*", "PanelContainer", true, false):
			panel.add_theme_stylebox_override("panel", widget_panel_style)
		for rich_text in terminal_widget_stack.find_children("*", "RichTextLabel", true, false):
			rich_text.add_theme_color_override("font_color", Color(0.82, 0.92, 0.88, 1.0))
			rich_text.add_theme_font_size_override("font_size", 13)
			rich_text.fit_content = false
			rich_text.scroll_active = true
			rich_text.scroll_following = true
			rich_text.bbcode_enabled = true
		for label in terminal_widget_stack.find_children("*", "Label", true, false):
			label.add_theme_color_override("font_color", Color(0.63, 0.83, 0.74, 0.92))
			label.add_theme_font_size_override("font_size", 11)
	if terminal_activity_scroll:
		var scroll_style := StyleBoxFlat.new()
		scroll_style.bg_color = Color(0.012, 0.02, 0.024, 0.99)
		scroll_style.border_color = Color(0.18, 0.3, 0.28, 1.0)
		scroll_style.set_border_width_all(1)
		scroll_style.set_corner_radius_all(6)
		terminal_activity_scroll.add_theme_stylebox_override("panel", scroll_style)

	if terminal_input:
		var input_style := StyleBoxFlat.new()
		input_style.bg_color = Color(0.06, 0.12, 0.095, 1.0)
		input_style.border_color = Color(0.58, 0.92, 0.74, 1.0)
		input_style.set_border_width_all(2)
		input_style.set_corner_radius_all(6)
		input_style.content_margin_left = 10.0
		input_style.content_margin_right = 10.0
		input_style.content_margin_top = 8.0
		input_style.content_margin_bottom = 8.0
		terminal_input.add_theme_stylebox_override("normal", input_style)
		terminal_input.add_theme_stylebox_override("focus", input_style)
		terminal_input.add_theme_color_override("font_color", Color(0.96, 1.0, 0.98, 1.0))
		terminal_input.add_theme_color_override("font_placeholder_color", Color(0.70, 0.88, 0.79, 0.95))
		terminal_input.add_theme_color_override("font_selected_color", Color(0.02, 0.05, 0.04, 1.0))
		terminal_input.add_theme_color_override("selection_color", Color(0.68, 0.92, 0.80, 0.92))
		terminal_input.add_theme_color_override("caret_color", Color(0.96, 1.0, 0.98, 1.0))
		terminal_input.add_theme_constant_override("minimum_character_width", 1)
		terminal_input.add_theme_font_size_override("font_size", 18)
		terminal_input.self_modulate = Color(1, 1, 1, 1)
	var prompt_label = get_node_or_null("TerminalPanel/Body/CommandColumn/InputRow/Prompt")
	if prompt_label:
		prompt_label.add_theme_color_override("font_color", Color(0.78, 0.96, 0.86, 1.0))
		prompt_label.add_theme_font_size_override("font_size", 18)
	if terminal_status_label:
		terminal_status_label.add_theme_color_override("font_color", Color(0.64, 0.88, 0.78, 0.96))
		terminal_status_label.add_theme_font_size_override("font_size", 13)
	if terminal_hint_label:
		terminal_hint_label.add_theme_color_override("font_color", Color(0.54, 0.72, 0.68, 0.88))
		terminal_hint_label.add_theme_font_size_override("font_size", 12)
	var nav_button_style := StyleBoxFlat.new()
	nav_button_style.bg_color = Color(0.04, 0.06, 0.065, 0.98)
	nav_button_style.border_color = Color(0.20, 0.34, 0.31, 1.0)
	nav_button_style.set_border_width_all(1)
	nav_button_style.set_corner_radius_all(4)
	var nav_button_active_style := StyleBoxFlat.new()
	nav_button_active_style.bg_color = Color(0.08, 0.16, 0.14, 1.0)
	nav_button_active_style.border_color = Color(0.43, 0.76, 0.61, 1.0)
	nav_button_active_style.set_border_width_all(1)
	nav_button_active_style.set_corner_radius_all(4)
	var nav_button_focus_style := StyleBoxFlat.new()
	nav_button_focus_style.bg_color = Color(0.10, 0.20, 0.17, 1.0)
	nav_button_focus_style.border_color = Color(0.62, 0.92, 0.78, 1.0)
	nav_button_focus_style.set_border_width_all(2)
	nav_button_focus_style.set_corner_radius_all(4)
	for button in _terminal_page_buttons.values():
		if button == null:
			continue
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_stylebox_override("normal", nav_button_style)
		button.add_theme_stylebox_override("hover", nav_button_style)
		button.add_theme_stylebox_override("pressed", nav_button_active_style)
		button.add_theme_stylebox_override("disabled", nav_button_active_style)
		button.add_theme_stylebox_override("focus", nav_button_focus_style)
		button.add_theme_color_override("font_color", Color(0.80, 0.92, 0.88, 1.0))
		button.add_theme_color_override("font_disabled_color", Color(0.95, 1.0, 0.97, 1.0))
		button.add_theme_font_size_override("font_size", 13)
	for button in [terminal_wait_button, terminal_wait_10x_button, terminal_focus_button, terminal_harden_button, terminal_reset_button, terminal_reboot_button, terminal_help_button]:
		if button == null:
			continue
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_stylebox_override("normal", nav_button_style)
		button.add_theme_stylebox_override("hover", nav_button_style)
		button.add_theme_stylebox_override("pressed", nav_button_active_style)
		button.add_theme_stylebox_override("focus", nav_button_focus_style)
		button.add_theme_color_override("font_color", Color(0.74, 0.88, 0.82, 1.0))
		button.add_theme_font_size_override("font_size", 12)
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
	_terminal_activity_autofollow = _is_terminal_activity_near_bottom()
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
	if _terminal_activity_autofollow:
		call_deferred("_scroll_terminal_output_to_bottom")

func _scroll_terminal_output_to_bottom():
	if terminal_output == null or terminal_activity_scroll == null:
		return
	var scroll_bar: ScrollBar = terminal_activity_scroll.get_v_scroll_bar()
	if scroll_bar == null:
		return
	terminal_activity_scroll.scroll_vertical = int(max(0.0, scroll_bar.max_value))

func _is_terminal_activity_near_bottom() -> bool:
	if terminal_activity_scroll == null:
		return true
	var scroll_bar: ScrollBar = terminal_activity_scroll.get_v_scroll_bar()
	if scroll_bar == null:
		return true
	var bottom_threshold: float = max(0.0, scroll_bar.max_value - scroll_bar.page - TERMINAL_ACTIVITY_SCROLL_FOLLOW_MARGIN)
	return scroll_bar.value >= bottom_threshold

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
	_set_terminal_page("SECTORS")
	_append_terminal_line("FOCUS SHIFTED TO %s" % _display_sector_name(_terminal_highlight_sector).to_upper(), "success", _terminal_highlight_sector)
	_refresh_snapshot()

func _render_terminal_status(text: String):
	if terminal_status_label:
		terminal_status_label.text = text


func _format_terminal_input_echo(raw_text: String) -> String:
	var compact := raw_text.strip_edges()
	if compact.is_empty():
		return ""
	if compact.length() > 48:
		return compact.substr(0, 45) + "..."
	return compact


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
	var input_echo := _format_terminal_input_echo(raw_text)
	var parsed := _parse_terminal_command(raw_text)
	var verb := str(parsed.get("verb", ""))
	if verb.is_empty():
		terminal_status_label.text = "READY // COMMAND BAR ACTIVE%s" % (" // > " + input_echo if not input_echo.is_empty() else "")
		return
	var valid_verbs := {
		"HELP": true, "STATUS": true, "ENEMIES": true, "WAVE": true, "SECTORS": true,
		"CONTRACT": true, "PLANET": true, "MAP": true, "CLEAR": true, "WALL": true,
		"START": true, "OVERLAY": true, "ALLOCATE_DEFENSE": true, "DEPLOY": true, "FOCUS": true,
		"TURRET": true, "REROUTE": true, "GOTO": true, "WAIT": true, "HARDEN": true,
		"REPAIR": true, "MOVE": true, "RETURN": true, "SYNC": true, "LOCKDOWN": true,
		"FORTIFY": true, "BOOST": true, "SCAN": true, "STABILIZE": true, "PRIORITIZE": true,
		"DRONE": true, "POLICY": true, "CONFIG": true, "SET": true, "FAB": true, "SCAVENGE": true,
	}
	if valid_verbs.has(verb):
		terminal_status_label.text = "VALIDATING // %s%s" % [verb, " // > " + input_echo if not input_echo.is_empty() else ""]
	else:
		terminal_status_label.text = "UNKNOWN VERB // %s%s" % [verb, " // > " + input_echo if not input_echo.is_empty() else ""]

func _should_refresh_snapshot(command_upper: String) -> bool:
	var verb = command_upper.split(" ", false, 1)[0]
	return verb in [
		"STATUS", "ENEMIES", "WAVE", "SECTORS", "CONTRACT", "PLANET", "MAP",
		"START", "WALL", "TURRET",
		"WAIT", "RESET", "REBOOT", "SET", "FAB", "CONFIG",
		"ALLOCATE", "FOCUS", "HARDEN", "SCAVENGE", "REPAIR", "DEPLOY",
		"MOVE", "RETURN", "SYNC", "LOCKDOWN", "OVERLAY", "ALLOCATE_DEFENSE", "REROUTE",
	]

func _on_terminal_poll_timeout():
	if _terminal_open and _terminal_ready:
		_refresh_snapshot()

func _refresh_snapshot() -> void:
	_ensure_terminal_contract_binding()
	_terminal_snapshot = _build_local_snapshot()
	_record_terminal_snapshot_events(_terminal_snapshot)
	_render_terminal_header(_terminal_snapshot)
	_render_terminal_main_content(_terminal_snapshot)
	_refresh_contract_previews()
	_render_terminal_status("LOCAL SNAPSHOT LIVE")

func _render_terminal_header(snapshot: Dictionary) -> void:
	var contract: Dictionary = snapshot.get("contract", {})
	var contract_seed := int(contract.get("contract_seed", -1)) if contract is Dictionary else -1
	var planet_key := str(contract.get("planet_key", "NO CONTRACT")).to_upper() if contract is Dictionary else "NO CONTRACT"
	var phase_text := str(snapshot.get("contract_phase", "UNKNOWN")).replace("_", " ").to_upper()
	var threat_value := float(snapshot.get("threat_raw", 0.0))
	var threat_label := _get_threat_band(threat_value)
	var power_status := _get_power_status_snapshot()
	var reserve_rate := float(power_status.get("net", 0.0)) * 60.0
	var rate_text := _format_terminal_rate(Engine.time_scale)
	var archive_state := "NOMINAL" if contract_seed >= 0 else "UNSYNCED"
	var reserve_text := "%+0.1f/s" % reserve_rate
	if terminal_header_eyebrow:
		terminal_header_eyebrow.text = "CUSTODIAN // COMMAND LINK | MODE: COMMAND | FIDELITY: FULL | PAGE: %s" % _terminal_current_page
	if terminal_title_label:
		terminal_title_label.text = "%s // %s" % [planet_key, "CONTRACT-%04d" % contract_seed if contract_seed >= 0 else "NO CONTRACT LOCK"]
	if terminal_target_label:
		var threat_color := _get_threat_color(threat_label)
		terminal_target_label.text = "T:%s | THREAT:%s | ASSAULT:%s | POWER:%s | ARCHIVE:%s | RATE:%s" % [
			str(snapshot.get("time", "--:--:--")),
			threat_label,
			phase_text,
			reserve_text,
			archive_state,
			rate_text,
		]
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


func _terminal_section(title: String) -> String:
	return "[color=#7DAF9D]%s[/color]" % title.to_upper()


func _terminal_card(title: String, body_lines: Array[String]) -> Array[String]:
	var lines: Array[String] = []
	lines.append(_terminal_section(title))
	lines.append("------------------------------")
	for line in body_lines:
		lines.append(line)
	return lines


func _terminal_kv(label: String, value) -> String:
	return "%-12s %s" % [label.to_upper(), str(value)]


func _terminal_divider() -> String:
	return "=============================="


func _format_terminal_rate(rate: float) -> String:
	if is_equal_approx(rate, round(rate)):
		return "%dX" % int(round(rate))
	return "%.1fX" % rate


func _set_terminal_page(page_name: String) -> void:
	var normalized := page_name.to_upper()
	if not _terminal_page_buttons.has(normalized):
		return
	_terminal_current_page = normalized
	_refresh_terminal_page_buttons()
	if _terminal_open:
		_refresh_snapshot()


func _refresh_terminal_page_buttons() -> void:
	for page_name in _terminal_page_buttons.keys():
		var button: BaseButton = _terminal_page_buttons[page_name]
		if button == null:
			continue
		var active: bool = String(page_name) == _terminal_current_page
		button.disabled = active
		button.text = ("> %s" % String(page_name)) if active else String(page_name)

func _on_primary_weapon_button_pressed() -> void:
	var operator = get_node_or_null("/root/GameRoot/World/Operator")
	if operator == null:
		return
	if operator.has_method("toggle_primary_carbine"):
		operator.toggle_primary_carbine()


func _on_terminal_page_button_pressed(page_name: String) -> void:
	_set_terminal_page(page_name)


func _on_terminal_action_button_pressed(command_text: String) -> void:
	if not _terminal_open or not _terminal_ready:
		return
	_queue_terminal_command(command_text)


func _set_terminal_rich_text(target: Node, text: String) -> void:
	if target == null:
		return
	if target is RichTextLabel:
		target.clear()
		target.append_text(text)
		call_deferred("_scroll_terminal_rich_text_to_bottom", target)
	elif target is Label:
		target.text = text


func _scroll_terminal_main_by(delta: int) -> void:
	if _terminal_main_scroll == null or not is_instance_valid(_terminal_main_scroll):
		return
	_terminal_main_scroll.scroll_vertical = max(0, _terminal_main_scroll.scroll_vertical + delta)


func _scroll_terminal_rich_text_to_bottom(target: Node) -> void:
	if target == null or not (target is RichTextLabel):
		return
	var rich_text: RichTextLabel = target
	rich_text.scroll_to_line(max(0, rich_text.get_line_count() - 1))


func _render_terminal_text_output(lines: Array[String]) -> void:
	_set_terminal_rich_text(terminal_map_label, "\n".join(lines))


func _build_terminal_contract_lines(contract: Dictionary) -> Array[String]:
	if contract is Dictionary and not contract.is_empty():
		return [
			_terminal_kv("PLANET", str(contract.get("planet_key", "UNKNOWN")).to_upper()),
			_terminal_kv("CONTRACT", "#%d" % int(contract.get("contract_seed", -1))),
			_terminal_kv("MAP", str(contract.get("map_seed", "?"))),
			_terminal_kv("ROOMS", int(contract.get("room_count", 0))),
			_terminal_kv("SPAWNS", int(contract.get("corridor_spawn_count", 0))),
		]
	return [_terminal_kv("PLANET", "NO CONTRACT")]


func _analyze_terminal_sectors(sector_array: Array, highlighted_name: String) -> Dictionary:
	var selected_sector: Dictionary = {}
	var compromised_count := 0
	var offline_count := 0
	var critical_count := 0
	for sector_variant in sector_array:
		if not (sector_variant is Dictionary):
			continue
		var sector_dict: Dictionary = sector_variant
		var raw_name := str(sector_dict.get("name", sector_dict.get("id", "SECTOR")))
		var status_text := str(sector_dict.get("status", "UNKNOWN")).to_upper()
		if highlighted_name.is_empty():
			if selected_sector.is_empty():
				selected_sector = sector_dict
		elif raw_name.to_upper() == highlighted_name:
			selected_sector = sector_dict
		if status_text.find("OFFLINE") >= 0:
			offline_count += 1
		if status_text.find("BREACH") >= 0 or status_text.find("DAMAGED") >= 0 or status_text.find("CRITICAL") >= 0:
			compromised_count += 1
		if int(sector_dict.get("power_priority", 0)) >= 85:
			critical_count += 1
	if selected_sector.is_empty() and not sector_array.is_empty() and sector_array[0] is Dictionary:
		selected_sector = sector_array[0]
	return {
		"selected_sector": selected_sector,
		"compromised_count": compromised_count,
		"offline_count": offline_count,
		"critical_count": critical_count,
	}


func _build_terminal_render_context(snapshot: Dictionary) -> Dictionary:
	var local_director := _get_local_director_status()
	var threat_text: Variant = snapshot.get("threat", "?")
	var assault_value: Variant = snapshot.get("assault", "?")
	if threat_text == "?" and not local_director.is_empty():
		threat_text = "%.1f" % float(local_director.get("threat", 0.0))
	if assault_value == "?" and not local_director.is_empty():
		assault_value = "%s/%s" % [
			str(local_director.get("lane", "none")).to_upper(),
			str(local_director.get("objective", "none")).to_upper(),
		]
	var wave: Dictionary = snapshot.get("wave", {})
	var wave_text := "--"
	if wave is Dictionary and not wave.is_empty():
		wave_text = "%d/%d P%d" % [
			int(wave.get("wave_number", 0)),
			int(wave.get("max_wave", 0)),
			int(wave.get("pending_spawns", 0)),
		]
	var enemies = snapshot.get("enemies", {})
	var hostile_text := "--"
	if enemies is Dictionary and not enemies.is_empty():
		hostile_text = "%d | D%d F%d H%d" % [
			int(enemies.get("total", 0)),
			int(enemies.get("drone", 0)),
			int(enemies.get("fast", 0)),
			int(enemies.get("heavy", 0)),
		]
	var contract: Dictionary = snapshot.get("contract", {})
	var power_status := _get_power_status_snapshot()
	var sector_array: Array = snapshot.get("sectors", []) if snapshot.get("sectors", []) is Array else []
	var sector_analysis := _analyze_terminal_sectors(sector_array, _terminal_highlight_sector.strip_edges().to_upper())
	var phase_text := str(snapshot.get("contract_phase", "UNKNOWN")).replace("_", " ").to_upper()
	var power_summary := "%d/%d | %+0.1f/s" % [
		int(round(float(power_status.get("total", 0.0)))),
		int(round(float(power_status.get("max", 0.0)))),
		float(power_status.get("net", 0.0)) * 60.0,
	]
	return {
		"snapshot": snapshot,
		"threat_text": threat_text,
		"assault_value": assault_value,
		"wave_text": wave_text,
		"hostile_text": hostile_text,
		"contract": contract,
		"power_status": power_status,
		"sector_array": sector_array,
		"selected_sector": sector_analysis.get("selected_sector", {}),
		"compromised_count": int(sector_analysis.get("compromised_count", 0)),
		"offline_count": int(sector_analysis.get("offline_count", 0)),
		"critical_count": int(sector_analysis.get("critical_count", 0)),
		"phase_text": phase_text,
		"power_summary": power_summary,
		"contract_lines": _build_terminal_contract_lines(contract),
	}


func _build_terminal_overlay_lines() -> Array[String]:
	return [
		"",
		_terminal_divider(),
		"%s PWR:%s PATH:%s THREAT:%s REPAIR:%s" % [_terminal_section("OVERLAYS"),
			"ON" if bool(_terminal_overlay_flags.get("power", false)) else "OFF",
			"ON" if bool(_terminal_overlay_flags.get("path", false)) else "OFF",
			"ON" if bool(_terminal_overlay_flags.get("threat", false)) else "OFF",
			"ON" if bool(_terminal_overlay_flags.get("repair", false)) else "OFF",
		],
	]


func _render_terminal_page(context: Dictionary) -> String:
	var snapshot: Dictionary = context.get("snapshot", {})
	var phase_text: String = context.get("phase_text", "UNKNOWN")
	var threat_text: Variant = context.get("threat_text", "?")
	var assault_value: Variant = context.get("assault_value", "?")
	var wave_text: String = context.get("wave_text", "--")
	var hostile_text: String = context.get("hostile_text", "--")
	var contract: Dictionary = context.get("contract", {})
	var power_status: Dictionary = context.get("power_status", {})
	var sector_array: Array = context.get("sector_array", [])
	var selected_sector: Dictionary = context.get("selected_sector", {})
	var contract_lines: Array[String] = context.get("contract_lines", [])
	match _terminal_current_page:
		"OVERVIEW":
			_render_terminal_overview_widgets(phase_text, hostile_text, int(context.get("compromised_count", 0)), int(context.get("offline_count", 0)), power_status, str(context.get("power_summary", "")), int(context.get("critical_count", 0)), threat_text, assault_value, wave_text, snapshot.get("defense_rating", 0.0), sector_array, contract_lines)
			return "DEFAULT COMMAND SURFACE // SUMMARY, POWER, ASSAULT, PRIORITIES"
		"STATUS":
			_render_terminal_status_widgets(snapshot, phase_text, threat_text, str(context.get("power_summary", "")), assault_value, wave_text, hostile_text)
			return "CANONICAL SNAPSHOT // RAW OPERATIONAL STATUS MIRROR"
		"SECTORS":
			_render_terminal_sector_widgets(sector_array, selected_sector)
			return "TACTICAL MANAGEMENT // SECTOR HEALTH, POWER, PRIORITY"
		"POWER":
			_render_terminal_power_widgets(power_status, sector_array)
			return "POWER ROUTING // GENERATION, DRAW, PRIORITIES"
		"DEFENSE":
			_render_terminal_defense_widgets(snapshot, assault_value, hostile_text)
			return "DEFENSE READINESS // TURRETS, ASSAULT LANES, COVERAGE"
		"SENSORS":
			_render_terminal_sensors_widgets(threat_text, hostile_text, wave_text, assault_value, sector_array)
			return "SENSOR FIDELITY // CONTACTS, THREAT LANES, ACTIVITY"
		"INCIDENTS":
			_render_terminal_incidents_widgets()
			return "EVENT TRIAGE // RECENT TRANSCRIPT SIGNALS AND ALERTS"
		"ARCHIVE":
			_render_terminal_archive_widgets(contract)
			return "KNOWLEDGE PRESERVATION // CONTRACT WORLD PROFILE AND STATE"
		"RECON":
			_render_terminal_recon_widgets(contract, assault_value, hostile_text)
			return "RECON HYPOTHESES // WHAT THE CURRENT CONTRACT SUGGESTS"
		"CONTRACTS":
			_render_terminal_contracts_widgets(contract_lines, contract)
			return "ACTIVE CONTRACT // PLANET, SEEDS, WORLD LINK"
		"HISTORY":
			_render_terminal_history_widgets()
			return "OPERATIONAL LOG // CHRONOLOGICAL RECORD OF THIS RUN"
		"SETTINGS":
			_render_terminal_settings_widgets()
			return "TERMINAL SETTINGS // CURRENT LIVE-SHELL CONTROLS"
		_:
			return "TACTICAL SUMMARY // LIVE CONTRACT SNAPSHOT"


func _set_terminal_widget_mode(page_name: String) -> void:
	var show_overview := page_name == "OVERVIEW"
	var show_sectors := page_name == "SECTORS"
	var show_power := page_name == "POWER"
	var show_defense := page_name == "DEFENSE"
	var show_sensors := page_name == "SENSORS"
	var show_incidents := page_name == "INCIDENTS"
	var show_archive := page_name == "ARCHIVE"
	var show_recon := page_name == "RECON"
	var show_contracts := page_name == "CONTRACTS"
	var show_history := page_name == "HISTORY"
	var show_status := page_name == "STATUS"
	var show_settings := page_name == "SETTINGS"
	var using_widgets := show_overview or show_sectors or show_power or show_defense or show_sensors or show_incidents or show_archive or show_recon or show_contracts or show_history or show_status or show_settings
	if terminal_widget_stack:
		terminal_widget_stack.visible = using_widgets
	if terminal_overview_widgets:
		terminal_overview_widgets.visible = show_overview
	if terminal_sectors_widgets:
		terminal_sectors_widgets.visible = show_sectors
	if terminal_power_widgets:
		terminal_power_widgets.visible = show_power
	if terminal_defense_widgets:
		terminal_defense_widgets.visible = show_defense
	if terminal_sensors_widgets:
		terminal_sensors_widgets.visible = show_sensors
	if terminal_incidents_widgets:
		terminal_incidents_widgets.visible = show_incidents
	if terminal_archive_widgets:
		terminal_archive_widgets.visible = show_archive
	if terminal_recon_widgets:
		terminal_recon_widgets.visible = show_recon
	if terminal_contracts_widgets:
		terminal_contracts_widgets.visible = show_contracts
	if terminal_history_widgets:
		terminal_history_widgets.visible = show_history
	if terminal_status_widgets:
		terminal_status_widgets.visible = show_status
	if terminal_settings_widgets:
		terminal_settings_widgets.visible = show_settings
	if terminal_map_label:
		terminal_map_label.visible = not using_widgets


func _render_terminal_overview_widgets(phase_text: String, hostile_text: String, compromised_count: int, offline_count: int, power_status: Dictionary, power_summary: String, critical_count: int, threat_text: Variant, assault_value: Variant, wave_text: String, defense_rating: Variant, sector_array: Array, contract_lines: Array[String]) -> void:
	_set_terminal_rich_text(terminal_overview_operational_body, "\n".join([
		_terminal_kv("MODE", "COMMAND"),
		_terminal_kv("PHASE", phase_text),
		_terminal_kv("HOSTILES", hostile_text),
		_terminal_kv("COMPROMISED", compromised_count),
		_terminal_kv("SYSTEMS OFF", offline_count),
	]))
	_set_terminal_rich_text(terminal_overview_power_body, "\n".join([
		_terminal_kv("BUDGET", power_summary),
		_terminal_kv("GEN", "%.1f/s" % (float(power_status.get("generated", 0.0)) * 60.0)),
		_terminal_kv("DRAW", "%.1f/s" % (float(power_status.get("consumed", 0.0)) * 60.0)),
		_terminal_kv("ROUTING", "%d PRIORITY SECTORS" % critical_count),
	]))
	_set_terminal_rich_text(terminal_overview_assault_body, "\n".join([
		_terminal_kv("THREAT", threat_text),
		_terminal_kv("ASSAULT", assault_value),
		_terminal_kv("WAVE", wave_text),
		_terminal_kv("DEFENSE", defense_rating),
	]))
	var priority_lines: Array[String] = []
	for sector_variant in sector_array.slice(0, min(4, sector_array.size())):
		if not (sector_variant is Dictionary):
			continue
		var sector: Dictionary = sector_variant
		var raw_name := str(sector.get("name", sector.get("id", "SECTOR")))
		var display := _display_sector_name(raw_name).to_upper()
		var status := str(sector.get("status", "UNKNOWN")).to_upper()
		priority_lines.append("%-18s HP %3s%% | %s" % [display, str(sector.get("hp_pct", "?")), status])
	if priority_lines.is_empty():
		priority_lines.append("NO PRIORITY SECTORS AVAILABLE")
	_set_terminal_rich_text(terminal_overview_priority_body, "\n".join(priority_lines))
	_set_terminal_rich_text(terminal_overview_contract_body, "\n".join(contract_lines))


func _render_terminal_sector_widgets(sector_array: Array, selected_sector: Dictionary) -> void:
	var list_lines: Array[String] = [
		"SECTOR             HP   PWR       PRI  STATUS",
		"------------------ ---- --------- ---- ----------------",
	]
	for sector_variant in sector_array:
		if not (sector_variant is Dictionary):
			continue
		var sector: Dictionary = sector_variant
		var raw_name := str(sector.get("name", sector.get("id", "SECTOR")))
		var display := _display_sector_name(raw_name)
		var status := str(sector.get("status", "UNKNOWN")).to_upper()
		var prefix := " "
		if _terminal_highlight_sector == raw_name:
			prefix = ">"
		list_lines.append("%s %-18s %3s%% %-9s %3s  %s" % [
			prefix,
			display.to_upper(),
			str(sector.get("hp_pct", "?")),
			str(sector.get("power_tier", "UNKNOWN")).to_upper(),
			str(sector.get("power_priority", "?")),
			status,
		])
	_set_terminal_rich_text(terminal_sector_list_body, "\n".join(list_lines))
	var detail_lines: Array[String] = []
	if not selected_sector.is_empty():
		detail_lines = [
			_terminal_kv("NAME", _display_sector_name(str(selected_sector.get("name", "SECTOR"))).to_upper()),
			_terminal_kv("STATUS", str(selected_sector.get("status", "UNKNOWN")).to_upper()),
			_terminal_kv("HP", "%s%%" % str(selected_sector.get("hp_pct", "?"))),
			_terminal_kv("POWER", "%s / %s" % [str(selected_sector.get("power_allocated", 0.0)), str(selected_sector.get("power_standard", 0.0))]),
			_terminal_kv("PRIORITY", str(selected_sector.get("power_priority", "?"))),
			"",
			"AVAILABLE ACTIONS",
			"OPEN POWER VIEW",
			"PIN SECTOR",
			"SET PRIORITY",
			"TRACK INCIDENTS",
		]
	else:
		detail_lines = ["NO SECTOR SELECTED"]
	_set_terminal_rich_text(terminal_sector_detail_body, "\n".join(detail_lines))


func _render_terminal_power_widgets(power_status: Dictionary, sector_array: Array) -> void:
	_set_terminal_rich_text(terminal_power_global_body, "\n".join([
		_terminal_kv("TOTAL", "%d/%d" % [int(round(float(power_status.get("total", 0.0)))), int(round(float(power_status.get("max", 0.0))))]),
		_terminal_kv("GEN", "%.1f/s" % (float(power_status.get("generated", 0.0)) * 60.0)),
		_terminal_kv("DRAW", "%.1f/s" % (float(power_status.get("consumed", 0.0)) * 60.0)),
		_terminal_kv("RESERVE", "%+0.1f/s" % (float(power_status.get("net", 0.0)) * 60.0)),
	]))
	_set_terminal_rich_text(terminal_power_preset_body, "\n".join([
		"BALANCED",
		"DEFENSE FIRST",
		"SENSORS FIRST",
		"EMERGENCY LOAD SHED",
	]))
	var allocation_lines: Array[String] = [
		"SECTOR            LIVE / STD   TIER      PRI",
		"----------------  ----------   --------  ---",
	]
	for sector_variant in sector_array:
		if not (sector_variant is Dictionary):
			continue
		var sector: Dictionary = sector_variant
		allocation_lines.append("%-16s %5.1f / %5.1f   %-8s  %3s" % [
			_display_sector_name(str(sector.get("name", "SECTOR"))).to_upper(),
			float(sector.get("power_allocated", 0.0)),
			float(sector.get("power_standard", 0.0)),
			str(sector.get("power_tier", "UNKNOWN")).to_upper(),
			str(sector.get("power_priority", "?")),
		])
	_set_terminal_rich_text(terminal_power_allocation_body, "\n".join(allocation_lines))


func _build_terminal_defense_coverage_lines(sector_array: Array) -> Array[String]:
	var coverage_lines: Array[String] = []
	for sector_variant in sector_array:
		if not (sector_variant is Dictionary):
			continue
		var sector: Dictionary = sector_variant
		var display_name := _display_sector_name(str(sector.get("name", "SECTOR"))).to_upper()
		var status_text := str(sector.get("status", "UNKNOWN")).to_upper()
		var hp_pct := int(sector.get("hp_pct", 0))
		var readiness := "HOLDING"
		if status_text.find("BREACH") >= 0 or status_text.find("CRITICAL") >= 0:
			readiness = "BREACHED"
		elif status_text.find("DAMAGED") >= 0:
			readiness = "STRAINED"
		elif status_text.find("OFFLINE") >= 0:
			readiness = "OFFLINE"
		elif hp_pct < 70:
			readiness = "WATCHED"
		coverage_lines.append("%-16s %s | HP %3d%%" % [display_name, readiness, hp_pct])
		if coverage_lines.size() >= 6:
			break
	if coverage_lines.is_empty():
		coverage_lines.append("NO DEFENSE COVERAGE DATA AVAILABLE")
	return coverage_lines


func _render_terminal_defense_widgets(snapshot: Dictionary, assault_value: Variant, hostile_text: String) -> void:
	_set_terminal_rich_text(terminal_defense_readiness_body, "\n".join([
		_terminal_kv("RATING", "%.1f" % float(snapshot.get("defense_rating", 0.0))),
		_terminal_kv("ASSAULT", assault_value),
		_terminal_kv("HOSTILES", hostile_text),
		_terminal_kv("TURRETS", get_tree().get_nodes_in_group("turret").size()),
	]))
	_set_terminal_rich_text(terminal_defense_modes_body, "\n".join([
		"FIRST CONTACT",
		"CLOSEST",
		"HEAVIEST",
		"OBJECTIVE THREATS",
	]))
	_set_terminal_rich_text(terminal_defense_coverage_body, "\n".join(_build_terminal_defense_coverage_lines(snapshot.get("sectors", []))))


func _render_terminal_sensors_widgets(threat_text: Variant, hostile_text: String, wave_text: String, assault_value: Variant, sector_array: Array) -> void:
	_set_terminal_rich_text(terminal_sensors_fidelity_body, "\n".join([
		_terminal_kv("THREAT", threat_text),
		_terminal_kv("HOSTILES", hostile_text),
		_terminal_kv("WAVE", wave_text),
		_terminal_kv("MODE", "FULL COMMAND CLARITY"),
	]))
	_set_terminal_rich_text(terminal_sensors_prediction_body, "\n".join([
		"LIKELY INGRESS AXIS  %s" % str(assault_value),
		"WAVE PROFILE         %s" % wave_text,
		"CONTACT CONFIDENCE   HIGH",
	]))
	var activity_lines: Array[String] = []
	for sector_variant in sector_array:
		if not (sector_variant is Dictionary):
			continue
		var sector: Dictionary = sector_variant
		activity_lines.append("%-18s -> %s" % [
			_display_sector_name(str(sector.get("name", "SECTOR"))).to_upper(),
			str(sector.get("status", "UNKNOWN")).to_upper(),
		])
	if activity_lines.is_empty():
		activity_lines.append("NO SENSOR TAGS AVAILABLE")
	_set_terminal_rich_text(terminal_sensors_activity_body, "\n".join(activity_lines))


func _render_terminal_incidents_widgets() -> void:
	_set_terminal_rich_text(terminal_incidents_filter_body, "\n".join([
		"SEVERITY: ALL",
		"SECTOR:   ALL",
		"WINDOW:   LAST 10 MIN",
		"UNRESOLVED ONLY: OFF",
	]))
	var table_lines: Array[String] = [
		"TIME       LEVEL     SUMMARY",
		"---------  --------  ------------------------------",
	]
	var recent_entries := _terminal_log_entries.slice(max(0, _terminal_log_entries.size() - 8), _terminal_log_entries.size())
	for entry in recent_entries:
		table_lines.append("%-9s  %-8s  %s" % [
			str(entry.get("time", "--:--:--")),
			str(entry.get("level", "INFO")).to_upper(),
			str(entry.get("line", "")),
		])
	_set_terminal_rich_text(terminal_incidents_table_body, "\n".join(table_lines))


func _render_terminal_archive_widgets(contract: Dictionary) -> void:
	var world_profile: Dictionary = contract.get("world_profile", {})
	_set_terminal_rich_text(terminal_archive_integrity_body, "\n".join([
		_terminal_kv("STATE", "NOMINAL"),
		_terminal_kv("PLANET", str(contract.get("planet_key", "UNKNOWN")).to_upper()),
		_terminal_kv("PROFILE", str(world_profile.get("world_label", "UNCLASSIFIED")).to_upper()),
		_terminal_kv("SEEDS", "%s / %s" % [str(contract.get("planet_seed", "?")), str(contract.get("map_seed", "?"))]),
	]))
	_set_terminal_rich_text(terminal_archive_categories_body, "\n".join([
		"GOVERNANCE",
		"INFRASTRUCTURE",
		"WARFARE",
		"UNKNOWN",
	]))
	_set_terminal_rich_text(terminal_archive_detail_body, "\n".join([
		"FOLIAGE %.2f | OPEN %.2f | COMPOUND %.2f" % [
			float(world_profile.get("foliage_density", 0.0)),
			float(world_profile.get("open_layout_chance", 0.0)),
			float(world_profile.get("compound_area_ratio", 0.0)),
		],
		"STATUS: RECOVERED",
		"CONFIDENCE: HIGH",
	]))


func _render_terminal_recon_widgets(contract: Dictionary, assault_value: Variant, hostile_text: String) -> void:
	_set_terminal_rich_text(terminal_recon_hypothesis_body, "\n".join([
		_terminal_kv("SURFACE", str(contract.get("planet_key", "UNKNOWN")).to_upper()),
		_terminal_kv("ASSAULT AXIS", assault_value),
		_terminal_kv("HOSTILE MASS", hostile_text),
		_terminal_kv("CLARITY GAIN", "STATUS // SECTORS // POWER"),
	]))
	_set_terminal_rich_text(terminal_recon_targets_body, "\n".join([
		"HYP-01  SURFACE PATTERNING",
		"HYP-02  POWER DISTRIBUTION",
		"HYP-03  BREACH LANES",
	]))


func _render_terminal_contracts_widgets(contract_lines: Array[String], contract: Dictionary) -> void:
	_set_terminal_rich_text(terminal_contracts_slot_body, "\n".join(contract_lines))
	_set_terminal_rich_text(terminal_contracts_coupling_body, "\n".join([
		_terminal_kv("PROFILE", str(contract.get("world_profile", {}).get("world_label", "UNCLASSIFIED")).to_upper()),
		_terminal_kv("ROOMS", int(contract.get("room_count", 0))),
		_terminal_kv("SPAWNS", int(contract.get("corridor_spawn_count", 0))),
		_terminal_kv("REWARD", "ARCHIVE + MATERIALS"),
	]))


func _render_terminal_history_widgets() -> void:
	var lines: Array[String] = []
	for entry in _terminal_log_entries.slice(max(0, _terminal_log_entries.size() - 14), _terminal_log_entries.size()):
		lines.append("[%s] %s" % [str(entry.get("time", "--:--:--")), str(entry.get("line", ""))])
	if lines.is_empty():
		lines.append("NO COMMAND HISTORY AVAILABLE")
	_set_terminal_rich_text(terminal_history_log_body, "\n".join(lines))


func _render_terminal_status_widgets(snapshot: Dictionary, phase_text: String, threat_text: Variant, power_summary: String, assault_value: Variant, wave_text: String, hostile_text: String) -> void:
	_set_terminal_rich_text(terminal_status_raw_body, "\n".join([
		"MODE=COMMAND | FIDELITY=FULL | RATE=1X",
		"PHASE=%s | THREAT=%s | POWER=%s" % [phase_text, str(threat_text), power_summary],
		"ARCHIVE=NOMINAL | ASSAULT=%s | MATERIAL=%s" % [str(assault_value), str(snapshot.get("materials", 0))],
		"DEFENSE=%.1f | WAVE=%s | HOSTILES=%s" % [float(snapshot.get("defense_rating", 0.0)), wave_text, hostile_text],
	]))
	_set_terminal_rich_text(terminal_status_parsed_body, "\n".join([
		_terminal_kv("TIME", str(snapshot.get("time", "--:--:--"))),
		_terminal_kv("THREAT", _get_threat_band(float(snapshot.get("threat_raw", 0.0)))),
		_terminal_kv("ASSAULT", str(assault_value)),
		_terminal_kv("MATERIAL", int(snapshot.get("materials", 0))),
		_terminal_kv("FIDELITY", "FULL"),
	]))
	_set_terminal_rich_text(terminal_status_fidelity_body, "\n".join([
		"FULL        exact tactical truth",
		"DEGRADED    generalized counts, posture targets hidden",
		"FRAGMENTED  activity replaces certainty",
		"LOST        no usable network truth",
	]))


func _render_terminal_settings_widgets() -> void:
	_set_terminal_rich_text(terminal_settings_display_body, "\n".join([
		"TEXT SCALE      STANDARD",
		"LOG SPEED       LIVE",
		"COLORS          DEFAULT COMMAND",
		"POLICY         %s" % _terminal_policy_preset,
	]))
	_set_terminal_rich_text(terminal_settings_input_body, "\n".join([
		"MODE            KEYBOARD-FIRST",
		"COMMAND LINE    FOCUS LOCK",
		"CONFIRMATIONS   STANDARD",
		"FAB QUEUE       %s" % (", ".join(_terminal_fabrication_queue) if not _terminal_fabrication_queue.is_empty() else "EMPTY"),
	]))
	_set_terminal_rich_text(terminal_settings_map_body, "\n".join([
		"PLANET DRAG     ENABLED",
		"TACTICAL INPUT  ENABLED",
		"OVERLAYS        MANUAL",
	]))


func _render_terminal_main_content(snapshot: Dictionary) -> void:
	if terminal_map_label == null:
		return
	_set_terminal_widget_mode(_terminal_current_page)
	if terminal_map_title_label:
		terminal_map_title_label.text = _terminal_current_page
	if terminal_planet_title_label:
		terminal_planet_title_label.text = "PLANET CONTRACT // SURFACE GLOBE"
	if terminal_map_preview_title_label:
		terminal_map_preview_title_label.text = "TACTICAL FEED // LIVE MINIMAP"
	if terminal_command_title:
		terminal_command_title.text = "TRANSCRIPT"
	if terminal_planet_preview:
		terminal_planet_preview.visible = _terminal_current_page in ["OVERVIEW", "STATUS", "CONTRACTS", "ARCHIVE"]
	if terminal_planet_title_label:
		terminal_planet_title_label.visible = terminal_planet_preview != null and terminal_planet_preview.visible
	if terminal_map_preview:
		terminal_map_preview.visible = _terminal_current_page in ["OVERVIEW", "SECTORS", "POWER", "DEFENSE", "SENSORS", "INCIDENTS"]
	if terminal_map_preview_title_label:
		terminal_map_preview_title_label.visible = terminal_map_preview != null and terminal_map_preview.visible

	var lines: Array[String] = []
	var summary := "TACTICAL SUMMARY // LIVE CONTRACT SNAPSHOT"
	if snapshot.is_empty():
		lines.append_array(_terminal_card("LINK STATE", [
			_terminal_kv("PHASE", "NO LINK"),
			_terminal_kv("THREAT", "--"),
			_terminal_kv("ASSAULT", "--"),
			_terminal_kv("HOSTILES", "--"),
			_terminal_kv("MATERIAL", "--"),
		]))
		if terminal_page_summary_label:
			terminal_page_summary_label.text = "AWAITING LINK // NO SNAPSHOT AVAILABLE"
		if terminal_map_label is RichTextLabel:
			terminal_map_label.clear()
			terminal_map_label.append_text("\n".join(lines))
		else:
			terminal_map_label.text = "\n".join(lines)
		return

	var context := _build_terminal_render_context(snapshot)
	summary = _render_terminal_page(context)
	lines.append_array(_build_terminal_overlay_lines())

	if terminal_page_summary_label:
		terminal_page_summary_label.text = summary

	_render_terminal_text_output(lines)

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
		if "power_tier" in node:
			entry["power_tier"] = str(node.get("power_tier"))
		if "effective_output" in node:
			entry["effective_output"] = snapped(float(node.get("effective_output")) * 100.0, 0.1)
		if "power_priority" in node:
			entry["power_priority"] = int(node.get("power_priority"))
		if "power" in node and "standard_power_required" in node:
			entry["power_allocated"] = snapped(float(node.get("power")), 0.1)
			entry["power_standard"] = snapped(float(node.get("standard_power_required")), 0.1)
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


func _get_power_status_snapshot() -> Dictionary:
	var power_system = get_node_or_null("/root/GameRoot/Power")
	if power_system == null or not power_system.has_method("get_power_status"):
		return {}
	var status = power_system.call("get_power_status")
	return status if status is Dictionary else {}


func _resolve_power_priority(priority_name: String) -> int:
	match priority_name:
		"CRITICAL":
			return 100
		"HIGH":
			return 85
		"MEDIUM":
			return 60
		"LOW":
			return 35
		_:
			if priority_name.is_valid_int():
				return clampi(int(priority_name), 0, 100)
			return 60

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
		var power_status = _get_power_status_snapshot()
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
		if not power_status.is_empty():
			_append_terminal_line("POWER %d/%d | GEN %.1f/s | DRAW %.1f/s | NET %+0.1f/s" % [
				int(round(float(power_status.get("total", 0.0)))),
				int(round(float(power_status.get("max", 0.0)))),
				float(power_status.get("generated", 0.0)) * 60.0,
				float(power_status.get("consumed", 0.0)) * 60.0,
				float(power_status.get("net", 0.0)) * 60.0,
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
		var assault_game_state := _get_game_state()
		if assault_game_state == null:
			_append_terminal_line("CONTRACT STATE UNAVAILABLE", "warning")
			return true
		if assault_game_state.start_assault():
			_append_terminal_line("ASSAULT INITIATED. DEFEND THE COMPOUND.", "critical")
		else:
			_append_terminal_line("ASSAULT NOT AVAILABLE IN PHASE %s" % assault_game_state.get_phase_name(), "warning")
		return true
	if cmd_upper == "HELP ASSAULT":
		_append_terminal_line("ASSAULT COMMANDS: STATUS FULL, WAVE, ENEMIES, SECTORS, START ASSAULT", "info")
		_append_terminal_line("START ASSAULT is only valid during FREE_ROAM_PREP.", "info")
		return true
	if cmd_upper == "HELP PREP":
		_append_terminal_line("PREP COMMANDS: STATUS, CONTRACT, MAP, SECTORS, WALL, TURRET <TYPE>, START ASSAULT", "info")
		_append_terminal_line("FREE_ROAM_PREP keeps waves inactive until you trigger the assault.", "info")
		_append_terminal_line("WALL and TURRET placement can be placed directly in the world once placement mode is active.", "info")
		return true
	if cmd_upper == "HELP STATUS":
		_append_terminal_line("STATUS: quick snapshot refresh.", "info")
		_append_terminal_line("STATUS FULL: contract phase + snapshot + wave + enemy summary lines.", "info")
		_append_terminal_line("CONTRACT/PLANET/MAP: active contract metadata.", "info")
		_append_terminal_line("SECTORS: shows power tier, effective output, and priority.", "info")
		_append_terminal_line("REROUTE POWER sector=<NAME> priority=CRITICAL|HIGH|MEDIUM|LOW", "info")
		return true

	match verb:
		"HELP":
			_append_terminal_line("LOCAL COMMANDS: HELP STATUS PREP ENEMIES WAVE SECTORS CONTRACT PLANET MAP START ASSAULT WALL TURRET REROUTE CLEAR OVERLAY RESET REBOOT", "info")
			_append_terminal_line("ACTIONS: WAIT | WAIT 10X | GOTO <PAGE> | HARDEN <SECTOR> | FOCUS <TARGET>", "info")
			_append_terminal_line("LIVE CONTROL: ALLOCATE_DEFENSE sector=COMMAND weight=HIGH | DEPLOY turret_sniper sector=COMMAND | REPAIR COMMAND", "info")
			return true
		"GOTO":
			if args.is_empty():
				_append_terminal_line("USE: GOTO <PAGE>", "warning")
				return true
			var page_name := str(args[0]).to_upper()
			if not _terminal_page_buttons.has(page_name):
				_append_terminal_line("UNKNOWN PAGE %s" % page_name, "warning")
				return true
			_set_terminal_page(page_name)
			_append_terminal_line("PAGE OPEN -> %s" % page_name, "success")
			return true
		"WAIT":
			var target_scale := 2.0
			if not args.is_empty() and str(args[0]).to_upper() == "10X":
				target_scale = 10.0
			_set_terminal_time_scale(target_scale)
			_append_terminal_line("TIME RATE SET -> %s // LIVE SIMULATION" % _format_terminal_rate(Engine.time_scale), "success")
			_refresh_snapshot()
			return true
	"HARDEN":
		var requested_target := str(args[0]).to_upper() if not args.is_empty() else "COMMAND"
		var harden_target := _resolve_terminal_sector_name(requested_target)
		if harden_target.is_empty():
			_append_terminal_line("UNKNOWN HARDEN TARGET %s" % requested_target, "warning")
			return true
		_terminal_highlight_sector = harden_target
		var harden_power_system := get_node_or_null("/root/GameRoot/Power")
		if harden_power_system != null and harden_power_system.has_method("set_sector_priority"):
			harden_power_system.call("set_sector_priority", harden_target, 100)
		var harden_repair_result: Dictionary = {}
		if harden_power_system != null and harden_power_system.has_method("apply_emergency_repair"):
			var response = harden_power_system.call("apply_emergency_repair", harden_target)
			if response is Dictionary:
				harden_repair_result = response
		_set_terminal_page("DEFENSE")
		if harden_repair_result.is_empty():
			_append_terminal_line("HARDENED %s // PRIORITY RAISED TO CRITICAL" % harden_target, "success", harden_target)
		elif bool(harden_repair_result.get("available", false)) and str(harden_repair_result.get("reason", "")) == "APPLIED":
			_append_terminal_line("HARDENED %s // REPAIRED +%.1f HP // PRIORITY CRITICAL" % [
				harden_target,
				float(harden_repair_result.get("repair_amount", 0.0)),
			], "success", harden_target)
		else:
			_append_terminal_line("HARDENED %s // PRIORITY CRITICAL // REPAIR %s" % [
				harden_target,
				str(harden_repair_result.get("reason", "UNAVAILABLE")),
			], "warning", harden_target)
		_refresh_snapshot()
		return true
		"RESET":
			_reset_terminal_local_state(false)
			_append_terminal_line("TERMINAL STATE RESET // OVERLAYS CLEARED // RATE %s" % _format_terminal_rate(Engine.time_scale), "success")
			_refresh_snapshot()
			return true
		"REBOOT":
			_reset_terminal_local_state(true)
			_append_terminal_line("COMMAND LINK REBOOT COMPLETE // LOCAL CONTROL RESTORED", "success")
			_refresh_snapshot()
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
				_append_terminal_line("%s | %s | HP %s%% | PWR %s %.0f%% | PRI %s" % [
					str(sector.get("name", "SECTOR")),
					str(sector.get("status", "unknown")).to_upper(),
					str(sector.get("hp_pct", "?")),
					str(sector.get("power_tier", "UNKNOWN")).to_upper(),
					float(sector.get("effective_output", 0.0)),
					str(sector.get("power_priority", "?")),
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
				_append_terminal_line("1=BARRICADE 2=WALL 3=REINFORCED 4=DOUBLE | LEFT CLICK IN WORLD TO PLACE | TAB ROTATES", "info")
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
			var turret_place_type := str(args[0]).to_lower()
			if not turret_placement.has_method("enter_placement_mode"):
				_append_terminal_line("TURRET PLACEMENT API MISSING", "warning")
				return true
			if turret_placement.call("enter_placement_mode", turret_place_type):
				_append_terminal_line("TURRET PLACEMENT ACTIVE // %s" % turret_place_type.to_upper(), "success")
				_append_terminal_line("LEFT CLICK IN WORLD TO PLACE // B CYCLES TYPES // Q OR ESC TO EXIT", "info")
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
		var defense_sector_name := str(params.get("sector", "COMMAND")).to_upper()
		var weight := str(params.get("weight", "MEDIUM")).to_upper()
		var resolved_sector := _resolve_terminal_sector_name(defense_sector_name)
		if resolved_sector.is_empty():
			_append_terminal_line("UNKNOWN SECTOR %s" % defense_sector_name, "warning")
			return true
		_terminal_highlight_sector = resolved_sector
		var defense_priority_value := _resolve_power_priority(weight)
		var defense_power_system := get_node_or_null("/root/GameRoot/Power")
		if defense_power_system != null and defense_power_system.has_method("set_sector_priority"):
			defense_power_system.call("set_sector_priority", resolved_sector, defense_priority_value)
		_set_terminal_page("DEFENSE")
		_append_terminal_line("DEFENSE PRIORITY UPDATED %s -> %s (%d)" % [resolved_sector, weight, defense_priority_value], "success", resolved_sector)
		_refresh_snapshot()
		return true
		"DEPLOY":
			if args.is_empty():
				_append_terminal_line("USE: DEPLOY <TURRET_TYPE> x=<WORLD_X> y=<WORLD_Y> OR sector=<SECTOR>", "warning")
				return true
			if str(args[0]).to_upper() == "DRONE":
				_set_terminal_page("RECON")
				_terminal_overlay_flags["path"] = true
				_append_terminal_line("RECON DEPLOY PLAN OPENED // DRONE SUPPORT NOT YET A PHYSICAL RUNTIME UNIT", "success")
				_refresh_snapshot()
				return true
			var deploy_turret_type := _resolve_terminal_turret_type(str(args[0]))
			if deploy_turret_type.is_empty():
				_append_terminal_line("UNKNOWN DEPLOY TYPE %s" % str(args[0]).to_upper(), "warning")
				return true
			var fallback_sector := str(args[1]) if args.size() > 1 else ""
			var target := _resolve_terminal_target_position(params, fallback_sector)
			if not bool(target.get("ok", false)):
				_append_terminal_line("DEPLOY REQUIRES x=<WORLD_X> y=<WORLD_Y> OR sector=<SECTOR>", "warning")
				return true
			var deploy_result := _attempt_terminal_turret_deploy(deploy_turret_type, target)
			if bool(deploy_result.get("ok", false)):
				_set_terminal_page("DEFENSE")
				_append_terminal_line("DEPLOYED %s // %s @ %s" % [
					deploy_turret_type.to_upper(),
					str(target.get("source", "TARGET")).to_upper(),
					str(deploy_result.get("position", Vector2.ZERO)),
				], "success")
				_refresh_snapshot()
			else:
				_append_terminal_line("DEPLOY FAILED // %s" % str(deploy_result.get("reason", "UNKNOWN")), "warning")
			return true
		"REPAIR":
			var repair_target := str(args[0]) if not args.is_empty() else str(params.get("sector", _terminal_highlight_sector if not _terminal_highlight_sector.is_empty() else "COMMAND"))
			var repair_result := _apply_terminal_emergency_repair(repair_target)
			if bool(repair_result.get("ok", false)):
				_set_terminal_page("SECTORS")
				_terminal_highlight_sector = str(repair_result.get("sector", ""))
				_append_terminal_line("REPAIRED %s // +%.1f HP" % [
					str(repair_result.get("sector", "UNKNOWN")),
					float(repair_result.get("repair_amount", 0.0)),
				], "success", str(repair_result.get("sector", "")))
				_refresh_snapshot()
			else:
				_append_terminal_line("REPAIR FAILED // %s" % str(repair_result.get("reason", "UNKNOWN")), "warning")
			return true
		"MOVE":
			var move_target := str(args[0]).to_upper() if not args.is_empty() else "SECTORS"
			if _terminal_page_buttons.has(move_target):
				_set_terminal_page(move_target)
				_append_terminal_line("MOVED VIEW -> %s" % move_target, "success")
				return true
			var move_sector := _resolve_terminal_sector_name(move_target)
			if not move_sector.is_empty():
				_terminal_highlight_sector = move_sector
				_set_terminal_page("SECTORS")
				_append_terminal_line("MOVED FOCUS -> %s" % _display_sector_name(move_sector).to_upper(), "success", move_sector)
				_refresh_snapshot()
				return true
			_append_terminal_line("UNKNOWN MOVE TARGET %s" % move_target, "warning")
			return true
		"RETURN":
			_cancel_active_placement_mode()
			_terminal_highlight_sector = ""
			_set_terminal_page("OVERVIEW")
			_append_terminal_line("RETURNED TO COMMAND OVERVIEW", "success")
			_refresh_snapshot()
			return true
		"SYNC":
			_ensure_terminal_contract_binding()
			_refresh_snapshot()
			_append_terminal_line("COMMAND LINK SYNCHRONIZED // SNAPSHOT REFRESHED", "success")
			return true
		"LOCKDOWN":
			var lockdown_target := str(args[0]).to_upper() if not args.is_empty() else "ALL"
			_terminal_overlay_flags["threat"] = true
			_terminal_overlay_flags["repair"] = true
			_terminal_overlay_flags["path"] = false
			_terminal_overlay_flags["power"] = false
			if lockdown_target == "ALL":
				for sector_variant in _collect_sector_snapshot():
					if not (sector_variant is Dictionary):
						continue
					_apply_terminal_sector_priority(str((sector_variant as Dictionary).get("name", "")), "CRITICAL")
				_set_terminal_page("DEFENSE")
				_append_terminal_line("LOCKDOWN APPLIED // ALL SECTOR PRIORITIES CRITICAL", "critical")
			else:
				var lock_result := _apply_terminal_sector_priority(lockdown_target, "CRITICAL")
				if bool(lock_result.get("ok", false)):
					_terminal_highlight_sector = str(lock_result.get("sector", ""))
					_set_terminal_page("DEFENSE")
					_append_terminal_line("LOCKDOWN APPLIED // %s" % str(lock_result.get("sector", "UNKNOWN")), "critical", str(lock_result.get("sector", "")))
				else:
					_append_terminal_line("LOCKDOWN FAILED // %s" % str(lock_result.get("reason", "UNKNOWN")), "warning")
			_refresh_snapshot()
			return true
		"FORTIFY":
			var fortify_target := str(args[0]) if not args.is_empty() else "COMMAND"
			var fortify_result := _apply_terminal_sector_priority(fortify_target, "CRITICAL")
			if bool(fortify_result.get("ok", false)):
				_terminal_highlight_sector = str(fortify_result.get("sector", ""))
				_set_terminal_page("DEFENSE")
				_append_terminal_line("FORTIFY APPLIED // %s PRIORITY CRITICAL" % str(fortify_result.get("sector", "UNKNOWN")), "success", str(fortify_result.get("sector", "")))
				_refresh_snapshot()
			else:
				_append_terminal_line("FORTIFY FAILED // %s" % str(fortify_result.get("reason", "UNKNOWN")), "warning")
			return true
		"BOOST":
			if not args.is_empty() and str(args[0]).to_upper() == "DEFENSE":
				_terminal_overlay_flags["threat"] = true
				_terminal_overlay_flags["repair"] = true
				_set_terminal_page("DEFENSE")
				_append_terminal_line("DEFENSE BOOST MODE ENABLED", "success")
				_refresh_snapshot()
				return true
			_append_terminal_line("UNKNOWN BOOST TARGET", "warning")
			return true
		"SCAN":
			if not args.is_empty() and str(args[0]).to_upper() == "RELAYS":
				_terminal_overlay_flags["path"] = true
				_terminal_overlay_flags["threat"] = true
				_set_terminal_page("SENSORS")
				_refresh_snapshot()
				_append_terminal_line("RELAY SCAN COMPLETE // SENSOR PAGE OPEN", "success")
				return true
			_append_terminal_line("UNKNOWN SCAN TARGET", "warning")
			return true
		"STABILIZE":
			if not args.is_empty() and str(args[0]).to_upper() == "RELAY":
				var relay_target := str(args[1]) if args.size() > 1 else str(params.get("sector", "COMMS"))
				var relay_priority := _apply_terminal_sector_priority(relay_target, "CRITICAL")
				var relay_repair := _apply_terminal_emergency_repair(relay_target)
				if bool(relay_priority.get("ok", false)):
					_terminal_highlight_sector = str(relay_priority.get("sector", ""))
					_set_terminal_page("SENSORS")
					_append_terminal_line("RELAY STABILIZED // %s // REPAIR %s" % [
						str(relay_priority.get("sector", "UNKNOWN")),
						str(relay_repair.get("reason", "UNAVAILABLE")),
					], "success", str(relay_priority.get("sector", "")))
					_refresh_snapshot()
				else:
					_append_terminal_line("STABILIZE RELAY FAILED // %s" % str(relay_priority.get("reason", "UNKNOWN")), "warning")
				return true
			_append_terminal_line("UNKNOWN STABILIZE TARGET", "warning")
			return true
		"PRIORITIZE":
			if not args.is_empty() and str(args[0]).to_upper() == "REPAIR":
				_terminal_overlay_flags["repair"] = true
				var repair_focus := str(args[1]) if args.size() > 1 else str(params.get("sector", _terminal_highlight_sector))
				if not repair_focus.is_empty():
					var prioritized_sector := _resolve_terminal_sector_name(repair_focus)
					if not prioritized_sector.is_empty():
						_terminal_highlight_sector = prioritized_sector
				_set_terminal_page("SECTORS")
				_append_terminal_line("REPAIR PRIORITY ENABLED", "success", _terminal_highlight_sector)
				_refresh_snapshot()
				return true
			_append_terminal_line("UNKNOWN PRIORITIZE TARGET", "warning")
			return true
		"DRONE":
			if not args.is_empty() and str(args[0]).to_upper() == "DEPLOY":
				_set_terminal_page("RECON")
				_terminal_overlay_flags["path"] = true
				_append_terminal_line("DRONE RECON MODE ENABLED", "success")
				_refresh_snapshot()
				return true
			_append_terminal_line("UNKNOWN DRONE TARGET", "warning")
			return true
		"POLICY":
			if args.is_empty() or str(args[0]).to_upper() == "SHOW":
				_set_terminal_page("SETTINGS")
				_append_terminal_line("POLICY PRESET=%s | RATE=%s" % [_terminal_policy_preset, _format_terminal_rate(Engine.time_scale)], "info")
				return true
			if str(args[0]).to_upper() == "PRESET":
				var preset_name := str(args[1]).to_upper() if args.size() > 1 else str(params.get("name", "BALANCED")).to_upper()
				_apply_terminal_policy_preset(preset_name)
				_append_terminal_line("POLICY PRESET APPLIED -> %s" % _terminal_policy_preset, "success")
				_refresh_snapshot()
				return true
			_append_terminal_line("UNKNOWN POLICY COMMAND", "warning")
			return true
		"CONFIG":
			if not args.is_empty() and str(args[0]).to_upper() == "DOCTRINE":
				_set_terminal_page("SETTINGS")
				_append_terminal_line("DOCTRINE CONFIG OPENED", "success")
				return true
			_append_terminal_line("UNKNOWN CONFIG TARGET", "warning")
			return true
		"SET":
			if not args.is_empty() and str(args[0]).to_upper() == "FAB":
				_set_terminal_page("SETTINGS")
				var fab_profile := str(args[1]).to_upper() if args.size() > 1 else "STANDARD"
				_append_terminal_line("FAB PROFILE SET -> %s" % fab_profile, "success")
				return true
			_append_terminal_line("UNKNOWN SET TARGET", "warning")
			return true
		"FAB":
			var fab_action := str(args[0]).to_upper() if not args.is_empty() else "QUEUE"
			var fab_payload := " ".join(args.slice(1, args.size()))
			match fab_action:
				"ADD":
					if fab_payload.is_empty():
						_append_terminal_line("FAB ADD REQUIRES AN ITEM NAME", "warning")
						return true
					_terminal_fabrication_queue.append(fab_payload)
					_set_terminal_page("SETTINGS")
					_append_terminal_line("FAB QUEUE ADD -> %s" % fab_payload, "success")
				"QUEUE":
					_set_terminal_page("SETTINGS")
					_append_terminal_line("FAB QUEUE: %s" % (", ".join(_terminal_fabrication_queue) if not _terminal_fabrication_queue.is_empty() else "EMPTY"), "info")
				"CANCEL":
					if _terminal_fabrication_queue.is_empty():
						_append_terminal_line("FAB QUEUE ALREADY EMPTY", "warning")
					else:
						var cancelled: String = str(_terminal_fabrication_queue.pop_back())
						_append_terminal_line("FAB CANCELLED -> %s" % cancelled, "success")
				"PRIORITY":
					_set_terminal_page("SETTINGS")
					_append_terminal_line("FAB PRIORITY -> %s" % (fab_payload if not fab_payload.is_empty() else "STANDARD"), "success")
				_:
					_append_terminal_line("UNKNOWN FAB COMMAND", "warning")
			return true
	"SCAVENGE":
		var salvage_gain := 5
		var salvage_game_state := _get_game_state()
		if salvage_game_state != null and salvage_game_state.has_method("add_materials"):
			salvage_game_state.add_materials(salvage_gain)
		_set_terminal_page("RECON")
		_append_terminal_line("SCAVENGE COMPLETE // +%d MATERIALS" % salvage_gain, "success")
		_refresh_snapshot()
		return true
		"FOCUS":
			var focus_target := str(args[0]).to_upper() if not args.is_empty() else "SYSTEM"
			var priority := str(params.get("priority", "NORMAL")).to_upper()
			if _terminal_page_buttons.has(focus_target):
				_set_terminal_page(focus_target)
				_append_terminal_line("FOCUS SHIFTED TO PAGE %s" % focus_target, "success")
				return true
			var sector_target := _resolve_terminal_sector_name(focus_target)
			if not sector_target.is_empty():
				_terminal_highlight_sector = sector_target
				_set_terminal_page("SECTORS")
				_append_terminal_line("FOCUS SHIFTED TO %s" % _display_sector_name(sector_target).to_upper(), "success", sector_target)
				_refresh_snapshot()
				return true
			if _terminal_overlay_flags.has(focus_target.to_lower()):
				for key in _terminal_overlay_flags.keys():
					_terminal_overlay_flags[key] = key == focus_target.to_lower()
				_append_terminal_line("FOCUS FILTER -> %s OVERLAY" % focus_target, "success")
				_refresh_snapshot()
				return true
			_append_terminal_line("FOCUS ACKNOWLEDGED target=%s priority=%s" % [focus_target, priority], "success")
			return true
	"REROUTE":
		if args.is_empty() or str(args[0]).to_upper() != "POWER":
			_append_terminal_line("USE: REROUTE POWER sector=COMMAND priority=CRITICAL|HIGH|MEDIUM|LOW", "warning")
			return true
		var reroute_sector_name := str(params.get("sector", "")).strip_edges().to_upper()
		if reroute_sector_name.is_empty():
			_append_terminal_line("REROUTE POWER REQUIRES sector=<SECTOR_NAME>", "warning")
			return true
		var priority_name := str(params.get("priority", "HIGH")).strip_edges().to_upper()
		var reroute_priority_value := _resolve_power_priority(priority_name)
		var reroute_power_system := get_node_or_null("/root/GameRoot/Power")
		if reroute_power_system == null or not reroute_power_system.has_method("set_sector_priority"):
			_append_terminal_line("POWER ROUTING UNAVAILABLE", "warning")
			return true
		if reroute_power_system.call("set_sector_priority", reroute_sector_name, reroute_priority_value):
			_append_terminal_line("POWER PRIORITY UPDATED %s -> %s (%d)" % [reroute_sector_name, priority_name, reroute_priority_value], "success", reroute_sector_name)
			_refresh_snapshot()
		else:
			_append_terminal_line("UNKNOWN SECTOR %s" % reroute_sector_name, "warning")
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
			if button_event.ctrl_pressed:
				_planet_preview_zoom_distance = max(PLANET_PREVIEW_ZOOM_MIN, _planet_preview_zoom_distance - PLANET_PREVIEW_ZOOM_STEP)
				_apply_terminal_planet_zoom()
			else:
				_scroll_terminal_main_by(-96)
			terminal_planet_preview.accept_event()
			return
		if button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and button_event.pressed:
			if button_event.ctrl_pressed:
				_planet_preview_zoom_distance = min(PLANET_PREVIEW_ZOOM_MAX, _planet_preview_zoom_distance + PLANET_PREVIEW_ZOOM_STEP)
				_apply_terminal_planet_zoom()
			else:
				_scroll_terminal_main_by(96)
			terminal_planet_preview.accept_event()
			return
		if button_event.button_index == MOUSE_BUTTON_LEFT:
			_planet_preview_drag_active = button_event.pressed
			_planet_preview_drag_last_pos = button_event.position
			if button_event.pressed:
				if terminal_input:
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
	if event is InputEventMouseButton:
		var scroll_event := event as InputEventMouseButton
		if scroll_event.button_index == MOUSE_BUTTON_WHEEL_UP and scroll_event.pressed:
			_scroll_terminal_main_by(-96)
			terminal_map_preview.accept_event()
			return
		if scroll_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and scroll_event.pressed:
			_scroll_terminal_main_by(96)
			terminal_map_preview.accept_event()
			return
	if event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		var hover_world_pos := _terminal_map_local_to_world(motion_event.position)
		_terminal_map_hover_world_pos = hover_world_pos
		_update_terminal_map_placement_preview(hover_world_pos)
		terminal_map_preview.accept_event()
		return
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		var click_world_pos := _terminal_map_local_to_world(button_event.position)
		_terminal_map_hover_world_pos = click_world_pos
		if button_event.button_index == MOUSE_BUTTON_LEFT and button_event.pressed:
			if _apply_terminal_map_placement(click_world_pos):
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


func _resolve_terminal_sector_name(raw_name: String) -> String:
	var needle := raw_name.strip_edges().to_upper()
	if needle.is_empty():
		return ""
	var sectors := _collect_sector_snapshot()
	for sector_variant in sectors:
		if not (sector_variant is Dictionary):
			continue
		var sector: Dictionary = sector_variant
		var sector_name := str(sector.get("name", "")).strip_edges().to_upper()
		if sector_name == needle:
			return sector_name
		if _display_sector_name(sector_name).to_upper() == needle:
			return sector_name
		if sector_name.replace("_", " ").to_upper() == needle:
			return sector_name
	if SECTOR_DISPLAY_NAMES.has(needle):
		var display_name := str(SECTOR_DISPLAY_NAMES[needle]).to_upper()
		for sector_variant in sectors:
			if not (sector_variant is Dictionary):
				continue
			var mapped_sector: Dictionary = sector_variant
			var mapped_sector_name := str(mapped_sector.get("name", "")).strip_edges().to_upper()
			if _display_sector_name(mapped_sector_name).to_upper() == display_name:
				return mapped_sector_name
	return ""


func _set_terminal_time_scale(rate: float) -> void:
	Engine.time_scale = clampf(rate, 0.1, 10.0)
	_last_time_scale = -1.0


func _reset_terminal_local_state(include_boot_lines: bool) -> void:
	_set_terminal_time_scale(1.0)
	_terminal_highlight_sector = ""
	for key in _terminal_overlay_flags.keys():
		_terminal_overlay_flags[key] = key == "threat"
	_set_terminal_page("OVERVIEW")
	if _terminal_main_scroll != null and is_instance_valid(_terminal_main_scroll):
		_terminal_main_scroll.scroll_vertical = 0
	_terminal_command_queue.clear()
	_terminal_command_inflight = false
	_terminal_completion_matches.clear()
	_terminal_completion_index = -1
	_terminal_completion_seed = ""
	if include_boot_lines:
		_terminal_lines = TERMINAL_BOOT_LINES.duplicate()
		_terminal_log_entries.clear()
		_render_terminal_output()


func _find_terminal_sector_snapshot(raw_name: String) -> Dictionary:
	var resolved_name := _resolve_terminal_sector_name(raw_name)
	if resolved_name.is_empty():
		return {}
	for sector_variant in _collect_sector_snapshot():
		if not (sector_variant is Dictionary):
			continue
		var sector: Dictionary = sector_variant
		if str(sector.get("name", "")).strip_edges().to_upper() == resolved_name:
			return sector
	return {}


func _get_terminal_sector_world_pos(raw_name: String) -> Variant:
	var sector := _find_terminal_sector_snapshot(raw_name)
	var world_pos = sector.get("world_pos", null)
	if world_pos is Vector2:
		return world_pos
	return null


func _apply_terminal_emergency_repair(raw_name: String) -> Dictionary:
	var resolved_name := _resolve_terminal_sector_name(raw_name)
	if resolved_name.is_empty():
		return {"ok": false, "reason": "UNKNOWN_SECTOR"}
	var power_system := get_node_or_null("/root/GameRoot/Power")
	if power_system == null or not power_system.has_method("apply_emergency_repair"):
		return {"ok": false, "reason": "POWER_UNAVAILABLE", "sector": resolved_name}
	var result = power_system.call("apply_emergency_repair", resolved_name)
	if result is Dictionary:
		var response: Dictionary = result
		response["ok"] = str(response.get("reason", "")) == "APPLIED"
		response["sector"] = resolved_name
		return response
	return {"ok": false, "reason": "UNKNOWN", "sector": resolved_name}


func _apply_terminal_sector_priority(raw_name: String, priority_name: String) -> Dictionary:
	var resolved_name := _resolve_terminal_sector_name(raw_name)
	if resolved_name.is_empty():
		return {"ok": false, "reason": "UNKNOWN_SECTOR"}
	var power_system := get_node_or_null("/root/GameRoot/Power")
	if power_system == null or not power_system.has_method("set_sector_priority"):
		return {"ok": false, "reason": "POWER_UNAVAILABLE", "sector": resolved_name}
	var priority_value := _resolve_power_priority(priority_name)
	var changed := bool(power_system.call("set_sector_priority", resolved_name, priority_value))
	return {
		"ok": changed,
		"sector": resolved_name,
		"priority_name": priority_name,
		"priority_value": priority_value,
	}


func _resolve_terminal_turret_type(raw_name: String) -> String:
	var key := raw_name.strip_edges().to_lower()
	match key:
		"gunner", "turret_gunner", "tg":
			return "gunner"
		"blaster", "turret_blaster", "tb":
			return "blaster"
		"repeater", "turret_repeater", "tr":
			return "repeater"
		"sniper", "turret_sniper", "ts":
			return "sniper"
		_:
			return ""


func _resolve_terminal_target_position(params: Dictionary, fallback_sector: String = "") -> Dictionary:
	var x_raw := str(params.get("x", "")).strip_edges()
	var y_raw := str(params.get("y", "")).strip_edges()
	if x_raw.is_valid_float() and y_raw.is_valid_float():
		return {"ok": true, "position": Vector2(x_raw.to_float(), y_raw.to_float()), "source": "coordinates"}
	var sector_name := str(params.get("sector", fallback_sector)).strip_edges()
	if sector_name.is_empty():
		sector_name = _terminal_highlight_sector
	if not sector_name.is_empty():
		var anchor = _get_terminal_sector_world_pos(sector_name)
		if anchor is Vector2:
			return {"ok": true, "position": anchor, "source": "sector", "sector": _resolve_terminal_sector_name(sector_name)}
	if _terminal_map_hover_world_pos != Vector2.ZERO:
		return {"ok": true, "position": _terminal_map_hover_world_pos, "source": "hover"}
	return {"ok": false, "reason": "MISSING_TARGET"}


func _attempt_terminal_turret_deploy(turret_type: String, target: Dictionary) -> Dictionary:
	var placement := get_node_or_null("/root/GameRoot/World/TurretPlacement")
	if placement == null:
		return {"ok": false, "reason": "PLACEMENT_UNAVAILABLE"}
	if not placement.has_method("enter_placement_mode") or not placement.has_method("attempt_place_turret_at"):
		return {"ok": false, "reason": "PLACEMENT_API_MISSING"}
	if not placement.call("enter_placement_mode", turret_type):
		return {"ok": false, "reason": "ENTER_FAILED"}
	var anchor: Vector2 = target.get("position", Vector2.ZERO)
	var attempts: Array[Vector2] = [
		Vector2.ZERO,
		Vector2(64, 0), Vector2(-64, 0), Vector2(0, 64), Vector2(0, -64),
		Vector2(64, 64), Vector2(-64, 64), Vector2(64, -64), Vector2(-64, -64),
	]
	for offset in attempts:
		var world_pos := anchor + offset
		if bool(placement.call("attempt_place_turret_at", world_pos)):
			return {"ok": true, "position": world_pos, "source": target.get("source", "unknown")}
	placement.call("exit_placement_mode")
	return {"ok": false, "reason": "INVALID_POSITION"}


func _apply_terminal_policy_preset(preset_name: String) -> void:
	var normalized := preset_name.strip_edges().to_upper()
	match normalized:
		"DEFENSE", "FORTIFY":
			_terminal_policy_preset = "DEFENSE"
			_terminal_overlay_flags["threat"] = true
			_terminal_overlay_flags["repair"] = true
			_terminal_overlay_flags["power"] = false
			_terminal_overlay_flags["path"] = false
			_set_terminal_page("DEFENSE")
		"SCAN", "RECON":
			_terminal_policy_preset = "SCAN"
			_terminal_overlay_flags["threat"] = true
			_terminal_overlay_flags["path"] = true
			_terminal_overlay_flags["power"] = false
			_terminal_overlay_flags["repair"] = false
			_set_terminal_page("SENSORS")
		"POWER":
			_terminal_policy_preset = "POWER"
			_terminal_overlay_flags["power"] = true
			_terminal_overlay_flags["path"] = false
			_terminal_overlay_flags["threat"] = true
			_terminal_overlay_flags["repair"] = false
			_set_terminal_page("POWER")
		_:
			_terminal_policy_preset = "BALANCED"
			_terminal_overlay_flags["power"] = false
			_terminal_overlay_flags["path"] = false
			_terminal_overlay_flags["threat"] = true
			_terminal_overlay_flags["repair"] = false
			_set_terminal_page("OVERVIEW")

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
