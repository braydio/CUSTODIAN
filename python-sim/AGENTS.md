# AGENTS.md

CUSTODIAN has pivoted to a Godot-native runtime. Treat `custodian/` as active implementation and `python-sim/` as legacy/reference unless the user explicitly requests legacy work.

## Active Repo Structure

- `custodian/`: active Godot 4.x project.
- `python-sim/design/`: canonical design docs (shared reference).
- `python-sim/ai/`: AI projection docs.

## Legacy / Deprecated

- `python-sim/game/`: legacy Python simulation runtime.
- `python-sim/custodian-terminal/`: legacy terminal UI.

Do not delete legacy assets unless explicitly requested.

## Active Entrypoints

- Open Godot project: `custodian/project.godot`
- Run from terminal: `cd custodian && godot`

## Documentation Workflow

When architecture/design behavior changes:

1. Update relevant docs in `python-sim/design/`.
2. Update `python-sim/design/CHANGELOG.md`.
3. Update `python-sim/design/DEVLOG.md`.
4. Sync `python-sim/ai/CURRENT_STATE.md` (and `CONTEXT.md`/`FILE_INDEX.md` as needed).

## Design/Lifecycle Rules

- Keep feature lifecycle docs in `python-sim/design/20_features/{planned,in_progress,completed}`.
- Move deprecated terminal-contract docs to `python-sim/design/archive/terminal-deprecated/`.
- Avoid duplicate canonical docs.

## Coding and Style

- Keep changes pragmatic and deterministic.
- Preserve operational tone in user-facing copy.
- Keep docs ASCII unless file already requires otherwise.

## Validation

For doc-only updates, validate by checking references and paths.
For code changes in Godot, validate by opening/running `custodian/project.godot` when feasible.
