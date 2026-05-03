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
- Run feasible Godot validation.

## Context Files
- `custodian/docs/ai_context/AGENTS.md` — Coding rules and conventions
- `custodian/docs/ai_context/CURRENT_STATE.md` — Live runtime state
- `custodian/docs/ai_context/FILE_INDEX.md` — File ownership map
- `custodian/docs/ai_context/CONTEXT.md` — Full context overview

## Process

1. **Scan git state**:
   ```bash
   cd /home/linux/Projects/CUSTODIAN
   git status --short
   git status --porcelain | grep "^??" | wc -l  # Untracked count
   git status --porcelain | grep "^ M" | wc -l  # Modified count
   ```

2. **Group files into logical commits** (generalized, not picky):
   - **Commit 1**: `chore: Reimport Godot assets (update .import files)` — All `*.import` changes
   - **Commit 2**: `feat(addons): Add new Godot plugins and addons` — New `custodian/addons/` directories
   - **Commit 3**: `feat(game): Update game systems, actors, and content` — `custodian/game/`, `custodian/content/sprites/`, `custodian/content/items/`, `custodian/scenes/`
   - **Commit 4**: `docs: Update documentation and design notes` — `custodian/docs/`, `design/`
   - **Commit 5**: `feat(tools): Add development pipelines and scripts` — `custodian/tools/`, `scripts/`, `custodian/dev/`
   - **Commit 6**: `chore: Update project configuration and gitignore` — `custodian/project.godot`, `.gitignore`

3. **Execute commits in sequence**:
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

4. **Verify clean state**:
   ```bash
   git status --short
   git log --oneline -10
   ```

## Notes
- Use `git add` patterns that capture entire directories (not individual files)
- Skip `node_modules/` (already in `.gitignore`)
- If commits fail, adjust file groupings (some may need to be split)
- Update `CURRENT_STATE.md` and `FILE_INDEX.md` only if the commits change runtime behavior or file ownership
- This is a generalized approach — no need to be super picky about individual files
- Check `rtk status` (via `rtk git status`) for a token-optimized view of changes
