# CUSTODIAN Terminal Asset Checklist

**Status:** design_spec  
**Created:** 2026-05-04  
**Owner:** art / ui  
**Purpose:** Production-ready asset manifest for CUSTODIAN command terminal art pass  

---

## Design Principle

Build a **modular UI kit**, not one flattened screen.

Assets must support:
- Main command terminal shell
- Navigation and tab states
- Content panels
- Map/minimap framing
- Status indicators
- Buttons
- Icons
- Small overlays / polish FX

**Rule:** Do **not** paint text into assets unless decorative. Let Godot render labels, values, warnings, and dynamic text.

Runtime integration note: before redrawing frame art, verify `StyleBoxTexture` setup in `custodian/game/ui/hud/ui.gd`. Thin pixel frames should use slice margins that match the drawn linework and per-family axis modes. Large frame-only panels should tile-fit borders without drawing a repeated center; nav tabs, action buttons, header bars, and command inputs should stretch one clean center. Oversized margins smear borders, while tiling every center creates repeated panel wallpaper.

---

## Folder Layout

Create this structure under your Godot project:

```text
custodian/content/ui/terminal/
├── frames/
├── panels/
├── buttons/
├── nav/
├── icons/
├── markers/
├── meters/
├── overlays/
├── command_line/
├── log/
├── map/
├── planet/
└── source/
```

- `source/` — Store `.aseprite`, `.kra`, layered PNGs, or working files here
- Runtime PNGs go in the typed folders
- Your active runtime is under `custodian/`, keep assets aligned with the active Godot project (not legacy `python-sim` assets)

---

## Asset Priority

### Tier 1 — Draw Now (Minimum Viable Terminal)

These are the minimum assets to make the terminal stop looking like raw Godot controls.

| # | Asset | Folder | Size | Notes |
|---|-------|--------|------|-------|
| 1 | `terminal_frame_outer_9slice.png` | `frames/` | 96x96 or 128x128 | Main shell, 9-slice 24-32px margins |
| 2 | `panel_frame_medium_9slice.png` | `panels/` | 64x64 | Reusable frame, 9-slice 16px margins |
| 3 | `panel_header_bar.png` | `panels/` | 256x32 | Blank, no text, tile horizontally |
| 4 | `terminal_bg_tile_dark.png` | `panels/` | 32x32 or 64x64 | Tileable, subtle grid/noise |
| 5 | `command_line_frame_9slice.png` | `command_line/` | 64x32 | Input field, 9-slice 12px margins |
| 6 | `nav_tab_idle_9slice.png` | `nav/` | 96x32 | Page buttons, 9-slice 12px margins |
| 7 | `nav_tab_active_9slice.png` | `nav/` | 96x32 | Brighter than idle |
| 8 | `button_idle_9slice.png` | `buttons/` | 128x36 | Action buttons, 9-slice 12px margins |
| 9 | `button_hover_9slice.png` | `buttons/` | 128x36 | Subtle glow |
| 10 | `button_pressed_9slice.png` | `buttons/` | 128x36 | Inset look |
| 11 | `map_frame_large_9slice.png` | `map/` | 96x96 or 128x128 | Tactical map frame, 24px margins |
| 12 | `map_grid_tile.png` | `map/` | 32x32 or 64x64 | Tileable, thin dim grid |
| 13 | `status_pip_green.png` | `meters/` | 8x8, 12x12, or 16x16 | Tiny LEDs, same shape across colors |
| 14 | `status_pip_yellow.png` | `meters/` | 8x8, 12x12, or 16x16 | |
| 15 | `status_pip_red.png` | `meters/` | 8x8, 12x12, or 16x16 | |
| 16 | `icon_power.png` | `icons/` | 24x24 or 32x32 | Single-color, transparent bg |
| 17 | `icon_defense.png` | `icons/` | 24x24 or 32x32 | |
| 18 | `icon_repair.png` | `icons/` | 24x24 or 32x32 | |
| 19 | `icon_recon.png` | `icons/` | 24x24 or 32x32 | |
| 20 | `icon_contract.png` | `icons/` | 24x24 or 32x32 | |
| 21 | `icon_map.png` | `icons/` | 24x24 or 32x32 | |
| 22 | `icon_turret.png` | `icons/` | 24x24 or 32x32 | |
| 23 | `icon_wall.png` | `icons/` | 24x24 or 32x32 | |
| 24 | `icon_drone.png` | `icons/` | 24x24 or 32x32 | |
| 25 | `icon_warning.png` | `icons/` | 24x24 or 32x32 | |
| 26 | `icon_critical.png` | `icons/` | 24x24 or 32x32 | |
| 27 | `marker_operator.png` | `markers/` | 12x12, 16x16, or 24x24 | Readable at small size |
| 28 | `marker_enemy.png` | `markers/` | 12x12, 16x16, or 24x24 | Distinct silhouettes |
| 29 | `marker_turret_friendly.png` | `markers/` | 12x12, 16x16, or 24x24 | |
| 30 | `marker_sector.png` | `markers/` | 12x12, 16x16, or 24x24 | |
| 31 | `marker_objective.png` | `markers/` | 12x12, 16x16, or 24x24 | |
| 32 | `selection_bracket_tl.png` | `nav/` | 16x16 or 24x24 | Focus brackets, transparent bg |
| 33 | `selection_bracket_tr.png` | `nav/` | 16x16 or 24x24 | |
| 34 | `selection_bracket_bl.png` | `nav/` | 16x16 or 24x24 | |
| 35 | `selection_bracket_br.png` | `nav/` | 16x16 or 24x24 | |
| 36 | `command_line_prompt_icon.png` | `command_line/` | 16x16 or 24x24 | |
| 37 | `command_line_caret.png` | `command_line/` | 4x16 or 6x24 | |

---

### Tier 2 — Draw After Terminal Works

These make the terminal feel rich, but aren't required for first integration.

| # | Asset | Folder | Size | Purpose |
|---|-------|--------|------|---------|
| 38 | `panel_header_bar_active.png` | `panels/` | 256x32 | Active panel header |
| 39 | `panel_header_bar_warning.png` | `panels/` | 256x32 | Warning state |
| 40 | `panel_header_bar_critical.png` | `panels/` | 256x32 | Critical state |
| 41 | `nav_tab_hover_9slice.png` | `nav/` | 96x32 | Hover state |
| 42 | `nav_tab_disabled_9slice.png` | `nav/` | 96x32 | Disabled state |
| 43 | `nav_tab_alert_9slice.png` | `nav/` | 96x32 | Alert state |
| 44 | `button_disabled_9slice.png` | `buttons/` | 128x36 | Disabled state |
| 45 | `button_warning_9slice.png` | `buttons/` | 128x36 | Warning action |
| 46 | `button_critical_9slice.png` | `buttons/` | 128x36 | Critical action |
| 47 | `log_row_bg.png` | `log/` | 256x24 or 9-slice 64x24 | Terminal output feed |
| 48 | `log_row_bg_alt.png` | `log/` | 256x24 or 9-slice 64x24 | Alt row |
| 49 | `log_row_info_marker.png` | `log/` | 12x12 or 16x16 | Info messages |
| 50 | `log_row_success_marker.png` | `log/` | 12x12 or 16x16 | Success messages |
| 51 | `log_row_warning_marker.png` | `log/` | 12x12 or 16x16 | Warning messages |
| 52 | `log_row_critical_marker.png` | `log/` | 12x12 or 16x16 | Critical messages |
| 53 | `log_entry_arrow.png` | `log/` | 12x12 or 16x16 | Entry indicator |
| 54 | `meter_frame_horizontal_9slice.png` | `meters/` | 128x16 | Progress bars |
| 55 | `meter_fill_green.png` | `meters/` | 8x8 or 16x8 | Power, integrity |
| 56 | `meter_fill_yellow.png` | `meters/` | 8x8 or 16x8 | Cooldown, threat |
| 57 | `meter_fill_red.png` | `meters/` | 8x8 or 16x8 | Critical state |
| 58 | `meter_tick_marks.png` | `meters/` | 128x16 | Tick marks |
| 59 | `divider_horizontal.png` | `panels/` | 128x4 | Content separation |
| 60 | `divider_vertical.png` | `panels/` | 4x128 | Content separation |
| 61 | `divider_glow.png` | `panels/` | 128x4 | Glow divider |
| 62 | `status_pip_off.png` | `meters/` | 8x8, 12x12, or 16x16 | Inactive LED |
| 63 | `status_pip_blue.png` | `meters/` | 8x8, 12x12, or 16x16 | Special state |
| 64 | `status_pip_blink.png` | `meters/` | 8x8, 12x12, or 16x16 | Blinking state |
| 65 | `icon_logistics.png` | `icons/` | 24x24 or 32x32 | |
| 66 | `icon_ammo.png` | `icons/` | 24x24 or 32x32 | |
| 67 | `icon_health.png` | `icons/` | 24x24 or 32x32 | |
| 68 | `icon_integrity.png` | `icons/` | 24x24 or 32x32 | |
| 69 | `icon_fabrication.png` | `icons/` | 24x24 or 32x32 | |
| 70 | `icon_lock.png` | `icons/` | 24x24 or 32x32 | |
| 71 | `icon_unlock.png` | `icons/` | 24x24 or 32x32 | |
| 72 | `icon_sync.png` | `icons/` | 24x24 or 32x32 | |
| 73 | `icon_scan.png` | `icons/` | 24x24 or 32x32 | |
| 74 | `icon_policy.png` | `icons/` | 24x24 or 32x32 | |
| 75 | `icon_config.png` | `icons/` | 24x24 or 32x32 | |
| 76 | `icon_boost.png` | `icons/` | 24x24 or 32x32 | |
| 77 | `icon_lockdown.png` | `icons/` | 24x24 or 32x32 | |
| 78 | `icon_fortify.png` | `icons/` | 24x24 or 32x32 | |
| 79 | `marker_enemy_elite.png` | `markers/` | 12x12, 16x16, or 24x24 | |
| 80 | `marker_enemy_group.png` | `markers/` | 12x12, 16x16, or 24x24 | |
| 81 | `marker_threat.png` | `markers/` | 12x12, 16x16, or 24x24 | |
| 82 | `marker_power_node.png` | `markers/` | 12x12, 16x16, or 24x24 | |
| 83 | `marker_repair_target.png` | `markers/` | 12x12, 16x16, or 24x24 | |
| 84 | `marker_fabricator.png` | `markers/` | 12x12, 16x16, or 24x24 | |
| 85 | `marker_blueprint.png` | `markers/` | 12x12, 16x16, or 24x24 | |
| 86 | `marker_wall_placement.png` | `markers/` | 12x12, 16x16, or 24x24 | |
| 87 | `marker_command.png` | `markers/` | 12x12, 16x16, or 24x24 | |
| 88 | `marker_destroyed_overlay.png` | `markers/` | 12x12, 16x16, or 24x24 | |
| 89 | `marker_priority_overlay.png` | `markers/` | 12x12, 16x16, or 24x24 | |
| 90 | `marker_warning_overlay.png` | `markers/` | 12x12, 16x16, or 24x24 | |
| 91 | `marker_selected_overlay.png` | `markers/` | 12x12, 16x16, or 24x24 | |
| 92 | `rail_button_idle_9slice.png` | `nav/` | 48x48 or 64x48 | Left-side rail |
| 93 | `rail_button_hover_9slice.png` | `nav/` | 48x48 or 64x48 | |
| 94 | `rail_button_active_9slice.png` | `nav/` | 48x48 or 64x48 | |
| 95 | `rail_button_disabled_9slice.png` | `nav/` | 48x48 or 64x48 | |
| 96 | `text_backplate_small_9slice.png` | `panels/` | 64x16 | Label backplates |
| 97 | `text_backplate_warning_9slice.png` | `panels/` | 64x16 | |
| 98 | `text_backplate_critical_9slice.png` | `panels/` | 64x16 | |
| 99 | `selection_highlight_bar.png` | `nav/` | 64x4 | Focus bar |
| 100 | `cursor_chevron.png` | `nav/` | 8x8 or 12x12 | |

---

### Tier 3 — Polish / Juice

These can wait until the UI is stable.

| # | Asset | Folder | Size | Purpose |
|---|-------|--------|------|---------|
| 101 | `overlay_scanlines_fullscreen.png` | `overlays/` | 16x16, 32x32, or full-screen | TextureRect, low alpha |
| 102 | `overlay_terminal_vignette.png` | `overlays/` | Full-screen | Subtle vignette |
| 103 | `overlay_glow_soft.png` | `overlays/` | 64x64 | Soft glow effect |
| 104 | `overlay_chromatic_noise.png` | `overlays/` | 64x64 | Tileable noise |
| 105 | `overlay_warning_flash.png` | `overlays/` | 64x64 or full-screen | Attack/lockdown flash |
| 106 | `overlay_critical_flash.png` | `overlays/` | 64x64 or full-screen | Critical state flash |
| 107 | `overlay_data_flicker.png` | `overlays/` | 64x64 | Data flicker effect |
| 108 | `overlay_target_lock.png` | `overlays/` | 64x64 | Targeting lock |
| 109 | `terminal_scanline_overlay.png` | `overlays/` | 16x16 or 32x32 | Subtle scanlines |
| 110 | `terminal_noise_overlay.png` | `overlays/` | 64x64 | Subtle noise |
| 111 | `planet_preview_frame_9slice.png` | `planet/` | 96x96 or 128x128 | Planet preview widget |
| 112 | `planet_orbit_ring.png` | `planet/` | 64x64 | Orbit ring |
| 113 | `planet_scan_overlay.png` | `planet/` | 64x64 | Scan effect |
| 114 | `planet_target_brackets.png` | `planet/` | 32x32 | Target brackets |
| 115 | `planet_data_backplate.png` | `planet/` | 128x32 | Data plate |
| 116 | `planet_shader_mask.png` | `planet/` | 64x64 | Optional shader mask |
| 117 | `planet_shadow_mask.png` | `planet/` | 64x64 | Optional shadow mask |
| 118 | `dial_frame.png` | `meters/` | 64x64 | Radial gauge |
| 119 | `dial_needle.png` | `meters/` | 4x32 | Gauge needle |
| 120 | `dial_tick_overlay.png` | `meters/` | 64x64 | Tick marks |
| 121 | `map_corner_marker.png` | `map/` | 16x16 | Map corners |
| 122 | `map_crosshair_center.png` | `map/` | 32x32 | Center crosshair |
| 123 | `map_scan_border.png` | `map/` | 128x128 | Scan border |
| 124 | `map_sweep_overlay.png` | `map/` | 64x64 or full-screen | Sweep effect |
| 125 | `map_fog_overlay.png` | `map/` | 64x64 | Fog of war |
| 126 | `map_targeting_reticle.png` | `map/` | 32x32 | Targeting reticle |

---

## Recommended Drawing Order

### Pass 1 — Make It Usable

Draw these first (Tier 1 essentials):

```text
frames/terminal_frame_outer_9slice.png
panels/panel_frame_medium_9slice.png
panels/panel_header_bar.png
panels/terminal_bg_tile_dark.png
command_line/command_line_frame_9slice.png
nav/nav_tab_idle_9slice.png
nav/nav_tab_active_9slice.png
buttons/button_idle_9slice.png
buttons/button_hover_9slice.png
buttons/button_pressed_9slice.png
map/map_frame_large_9slice.png
map/map_grid_tile.png
meters/status_pip_green.png
meters/status_pip_yellow.png
meters/status_pip_red.png
icons/icon_power.png
icons/icon_defense.png
icons/icon_repair.png
icons/icon_recon.png
icons/icon_contract.png
icons/icon_map.png
icons/icon_turret.png
icons/icon_wall.png
icons/icon_drone.png
icons/icon_warning.png
markers/marker_operator.png
markers/marker_enemy.png
markers/marker_turret_friendly.png
markers/marker_sector.png
nav/selection_bracket_tl.png
nav/selection_bracket_tr.png
nav/selection_bracket_bl.png
nav/selection_bracket_br.png
```

### Pass 2 — Make It Readable

```text
log/log_row_bg.png
log/log_row_warning_marker.png
log/log_row_critical_marker.png
meters/meter_frame_horizontal_9slice.png
meters/meter_fill_green.png
meters/meter_fill_yellow.png
meters/meter_fill_red.png
icons/icon_logistics.png
icons/icon_ammo.png
icons/icon_health.png
icons/icon_fabrication.png
icons/icon_scan.png
icons/icon_lock.png
icons/icon_sync.png
markers/marker_enemy_elite.png
markers/marker_threat.png
markers/marker_power_node.png
markers/marker_fabricator.png
markers/marker_selected_overlay.png
```

### Pass 3 — Make It Feel Alive

```text
overlays/terminal_scanline_overlay.png
overlays/terminal_noise_overlay.png
overlays/overlay_warning_flash.png
panels/panel_header_bar_active.png
panels/panel_header_bar_warning.png
nav/nav_tab_hover_9slice.png
nav/nav_tab_alert_9slice.png
buttons/button_warning_9slice.png
buttons/button_critical_9slice.png
```

### Pass 4 — Make It Premium

```text
planet/planet_preview_frame_9slice.png
planet/planet_orbit_ring.png
planet/planet_scan_overlay.png
map/map_sweep_overlay.png
map/map_targeting_reticle.png
meters/dial_frame.png
meters/dial_needle.png
```

---

## Godot Import Notes

### For Pixel-Art UI Assets:

```text
Filter: Off / Nearest
Mipmaps: Off
Repeat: Enabled only for tiles/overlays
Compression: Lossless or VRAM Compressed if not pixel-sensitive
```

### For 9-Slice Assets:

- Use `NinePatchRect`, or
- Use `StyleBoxTexture` inside a `.tres` Theme

### For Icon Assets:

- Keep text separate
- Let Godot recolor where possible using `modulate`

### For Overlays:

- Use `TextureRect`
- Set `mouse_filter = Ignore`
- Use low opacity in Godot, not baked into the art unless necessary

---

## Naming Convention

Use this pattern:

```text
<category>_<thing>_<state>_<usage>.png
```

Examples:

```text
button_terminal_idle_9slice.png
button_terminal_hover_9slice.png
panel_terminal_medium_9slice.png
icon_terminal_power.png
marker_terminal_enemy.png
overlay_terminal_scanlines_tile.png
```

Shorter names in folders (recommended):

```text
buttons/terminal_idle_9slice.png
buttons/terminal_hover_9slice.png
icons/power.png
markers/enemy.png
```

Either is fine. **Just be consistent.**

---

## Asset Acceptance Checklist

Before wiring an asset into Godot, check:

```text
[ ] Transparent where needed
[ ] No baked text unless decorative
[ ] Same palette family as CUSTODIAN
[ ] Reads at intended runtime size
[ ] 9-slice corners do not stretch badly
[ ] Tile assets loop cleanly
[ ] Icons share consistent line weight
[ ] Markers are distinguishable by shape, not only color
[ ] File is saved under custodian/content/ui/terminal/
[ ] Source file is saved under custodian/content/ui/terminal/source/
```

---

## Art Direction Notes

### 1A. Main Terminal Frame (`frames/terminal_frame_outer_9slice.png`)

- Dark sci-fi metal
- Lightly worn panel edges
- Corners heavier than edges
- No text
- Transparent center if used as frame-only, or dark filled center if used as panel background

### 1B. Panel Background Tiles (`panels/terminal_bg_tile_dark.png`)

- Tileable
- Very subtle grid/noise
- Low contrast

### 5. Command Line Frame (`command_line/command_line_frame_9slice.png`)

- Slight glow along bottom edge
- Should visually say "input field"
- No text
- Also draw: `command_line_prompt_icon.png` (16x16 or 24x24), `command_line_caret.png` (4x16 or 6x24)

### 6. Nav Tab States (`nav/nav_tab_*_9slice.png`)

- Text should be Godot-rendered
- Active state should be visibly brighter
- Alert state should be usable for warnings without screaming

### 7. Button States (`buttons/button_*_9slice.png`)

- Text rendered in Godot
- Idle should be dark
- Hover can glow subtly
- Pressed should look inset

### 10. Map Markers (`markers/*`)

- Need to read at small size
- Use distinct silhouettes, not just colors
- Overlay markers should be transparent center / bracket-like

---

## Documentation Drift Note

This is now a real terminal art pipeline, not just UI cleanup. Once you start wiring these assets, create:

```text
custodian/docs/design/features/implementation/COMMAND_TERMINAL_UI_ART_PASS.md
```

**Minimum contents:**
- Asset folder path (`custodian/content/ui/terminal/`)
- Asset naming convention
- Which terminal scene/script owns the UI (`custodian/game/ui/hud/ui.gd`)
- Which command terminal functions are canonical
- Note that pause menu no longer controls power/repair/deployment

This matches the repo guidance that meaningful Godot runtime or architecture changes should update active `design/` docs first.

---

**End of Asset Specification**
