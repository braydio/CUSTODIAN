# AGENTS.md

## CUSTODIAN Design Governance (Post-Pivot)

CUSTODIAN runtime authority is Godot-native (`custodian/`).
Design canon remains in `python-sim/design/` with explicit active-vs-legacy classification.

## Canonical Layers

### Active Code Layer

- `custodian/` (Godot 4.x runtime)

### Active Design Layer

- `design/MASTER_DESIGN_DOCTRINE.md`
- `design/00_foundations/*`
- `design/30_playable_game/*`
- `../custodian/docs/*`

### Legacy Design Layer

- `design/10_systems/*`
- `design/20_features/*`

Use `design/DOC_STATUS.md` for status authority.

## Archive Rules

- Terminal-contract docs belong in `design/archive/terminal-deprecated/`.
- Historical material belongs in `design/archive/`.

## Update Rules

When active architecture/behavior changes:

1. Update impacted active docs.
2. Update `design/CHANGELOG.md`.
3. Update `design/DEVLOG.md`.
4. Update `../ai/CURRENT_STATE.md`.
5. Keep status labels in `DOC_STATUS.md` accurate.

## Determinism Rule

- Fixed-step simulation constraints must remain explicit in `00_foundations/SIMULATION_RULES.md`.

## Principle

If legacy docs conflict with active docs, active docs win.
