# Update Sprite Pipeline

Read `custodian/AGENTS.md` first.
Then read `CURRENT_STATE.md`, `FILE_INDEX.md`, and the linked design doc.

## Task: {{target_actor_or_system}}
Update the sprite pipeline for: {{target_actor_or_system}}

## Rules
- Preserve deterministic fixed-step simulation.
- Keep rendering/UI separate from simulation authority.
- Create or update a compact task packet when durable scope, acceptance, or handoff context adds value; expand it only for high-risk or multi-session work.
- Update `CURRENT_STATE.md` if behavior changes.
- Update `FILE_INDEX.md` if ownership or entrypoints change.
- Follow `custodian/docs/ai_context/VALIDATION_RECIPES.md`.

## Context Files
- `custodian/AGENTS.md` — Local routing and working rules
- `custodian/docs/ai_context/CURRENT_STATE.md` — Live runtime state
- `custodian/docs/ai_context/FILE_INDEX.md` — File ownership map
- `custodian/docs/ai_context/CONTEXT.md` — Full context overview
- `custodian/docs/ai_context/VALIDATION_RECIPES.md` — Validation command guide
- Pipeline docs: `custodian/content/sprites/_pipeline/README.md`, `custodian/docs/ASSET_LAYOUT_CONVENTION.md`, and `design/04_architecture/SPRITE_PIPELINE_SYSTEM.md`

## Sprite Pipeline Structure
- **Source assets**: `custodian/content/sprites/[actor]/source/`
- **Runtime output**: `custodian/content/sprites/[actor]/runtime/`
- **Pipeline scripts**: `custodian/tools/pipelines/`
- **Aseprite files**: `.aseprite` (keep originals)
- **Exported frames**: `.png` with `.png.import` (Godot import)

## Implementation Notes
- Check `custodian/content/sprites/` for existing pipeline patterns
- Use `custodian/tools/pipelines/ingest.py` for batch processing; it writes outputs and archives intake without staging Git changes
- Update `custodian/content/sprites/[actor]/runtime/` with new animations
- Preserve `.aseprite` source files for iterative editing
- Test animations in Godot scene: `custodian/scenes/game.tscn`
