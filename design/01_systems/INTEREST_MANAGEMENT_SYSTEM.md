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

## Live Workload Slice

1. Add `SimulationInterestManager` autoload.
2. Find the grouped player at runtime.
3. Compute squared distance bands at 5 Hz (`0.20s`), with one immediate initial classification.
4. Call `set_simulation_tier(tier)` on compatible grouped nodes.
5. Surface active counts into `DevObservatory`.

Enemy workload semantics are deliberately conservative:

- `active`: ordinary physics/behavior processing.
- `nearby`: ordinary physics/behavior processing.
- `background`: ordinary physics/behavior processing until an abstract 1–2 Hz tick exists.
- `dormant`: zero velocity and local physics processing disabled. The always-running manager remains responsible for reactivation.

Screen visibility is never simulation authority. `VisibleOnScreenNotifier2D` or equivalent visibility signals may suppress sprite animation, health bars, particles, decorative VFX, optional audio, or interpolation only. Camera movement and zoom must not stop perception, navigation, movement, attacks, or objective behavior.

## Constraints

- Tiering must not break deterministic ownership inside the controlled node.
- No special-case enemy logic in the manager; it only classifies.
- Keep the first slice conservative and low-risk.
- Do not disable `background` entities until an authoritative abstract/background update path exists.

## Acceptance

- Grouped runtime nodes can opt in via `interest_managed`.
- Nodes with `set_simulation_tier(...)` receive stable tier transitions.
- Classification does not rerun inside the configured 0.20-second budget.
- Dormant enemies stop local physics and resume when reclassified by distance.
- Live telemetry can report tier totals.

## Next Slice

- Add hysteresis at band edges.
- Add an authoritative 1–2 Hz background tick before suppressing normal background processing.
- Replace repeated group snapshots with registration only if profiling still shows meaningful allocation cost.
