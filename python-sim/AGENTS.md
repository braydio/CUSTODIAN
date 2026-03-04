# AGENTS.md

CUSTODIAN is now Godot-native. Treat `custodian/` as active implementation and `python-sim/` as design/legacy reference unless explicitly asked otherwise.

## Active Areas

- `custodian/`: active Godot 4.x runtime code
- `custodian/docs/`: active runtime architecture/spec docs
- `python-sim/design/MASTER_DESIGN_DOCTRINE.md`: locked doctrine
- `python-sim/design/00_foundations/*`, `python-sim/design/30_playable_game/*`: active design references

## Legacy Areas

- `python-sim/game/`: terminal-era Python simulation
- `python-sim/custodian-terminal/`: terminal UI
- `python-sim/design/10_systems/*` and `python-sim/design/20_features/*`: legacy reference unless explicitly refreshed

See `python-sim/design/DOC_STATUS.md` for canonical status mapping.

## Entrypoint

- `cd custodian && godot`

## Documentation Workflow

When architecture/design changes:

1. Update active docs (`custodian/docs/*`, `python-sim/design/00_foundations/*`, `python-sim/design/30_playable_game/*` as needed).
2. Update `python-sim/design/CHANGELOG.md`.
3. Update `python-sim/design/DEVLOG.md`.
4. Sync `python-sim/ai/CURRENT_STATE.md` and related tracker files.

## Guardrails

- Keep active-vs-legacy labels explicit.
- Preserve deterministic fixed-step assumptions.
- Do not delete legacy content unless explicitly requested.
