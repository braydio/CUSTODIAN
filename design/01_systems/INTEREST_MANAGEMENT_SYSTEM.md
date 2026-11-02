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

## Current Live Enemy Workload (source + read-only local audit, 2026-10-08)

The original V1 behavioral prose below had become stale. The following is **observed implementation**, not a new approved offscreen simulation policy:

- `active`: ordinary root `_physics_process` work each physics callback.
- `nearby`: root `_physics_process` still enters but accumulates physics `delta`; `Enemy._simulation_tier_interval()` gates full root behavior updates to an interval of `0.10s`.
- `background`: the same root physics entry/accumulation, with `0.50s` interval for full behavior work. **This is throttled physical actor behavior, not an abstract 1–2 Hz world/sector simulator.**
- `dormant`: `Enemy.set_simulation_tier()` zeros root velocity and disables the **enemy root's** physics processing. The manager continues 0.20-second player-distance classification for reactivation. It does not automatically suspend independent descendant callbacks, bus signals or presentation.

Source: `custodian/game/actors/enemies/enemy.gd:548–570,1980–1988,2006–2030`; `custodian/game/systems/simulation/simulation_interest_manager.gd:3–49`. The user-supplied read-only local agent audit reported `enemy_runtime_attribution_perf_bench.gd` **PASS** with eight dormant actors producing zero root enemy physics spans, while all eight remained presentation-enabled. This is not an end-to-end subtree-suspension or unloaded-world reification test. Its code inspection identified a **possible**, not runtime-reproduced, dormant noise-bus blackboard mutation path in `enemy_perception_component.gd`.

**Design intent retained:** Do not replace live actor behavior with imaginary offscreen consequences until a single authoritative abstract simulation and stable geographic identity/handoff contract is implemented. See [F14 living-world simulation audit](../04_architecture/codebase_systems_audit/F14_LIVING_WORLD_SIMULATION.md) and [F15 geographic topology](../04_architecture/codebase_systems_audit/F15_CAMPAIGN_WORLD_GEOGRAPHY.md). These audits are not yet locked implementation authority.

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
- Define an **authoritative abstract** background update before suppressing remaining physical background processing; `Enemy`'s existing 0.50s root-physics throttle is not this system. Cadence, identity and handoff remain F14/F15 design decisions, not a preapproved 1–2 Hz setting.
- Replace repeated group snapshots with registration only if profiling still shows meaningful allocation cost.
