# Agent Prompt Templates

Reusable prompts for common CUSTODIAN agent tasks.

Use these prompts after reading `custodian/AGENTS.md`, the active AI context pack, and any task packet for the work. For non-trivial work, create or update a task packet before implementation.

## Templates

- `implement_runtime_feature.md` - scoped Godot runtime implementation.
- `review_docs_drift.md` - documentation drift review against live runtime files.
- `update_sprite_pipeline.md` - sprite intake and runtime animation pipeline work.
- `inspect_procgen_handoff.md` - procgen handoff and integration inspection.
- `tune_combat_feel.md` - combat timing/feel tuning review or implementation.
- `scan_git_commit.md` - git state grouping and commit preparation; requires explicit user approval before staging or committing.

## Required Use

1. Replace bracketed placeholders before acting.
2. Confirm referenced paths exist.
3. Attach or update a task packet for non-trivial work.
4. Follow `custodian/docs/ai_context/VALIDATION_RECIPES.md`.
5. Update `CURRENT_STATE.md`, `CONTEXT.md`, and `FILE_INDEX.md` when workflow, ownership, or runtime state changes.
