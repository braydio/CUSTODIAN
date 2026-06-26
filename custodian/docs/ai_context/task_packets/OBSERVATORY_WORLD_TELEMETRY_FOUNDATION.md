# OBSERVATORY WORLD TELEMETRY FOUNDATION

- Status: `in_progress`
- Authority:
  - `design/02_features/debug_ui/DEVELOPER_OBSERVATORY_SYSTEM.md`
  - `design/01_systems/WORLD_STATE_GRAPH_SYSTEM.md`
  - `design/01_systems/WORLD_HISTORY_SYSTEM.md`
  - `design/01_systems/INTEREST_MANAGEMENT_SYSTEM.md`
  - `design/01_systems/SECTOR_HEATMAP_SYSTEM.md`
- Goal:
  - Add the first shared observability and world-memory foundation for CUSTODIAN: F9 observatory overlay, world state graph, world history, interest management, and sector heatmaps, with the first live hooks focused on player presence and player damage/death.
- Files:
  - `custodian/project.godot`
  - `custodian/scenes/game.tscn`
  - `custodian/game/systems/debug/*`
  - `custodian/game/systems/world/*`
  - `custodian/game/systems/simulation/*`
  - `custodian/game/actors/operator/operator.gd`
  - `custodian/game/actors/sector/sector.gd`
  - `custodian/game/actors/sector/power_node.gd`
  - `custodian/game/actors/enemies/enemy.gd`
  - `custodian/tools/validation/*`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
- Constraints:
  - Keep simulation authority with existing owners.
  - Make the observatory presentation-only.
  - Do not regress the existing F12 debug screen or current debug stack.
  - Keep the first slice bounded; persistence beyond in-memory history is deferred.
- Acceptance:
  - F9 toggles a live observatory overlay in the main game scene.
  - Autoloads exist for observatory, world state graph, world history, interest management, and sector heatmap.
  - Player presence, damage, and death telemetry are recorded.
  - Shared systems expose bounded APIs and pass focused headless validation.
- Completed:
  - Added authority docs for the five-system foundation and selected active design-tree locations that match current repo conventions instead of reviving the retired `design/20_features/in_progress/` path.
- Deferred:
  - Save/load for world history.
  - Rich world-state consumers beyond the initial power/repair hooks.
  - Full heatmap rendering overlays and AI/noise telemetry overlays.

### Ownership And Timing

- Owner: gameplay/tools + gameplay/systems
- Agent/session: Codex 2026-06-25
- Created: 2026-06-25
- Last updated: 2026-06-25

### Work Surface

- Read:
  - `custodian/AGENTS.md`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/CONTEXT.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
  - `custodian/docs/ai_context/VALIDATION_RECIPES.md`
  - `design/02_features/debug_ui/DEBUG_DEV_UI_SYSTEM.md`
- Change:
  - runtime autoloads, overlay scene wiring, shared systems, first telemetry hooks, docs/indexes
- Out of scope:
  - minimap integration
  - save/load
  - full debug draw/AI overlay expansion
  - terminal-facing intel/history presentation

### Plan

1. Add the five system docs and this packet.
2. Implement autoload scaffolds and the F9 observatory overlay.
3. Wire initial player/sector hooks plus focused validation.
4. Update runtime state/index docs with the new systems and first-slice limits.

### Drift Review

- Primary authority: new design docs above plus existing `design/02_features/debug_ui/DEBUG_DEV_UI_SYSTEM.md`
- `CURRENT_STATE.md`: requires update after runtime lands
- `CONTEXT.md`: no workflow-model change expected
- `FILE_INDEX.md`: requires new runtime/doc/test entries
- Local routing/readmes: task packet index requires update

### Handoff

- Next action:
  - implement the shared autoloads and mount the overlay into `res://scenes/game.tscn`
- Best starting files:
  - `custodian/project.godot`
  - `custodian/scenes/game.tscn`
  - `custodian/game/actors/operator/operator.gd`
- Validation to run:
  - `cd custodian && godot --headless --import --quit`
  - `cd custodian && godot --headless --script tools/validation/dev_observatory_smoke.gd`
  - `cd custodian && godot --headless --script tools/validation/world_telemetry_foundation_smoke.gd`
  - `cd custodian && godot --headless --quit`
- Blockers or open questions:
  - The repo still has design-path drift around retired `design/20_features/in_progress/`; this packet intentionally uses active design locations.
