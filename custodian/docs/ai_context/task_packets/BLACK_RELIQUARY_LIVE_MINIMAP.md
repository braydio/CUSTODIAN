# Black Reliquary Live Minimap

Status: complete  
Agent/session: Codex 2026-06-05  
Last updated: 2026-06-05

## Task

Make the Black Reliquary HUD minimap compact and live instead of chunky/static.

## Outcome

- `black_reliquary_minimap_frame.tscn` is now a small brass tactical frame that embeds the shared `res://game/ui/minimap/minimap_panel.tscn` renderer.
- The embedded minimap has its own heavy panel chrome hidden, uses tighter padding and smaller pips, and keeps the Black Reliquary frame as the visual owner.
- `SunderedKeepMap` now exports authored floor/wall minimap data plus tile/world conversion methods so the HUD minimap renders the keep layout instead of placeholder markers.
- `MinimapController` can discover authored map providers as well as procgen tilemaps, and `MinimapView` has a live actor-bounds fallback when no terrain provider exists.

## Constraints

- Do not use raw level screenshots as minimaps.
- Keep prompt/status/minimap text as live Godot UI, not baked art.
- Do not reintroduce large blocking HUD panels during normal play.
- Keep legacy Python runtime untouched.

## Validation

Passed:

```bash
cd custodian
godot --headless --check-only --script res://game/ui/components/black_reliquary_minimap_frame.gd
godot --headless --check-only --script res://game/ui/minimap/minimap_controller.gd
godot --headless --check-only --script res://game/ui/minimap/minimap_view.gd
godot --headless --check-only --script res://game/world/sundered_keep/sundered_keep_map.gd
godot --headless --script res://tools/validation/black_reliquary_live_minimap_smoke.gd
godot --headless --script res://tools/validation/black_reliquary_ui_smoke.gd
godot --headless --script res://tools/validation/sundered_keep_large_layout_smoke.gd
```

## Completion Notes

No new production art is required for this slice. Future polish can add Black Reliquary-specific live minimap symbols, but the current implementation already uses the shared live tactical renderer and authored Sundered Keep map data.

## Next Steps

- Run a visual playtest in Sundered Keep and tune frame/pip sizes if the compact minimap is still too visually heavy.
- If more authored connected maps need minimaps, implement the same `get_level_data()` and tile conversion provider surface on those map scripts.
