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
        ├── COMBAT_FEEL_SYSTEM.md
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
2. **For Godot runtime changes:** Update `./design/` with implementation specs FIRST.
3. Optionally update legacy docs (CHANGELOG, DEVLOG) for historical tracking.
4. Update `python-sim/ai/CURRENT_STATE.md` if game state significantly changes.

## Clarifications

- Agents should ask concise clarifying questions when requirements, assets, or intended behavior are ambiguous enough that guessing would risk incorrect work.
- The user explicitly encourages clarifying questions when needed; do not avoid asking just to appear autonomous.
- When in doubt during this project, explicitly note the ambiguity and ask the user for details before proceeding further; they prefer responses that surface open questions early instead of silent assumptions.
- If proceeding with a reasonable temporary assumption, state that assumption clearly and keep the implementation easy to revise.

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
| `/build-plan` | `/build-plan design/20_features/in_progress/REPAIR_GAMEPLAY_SYSTEM.md` |
| `/designaudit` | `/designaudit design/20_features/in_progress` |

These commands map to scripts under `~/.codex/scripts/`.

## Animation Asset Workflow

- When gameplay work requires a new or updated animation asset, explicitly ask the user to implement/provide that animation.
- For each requested animation, include:
  - exact save path under `custodian/assets/sprites/...`
  - short description of the animation intent (what it should communicate in gameplay)
- Do not silently invent missing production art assets; wire placeholders only when explicitly approved.
- Treat multi-animation or multi-direction master sheets as source assets, not direct runtime assets.
- For any sheet that contains more than one animation or directional set, rebuild only the concrete runtime slices actually used by the game into `SpriteFrames` resources.
- Prefer smaller per-animation runtime slices over binding a large master sheet directly to the active runtime.

## Implementation Workflow

### Codex Agent (Special)
- **Can implement IMMEDIATELY** without proposal sheets
- Copy code from `design/features/implementation/*.md` files
- Make changes directly to Godot runtime

### All Other Agents (OpenCode, Claude, etc.)
1. Create **design document** in `design/` folder
2. Create **implementation code** in `design/features/implementation/` as proposal
3. Wait for **human review/approval**
4. After approval, implement and update design doc status to `complete`

### Required Process for New Features

```
design/
└── features/
    └── implementation/
        ├── FEATURE_NAME.md           ← Design doc
        └── FEATURE_NAME_CODE.md      ← Exact code to copy (PROPOSAL)
```

**Template locations:**
- Design doc: `design/00_meta/TEMPLATE_SYSTEM.md`
- Implementation: Copy existing `WEAPON_DATA_INTEGRATION_CODE.md` format

**Status labels:** `draft` → `review` → `complete`
