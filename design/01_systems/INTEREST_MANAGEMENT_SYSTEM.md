# INTEREST MANAGEMENT SYSTEM

Status: in_progress
Owner: gameplay/systems
Runtime target: Godot 4 (`custodian/`)

## Goal

Introduce distance-based simulation tiers so large runtime spaces can keep far-away entities lightweight without deleting their world relevance.

## Runtime Contract

- `SimulationInterestManager` is an autoload that classifies `interest_managed` nodes relative to the player.
- Tier assignment is read-only from the manager’s perspective; target nodes decide what each tier means locally.
- Initial tiers:
  - `active`
  - `nearby`
  - `background`
  - `dormant`

## Initial Slice

1. Add `SimulationInterestManager` autoload.
2. Find the grouped player at runtime.
3. Compute distance bands each frame.
4. Call `set_simulation_tier(tier)` on compatible grouped nodes.
5. Surface active counts into `DevObservatory`.

## Constraints

- Tiering must not break deterministic ownership inside the controlled node.
- No special-case enemy logic in the manager; it only classifies.
- Keep the first slice conservative and low-risk.

## Acceptance

- Grouped runtime nodes can opt in via `interest_managed`.
- Nodes with `set_simulation_tier(...)` receive stable tier transitions.
- Live telemetry can report tier totals.
