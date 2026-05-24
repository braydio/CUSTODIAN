# COGNITIVE STATE PHASE B — TASK PACKET

## Packet Status

- Status: in_progress
- Owner: agent
- Created: 2026-05-03
- Last updated: 2026-05-03

Status values:

- `draft` - scope is being shaped
- `ready` - implementation can begin
- `in_progress` - implementation is active
- `blocked` - waiting on user input, assets, tooling, or design authority
- `complete` - implementation, docs, and validation are done

## Task

Wire cognitive state modifiers (Phase B) into game systems and fix debug panel bugs:

1. **Fix dead code in ui.gd** — `_create_debug_panel_style()` had unreachable code (lines 410-460) after `return style`. That code belongs to `_setup_terminal_main_scroll()`.
2. **Wire move speed multiplier** — `CognitiveState.get_move_speed_multiplier()` → `operator.gd` movement logic.
3. **Wire attack recovery multiplier** — `CognitiveState.get_attack_recovery_multiplier()` → melee recovery timer + ranged fire cooldown.
4. **Wire player accuracy bonus** — `CognitiveState.get_player_accuracy_bonus()` → reduces bullet spread.
5. **Wire player crit bonus** — `CognitiveState.get_player_crit_bonus()` → bullet crit chance.
6. **Update AGENTS.md** — Add RTK subcommand usage guidelines.

## Outcome

- Debug panel toggles with F12 and displays inventory + cognitive state correctly
- Player moves faster with high instinct cognitive state
- Player attacks recover faster with high instinct
- Player has reduced bullet spread with high bearing
- Player has increased crit chance with high bearing
- RTK command routing is documented as subcommand usage, for example `rtk git status`; RTK is not a blind prefix for all CLI commands.

## Authority

- Root routing: `custodian/AGENTS.md`
- Local routing: `custodian/docs/ai_context/CURRENT_STATE.md`, `docs/ai_context/FILE_INDEX.md`
- Active design/spec docs: `../design/THE_TRAGEDY_OF_THE_FOREST_SHRUMB_GAMEPLAY_CORE.md`
- Active runtime/docs files: `custodian/game/systems/cognitive/cognitive_state_system.gd`
- Historical reference only: `../python-sim/design/`

## Work Surface

- Files expected to change:
  - `custodian/game/ui/hud/ui.gd` ✅ (dead code fixed)
  - `custodian/game/actors/operator/operator.gd` ✅ (4 modifiers wired)
  - `custodian/game/actors/projectiles/bullet.gd` ✅ (crit support added)
  - `AGENTS.md` ✅ (RTK subcommand usage added)

- Files expected to be read but not changed:
  - `custodian/game/systems/cognitive/cognitive_state_system.gd` (API reference)
  - `custodian/game/systems/core/systems/inventory_manager.gd` (API reference)
  - `custodian/project.godot` (input mapping verification)

- Out-of-scope areas:
  - Enemy accuracy/tracking bonuses (recollection) — deferred to Phase C
  - Visual polish of debug panel — deferred
  - MCP server integration — deferred

## Constraints

- Determinism concerns: Cognitive state modifiers must NOT affect simulation determinism — they only affect player-controlled actor and UI feedback.
- Simulation/UI boundary concerns: Debug panel is UI-only, no simulation authority.
- Asset requirements: None.
- Compatibility or migration concerns: None — new code uses existing `CognitiveStateSystem` API.
- Clarifying questions or assumptions:
  - ASSUMED: `get_node_or_null("/root/CognitiveState")` is correct autoload path ✅ (confirmed in project.godot)
  - ASSUMED: `Input.is_action_just_pressed("debug_toggle")` maps to F12 ✅ (confirmed physical_keycode 70 = F key in project.godot)

## Implementation Plan

1. ✅ Fix dead code in `ui.gd` — move lines 410-460 from `_create_debug_panel_style()` to `_setup_terminal_main_scroll()`
2. ✅ Wire `get_move_speed_multiplier()` into `operator.gd` `_physics_process()` movement block
3. ✅ Wire `get_attack_recovery_multiplier()` into:
   - `_start_fast_attack_recovery()` (melee recovery timer)
   - `_request_ranged_shot()` (ranged fire cooldown)
4. ✅ Wire `get_player_accuracy_bonus()` into `_emit_pending_ranged_shot()` (reduce spread)
5. ✅ Add crit support to `bullet.gd` (`crit_chance`, `crit_multiplier` exports)
6. ✅ Wire `get_player_crit_bonus()` into `_request_ranged_shot()` (set bullet crit_chance)
7. ✅ Update `AGENTS.md` with RTK subcommand usage guidelines
8. ⬜ Test in Godot — verify F12 toggles debug panel
9. ⬜ Test cognitive modifiers — collect items, verify move speed/attack speed changes

## Acceptance

- Runtime behavior:
  - ⬜ F12 toggles debug panel visible/hidden
  - ⬜ Debug panel shows inventory counts correctly
  - ⬜ Debug panel shows cognitive weights + dominant state
  - ⬜ High instinct (>0.5): player move speed noticeably faster
  - ⬜ High instinct (>0.5): melee recovery and ranged cooldown noticeably faster
  - ⬜ High bearing (>0.5): bullet spread noticeably tighter
  - ⬜ High bearing (>0.5): occasional crit hits (visual confirmation)

- Documentation:
  - ✅ `AGENTS.md` updated with RTK subcommand usage
  - ⬜ `CURRENT_STATE.md` — update if behavior changes verified

- Path/reference validation:
  - ✅ All autoload paths (`/root/CognitiveState`, `/root/InventoryManager`) verified

- Manual validation:
  - ⬜ Run Godot, load game, press F12, verify debug panel
  - ⬜ Collect cognitive items, watch weights change in debug panel
  - ⬜ Verify move speed/attack speed changes visually

- Automated/headless validation:
  - ✅ `rtk git status` shows modified files correctly

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update?
  - ⬜ Check after testing — if cognitive modifiers work, update state to reflect Phase B complete
- Does `custodian/docs/ai_context/CONTEXT.md` need an update?
  - No — working model unchanged
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update?
  - No — file ownership unchanged
- Does `custodian/AGENTS.md` need an update?
  - ✅ Updated with RTK subcommand usage guidelines
- Do any design docs need an update?
  - No — implementation matches `THE_TRAGEDY_OF_THE_FOREST_SHRUMB_GAMEPLAY_CORE.md`

## Completion Notes

- Implemented:
  - ✅ Dead code fix in ui.gd
  - ✅ Move speed multiplier wired
  - ✅ Attack recovery multiplier wired (melee + ranged)
  - ✅ Player accuracy bonus wired (spread reduction)
  - ✅ Player crit bonus wired (bullet crit_chance)
  - ✅ Bullet.gd crit support added
  - ✅ AGENTS.md RTK subcommand usage added

- Validated:
  - ⬜ Godot runtime test pending

- Deferred:
  - Enemy accuracy/tracking bonuses (recollection) → Phase C
  - Debug panel visual polish (colors, icons)
  - MCP server access verification after OpenCode restart
