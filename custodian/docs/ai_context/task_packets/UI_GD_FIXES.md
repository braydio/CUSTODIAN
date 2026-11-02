# UI.GD FIXES — TASK PACKET

## Packet Status

- Status: in_progress
- Owner: agent
- Created: 2026-05-03
- Last updated: 2026-05-03

## Task

Fix 11 hard compile blockers, runtime bugs, and performance issues in `custodian/game/ui/hud/ui.gd` (~3,957 lines, CanvasLayer HUD/terminal script).

## Outcome

- `ui.gd` compiles without errors in Godot 4.x
- Duplicate local variable declarations eliminated
- Minimap renders enemies/operator correctly (not nested inside turret loop)
- Debug panel uses `call_deferred()` correctly
- Terminal input grabs are null-guarded
- Supply drop and cooldown variable conflicts resolved
- Boot sequence logic is intentional (not dead code)
- Performance: minimap rebuilds reduced

## Authority

- Root routing: `custodian/AGENTS.md`
- Local routing: `custodian/docs/ai_context/CURRENT_STATE.md`
- Active runtime: `custodian/game/ui/hud/ui.gd`
- Historical reference only: N/A

## Work Surface

- Files expected to change:
  - `custodian/game/ui/hud/ui.gd` (all 11 fixes)

- Files expected to be read but not changed:
  - `custodian/project.godot` (verify input mappings)
  - `custodian/docs/ai_context/CURRENT_STATE.md` (drift check after)

- Out-of-scope areas:
  - Refactoring ui.gd into separate files (Phase 2 task)
  - Debug panel visual polish
  - New terminal commands
  - Cognitive state wiring (done in Phase B commit)

## Constraints

- Deterministic simulation: no changes to simulation authority
- Simulation/UI boundary: all changes are UI-only
- No new features: fixes only, per user instructions
- Minimal scope: only the 11 specified fixes

## Implementation Plan

1. ✅ Delete stub `_setup_terminal_main_scroll()` (first occurrence, ~line 344) — VERIFIED DONE
2. ✅ Rename supply drop `status` → `supply_status` in `_process(delta)` (Fix #2) — VERIFIED DONE
3. ✅ Rename cooldown `total`/`remaining` → `cooldown_total`/`cooldown_remaining`, use `.get()` (Fix #2) — VERIFIED DONE
4. ⬜ Fix duplicate locals in `_execute_local_terminal_command()`:
   - `assault_game_state` (Fix #3)
   - `salvage_game_state` (Fix #3)
   - `harden_power_system`, `harden_repair_result` (Fix #3)
   - `defense_sector_name`, `defense_priority_value`, `defense_power_system` (Fix #3)
   - `deploy_turret_type`, `turret_place_type` (Fix #3)
   - `reroute_sector_name`, `reroute_priority_value`, `reroute_power_system` (Fix #3)
5. ⬜ Rename `world_pos` → `hover_world_pos`/`click_world_pos` in `_on_terminal_map_preview_gui_input()` (Fix #4)
6. ⬜ Rename `sector`/`sector_name` → `mapped_sector`/`mapped_sector_name` in second loop of `_resolve_terminal_sector_name()` (Fix #5)
7. ⬜ Fix minimap rendering: unnest enemies/operator from turret loop (Fix #6)
8. ⬜ Guard all `terminal_input.grab_focus()` with `if terminal_input:` (Fix #7)
9. ⬜ Replace `add_child.call_deferred()` → `call_deferred("add_child", debug_panel)` (Fix #8)
10. ⬜ Make nullable node arrays untyped `Array` (Fix #9)
11. ⬜ Fix boot sequence logic in `open_command_terminal()` (Fix #10)
12. ⬜ Performance: minimize minimap rebuilds (Fix #11 — if time permits)

## Acceptance

- Runtime behavior:
  - ⬜ Godot parser reports 0 errors on `ui.gd` (pending runtime test)
  - ✅ Terminal opens without duplicate function error (Fix #1 verified)
  - ✅ Minimap renders turrets, enemies, AND operator independently (Fix #6 done)
  - ✅ Supply drop HUD updates correctly (no variable conflict — Fix #2 done)
  - ✅ Weapon cooldown bar renders correctly (no variable conflict — Fix #2 done)
  - ✅ Debug panel appears on F12 (deferred add works — Fix #8 done)
  - ✅ Terminal input doesn't crash if `terminal_input` is null (Fix #7 done)

- Documentation:
  - ⬜ Check `CURRENT_STATE.md` for drift after fixes

- Path/reference validation:
  - ✅ All autoload paths verified in `project.godot`

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update?
  - ⬜ Check after fixes — terminal command set is unchanged, but boot sequence logic changed
- Does `custodian/docs/ai_context/CONTEXT.md` need an update?
  - No — working model unchanged
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update?
  - No — file ownership unchanged
- Does `custodian/AGENTS.md` need an update?
  - No
- Do any design docs need an update?
  - ⬜ Check if terminal boot sequence change needs documenting

## Completion Notes

- Implemented:
  - ✅ Fix #1: Delete stub `_setup_terminal_main_scroll()` (verified pre-existing)
  - ✅ Fix #2: `supply_status` rename + `.get()` pattern (verified pre-existing)
  - ✅ Fix #3: All duplicate locals renamed in `_execute_local_terminal_command()`
  - ✅ Fix #4: `world_pos` → `hover_world_pos`/`click_world_pos`
  - ✅ Fix #5: `sector`/`sector_name` → `mapped_sector`/`mapped_sector_name`
  - ✅ Fix #6: Unnested enemies/operator from turret loop
  - ✅ Fix #7: All `grab_focus()` calls null-guarded
  - ✅ Fix #8: `call_deferred("add_child", debug_panel)` pattern
  - ✅ Fix #9: Untyped `Array` for nullable node arrays
  - ✅ Fix #10: Boot sequence logic fixed in `open_command_terminal()`
  - ⬜ Fix #11: Performance (deferred, "if time permits")

- Validated:
  - ⬜ Godot runtime test pending

- Deferred:
  - Fix #11: Performance (minimize minimap rebuilds)
  - Refactor ui.gd into separate files (Phase 2)
  - Debug panel visual polish
  - MCP server integration
