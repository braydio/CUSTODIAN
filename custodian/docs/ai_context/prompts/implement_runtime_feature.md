# Implement Runtime Feature

Read `custodian/AGENTS.md` first.
Then read `CURRENT_STATE.md`, `FILE_INDEX.md`, and the linked design doc.

## Task
Implement the next slice of: **[feature_name]**

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
- Design doc: `design/[feature_path].md` — Feature specification

## Implementation Notes
- Check `custodian/project.godot` for autoloads before adding new ones
- Inspect existing actors/systems before adding similar ones
- Use `/root/InventoryManager` and `/root/CognitiveState` for autoload access (not `Engine.has_singleton()`)
- Signals over direct calls when crossing system boundaries
- Check `design/THE_TRAGEDY_OF_THE_FOREST_SHRUMB*` for cognitive system integration patterns
