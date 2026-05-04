# Review Docs Drift

Read `custodian/AGENTS.md` first.
Then read `CURRENT_STATE.md`, `FILE_INDEX.md`, and the linked design doc.

## Task
Review documentation for drift against the live runtime in: **[target_system or feature]**

## Rules
- Preserve deterministic fixed-step simulation.
- Keep rendering/UI separate from simulation authority.
- Create or update a task packet when the review produces follow-up implementation work.
- Update `CURRENT_STATE.md` if behavior changes.
- Update `FILE_INDEX.md` if ownership or entrypoints change.
- Follow `custodian/docs/ai_context/VALIDATION_RECIPES.md`.

## Context Files
- `custodian/AGENTS.md` — Local routing and working rules
- `custodian/docs/ai_context/CURRENT_STATE.md` — Live runtime state (primary drift check)
- `custodian/docs/ai_context/FILE_INDEX.md` — File ownership map
- `custodian/docs/ai_context/CONTEXT.md` — Full context overview
- `custodian/docs/ai_context/VALIDATION_RECIPES.md` — Validation command guide
- Design docs: `design/` — Original specifications

## Drift Check Process
1. Read `CURRENT_STATE.md` for documented runtime state
2. Inspect actual implementation:
   - `custodian/game/systems/` — System implementations
   - `custodian/game/actors/` — Actor implementations
   - `custodian/project.godot` — Autoload registrations
3. Compare documented state vs. actual implementation
4. Note discrepancies in:
   - **Missing implementations** (documented but not implemented)
   - **Extra implementations** (implemented but not documented)
   - **Behavior changes** (documented behavior differs from actual)
5. Update `CURRENT_STATE.md` to match reality
6. Update `FILE_INDEX.md` if file ownership changed

## Common Drift Areas
- **Forest Shrumb cognitive system** (`custodian/game/systems/cognitive/`)
- **Inventory system** (`custodian/game/systems/core/systems/inventory_manager.gd`)
- **Procgen tilemap system** (`custodian/game/world/procgen/`)
- **Animation state machine** (`custodian/game/actors/operator/animations/`)
