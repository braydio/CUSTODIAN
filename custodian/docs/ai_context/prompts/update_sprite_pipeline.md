# Update Sprite Pipeline

Read `custodian/AGENTS.md` first.
Then read `CURRENT_STATE.md`, `FILE_INDEX.md`, and the linked design doc.

## Task
Update the sprite pipeline for: **[target_actor or system]**

## Rules
- Preserve deterministic fixed-step simulation.
- Keep rendering/UI separate from simulation authority.
- Create or update a task packet for non-trivial work.
- Update `CURRENT_STATE.md` if behavior changes.
- Update `FILE_INDEX.md` if ownership or entrypoints change.
- Follow `custodian/docs/ai_context/VALIDATION_RECIPES.md`.

## Context Files
- `custodian/AGENTS.md` — Local routing and working rules
- `custodian/docs/ai_context/CURRENT_STATE.md` — Live runtime state
- `custodian/docs/ai_context/FILE_INDEX.md` — File ownership map
- `custodian/docs/ai_context/CONTEXT.md` — Full context overview
- `custodian/docs/ai_context/VALIDATION_RECIPES.md` — Validation command guide
- Pipeline docs: `custodian/content/sprites/_pipeline/README.md`, `custodian/docs/ASSET_LAYOUT_CONVENTION.md`, and `design/03_architecture/SPRITE_PIPELINE_SYSTEM.md`

## Sprite Pipeline Structure
- **Source assets**: `custodian/content/sprites/[actor]/source/`
- **Runtime output**: `custodian/content/sprites/[actor]/runtime/`
- **Pipeline scripts**: `custodian/tools/pipelines/`
- **Aseprite files**: `.aseprite` (keep originals)
- **Exported frames**: `.png` with `.png.import` (Godot import)

## Implementation Notes
- Check `custodian/content/sprites/` for existing pipeline patterns
- Use `custodian/tools/pipelines/ingest.py` for batch processing; pass `--no-git-add` when inspecting without staging
- Update `custodian/content/sprites/[actor]/runtime/` with new animations
- Preserve `.aseprite` source files for iterative editing
- Test animations in Godot scene: `custodian/scenes/game.tscn`
