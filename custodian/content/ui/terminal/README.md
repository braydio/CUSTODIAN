# Terminal UI PNG Assets

Runtime PNG assets for the command terminal should land here.

Preferred targets:

- `panel_frame_9slice.png` — `NinePatchRect` or `StyleBoxTexture` panel border.
- `button_idle.png`, `button_hover.png`, `button_pressed.png` — `TextureButton` or textured button style states.
- `scanline_overlay.png` — transparent `TextureRect` overlay.
- `grid_overlay.png` — transparent tactical/map overlay.
- `icon_power.png`, `icon_defense.png`, `icon_sector_warning.png` — status and navigation icons.
- `pip_ok.png`, `pip_warning.png`, `pip_critical.png` — compact status pips.

Keep layout in `res://scenes/game.tscn` and behavior in `res://game/ui/terminal/*.gd`.
Use PNGs as skins and overlays, not as the whole terminal layout.
