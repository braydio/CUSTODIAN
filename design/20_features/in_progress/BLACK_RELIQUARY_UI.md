# Black Reliquary UI

Status: complete  
Last updated: 2026-06-02

## Summary

Black Reliquary is the current CUSTODIAN gothic/brass runtime UI style. It replaces debug-looking normal-play HUD text with dark charcoal panels, brass/gold borders, compact icons, styled interaction prompts, minimap framing, and objective/status plaques.

## Runtime Ownership

- UI assets live under `custodian/content/ui/black_reliquary/`.
- Centralized Godot asset paths live in `custodian/game/ui/theme/black_reliquary_asset_catalog.gd`.
- Palette and reusable style helpers live in `custodian/game/ui/theme/black_reliquary_palette.gd` and `custodian/game/ui/theme/black_reliquary_styles.gd`.
- Reusable components live under `custodian/game/ui/components/`.
- The first HUD scene is `custodian/game/ui/hud/custodian_hud.tscn`, controlled by `custodian_hud.gd`.

## Behavior Rules

- Gameplay text is always rendered as Godot `Label` text. Do not bake prompt, objective, or status text into UI textures.
- HUD panels should use `NinePatchRect` when the Black Reliquary panel textures resolve, with fallback `StyleBoxFlat` styling when they do not.
- Runtime code should use `BlackReliquaryAssetCatalog` instead of scattering `res://content/ui/black_reliquary/` strings through gameplay scripts.
- Sundered Keep prompts should use `CustodianHUD.show_interaction(...)` through the new HUD API.
- Normal gameplay should not show giant world-space debug labels. Debug text may exist behind `set_debug_overlay_visible(...)` or an explicit debug surface.
- The minimap frame should use simplified tactical markers and the Black Reliquary minimap art, not raw level screenshots.

## Sundered Keep Integration

`custodian/game/world/sundered_keep/sundered_keep_map.gd` currently creates a safe local `CustodianHUD` instance because there is not yet a global Black Reliquary HUD singleton. The integration is intentionally easy to replace later: Sundered Keep owns gate/key/siege state, while the HUD only renders health, stamina, phase, objective, prompt, minimap, and status plaques.

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
godot --headless --script res://tools/validation/sundered_keep_asset_smoke.gd
```

The smoke test checks the Black Reliquary asset root, required panel/icon/prompt/minimap assets, and the reusable HUD/component scenes.
