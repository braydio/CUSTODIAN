# Update Sprite Pipeline

Read `custodian/AGENTS.md` first.
Then read `CURRENT_STATE.md`, `FILE_INDEX.md`, and the linked design doc.

## Task
Update the sprite pipeline for: **[target_actor or system]**

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
- Pipeline docs: `custodian/docs/PAIPELINE.md` or `design/` — Pipeline specifications

## Sprite Pipeline Structure
- **Source assets**: `custodian/content/sprites/[actor]/source/`
- **Runtime output**: `custodian/content/sprites/[actor]/runtime/`
- **Pipeline scripts**: `custodian/tools/pipelines/`
- **Aseprite files**: `.aseprite` (keep originals)
- **Exported frames**: `.png` with `.png.import` (Godot import)

## Implementation Notes
- Check `custodian/content/sprites/` for existing pipeline patterns
- Use `custodian/tools/pipelines/ingest.py` for batch processing
- Update `custodian/content/sprites/[actor]/runtime/` with new animations
- Preserve `.aseprite` source files for iterative editing
- Test animations in Godot scene: `custodian/scenes/game.tscn`
