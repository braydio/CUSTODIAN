# WORLD STATE GRAPH SYSTEM

Status: in_progress
Owner: gameplay/systems
Runtime target: Godot 4 (`custodian/`)

## Goal

Provide a small reactive state graph for facility-level booleans and keyed values so repairs, power, terminals, lights, gates, and similar world systems can respond to shared world truth instead of isolated local flags.

## Runtime Contract

- `WorldStateGraph` is an autoload authority for keyed world state.
- State changes emit `state_changed(key, value)`.
- Optional dependency rules may derive output state from required input state.
- The graph is deterministic and data-light; it is not a general scripting engine.

## Initial Slice

1. Add `WorldStateGraph` autoload.
2. Support:
   - `set_state(key, value)`
   - `get_state(key, default)`
   - `add_dependency(output_key, required_states, output_value)`
3. Log state transitions into `DevObservatory`.
4. Wire an initial power/repair-facing key path for damageable sectors and power nodes.

## Constraints

- No scene-specific hard coupling inside the autoload.
- Keep rules explicit and inspectable.
- Do not move simulation authority out of existing owners; this graph mirrors or derives state after owners decide it.

## Acceptance

- Runtime systems can set and query keys from any scene.
- Derived state updates when dependencies become satisfied.
- Observability reflects world-state changes without introducing side effects.
