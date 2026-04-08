# CUSTODIAN Architecture Overview

> High-level system design and data flow for the CUSTODIAN Godot project.

## Core Systems Map

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AUTOLOADS (Singletons)                          │
├─────────────────────────────────────────────────────────────────────────────┤
│  GameState ─────────────────────────────────────────────────────────────── │
│  └── Central state machine: Phase, lives, materials, tick                  │
│                                                                             │
│  DevConsole ─────────────────────────────────────────────────────────────── │
│  └── In-game command console for debugging                                  │
│                                                                             │
│  DebugBus ───────────────────────────────────────────────────────────────── │
│  └── Debug signal routing and logging                                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           GAME STATE MACHINE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Phase.CONTRACT_BRIEFING ──► Phase.FREE_ROAM_PREP ──► Phase.ASSAULT_ACTIVE │
│           │                          │                        │            │
│           ▼                          ▼                        ▼            │
│    Contract loading        Prep/build time              Wave combat        │
│                                                                             │
│  Phase.ASSAULT_ACTIVE ──► Phase.POST_ASSAULT ──► Phase.EXFIL               │
│           │                          │                        │            │
│           ▼                          ▼                        ▼            │
│    End of waves              Summary/results              Exit             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Major Subsystems

### 1. Wave Manager (`wave_manager.gd`)
- Controls wave-based enemy spawning
- Emits: `wave_started`, `wave_completed`, `all_waves_completed`
- Configurable intervals, burst sizes, enemy composition
- References enemy scenes: drone, fast_drone, heavy_drone

### 2. Enemy Director (`enemy_director.gd`)
- AI director that influences spawn decisions
- Coordinates with WaveManager for difficulty scaling

### 3. Combat System (`combat.gd`)
- Damage calculation, hit detection
- Integrates with animation states (hit_recoil_state.gd)

### 4. Player Controller (`player_controller.gd`)
- Input handling, movement, camera control

### 5. Turret Placement (`turret_placement.gd`)
- Tower defense-style turret placement system

### 6. Wall Build System (`wall_build_system.gd`)
- Wall construction during prep phase
- Signals: `wall_built`, `build_started`, `build_progress`

### 7. Contract World Loader (`contract_world_loader.gd`)
- Procedural world generation
- Loads ContractMap data

### 8. Navigation System (`navigation_system.gd`)
- Pathfinding and navigation mesh handling

## Signal Communication

The project uses a **signal-driven decoupled architecture**:

| Signal | Emitter | Receivers |
|--------|---------|------------|
| `phase_changed(old, new)` | GameState | WaveManager, UI, World |
| `resources_changed()` | GameState | UI |
| `lives_changed(lives)` | GameState | UI |
| `wave_started(num)` | WaveManager | EnemyDirector, UI |
| `wave_completed(num)` | WaveManager | GameState, UI |
| `all_waves_completed()` | WaveManager | GameState |

## Scene Composition

```
scenes/game.tscn (Main)
├── GameRoot
│   ├── World
│   │   ├── Environment
│   │   ├── Enemies (container)
│   │   └── Navigation
│   ├── Camera
│   ├── UI
│   ├── WaveManager
│   ├── EnemyDirector
│   └── Combat
```

## Data Flow: Wave Execution

```
1. GameState.set_phase(ASSAULT_ACTIVE)
      │
2. WaveManager detects phase → starts wave timer
      │
3. WaveManager emits wave_started(wave_number)
      │
4. EnemyDirector receives → decides spawn composition
      │
5. SpawnNode instances → enemy scenes spawn
      │
6. Enemies pathfind via NavigationSystem
      │
7. Enemies damage player → Combat system resolves
      │
8. Wave ends → WaveManager emits wave_completed
      │
9. Repeat or all_waves_completed → GameState phase change
```

## Autoload Dependencies

```gdscript
# project.godot [autoload] section
GameState="*res://game/systems/core/state/game_state.gd"
DevConsole="*uid://ccoijpiv8l45j"
DebugBus="*res://dev/debug/debug_bus.gd"
```

## Key Files Reference

| System | Path |
|--------|------|
| State Machine | `game/systems/core/state/game_state.gd` |
| Wave Manager | `game/systems/core/systems/wave_manager.gd` |
| Enemy Director | `game/systems/core/systems/enemy_director.gd` |
| Combat | `game/systems/core/systems/combat.gd` |
| Player | `game/systems/core/player_controller.gd` |
| Turrets | `game/systems/core/systems/turret_placement.gd` |
| Walls | `game/systems/core/systems/wall_build_system.gd` |
| Navigation | `game/systems/core/systems/navigation_system.gd` |
| Contracts | `game/systems/core/systems/contract_world_loader.gd` |

## Conventions

- **Signals**: Used for all inter-system communication
- **Autoloads**: Global state (GameState) and editor tools (DevConsole)
- **NodePaths**: Hardcoded paths in exported properties (e.g., `NodePath("/root/GameRoot/World/Enemies")`)
- **Phase Enum**: Central gameplay state tracking

---

*Last updated: 2026-04-08*