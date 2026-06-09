# Reliquary UI to Inventory Status/Log

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: codex-2026-06-08-reliquary-ui-to-inventory
- Created: 2026-06-08
- Last updated: 2026-06-08

## Task

Move the Black Reliquary play HUD clutter into the inventory overlay and turn that overlay into the primary status surface: a full-screen status page with a blown-up reliquary minimap, plus a toggleable quest history/log page. The live play HUD should be reduced to the minimap, health, and a pale-green stamina bar in the left corner.

## Outcome

- The in-play HUD only shows the minimap, health, and stamina.
- The inventory menu opens to a logically organized status page with a large Black Reliquary-flavored minimap and compact status summary.
- A second page shows a quest/history log.
- Existing carried-item inventory content remains available rather than being discarded.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/world_expansion/THE_SUNDERED_KEEP_LEVEL_SET.md`
- Active runtime/docs files: `custodian/game/ui/hud/custodian_hud.gd`, `custodian/game/ui/hud/custodian_hud.tscn`, `custodian/game/ui/inventory/inventory_ui.gd`, `custodian/game/ui/inventory/inventory_ui.tscn`, `custodian/game/ui/hud/ui.gd`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/game/ui/hud/custodian_hud.gd`
  - `custodian/game/ui/hud/custodian_hud.tscn`
  - `custodian/game/ui/inventory/inventory_ui.gd`
  - `custodian/game/ui/inventory/inventory_ui.tscn`
  - `custodian/game/ui/hud/ui.gd` if inventory mounting or overlay suppression needs a small hook
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
  - `design/02_features/world_expansion/THE_SUNDERED_KEEP_LEVEL_SET.md`
  - `REQUIRED_ASSETS.md` only if the new status/log page exposes a missing production asset need
- Files or folders expected to be read but not changed:
  - `custodian/game/ui/components/black_reliquary_*`
  - `custodian/game/ui/minimap/`
  - `custodian/game/world/sundered_keep/sundered_keep_map.gd`
  - current inventory/item catalogs
- Out-of-scope areas:
  - combat tuning
  - inventory gameplay semantics
  - minimap rendering internals

## Constraints

- Determinism concerns: history entries should be stable and appended in a predictable order.
- Simulation/UI boundary concerns: HUD/overlay must remain presentation-only and not mutate gameplay state.
- Asset requirements: reuse current Black Reliquary assets and the live minimap; do not invent new production art unless a clear gap appears.
- Compatibility or migration concerns: preserve `toggle_inventory` behavior and the existing inventory ledger.
- Clarifying questions or assumptions: use the existing inventory overlay as the host for the new status/log pages rather than creating a separate menu scene.

## Implementation Plan

1. Simplify the play HUD to only the minimap, health, and stamina stack.
2. Rebuild the inventory overlay into tabbed status/history/item pages with a full-screen reliquary status layout.
3. Add a lightweight quest/history feed from existing objective/state updates and verify the overlay still opens/closes cleanly.

## Acceptance

- Runtime behavior: play HUD is minimal; inventory opens to a status page; a page toggle reaches quest history/log; carried-item inventory remains accessible.
- Documentation: active-state docs describe the new HUD split and inventory page role.
- Path/reference validation: existing UI asset paths and minimap scene paths still resolve.
- Manual validation: layout reads logically at a glance in code and scene structure.
- Automated/headless validation: inventory smoke and a Godot boot/script check pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? yes
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? probably not
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? yes
- Does `custodian/AGENTS.md` need an update? no
- Do any design docs need an update? yes

## Completion Notes

- Implemented: HUD now shows only the minimap, health, and pale-green stamina; inventory opens to a full-screen status page with a large reliquary minimap and a separate history/log page.
- Validated: `godot --headless --script tools/validation/inventory_ui_smoke.gd`, `godot --headless --script tools/validation/sundered_keep_hud_scope_smoke.gd`
- Deferred: any new production art for additional status/log embellishment

## Next Steps

- Next action: none required for this feature unless the inventory/status art set is expanded later
- Best starting files: `custodian/game/ui/hud/custodian_hud.gd`, `custodian/game/ui/inventory/inventory_ui.gd`
- Required context: current Black Reliquary component palette and live minimap panel
- Validation to run: already completed for this pass
- Blockers or open questions: none
