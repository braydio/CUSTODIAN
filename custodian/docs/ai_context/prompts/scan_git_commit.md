# Scan Git State & Commit

Read `custodian/AGENTS.md` first.
Then read `CURRENT_STATE.md`, `FILE_INDEX.md`, and the linked design doc.

## Task
Scan the current git state and create a series of generalized commits for untracked/modified files.

## Rules
- Preserve deterministic fixed-step simulation.
- Keep rendering/UI separate from simulation authority.
- Update `CURRENT_STATE.md` if behavior changes.
- Update `FILE_INDEX.md` if ownership or entrypoints change.
- Follow `custodian/docs/ai_context/VALIDATION_RECIPES.md`.
- Do not stage, commit, stash, reset, or delete files without explicit user approval for that action.
- Do not stage unrelated user changes just because they match a broad directory pattern.

## Context Files
- `custodian/AGENTS.md` — Local routing and working rules
- `custodian/docs/ai_context/CURRENT_STATE.md` — Live runtime state
- `custodian/docs/ai_context/FILE_INDEX.md` — File ownership map
- `custodian/docs/ai_context/CONTEXT.md` — Full context overview
- `custodian/docs/ai_context/VALIDATION_RECIPES.md` — Validation command guide

## Process

1. **Scan git state**:
   ```bash
   cd /home/linux/Projects/CUSTODIAN
   rtk git status
   git status --short
   git status --porcelain | grep "^??" | wc -l  # Untracked count
   git status --porcelain | grep "^ M" | wc -l  # Modified count
   ```

2. **Group files into logical commit candidates**:
   - **Commit 1**: `chore: Reimport Godot assets (update .import files)` — All `*.import` changes
   - **Commit 2**: `feat(addons): Add new Godot plugins and addons` — New `custodian/addons/` directories
   - **Commit 3**: `feat(game): Update game systems, actors, and content` — `custodian/game/`, `custodian/content/sprites/`, `custodian/content/items/`, `custodian/scenes/`
   - **Commit 4**: `docs: Update documentation and design notes` — `custodian/docs/`, `design/`
   - **Commit 5**: `feat(tools): Add development pipelines and scripts` — `custodian/tools/`, `scripts/`, `custodian/dev/`
   - **Commit 6**: `chore: Update project configuration and gitignore` — `custodian/project.godot`, `.gitignore`

3. **Ask for approval before staging or committing**:

   Present the proposed commit groups and wait for explicit user approval. If approved, stage exact reviewed paths instead of broad patterns whenever unrelated user changes may be present.

4. **Execute approved commits in sequence**:
   ```bash
   # Commit 1: Asset reimports
   git add 'custodian/content/**/*.import' && git commit -m "chore: Reimport Godot assets (update .import files)"
   
   # Commit 2: New addons
   git add custodian/addons/<new_addon_dirs>/ && git commit -m "feat(addons): Add new Godot plugins and addons"
   
   # Commit 3: Game systems and content
   git add custodian/game/ custodian/content/sprites/ custodian/content/items/ custodian/scenes/ && git commit -m "feat(game): Update game systems, actors, and content"
   
   # Commit 4: Documentation
   git add custodian/docs/ design/ .gitignore && git commit -m "docs: Update documentation and design notes"
   
   # Commit 5: Tools and pipelines
   git add custodian/tools/ scripts/ custodian/dev/ && git commit -m "feat(tools): Add development pipelines and scripts"
   
   # Commit 6: Project config
   git add custodian/project.godot .gitignore && git commit -m "chore: Update project configuration and gitignore"
   ```

5. **Verify clean state**:
   ```bash
   git status --short
   git log --oneline -10
   ```

## Notes
- Prefer exact path staging; use broad directory staging only after confirming the directory contains no unrelated user changes
- Skip `node_modules/` (already in `.gitignore`)
- If commits fail, adjust file groupings (some may need to be split)
- Update `CURRENT_STATE.md` and `FILE_INDEX.md` only if the commits change runtime behavior or file ownership
- Use `rtk git status` for a token-optimized view of changes
