# CUSTODIAN — Godot Project

2.5D isometric real-time tactical base defense game.

Status: Active implementation runtime.

## Start Here

Before changing anything under `custodian/`, read `AGENTS.md`.

That file is the mandatory local primer for:

- active design and development state
- source-of-truth routing
- context retrieval across adjacent docs and runtime files
- documentation drift review and remediation
- migration execution instructions for layout or authority changes

## Run

```bash
cd custodian
godot
```

Or open `custodian/project.godot` and press `F5`.

## Current Project Structure

```text
custodian/
├── game/                   # All runtime (code + scenes)
│   ├── world/              # Tilemaps, procgen, navigation, compound
│   ├── systems/            # Fixed-step deterministic systems
│   ├── actors/             # Player/enemy/turret/etc scenes + scripts
│   ├── ui/                 # Runtime UI
│   └── rendering/          # Shaders + effects
├── content/                # Assets only (sprites, tiles, audio, etc.)
├── scenes/                 # Entry points (game.tscn, test_*.tscn)
├── addons/                 # Godot editor plugins
├── tools/                  # Import/pipeline scripts
├── dev/                    # Debug + test scenes/logs
└── docs/
	├── ARCHITECTURE.md
	├── GDSCRIPT_STANDARDS.md
	└── SCENE_HIERARCHY.md
```

## Runtime Contract

- Godot is authoritative for active gameplay state.
- Simulation runs as fixed-step deterministic logic.
- Tactical pause is a hard freeze of simulation progression.

## Controls

- `WASD`: move operator
- `Mouse`: aim
- `Arrow Keys`: aim when arrow-aim mode is enabled
- `F` or `Left Mouse`: attack
- `R` or `Right Mouse`: block
- `Q`: toggle ranged equip/holster
- `E`: toggle melee equip/holster
- `H`: hold repair
- `G`: interact (including Command sector terminal access)
- `C`: camera follow toggle
- `Z`: auto-zoom toggle
- `V`: toggle aim input mode (`Mouse` / `Arrows`)
- `X`: reload ranged weapon
- `T`: time shift
- `Space`: pause menu

## In-Game Command Terminal

- Command sector includes an interactable terminal prop.
- Terminal UI is rendered inside Godot and consumes the Godot-owned local
  snapshot and command boundaries.
- The terminal is self-contained; it has no external service dependency.

## Legacy Reference

The retired pre-Godot implementation is preserved in `../python-sim/` as a
historical artifact only. It has no active design, implementation, runtime,
validation, tooling, or source-of-truth authority.

## Design Doctrine

Canonical doctrine is maintained in:

- `../design/00_meta/MASTER_DESIGN_DOCTRINE.md`
- `AGENTS.md`
