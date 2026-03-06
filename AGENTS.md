# AGENTS.md

Repository-level guidance for CUSTODIAN (post-Godot pivot).

## Active Runtime

- Active gameplay/runtime code: `custodian/` (Godot 4.x)
- Active runtime docs: `custodian/docs/`
- Locked master doctrine: `python-sim/design/MASTER_DESIGN_DOCTRINE.md`

## Godot-Native Design Docs

New Godot implementation specs live in `./design/`:

```
design/
└── 20_features/
    └── in_progress/
        ├── WAVE_SPAWNING_SYSTEM.md
        ├── ENEMY_OBJECTIVE_SYSTEM.md
        ├── ENEMY_BEHAVIOR_DIRECTOR.md
        ├── TURRET_SYSTEM.md
        ├── SECTOR_DAMAGE_SYSTEM.md
        └── REPAIR_GAMEPLAY_SYSTEM.md
```

## Legacy Reference

- `python-sim/game/` and `python-sim/custodian-terminal/` are preserved terminal-era implementations.
- Do not treat legacy Python runtime as active gameplay authority.
- Do not delete legacy assets/docs unless explicitly requested.

## Documentation Source of Truth

Use this precedence order:

1. `./design/` (Godot-native implementation specs)
2. `python-sim/design/MASTER_DESIGN_DOCTRINE.md`
3. `custodian/docs/*`
4. `python-sim/design/00_foundations/*` and `python-sim/design/30_playable_game/*`
5. `python-sim/design/DOC_STATUS.md` for active vs legacy classification

## Change Requirements

When behavior/architecture changes:

1. Update relevant docs in active sets above.
2. If the change is in the Godot runtime, update `./design/` with implementation specs.
3. Update `python-sim/design/CHANGELOG.md`.
4. Update `python-sim/design/DEVLOG.md`.
5. Update `python-sim/ai/CURRENT_STATE.md` (and `CONTEXT.md`/`FILE_INDEX.md` if impacted).

## Determinism

- Keep fixed-step simulation deterministic.
- Keep simulation logic separate from rendering and UI logic.

## Validation

- For doc-only changes, validate paths/references and status labels.
- For code changes in Godot, run with `cd custodian && godot` when feasible.

## Slash Commands

Use slash commands to run the implementation workflows from design docs:

| Command | Example |
|--------|---------|
| `/implement` | `/implement design/20_features/in_progress/TURRET_SYSTEM.md` |
| `/plan` | `/plan design/20_features/in_progress/REPAIR_GAMEPLAY_SYSTEM.md` |
| `/design-audit` | `/design-audit design/20_features/in_progress` |

These commands map to scripts under `~/.codex/scripts/`.
