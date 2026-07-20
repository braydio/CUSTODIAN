extends CanvasLayer

const TerminalCommandRouterScript := preload("res://game/ui/terminal/terminal_command_router.gd")
const TerminalSnapshotScript := preload("res://game/ui/terminal/terminal_snapshot.gd")
const TerminalStatusFormatterScript := preload("res://game/ui/terminal/terminal_status_formatter.gd")
const TerminalOverviewViewModelScript := preload("res://game/ui/terminal/terminal_overview_view_model.gd")
const TerminalFabricationViewModelScript := preload("res://game/ui/terminal/fabrication_terminal_view_model.gd")
const TerminalMapPreviewScript := preload("res://game/ui/terminal/terminal_map_preview.gd")
const TerminalPlanetPreviewScript := preload("res://game/ui/terminal/terminal_planet_preview.gd")
const DebugScreenScene := preload("res://game/ui/hud/debug_screen.tscn")

const TERMINAL_PANEL_FRAME_TEXTURE := preload("res://content/ui/terminal/panels/panel_frame_medium_9slice.png")
const TERMINAL_HEADER_ACTIVE_TEXTURE := preload("res://content/ui/terminal/overlays/Header_Bar_Active.png")
const TERMINAL_HEADER_WARNING_TEXTURE := preload("res://content/ui/terminal/overlays/Header_Bar_Warning.png")
const TERMINAL_NAV_IDLE_TEXTURE := preload("res://content/ui/terminal/nav/nav_tab_idle_9slice.png")
const TERMINAL_NAV_HOVER_TEXTURE := preload("res://content/ui/terminal/nav/nav_tab_hover_9slice.png")
const TERMINAL_NAV_ACTIVE_TEXTURE := preload("res://content/ui/terminal/nav/nav_tab_active_9slice.png")
const TERMINAL_NAV_DISABLED_TEXTURE := preload("res://content/ui/terminal/nav/nav_tab_disabled_9slice.png")
const TERMINAL_BUTTON_IDLE_TEXTURE := preload("res://content/ui/terminal/buttons/button_idle_9slice.png")
const TERMINAL_BUTTON_HOVER_TEXTURE := preload("res://content/ui/terminal/buttons/button_hover_9slice.png")
const TERMINAL_BUTTON_PRESSED_TEXTURE := preload("res://content/ui/terminal/buttons/button_pressed_9slice.png")
const TERMINAL_BUTTON_DISABLED_TEXTURE := preload("res://content/ui/terminal/buttons/button_disabled_9slice.png")
const TERMINAL_COMMAND_LINE_TEXTURE := preload("res://content/ui/terminal/command_line/command_line_frame_9slice.png")
const TERMINAL_MAP_FRAME_TEXTURE := preload("res://content/ui/terminal/map/map_frame_large_9slice.png")
const TERMINAL_SCANLINE_TEXTURE := preload("res://content/ui/terminal/overlays/terminal_scanline_overlay.png")
const TERMINAL_NOISE_TEXTURE := preload("res://content/ui/terminal/overlays/terminal_noise_overlay.png")
const TERMINAL_ICON_CONTRACT := preload("res://content/ui/terminal/icons/icon_contract.png")
const TERMINAL_ICON_DEFENSE := preload("res://content/ui/terminal/icons/icon_defense.png")
const TERMINAL_ICON_FABRICATION := preload("res://content/ui/terminal/icons/icon_fabrication.png")
const TERMINAL_ICON_MAP := preload("res://content/ui/terminal/icons/icon_map.png")
const TERMINAL_ICON_POWER := preload("res://content/ui/terminal/icons/icon_power.png")
const TERMINAL_ICON_RECON := preload("res://content/ui/terminal/icons/icon_recon.png")
const TERMINAL_ICON_REPAIR := preload("res://content/ui/terminal/icons/icon_repair.png")
const TERMINAL_ICON_RESTART := preload("res://content/ui/terminal/icons/icon_restart.png")
const TERMINAL_ICON_SCAN := preload("res://content/ui/terminal/icons/icon_scan.png")
const TERMINAL_ICON_TURRET := preload("res://content/ui/terminal/icons/icon_turret.png")
const TERMINAL_ICON_WARNING := preload("res://content/ui/terminal/icons/icon_warning.png")
const TERMINAL_ICON_CRITICAL := preload("res://content/ui/terminal/icons/icon_critical.png")

const TERMINAL_FONT_MONO_PATH := "res://content/ui/fonts/terminal_mono_regular.ttf"
const TERMINAL_FONT_MONO_BOLD_PATH := "res://content/ui/fonts/terminal_mono_bold.ttf"
const TERMINAL_FONT_DISPLAY_PATH := "res://content/ui/fonts/terminal_display_regular.ttf"
const TERMINAL_FONT_SIZE_TITLE := 22
const TERMINAL_FONT_SIZE_HEADER := 11
const TERMINAL_FONT_SIZE_NAV := 12
const TERMINAL_FONT_SIZE_SECTION := 11
const TERMINAL_FONT_SIZE_BODY := 13
const TERMINAL_FONT_SIZE_ROW := 12
const TERMINAL_FONT_SIZE_LOG := 12
const TERMINAL_FONT_SIZE_INPUT := 16
const TERMINAL_FONT_SIZE_HINT := 10
const TERMINAL_FONT_SIZE_BUTTON := 12

const TERMINAL_STYLE_STRETCH := StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
const TERMINAL_STYLE_TILE := StyleBoxTexture.AXIS_STRETCH_MODE_TILE
const TERMINAL_STYLE_TILE_FIT := StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
const TERMINAL_PANEL_SLICE := 2.0
const TERMINAL_MAP_SLICE := 2.0
const TERMINAL_NAV_SLICE := 2.0
const TERMINAL_BUTTON_SLICE := 2.0
const TERMINAL_COMMAND_LINE_SLICE := 2.0
const TERMINAL_HEADER_SLICE := 2.0
const TERMINAL_SCANLINE_ALPHA := 0.05
const TERMINAL_NOISE_ALPHA := 0.025
const TERMINAL_DECOR_OVERLAY_Z := 5
const TERMINAL_COMMAND_ENTRY_Z := 10
const TERMINAL_BACKDROP_COLOR := Color(0.015, 0.025, 0.03, 0.78)
const TERMINAL_DENSE_PANEL_MODULATE := Color(1.0, 1.0, 1.0, 0.82)
const DEBUG_TERMINAL_STYLEBOXES := false
const DEBUG_TERMINAL_INPUT_LAYOUT := false
const DEBUG_TERMINAL_LAYOUT_BOUNDS := false
const DEBUG_GRUNT_SPAWN_MODES := [
	&"normal",
	&"falcon",
	&"critical_enter",
	&"critical_hold",
	&"critical_recover",
	&"execution_ready",
	&"execution_lethal",
]

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
	"RESET", "REBOOT CONFIRM",
	"REPAIR", "SCAVENGE", "SET", "SET FAB", "POLICY SHOW", "POLICY PRESET",
	"FABRICATION",
	"FAB STATUS", "FAB RECIPES", "FAB GRANT", "FAB START", "FAB QUEUE", "FAB CANCEL",
	"FAB PRIORITY",
	"FORTIFY", "CONFIG DOCTRINE", "ALLOCATE DEFENSE", "SCAN RELAYS",
	"STABILIZE RELAY", "SYNC", "FAB ADD", "FAB QUEUE", "FAB CANCEL",
	"FAB PRIORITY", "BUILD", "BUILD PLACE", "REROUTE POWER", "BOOST DEFENSE", "DRONE DEPLOY",
	"DEPLOY DRONE", "LOCKDOWN", "PRIORITIZE REPAIR", "STATUS RELAY",
	"OVERLAY SHOW", "OVERLAY THREAT", "OVERLAY PATH", "OVERLAY POWER", "OVERLAY REPAIR", "OVERLAY CLEAR",
	"TURRET", "TURRET GUNNER", "TURRET BLASTER", "TURRET REPEATER", "TURRET SNIPER",
	"ALLOCATE_DEFENSE", "DEPLOY", "FOCUS",
]

# Custom minimap feature flag.
const ENABLE_MINIMAP := true
const MINIMAP_TOGGLE_ACTION := &"toggle_minimap"

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
@onready var power_display = get_node_or_null("PowerDisplay")
@onready var contract_phase_label = get_node_or_null("ContractPhaseLabel")
@onready var lives_label = get_node_or_null("LivesLabel")
@onready var field_patch_prompt = get_node_or_null("FieldPatchPrompt")
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
@onready var ranged_reticle = get_node_or_null("RangedReticle")
@onready var interaction_label = get_node_or_null("InteractionLabel")
@onready var minimap = get_node_or_null("Minimap")

@onready var terminal_panel = get_node_or_null("TerminalPanel")
@onready var terminal_header_eyebrow = get_node_or_null("TerminalPanel/Header/Margin/HeaderRow/Eyebrow")
@onready var terminal_title_label = get_node_or_null("TerminalPanel/Header/Margin/HeaderRow/Title")
@onready var terminal_nav_title = get_node_or_null("TerminalPanel/Body/NavRail/NavTitle")
@onready var terminal_action_title = get_node_or_null("TerminalPanel/Body/NavRail/ActionTitle")
@onready var terminal_activity_scroll = get_node_or_null("TerminalPanel/Body/CommandColumn/ActivityScroll")
@onready var terminal_output = get_node_or_null("TerminalPanel/Body/CommandColumn/ActivityScroll/TerminalOutput")
@onready var terminal_command_title = get_node_or_null("TerminalPanel/Body/CommandColumn/CommandTitle")
@onready var terminal_input = get_node_or_null("TerminalPanel/Body/CommandColumn/InputRow/TerminalInput")
@onready var terminal_status_label = get_node_or_null("TerminalPanel/Body/CommandColumn/Status")
@onready var terminal_time_chip = get_node_or_null("TerminalPanel/Header/Margin/HeaderRow/StatusChips/TimeChip")
@onready var terminal_threat_chip = get_node_or_null("TerminalPanel/Header/Margin/HeaderRow/StatusChips/ThreatChip")
@onready var terminal_phase_chip = get_node_or_null("TerminalPanel/Header/Margin/HeaderRow/StatusChips/PhaseChip")
@onready var terminal_grid_chip = get_node_or_null("TerminalPanel/Header/Margin/HeaderRow/StatusChips/GridChip")
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
@onready var terminal_overview_map_slot = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewMapSlot")
@onready var terminal_overview_priority_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewBottomRow/OverviewPriorityPanel/Margin/Content/Body")
@onready var terminal_overview_incident_body = get_node_or_null("TerminalPanel/Body/MapColumn/WidgetStack/OverviewWidgets/OverviewBottomRow/OverviewIncidentPanel/Margin/Content/Body")
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
@onready var _terminal_page_buttons_scroll = get_node_or_null("TerminalPanel/Body/NavRail/PageButtonsScroll") as ScrollContainer
@onready var terminal_overview_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons/OverviewButton")
@onready var terminal_status_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons/StatusButton")
@onready var terminal_sectors_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons/SectorsButton")
@onready var terminal_power_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons/PowerButton")
@onready var terminal_defense_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons/DefenseButton")
@onready var terminal_sensors_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons/SensorsButton")
@onready var terminal_incidents_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons/IncidentsButton")
@onready var terminal_archive_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons/ArchiveButton")
@onready var terminal_recon_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons/ReconButton")
@onready var terminal_contracts_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons/ContractsButton")
@onready var terminal_history_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons/HistoryButton")
@onready var terminal_settings_button = get_node_or_null("TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons/SettingsButton")
var terminal_fabrication_button: BaseButton = null
@onready var _terminal_more_button = get_node_or_null("TerminalPanel/Body/NavRail/MoreButton") as BaseButton
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
var _last_legacy_weapon_hud_text := ""
var _last_ammo_text := ""
var _last_health_text := ""
var _last_cooldown_pct := -1.0
var _last_cooldown_text := ""
var _last_director_text := ""

var _terminal_open := false
var _terminal_ready := false
var _terminal_boot_started := false
var _terminal_boot_complete := false
var _terminal_previous_mouse_mode := Input.MOUSE_MODE_VISIBLE
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
var _debug_hud_visible := false
var _debug_toggle_key_was_pressed := false
var _debug_screen: Control = null
var _minimap_visible := true
var _world_presentation_mode: StringName = &"gameplay"
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
var _terminal_secondary_nav_expanded := false
var _terminal_page_buttons: Dictionary = {}
var _terminal_nav_buttons: Array = []
var _terminal_action_buttons: Array = []
var _terminal_main_scroll: ScrollContainer = null
var _terminal_font_mono: Font = null
var _terminal_font_mono_bold: Font = null
var _terminal_font_display: Font = null
var _terminal_fabrication_queue: Array[String] = []
var _terminal_fabrication_selected_work_order_id := ""
var _terminal_policy_preset := "BALANCED"
var _terminal_activity_autofollow := true
var _terminal_command_router: TerminalCommandRouter = TerminalCommandRouterScript.new()
var _terminal_snapshot_builder: TerminalSnapshot = TerminalSnapshotScript.new()
var _terminal_status_formatter: TerminalStatusFormatter = TerminalStatusFormatterScript.new()
var _terminal_overview_view_model: TerminalOverviewViewModel = TerminalOverviewViewModelScript.new()
var _terminal_fabrication_view_model: FabricationTerminalViewModel = TerminalFabricationViewModelScript.new()
var _terminal_map_preview_renderer: TerminalMapPreview = TerminalMapPreviewScript.new()
var _terminal_planet_preview_renderer: TerminalPlanetPreview = TerminalPlanetPreviewScript.new()

const PLANET_PREVIEW_ZOOM_MIN := 2.7
const PLANET_PREVIEW_ZOOM_MAX := 6.2
const PLANET_PREVIEW_ZOOM_STEP := 0.3
const TERMINAL_LOG_LIMIT := 1000
const TERMINAL_COMMAND_QUEUE_INTERVAL := 0.12
const TERMINAL_MAP_PREVIEW_SIZE := 320
const CROSSHAIR_WORLD_DISTANCE := 110.0
const CROSSHAIR_SCREEN_MARGIN := 22.0
const TERMINAL_ACTIVITY_SCROLL_FOLLOW_MARGIN := 24.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_terminal_modal_input_order()
	if minimap:
		_minimap_visible = minimap.visible
	_set_main_hud_hidden(false)
	_create_debug_panel()
	_register_devconsole_commands()
	if terminal_panel:
		terminal_panel.visible = false
	_update_terminal_hint_visibility()
	if terminal_input and not terminal_input.text_submitted.is_connected(_on_terminal_input_submitted):
		terminal_input.text_submitted.connect(_on_terminal_input_submitted)
	if terminal_input and not terminal_input.gui_input.is_connected(_on_terminal_input_gui_input):
		terminal_input.gui_input.connect(_on_terminal_input_gui_input)
	if terminal_input and not terminal_input.text_changed.is_connected(_on_terminal_input_text_changed):
		terminal_input.text_changed.connect(_on_terminal_input_text_changed)
	if terminal_input and not terminal_input.focus_entered.is_connected(_on_terminal_input_focus_changed):
		terminal_input.focus_entered.connect(_on_terminal_input_focus_changed)
	if terminal_input and not terminal_input.focus_exited.is_connected(_on_terminal_input_focus_changed):
		terminal_input.focus_exited.connect(_on_terminal_input_focus_changed)
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
		"FABRICATION": terminal_fabrication_button,
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
		terminal_fabrication_button,
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
	_ensure_fabrication_terminal_button()
	_ensure_terminal_more_button()
	_terminal_page_buttons["FABRICATION"] = terminal_fabrication_button
	if terminal_fabrication_button != null and not terminal_fabrication_button.pressed.is_connected(_on_terminal_page_button_pressed.bind("FABRICATION")):
		terminal_fabrication_button.pressed.connect(_on_terminal_page_button_pressed.bind("FABRICATION"))
	if terminal_fabrication_button != null and not _terminal_nav_buttons.has(terminal_fabrication_button):
		_terminal_nav_buttons.append(terminal_fabrication_button)
	if _terminal_more_button != null and not _terminal_nav_buttons.has(_terminal_more_button):
		_terminal_nav_buttons.append(_terminal_more_button)
	_bind_terminal_nav_wheel()
	_connect_terminal_meta_links(terminal_widget_stack)
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
	_load_terminal_typography_fonts()
	_apply_terminal_theme()
	_init_terminal_previews()
	_ensure_terminal_contract_binding()
	_bind_wall_placer_ui()
	_bind_turret_placement_ui()
	_refresh_terminal_page_buttons()

func _create_debug_panel() -> void:
	if _debug_screen != null:
		return
	_debug_screen = DebugScreenScene.instantiate() as Control
	if _debug_screen == null:
		push_warning("[UI] Failed to instantiate debug screen")
		return
	_debug_screen.name = "DebugScreen"
	_debug_screen.visible = false
	add_child(_debug_screen)


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

func _register_devconsole_commands() -> void:
	# Register custom debug commands with the DevConsole addon
	var console = get_node_or_null("/root/DevConsole")
	if console == null:
		printerr("DevConsole not found at /root/DevConsole")
		return
	
	# Command: debug_hud - Toggle debug HUD visibility
	if console.has_method("add_command"):
		_register_devconsole_command(console, "debug_hud", _devconsole_toggle_debug_hud)
		_register_devconsole_command(console, "show_cognitive", _devconsole_show_cognitive)
		_register_devconsole_command(console, "test_spawn", _devconsole_test_spawn)
		_register_devconsole_command(console, "spawn_grunt", _devconsole_spawn_grunt)
		_register_devconsole_command(console, "spawn_savage", _devconsole_spawn_savage)
		_register_devconsole_command(console, "knight_skin", _devconsole_knight_skin)
		_register_devconsole_command(console, "ui_status", _devconsole_ui_status)
		_register_devconsole_command(console, "fab_status", _devconsole_fab_status)
		_register_devconsole_command(console, "fab_recipes", _devconsole_fab_recipes)
		_register_devconsole_command(console, "fab_grant", _devconsole_fab_grant)
		_register_devconsole_command(console, "fab_start", _devconsole_fab_start)
		_register_devconsole_command(console, "spawn_looter", _devconsole_spawn_looter)
		_register_devconsole_command(console, "spawn_looter_near_vault", _devconsole_spawn_looter_near_vault)
		_register_devconsole_command(console, "vault_add", _devconsole_vault_add)
		_register_devconsole_command(console, "vault_status", _devconsole_vault_status)
		_register_devconsole_command(console, "enemy_debug", _devconsole_enemy_debug)
		_register_devconsole_command(console, "force_enemy_notice", _devconsole_force_enemy_notice)
		_register_devconsole_command(console, "force_enemy_steal", _devconsole_force_enemy_steal)
		_register_devconsole_command(console, "stuck_report", _devconsole_stuck_report)
		if ENABLE_MINIMAP:
			_register_devconsole_command(console, "toggle_minimap", _devconsole_toggle_minimap)
			_register_devconsole_command(console, "minimap_status", _devconsole_minimap_status)
		print("Registered debug commands with DevConsole")


func _register_devconsole_command(console: Node, command_name: String, handler: Callable) -> void:
	console.add_command(command_name, func(...args): return handler.call(args))


func _devconsole_toggle_debug_hud(args: Array) -> String:
	var next_visible := not _debug_hud_visible
	if args.size() > 0:
		var mode := str(args[0]).strip_edges().to_lower()
		if mode in ["on", "true", "1", "show", "open"]:
			next_visible = true
		elif mode in ["off", "false", "0", "hide", "close"]:
			next_visible = false
	_set_debug_screen_visible(next_visible)
	return "Debug screen: " + ("ON" if _debug_hud_visible else "OFF")

func _devconsole_show_cognitive(args: Array) -> String:
	# Show cognitive state from CognitiveState autoload
	var cs = get_node_or_null("/root/CognitiveState")
	if cs == null:
		return "CognitiveState autoload not found"
	var dominant = cs.get_dominant_state() if cs.has_method("get_dominant_state") else "UNKNOWN"
	return "Cognitive: Dominant=%s" % str(dominant)


func _devconsole_stuck_report(_args: Array) -> String:
	var operator := _get_operator_node()
	if operator == null:
		return "Operator not found"
	if not operator.has_method("debug_print_stuck_report"):
		return "Operator does not expose stuck diagnostics"
	var report: Dictionary = operator.call("debug_print_stuck_report")
	if report.is_empty():
		return "No active procgen walkability provider"
	return "Stuck report: tile=%s floor=%s wall=%s region=%s prop_blocked=%s escape_neighbors=%s nearby=%s" % [
		report.get("tile"), report.get("floor_source_id"), report.get("wall_source_id"),
		report.get("region_type"), report.get("runtime_prop_blocked"),
		report.get("escape_neighbor_count"), report.get("nearby_collision_bodies"),
	]

func _devconsole_test_spawn(args: Array) -> String:
	# Spawn a test enemy at operator position
	var operator = _get_operator_node()
	if operator == null:
		return "Operator not found"
	var enemy_mgr = get_node_or_null("/root/GameRoot/EnemyDirector")
	if enemy_mgr != null and enemy_mgr.has_method("spawn_test_enemy"):
		var pos = operator.global_position
		enemy_mgr.call("spawn_test_enemy", pos)
		return "Spawned test enemy at " + str(pos)
	return "EnemyDirector not found or spawn_test_enemy not available"

func _devconsole_spawn_grunt(args: Array) -> String:
	var operator = _get_operator_node()
	if operator == null:
		return "Operator not found"
	var mode := &"normal"
	var offset_arg_index := 0
	if not args.is_empty():
		var first_arg := str(args[0]).strip_edges().to_lower()
		if first_arg == "modes":
			return "Grunt modes: %s" % ", ".join(DEBUG_GRUNT_SPAWN_MODES.map(func(value): return String(value)))
		if not first_arg.is_valid_float():
			mode = _normalize_debug_grunt_spawn_mode(first_arg)
			if mode.is_empty():
				return "Unknown grunt mode '%s'. Use: spawn_grunt modes" % first_arg
			offset_arg_index = 1
	var enemy_mgr = get_node_or_null("/root/GameRoot/EnemyDirector")
	if enemy_mgr != null and enemy_mgr.has_method("spawn_debug_enemy_type"):
		var offset := Vector2(128.0, 0.0) if mode == &"falcon" else (Vector2(96.0, 0.0) if mode == &"normal" else Vector2(48.0, 0.0))
		if args.size() >= offset_arg_index + 2:
			offset = Vector2(float(args[offset_arg_index]), float(args[offset_arg_index + 1]))
		var pos = operator.global_position + offset
		var spawned := bool(enemy_mgr.call("spawn_debug_enemy_type", "grunt", pos, &"", mode))
		return "Spawned grunt mode=%s at %s" % [String(mode), str(pos)] if spawned else "Failed to spawn grunt mode=%s" % String(mode)
	return "EnemyDirector not found or spawn_debug_enemy_type not available"


func _normalize_debug_grunt_spawn_mode(value: String) -> StringName:
	match value:
		"normal":
			return &"normal"
		"falcon", "falcon_punch":
			return &"falcon"
		"enter", "critical_enter":
			return &"critical_enter"
		"hold", "critical_hold":
			return &"critical_hold"
		"recover", "critical_recover":
			return &"critical_recover"
		"ready", "open", "execution_ready":
			return &"execution_ready"
		"lethal", "execution_lethal":
			return &"execution_lethal"
	return &""


func _devconsole_spawn_savage(args: Array) -> String:
	var operator = _get_operator_node()
	if operator == null:
		return "Operator not found"
	var enemy_mgr = get_node_or_null("/root/GameRoot/EnemyDirector")
	if enemy_mgr != null and enemy_mgr.has_method("spawn_debug_enemy_type"):
		var offset := Vector2(128.0, 0.0)
		if args.size() >= 2:
			offset = Vector2(float(args[0]), float(args[1]))
		var pos = operator.global_position + offset
		var spawned := bool(enemy_mgr.call("spawn_debug_enemy_type", "savage", pos))
		return "Spawned savage at %s" % str(pos) if spawned else "Failed to spawn savage"
	return "EnemyDirector not found or spawn_debug_enemy_type not available"


func _devconsole_spawn_looter(args: Array) -> String:
	var operator = _get_operator_node()
	if operator == null:
		return "Operator not found"
	var offset := Vector2(128.0, 0.0)
	if args.size() >= 2:
		offset = Vector2(float(args[0]), float(args[1]))
	return _spawn_profiled_grunt(operator.global_position + offset, &"iconoclast_looter")


func _devconsole_spawn_looter_near_vault(args: Array) -> String:
	var manager := get_node_or_null("/root/VaultManager")
	if manager == null or not manager.has_method("get_debug_snapshot"):
		return "VaultManager unavailable"
	var snapshot: Dictionary = manager.call("get_debug_snapshot")
	var storages: Array = snapshot.get("storages", [])
	if storages.is_empty():
		return "No vault storage available"
	var storage: Dictionary = storages[0]
	var pos := Vector2(storage.get("position", Vector2.ZERO)) + Vector2(96.0, 0.0)
	return _spawn_profiled_grunt(pos, &"iconoclast_looter")


func _spawn_profiled_grunt(pos: Vector2, profile_id: StringName) -> String:
	var enemy_mgr = get_node_or_null("/root/GameRoot/EnemyDirector")
	if enemy_mgr != null and enemy_mgr.has_method("spawn_debug_enemy_type"):
		var spawned := bool(enemy_mgr.call("spawn_debug_enemy_type", "grunt", pos, profile_id))
		return "Spawned %s grunt at %s" % [String(profile_id), str(pos)] if spawned else "Failed to spawn profiled grunt"
	return "EnemyDirector not found or spawn_debug_enemy_type not available"


func _devconsole_vault_add(args: Array) -> String:
	if args.size() < 2:
		return "Usage: vault_add <resource_id> <amount>"
	var manager := get_node_or_null("/root/VaultManager")
	if manager == null or not manager.has_method("debug_add"):
		return "VaultManager unavailable"
	var resource_id := StringName(str(args[0]).strip_edges())
	var amount := int(str(args[1]))
	manager.call("debug_add", resource_id, amount)
	return _devconsole_vault_status([])


func _devconsole_vault_status(args: Array) -> String:
	var manager := get_node_or_null("/root/VaultManager")
	if manager == null or not manager.has_method("get_debug_snapshot"):
		return "VaultManager unavailable"
	var snapshot: Dictionary = manager.call("get_debug_snapshot")
	return "VAULT\nResources: %s\nStorage count: %d\nEvents: %s" % [
		_format_debug_dictionary(snapshot.get("total", {})),
		int(snapshot.get("storage_count", 0)),
		str(snapshot.get("recent_events", [])),
	]


func _devconsole_enemy_debug(args: Array) -> String:
	var lines: Array[String] = ["ENEMY DEBUG"]
	for enemy in get_tree().get_nodes_in_group("enemy_behavior_agent"):
		if enemy != null and enemy.has_method("get_behavior_snapshot"):
			lines.append("%s: %s" % [enemy.name, str(enemy.call("get_behavior_snapshot"))])
	return "\n".join(lines)


func _devconsole_force_enemy_notice(args: Array) -> String:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemy_behavior_agent"):
		if enemy != null and enemy.has_method("force_behavior_notice"):
			enemy.call("force_behavior_notice")
			count += 1
	return "Forced notice on %d behavior enemies" % count


func _devconsole_force_enemy_steal(args: Array) -> String:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemy_behavior_agent"):
		if enemy != null and enemy.has_method("force_behavior_steal"):
			enemy.call("force_behavior_steal")
			count += 1
	return "Forced steal on %d behavior enemies" % count

func _devconsole_knight_skin(args: Array) -> String:
	var operator = _get_operator_node()
	if operator == null:
		return "Operator not found"
	if not operator.has_method("set_knight_test_skin_enabled"):
		return "Operator does not expose Knight test skin controls"
	var mode := "toggle"
	if args.size() > 0:
		mode = str(args[0]).strip_edges().to_lower()
	match mode:
		"on", "true", "1", "enable", "enabled":
			operator.call("set_knight_test_skin_enabled", true)
		"off", "false", "0", "disable", "disabled":
			operator.call("set_knight_test_skin_enabled", false)
		"status":
			pass
		"toggle", "":
			operator.call("toggle_knight_test_skin")
		_:
			return "Usage: knight_skin [on|off|toggle|status]"
	var active := bool(operator.call("is_knight_test_skin_active")) if operator.has_method("is_knight_test_skin_active") else false
	return "Knight skin: " + ("ON" if active else "OFF")

func _get_operator_node() -> Node:
	var operator := get_tree().get_first_node_in_group("player")
	if operator != null:
		return operator
	operator = get_node_or_null("/root/GameRoot/World/Operator")
	if operator != null:
		return operator
	return get_node_or_null("/root/GameRoot/Operator")

func _devconsole_ui_status(args: Array) -> String:
	# Show HUD/terminal status
	var status = "Terminal: " + ("OPEN" if _terminal_open else "CLOSED")
	status += " | Ready: " + str(_terminal_ready)
	status += " | Boot started: " + str(_terminal_boot_started)
	return status


func _devconsole_fab_status(args: Array) -> String:
	var ledger := get_node_or_null("/root/ResourceLedger")
	var build_inventory := get_node_or_null("/root/BuildInventory")
	var fab_pipeline := get_node_or_null("/root/FabPipeline")
	if ledger == null or build_inventory == null or fab_pipeline == null:
		return "Fabrication autoloads unavailable"

	var lines: Array[String] = ["FAB STATUS"]
	lines.append("Resources: " + _format_debug_dictionary(ledger.call("get_snapshot")))
	lines.append("Build tokens: " + _format_debug_dictionary(build_inventory.call("get_snapshot")))
	lines.append("Jobs: " + _format_fab_jobs(fab_pipeline.call("get_jobs_snapshot")))
	lines.append("Unlocks: " + _format_debug_dictionary(fab_pipeline.call("get_completed_unlocks")))
	return "\n".join(lines)


func _devconsole_fab_recipes(args: Array) -> String:
	var fab_pipeline := get_node_or_null("/root/FabPipeline")
	if fab_pipeline == null:
		return "FabPipeline autoload unavailable"
	var recipes: Dictionary = fab_pipeline.call("get_all_recipes")
	if recipes.is_empty():
		return "No fabrication recipes loaded"

	var lines: Array[String] = ["FAB RECIPES"]
	for recipe_id in recipes.keys():
		var recipe: Dictionary = recipes[recipe_id]
		var label := str(recipe.get("label", recipe_id))
		var cost: Dictionary = recipe.get("cost", {})
		var build_seconds := float(recipe.get("build_seconds", 0.0))
		var output_type := str(recipe.get("output_type", "build_token"))
		var output_id := str(recipe.get("output_id", recipe_id))
		lines.append("%s - %s | %.1fs | cost: %s | output: %s:%s" % [
			str(recipe_id),
			label,
			build_seconds,
			_format_debug_dictionary(cost),
			output_type,
			output_id,
		])
	return "\n".join(lines)


func _devconsole_fab_grant(args: Array) -> String:
	var ledger := get_node_or_null("/root/ResourceLedger")
	if ledger == null:
		return "ResourceLedger autoload unavailable"

	if args.size() >= 2:
		var resource_id := str(args[0]).strip_edges()
		var amount := int(str(args[1]))
		if resource_id.is_empty() or amount <= 0:
			return "Usage: fab_grant [resource_id amount] or fab_grant"
		ledger.call("add", resource_id, amount)
		return "Granted %d %s. Resources: %s" % [
			amount,
			resource_id,
			_format_debug_dictionary(ledger.call("get_snapshot")),
		]

	ledger.call("debug_grant")
	return "Granted starter fabrication resources. Resources: %s" % _format_debug_dictionary(ledger.call("get_snapshot"))


func _devconsole_fab_start(args: Array) -> String:
	if args.is_empty():
		return "Usage: fab_start <recipe_id>"
	var fab_pipeline := get_node_or_null("/root/FabPipeline")
	if fab_pipeline == null:
		return "FabPipeline autoload unavailable"

	var recipe_id := str(args[0]).strip_edges()
	if recipe_id.is_empty():
		return "Usage: fab_start <recipe_id>"
	if not bool(fab_pipeline.call("has_recipe", recipe_id)):
		return "Unknown recipe: %s" % recipe_id
	if not bool(fab_pipeline.call("can_start_recipe", recipe_id)):
		return "Cannot start %s. Insufficient resources or pipeline unavailable." % recipe_id
	if bool(fab_pipeline.call("try_start_recipe", recipe_id)):
		return "Started fabrication recipe: %s" % recipe_id
	return "Failed to start fabrication recipe: %s" % recipe_id


func _format_debug_dictionary(value: Variant) -> String:
	if not (value is Dictionary):
		return "{}"
	var dictionary := value as Dictionary
	if dictionary.is_empty():
		return "{}"
	var parts: Array[String] = []
	for key in dictionary.keys():
		parts.append("%s=%s" % [str(key), str(dictionary[key])])
	return ", ".join(parts)


func _format_fab_jobs(value: Variant) -> String:
	if not (value is Array):
		return "[]"
	var jobs := value as Array
	if jobs.is_empty():
		return "[]"
	var parts: Array[String] = []
	for job_variant in jobs:
		if not (job_variant is Dictionary):
			continue
		var job := job_variant as Dictionary
		parts.append("#%d %s %.0f%%" % [
			int(job.get("job_id", 0)),
			str(job.get("recipe_id", "")),
			float(job.get("progress", 0.0)) * 100.0,
		])
	return "; ".join(parts)


func _devconsole_toggle_minimap(args: Array) -> String:
	# Toggle minimap visibility at runtime
	if not ENABLE_MINIMAP:
		return "Minimap feature is disabled (ENABLE_MINIMAP = false)"
	var minimap = get_node_or_null("Minimap")
	if minimap == null:
		# Try absolute path
		minimap = get_node_or_null("/root/GameRoot/UI/Minimap")
	if minimap == null:
		return "Minimap node not found. Check scene tree path."
	_set_minimap_visible(not _minimap_visible)
	return "Minimap: " + ("VISIBLE" if _minimap_visible else "HIDDEN")

func _devconsole_minimap_status(args: Array) -> String:
	# Show minimap status and configuration
	if not ENABLE_MINIMAP:
		return "Minimap feature is disabled (ENABLE_MINIMAP = false)"
	var minimap = get_node_or_null("Minimap")
	if minimap == null:
		minimap = get_node_or_null("/root/GameRoot/UI/Minimap")
	if minimap == null:
		return "Minimap node not found. Check scene tree path."
	var status = "Minimap: " + ("VISIBLE" if _minimap_visible and minimap.visible else "HIDDEN") + "\n"
	if minimap.has_method("get_status_summary"):
		var summary: Dictionary = minimap.call("get_status_summary")
		status += "Procgen connected: " + str(summary.get("procgen_connected", false)) + "\n"
		status += "Map size: " + str(summary.get("map_size", Vector2i.ZERO)) + "\n"
		status += "Floor cells: " + str(summary.get("floor_cells", 0)) + "\n"
		status += "Wall cells: " + str(summary.get("wall_cells", 0)) + "\n"
		status += "Player tracked: " + str(summary.get("has_player", false)) + "\n"
		status += "Enemies tracked: " + str(summary.get("enemies", 0)) + "\n"
		status += "Objectives tracked: " + str(summary.get("objectives", 0))
	else:
		status += "Status summary unavailable"
	return status

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
		_terminal_main_scroll.follow_focus = false
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
	_terminal_main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_terminal_main_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	if content_column == null:
		return
	content_column.custom_minimum_size.x = 0.0
	content_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_configure_terminal_scroll_policy()
	for node in content_nodes:
		if node == null:
			continue
		if not (node is Node):
			continue
		if node.get_parent() != content_column:
			var previous_parent: Node = node.get_parent()
			if previous_parent != null:
				previous_parent.remove_child(node)
			content_column.add_child(node)
	_apply_terminal_page_layout()


func _apply_terminal_page_layout() -> void:
	if _terminal_main_scroll == null or terminal_map_preview == null or terminal_map_preview_title_label == null:
		return
	var content_column := _terminal_main_scroll.get_node_or_null("Content") as VBoxContainer
	if content_column == null:
		return
	var is_overview := _terminal_current_page == "OVERVIEW"
	if terminal_map_preview.has_method("set_overview_mode"):
		terminal_map_preview.call("set_overview_mode", is_overview)
	if is_overview and terminal_overview_map_slot != null:
		if terminal_map_preview_title_label.get_parent() != terminal_overview_map_slot:
			terminal_map_preview_title_label.reparent(terminal_overview_map_slot)
		if terminal_map_preview.get_parent() != terminal_overview_map_slot:
			terminal_map_preview.reparent(terminal_overview_map_slot)
		terminal_map_preview_title_label.visible = true
		terminal_map_preview.visible = true
		terminal_map_preview.custom_minimum_size.y = 236.0
	else:
		if terminal_map_preview_title_label.get_parent() != content_column:
			terminal_map_preview_title_label.reparent(content_column)
		if terminal_map_preview.get_parent() != content_column:
			terminal_map_preview.reparent(content_column)
		var widget_index := terminal_widget_stack.get_index() if terminal_widget_stack != null and terminal_widget_stack.get_parent() == content_column else content_column.get_child_count()
		content_column.move_child(terminal_map_preview_title_label, widget_index)
		content_column.move_child(terminal_map_preview, mini(widget_index + 1, content_column.get_child_count() - 1))
		terminal_map_preview.custom_minimum_size.y = 250.0
	if terminal_planet_preview != null:
		terminal_planet_preview.custom_minimum_size.y = 144.0
	if _terminal_main_scroll != null:
		_terminal_main_scroll.scroll_vertical = 0


func _update_debug_panel() -> void:
	var f12_pressed := Input.is_key_pressed(KEY_F12)
	var debug_toggle_pressed := InputMap.has_action("debug_toggle") and Input.is_action_just_pressed("debug_toggle")
	if f12_pressed and not _debug_toggle_key_was_pressed:
		debug_toggle_pressed = true
	_debug_toggle_key_was_pressed = f12_pressed

	if debug_toggle_pressed:
		_set_debug_screen_visible(not _debug_hud_visible)

	if not _debug_hud_visible or _debug_screen == null:
		return
	_debug_screen.call("update_snapshot", _build_debug_snapshot())


func _set_debug_screen_visible(p_visible: bool) -> void:
	_debug_hud_visible = p_visible
	_apply_debug_screen_visibility()
	_set_main_hud_hidden(_main_hud_hidden)


func _apply_debug_screen_visibility() -> void:
	if _debug_screen != null and _debug_screen.has_method("set_debug_visible"):
		_debug_screen.call("set_debug_visible", _debug_hud_visible and not _terminal_open)


func _build_debug_snapshot() -> Dictionary:
	var game_state := _get_game_state()
	var operator := _get_operator_node()
	var power_system := get_node_or_null("/root/GameRoot/Power")
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D")
	var director_status := _get_local_director_status()
	var scene_name := "none"
	if get_tree().current_scene != null:
		scene_name = get_tree().current_scene.name
	var phase_name := "UNKNOWN"
	if game_state != null and game_state.has_method("get_phase_name"):
		phase_name = str(game_state.call("get_phase_name")).replace("_", " ")
	return {
		"summary": "Scene %s | Phase %s | Debug diagnostics are isolated from normal HUD." % [scene_name, phase_name],
		"runtime": _build_debug_runtime_snapshot(game_state, scene_name),
		"player": _build_debug_player_snapshot(operator),
		"combat": _build_debug_combat_snapshot(operator, director_status),
		"world": _build_debug_world_snapshot(camera),
		"systems": _build_debug_systems_snapshot(power_system, director_status),
		"inventory": _build_debug_inventory_snapshot(),
	}


func _build_debug_runtime_snapshot(game_state: Node, scene_name: String) -> Dictionary:
	var phase_name := "UNKNOWN"
	var game_over := false
	var game_over_reason := ""
	if game_state != null:
		if game_state.has_method("get_phase_name"):
			phase_name = str(game_state.call("get_phase_name")).replace("_", " ")
		if "game_over" in game_state:
			game_over = bool(game_state.get("game_over"))
		if "game_over_reason" in game_state:
			game_over_reason = str(game_state.get("game_over_reason"))
	return {
		"scene": scene_name,
		"phase": phase_name,
		"time_scale": Engine.time_scale,
		"fps": Engine.get_frames_per_second(),
		"terminal_open": _terminal_open,
		"terminal_ready": _terminal_ready,
		"minimap_visible": _minimap_visible,
		"placement_mode": _placement_mode_active,
		"game_over": game_over,
		"game_over_reason": game_over_reason,
	}


func _build_debug_player_snapshot(operator: Node) -> Dictionary:
	if operator == null:
		return {"operator": "missing"}
	var health_value := 0.0
	var max_health_value := 0.0
	if operator.has_method("get_health"):
		health_value = float(operator.call("get_health"))
	elif "health" in operator:
		health_value = float(operator.get("health"))
	if operator.has_method("get_max_health"):
		max_health_value = float(operator.call("get_max_health"))
	elif "max_health" in operator:
		max_health_value = float(operator.get("max_health"))
	var sprint := {}
	if operator.has_method("get_sprint_status"):
		sprint = operator.call("get_sprint_status")
	var field_patch := {}
	if operator.has_method("get_field_patch_status"):
		field_patch = operator.call("get_field_patch_status")
	return {
		"name": operator.name,
		"position": (operator as Node2D).global_position if operator is Node2D else Vector2.ZERO,
		"health": "%d/%d" % [int(round(health_value)), int(round(max_health_value))],
		"field_patch": "%d/%d%s" % [
			int(field_patch.get("count", 0)),
			int(field_patch.get("max", 0)),
			" active" if bool(field_patch.get("active", false)) else "",
		],
		"stamina": "%.0f/%.0f" % [float(sprint.get("stamina", 0.0)), float(sprint.get("stamina_max", 0.0))],
		"sprinting": bool(sprint.get("is_sprinting", false)),
		"exhausted": bool(sprint.get("sprint_exhausted", false)),
		"interaction": str(operator.call("get_interaction_prompt")) if operator.has_method("get_interaction_prompt") else "",
	}


func _build_debug_combat_snapshot(operator: Node, director_status: Dictionary) -> Dictionary:
	var result := {
		"weapon": "unavailable",
		"ammo": "unavailable",
		"cooldown": "unavailable",
		"director": director_status,
	}
	if operator != null and operator.has_method("get_weapon_status"):
		var ws: Dictionary = operator.call("get_weapon_status")
		result["weapon"] = str(ws.get("weapon_name", ws.get("primary_weapon_id", "HOLSTERED")))
		result["loadout"] = str(ws.get("loadout_mode", "unknown"))
		result["equipped"] = bool(ws.get("equipped", false))
		result["aim_mode"] = str(ws.get("aim_mode", "unknown"))
		result["ammo"] = "%d/%d +%d" % [
			int(ws.get("ammo_standard_loaded", 0)),
			int(ws.get("ammo_standard_magazine_size", 0)),
			int(ws.get("ammo_standard", 0)),
		]
		result["cooldown"] = "%.2fs" % float(ws.get("cooldown_remaining", 0.0))
		result["blocking"] = bool(ws.get("blocking", false))
	return result


func _build_debug_world_snapshot(camera: Node) -> Dictionary:
	var enemy_count := get_tree().get_nodes_in_group("enemy").size()
	var behavior_enemy_count := get_tree().get_nodes_in_group("enemy_behavior_agent").size()
	var result := {
		"enemies": enemy_count,
		"behavior_enemies": behavior_enemy_count,
		"terminals": get_tree().get_nodes_in_group("command_terminal").size(),
		"interactables": get_tree().get_nodes_in_group("interactable").size(),
	}
	if camera != null:
		result["camera_position"] = (camera as Node2D).global_position if camera is Node2D else Vector2.ZERO
		if "follow_enabled" in camera:
			result["camera_follow"] = bool(camera.get("follow_enabled"))
		if "auto_zoom_enabled" in camera:
			result["camera_auto_zoom"] = bool(camera.get("auto_zoom_enabled"))
		if camera is Camera2D:
			result["camera_zoom"] = (camera as Camera2D).zoom
	return result


func _build_debug_systems_snapshot(power_system: Node, director_status: Dictionary) -> Dictionary:
	var result := {
		"director": director_status,
		"supply_drop": "unavailable",
		"vault": "unavailable",
	}
	if power_system != null and power_system.has_method("get_power_status"):
		var status: Dictionary = power_system.call("get_power_status")
		result["power"] = "%d/%d | net %.1f/tick" % [
			int(round(float(status.get("total", 0.0)))),
			int(round(float(status.get("max", 0.0)))),
			float(status.get("net", 0.0)),
		]
	var supply_manager := get_node_or_null("/root/GameRoot/SupplyDropManager")
	if supply_manager != null and supply_manager.has_method("get_status"):
		result["supply_drop"] = supply_manager.call("get_status")
	var vault_manager := get_node_or_null("/root/VaultManager")
	if vault_manager != null and vault_manager.has_method("get_debug_snapshot"):
		result["vault"] = vault_manager.call("get_debug_snapshot")
	return result


func _build_debug_inventory_snapshot() -> Dictionary:
	var result := {}
	var inventory := get_node_or_null("/root/InventoryManager")
	if inventory != null and inventory.has_method("get_all_items"):
		result["items"] = inventory.call("get_all_items")
	else:
		result["items"] = "InventoryManager unavailable"
	var cognitive := get_node_or_null("/root/CognitiveState")
	if cognitive != null and cognitive.has_method("get_weights"):
		result["cognitive_weights"] = cognitive.call("get_weights")
		result["dominant_cognitive_state"] = cognitive.call("get_dominant_state") if cognitive.has_method("get_dominant_state") else "UNKNOWN"
	else:
		result["cognitive_state"] = "CognitiveState unavailable"
	var ledger := get_node_or_null("/root/ResourceLedger")
	if ledger != null and ledger.has_method("get_snapshot"):
		result["resources"] = ledger.call("get_snapshot")
	var build_inventory := get_node_or_null("/root/BuildInventory")
	if build_inventory != null and build_inventory.has_method("get_snapshot"):
		result["build_tokens"] = build_inventory.call("get_snapshot")
	return result


func _process(delta):
	_handle_terminal_shortcuts()
	_update_terminal_planet_spin(delta)
	_process_terminal_command_queue(delta)
	_update_debug_panel()

	var show_debug_hud := false
	var power_system = get_node_or_null("/root/GameRoot/Power")
	if show_debug_hud and power_system and power_label and power_bar:
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
		var health_value := 0.0
		var max_health_value := 1.0
		var operator_for_health = get_node_or_null("/root/GameRoot/World/Operator")
		if operator_for_health != null:
			if operator_for_health.has_method("get_health"):
				health_value = float(operator_for_health.get_health())
			elif "health" in operator_for_health:
				health_value = float(operator_for_health.get("health"))
			if operator_for_health.has_method("get_max_health"):
				max_health_value = max(1.0, float(operator_for_health.get_max_health()))
			elif "max_health" in operator_for_health:
				max_health_value = max(1.0, float(operator_for_health.get("max_health")))
		var health_text := "HEALTH: %d/%d" % [int(round(health_value)), int(round(max_health_value))]
		var patch_prompt_visible := false
		var patch_prompt_critical := false
		if operator_for_health != null and operator_for_health.has_method("get_field_patch_status"):
			var patch_status: Dictionary = operator_for_health.get_field_patch_status()
			var patch_count := int(patch_status.get("count", 0))
			var patch_max := int(patch_status.get("max", 0))
			if bool(patch_status.get("active", false)):
				health_text += "  PATCHING %.1fs" % maxf(0.0, float(patch_status.get("time_remaining", 0.0)))
			else:
				health_text += "  PATCH %d/%d" % [patch_count, patch_max]
			patch_prompt_visible = bool(patch_status.get("prompt_visible", false))
			patch_prompt_critical = bool(patch_status.get("prompt_critical", false))
		if health_text != _last_health_text:
			lives_label.text = health_text
			_last_health_text = health_text
		var health_pct: float = clamp(health_value / max_health_value, 0.0, 1.0)
		if health_pct <= 0.3:
			lives_label.modulate = Color(0.95, 0.35, 0.35, 1.0)
		elif health_pct <= 0.6:
			lives_label.modulate = Color(0.95, 0.8, 0.35, 1.0)
		else:
			lives_label.modulate = Color(0.55, 0.95, 0.65, 1.0)
		if field_patch_prompt is Label:
			var prompt := field_patch_prompt as Label
			prompt.visible = patch_prompt_visible and not _terminal_open
			if prompt.visible:
				prompt.text = "!! FIELD PATCH [P] — CRITICAL !!" if patch_prompt_critical else "+ FIELD PATCH READY [P]"
				var pulse := 0.72 + 0.28 * sin(float(Time.get_ticks_msec()) * (0.012 if patch_prompt_critical else 0.006))
				prompt.modulate = Color(1.0, 0.22, 0.18, pulse) if patch_prompt_critical else Color(0.42, 1.0, 0.58, pulse)

	var cam = get_node_or_null("/root/GameRoot/World/Camera2D")
	if show_debug_hud and cam and camera_follow_label and camera_zoom_label and "auto_zoom_enabled" in cam and "follow_enabled" in cam:
		var follow_enabled: bool = bool(cam.follow_enabled)
		var auto_zoom_enabled: bool = bool(cam.auto_zoom_enabled)
		if follow_enabled != _last_follow_state or auto_zoom_enabled != _last_auto_zoom_state or camera_follow_label.text.is_empty() or camera_zoom_label.text.is_empty():
			camera_follow_label.text = "CAMERA: %s (C)" % ("TRACKING" if follow_enabled else "FREE")
			camera_zoom_label.text = "ZOOM: %s (Z)" % ("AUTO" if auto_zoom_enabled else "LOCKED")
			_last_follow_state = follow_enabled
			_last_auto_zoom_state = auto_zoom_enabled

	if show_debug_hud and time_scale_label and Engine.time_scale != _last_time_scale:
		time_scale_label.text = "TIME SCALE: %.1fX (Y)" % Engine.time_scale
		_last_time_scale = Engine.time_scale

	var operator = get_node_or_null("/root/GameRoot/World/Operator")
	if show_debug_hud and operator and aim_mode_label:
		if operator.has_method("get_weapon_status"):
			var aim_ws = operator.get_weapon_status()
			var aim_mode := str(aim_ws.get("aim_mode", "mouse"))
			if aim_mode != _last_aim_mode or aim_mode_label.text.is_empty():
				aim_mode_label.text = "AIM: %s (V TOGGLE, ARROWS)" % aim_mode.to_upper()
				_last_aim_mode = aim_mode

	if not _main_hud_hidden and operator:
		if operator.has_method("get_weapon_status"):
			var ws = operator.get_weapon_status()
			var equipped := bool(ws.get("equipped", false))
			var primary_weapon_id := str(ws.get("primary_weapon_id", ""))
			var loadout_mode := str(ws.get("loadout_mode", "holstered"))
			if show_debug_hud and weapon_label:
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
			if show_debug_hud and primary_weapon_button:
				primary_weapon_button.text = "UNEQUIP CARBINE" if equipped and primary_weapon_id == "carbine_rifle" else "EQUIP CARBINE"
			if show_debug_hud and ammo_label:
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
			elif ammo_label:
				var weapon_name := _fit_legacy_hud_text(str(ws.get("weapon_name", "WEAPON")).to_upper(), 12)
				var magazine_size := int(ws.get("magazine_size", 0))
				var loaded := int(ws.get("loaded_ammo", 0))
				var reserve := int(ws.get("reserve_ammo", 0))
				var reloading := bool(ws.get("reloading", false))
				var overheated := bool(ws.get("overheated", false))
				var ammo_text := "%s  MELEE READY" % weapon_name
				if magazine_size > 0:
					ammo_text = "%s  MAG %d/%d  RES %d" % [weapon_name, loaded, magazine_size, reserve]
				if reloading and magazine_size > 0:
					ammo_text = "%s  RELOADING %d/%d" % [weapon_name, loaded, magazine_size]
				elif overheated and magazine_size > 0:
					ammo_text = "%s  OVERHEATED %d/%d" % [weapon_name, loaded, magazine_size]
				if ammo_text != _last_legacy_weapon_hud_text:
					ammo_label.text = ammo_text
					_last_legacy_weapon_hud_text = ammo_text
				ammo_label.visible = true
			if cooldown_bar and cooldown_label:
				var cooldown_total = max(0.001, float(ws.get("cooldown_total", 0.001)))
				var cooldown_remaining = max(0.0, float(ws.get("cooldown_remaining", 0.0)))
				var pct = clamp((cooldown_remaining / cooldown_total) * 100.0, 0.0, 100.0)
				var cd_text = "COOLDOWN: READY" if cooldown_remaining <= 0.001 else "COOLDOWN: %.2fs" % cooldown_remaining
				if absf(pct - _last_cooldown_pct) > 0.1:
					cooldown_bar.value = pct
					_last_cooldown_pct = pct
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

	if show_debug_hud and director_label:
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

	if show_debug_hud and supply_drop_label:
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
		if _terminal_open:
			interaction_label.visible = false
			return
		var player_controller = get_node_or_null("/root/GameRoot/World/PlayerController")
		if player_controller and player_controller.has_method("should_show_prompt") and bool(player_controller.should_show_prompt()):
			if player_controller.has_method("get_interaction_prompt"):
				prompt = str(player_controller.get_interaction_prompt())
		else:
			var operator_ref = get_node_or_null("/root/GameRoot/World/Operator")
			if operator_ref and operator_ref.has_method("get_interaction_prompt"):
				prompt = str(operator_ref.get_interaction_prompt())
		interaction_label.visible = not prompt.is_empty()
		if interaction_label.visible:
			interaction_label.text = prompt

	_update_crosshair()


func _update_crosshair() -> void:
	if crosshair_label == null and ranged_reticle == null:
		return
	if _main_hud_hidden or _terminal_open or _placement_mode_active:
		_hide_aim_reticles()
		return
	var drone_manager = get_node_or_null("/root/GameRoot/World/DroneManager")
	if drone_manager != null and drone_manager.has_method("get_command_reticle_state"):
		var command_state: Dictionary = drone_manager.call("get_command_reticle_state")
		if bool(command_state.get("active", false)) and crosshair_label != null:
			if ranged_reticle != null:
				ranged_reticle.visible = false
			var command_world_position: Vector2 = command_state.get("world_position", Vector2.ZERO)
			var command_screen_position := get_viewport().get_canvas_transform() * command_world_position
			var command_size := Vector2.ZERO
			if crosshair_label.texture:
				command_size = crosshair_label.texture.get_size()
			crosshair_label.position = command_screen_position - command_size * 0.5
			crosshair_label.visible = true
			crosshair_label.modulate = Color(1.0, 0.18, 0.14, 1.0) if bool(command_state.get("has_hostile", false)) else Color(0.9, 0.9, 0.9, 1.0)
			return
	var operator_ref = get_node_or_null("/root/GameRoot/World/Operator")
	if operator_ref == null or not operator_ref.has_method("get_weapon_status"):
		_hide_aim_reticles()
		return
	var weapon_status: Dictionary = operator_ref.get_weapon_status()
	if ranged_reticle != null and ranged_reticle.has_method("set_weapon_status"):
		ranged_reticle.call("set_weapon_status", weapon_status)
		if ranged_reticle.visible:
			if crosshair_label != null:
				crosshair_label.visible = false
			var ranged_screen_position := _get_ranged_reticle_screen_position(weapon_status, operator_ref)
			if ranged_screen_position != Vector2.INF:
				ranged_reticle.position = ranged_screen_position - ranged_reticle.size * 0.5
			return
	var aim_mode = str(weapon_status.get("aim_mode", "mouse"))
	if aim_mode != "arrows":
		if crosshair_label != null:
			crosshair_label.visible = false
		return
	if crosshair_label == null:
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


func _get_ranged_reticle_screen_position(weapon_status: Dictionary, operator_ref: Node2D) -> Vector2:
	var viewport_rect := get_viewport().get_visible_rect()
	var margin := CROSSHAIR_SCREEN_MARGIN
	if str(weapon_status.get("aim_mode", "mouse")) == "mouse":
		var mouse_position := get_viewport().get_mouse_position()
		mouse_position.x = clampf(mouse_position.x, margin, maxf(margin, viewport_rect.size.x - margin))
		mouse_position.y = clampf(mouse_position.y, margin, maxf(margin, viewport_rect.size.y - margin))
		return mouse_position
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D") as Camera2D
	if camera == null:
		return Vector2.INF
	var aim_direction: Vector2 = weapon_status.get("aim_direction", Vector2.RIGHT)
	if aim_direction.length_squared() <= 0.0001:
		aim_direction = Vector2.RIGHT
	var player_position: Vector2 = weapon_status.get("player_position", operator_ref.global_position)
	var world_position := player_position + aim_direction.normalized() * CROSSHAIR_WORLD_DISTANCE
	var screen_position := get_viewport().get_canvas_transform() * world_position
	screen_position.x = clampf(screen_position.x, margin, maxf(margin, viewport_rect.size.x - margin))
	screen_position.y = clampf(screen_position.y, margin, maxf(margin, viewport_rect.size.y - margin))
	return screen_position


func _hide_aim_reticles() -> void:
	if crosshair_label != null:
		crosshair_label.visible = false
	if ranged_reticle != null:
		ranged_reticle.visible = false


func _get_essential_hud_nodes() -> Array:
	return [
		lives_label,
		field_patch_prompt,
		stamina_bar,
		stamina_label,
		ammo_label,
	]


func _fit_legacy_hud_text(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, maxi(1, max_chars - 1)) + "."


func _get_debug_hud_nodes() -> Array:
	return [
		power_display,
		power_label,
		power_bar,
		contract_phase_label,
		camera_follow_label,
		camera_zoom_label,
		time_scale_label,
		aim_mode_label,
		weapon_label,
		primary_weapon_button,
		ammo_label,
		cooldown_bar,
		cooldown_label,
		director_label,
		supply_drop_label,
		crosshair_label,
		get_node_or_null("ControlsHintLabel"),
	]


func _set_main_hud_hidden(hidden: bool) -> void:
	_main_hud_hidden = hidden
	var effective_hidden := hidden or _terminal_open
	for node in _get_essential_hud_nodes():
		if node:
			node.visible = not effective_hidden
	if minimap:
		minimap.visible = not effective_hidden and _minimap_visible
	for node in _get_debug_hud_nodes():
		if node:
			node.visible = false
	if crosshair_label:
		crosshair_label.visible = false
	if ranged_reticle:
		ranged_reticle.visible = false
	_set_external_gameplay_overlays_hidden(effective_hidden)


func _handle_minimap_toggle_input(event: InputEvent) -> bool:
	if not ENABLE_MINIMAP or minimap == null:
		return false
	if not InputMap.has_action(MINIMAP_TOGGLE_ACTION):
		return false
	if not event.is_action_pressed(MINIMAP_TOGGLE_ACTION):
		return false
	_set_minimap_visible(not _minimap_visible)
	get_viewport().set_input_as_handled()
	return true


func _set_minimap_visible(visible: bool) -> void:
	_minimap_visible = visible
	if minimap:
		minimap.visible = visible and not _main_hud_hidden and not _terminal_open


func set_world_presentation_mode(mode: StringName) -> void:
	_world_presentation_mode = mode
	# The legacy contract HUD is procgen-specific. Vista traversal deliberately
	# uses a clean screen; authored destination prompts are world-owned.
	_set_main_hud_hidden(mode == &"vista_approach")


func get_world_presentation_mode() -> StringName:
	return _world_presentation_mode


func _set_external_gameplay_overlays_hidden(hidden: bool) -> void:
	for node in get_tree().get_nodes_in_group("gameplay_overlay"):
		if node == self:
			continue
		if node.has_method("set_external_overlay_hidden"):
			node.call("set_external_overlay_hidden", hidden)
		elif node is CanvasItem:
			(node as CanvasItem).visible = not hidden
		elif "visible" in node:
			node.set("visible", not hidden)

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
	if not _terminal_open:
		_terminal_previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_ensure_terminal_modal_input_order()
	if not service_url.strip_edges().is_empty():
		_terminal_service_url = service_url.strip_edges()
	_terminal_open = true
	_set_main_hud_hidden(_main_hud_hidden)
	_apply_debug_screen_visibility()
	_set_terminal_page(_terminal_current_page if _terminal_page_buttons.has(_terminal_current_page) else "OVERVIEW")
	if terminal_panel:
		terminal_panel.visible = true
		terminal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if terminal_background:
		terminal_background.visible = true
		terminal_background.initialize()
		terminal_background.generate_new()
	if terminal_time_chip:
		terminal_time_chip.text = "T:--:--"
	if terminal_threat_chip:
		terminal_threat_chip.text = "THREAT:STABLE"
	if terminal_phase_chip:
		terminal_phase_chip.text = "PHASE:LINKING"
	if terminal_grid_chip:
		terminal_grid_chip.text = "GRID:--"
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
		_terminal_boot_complete = true
		_append_terminal_line("LOCAL SNAPSHOT MODE ACTIVE", "info")
	_set_terminal_input_enabled(true)
	_update_terminal_hint_visibility()
	call_deferred("_ensure_terminal_input_visible_and_focused")
	_debug_terminal_input_layout("open_command_terminal")
	_refresh_snapshot()
	call_deferred("_report_terminal_layout_open")
	call_deferred("_set_terminal_layout_debug_bounds_visible", DEBUG_TERMINAL_LAYOUT_BOUNDS)
	if terminal_poll_timer:
		terminal_poll_timer.start()


func open_fabricator_terminal(service_url: String = ""):
	open_command_terminal(service_url)
	_set_terminal_page("FABRICATION")
	if _terminal_ready:
		_append_terminal_line("FABRICATION SHELL ACTIVE", "success")
		_render_terminal_status("FABRICATION LINK ESTABLISHED")


func close_fabricator_terminal():
	close_command_terminal()

func close_command_terminal():
	if _placement_mode_active:
		if not _cancel_active_placement_mode():
			exit_placement_mode_ui()
		return
	_terminal_open = false
	Input.mouse_mode = _terminal_previous_mouse_mode
	_set_main_hud_hidden(_main_hud_hidden)
	_apply_debug_screen_visibility()
	_terminal_command_queue.clear()
	_terminal_command_queue_tick = 0.0
	_set_terminal_input_enabled(false)
	if terminal_panel:
		terminal_panel.visible = false
	_update_terminal_hint_visibility()
	if terminal_background:
		terminal_background.visible = false
	if terminal_poll_timer:
		terminal_poll_timer.stop()
	var world_terminal := get_node_or_null("/root/GameRoot/World/CommandTerminal")
	if world_terminal != null and world_terminal.has_method("deactivate_visual_after_ui_close"):
		world_terminal.call("deactivate_visual_after_ui_close")


func _ensure_terminal_modal_input_order() -> void:
	if terminal_panel == null or terminal_background == null:
		return
	var shared_parent := terminal_panel.get_parent()
	if shared_parent == null or terminal_background.get_parent() != shared_parent:
		return
	# Godot GUI picking follows sibling order independently of visual z ordering.
	# Keep the full-screen click blocker before the panel so it catches gameplay
	# clicks outside the modal without intercepting controls inside the terminal.
	if terminal_background.get_index() > terminal_panel.get_index():
		shared_parent.move_child(terminal_background, terminal_panel.get_index())

func is_terminal_open() -> bool:
	return _terminal_open


func _report_terminal_layout_open() -> void:
	if not _terminal_open or terminal_panel == null:
		return
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory == null or not observatory.has_method("log_event"):
		return
	var nav_rail := get_node_or_null("TerminalPanel/Body/NavRail") as Control
	var command_column := get_node_or_null("TerminalPanel/Body/CommandColumn") as Control
	var input_row := get_node_or_null("TerminalPanel/Body/CommandColumn/InputRow") as Control
	var visible_nav_buttons := 0
	for button in _terminal_page_buttons.values():
		if button is Control and (button as Control).is_visible_in_tree():
			visible_nav_buttons += 1
	if _terminal_more_button != null and _terminal_more_button.is_visible_in_tree():
		visible_nav_buttons += 1
	var header_truncated := false
	for label in [terminal_header_eyebrow, terminal_title_label, terminal_time_chip, terminal_threat_chip, terminal_phase_chip, terminal_grid_chip]:
		if label is Label and (label as Label).get_minimum_size().x > (label as Label).size.x + 1.0:
			header_truncated = true
	observatory.call("log_event", "terminal_layout_open", {
		"terminal_viewport_size": get_viewport().get_visible_rect().size,
		"terminal_panel_rect": terminal_panel.get_global_rect(),
		"terminal_overview_map_rect": terminal_map_preview.get_global_rect() if terminal_map_preview != null else Rect2(),
		"terminal_nav_rect": nav_rail.get_global_rect() if nav_rail != null else Rect2(),
		"terminal_transcript_rect": command_column.get_global_rect() if command_column != null else Rect2(),
		"terminal_command_input_rect": input_row.get_global_rect() if input_row != null else Rect2(),
		"terminal_nav_visible_buttons": visible_nav_buttons,
		"terminal_header_truncated": header_truncated,
		"page": _terminal_current_page,
	})


func _set_terminal_layout_debug_bounds_visible(enabled: bool) -> void:
	var targets := {
		"TerminalSafeRect": terminal_panel,
		"NavRailRect": get_node_or_null("TerminalPanel/Body/NavRail"),
		"OverviewMapRect": terminal_map_preview,
		"TranscriptRect": get_node_or_null("TerminalPanel/Body/CommandColumn"),
		"CommandInputRect": get_node_or_null("TerminalPanel/Body/CommandColumn/InputRow"),
	}
	var colors := [Color.CYAN, Color(0.95, 0.72, 0.25), Color(0.35, 0.95, 0.62), Color(0.8, 0.45, 0.95), Color(0.95, 0.45, 0.42)]
	var color_index := 0
	for overlay_name in targets.keys():
		var target := targets[overlay_name] as Control
		if target == null:
			continue
		var overlay := target.get_node_or_null(String(overlay_name)) as ReferenceRect
		if overlay == null:
			overlay = ReferenceRect.new()
			overlay.name = String(overlay_name)
			overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			overlay.editor_only = false
			overlay.border_width = 2.0
			target.add_child(overlay)
		overlay.border_color = colors[color_index % colors.size()]
		overlay.visible = enabled
		color_index += 1

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
	if _handle_minimap_toggle_input(event):
		return
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
	terminal_input.visible = true
	terminal_input.focus_mode = Control.FOCUS_ALL
	_update_terminal_hint_visibility()
	if enabled and _terminal_open:
		if terminal_input:
			terminal_input.grab_focus()
			_update_terminal_hint_visibility()


func _ensure_terminal_input_visible_and_focused() -> void:
	var input_row := get_node_or_null("TerminalPanel/Body/CommandColumn/InputRow")
	if input_row is Control:
		var row_control := input_row as Control
		row_control.visible = true
		row_control.custom_minimum_size.y = max(row_control.custom_minimum_size.y, 48.0)
		row_control.size_flags_vertical = Control.SIZE_SHRINK_END
	var prompt_label := get_node_or_null("TerminalPanel/Body/CommandColumn/InputRow/Prompt")
	if prompt_label is Control:
		var prompt_control := prompt_label as Control
		prompt_control.custom_minimum_size.y = max(prompt_control.custom_minimum_size.y, 42.0)
		prompt_control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if terminal_activity_scroll is ScrollContainer:
		var activity_scroll := terminal_activity_scroll as ScrollContainer
		activity_scroll.custom_minimum_size.y = 0.0
		activity_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if terminal_output is RichTextLabel:
		var output := terminal_output as RichTextLabel
		output.custom_minimum_size = Vector2(0.0, 0.0)
		output.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		output.size_flags_vertical = Control.SIZE_EXPAND_FILL
		output.fit_content = false
		output.scroll_active = false
	if terminal_input == null:
		push_warning("[TerminalInput] Missing TerminalInput node.")
		_debug_terminal_input_layout("ensure_missing_input")
		return
	terminal_input.visible = true
	terminal_input.custom_minimum_size.x = max(terminal_input.custom_minimum_size.x, 220.0)
	terminal_input.custom_minimum_size.y = max(terminal_input.custom_minimum_size.y, 44.0)
	terminal_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	terminal_input.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	terminal_input.editable = _terminal_open and _terminal_ready
	terminal_input.focus_mode = Control.FOCUS_ALL
	if _terminal_open and _terminal_ready:
		terminal_input.grab_focus()
		if terminal_status_label:
			terminal_status_label.text = "COMMAND INPUT FOCUSED"
	_debug_terminal_input_layout("ensure_terminal_input_visible_and_focused")


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
		_update_terminal_hint_visibility()

func _on_terminal_input_focus_changed() -> void:
	if terminal_input != null and terminal_input.has_focus() and terminal_status_label != null:
		terminal_status_label.text = "COMMAND INPUT FOCUSED"
	_update_terminal_hint_visibility()
	_debug_terminal_input_layout("terminal_input_focus_changed")

func _update_terminal_hint_visibility() -> void:
	if terminal_hint_label == null:
		return
	if _terminal_current_page == "FABRICATION":
		terminal_hint_label.visible = false
		_debug_terminal_input_layout("update_terminal_hint_visibility")
		return
	terminal_hint_label.visible = _terminal_open and terminal_input != null and terminal_input.has_focus()
	_debug_terminal_input_layout("update_terminal_hint_visibility")


func _debug_terminal_input_layout(reason: String) -> void:
	if not DEBUG_TERMINAL_INPUT_LAYOUT:
		return
	var viewport := get_viewport()
	var focus_owner := viewport.gui_get_focus_owner() if viewport != null else null
	var input_row := get_node_or_null("TerminalPanel/Body/CommandColumn/InputRow")
	print("[TerminalInputDebug] ", reason)
	print("  terminal_open=", _terminal_open, " ready=", _terminal_ready, " page=", _terminal_current_page)
	print("  focus_owner=", focus_owner.name if focus_owner != null else "none")
	if input_row is Control:
		var row_control := input_row as Control
		print("  InputRow rect=", row_control.get_global_rect(), " visible=", row_control.visible, " min=", row_control.custom_minimum_size)
	if terminal_input is Control:
		print("  TerminalInput rect=", terminal_input.get_global_rect(), " visible=", terminal_input.visible, " editable=", terminal_input.editable, " min=", terminal_input.custom_minimum_size, " text='", terminal_input.text, "'")

func _focus_terminal_button_group(buttons: Array, forward: bool) -> void:
	var indexes: Array[int] = []
	for idx in range(buttons.size()):
		indexes.append(idx)

	if not forward:
		indexes.reverse()

	for idx in indexes:
		var button = buttons[idx]
		if button == null or not is_instance_valid(button) or not (button is BaseButton):
			continue
		if button.disabled or not (button as Control).is_visible_in_tree():
			continue

		(button as BaseButton).grab_focus()
		_ensure_terminal_nav_button_visible.call_deferred(button as Control)
		return

	if terminal_input and terminal_input.editable:
		terminal_input.grab_focus()


func _move_terminal_button_focus(step: int) -> void:
	var viewport := get_viewport()
	var focus_owner := viewport.gui_get_focus_owner() if viewport != null else null
	if not (focus_owner is BaseButton):
		return

	var ordered_buttons: Array = []

	for button in _terminal_nav_buttons:
		if button is BaseButton:
			ordered_buttons.append(button)

	for button in _terminal_action_buttons:
		if button is BaseButton:
			ordered_buttons.append(button)

	var current_index := ordered_buttons.find(focus_owner)
	if current_index < 0 or ordered_buttons.is_empty():
		return

	var total := ordered_buttons.size()
	for offset in range(1, total + 1):
		var next_index := (current_index + (step * offset) + total) % total
		var next_button = ordered_buttons[next_index]
		if next_button == null or not is_instance_valid(next_button) or not (next_button is BaseButton):
			continue
		if next_button.disabled or not (next_button as Control).is_visible_in_tree():
			continue

		(next_button as BaseButton).grab_focus()
		_ensure_terminal_nav_button_visible.call_deferred(next_button)
		return

func _update_terminal_planet_spin(delta: float) -> void:
	_terminal_planet_preview_renderer.update_spin(delta)

func _apply_terminal_planet_rotation() -> void:
	_terminal_planet_preview_renderer.apply_rotation()

func _apply_terminal_planet_zoom() -> void:
	_terminal_planet_preview_renderer.apply_zoom()

func _make_terminal_texture_style(
	texture: Texture2D,
	margin: float,
	content_margin: float = 8.0,
	h_axis_mode: int = TERMINAL_STYLE_TILE,
	v_axis_mode: int = TERMINAL_STYLE_TILE,
	draw_center: bool = true
) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = margin
	style.texture_margin_top = margin
	style.texture_margin_right = margin
	style.texture_margin_bottom = margin
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	style.axis_stretch_horizontal = h_axis_mode
	style.axis_stretch_vertical = v_axis_mode
	style.draw_center = draw_center
	return style


func _make_terminal_panel_style(content_margin: float = 8.0) -> StyleBoxTexture:
	return _make_terminal_texture_style(
		TERMINAL_PANEL_FRAME_TEXTURE,
		TERMINAL_PANEL_SLICE,
		content_margin,
		TERMINAL_STYLE_TILE_FIT,
		TERMINAL_STYLE_TILE_FIT,
		false
	)


func _make_terminal_header_style(texture: Texture2D, content_margin: float = 6.0) -> StyleBoxTexture:
	return _make_terminal_texture_style(
		texture,
		TERMINAL_HEADER_SLICE,
		content_margin,
		TERMINAL_STYLE_STRETCH,
		TERMINAL_STYLE_STRETCH,
		true
	)


func _make_terminal_map_style(content_margin: float = 10.0) -> StyleBoxTexture:
	return _make_terminal_texture_style(
		TERMINAL_MAP_FRAME_TEXTURE,
		TERMINAL_MAP_SLICE,
		content_margin,
		TERMINAL_STYLE_TILE_FIT,
		TERMINAL_STYLE_TILE_FIT,
		false
	)


func _make_terminal_nav_style(texture: Texture2D, content_margin: float = 6.0) -> StyleBoxTexture:
	return _make_terminal_texture_style(
		texture,
		TERMINAL_NAV_SLICE,
		content_margin,
		TERMINAL_STYLE_STRETCH,
		TERMINAL_STYLE_STRETCH,
		true
	)


func _make_terminal_button_style(texture: Texture2D, content_margin: float = 6.0) -> StyleBoxTexture:
	return _make_terminal_texture_style(
		texture,
		TERMINAL_BUTTON_SLICE,
		content_margin,
		TERMINAL_STYLE_STRETCH,
		TERMINAL_STYLE_STRETCH,
		true
	)


func _make_terminal_input_style() -> StyleBoxTexture:
	var style := _make_terminal_texture_style(
		TERMINAL_COMMAND_LINE_TEXTURE,
		TERMINAL_COMMAND_LINE_SLICE,
		8.0,
		TERMINAL_STYLE_STRETCH,
		TERMINAL_STYLE_STRETCH,
		true
	)
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style


func _debug_terminal_stylebox(label: String, style: StyleBoxTexture) -> void:
	if not DEBUG_TERMINAL_STYLEBOXES:
		return
	print("[TerminalStyle] %s margin=(%s,%s,%s,%s) axis=(%s,%s)" % [
		label,
		style.texture_margin_left,
		style.texture_margin_top,
		style.texture_margin_right,
		style.texture_margin_bottom,
		style.axis_stretch_horizontal,
		style.axis_stretch_vertical,
	])


func _apply_terminal_widget_button_styles(normal: StyleBoxTexture, hover: StyleBoxTexture, pressed: StyleBoxTexture, disabled: StyleBoxTexture) -> void:
	if terminal_widget_stack == null:
		return
	var button_color := Color(1.0, 0.90, 0.76, 1.0) if _terminal_current_page == "FABRICATION" else Color(0.82, 0.92, 0.88, 1.0)
	for button in terminal_widget_stack.find_children("*", "Button", true, false):
		if not (button is BaseButton):
			continue
		var terminal_button := button as BaseButton
		if terminal_button.has_meta("fabrication_flat_row"):
			continue
		_apply_terminal_button_assets(terminal_button, normal, hover, pressed, disabled, pressed)
		_apply_button_type(terminal_button, _terminal_font_mono_bold, TERMINAL_FONT_SIZE_BUTTON, button_color)


func _load_terminal_typography_fonts() -> void:
	_terminal_font_mono = _load_terminal_font(TERMINAL_FONT_MONO_PATH)
	_terminal_font_mono_bold = _load_terminal_font(TERMINAL_FONT_MONO_BOLD_PATH)
	_terminal_font_display = _load_terminal_font(TERMINAL_FONT_DISPLAY_PATH)
	var missing: Array[String] = []
	if _terminal_font_mono == null:
		missing.append(TERMINAL_FONT_MONO_PATH)
	if _terminal_font_mono_bold == null:
		missing.append(TERMINAL_FONT_MONO_BOLD_PATH)
	if _terminal_font_display == null:
		missing.append(TERMINAL_FONT_DISPLAY_PATH)
	if not missing.is_empty():
		_log_terminal_missing_assets(missing, "terminal_typography")


func _log_terminal_missing_assets(paths: Array[String], context: String) -> void:
	var message := "[TerminalAssets] Required asset missing; using runtime fallback. Missing: %s" % ", ".join(paths)
	push_warning(message)
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("mark_warning"):
		observatory.call("mark_warning", message, {
			"kind": "missing_ui_asset",
			"context": context,
			"paths": paths.duplicate(),
		})


func _load_terminal_font(path: String) -> Font:
	if not ResourceLoader.exists(path, "Font"):
		return null
	var resource := load(path)
	return resource as Font if resource is Font else null


func _apply_label_type(label: Label, font: Font, size: int, color: Color) -> void:
	if label == null:
		return
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.clip_text = true
	_set_control_property_if_available(label, &"text_overrun_behavior", TextServer.OVERRUN_TRIM_ELLIPSIS)


func _apply_button_type(button: BaseButton, font: Font, size: int, color: Color) -> void:
	if button == null:
		return
	if font != null:
		button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", color)
	if button is Button:
		(button as Button).clip_text = true
	_set_control_property_if_available(button, &"text_overrun_behavior", TextServer.OVERRUN_TRIM_ELLIPSIS)


func _apply_rich_text_type(rich_text: RichTextLabel, font: Font, mono_font: Font, size: int, color: Color) -> void:
	if rich_text == null:
		return
	if font != null:
		rich_text.add_theme_font_override("normal_font", font)
	if mono_font != null:
		rich_text.add_theme_font_override("mono_font", mono_font)
	if _terminal_font_mono_bold != null:
		rich_text.add_theme_font_override("bold_font", _terminal_font_mono_bold)
	rich_text.add_theme_font_size_override("normal_font_size", size)
	rich_text.add_theme_font_size_override("mono_font_size", size)
	rich_text.add_theme_font_size_override("bold_font_size", size)
	rich_text.add_theme_color_override("default_color", color)
	rich_text.bbcode_enabled = true
	rich_text.fit_content = false
	rich_text.scroll_active = true


func _set_control_property_if_available(control: Object, property_name: StringName, value: Variant) -> void:
	if control == null:
		return
	for property in control.get_property_list():
		if StringName(str(property.get("name", ""))) == property_name:
			control.set(property_name, value)
			return


func _configure_terminal_scroll_policy() -> void:
	if _terminal_main_scroll != null:
		_terminal_main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_terminal_main_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if _terminal_current_page in ["OVERVIEW", "FABRICATION"] else ScrollContainer.SCROLL_MODE_AUTO
		if _terminal_current_page in ["OVERVIEW", "FABRICATION"]:
			_terminal_main_scroll.scroll_vertical = 0
	if terminal_activity_scroll is ScrollContainer:
		var activity_scroll := terminal_activity_scroll as ScrollContainer
		activity_scroll.custom_minimum_size.y = 0.0
		activity_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		activity_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		activity_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	if terminal_output is RichTextLabel:
		var output := terminal_output as RichTextLabel
		output.custom_minimum_size = Vector2(0.0, 0.0)
		output.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		output.size_flags_vertical = Control.SIZE_EXPAND_FILL
		output.fit_content = false
		output.scroll_active = false
	if terminal_widget_stack == null:
		return
	for scroll in terminal_widget_stack.find_children("*", "ScrollContainer", true, false):
		if not (scroll is ScrollContainer):
			continue
		var scroll_container := scroll as ScrollContainer
		scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO


func _configure_terminal_nav_fit() -> void:
	var nav_rail := get_node_or_null("TerminalPanel/Body/NavRail") as VBoxContainer
	var page_buttons := nav_rail.find_child("PageButtons", true, false) as VBoxContainer if nav_rail != null else null
	var action_buttons := get_node_or_null("TerminalPanel/Body/NavRail/ActionButtons") as VBoxContainer
	var context_spacer := get_node_or_null("TerminalPanel/Body/NavRail/ContextSpacer") as Control
	if nav_rail != null:
		nav_rail.add_theme_constant_override("separation", 3)
	if page_buttons != null:
		page_buttons.add_theme_constant_override("separation", 1)
		if _terminal_page_buttons_scroll != null:
			_terminal_page_buttons_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			_terminal_page_buttons_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
			_terminal_page_buttons_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_terminal_page_buttons_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_terminal_page_buttons_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
		page_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for child in page_buttons.get_children():
			if child is BaseButton:
				(child as BaseButton).custom_minimum_size.y = 30.0
	if action_buttons != null:
		action_buttons.add_theme_constant_override("separation", 1)
		for child in action_buttons.get_children():
			if child is BaseButton:
				(child as BaseButton).custom_minimum_size.y = 20.0
	if context_spacer != null:
		context_spacer.custom_minimum_size.y = 2.0
	_configure_terminal_nav_groups()


func _bind_terminal_nav_wheel() -> void:
	var nav_rail := get_node_or_null("TerminalPanel/Body/NavRail") as Control
	var page_buttons := get_node_or_null("TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons") as Control
	for target in [nav_rail, _terminal_page_buttons_scroll, page_buttons]:
		if target is Control and not (target as Control).gui_input.is_connected(_on_terminal_nav_gui_input):
			(target as Control).gui_input.connect(_on_terminal_nav_gui_input)
	for button in _terminal_nav_buttons:
		if button is Control and not (button as Control).gui_input.is_connected(_on_terminal_nav_gui_input):
			(button as Control).gui_input.connect(_on_terminal_nav_gui_input)


func _on_terminal_nav_gui_input(event: InputEvent) -> void:
	if not _terminal_open or _terminal_page_buttons_scroll == null:
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index not in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		return
	var delta := -52 if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP else 52
	var scroll_bar := _terminal_page_buttons_scroll.get_v_scroll_bar()
	var max_scroll := maxi(0, int(ceil(scroll_bar.max_value - scroll_bar.page))) if scroll_bar != null else 0
	_terminal_page_buttons_scroll.scroll_vertical = clampi(_terminal_page_buttons_scroll.scroll_vertical + delta, 0, max_scroll)
	get_viewport().set_input_as_handled()


func _ensure_terminal_nav_button_visible(button: Control) -> void:
	if _terminal_page_buttons_scroll == null or button == null or not button.is_visible_in_tree():
		return
	if _terminal_page_buttons_scroll.is_ancestor_of(button):
		_terminal_page_buttons_scroll.ensure_control_visible(button)


func _refresh_terminal_nav_scroll() -> void:
	if _terminal_page_buttons_scroll == null:
		return
	var scroll_bar := _terminal_page_buttons_scroll.get_v_scroll_bar()
	if scroll_bar != null:
		var max_scroll := maxi(0, int(ceil(scroll_bar.max_value - scroll_bar.page)))
		_terminal_page_buttons_scroll.scroll_vertical = clampi(_terminal_page_buttons_scroll.scroll_vertical, 0, max_scroll)
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner is Control:
		if not (focus_owner as Control).is_visible_in_tree():
			if _terminal_more_button != null:
				_terminal_more_button.grab_focus()
		else:
			_ensure_terminal_nav_button_visible(focus_owner as Control)


func _make_fabrication_compact_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.05, 0.047, 0.92)
	style.border_color = Color(0.19, 0.43, 0.40, 0.84)
	style.set_border_width_all(1)
	style.content_margin_left = 4.0
	style.content_margin_top = 2.0
	style.content_margin_right = 4.0
	style.content_margin_bottom = 2.0
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style


func _configure_fabrication_dashboard_layout() -> void:
	if terminal_widget_stack == null:
		return
	var fabrication_widgets := terminal_widget_stack.get_node_or_null("FabricationWidgets") as VBoxContainer
	if fabrication_widgets == null:
		return
	fabrication_widgets.custom_minimum_size.x = 0.0
	fabrication_widgets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fabrication_widgets.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fabrication_widgets.add_theme_constant_override("separation", 2)

	var top_row := fabrication_widgets.get_node_or_null("TopRow") as BoxContainer
	var main_row := fabrication_widgets.get_node_or_null("MainRow") as HBoxContainer
	var bottom_row := fabrication_widgets.get_node_or_null("BottomRow") as HBoxContainer
	var action_row := fabrication_widgets.get_node_or_null("ActionRow") as HBoxContainer
	var status_panel := fabrication_widgets.find_child("FabStatusPanel", true, false) as Control
	var selected_panel := fabrication_widgets.find_child("FabSelectedRecipePanel", true, false) as Control
	var filter_panel := fabrication_widgets.find_child("FabCategoryPanel", true, false) as Control
	var recipe_panel := fabrication_widgets.find_child("FabRecipeListPanel", true, false) as Control
	var cost_panel := fabrication_widgets.find_child("FabCostPanel", true, false) as Control

	if top_row != null:
		top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.add_theme_constant_override("separation", 0)
		if status_panel != null:
			_ensure_child_parent(status_panel, top_row)
	if main_row != null:
		main_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		main_row.add_theme_constant_override("separation", 6)
		if filter_panel != null:
			_ensure_child_parent(filter_panel, main_row)
		if recipe_panel != null:
			_ensure_child_parent(recipe_panel, main_row)
	if selected_panel != null:
		_ensure_child_parent(selected_panel, fabrication_widgets)
	if cost_panel != null:
		_ensure_child_parent(cost_panel, fabrication_widgets)
	if bottom_row != null:
		_ensure_child_parent(bottom_row, fabrication_widgets)
	if action_row != null:
		_ensure_child_parent(action_row, fabrication_widgets)

	_order_fabrication_children(fabrication_widgets, [top_row, main_row, selected_panel, cost_panel, bottom_row, action_row])
	for panel in [status_panel, selected_panel, recipe_panel, cost_panel]:
		if panel == null:
			continue
		panel.custom_minimum_size.x = 0.0
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if status_panel != null:
		status_panel.custom_minimum_size = Vector2(0.0, 34.0)
		var status_title := status_panel.find_child("Title", true, false) as Label
		if status_title != null:
			status_title.visible = false
		var status_margin := status_panel.find_child("Margin", true, false) as MarginContainer
		if status_margin != null:
			status_margin.add_theme_constant_override("margin_top", 4)
			status_margin.add_theme_constant_override("margin_bottom", 4)
		status_panel.add_theme_stylebox_override("panel", _make_fabrication_compact_panel_style())
	if filter_panel != null:
		filter_panel.custom_minimum_size = Vector2(124.0, 0.0)
		filter_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		filter_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if recipe_panel != null:
		recipe_panel.custom_minimum_size.x = 0.0
		recipe_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		recipe_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var recipe_scroll := recipe_panel.find_child("RecipeScroll", true, false) as ScrollContainer
		if recipe_scroll != null:
			recipe_scroll.custom_minimum_size.y = 176.0
	if selected_panel != null:
		selected_panel.custom_minimum_size = Vector2(0.0, 142.0)
	if cost_panel != null:
		cost_panel.visible = false
		cost_panel.custom_minimum_size = Vector2(0.0, 0.0)
	if bottom_row != null:
		bottom_row.custom_minimum_size = Vector2(0.0, 36.0)
		bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if action_row != null:
		action_row.custom_minimum_size = Vector2(0.0, 34.0)
		action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_row.add_theme_constant_override("separation", 6)
		for child in action_row.get_children():
			if child is Button:
				var button := child as Button
				button.custom_minimum_size = Vector2(0.0, 32.0)
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				button.clip_text = true
				_apply_button_type(button, _terminal_font_mono_bold, TERMINAL_FONT_SIZE_BUTTON, Color(0.82, 0.92, 0.88, 1.0))
				_set_control_property_if_available(button, &"text_overrun_behavior", TextServer.OVERRUN_TRIM_ELLIPSIS)
	for scroll in fabrication_widgets.find_children("*", "ScrollContainer", true, false):
		if scroll is ScrollContainer:
			var scroll_container := scroll as ScrollContainer
			scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
			scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for body in fabrication_widgets.find_children("Body", "RichTextLabel", true, false):
		var rich_text := body as RichTextLabel
		rich_text.custom_minimum_size.x = 0.0
		rich_text.fit_content = false
		rich_text.scroll_active = false
		_apply_rich_text_type(rich_text, _terminal_font_mono, _terminal_font_mono, TERMINAL_FONT_SIZE_ROW, Color(0.82, 0.92, 0.88, 1.0))
	var fabrication_text_color := Color(1.0, 0.90, 0.76, 1.0) if _terminal_current_page == "FABRICATION" else Color(0.82, 0.92, 0.88, 1.0)
	var status_body := _get_fabrication_panel_body("FabStatusPanel")
	if status_body != null:
		status_body.custom_minimum_size = Vector2(0.0, 22.0)
		_apply_rich_text_type(status_body, _terminal_font_mono, _terminal_font_mono, TERMINAL_FONT_SIZE_HEADER, fabrication_text_color)
	var selected_body := _get_fabrication_panel_body("FabSelectedRecipePanel")
	if selected_body != null:
		selected_body.custom_minimum_size = Vector2(0.0, 112.0)
		_apply_rich_text_type(selected_body, _terminal_font_mono, _terminal_font_mono, TERMINAL_FONT_SIZE_ROW, fabrication_text_color)
	var filter_body := _get_fabrication_panel_body("FabCategoryPanel")
	if filter_body != null:
		filter_body.custom_minimum_size.y = 172.0
		_apply_rich_text_type(filter_body, _terminal_font_mono, _terminal_font_mono, TERMINAL_FONT_SIZE_HEADER, fabrication_text_color)
		filter_body.autowrap_mode = TextServer.AUTOWRAP_OFF


func _ensure_child_parent(child: Node, parent: Node) -> void:
	if child == null or parent == null or child.get_parent() == parent:
		return
	var old_parent := child.get_parent()
	if old_parent != null:
		old_parent.remove_child(child)
	parent.add_child(child)


func _order_fabrication_children(parent: Node, ordered_children: Array) -> void:
	var target_index := 0
	for child_variant in ordered_children:
		if not (child_variant is Node):
			continue
		var child := child_variant as Node
		if child.get_parent() != parent:
			continue
		parent.move_child(child, target_index)
		target_index += 1


func _apply_terminal_button_assets(button: BaseButton, normal: StyleBoxTexture, hover: StyleBoxTexture, pressed: StyleBoxTexture, disabled: StyleBoxTexture, focus: StyleBoxTexture, icon: Texture2D = null) -> void:
	if button == null:
		return
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", focus)
	if icon != null and button is Button:
		var concrete_button := button as Button
		concrete_button.icon = icon
		concrete_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT

func _terminal_page_icon(page_name: String) -> Texture2D:
	match page_name:
		"OVERVIEW":
			return TERMINAL_ICON_MAP
		"STATUS":
			return TERMINAL_ICON_CRITICAL
		"SECTORS":
			return TERMINAL_ICON_MAP
		"POWER":
			return TERMINAL_ICON_POWER
		"DEFENSE":
			return TERMINAL_ICON_DEFENSE
		"SENSORS":
			return TERMINAL_ICON_SCAN
		"INCIDENTS":
			return TERMINAL_ICON_WARNING
		"ARCHIVE":
			return TERMINAL_ICON_CONTRACT
		"RECON":
			return TERMINAL_ICON_RECON
		"CONTRACTS":
			return TERMINAL_ICON_CONTRACT
		"HISTORY":
			return TERMINAL_ICON_RESTART
		"SETTINGS":
			return TERMINAL_ICON_REPAIR
		"FABRICATION":
			return TERMINAL_ICON_FABRICATION
		_:
			return null

func _terminal_action_icon(button: BaseButton) -> Texture2D:
	if button == terminal_wait_button or button == terminal_wait_10x_button:
		return TERMINAL_ICON_SCAN
	if button == terminal_focus_button:
		return TERMINAL_ICON_POWER
	if button == terminal_harden_button:
		return TERMINAL_ICON_DEFENSE
	if button == terminal_reset_button or button == terminal_reboot_button:
		return TERMINAL_ICON_RESTART
	if button == terminal_help_button:
		return TERMINAL_ICON_WARNING
	return null

func _ensure_terminal_texture_overlays() -> void:
	if terminal_panel == null:
		return
	var backdrop := terminal_panel.get_node_or_null("StarterDarkBackdrop")
	if backdrop == null:
		backdrop = ColorRect.new()
		backdrop.name = "StarterDarkBackdrop"
		terminal_panel.add_child(backdrop)
		terminal_panel.move_child(backdrop, 0)
	var backdrop_rect := backdrop as ColorRect
	if backdrop_rect:
		backdrop_rect.color = TERMINAL_BACKDROP_COLOR
		backdrop_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backdrop_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		backdrop_rect.z_index = -1
	var scanline_overlay := terminal_panel.get_node_or_null("StarterScanlineOverlay")
	if scanline_overlay == null:
		scanline_overlay = TextureRect.new()
		scanline_overlay.name = "StarterScanlineOverlay"
		terminal_panel.add_child(scanline_overlay)
	var scanline_rect := scanline_overlay as TextureRect
	if scanline_rect:
		scanline_rect.texture = TERMINAL_SCANLINE_TEXTURE
		scanline_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scanline_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		scanline_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		scanline_rect.stretch_mode = TextureRect.STRETCH_TILE
		scanline_rect.modulate = Color(1.0, 1.0, 1.0, TERMINAL_SCANLINE_ALPHA)
		scanline_rect.z_index = TERMINAL_DECOR_OVERLAY_Z
	var noise_overlay := terminal_panel.get_node_or_null("StarterNoiseOverlay")
	if noise_overlay == null:
		noise_overlay = TextureRect.new()
		noise_overlay.name = "StarterNoiseOverlay"
		terminal_panel.add_child(noise_overlay)
	var noise_rect := noise_overlay as TextureRect
	if noise_rect:
		noise_rect.texture = TERMINAL_NOISE_TEXTURE
		noise_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		noise_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		noise_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		noise_rect.stretch_mode = TextureRect.STRETCH_TILE
		noise_rect.modulate = Color(1.0, 1.0, 1.0, TERMINAL_NOISE_ALPHA)
		noise_rect.z_index = TERMINAL_DECOR_OVERLAY_Z + 1

func _raise_terminal_command_entry_layer() -> void:
	var input_row := get_node_or_null("TerminalPanel/Body/CommandColumn/InputRow")
	for control in [input_row, terminal_input, terminal_status_label]:
		if control == null or not (control is CanvasItem):
			continue
		var canvas_item := control as CanvasItem
		canvas_item.z_index = TERMINAL_COMMAND_ENTRY_Z
		canvas_item.z_as_relative = true

func _apply_terminal_theme():
	_ensure_terminal_texture_overlays()
	_raise_terminal_command_entry_layer()
	_configure_terminal_scroll_policy()
	_configure_terminal_nav_fit()
	_configure_fabrication_dashboard_layout()
	var panel_style := _make_terminal_panel_style(10.0)
	var header_style := _make_terminal_header_style(TERMINAL_HEADER_ACTIVE_TEXTURE, 6.0)
	var output_style := _make_terminal_panel_style(8.0)
	var map_style := _make_terminal_map_style(10.0)
	var input_style := _make_terminal_input_style()
	var nav_button_style := _make_terminal_nav_style(TERMINAL_NAV_IDLE_TEXTURE, 3.0)
	var nav_button_hover_style := _make_terminal_nav_style(TERMINAL_NAV_HOVER_TEXTURE, 3.0)
	var nav_button_active_style := _make_terminal_nav_style(TERMINAL_NAV_ACTIVE_TEXTURE, 3.0)
	var nav_button_focus_style := _make_terminal_nav_style(TERMINAL_NAV_ACTIVE_TEXTURE, 3.0)
	var action_button_style := _make_terminal_button_style(TERMINAL_BUTTON_IDLE_TEXTURE, 4.0)
	var action_button_hover_style := _make_terminal_button_style(TERMINAL_BUTTON_HOVER_TEXTURE, 4.0)
	var action_button_pressed_style := _make_terminal_button_style(TERMINAL_BUTTON_PRESSED_TEXTURE, 4.0)
	var action_button_disabled_style := _make_terminal_button_style(TERMINAL_BUTTON_DISABLED_TEXTURE, 4.0)
	_debug_terminal_stylebox("panel", panel_style)
	_debug_terminal_stylebox("header", header_style)
	_debug_terminal_stylebox("output", output_style)
	_debug_terminal_stylebox("map", map_style)
	_debug_terminal_stylebox("input", input_style)
	_debug_terminal_stylebox("nav", nav_button_style)
	_debug_terminal_stylebox("button", action_button_style)
	if terminal_panel:
		terminal_panel.add_theme_stylebox_override("panel", panel_style)
		terminal_panel.modulate = Color(1, 1, 1, 1)

	if terminal_header_panel:
		terminal_header_panel.add_theme_stylebox_override("panel", header_style)

	for label in [terminal_nav_title, terminal_action_title, terminal_command_title, terminal_map_title_label, terminal_planet_title_label, terminal_map_preview_title_label]:
		if not (label is Label):
			continue
		_apply_label_type(label as Label, _terminal_font_display, TERMINAL_FONT_SIZE_SECTION, Color(0.63, 0.83, 0.74, 0.92))
	if _terminal_main_scroll:
		var main_scroll_style := StyleBoxFlat.new()
		main_scroll_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		main_scroll_style.set_border_width_all(0)
		_terminal_main_scroll.add_theme_stylebox_override("panel", main_scroll_style)

	if terminal_title_label is Label:
		_apply_label_type(terminal_title_label as Label, _terminal_font_display, TERMINAL_FONT_SIZE_TITLE, Color(0.93, 0.98, 0.95, 1.0))
	if terminal_header_eyebrow is Label:
		_apply_label_type(terminal_header_eyebrow as Label, _terminal_font_mono, TERMINAL_FONT_SIZE_HEADER, Color(0.63, 0.83, 0.74, 0.92))

	for chip in [terminal_time_chip, terminal_threat_chip, terminal_phase_chip, terminal_grid_chip]:
		if not (chip is Label):
			continue
		_apply_label_type(chip as Label, _terminal_font_mono, TERMINAL_FONT_SIZE_HEADER, Color(0.76, 0.92, 0.86, 0.95))
		var chip_style := StyleBoxFlat.new()
		chip_style.bg_color = Color(0.025, 0.08, 0.085, 0.88)
		chip_style.border_color = Color(0.22, 0.48, 0.44, 0.78)
		chip_style.set_border_width_all(1)
		chip_style.set_content_margin_all(5.0)
		(chip as Label).add_theme_stylebox_override("normal", chip_style)
	if terminal_page_summary_label is Label:
		_apply_label_type(terminal_page_summary_label as Label, _terminal_font_mono, TERMINAL_FONT_SIZE_HEADER, Color(0.62, 0.78, 0.72, 0.92))

	for output in [terminal_output, terminal_map_label]:
		if output == null:
			continue
		output.add_theme_stylebox_override("normal", map_style if output == terminal_map_label else output_style)
		if output is RichTextLabel:
			_apply_rich_text_type(output as RichTextLabel, _terminal_font_mono, _terminal_font_mono, TERMINAL_FONT_SIZE_BODY if output == terminal_map_label else TERMINAL_FONT_SIZE_LOG, Color(0.82, 0.92, 0.88, 1.0))
			(output as RichTextLabel).scroll_active = output != terminal_output
	if terminal_widget_stack:
		var widget_panel_style := _make_terminal_panel_style(8.0)
		for panel in terminal_widget_stack.find_children("*", "PanelContainer", true, false):
			panel.add_theme_stylebox_override("panel", widget_panel_style)
			panel.self_modulate = TERMINAL_DENSE_PANEL_MODULATE
		for rich_text in terminal_widget_stack.find_children("*", "RichTextLabel", true, false):
			_apply_rich_text_type(rich_text as RichTextLabel, _terminal_font_mono, _terminal_font_mono, TERMINAL_FONT_SIZE_BODY, Color(0.82, 0.92, 0.88, 1.0))
			if rich_text.custom_minimum_size.y > 0.0 and rich_text.custom_minimum_size.y < 130.0:
				rich_text.custom_minimum_size.y = min(rich_text.custom_minimum_size.y, 86.0)
			rich_text.scroll_following = false
		for label in terminal_widget_stack.find_children("*", "Label", true, false):
			_apply_label_type(label as Label, _terminal_font_display, TERMINAL_FONT_SIZE_SECTION, Color(0.63, 0.83, 0.74, 0.92))
		_apply_terminal_widget_button_styles(action_button_style, action_button_hover_style, action_button_pressed_style, action_button_disabled_style)
	if terminal_output:
		terminal_output.scroll_following = true
		terminal_output.custom_minimum_size = Vector2(0.0, 0.0)
		terminal_output.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		terminal_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
		terminal_output.fit_content = false
		terminal_output.scroll_active = false
	if terminal_activity_scroll:
		terminal_activity_scroll.custom_minimum_size.y = 0.0
		terminal_activity_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		terminal_activity_scroll.add_theme_stylebox_override("panel", output_style)
		terminal_activity_scroll.self_modulate = TERMINAL_DENSE_PANEL_MODULATE

	if terminal_input:
		terminal_input.visible = true
		terminal_input.focus_mode = Control.FOCUS_ALL
		terminal_input.custom_minimum_size.x = max(terminal_input.custom_minimum_size.x, 220.0)
		terminal_input.custom_minimum_size.y = max(terminal_input.custom_minimum_size.y, 44.0)
		terminal_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		terminal_input.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		terminal_input.add_theme_stylebox_override("normal", input_style)
		terminal_input.add_theme_stylebox_override("focus", input_style)
		terminal_input.add_theme_color_override("font_color", Color(0.96, 1.0, 0.98, 1.0))
		terminal_input.add_theme_color_override("font_placeholder_color", Color(0.70, 0.88, 0.79, 0.95))
		terminal_input.add_theme_color_override("font_selected_color", Color(0.02, 0.05, 0.04, 1.0))
		terminal_input.add_theme_color_override("selection_color", Color(0.68, 0.92, 0.80, 0.92))
		terminal_input.add_theme_color_override("caret_color", Color(0.96, 1.0, 0.98, 1.0))
		terminal_input.add_theme_constant_override("minimum_character_width", 1)
		if _terminal_font_mono != null:
			terminal_input.add_theme_font_override("font", _terminal_font_mono)
		terminal_input.add_theme_font_size_override("font_size", TERMINAL_FONT_SIZE_INPUT)
		terminal_input.self_modulate = Color(1, 1, 1, 1)
	var input_row = get_node_or_null("TerminalPanel/Body/CommandColumn/InputRow")
	if input_row is Control:
		var input_row_control := input_row as Control
		input_row_control.visible = true
		input_row_control.custom_minimum_size.y = max(input_row_control.custom_minimum_size.y, 48.0)
		input_row_control.size_flags_vertical = Control.SIZE_SHRINK_END
	var prompt_label = get_node_or_null("TerminalPanel/Body/CommandColumn/InputRow/Prompt")
	if prompt_label:
		if prompt_label is Control:
			var prompt_control := prompt_label as Control
			prompt_control.custom_minimum_size.y = max(prompt_control.custom_minimum_size.y, 42.0)
			prompt_control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if prompt_label is Label:
			_apply_label_type(prompt_label as Label, _terminal_font_mono_bold, TERMINAL_FONT_SIZE_INPUT, Color(0.78, 0.96, 0.86, 1.0))
	if terminal_status_label is Label:
		_apply_label_type(terminal_status_label as Label, _terminal_font_mono, TERMINAL_FONT_SIZE_HEADER, Color(0.64, 0.88, 0.78, 0.96))
	if terminal_hint_label is Label:
		_apply_label_type(terminal_hint_label as Label, _terminal_font_mono, TERMINAL_FONT_SIZE_HINT, Color(0.54, 0.72, 0.68, 0.88))
		_update_terminal_hint_visibility()
	for page_name in _terminal_page_buttons.keys():
		var button: BaseButton = _terminal_page_buttons[page_name]
		if button == null:
			continue
		_apply_terminal_button_assets(button, nav_button_style, nav_button_hover_style, nav_button_active_style, nav_button_active_style, nav_button_focus_style, _terminal_page_icon(page_name))
		button.add_theme_color_override("icon_normal_color", Color(1.0, 1.0, 1.0, 0.62))
		button.add_theme_color_override("icon_hover_color", Color(1.0, 1.0, 1.0, 0.82))
		button.add_theme_color_override("icon_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
		button.add_theme_color_override("icon_disabled_color", Color(1.0, 1.0, 1.0, 1.0))
		_apply_button_type(button, _terminal_font_display, TERMINAL_FONT_SIZE_NAV, Color(0.80, 0.92, 0.88, 1.0))
		button.add_theme_color_override("font_disabled_color", Color(0.95, 1.0, 0.97, 1.0))
	if _terminal_more_button != null:
		_apply_terminal_button_assets(_terminal_more_button, nav_button_style, nav_button_hover_style, nav_button_active_style, nav_button_active_style, nav_button_focus_style, TERMINAL_ICON_RESTART)
		_apply_button_type(_terminal_more_button, _terminal_font_display, TERMINAL_FONT_SIZE_NAV, Color(0.72, 0.88, 0.83, 1.0))
	for button in [terminal_wait_button, terminal_wait_10x_button, terminal_focus_button, terminal_harden_button, terminal_reset_button, terminal_reboot_button, terminal_help_button]:
		if button == null:
			continue
		_apply_terminal_button_assets(button, action_button_style, action_button_hover_style, action_button_pressed_style, action_button_disabled_style, action_button_pressed_style, _terminal_action_icon(button))
		_apply_button_type(button, _terminal_font_display, TERMINAL_FONT_SIZE_BUTTON, Color(0.74, 0.88, 0.82, 1.0))
	if primary_weapon_button:
		primary_weapon_button.add_theme_stylebox_override("normal", action_button_style)
		primary_weapon_button.add_theme_stylebox_override("hover", action_button_hover_style)
		primary_weapon_button.add_theme_stylebox_override("pressed", action_button_pressed_style)
		primary_weapon_button.add_theme_color_override("font_color", Color(0.88, 1.0, 0.92, 1.0))


func _ensure_fabrication_terminal_button() -> void:
	if terminal_fabrication_button != null and is_instance_valid(terminal_fabrication_button):
		return
	var nav_rail := get_node_or_null("TerminalPanel/Body/NavRail")
	var page_buttons_container := nav_rail.find_child("PageButtons", true, false) if nav_rail != null else null
	if page_buttons_container == null:
		return
	var existing := page_buttons_container.get_node_or_null("FabricationButton")
	if existing is BaseButton:
		terminal_fabrication_button = existing as BaseButton
		return
	var button := Button.new()
	button.name = "FabricationButton"
	button.text = "FABRICATION"
	button.focus_mode = Control.FOCUS_ALL
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 32)
	page_buttons_container.add_child(button)
	page_buttons_container.move_child(button, page_buttons_container.get_child_count() - 1)
	terminal_fabrication_button = button


func _ensure_terminal_more_button() -> void:
	if _terminal_more_button != null and is_instance_valid(_terminal_more_button):
		if not _terminal_more_button.pressed.is_connected(_toggle_terminal_secondary_nav):
			_terminal_more_button.pressed.connect(_toggle_terminal_secondary_nav)
		return
	var nav_rail := get_node_or_null("TerminalPanel/Body/NavRail")
	if nav_rail == null:
		return
	var existing := nav_rail.get_node_or_null("MoreButton")
	if existing is BaseButton:
		_terminal_more_button = existing as BaseButton
	else:
		_terminal_more_button = Button.new()
		_terminal_more_button.name = "MoreButton"
		_terminal_more_button.text = "MORE / SYSTEMS"
		_terminal_more_button.focus_mode = Control.FOCUS_ALL
		_terminal_more_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav_rail.add_child(_terminal_more_button)
		var context_spacer := nav_rail.get_node_or_null("ContextSpacer")
		if context_spacer != null:
			nav_rail.move_child(_terminal_more_button, context_spacer.get_index())
	if not _terminal_more_button.pressed.is_connected(_toggle_terminal_secondary_nav):
		_terminal_more_button.pressed.connect(_toggle_terminal_secondary_nav)
	_configure_terminal_nav_groups()


func _toggle_terminal_secondary_nav() -> void:
	_terminal_secondary_nav_expanded = not _terminal_secondary_nav_expanded
	_configure_terminal_nav_groups()
	_refresh_terminal_nav_scroll.call_deferred()


func _configure_terminal_nav_groups() -> void:
	var page_buttons_container := terminal_overview_button.get_parent() if terminal_overview_button != null else null
	if page_buttons_container == null:
		return
	var primary_order: Array[BaseButton] = [
		terminal_overview_button,
		terminal_sectors_button,
		terminal_power_button,
		terminal_defense_button,
		terminal_fabrication_button,
		terminal_sensors_button,
		terminal_archive_button,
		terminal_recon_button,
	]
	for button in primary_order:
		if button != null and button.get_parent() == page_buttons_container:
			page_buttons_container.move_child(button, page_buttons_container.get_child_count() - 1)
	var secondary_buttons: Array[BaseButton] = [
		terminal_status_button,
		terminal_incidents_button,
		terminal_contracts_button,
		terminal_history_button,
		terminal_settings_button,
	]
	var current_is_secondary := false
	for button in secondary_buttons:
		if button == null:
			continue
		var page_name := String(button.name).trim_suffix("Button").to_upper()
		if page_name == _terminal_current_page:
			current_is_secondary = true
	var show_secondary := _terminal_secondary_nav_expanded or current_is_secondary
	for button in secondary_buttons:
		if button != null:
			button.visible = show_secondary
			button.focus_mode = Control.FOCUS_ALL if show_secondary else Control.FOCUS_NONE
			if show_secondary and button.get_parent() == page_buttons_container:
				page_buttons_container.move_child(button, page_buttons_container.get_child_count() - 1)
	if _terminal_more_button != null:
		_terminal_more_button.text = "LESS / PRIMARY" if show_secondary else "MORE / SYSTEMS"
		_terminal_more_button.focus_mode = Control.FOCUS_ALL
	for secondary_action in [terminal_wait_10x_button, terminal_reset_button, terminal_reboot_button]:
		if secondary_action != null:
			secondary_action.visible = false
	_refresh_terminal_nav_scroll.call_deferred()


func _append_terminal_line(line: String, level: String = "info", sector: String = ""):
	_terminal_activity_autofollow = _is_terminal_activity_near_bottom()
	_terminal_lines.append(line)
	var entry := {
		"time": _get_terminal_sim_timestamp(),
		"line": line,
		"level": level,
		"sector": sector,
	}
	if line.begins_with("FOCUS SHIFTED TO ") and not _terminal_log_entries.is_empty():
		var last_index := _terminal_log_entries.size() - 1
		var last_entry: Dictionary = _terminal_log_entries[last_index]
		var last_line := str(last_entry.get("line", ""))
		var from_sector := ""
		if last_line.begins_with("FOCUS SHIFTED TO "):
			from_sector = last_line.trim_prefix("FOCUS SHIFTED TO ").strip_edges()
		elif last_line.begins_with("FOCUS SHIFTED: "):
			var arrow_index := last_line.rfind("→")
			if arrow_index > 0:
				from_sector = last_line.substr(15, arrow_index - 15).strip_edges()
		if not from_sector.is_empty():
			var to_sector := line.trim_prefix("FOCUS SHIFTED TO ").strip_edges()
			last_entry["time"] = entry["time"]
			last_entry["line"] = "FOCUS SHIFTED: %s → %s" % [from_sector, to_sector]
			last_entry["level"] = level
			last_entry["sector"] = sector
			_terminal_log_entries[last_index] = last_entry
			_render_terminal_output()
			return
	_terminal_log_entries.append(entry)
	if _terminal_log_entries.size() > TERMINAL_LOG_LIMIT:
		_terminal_log_entries = _terminal_log_entries.slice(_terminal_log_entries.size() - TERMINAL_LOG_LIMIT, _terminal_log_entries.size())
	_render_terminal_output()

func _render_terminal_output():
	if terminal_output == null:
		return
	var chunks: PackedStringArray = []
	if _terminal_current_page == "OVERVIEW":
		chunks.append_array(_build_terminal_attention_feed_chunks())
	var entries_to_render: Array = _terminal_log_entries
	if _terminal_current_page == "OVERVIEW" and entries_to_render.size() > 12:
		entries_to_render = entries_to_render.slice(entries_to_render.size() - 12, entries_to_render.size())
	if _terminal_current_page == "OVERVIEW" and _terminal_boot_complete:
		var non_boot_entries: Array = []
		var collapsed_boot_count := 0
		for entry in entries_to_render:
			if _is_terminal_boot_log_line(str(entry.get("line", ""))):
				collapsed_boot_count += 1
			else:
				non_boot_entries.append(entry)
		entries_to_render = non_boot_entries
		if collapsed_boot_count > 0:
			chunks.append("[color=#6FAE9C][BOOT][/color] [color=#8CA49D]BOOT LOG // %d PRIOR MESSAGES[/color]" % collapsed_boot_count)
	for entry in entries_to_render:
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
	if _terminal_current_page == "FABRICATION" and _terminal_command_queue.is_empty():
		chunks.append("\n[color=#e3b763][b]SELECT WORK ORDER[/b][/color]")
		chunks.append("[color=#d9c7a2]CRAFT 1[/color] starts selected recipe")
		chunks.append("[color=#d9c7a2]TO MAX[/color] crafts until capped or resources fail")
		chunks.append("[color=#9eb9ae]Esc closes terminal[/color]")
	if terminal_output is RichTextLabel:
		terminal_output.clear()
		terminal_output.append_text("\n".join(chunks))
	else:
		terminal_output.text = "\n".join(chunks)
	if _terminal_activity_autofollow:
		call_deferred("_scroll_terminal_output_to_bottom")


func _is_terminal_boot_log_line(line: String) -> bool:
	return line in TERMINAL_BOOT_LINES or line in [
		"--- COMMAND INTERFACE ACTIVE ---",
		"Awaiting directives.",
		"Type HELP for available commands.",
	]


func _build_terminal_attention_feed_chunks() -> PackedStringArray:
	var chunks := PackedStringArray()
	var timestamp := _get_terminal_sim_timestamp()
	var power_status := _get_power_status_snapshot()
	var reserve_rate := float(power_status.get("net", 0.0)) * 60.0
	var enemy_snapshot: Dictionary = _terminal_snapshot.get("enemies", {})
	var contacts := int(enemy_snapshot.get("total", 0))
	var threat_band := _get_threat_band(float(_terminal_snapshot.get("threat_raw", 0.0)))
	var recommended := "OPEN SECTORS"
	if reserve_rate < 0.0:
		recommended = "OPEN POWER"
	elif threat_band in ["ELEVATED", "CRITICAL"]:
		recommended = "OPEN DEFENSE"
	chunks.append("[color=#6FAE9C][%s][/color] [color=#9EDBFF]SYSTEM[/color]  [color=#D7E8E1]LOCAL SNAPSHOT MODE ACTIVE[/color]" % timestamp)
	chunks.append("[color=#6FAE9C][%s][/color] [color=#E8C86D]POWER[/color]   [color=#D7E8E1]GRID RESERVE %+0.0f // %s[/color]" % [timestamp, reserve_rate, "DEFICIT" if reserve_rate < 0.0 else "STABLE"])
	chunks.append("[color=#6FAE9C][%s][/color] [color=%s]SENSOR[/color]  [color=#D7E8E1]%d CONTACTS // %s CONFIDENCE[/color]" % [timestamp, "#F07A7A" if contacts > 0 else "#9EDBFF", contacts, "HIGH" if contacts > 0 else "LOW"])
	chunks.append("[color=#6FAE9C][%s][/color] [color=#7DDE9B]ACTION[/color]  [color=#D7E8E1]RECOMMENDED: %s[/color]\n" % [timestamp, recommended])
	return chunks


func _get_terminal_sim_timestamp() -> String:
	var snapshot_time := String(_terminal_snapshot.get("time", "")).strip_edges()
	if not snapshot_time.is_empty():
		return snapshot_time
	var game_state := _get_game_state()
	var tick := int(game_state.get("tick")) if game_state != null and "tick" in game_state else Engine.get_physics_frames()
	return _terminal_status_formatter.format_duration(float(tick) / 60.0)

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
		"success", "accepted", "stable":
			return "#7DDE9B"
		"warning", "power":
			return "#E8C86D"
		"critical", "threat", "assault":
			return "#F07A7A"
		"command", "system":
			return "#9EDBFF"
		"queued":
			return "#B7B6FF"
		_:
			return "#D7E8E1"

func _escape_bbcode(value: String) -> String:
	return value.replace("[", "[lb]").replace("]", "[rb]")

func _on_terminal_activity_meta_clicked(meta: Variant) -> void:
	var meta_text := str(meta)
	if meta_text.begins_with("terminal_action:"):
		_handle_terminal_action_link(meta_text.trim_prefix("terminal_action:"))
		return
	if not meta_text.begins_with("sector:"):
		return
	select_sector(meta_text.trim_prefix("sector:"))


func _connect_terminal_meta_links(root_node: Node) -> void:
	if root_node == null:
		return
	for rich_text in root_node.find_children("*", "RichTextLabel", true, false):
		var label := rich_text as RichTextLabel
		label.meta_underlined = true
		if not label.meta_clicked.is_connected(_on_terminal_activity_meta_clicked):
			label.meta_clicked.connect(_on_terminal_activity_meta_clicked)

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
	_terminal_boot_complete = false
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
	_terminal_boot_complete = true
	_render_terminal_output()
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
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()
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
			get_viewport().set_input_as_handled()
		KEY_DOWN:
			_recall_history_next()
			terminal_input.accept_event()
			get_viewport().set_input_as_handled()
		KEY_TAB:
			if _autocomplete_terminal_input(key_event.shift_pressed):
				terminal_input.accept_event()
			get_viewport().set_input_as_handled()

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
	var parsed := _terminal_command_router.parse(command)
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
	var handled := _terminal_command_router.execute(self, parsed)
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
	return _terminal_command_router.parse(command)

func _update_terminal_input_validation(raw_text: String) -> void:
	if terminal_status_label == null:
		return
	var input_echo := _format_terminal_input_echo(raw_text)
	var parsed := _terminal_command_router.parse(raw_text)
	var verb := str(parsed.get("verb", ""))
	if verb.is_empty():
		terminal_status_label.text = "READY // COMMAND BAR ACTIVE%s" % (" // > " + input_echo if not input_echo.is_empty() else "")
		return
	if _terminal_command_router.is_known_verb(verb):
		terminal_status_label.text = "VALIDATING // %s%s" % [verb, " // > " + input_echo if not input_echo.is_empty() else ""]
	else:
		terminal_status_label.text = "UNKNOWN VERB // %s%s" % [verb, " // > " + input_echo if not input_echo.is_empty() else ""]

func _should_refresh_snapshot(command_upper: String) -> bool:
	return _terminal_command_router.should_refresh_snapshot(command_upper)

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
	var phase_text := str(snapshot.get("contract_phase", "UNKNOWN")).replace("_", " ").to_upper()
	var threat_value := float(snapshot.get("threat_raw", 0.0))
	var threat_label := _get_threat_band(threat_value)
	var power_status := _get_power_status_snapshot()
	var reserve_rate := float(power_status.get("net", 0.0)) * 60.0
	var phase_short := _terminal_truncate(phase_text, 14)
	var grid_text := "GRID:STABLE"
	if reserve_rate < 0.0:
		grid_text = "GRID:%s" % _format_terminal_grid_rate(reserve_rate)
	if terminal_header_eyebrow:
		terminal_header_eyebrow.text = "CUSTODIAN NODE"
	if terminal_title_label:
		terminal_title_label.text = _terminal_current_page
	if terminal_time_chip:
		terminal_time_chip.text = "T:%s" % str(snapshot.get("time", "--:--" )).substr(0, 5)
	if terminal_threat_chip:
		terminal_threat_chip.text = "THREAT:%s" % threat_label
		terminal_threat_chip.add_theme_color_override("font_color", Color(_get_threat_color(threat_label)))
	if terminal_phase_chip:
		terminal_phase_chip.text = "PHASE:%s" % phase_short
	if terminal_grid_chip:
		terminal_grid_chip.text = grid_text
		terminal_grid_chip.add_theme_color_override("font_color", Color("#F07A7A" if reserve_rate < 0.0 else "#7DDE9B"))

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


func _terminal_truncate(value: String, max_chars: int) -> String:
	var compact := value.strip_edges()
	if compact.length() <= max_chars:
		return compact
	if max_chars <= 1:
		return "…"
	return compact.substr(0, max_chars - 1) + "…"


func format_sector_state(sector: Dictionary) -> String:
	var status := str(sector.get("status", "UNKNOWN")).strip_edges().to_upper()
	if status.is_empty():
		return "UNKNOWN"
	return status


func format_power(sector: Dictionary) -> String:
	if sector.has("power_allocated") or sector.has("power_standard"):
		var allocated := float(sector.get("power_allocated", 0.0))
		var capacity := float(sector.get("power_standard", 0.0))
		if is_equal_approx(allocated, round(allocated)) and is_equal_approx(capacity, round(capacity)):
			return "%d/%d" % [int(round(allocated)), int(round(capacity))]
		return "%.1f/%.1f" % [allocated, capacity]
	var tier := str(sector.get("power_tier", "UNKNOWN")).strip_edges().to_upper()
	return "UNKNOWN" if tier.is_empty() else tier


func _sector_threat_state(sector: Dictionary) -> String:
	var status := format_sector_state(sector)
	var hp_pct := int(sector.get("hp_pct", 100))
	if status in ["ASSAULT", "CRITICAL", "COMPROMISED", "OFFLINE"]:
		return status
	if hp_pct <= 30:
		return "CRITICAL"
	if hp_pct < 70:
		return "LOW"
	if status in ["DAMAGED", "DEGRADED", "WARNING"]:
		return "LOW"
	return "NONE"


func severity_color(value: String) -> String:
	var key := value.strip_edges().to_upper()
	if key in ["OPERATIONAL", "STABLE", "ONLINE", "NOMINAL", "NONE"]:
		return "#7DDE9B"
	if key in ["DEGRADED", "WARNING", "LOW", "ELEVATED"]:
		return "#E8C86D"
	if key in ["DAMAGED", "CRITICAL", "ASSAULT", "COMPROMISED", "OFFLINE"]:
		return "#F07A7A"
	if key in ["SELECTED", "PINNED"]:
		return "#9EDBFF"
	return "#7F9EAF"


func _format_sector_hp(sector: Dictionary) -> String:
	if not sector.has("hp_pct"):
		return "UNK"
	return "%3d%%" % int(sector.get("hp_pct", 0))


func _format_sector_bar(sector: Dictionary, width: int = 12) -> String:
	if not sector.has("hp_pct"):
		return "[color=#5F7580]%s[/color]" % "·".repeat(width)
	var hp_pct: int = clampi(int(sector.get("hp_pct", 0)), 0, 100)
	var filled: int = clampi(int(round(float(width) * float(hp_pct) / 100.0)), 0, width)
	var empty: int = max(0, width - filled)
	var color := severity_color("CRITICAL" if hp_pct <= 30 else ("WARNING" if hp_pct < 70 else "STABLE"))
	return "[color=%s]%s[/color][color=#2F4A52]%s[/color]" % [color, "█".repeat(filled), "░".repeat(empty)]


func _terminal_divider() -> String:
	return "=============================="


func _format_terminal_rate(rate: float) -> String:
	if is_equal_approx(rate, round(rate)):
		return "%dX" % int(round(rate))
	return "%.1fX" % rate


func _format_terminal_grid_rate(value: float) -> String:
	if absf(value) >= 1000.0:
		return "%+.1fK/s" % (value / 1000.0)
	return "%+.0f/s" % value


func _set_terminal_page(page_name: String) -> void:
	var normalized := page_name.to_upper()
	if not _terminal_page_buttons.has(normalized):
		return
	_terminal_current_page = normalized
	_refresh_terminal_page_buttons()
	_apply_terminal_page_theme()
	_render_terminal_output()
	if _terminal_open:
		_refresh_snapshot()
	if _terminal_open or terminal_input != null:
		call_deferred("_ensure_terminal_input_visible_and_focused")
	_debug_terminal_input_layout("_set_terminal_page")


func _apply_terminal_page_theme() -> void:
	var fabrication_mode := _terminal_current_page == "FABRICATION"
	_apply_terminal_page_layout()
	_configure_terminal_scroll_policy()
	_configure_terminal_nav_fit()
	if terminal_panel:
		terminal_panel.add_theme_stylebox_override("panel", _make_terminal_panel_style(10.0))
		terminal_panel.self_modulate = Color(1.0, 0.92, 0.72, 1.0) if fabrication_mode else Color(1, 1, 1, 1)
	if terminal_header_panel:
		var header_texture: Texture2D = TERMINAL_HEADER_WARNING_TEXTURE if fabrication_mode else TERMINAL_HEADER_ACTIVE_TEXTURE
		terminal_header_panel.add_theme_stylebox_override("panel", _make_terminal_header_style(header_texture, 6.0))
	if terminal_title_label is Label:
		_apply_label_type(terminal_title_label as Label, _terminal_font_display, TERMINAL_FONT_SIZE_TITLE, Color(0.98, 0.90, 0.72, 1.0) if fabrication_mode else Color(0.93, 0.98, 0.95, 1.0))
	if terminal_header_eyebrow is Label:
		_apply_label_type(terminal_header_eyebrow as Label, _terminal_font_mono, TERMINAL_FONT_SIZE_HEADER, Color(0.98, 0.74, 0.42, 0.92) if fabrication_mode else Color(0.63, 0.83, 0.74, 0.92))
	if terminal_nav_title is Label:
		_apply_label_type(terminal_nav_title as Label, _terminal_font_display, TERMINAL_FONT_SIZE_SECTION, Color(0.98, 0.74, 0.42, 0.92) if fabrication_mode else Color(0.63, 0.83, 0.74, 0.92))
	if terminal_action_title is Label:
		_apply_label_type(terminal_action_title as Label, _terminal_font_display, TERMINAL_FONT_SIZE_SECTION, Color(0.98, 0.74, 0.42, 0.92) if fabrication_mode else Color(0.63, 0.83, 0.74, 0.92))
		terminal_action_title.text = "TERMINAL ACTIONS" if fabrication_mode else "ACTIONS"
	if terminal_status_label is Label:
		_apply_label_type(terminal_status_label as Label, _terminal_font_mono, TERMINAL_FONT_SIZE_HEADER, Color(1.0, 0.78, 0.48, 0.96) if fabrication_mode else Color(0.64, 0.88, 0.78, 0.96))
	if terminal_hint_label is Label:
		_apply_label_type(terminal_hint_label as Label, _terminal_font_mono, TERMINAL_FONT_SIZE_HINT, Color(0.96, 0.79, 0.54, 0.88) if fabrication_mode else Color(0.54, 0.72, 0.68, 0.88))
		terminal_hint_label.text = "Click a work order. Esc closes." if fabrication_mode else ("Type commands or inspect the live tactical map. Esc closes." if _terminal_current_page == "OVERVIEW" else "Type directly into the command line. Drag globe where available. Esc closes.")
	if terminal_input:
		var input_style := _make_terminal_input_style()
		terminal_input.visible = true
		terminal_input.focus_mode = Control.FOCUS_ALL
		terminal_input.custom_minimum_size.x = max(terminal_input.custom_minimum_size.x, 220.0)
		terminal_input.custom_minimum_size.y = max(terminal_input.custom_minimum_size.y, 44.0)
		terminal_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		terminal_input.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		terminal_input.add_theme_stylebox_override("normal", input_style)
		terminal_input.add_theme_stylebox_override("focus", input_style)
		terminal_input.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88, 1.0) if fabrication_mode else Color(0.96, 1.0, 0.98, 1.0))
		terminal_input.add_theme_color_override("font_placeholder_color", Color(0.92, 0.74, 0.46, 0.92) if fabrication_mode else Color(0.70, 0.88, 0.79, 0.95))
		terminal_input.add_theme_color_override("font_selected_color", Color(0.18, 0.10, 0.02, 1.0) if fabrication_mode else Color(0.02, 0.05, 0.04, 1.0))
		terminal_input.add_theme_color_override("selection_color", Color(0.96, 0.72, 0.28, 0.92) if fabrication_mode else Color(0.68, 0.92, 0.80, 0.92))
		terminal_input.add_theme_color_override("caret_color", Color(1.0, 0.96, 0.88, 1.0) if fabrication_mode else Color(0.96, 1.0, 0.98, 1.0))
		terminal_input.add_theme_constant_override("minimum_character_width", 1)
		if _terminal_font_mono != null:
			terminal_input.add_theme_font_override("font", _terminal_font_mono)
		terminal_input.add_theme_font_size_override("font_size", TERMINAL_FONT_SIZE_INPUT)
		terminal_input.self_modulate = Color(1, 1, 1, 1)
	_update_terminal_hint_visibility()
	_debug_terminal_input_layout("_apply_terminal_page_theme")
	for output in [terminal_output, terminal_map_label]:
		if output == null:
			continue
		if output is RichTextLabel:
			var rich_output := output as RichTextLabel
			_apply_rich_text_type(rich_output, _terminal_font_mono, _terminal_font_mono, TERMINAL_FONT_SIZE_LOG if output == terminal_output else TERMINAL_FONT_SIZE_BODY, Color(1.0, 0.90, 0.76, 1.0) if fabrication_mode else Color(0.82, 0.92, 0.88, 1.0))
			rich_output.add_theme_color_override("selection_color", Color(0.98, 0.72, 0.28, 0.92) if fabrication_mode else Color(0.68, 0.92, 0.80, 0.92))
	if terminal_background and fabrication_mode:
		terminal_background.modulate = Color(1.0, 0.92, 0.72, 1.0)
	elif terminal_background:
		terminal_background.modulate = Color(1, 1, 1, 1)
	if terminal_widget_stack:
		var widget_panel_style := _make_terminal_panel_style(8.0)
		var action_button_style := _make_terminal_button_style(TERMINAL_BUTTON_IDLE_TEXTURE, 6.0)
		var action_button_hover_style := _make_terminal_button_style(TERMINAL_BUTTON_HOVER_TEXTURE, 6.0)
		var action_button_pressed_style := _make_terminal_button_style(TERMINAL_BUTTON_PRESSED_TEXTURE, 6.0)
		var action_button_disabled_style := _make_terminal_button_style(TERMINAL_BUTTON_DISABLED_TEXTURE, 6.0)
		for panel in terminal_widget_stack.find_children("*", "PanelContainer", true, false):
			panel.add_theme_stylebox_override("panel", widget_panel_style)
			panel.self_modulate = TERMINAL_DENSE_PANEL_MODULATE
		for rich_text in terminal_widget_stack.find_children("*", "RichTextLabel", true, false):
			_apply_rich_text_type(rich_text as RichTextLabel, _terminal_font_mono, _terminal_font_mono, TERMINAL_FONT_SIZE_BODY, Color(1.0, 0.90, 0.76, 1.0) if fabrication_mode else Color(0.82, 0.92, 0.88, 1.0))
			rich_text.scroll_following = false
		for label in terminal_widget_stack.find_children("*", "Label", true, false):
			_apply_label_type(label as Label, _terminal_font_display, TERMINAL_FONT_SIZE_SECTION, Color(0.98, 0.74, 0.42, 0.92) if fabrication_mode else Color(0.63, 0.83, 0.74, 0.92))
		if terminal_overview_widgets != null:
			for overview_body in terminal_overview_widgets.find_children("*", "RichTextLabel", true, false):
				_apply_rich_text_type(overview_body as RichTextLabel, _terminal_font_mono, _terminal_font_mono, TERMINAL_FONT_SIZE_HEADER, Color(0.82, 0.92, 0.88, 1.0))
				(overview_body as RichTextLabel).scroll_active = false
		_apply_terminal_widget_button_styles(action_button_style, action_button_hover_style, action_button_pressed_style, action_button_disabled_style)
		_configure_fabrication_dashboard_layout()
	if terminal_output is RichTextLabel:
		terminal_output.scroll_following = true


func _refresh_terminal_page_buttons() -> void:
	for page_name in _terminal_page_buttons.keys():
		var button: BaseButton = _terminal_page_buttons[page_name]
		if button == null:
			continue
		var active: bool = String(page_name) == _terminal_current_page
		button.disabled = active
		button.text = ("> %s" % String(page_name)) if active else String(page_name)
	_configure_terminal_nav_groups()

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


func _set_terminal_rich_text(target: Node, text: String, auto_scroll_bottom: bool = false) -> void:
	if target == null:
		return
	if target is RichTextLabel:
		target.clear()
		target.append_text(text)
		if auto_scroll_bottom and target != terminal_sector_list_body and target != terminal_sector_detail_body:
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
	_set_terminal_rich_text(terminal_map_label, "\n".join(lines), false)


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
		hostile_text = "%d | D%d F%d H%d S%d L%d" % [
			int(enemies.get("total", 0)),
			int(enemies.get("drone", 0)),
			int(enemies.get("fast", 0)),
			int(enemies.get("heavy", 0)),
			int(enemies.get("searching_storage", 0)),
			int(enemies.get("carrying_loot", 0)),
		]
	var vault: Dictionary = snapshot.get("vault", {})
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
		"vault": vault,
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
			_render_terminal_overview_widgets(snapshot, context)
			return "DEFAULT COMMAND SURFACE // SUMMARY, POWER, ASSAULT, PRIORITIES"
		"STATUS":
			_render_terminal_status_widgets(snapshot)
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
			_render_terminal_sensors_widgets(threat_text, hostile_text, wave_text, assault_value, sector_array, snapshot.get("arrn", {}))
			return "SENSOR FIDELITY // CONTACTS, THREAT LANES, ACTIVITY"
		"INCIDENTS":
			_render_terminal_incidents_widgets()
			return "EVENT TRIAGE // RECENT TRANSCRIPT SIGNALS AND ALERTS"
		"ARCHIVE":
			_render_terminal_archive_widgets(contract, snapshot.get("arrn", {}))
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
		"FABRICATION":
			_render_terminal_fabrication_widgets()
			return "FABRICATION SHELL // RESOURCES, RECIPES, BUILD TOKENS"
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
	var show_fabrication := page_name == "FABRICATION"
	var using_widgets := show_overview or show_sectors or show_power or show_defense or show_sensors or show_incidents or show_archive or show_recon or show_contracts or show_history or show_status or show_settings or show_fabrication
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
	if terminal_widget_stack:
		var fabrication_widgets := terminal_widget_stack.get_node_or_null("FabricationWidgets")
		if fabrication_widgets:
			fabrication_widgets.visible = show_fabrication
	if terminal_map_label:
		terminal_map_label.visible = not using_widgets
	if show_fabrication:
		for control in [terminal_planet_title_label, terminal_planet_preview, terminal_map_preview_title_label, terminal_map_preview]:
			if control is CanvasItem:
				(control as CanvasItem).visible = false


func _render_terminal_overview_widgets(snapshot: Dictionary, context: Dictionary) -> void:
	var view_model := _terminal_overview_view_model.build(snapshot)
	var phase_text := String(context.get("phase_text", "UNKNOWN"))
	var enemy_snapshot: Dictionary = snapshot.get("enemies", {}) if snapshot.get("enemies", {}) is Dictionary else {}
	var power_status: Dictionary = context.get("power_status", {})
	var threat_text: Variant = context.get("threat_text", "?")
	var assault_value: Variant = context.get("assault_value", "?")
	var wave_text := String(context.get("wave_text", "--"))
	_set_terminal_rich_text(terminal_overview_operational_body, "\n".join([
		"%s/%s | %s" % [_terminal_truncate(String(snapshot.get("terminal_mode", &"field")).to_upper(), 3), _terminal_truncate(String(snapshot.get("fidelity", &"lost")).to_upper(), 4), _terminal_truncate(phase_text, 8)],
		"OP %s | POST %s" % [_terminal_truncate(String(view_model.get("operator_location", "UNKNOWN")).to_upper(), 8), "YES" if bool(snapshot.get("command_center_occupied", false)) else "NO"],
		"HOST %d | CMP %d | OFF %d" % [int(enemy_snapshot.get("total", 0)), int(snapshot.get("systems_compromised_count", 0)), int(view_model.get("systems_offline_count", 0))],
	]))
	_set_terminal_rich_text(terminal_overview_power_body, "\n".join([
		"NET      %+0.1f/s" % (float(power_status.get("net", 0.0)) * 60.0),
		"GEN %.1f // DRAW %.1f" % [float(power_status.get("generated", 0.0)) * 60.0, float(power_status.get("consumed", 0.0)) * 60.0],
		"COLD START %d // OFFLINE %d" % [int(view_model.get("cold_start_systems_count", 0)), int(view_model.get("systems_offline_count", 0))],
	]))
	_set_terminal_rich_text(terminal_overview_assault_body, "\n".join([
		_terminal_kv("THREAT", threat_text),
		_terminal_kv("ASSAULT", assault_value),
		_terminal_kv("WAVE", wave_text),
		_terminal_kv("DEFENSE", snapshot.get("defense_rating", 0.0)),
	]))
	var priority_lines: Array[String] = []
	var priority_sectors: Array = view_model.get("priority_sectors", [])
	for sector_variant in priority_sectors.slice(0, min(2, priority_sectors.size())):
		if not (sector_variant is Dictionary):
			continue
		var sector: Dictionary = sector_variant
		var raw_name := str(sector.get("name", sector.get("id", "SECTOR")))
		var display := _terminal_truncate(_display_sector_name(raw_name).to_upper(), 8)
		var status := str(sector.get("status", "UNKNOWN")).to_upper()
		var priority_line := "%-8s %3s%% %s" % [display, str(sector.get("hp_pct", "?")), _terminal_truncate(status, 6)]
		priority_lines.append("[url=terminal_action:focus_sector:%s][color=#9EDBFF]%s[/color][/url]" % [_escape_bbcode(raw_name), priority_line])
	if priority_lines.is_empty():
		priority_lines.append("NO PRIORITY SECTORS AVAILABLE")
	_set_terminal_rich_text(terminal_overview_priority_body, "\n".join(priority_lines))
	var incident_lines: Array[String] = []
	var active_incidents: Array = view_model.get("active_incidents", [])
	for incident_variant in active_incidents.slice(0, min(2, active_incidents.size())):
		if incident_variant is Dictionary:
			incident_lines.append(_terminal_truncate(String((incident_variant as Dictionary).get("label", "INCIDENT")), 24))
	if incident_lines.is_empty():
		incident_lines.append("NO ACTIVE CRITICAL INCIDENTS")
	incident_lines.append("[url=terminal_action:open_incidents][color=#7DDE9B]> OPEN INCIDENTS[/color][/url]")
	_set_terminal_rich_text(terminal_overview_incident_body, "\n".join(incident_lines))
	var recommendations: Array = view_model.get("recommendations", [])
	var primary_recommendation: Dictionary = recommendations[0] if not recommendations.is_empty() and recommendations[0] is Dictionary else {}
	var recommendation_action := String(primary_recommendation.get("action", "open_sectors"))
	var recommendation := String(primary_recommendation.get("label", "OPEN SECTORS // VERIFY PRIORITY"))
	_set_terminal_rich_text(terminal_overview_contract_body, "[url=terminal_action:%s][color=#7DDE9B]> %s[/color][/url]" % [recommendation_action, recommendation])


func _render_terminal_sector_widgets(sector_array: Array, selected_sector: Dictionary) -> void:
	refresh_sector_table(sector_array)
	refresh_sector_detail(selected_sector)


func refresh_sector_table(sector_array: Array) -> void:
	var list_lines: Array[String] = [
		"[color=#9CCEBB][code]  NAME            STATE       HP   POWER   PRIORITY THREAT[/code][/color]",
		"[color=#33565C][code]  ──────────────  ──────────  ───  ─────── ──────── ────────[/code][/color]",
	]
	for sector_variant in sector_array:
		if not (sector_variant is Dictionary):
			continue
		var sector: Dictionary = sector_variant
		var raw_name := str(sector.get("name", sector.get("id", "SECTOR")))
		var display := _terminal_truncate(_display_sector_name(raw_name).to_upper(), 14)
		var state := _terminal_truncate(format_sector_state(sector), 10)
		var threat := _terminal_truncate(_sector_threat_state(sector), 8)
		var priority := str(sector.get("power_priority", "UNK"))
		var selected := _resolve_terminal_sector_name(raw_name) == _terminal_highlight_sector
		var row_color := "#F2F1D0" if selected else severity_color(state)
		var prefix := "▶" if selected else " "
		var row := "%s %-14s  %-10s  %3s  %-7s %8s %-8s" % [
			prefix,
			display,
			state,
			_format_sector_hp(sector),
			_terminal_truncate(format_power(sector), 7),
			_terminal_truncate(priority, 8),
			threat,
		]
		list_lines.append("[url=sector:%s][color=%s][code]%s[/code][/color][/url]" % [
			_escape_bbcode(raw_name),
			row_color,
			_escape_bbcode(row),
		])
	if sector_array.is_empty():
		list_lines.append("[color=#7F9EAF][code]   NO SECTOR DATA AVAILABLE[/code][/color]")
	_set_terminal_rich_text(terminal_sector_list_body, "\n".join(list_lines))


func refresh_sector_detail(selected_sector: Dictionary) -> void:
	var detail_lines: Array[String] = []
	if not selected_sector.is_empty():
		var raw_name := str(selected_sector.get("name", "SECTOR"))
		var state := format_sector_state(selected_sector)
		var threat := _sector_threat_state(selected_sector)
		var action_sector := _escape_bbcode(raw_name)
		var power_enabled := selected_sector.has("power_allocated") or selected_sector.has("power_standard") or selected_sector.has("power_tier")
		detail_lines = [
			"[color=#DCEBE5][code]%s // %s[/code][/color]" % [
				_escape_bbcode(_terminal_truncate(_display_sector_name(raw_name).to_upper(), 18)),
				_escape_bbcode(state),
			],
			"",
			"HP           [color=#DCEBE5]%s[/color]  %s" % [
				_escape_bbcode(_format_sector_hp(selected_sector)),
				_format_sector_bar(selected_sector, 16),
			],
			"POWER        [color=#DCEBE5]%s[/color]" % _escape_bbcode(format_power(selected_sector)),
			"PRIORITY     [color=#DCEBE5]%s[/color]" % _escape_bbcode(str(selected_sector.get("power_priority", "UNKNOWN"))),
			"THREAT       [color=%s]%s[/color]" % [
				severity_color(threat),
				_escape_bbcode(threat),
			],
			"DEFENSES     [color=#DCEBE5]%s[/color]" % _escape_bbcode(_sector_defense_summary(raw_name)),
			"INCIDENTS    [color=%s]%s[/color]" % [
				severity_color(state),
				_escape_bbcode(_sector_incident_summary(selected_sector)),
			],
			"",
			_terminal_section("AVAILABLE COMMANDS"),
			_terminal_action_link("OPEN POWER VIEW", "open_power:%s" % action_sector, power_enabled),
			_terminal_action_link("PIN SECTOR", "pin:%s" % action_sector, true),
			_terminal_action_link("SET PRIORITY", "set_priority:%s" % action_sector, power_enabled),
			_terminal_action_link("TRACK INCIDENTS", "track_incidents:%s" % action_sector, true),
		]
	else:
		detail_lines = [
			"[color=#7F9EAF]NO SECTOR SELECTED[/color]",
			"Select a sector row or minimap marker.",
			"",
			_terminal_action_link("OPEN POWER VIEW", "open_power:", false),
			_terminal_action_link("PIN SECTOR", "pin:", false),
			_terminal_action_link("SET PRIORITY", "set_priority:", false),
			_terminal_action_link("TRACK INCIDENTS", "track_incidents:", false),
		]
	_set_terminal_rich_text(terminal_sector_detail_body, "\n".join(detail_lines))


func _terminal_action_link(label: String, action: String, enabled: bool) -> String:
	if not enabled:
		return "[color=#4E6268][code]  %-18s  DISABLED[/code][/color]" % label
	return "[url=terminal_action:%s][color=#9EDBFF][code]› %-18s  READY[/code][/color][/url]" % [
		_escape_bbcode(action),
		label,
	]


func _sector_defense_summary(sector_name: String) -> String:
	var resolved := _resolve_terminal_sector_name(sector_name)
	if resolved.is_empty():
		return "UNKNOWN"
	var count := 0
	for turret in get_tree().get_nodes_in_group("turret"):
		if turret == null:
			continue
		var parent := turret.get_parent()
		while parent != null:
			var parent_name := str(parent.get("sector_name") if "sector_name" in parent else parent.name).strip_edges().to_upper()
			if parent_name == resolved:
				count += 1
				break
			parent = parent.get_parent()
	return "%d ACTIVE" % count if count > 0 else "NONE REPORTED"


func _sector_incident_summary(sector: Dictionary) -> String:
	var state := format_sector_state(sector)
	var hp_pct := int(sector.get("hp_pct", 100))
	if state in ["DAMAGED", "DEGRADED", "WARNING", "CRITICAL", "ASSAULT", "COMPROMISED", "OFFLINE"]:
		return state
	if hp_pct < 100:
		return "REPAIR RECOMMENDED"
	return "NO ACTIVE INCIDENTS"


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


func _render_terminal_sensors_widgets(threat_text: Variant, hostile_text: String, wave_text: String, assault_value: Variant, sector_array: Array, arrn_snapshot: Dictionary) -> void:
	var arrn_fidelity := str(arrn_snapshot.get("fidelity", "FULL")).to_upper() if not arrn_snapshot.is_empty() else "FULL"
	var threat_bonus := 0
	var arrn_manager := _get_arrn_manager()
	if arrn_manager != null and arrn_manager.has_method("get_threat_warning_tick_bonus"):
		threat_bonus = int(arrn_manager.call("get_threat_warning_tick_bonus"))
	_set_terminal_rich_text(terminal_sensors_fidelity_body, "\n".join([
		_terminal_kv("THREAT", threat_text),
		_terminal_kv("HOSTILES", hostile_text),
		_terminal_kv("WAVE", wave_text),
		_terminal_kv("MODE", "%s COMMAND CLARITY" % arrn_fidelity),
		_terminal_kv("ARRN", "%d/%d" % [int(arrn_snapshot.get("knowledge_index", 0)), int(arrn_snapshot.get("knowledge_max", 7))]),
	]))
	_set_terminal_rich_text(terminal_sensors_prediction_body, "\n".join([
		"LIKELY INGRESS AXIS  %s" % str(assault_value),
		"WAVE PROFILE         %s" % wave_text,
		"CONTACT CONFIDENCE   %s" % ("RAISED" if threat_bonus > 0 else "HIGH"),
		"FORECAST BONUS       +%d TICKS" % threat_bonus,
	]))
	var activity_lines: Array[String] = []
	if not arrn_snapshot.is_empty():
		activity_lines.append("ARRN RELAY NETWORK")
		for relay_variant in arrn_snapshot.get("relays", []):
			if not (relay_variant is Dictionary):
				continue
			var relay: Dictionary = relay_variant
			activity_lines.append("%-10s %-8s %3d%% %s" % [
				str(relay.get("relay_id", "RELAY")).to_upper(),
				str(relay.get("status", "UNKNOWN")).to_upper(),
				int(round(float(relay.get("stability", 0.0)))),
				str(relay.get("sector_id", "UNKNOWN")).to_upper(),
			])
	else:
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


func _render_terminal_archive_widgets(contract: Dictionary, arrn_snapshot: Dictionary = {}) -> void:
	var world_profile: Dictionary = contract.get("world_profile", {})
	_set_terminal_rich_text(terminal_archive_integrity_body, "\n".join([
		_terminal_kv("STATE", "NOMINAL"),
		_terminal_kv("PLANET", str(contract.get("planet_key", "UNKNOWN")).to_upper()),
		_terminal_kv("PROFILE", str(world_profile.get("world_label", "UNCLASSIFIED")).to_upper()),
		_terminal_kv("ARRN", "%d/%d" % [int(arrn_snapshot.get("knowledge_index", 0)), int(arrn_snapshot.get("knowledge_max", 7))]),
	]))
	var benefit_lines: Array[String] = []
	for label in arrn_snapshot.get("benefit_labels", []):
		benefit_lines.append(str(label))
	if benefit_lines.is_empty():
		benefit_lines = [
		"GOVERNANCE",
		"INFRASTRUCTURE",
		"WARFARE",
		"UNKNOWN",
		]
	_set_terminal_rich_text(terminal_archive_categories_body, "\n".join(benefit_lines))
	_set_terminal_rich_text(terminal_archive_detail_body, "\n".join([
		"FOLIAGE %.2f | OPEN %.2f | COMPOUND %.2f" % [
			float(world_profile.get("foliage_density", 0.0)),
			float(world_profile.get("open_layout_chance", 0.0)),
			float(world_profile.get("compound_area_ratio", 0.0)),
		],
		"TRACK: %s" % str(arrn_snapshot.get("knowledge_track", "RELAY_RECOVERY")),
		"PENDING PACKETS: %d" % int(arrn_snapshot.get("relay_packets_pending", 0)),
		"DORMANCY PRESSURE: %d" % int(arrn_snapshot.get("dormancy_pressure", 0)),
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


func _render_terminal_status_widgets(snapshot: Dictionary) -> void:
	_set_terminal_rich_text(terminal_status_raw_body, _terminal_status_formatter.format(snapshot))
	var parsed_lines: Array[String] = []
	for field_variant in _terminal_status_formatter.structured_fields(snapshot):
		var field: Dictionary = field_variant
		parsed_lines.append(_terminal_kv(String(field.get("label", "STATE")), field.get("value", "UNKNOWN")))
	_set_terminal_rich_text(terminal_status_parsed_body, "\n".join(parsed_lines))
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
		"FAB PAGE        USE FABRICATION",
	]))
	_set_terminal_rich_text(terminal_settings_map_body, "\n".join([
		"PLANET DRAG     ENABLED",
		"TACTICAL INPUT  ENABLED",
		"OVERLAYS        MANUAL",
	]))


func _render_terminal_fabrication_widgets() -> void:
	var view: Dictionary = _terminal_fabrication_view_model.build(self, _terminal_fabrication_selected_work_order_id)
	if view.is_empty():
		_set_terminal_rich_text(terminal_settings_display_body, "FABRICATION SYSTEM OFFLINE")
		_set_terminal_rich_text(terminal_settings_input_body, "RESOURCE LEDGER OR PIPELINE MISSING")
		_set_terminal_rich_text(terminal_settings_map_body, "CHECK AUTLOAD REGISTRATION")
		return

	var status: Dictionary = view.get("status", {})
	var work_orders: Array = view.get("work_orders", [])
	var selected_work_order: Dictionary = view.get("selected_work_order", {})
	if not selected_work_order.is_empty():
		_terminal_fabrication_selected_work_order_id = str(selected_work_order.get("id", ""))
	if terminal_widget_stack != null and terminal_widget_stack.get_node_or_null("FabricationWidgets") != null:
		_render_terminal_fabrication_clickable_widgets(view)
		return

	var display_lines: Array[String] = [
		"FABRICATION // WORK ORDERS",
		"-------------------------",
		"Fabricator: %s" % str(status.get("fabricator_state", "UNKNOWN")),
		"In Progress: %s" % str(status.get("queue_summary", "unknown")),
		"Ready Builds: %s" % str(status.get("ready_build_summary", "unknown")),
		"Next Action: %s" % str(status.get("next_action", "Review the list.")),
	]
	var first_hint := str(status.get("first_fabrication_hint", "")).strip_edges()
	if not first_hint.is_empty():
		display_lines.append("")
		display_lines.append(first_hint)
	if not selected_work_order.is_empty():
		display_lines.append("")
		display_lines.append("SELECTED WORK ORDER")
		display_lines.append("-------------------")
		display_lines.append(str(selected_work_order.get("display_name", "UNKNOWN")))
		display_lines.append("Purpose: %s" % str(selected_work_order.get("purpose", "Fabrication support output.")))
		display_lines.append("Cost: %s" % str(selected_work_order.get("cost_text", "FREE")))
		display_lines.append("You have: %s" % str(selected_work_order.get("have_text", "none")))
		display_lines.append(str(selected_work_order.get("missing_text", "Missing Materials: none")))
		display_lines.append("Result: %s" % str(selected_work_order.get("result_text", "Produces a build output.")))
		display_lines.append("Action: %s" % str(selected_work_order.get("action_text", "FAB START <work_order_id>")))
	_set_terminal_rich_text(terminal_settings_display_body, "\n".join(display_lines))

	var work_order_lines: Array[String] = [
		"AVAILABLE WORK ORDERS",
		"---------------------",
	]
	if work_orders.is_empty():
		work_order_lines.append("NO WORK ORDERS LOADED")
	else:
		for work_order_variant in work_orders:
			if not (work_order_variant is Dictionary):
				continue
			var work_order: Dictionary = work_order_variant
			var selector := ">" if bool(work_order.get("is_selected", false)) else " "
			work_order_lines.append("%s %-22s %-16s %s" % [
				selector,
				str(work_order.get("display_name", "UNKNOWN")),
				str(work_order.get("state", "UNKNOWN")),
				str(work_order.get("build_text", "")),
			])
			work_order_lines.append("  Purpose: %s" % str(work_order.get("purpose", "Fabrication support output.")))
			work_order_lines.append("  Cost: %s" % str(work_order.get("cost_text", "FREE")))
			work_order_lines.append("  You have: %s" % str(work_order.get("have_text", "none")))
			work_order_lines.append("  %s" % str(work_order.get("missing_text", "Missing Materials: none")))
			work_order_lines.append("  Result: %s" % str(work_order.get("result_text", "Produces a build output.")))
			work_order_lines.append("  Command: %s" % str(work_order.get("action_text", "FAB START <work_order_id>")))
	_set_terminal_rich_text(terminal_settings_input_body, "\n".join(work_order_lines))

	var map_lines: Array[String] = [
		"IN PROGRESS",
		"-----------",
	]
	var in_progress: Array = view.get("in_progress", [])
	if in_progress.is_empty():
		map_lines.append("NO ACTIVE JOBS")
	else:
		for job_variant in in_progress:
			if not (job_variant is Dictionary):
				continue
			var job: Dictionary = job_variant
			map_lines.append("#%d %-24s %s %s" % [
				int(job.get("job_id", 0)),
				str(job.get("display_name", "UNKNOWN")),
				str(job.get("progress_text", "0%")),
				str(job.get("timing_text", "")),
			])

	map_lines.append("")
	map_lines.append("READY BUILDS")
	map_lines.append("------------")
	var ready_builds: Array = view.get("ready_builds", [])
	if ready_builds.is_empty():
		map_lines.append("NO READY BUILDS")
	else:
		for ready_build_variant in ready_builds:
			if not (ready_build_variant is Dictionary):
				continue
			var ready_build: Dictionary = ready_build_variant
			map_lines.append("%s x%d" % [
				str(ready_build.get("display_name", "READY BUILD")),
				int(ready_build.get("count", 1)),
			])
			map_lines.append("  State: %s" % str(ready_build.get("deployment_state", "STORED")))
			map_lines.append("  Action: %s" % str(ready_build.get("action_text", "STORED READY BUILD")))

	map_lines.append("")
	map_lines.append("COMMANDS")
	map_lines.append("--------")
	var command_help: Array = view.get("command_help", [])
	if command_help.is_empty():
		map_lines.append("FAB START <work_order_id>")
		map_lines.append("FAB QUEUE")
		map_lines.append("FAB CANCEL <slot>")
		map_lines.append("BUILD PLACE <ready_build_id>")
	else:
		for command_variant in command_help:
			map_lines.append(str(command_variant))
	_set_terminal_rich_text(terminal_settings_map_body, "\n".join(map_lines))


func _render_terminal_fabrication_clickable_widgets(view: Dictionary) -> void:
	var status: Dictionary = view.get("status", {})
	var work_orders: Array = view.get("work_orders", [])
	var selected: Dictionary = view.get("selected_work_order", {})
	var in_progress: Array = view.get("in_progress", [])
	var ready_builds: Array = view.get("ready_builds", [])

	_configure_fabrication_dashboard_layout()
	_set_terminal_rich_text(_get_fabrication_panel_body("FabStatusPanel"), "FAB STATUS: %s | QUEUE %d | READY %d | %s" % [
		str(status.get("fabricator_state", "UNKNOWN")).to_upper(),
		in_progress.size(),
		ready_builds.size(),
		_get_operator_patch_carry_summary(),
	])

	var selected_detail := "NO WORK ORDER SELECTED"
	var cost_lines: Array[String] = ["Select a work order."]
	if not selected.is_empty():
		selected_detail = _build_fabrication_selected_detail(selected)
		cost_lines = []
	_set_terminal_rich_text(_get_fabrication_panel_body("FabSelectedRecipePanel"), selected_detail)
	_set_terminal_rich_text(_get_fabrication_panel_body("FabCostPanel"), "\n".join(cost_lines))

	var categories: Dictionary = {}
	for row_variant in work_orders:
		if row_variant is Dictionary:
			var category := str((row_variant as Dictionary).get("category", "utility")).to_upper()
			categories[category] = int(categories.get(category, 0)) + 1
	var category_lines: Array[String] = []
	for category in categories.keys():
		category_lines.append("%s %d" % [_short_fabrication_category(str(category)), int(categories[category])])
	category_lines.sort()
	_set_terminal_rich_text(_get_fabrication_panel_body("FabCategoryPanel"), "\n".join(category_lines) if not category_lines.is_empty() else "NO WORK ORDERS")

	_populate_fabrication_work_order_rows(work_orders)

	var progress_lines: Array[String] = []
	if in_progress.is_empty():
		progress_lines.append("NO ACTIVE JOBS")
	else:
		for job_variant in in_progress:
			if not (job_variant is Dictionary):
				continue
			var job := job_variant as Dictionary
			progress_lines.append("#%d %s %s" % [
				int(job.get("job_id", 0)),
				str(job.get("display_name", "UNKNOWN")),
				str(job.get("progress_text", "0%")),
			])
	var ready_lines: Array[String] = []
	if ready_builds.is_empty():
		ready_lines.append("NO READY BUILDS")
	else:
		for ready_variant in ready_builds:
			if not (ready_variant is Dictionary):
				continue
			var ready := ready_variant as Dictionary
			ready_lines.append("%s x%d // %s" % [
				str(ready.get("display_name", "READY BUILD")),
				int(ready.get("count", 1)),
				str(ready.get("deployment_state", "STORED")),
			])
	_render_fabrication_bottom_panels(in_progress, ready_builds, progress_lines, ready_lines)

	_update_fabrication_action_buttons(selected, in_progress, ready_builds)
	call_deferred("_debug_check_fabrication_widget_overflow")


func _build_fabrication_selected_detail(selected: Dictionary) -> String:
	var lines: Array[String] = [
		"[color=#e3b763][b]%s[/b][/color]" % str(selected.get("display_name", "UNKNOWN")).to_upper(),
		"[table=2]",
		"[cell][color=#9eb9ae]STATE[/color][/cell][cell]%s[/cell]" % str(selected.get("state", "UNKNOWN")).to_upper(),
		"[cell][color=#9eb9ae]CATEGORY[/color][/cell][cell]%s[/cell]" % _short_fabrication_category(str(selected.get("category", "utility"))),
		"[cell][color=#9eb9ae]RESULT[/color][/cell][cell]%s[/cell]" % str(selected.get("result_text", "Produces a build output.")),
	]
	if _is_selected_lattice_field_patch(selected):
		lines.append("[cell][color=#9eb9ae]CARRY[/color][/cell][cell]%s[/cell]" % _get_operator_patch_carry_summary())
	lines.append_array([
		"[/table]",
		"[color=#e3b763][b]COST[/b][/color]",
		"[table=4][cell][color=#9eb9ae]RESOURCE[/color][/cell][cell][color=#9eb9ae]NEED[/color][/cell][cell][color=#9eb9ae]HAVE[/color][/cell][cell][color=#9eb9ae]MISSING[/color][/cell]",
	])
	var cost_rows: Array = selected.get("cost_rows", [])
	if cost_rows.is_empty():
		lines.append("[cell]FREE[/cell][cell]--[/cell][cell]--[/cell][cell]--[/cell]")
	else:
		for cost_variant in cost_rows:
			if not (cost_variant is Dictionary):
				continue
			var cost := cost_variant as Dictionary
			var missing := int(cost.get("missing", 0))
			var missing_text := "--" if missing <= 0 else "[color=#e3a650]x%d[/color]" % missing
			lines.append("[cell]%s[/cell][cell]%d[/cell][cell]%d[/cell][cell]%s[/cell]" % [
				str(cost.get("label", "UNKNOWN")),
				int(cost.get("need", 0)),
				int(cost.get("have", 0)),
				missing_text,
			])
	lines.append("[/table]")
	return "\n".join(lines)


func _render_fabrication_bottom_panels(in_progress: Array, ready_builds: Array, progress_lines: Array[String], ready_lines: Array[String]) -> void:
	if terminal_widget_stack == null:
		return
	var bottom_row := terminal_widget_stack.find_child("BottomRow", true, false) as HBoxContainer
	var progress_panel := terminal_widget_stack.find_child("FabProgressPanel", true, false) as Control
	var ready_panel := terminal_widget_stack.find_child("FabReadyBuildPanel", true, false) as Control
	var progress_body := _get_fabrication_panel_body("FabProgressPanel")
	var ready_body := _get_fabrication_panel_body("FabReadyBuildPanel")
	var progress_title := progress_panel.find_child("Title", true, false) as Label if progress_panel != null else null
	var ready_title := ready_panel.find_child("Title", true, false) as Label if ready_panel != null else null
	var compact := in_progress.is_empty() and ready_builds.is_empty()
	if bottom_row != null:
		bottom_row.custom_minimum_size.y = 36.0 if compact else 64.0
	var filter_body := _get_fabrication_panel_body("FabCategoryPanel")
	if filter_body != null:
		filter_body.custom_minimum_size.y = 172.0 if compact else 142.0
	var recipe_scroll := terminal_widget_stack.find_child("RecipeScroll", true, false) as ScrollContainer
	if recipe_scroll != null:
		recipe_scroll.custom_minimum_size.y = 176.0 if compact else 146.0
	if progress_panel != null:
		progress_panel.visible = true
		progress_panel.add_theme_stylebox_override("panel", _make_fabrication_compact_panel_style())
		var progress_content := progress_panel.find_child("Content", true, false) as VBoxContainer
		if progress_content != null:
			progress_content.add_theme_constant_override("separation", 3)
		var progress_margin := progress_panel.find_child("Margin", true, false) as MarginContainer
		if progress_margin != null:
			progress_margin.add_theme_constant_override("margin_top", 2 if compact else 4)
			progress_margin.add_theme_constant_override("margin_bottom", 2 if compact else 4)
	if ready_panel != null:
		ready_panel.visible = not compact
		ready_panel.add_theme_stylebox_override("panel", _make_fabrication_compact_panel_style())
		var ready_content := ready_panel.find_child("Content", true, false) as VBoxContainer
		if ready_content != null:
			ready_content.add_theme_constant_override("separation", 3)
		var ready_margin := ready_panel.find_child("Margin", true, false) as MarginContainer
		if ready_margin != null:
			ready_margin.add_theme_constant_override("margin_top", 4)
			ready_margin.add_theme_constant_override("margin_bottom", 4)
	if progress_title != null:
		progress_title.visible = not compact
	if ready_title != null:
		ready_title.visible = not compact
	if progress_body != null:
		progress_body.custom_minimum_size.y = 20.0 if compact else 32.0
		_set_terminal_rich_text(progress_body, "[color=#9eb9ae]IN PROGRESS:[/color] NONE        [color=#9eb9ae]READY BUILDS:[/color] NONE" if compact else "\n".join(progress_lines))
	if ready_body != null:
		ready_body.custom_minimum_size.y = 32.0
		_set_terminal_rich_text(ready_body, "\n".join(ready_lines))


func _get_fabrication_panel_body(panel_name: String) -> RichTextLabel:
	if terminal_widget_stack == null:
		return null
	var panel := terminal_widget_stack.find_child(panel_name, true, false)
	if panel == null:
		return null
	return panel.find_child("Body", true, false) as RichTextLabel


func _get_operator_patch_carry_summary() -> String:
	var operator := get_tree().get_first_node_in_group("player")
	if operator == null or not operator.has_method("get_field_patch_status"):
		return "PATCH --/--"
	var status: Dictionary = operator.call("get_field_patch_status")
	return "PATCH %d/%d" % [int(status.get("count", 0)), int(status.get("max", 0))]


func _is_selected_lattice_field_patch(selected: Dictionary) -> bool:
	return str(selected.get("id", "")) == "lattice_field_patch" or str(selected.get("output_id", "")) == "lattice_field_patch"


func _short_fabrication_category(category: String) -> String:
	match category.to_upper():
		"CONSUMABLE":
			return "CONSUM."
		"STRUCTURE":
			return "STRUCT."
		_:
			return category.to_upper()


func _short_fabrication_state(state: String) -> String:
	match state.to_upper():
		"READY":
			return "READY"
		"IN PROGRESS":
			return "BUILD"
		"MISSING MATERIALS":
			return "MISS"
		"LOCKED":
			return "LOCK"
		_:
			return state.to_upper()


func _short_fabrication_cost(cost_text: String) -> String:
	var shortened := cost_text
	var replacements := {
		"Ruin Scrap": "SCRAP",
		"Structural Alloy": "ALLOY",
		"Power Components": "POWER",
		"Resin Clot": "RESIN",
		"Signal Filament": "SIGNAL",
		"Capacitor Dust": "DUST",
		"Memory Glass Fragment": "GLASS",
		"Fiber Moss": "FIBER",
		"Blackwood": "BLACKWOOD",
	}
	for key in replacements.keys():
		shortened = shortened.replace(str(key), str(replacements[key]))
	shortened = shortened.replace(" x", " ")
	var parts := shortened.split(" / ", false)
	if parts.size() > 3:
		var limited_parts: Array[String] = []
		for index in range(3):
			limited_parts.append(str(parts[index]))
		return " / ".join(limited_parts) + " / ..."
	return shortened


func _fabrication_row_state_color(state: String) -> Color:
	match state.to_upper():
		"READY":
			return Color(0.42, 0.82, 0.58, 1.0)
		"MISSING MATERIALS":
			return Color(0.90, 0.63, 0.28, 1.0)
		"LOCKED":
			return Color(0.66, 0.32, 0.30, 1.0)
		_:
			return Color(0.38, 0.70, 0.68, 1.0)


func _make_fabrication_work_order_style(selected: bool, hover: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.055, 0.052, 0.94) if not hover else Color(0.045, 0.085, 0.078, 0.98)
	style.border_color = Color(0.20, 0.46, 0.43, 0.86) if not selected else Color(0.92, 0.66, 0.27, 0.98)
	style.set_border_width_all(1)
	if selected:
		style.border_width_left = 3
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style


func _add_fabrication_row_label(parent: HBoxContainer, name: String, text: String, minimum_width: float, expand: bool, font: Font, color: Color) -> Label:
	var label := Label.new()
	label.name = name
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size.x = minimum_width
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL if expand else Control.SIZE_SHRINK_BEGIN
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	_apply_label_type(label, font, TERMINAL_FONT_SIZE_ROW, color)
	parent.add_child(label)
	return label


func _populate_fabrication_work_order_rows(work_orders: Array) -> void:
	var rows: Node = null
	if terminal_widget_stack != null:
		rows = terminal_widget_stack.find_child("Rows", true, false)
	if rows == null:
		return
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	var selected_recipe_id := ""
	for row_variant in work_orders:
		if not (row_variant is Dictionary):
			continue
		var row := row_variant as Dictionary
		var recipe_id := str(row.get("id", ""))
		var button := Button.new()
		button.name = "WorkOrderRow_%s" % recipe_id
		button.text = ""
		button.set_meta("fabrication_flat_row", true)
		button.set_meta("recipe_id", recipe_id)
		button.tooltip_text = str(row.get("purpose", "Fabrication support output."))
		button.toggle_mode = true
		var is_selected := bool(row.get("is_selected", false))
		button.button_pressed = is_selected
		button.custom_minimum_size = Vector2(0.0, 32.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		button.clip_text = true
		_apply_button_type(button, _terminal_font_mono_bold, TERMINAL_FONT_SIZE_ROW, Color(0.96, 0.90, 0.80, 1.0))
		_set_control_property_if_available(button, &"text_overrun_behavior", TextServer.OVERRUN_TRIM_ELLIPSIS)
		button.add_theme_stylebox_override("normal", _make_fabrication_work_order_style(is_selected))
		button.add_theme_stylebox_override("hover", _make_fabrication_work_order_style(is_selected, true))
		button.add_theme_stylebox_override("pressed", _make_fabrication_work_order_style(true, true))
		button.add_theme_stylebox_override("focus", _make_fabrication_work_order_style(true))
		var content := HBoxContainer.new()
		content.name = "Content"
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_theme_constant_override("separation", 7)
		button.add_child(content)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var state_color := _fabrication_row_state_color(str(row.get("state", "UNKNOWN")))
		var pip := ColorRect.new()
		pip.name = "StatePip"
		pip.color = Color(0.92, 0.66, 0.27, 1.0) if is_selected else state_color
		pip.custom_minimum_size = Vector2(3.0, 0.0)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(pip)
		_add_fabrication_row_label(content, "StateLabel", _short_fabrication_state(str(row.get("state", "UNKNOWN"))), 52.0, false, _terminal_font_mono_bold, state_color)
		_add_fabrication_row_label(content, "NameLabel", str(row.get("display_name", "UNKNOWN")).to_upper(), 138.0, true, _terminal_font_mono_bold, Color(0.96, 0.90, 0.80, 1.0))
		_add_fabrication_row_label(content, "CategoryLabel", _short_fabrication_category(str(row.get("category", "utility"))), 72.0, false, _terminal_font_mono, Color(0.42, 0.70, 0.68, 0.94))
		_add_fabrication_row_label(content, "CostLabel", _short_fabrication_cost(str(row.get("cost_text", "FREE"))), 130.0, true, _terminal_font_mono, Color(0.70, 0.68, 0.60, 0.94))
		button.pressed.connect(_on_fabrication_work_order_button_pressed.bind(recipe_id))
		rows.add_child(button)
		if is_selected:
			selected_recipe_id = recipe_id
	if not selected_recipe_id.is_empty():
		call_deferred("_ensure_fabrication_selected_row_visible", selected_recipe_id)


func _ensure_fabrication_selected_row_visible(recipe_id: String) -> void:
	if terminal_widget_stack == null:
		return
	var recipe_scroll := terminal_widget_stack.find_child("RecipeScroll", true, false) as ScrollContainer
	var rows := terminal_widget_stack.find_child("Rows", true, false)
	if recipe_scroll == null or rows == null:
		return
	for child in rows.get_children():
		if child is Control and str(child.get_meta("recipe_id", "")) == recipe_id:
			var selected_control := child as Control
			if recipe_scroll.is_ancestor_of(selected_control):
				recipe_scroll.ensure_control_visible(selected_control)
			return


func _debug_check_fabrication_widget_overflow() -> void:
	await get_tree().process_frame
	if terminal_widget_stack == null:
		return
	var fabrication_widgets := terminal_widget_stack.find_child("FabricationWidgets", true, false) as Control
	if fabrication_widgets == null or not fabrication_widgets.is_visible_in_tree():
		return
	var root_rect := fabrication_widgets.get_global_rect()
	var right_edge := root_rect.position.x + root_rect.size.x + 2.0
	for child in fabrication_widgets.find_children("*", "Control", true, false):
		if not (child is Control):
			continue
		var control := child as Control
		if not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		var child_right := rect.position.x + rect.size.x
		if child_right > right_edge:
			push_warning("[FabricationLayout] %s exceeds FabricationWidgets width by %.1f px." % [control.name, child_right - right_edge])


func _update_fabrication_action_buttons(selected: Dictionary, in_progress: Array, ready_builds: Array) -> void:
	var craft_one: Button = null
	var craft_to_max: Button = null
	var place_ready: Button = null
	var cancel_queue: Button = null
	if terminal_widget_stack != null:
		craft_one = terminal_widget_stack.find_child("CraftOneButton", true, false) as Button
		craft_to_max = terminal_widget_stack.find_child("CraftToMaxButton", true, false) as Button
		place_ready = terminal_widget_stack.find_child("PlaceReadyBuildButton", true, false) as Button
		cancel_queue = terminal_widget_stack.find_child("CancelQueueButton", true, false) as Button
	var ready_to_start := not selected.is_empty() and str(selected.get("state", "")) == "READY"
	if craft_one:
		craft_one.text = "CRAFT 1"
		craft_one.disabled = not ready_to_start
		_connect_fabrication_action_button(craft_one, "_on_fabrication_craft_one_pressed")
	if craft_to_max:
		craft_to_max.text = "TO MAX"
		craft_to_max.disabled = not ready_to_start
		_connect_fabrication_action_button(craft_to_max, "_on_fabrication_craft_to_max_pressed")
	if place_ready:
		place_ready.text = "PLACE"
		var has_deployable := not _first_deployable_ready_build_id(ready_builds).is_empty()
		place_ready.visible = has_deployable
		place_ready.disabled = not has_deployable
		_connect_fabrication_action_button(place_ready, "_on_fabrication_place_ready_pressed")
	if cancel_queue:
		cancel_queue.text = "CANCEL"
		cancel_queue.disabled = in_progress.is_empty()
		_connect_fabrication_action_button(cancel_queue, "_on_fabrication_cancel_queue_pressed")


func _connect_fabrication_action_button(button: Button, method_name: String) -> void:
	var callback := Callable(self, method_name)
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _on_fabrication_work_order_button_pressed(recipe_id: String) -> void:
	_terminal_fabrication_selected_work_order_id = _normalize_terminal_fab_identifier(recipe_id)
	_render_terminal_fabrication_widgets()
	_append_terminal_line("FAB SELECTED -> %s" % _terminal_fabrication_selected_work_order_id.to_upper(), "info")


func _on_fabrication_craft_one_pressed() -> void:
	_start_selected_fabrication_recipe(1)


func _on_fabrication_craft_to_max_pressed() -> void:
	_start_selected_fabrication_recipe(20)


func _on_fabrication_place_ready_pressed() -> void:
	var view: Dictionary = _terminal_fabrication_view_model.build(self, _terminal_fabrication_selected_work_order_id)
	var ready_builds: Array = view.get("ready_builds", [])
	var ready_id := _selected_deployable_ready_build_id(ready_builds, view.get("selected_work_order", {}))
	if ready_id.is_empty():
		ready_id = _first_deployable_ready_build_id(ready_builds)
	if ready_id.is_empty():
		_append_terminal_line("NO DEPLOYABLE READY BUILD", "warning")
		return
	_start_ready_build_placement(ready_id)


func _on_fabrication_cancel_queue_pressed() -> void:
	var fab_pipeline := get_node_or_null("/root/FabPipeline")
	if fab_pipeline == null:
		_append_terminal_line("FAB PIPELINE UNAVAILABLE", "warning")
		return
	fab_pipeline.call("clear_jobs")
	_append_terminal_line("FAB JOBS CLEARED", "success")
	_refresh_snapshot()


func _start_selected_fabrication_recipe(max_count: int) -> void:
	var recipe_id := _normalize_terminal_fab_identifier(_terminal_fabrication_selected_work_order_id)
	if recipe_id.is_empty():
		_append_terminal_line("NO FAB WORK ORDER SELECTED", "warning")
		return
	var fab_pipeline := get_node_or_null("/root/FabPipeline")
	if fab_pipeline == null:
		_append_terminal_line("FAB PIPELINE UNAVAILABLE", "warning")
		return
	var started := 0
	for _i in range(maxi(1, max_count)):
		if not bool(fab_pipeline.call("can_start_recipe", recipe_id)):
			break
		if not bool(fab_pipeline.call("try_start_recipe", recipe_id)):
			break
		started += 1
	if started <= 0:
		_append_terminal_line("CANNOT START %s" % recipe_id.to_upper(), "warning")
	else:
		_append_terminal_line("FAB JOB STARTED -> %s x%d" % [recipe_id.to_upper(), started], "success")
	_refresh_snapshot()


func _first_deployable_ready_build_id(ready_builds: Array) -> String:
	for ready_variant in ready_builds:
		if not (ready_variant is Dictionary):
			continue
		var ready := ready_variant as Dictionary
		if bool(ready.get("deployable", false)) and int(ready.get("count", 0)) > 0:
			return str(ready.get("id", ""))
	return ""


func _selected_deployable_ready_build_id(ready_builds: Array, selected_work_order: Dictionary) -> String:
	var selected_output_id := str(selected_work_order.get("output_id", ""))
	if selected_output_id.is_empty():
		return ""
	for ready_variant in ready_builds:
		if not (ready_variant is Dictionary):
			continue
		var ready := ready_variant as Dictionary
		if str(ready.get("id", "")) == selected_output_id \
				and bool(ready.get("deployable", false)) \
				and int(ready.get("count", 0)) > 0:
			return selected_output_id
	return ""


func _start_ready_build_placement(ready_build_id: String) -> bool:
	var turret_placement = get_node_or_null("/root/GameRoot/World/TurretPlacement")
	if turret_placement == null:
		_append_terminal_line("BUILD PLACEMENT UNAVAILABLE", "warning")
		return false
	if not turret_placement.has_method("get_placeable_type_for_build_token") \
			or not turret_placement.has_method("enter_build_token_placement"):
		_append_terminal_line("READY BUILD MAPPING UNAVAILABLE", "warning")
		return false
	var placeable_type := str(turret_placement.call("get_placeable_type_for_build_token", ready_build_id))
	if placeable_type.is_empty():
		_append_terminal_line("UNKNOWN READY BUILD %s" % ready_build_id.to_upper(), "warning")
		return false
	_bind_build_placement_feedback(turret_placement)
	if bool(turret_placement.call("enter_build_token_placement", ready_build_id)):
		_terminal_fabrication_selected_work_order_id = ready_build_id
		_append_terminal_line("BUILD PLACEMENT ACTIVE // %s" % ready_build_id.to_upper(), "success")
		return true
	_append_terminal_line("BUILD PLACE FAILED // READY BUILD UNAVAILABLE", "warning")
	return false


func _bind_build_placement_feedback(build_placement: Node) -> void:
	var placed_callback := Callable(self, "_on_build_token_placed")
	if build_placement.has_signal("build_token_placed") \
			and not build_placement.is_connected("build_token_placed", placed_callback):
		build_placement.connect("build_token_placed", placed_callback)
	var failed_callback := Callable(self, "_on_build_placement_failed")
	if build_placement.has_signal("build_placement_failed") \
			and not build_placement.is_connected("build_placement_failed", failed_callback):
		build_placement.connect("build_placement_failed", failed_callback)


func _on_build_token_placed(_instance: Node2D, build_token_id: String) -> void:
	if build_token_id == "barricade_light":
		_append_terminal_line("BARRICADE PLACED", "success")
	else:
		_append_terminal_line("READY BUILD PLACED // %s" % build_token_id.to_upper(), "success")
	_refresh_snapshot()


func _on_build_placement_failed(build_token_id: String, reason: String) -> void:
	if reason == "invalid_site":
		_append_terminal_line("INVALID BUILD SITE", "warning")
		return
	_append_terminal_line("BUILD PLACE FAILED // %s // %s" % [build_token_id.to_upper(), reason.to_upper()], "warning")


func _render_terminal_main_content(snapshot: Dictionary) -> void:
	if terminal_map_label == null:
		return
	_set_terminal_widget_mode(_terminal_current_page)
	if terminal_map_title_label:
		terminal_map_title_label.text = _terminal_current_page
	if terminal_planet_title_label:
		terminal_planet_title_label.text = "PLANET CONTRACT // SURFACE GLOBE"
	if terminal_map_preview_title_label:
		if _terminal_current_page == "SECTORS":
			var focus_label := "NO SECTOR"
			if not _terminal_highlight_sector.is_empty():
				focus_label = _terminal_truncate(_display_sector_name(_terminal_highlight_sector).to_upper(), 18)
			terminal_map_preview_title_label.text = "TACTICAL MAP // FOCUS: %s" % focus_label
		else:
			terminal_map_preview_title_label.text = "TACTICAL FEED // LIVE MINIMAP"
	if terminal_page_summary_label:
		if _terminal_current_page == "FABRICATION":
			terminal_page_summary_label.text = "FABRICATION PAGE // WORK ORDERS"
		elif _terminal_current_page == "SECTORS":
			terminal_page_summary_label.text = "TACTICAL MANAGEMENT // SECTOR HEALTH, POWER, PRIORITY"
		else:
			terminal_page_summary_label.text = "TACTICAL PAGE // LIVE CONTRACT"
	if terminal_command_title:
		terminal_command_title.text = "FABRICATION CONTROL" if _terminal_current_page == "FABRICATION" else ("EVENT LOG" if _terminal_current_page == "SECTORS" else ("ATTENTION FEED" if _terminal_current_page == "OVERVIEW" else "TRANSCRIPT"))
	if terminal_nav_title:
		terminal_nav_title.text = "WORK ORDERS" if _terminal_current_page == "FABRICATION" else "NAVIGATION"
	if terminal_action_title:
		terminal_action_title.text = "TERMINAL ACTIONS" if _terminal_current_page == "FABRICATION" else "ACTIONS"
	if terminal_header_eyebrow:
		terminal_header_eyebrow.text = "FABRICATION TERMINAL" if _terminal_current_page == "FABRICATION" else "CUSTODIAN NODE"
	if terminal_title_label:
		terminal_title_label.text = "FABRICATION" if _terminal_current_page == "FABRICATION" else "CUSTODIAN INTERFACE"
	if terminal_planet_preview:
		terminal_planet_preview.visible = _terminal_current_page in ["STATUS", "CONTRACTS", "ARCHIVE"]
	if terminal_planet_title_label:
		terminal_planet_title_label.visible = terminal_planet_preview != null and terminal_planet_preview.visible
	if terminal_map_preview:
		terminal_map_preview.visible = _terminal_current_page in ["OVERVIEW", "SECTORS", "POWER", "DEFENSE", "SENSORS", "INCIDENTS"]
	if terminal_map_preview_title_label:
		terminal_map_preview_title_label.visible = terminal_map_preview != null and terminal_map_preview.visible
	_apply_terminal_page_layout()

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
	return _terminal_snapshot_builder.build(self)

func _collect_sector_snapshot() -> Array[Dictionary]:
	return _terminal_snapshot_builder.collect_sectors(self)

func _collect_enemy_snapshot() -> Dictionary:
	return _terminal_snapshot_builder.collect_enemies(self)

func _collect_tactical_entities() -> Dictionary:
	return _terminal_snapshot_builder.collect_tactical_entities(self)

func _get_terminal_power_utilization_pct() -> float:
	return _terminal_snapshot_builder.get_power_utilization_pct(self)


func _get_power_status_snapshot() -> Dictionary:
	return _terminal_snapshot_builder.get_power_status(self)


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
	return _terminal_snapshot_builder.collect_wave(self)

func _execute_local_terminal_command_legacy(parsed: Dictionary) -> bool:
	var cmd_upper := str(parsed.get("normalized", ""))
	var verb := str(parsed.get("verb", ""))
	var args: Array[String] = parsed.get("args", [])
	var params: Dictionary = parsed.get("params", {})
	
	if verb == "ALLOCATE" and not args.is_empty() and str(args[0]).to_upper() == "DEFENSE":
		verb = ""

	if cmd_upper == "STATUS FULL" or cmd_upper == "STATUS":
		_refresh_snapshot()
		_append_terminal_line("SNAPSHOT REFRESHED", "success")
		for status_line in _terminal_status_formatter.format_lines(_terminal_snapshot):
			_append_terminal_line(status_line, "info")
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
	if cmd_upper == "HELP FABRICATION":
		_append_terminal_line("FABRICATION PAGE: FAB START <WORK_ORDER_ID>, FAB QUEUE, FAB CANCEL <SLOT>, BUILD PLACE <READY_BUILD_ID>", "info")
		_append_terminal_line("SET FAB opens the fabrication shell.", "info")
		return true
	if cmd_upper == "HELP ARRN":
		_append_terminal_line("ARRN COMMANDS: SCAN RELAYS, STATUS RELAY, STABILIZE RELAY <ID>, SYNC", "info")
		_append_terminal_line("Relay packets recover context density; knowledge benefits improve confidence, not omniscience.", "info")
		return true

	match verb:
		"HELP":
			_append_terminal_line("LOCAL COMMANDS: HELP STATUS PREP ARRN ENEMIES WAVE SECTORS CONTRACT PLANET MAP START ASSAULT WALL TURRET REROUTE CLEAR OVERLAY RESET REBOOT FABRICATION", "info")
			_append_terminal_line("ACTIONS: WAIT | WAIT 10X | GOTO <PAGE> | HARDEN <SECTOR> | FOCUS <TARGET>", "info")
			_append_terminal_line("PROTECTED: REBOOT CONFIRM // RESET clears local terminal view state", "warning")
			_append_terminal_line("LIVE CONTROL: SCAN RELAYS | STABILIZE RELAY <ID> | SYNC | REPAIR COMMAND", "info")
			return true
		"STATUS":
			if not args.is_empty() and str(args[0]).to_upper() == "RELAY":
				var arrn_manager := _get_arrn_manager()
				if arrn_manager == null or not arrn_manager.has_method("get_scan_lines"):
					_append_terminal_line("ARRN MANAGER UNAVAILABLE", "warning")
					return true
				_set_terminal_page("SENSORS")
				var status_lines: Array = arrn_manager.call("get_scan_lines", "FULL")
				for line in status_lines:
					_append_terminal_line(str(line), "info")
				_refresh_snapshot()
				return true
			_append_terminal_line("STATUS TARGET UNKNOWN", "warning")
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
				var harden_response = harden_power_system.call("apply_emergency_repair", harden_target)
				if harden_response is Dictionary:
					harden_repair_result = harden_response

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
			if args.is_empty() or str(args[0]).to_upper() != "CONFIRM":
				_append_terminal_line("REBOOT PROTECTED // USE: REBOOT CONFIRM", "warning")
				return true
			_reset_terminal_local_state(true)
			_terminal_boot_complete = true
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
		"BUILD":
			if args.is_empty():
				_append_terminal_line("USE: BUILD PLACE <READY_BUILD_ID>", "warning")
				return true
			var build_action := str(args[0]).to_upper()
			match build_action:
				"PLACE":
					if args.size() < 2:
						_append_terminal_line("USE: BUILD PLACE <READY_BUILD_ID>", "warning")
						return true
					var ready_build_id := _normalize_terminal_fab_identifier(str(args[1]))
					if ready_build_id.is_empty():
						_append_terminal_line("USE: BUILD PLACE <READY_BUILD_ID>", "warning")
						return true
					if _start_ready_build_placement(ready_build_id):
						_set_terminal_page("FABRICATION")
						_append_terminal_line("LEFT CLICK IN WORLD TO PLACE // Q OR ESC TO EXIT", "info")
						return true
					return true
				_:
					_append_terminal_line("USE: BUILD PLACE <READY_BUILD_ID>", "warning")
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
			var sync_arrn := _get_arrn_manager()
			if sync_arrn != null and sync_arrn.has_method("sync_packets"):
				var sync_result: Dictionary = sync_arrn.call("sync_packets")
				_set_terminal_page("ARCHIVE")
				if bool(sync_result.get("ok", false)):
					_append_terminal_line("SYNC COMPLETE: %d PACKETS." % int(sync_result.get("packets", 0)), "success")
					_append_terminal_line("KNOWLEDGE INDEX RELAY_RECOVERY=%d." % int(sync_result.get("knowledge_index", 0)), "success")
					var benefit := str(sync_result.get("benefit", ""))
					if not benefit.is_empty():
						_append_terminal_line("BENEFIT ACTIVE: %s." % benefit, "success")
					if int(sync_result.get("failed", 0)) > 0:
						_append_terminal_line("WEAK RELAY LOSS: %d PACKETS FAILED CONFIDENCE CHECK." % int(sync_result.get("failed", 0)), "warning")
				else:
					_append_terminal_line("SYNC FAILED // %s" % str(sync_result.get("reason", "UNKNOWN")), "warning")
			else:
				_ensure_terminal_contract_binding()
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
				var scan_arrn := _get_arrn_manager()
				if scan_arrn == null or not scan_arrn.has_method("scan_network"):
					_append_terminal_line("ARRN MANAGER UNAVAILABLE", "warning")
					return true
				scan_arrn.call("scan_network", "FULL")
				_terminal_overlay_flags["path"] = true
				_terminal_overlay_flags["threat"] = true
				_set_terminal_page("SENSORS")
				var scan_lines: Array = scan_arrn.call("get_scan_lines", "FULL")
				for line in scan_lines:
					_append_terminal_line(str(line), "info")
				_refresh_snapshot()
				_append_terminal_line("RELAY SCAN COMPLETE // CONTEXT ANCHORS REACQUIRED", "success")
				return true
			_append_terminal_line("UNKNOWN SCAN TARGET", "warning")
			return true
		"STABILIZE":
			if not args.is_empty() and str(args[0]).to_upper() == "RELAY":
				var stabilize_arrn := _get_arrn_manager()
				if stabilize_arrn == null or not stabilize_arrn.has_method("start_stabilization"):
					_append_terminal_line("ARRN MANAGER UNAVAILABLE", "warning")
					return true
				var relay_target := str(args[1]).to_upper() if args.size() > 1 else str(params.get("id", ""))
				if relay_target.is_empty():
					_append_terminal_line("USE: STABILIZE RELAY <R_NORTH|R_SOUTH|R_ARCHIVE|R_GATEWAY>", "warning")
					return true
				var relay_entity := _find_arrn_relay_entity(relay_target)
				var operator := get_tree().get_first_node_in_group("player")
				if relay_entity == null or operator == null or not (operator is Node2D):
					_append_terminal_line("STABILIZE RELAY FAILED // FIELD VERIFICATION REQUIRED", "warning")
					return true
				var relay_pos := relay_entity.global_position
				if relay_entity.has_method("get_interaction_position"):
					relay_pos = relay_entity.call("get_interaction_position")
				var allowed_distance := 86.0
				if relay_entity.has_method("get_interaction_distance"):
					allowed_distance = float(relay_entity.call("get_interaction_distance"))
				if (operator as Node2D).global_position.distance_to(relay_pos) > allowed_distance:
					_append_terminal_line("STABILIZE RELAY FAILED // OPERATOR NOT AT %s" % relay_target, "warning")
					return true
				var stabilize_result: Dictionary = stabilize_arrn.call("start_stabilization", StringName(relay_target), operator)
				if bool(stabilize_result.get("ok", false)):
					_set_terminal_page("SENSORS")
					_append_terminal_line("RELAY STABILIZATION STARTED // %s" % relay_target, "success")
					_append_terminal_line("FIELD TASK WILL COMPLETE AFTER ARRN TICKS; return to COMMAND for SYNC.", "info")
					_refresh_snapshot()
				else:
					_append_terminal_line("STABILIZE RELAY FAILED // %s" % str(stabilize_result.get("reason", "UNKNOWN")), "warning")
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
				_set_terminal_page("FABRICATION")
				var fab_profile := str(args[1]).to_upper() if args.size() > 1 else "STANDARD"
				_append_terminal_line("FAB PROFILE SET -> %s" % fab_profile, "success")
				return true
			_append_terminal_line("UNKNOWN SET TARGET", "warning")
			return true
		"FAB":
			var fab_action := str(args[0]).to_upper() if not args.is_empty() else "QUEUE"
			var fab_payload := " ".join(args.slice(1, args.size()))
			match fab_action:
				"STATUS":
					_set_terminal_page("FABRICATION")
					_refresh_snapshot()
					_append_terminal_line("FAB STATUS REFRESHED", "success")
				"RECIPES":
					_set_terminal_page("FABRICATION")
					var fab_pipeline := get_node_or_null("/root/FabPipeline")
					if fab_pipeline == null:
						_append_terminal_line("FAB PIPELINE UNAVAILABLE", "warning")
						return true
					var recipes: Dictionary = fab_pipeline.call("get_all_recipes")
					if recipes.is_empty():
						_append_terminal_line("NO FAB RECIPES LOADED", "warning")
						return true
					for recipe_id in recipes.keys():
						var recipe: Dictionary = recipes[recipe_id]
						var cost: Dictionary = recipe.get("cost", {})
						var cost_parts: Array[String] = []
						for resource_id in cost.keys():
							cost_parts.append("%s=%s" % [str(resource_id).to_upper(), str(cost[resource_id])])
						_append_terminal_line("%s | %s | %.1fs | %s" % [
							str(recipe_id).to_upper(),
							str(recipe.get("label", recipe_id)),
							float(recipe.get("build_seconds", 0.0)),
							", ".join(cost_parts) if not cost_parts.is_empty() else "FREE",
						], "info")
				"QUEUE":
					_set_terminal_page("FABRICATION")
					var fab_pipeline := get_node_or_null("/root/FabPipeline")
					if fab_pipeline == null:
						_append_terminal_line("FAB PIPELINE UNAVAILABLE", "warning")
						return true
					var jobs: Array = fab_pipeline.call("get_jobs_snapshot")
					if jobs.is_empty():
						_append_terminal_line("FAB JOBS: EMPTY", "info")
					else:
						for job_variant in jobs:
							if not (job_variant is Dictionary):
								continue
							var job: Dictionary = job_variant
							_append_terminal_line("#%d %s %.0f%%" % [
								int(job.get("job_id", 0)),
								str(job.get("recipe_id", "")).to_upper(),
								float(job.get("progress", 0.0)) * 100.0,
							], "info")
				"CANCEL":
					var cancel_pipeline := get_node_or_null("/root/FabPipeline")
					if cancel_pipeline == null:
						_append_terminal_line("FAB PIPELINE UNAVAILABLE", "warning")
						return true
					cancel_pipeline.call("clear_jobs")
					_set_terminal_page("FABRICATION")
					_append_terminal_line("FAB JOBS CLEARED", "success")
				"PRIORITY":
					_set_terminal_page("FABRICATION")
					_append_terminal_line("FAB PRIORITY -> %s" % (fab_payload if not fab_payload.is_empty() else "STANDARD"), "success")
				"GRANT":
					var fab_ledger := get_node_or_null("/root/ResourceLedger")
					if fab_ledger == null:
						_append_terminal_line("RESOURCE LEDGER UNAVAILABLE", "warning")
						return true
					if args.size() >= 3:
						var resource_id := _normalize_terminal_fab_identifier(str(args[1]))
						var amount := int(str(args[2]))
						if resource_id.is_empty() or amount <= 0:
							_append_terminal_line("USE: FAB GRANT <RESOURCE> <AMOUNT>", "warning")
							return true
						fab_ledger.call("add", resource_id, amount)
						_set_terminal_page("FABRICATION")
						_append_terminal_line("GRANTED %d %s" % [amount, resource_id.to_upper()], "success")
						_refresh_snapshot()
						return true
					fab_ledger.call("debug_grant")
					_set_terminal_page("FABRICATION")
					_append_terminal_line("STARTER FAB RESOURCES GRANTED", "success")
					_refresh_snapshot()
					return true
				"START":
					var recipe_id := _normalize_terminal_fab_identifier(fab_payload)
					if recipe_id.is_empty():
						_append_terminal_line("USE: FAB START <RECIPE_ID>", "warning")
						return true
					var start_pipeline := get_node_or_null("/root/FabPipeline")
					if start_pipeline == null:
						_append_terminal_line("FAB PIPELINE UNAVAILABLE", "warning")
						return true
					if not bool(start_pipeline.call("has_recipe", recipe_id)):
						_append_terminal_line("UNKNOWN RECIPE %s" % recipe_id.to_upper(), "warning")
						return true
					if not bool(start_pipeline.call("can_start_recipe", recipe_id)):
						_append_terminal_line("CANNOT START %s // INSUFFICIENT RESOURCES" % recipe_id.to_upper(), "warning")
						return true
					if bool(start_pipeline.call("try_start_recipe", recipe_id)):
						_terminal_fabrication_selected_work_order_id = recipe_id
						_set_terminal_page("FABRICATION")
						_append_terminal_line("FAB JOB STARTED -> %s" % recipe_id.to_upper(), "success")
						_refresh_snapshot()
						return true
					_append_terminal_line("FAB START FAILED -> %s" % recipe_id.to_upper(), "warning")
				_:
					_set_terminal_page("FABRICATION")
					_append_terminal_line("FAB COMMANDS: STATUS | RECIPES | GRANT | START | QUEUE | CANCEL", "info")
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
				_append_terminal_line("POWER PRIORITY UPDATED %s -> %s (%d)" % [
					reroute_sector_name,
					priority_name,
					reroute_priority_value,
				], "success", reroute_sector_name)
				_refresh_snapshot()
			else:
				_append_terminal_line("UNKNOWN SECTOR %s" % reroute_sector_name, "warning")

			return true

		_:
			return false

func _get_game_state() -> Node:
	return _terminal_snapshot_builder.get_game_state(self)

func _get_arrn_manager() -> Node:
	return get_node_or_null("/root/ARRNManager")

func _find_arrn_relay_entity(relay_id: String) -> Node2D:
	for node in get_tree().get_nodes_in_group("arrn_relay"):
		if not (node is Node2D):
			continue
		if str(node.get("relay_id")).to_upper() == relay_id.strip_edges().to_upper():
			return node as Node2D
	return null

func _get_local_director_status() -> Dictionary:
	return _terminal_snapshot_builder.get_local_director_status(self)

func _collect_contract_snapshot() -> Dictionary:
	_ensure_terminal_contract_binding()
	if _terminal_contract_snapshot.is_empty():
		return {}
	return _terminal_contract_snapshot.duplicate(true)

func _init_terminal_previews() -> void:
	_terminal_planet_preview_renderer.init(self, terminal_planet_preview)

func _refresh_contract_previews() -> void:
	_refresh_terminal_minimap()

	var contract = _collect_contract_snapshot()
	if contract.is_empty():
		if terminal_planet_preview:
			terminal_planet_preview.texture = _build_placeholder_preview("NO PLANET CONTRACT")
		return

	if terminal_planet_preview:
		_render_planet_preview()


func _refresh_terminal_minimap() -> void:
	if terminal_map_preview != null and terminal_map_preview.has_method("refresh_now"):
		terminal_map_preview.call("refresh_now")

func _render_planet_preview() -> void:
	_terminal_planet_preview_renderer.render(self, terminal_planet_preview, _terminal_latest_contract)

func _on_terminal_planet_preview_gui_input(event: InputEvent) -> void:
	if not _terminal_open or terminal_planet_preview == null:
		return
	var result := _terminal_planet_preview_renderer.handle_gui_input(event, terminal_planet_preview)
	if bool(result.get("handled", false)):
		if terminal_input:
			terminal_input.grab_focus()
		var scroll_delta := int(result.get("scroll_delta", 0))
		if scroll_delta != 0 and event is InputEventMouseButton and not (event as InputEventMouseButton).ctrl_pressed:
			_scroll_terminal_main_by(scroll_delta)

func _planet_preview_contains_screen_point(point: Vector2) -> bool:
	return _terminal_planet_preview_renderer.contains_screen_point(terminal_planet_preview, point)


func _on_terminal_map_preview_gui_input(event: InputEvent) -> void:
	if not _terminal_open or terminal_map_preview == null:
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
			if _terminal_current_page == "SECTORS" and select_sector_from_world_position(click_world_pos):
				if terminal_input:
					terminal_input.grab_focus()
				terminal_map_preview.accept_event()
				return
			if _apply_terminal_map_placement(click_world_pos):
				_refresh_snapshot()
			if terminal_input:
				terminal_input.grab_focus()
			terminal_map_preview.accept_event()
			return
		if button_event.button_index == MOUSE_BUTTON_RIGHT and button_event.pressed:
			if _cancel_active_placement_mode():
				_append_terminal_line("PLACEMENT CANCELLED", "info")
				if terminal_input:
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
	if terminal_map_preview != null and terminal_map_preview.has_method("local_to_world"):
		return terminal_map_preview.call("local_to_world", local_pos)
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
	image.fill(Color(0.035, 0.055, 0.055, 1.0))

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
			draw_point.call(p, Color(0.20, 0.25, 0.24, 1.0), 1)
	for p in room_points:
		if p is Vector2i:
			draw_point.call(p, Color(0.22, 0.72, 0.66, 1.0), 2)
	for p in corridor_points:
		if p is Vector2i:
			draw_point.call(p, Color(0.58, 0.82, 0.96, 0.95), 1)
	if player_spawn is Vector2i:
		draw_point.call(player_spawn, Color(0.9, 0.95, 0.25, 1.0), 2)

	var sectors = snapshot.get("sectors", [])
	if sectors is Array:
		for sector in sectors:
			if not (sector is Dictionary):
				continue
			var hp_pct := int(sector.get("hp_pct", 100))
			var sector_pos = sector.get("world_pos", null)
			if not (sector_pos is Vector2):
				continue
			var raw_name := str(sector.get("name", ""))
			var resolved_name := _resolve_terminal_sector_name(raw_name)
			var state := format_sector_state(sector)
			var tint := Color(0.40, 0.84, 0.76, 0.82)
			if state in ["DAMAGED", "CRITICAL", "ASSAULT", "COMPROMISED", "OFFLINE"] or hp_pct < 70:
				tint = Color(0.94, 0.28, 0.28, 0.86)
			elif state in ["DEGRADED", "WARNING"] or hp_pct < 100:
				tint = Color(0.92, 0.70, 0.28, 0.82)
			var selected := resolved_name == _terminal_highlight_sector
			_draw_preview_world_marker(image, Vector2(sector_pos), tint, 7 if selected else 4, points, min_x, min_y, scale, draw_offset)
			if selected:
				_draw_preview_world_ring(image, Vector2(sector_pos), Color(0.95, 0.96, 0.38, 0.98), 10, points, min_x, min_y, scale, draw_offset)
				_draw_preview_world_ring(image, Vector2(sector_pos), Color(0.40, 0.90, 1.0, 0.80), 14, points, min_x, min_y, scale, draw_offset)

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


func select_sector(raw_name: String) -> bool:
	var resolved_name := _resolve_terminal_sector_name(raw_name)
	if resolved_name.is_empty():
		_append_terminal_line("UNKNOWN SECTOR %s" % raw_name.to_upper(), "warning")
		return false
	_terminal_highlight_sector = resolved_name
	_set_terminal_page("SECTORS")
	_append_terminal_line("FOCUS SHIFTED TO %s" % _display_sector_name(_terminal_highlight_sector).to_upper(), "success", _terminal_highlight_sector)
	_refresh_snapshot()
	return true


func select_sector_from_world_position(world_position: Vector2) -> bool:
	var closest_name := ""
	var closest_distance_sq := INF
	for sector_variant in _collect_sector_snapshot():
		if not (sector_variant is Dictionary):
			continue
		var sector: Dictionary = sector_variant
		var sector_pos = sector.get("world_pos", null)
		if not (sector_pos is Vector2):
			continue
		var distance_sq := Vector2(sector_pos).distance_squared_to(world_position)
		if distance_sq < closest_distance_sq:
			closest_distance_sq = distance_sq
			closest_name = str(sector.get("name", ""))
	if closest_name.is_empty():
		_append_terminal_line("MINIMAP SECTOR SELECTION UNAVAILABLE", "warning")
		return false
	return select_sector(closest_name)


func _handle_terminal_action_link(action_payload: String) -> void:
	var parts := action_payload.split(":", true, 1)
	var action := str(parts[0]).strip_edges().to_lower()
	var sector_name := str(parts[1]).strip_edges() if parts.size() > 1 else _terminal_highlight_sector
	var resolved_name := _resolve_terminal_sector_name(sector_name)
	match action:
		"open_sectors":
			_set_terminal_page("SECTORS")
			_append_terminal_line("SECTOR PRIORITY VIEW OPENED", "command")
		"open_power":
			if not resolved_name.is_empty():
				_terminal_highlight_sector = resolved_name
			_set_terminal_page("POWER")
			_append_terminal_line("POWER VIEW OPENED%s" % (" // %s" % _display_sector_name(resolved_name).to_upper() if not resolved_name.is_empty() else ""), "command", resolved_name)
		"pin":
			if not resolved_name.is_empty():
				select_sector(resolved_name)
			else:
				_append_terminal_line("PIN SECTOR REQUIRES A SELECTED SECTOR", "warning")
		"set_priority":
			if resolved_name.is_empty():
				_append_terminal_line("SET PRIORITY REQUIRES A SELECTED SECTOR", "warning")
				return
			_terminal_highlight_sector = resolved_name
			_append_terminal_line("USE: REROUTE POWER sector=%s priority=CRITICAL|HIGH|MEDIUM|LOW" % _display_sector_name(resolved_name).to_upper(), "info", resolved_name)
			if terminal_input is LineEdit:
				terminal_input.text = "REROUTE POWER sector=%s priority=HIGH" % _display_sector_name(resolved_name).to_upper()
				terminal_input.caret_column = terminal_input.text.length()
				terminal_input.grab_focus()
		"open_incidents", "track_incidents":
			if not resolved_name.is_empty():
				_terminal_highlight_sector = resolved_name
			_set_terminal_page("INCIDENTS")
			_append_terminal_line("INCIDENT TRACKING FOCUSED%s" % (" // %s" % _display_sector_name(resolved_name).to_upper() if not resolved_name.is_empty() else ""), "command", resolved_name)
		"open_defense":
			_set_terminal_page("DEFENSE")
			_append_terminal_line("DEFENSE COVERAGE VIEW OPENED", "command")
		"focus_sector":
			select_sector(sector_name)
		_:
			_append_terminal_line("UNKNOWN TERMINAL ACTION %s" % action_payload.to_upper(), "warning", resolved_name)


func _set_terminal_time_scale(rate: float) -> void:
	Engine.time_scale = clampf(rate, 0.1, 10.0)
	_last_time_scale = -1.0


func _normalize_terminal_fab_identifier(value: String) -> String:
	return value.strip_edges().to_lower()


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

		_terminal_lines.clear()
		_terminal_lines.append_array(TERMINAL_BOOT_LINES)
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
