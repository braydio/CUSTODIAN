# Implement Runtime Feature

Read `custodian/AGENTS.md` first.
Then read `CURRENT_STATE.md`, `FILE_INDEX.md`, and the linked design doc.

## Task: {{feature_name}}
Implement the next slice of: {{feature_name}}

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
- Task packet, when selected: `custodian/docs/ai_context/task_packets/[TASK_PACKET].md`
- Design doc: `design/[feature_path].md` — Feature specification

## Implementation Notes
- Check `custodian/project.godot` for autoloads before adding new ones
- Inspect existing actors/systems before adding similar ones
- If the design doc lacks a current `Next Agent Slice`, add or refresh one when the implementation creates follow-up work
- Use `/root/InventoryManager` and `/root/CognitiveState` for autoload access (not `Engine.has_singleton()`)
- Signals over direct calls when crossing system boundaries
- Check `design/THE_TRAGEDY_OF_THE_FOREST_SHRUMB*` for cognitive system integration patterns
