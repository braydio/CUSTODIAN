# CUSTODIAN Code Style Guide

> Coding conventions and best practices for the CUSTODIAN Godot project.

## Naming Conventions

### Classes & Scripts
- **PascalCase**: `WaveManager`, `EnemyDirector`, `GameState`
- File name matches class name: `wave_manager.gd` → `class_name WaveManager`

### Functions & Variables
- **snake_case**: `get_wave_number()`, `spawn_enemy()`, `lives_remaining`
- Prefix private with underscore: `_spawn_nodes`, `_game_state`

### Constants
- **UPPER_SNAKE_CASE**: `ENEMY_COST`, `MAX_WAVE`

### Signals
- **snake_case**: `wave_started`, `phase_changed`, `resources_changed`

## Signal Usage

### Declaring Signals
```gdscript
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()
```

### Emitting Signals
```gdscript
wave_started.emit(current_wave)
phase_changed.emit(old_phase, new_phase)
```

### Connecting Signals
```gdscript
# In _ready()
_game_state.phase_changed.connect(_on_phase_changed)

# Or via editor
```

## NodePath Usage

Avoid hardcoded strings. Use exported NodePath properties:
```gdscript
@export var game_state_path: NodePath = NodePath("/root/GameState")
@export var enemy_container_path: NodePath = NodePath("/root/GameRoot/World/Enemies")
```

## Memory Management

### Signal Disconnection
Always disconnect signals when freeing nodes:
```gdscript
func _exit_tree() -> void:
    if _game_state and _game_state.phase_changed.is_connected(_on_phase_changed):
        _game_state.phase_changed.disconnect(_on_phase_changed)
```

### Queue Free
```gdscript
enemy.queue_free()  # Safe deferred cleanup
```

## Type Hints

Use typed variables and return types:
```gdscript
var wave_number: int = 0
var active: bool = false
var _spawn_nodes: Array[SpawnNode] = []

func get_wave_info() -> Dictionary:
    return {"wave": wave_number, "active": active}
```

## Export Variables

Group related exports and add comments:
```gdscript
@export_group("Wave Settings")
@export var wave_interval: float = 45.0
@export var intra_wave_spawn_interval: float = 0.5

@export_group("Enemy Scenes")
@export var drone_scene: PackedScene
@export var fast_drone_scene: PackedScene
```

## Print Statements

Use for debug, wrap in debug check for release:
```gdscript
print("[WaveManager] Wave %d started" % wave_number)

# Or with conditional
const DEBUG := true
func _debug_print(msg: String) -> void:
    if DEBUG:
        print(msg)
```

## File Organization

```
game/systems/core/
├── state/
│   └── game_state.gd
├── systems/
│   ├── wave_manager.gd
│   ├── enemy_director.gd
│   └── combat.gd
└── player_controller.gd
```

## TODO Patterns

```gdscript
# TODO: Implement wave scaling logic
# FIXME: Memory leak in signal cleanup
# NOTE: Called from GameState only
```

---

*Last updated: 2026-04-08*