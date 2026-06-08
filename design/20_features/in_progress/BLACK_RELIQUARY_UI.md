# Black Reliquary UI

Status: complete  
Last updated: 2026-06-06

## Summary

Black Reliquary is the current CUSTODIAN gothic/brass runtime UI style. It replaces debug-looking normal-play HUD text with dark charcoal panels, brass/gold borders, compact icons, styled interaction prompts, a compact live tactical minimap, and objective/status plaques.

## Runtime Ownership

- UI assets live under `custodian/content/ui/black_reliquary/`.
- Centralized Godot asset paths live in `custodian/game/ui/theme/black_reliquary_asset_catalog.gd`.
- Palette and reusable style helpers live in `custodian/game/ui/theme/black_reliquary_palette.gd` and `custodian/game/ui/theme/black_reliquary_styles.gd`.
- Reusable components live under `custodian/game/ui/components/`.
- The first HUD scene is `custodian/game/ui/hud/custodian_hud.tscn`, controlled by `custodian_hud.gd`; normal-play vitals should stay header-sized, not occupy large blocking panels.
- `black_reliquary_minimap_frame.tscn` is a compact brass frame around the shared live minimap scene `res://game/ui/minimap/minimap_panel.tscn`; it should not own a separate static minimap implementation.
- Authored connected maps that want live minimap terrain should expose `get_level_data()`, `global_to_minimap_tile(...)`, and `minimap_tile_to_global(...)` provider methods. `SunderedKeepMap` now does this for its authored floor/wall cells.

## Behavior Rules

- Gameplay text is always rendered as Godot `Label` text. Do not bake prompt, objective, or status text into UI textures.
- HUD panels should use `NinePatchRect` when the Black Reliquary panel textures resolve, with fallback `StyleBoxFlat` styling when they do not.
- Runtime code should use `BlackReliquaryAssetCatalog` instead of scattering `res://content/ui/black_reliquary/` strings through gameplay scripts.
- Sundered Keep prompts should use `CustodianHUD.show_interaction(...)` through the new HUD API.
- Normal gameplay should not show giant world-space debug labels. Debug text may exist behind `set_debug_overlay_visible(...)` only for local authored HUDs or inside the dedicated debug screen.
- Legacy command-terminal HUD diagnostics should live in the dedicated `res://game/ui/hud/debug_screen.tscn` surface opened by F12 or `debug_hud`; normal play should show only essentials such as health, stamina, prompts, status plaques, and tactical minimap.
- The minimap frame should embed the live shared minimap renderer with simplified tactical pips. Do not use raw level screenshots or static marker mockups for normal play.
- Authored-map-specific quest, status, prompt, and minimap HUDs must be hidden outside their owning map. External suppression such as the terminal interface must preserve that map-context visibility instead of blindly restoring every gameplay overlay.

## Inventory Overlay

The live inventory overlay is a Black Reliquary field ledger, not a generic RPG
backpack or fabrication menu. It reads carried stackable/key/lore items from the
autoloaded `InventoryManager`; resources and build tokens remain owned by their
separate ledgers.

Required presentation:

- full-screen darkened backdrop with a centered wide reliquary frame
- compact category rail, carried-item grid, and selected-item detail inspector
- readable item name, classification, count, rarity, description, and provenance
- keyboard/mouse and controller focus support
- empty-state copy that still reads as an intentional CUSTODIAN interface
- production assets resolved through a centralized inventory asset catalog
- canonical production assets may replace fallbacks by landing at the documented
  runtime paths without requiring scene or script edits

The overlay must connect to `/root/InventoryManager` and update when its
`inventory_changed` signal fires. The older local `Inventory` resource remains a
compatibility input for isolated UI tests, but must not be the live-game source
of truth.

Canonical asset contract:

```text
custodian/content/ui/inventory/runtime/
├── panels/
├── slots/
├── icons/
└── ornaments/
```

See `custodian/content/ui/inventory/runtime/inventory_ui_asset_manifest.json` for
the exact production filenames and current Black Reliquary/legacy fallbacks.

## Sundered Keep Integration

`custodian/game/world/sundered_keep/sundered_keep_map.gd` currently creates a safe local `CustodianHUD` instance because there is not yet a global Black Reliquary HUD singleton. The integration is intentionally easy to replace later: Sundered Keep owns gate/key/siege state, exports authored minimap floor/wall cells, and activates its local HUD only while the player is inside the keep. The HUD only renders health, stamina, phase, objective, prompt, live minimap, and status plaques.

Required prompt mappings:

- Return Mooring: title `RETURN MOORING`, body `Return to main map`, icon `ICON_RETURN_MOORING`.
- Locked Main Portcullis: title `MAIN PORTCULLIS`, body `Requires Sundered Gate Key`, icon `ICON_GATE_LOCKED`.
- Openable Main Portcullis: title `MAIN PORTCULLIS`, body `Open gate`, icon `ICON_GATE_OPEN`.
- Key pickup: title `SUNDERED GATE KEY`, body `Take key`, icon `ICON_KEY_ITEM`.

## Validation

Use:

```bash
cd custodian
godot --headless --script res://tools/validation/black_reliquary_ui_smoke.gd
godot --headless --script res://tools/validation/black_reliquary_live_minimap_smoke.gd
godot --headless --script res://tools/validation/debug_screen_smoke.gd
godot --headless --script res://tools/validation/sundered_keep_asset_smoke.gd
godot --headless --script res://tools/validation/sundered_keep_large_layout_smoke.gd
godot --headless --script res://tools/validation/sundered_keep_hud_scope_smoke.gd
```

The smoke tests check the Black Reliquary asset root, required panel/icon/prompt/minimap assets, reusable HUD/component scenes, live minimap mounting, and Sundered Keep authored minimap data export.
