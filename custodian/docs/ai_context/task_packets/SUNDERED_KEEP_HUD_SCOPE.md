# Sundered Keep HUD Scope

## Packet Status

- Status: complete
- Owner: Codex
- Agent/session: Codex 2026-06-06
- Created: 2026-06-06
- Last updated: 2026-06-06

## Task

Prevent Sundered Keep-specific quest, status, prompt, and minimap HUD surfaces from displaying while the player is on the main map.

## Outcome

The local Sundered Keep `CustodianHUD` is hidden by default, becomes active only when `enter_from_main(...)` runs, and hides again on `return_to_main(...)`. Terminal overlay suppression preserves this map-context state instead of blindly restoring inactive gameplay overlays.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/terminal/BLACK_RELIQUARY_UI.md`
- Active runtime/docs files: `custodian/game/world/sundered_keep/sundered_keep_map.gd`, `custodian/game/ui/hud/custodian_hud.gd`, `custodian/game/ui/hud/ui.gd`
- Historical reference only: legacy Python runtime

## Constraints

- Keep Sundered Keep gameplay state owned by the map, not the HUD.
- Do not regress terminal-open gameplay-overlay suppression.
- No new assets are required.

## Acceptance

- Sundered Keep HUD is hidden while the player is on the main map.
- Sundered Keep HUD shows after entering the keep.
- Sundered Keep HUD hides after returning to the main map.
- Terminal suppression cannot re-show an inactive map-local HUD.

## Completion Notes

- Implemented context-aware visibility in `CustodianHUD`.
- Made Sundered Keep travel methods own its local HUD context.
- Added `sundered_keep_hud_scope_smoke.gd`.
- Validated with:
  - `godot --headless --check-only --script res://game/ui/hud/custodian_hud.gd`
  - `godot --headless --check-only --script res://game/ui/hud/ui.gd`
  - `godot --headless --check-only --script res://game/world/sundered_keep/sundered_keep_map.gd`
  - `godot --headless --script res://tools/validation/sundered_keep_hud_scope_smoke.gd`
  - `godot --headless --script res://tools/validation/terminal_overlay_visibility_smoke.gd`
  - `godot --headless --script res://tools/validation/black_reliquary_live_minimap_smoke.gd`
  - `godot --headless --script res://tools/validation/black_reliquary_ui_smoke.gd`
  - `godot --headless --script res://tools/validation/sundered_keep_large_layout_smoke.gd`
- The older `sundered_keep_layout_smoke.gd` still fails on its `Collision/MainPortcullisBlocker` node-path assertion; the broader large-layout smoke validates the current portcullis behavior successfully.

## Next Steps

- Apply the same context activation contract to future authored-map-specific HUDs.
