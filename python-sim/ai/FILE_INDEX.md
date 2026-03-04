# FILE INDEX — CUSTODIAN

## Godot Project Structure

### Entrypoints

- `project.godot` — Godot 4.x project file
- Export via **Project → Export** menu

### Scenes

- `scenes/main/` — Main game scene and manager
- `scenes/operator/` — Player character (WASD-controlled)
- `scenes/sectors/` — Base sector scenes
- `scenes/combat/` — Enemy and projectile scenes
- `scenes/ui/` — Menus, HUD, pause overlay

### Scripts

- `scripts/core/` — Core systems (GameState, Systems)
- `scripts/entities/` — Entity behaviors
- `scripts/ui/` — Interface scripts

### Resources

- `resources/` — Assets, configs, tilemaps

---

## Legacy (Deprecated)

### Terminal Interface (Preserved for Reference)

- `custodian-terminal/server.py` — Terminal server
- `custodian-terminal/index.html` — Terminal UI
- `custodian-terminal/boot.js` — Boot sequence
- `custodian-terminal/terminal.js` — Input/output handling

### Python Simulation (Preserved for Reference)

- `game/simulations/world_state/core/state.py` — GameState
- `game/simulations/world_state/core/simulation.py` — Tick orchestration
- `game/simulations/world_state/core/assaults.py` — Assault system
- `game/simulations/world_state/terminal/` — Command parser/processor

---

## Design Documents

- `design/MASTER_DESIGN_DOCTRINE.md` — **LOCKED** master reference
- `design/00_foundations/` — Core design principles
- `design/10_systems/` — System specifications
- `design/20_features/` — Feature implementations
- `design/30_playable_game/` — Playable game layer docs
- `design/archive/` — Historical and deprecated docs

---

## Testing

Tests run via Godot's built-in test framework:

```bash
# If configured for headless
godot --headless --script tests/run.gd
```
