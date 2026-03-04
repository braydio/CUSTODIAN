# AGENTS.md

Repository-level guidance for CUSTODIAN (post-Godot pivot).

## Active Runtime

- Active gameplay/runtime code: `custodian/` (Godot 4.x)
- Active runtime docs: `custodian/docs/`
- Locked master doctrine: `python-sim/design/MASTER_DESIGN_DOCTRINE.md`

## Legacy Reference

- `python-sim/game/` and `python-sim/custodian-terminal/` are preserved terminal-era implementations.
- Do not treat legacy Python runtime as active gameplay authority.
- Do not delete legacy assets/docs unless explicitly requested.

## Documentation Source of Truth

Use this precedence order:

1. `python-sim/design/MASTER_DESIGN_DOCTRINE.md`
2. `custodian/docs/*`
3. `python-sim/design/00_foundations/*` and `python-sim/design/30_playable_game/*`
4. `python-sim/design/DOC_STATUS.md` for active vs legacy classification

## Change Requirements

When behavior/architecture changes:

1. Update relevant docs in active sets above.
2. Update `python-sim/design/CHANGELOG.md`.
3. Update `python-sim/design/DEVLOG.md`.
4. Update `python-sim/ai/CURRENT_STATE.md` (and `CONTEXT.md`/`FILE_INDEX.md` if impacted).

## Determinism

- Keep fixed-step simulation deterministic.
- Keep simulation logic separate from rendering and UI logic.

## Validation

- For doc-only changes, validate paths/references and status labels.
- For code changes in Godot, run with `cd custodian && godot` when feasible.
