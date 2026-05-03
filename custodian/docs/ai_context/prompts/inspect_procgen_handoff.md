# Inspect Procgen Handoff

Read `custodian/AGENTS.md` first.
Then read `CURRENT_STATE.md`, `FILE_INDEX.md`, and the linked design doc.

## Task
Inspect and document the handoff between: **[procgen_system]** → **[target_system]**

## Rules
- Preserve deterministic fixed-step simulation.
- Keep rendering/UI separate from simulation authority.
- Update `CURRENT_STATE.md` if behavior changes.
- Update `FILE_INDEX.md` if ownership or entrypoints change.
- Run feasible Godot validation.

## Context Files
- `custodian/docs/ai_context/AGENTS.md` — Coding rules and conventions
- `custodian/docs/ai_context/CURRENT_STATE.md` — Live runtime state
- `custodian/docs/ai_context/FILE_INDEX.md` — File ownership map
- `custodian/docs/ai_context/CONTEXT.md` — Full context overview
- Procgen docs: `design/` — Procedural generation specifications

## Procgen Systems to Inspect
- **Tilemap generator**: `custodian/game/world/procgen/generator/generator.gd`
- **Tilemap renderer**: `custodian/game/world/procgen/proc_gen_tilemap.gd`
- **Contract map**: `custodian/game/world/procgen/custodian_contract_map.gd`
- **World loader**: `custodian/game/systems/core/systems/contract_world_loader.gd`
- **Navigation system**: `custodian/game/systems/core/systems/navigation_system.gd`

## Handoff Inspection Points
1. **Data flow**: How does generator output reach tilemap renderer?
2. **Signal chain**: What signals fire during generation → render → nav-bake?
3. **Runtime segments**: Check `custodian/game/world/procgen/runtime_wall_segment.gd`
4. **Chunk streaming**: Inspect `streaming_*` variables in `proc_gen_tilemap.gd`
5. **Foliage integration**: Check `FOLIAGE_ASSET_PATHS` and scatter logic
6. **Ruin props**: Check `DEFAULT_RUIN_PROP_SCENE` and spawn patterns

## Output
Document in `CURRENT_STATE.md`:
- Procgen pipeline stages (generator → tilemap → nav → foliage → props)
- Key signals and data handoffs
- Runtime file locations for each stage
- Integration points with other systems (cognitive, combat, etc.)
