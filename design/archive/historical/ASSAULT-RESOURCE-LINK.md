# ASSAULT-RESOURCE-LINK (Implementation-Ready)

This document replaces the older draft assumptions with a design that fits the current world-state codebase.

## Implementation Status

- Phase A is now implemented in the live codebase (`core/assaults.py`) with deterministic transit interception, ammo spend, and bounded threat-budget mitigation before engagement.
- Phase B is implemented in the live codebase (`FORTIFY T_NORTH|T_SOUTH` transit-lane prep coupled to interception).
- Phase C salvage coupling is locked by `CLARIFY.md` and implemented in `core/assaults.py`.

## Goal

Link assault outcomes to operator resource decisions before, during, and after engagement without adding UI-heavy systems.

Desired loop:

`Allocate/Fabricate -> Intercept/Assault -> Damage/Salvage -> Repair/Rebuild -> Repeat`

## Reality Check (Current Code)

Implemented now:
- Structure lifecycle exists (`OPERATIONAL`, `DAMAGED`, `OFFLINE`, `DESTROYED`).
- Materials economy exists (`state.materials`) and is used by repair/scavenge.
- Assault approaches are spatial (`INGRESS_N`/`INGRESS_S` over `WORLD_GRAPH`).
- Tactical assaults are multi-tick and consume `turret_ammo_stock` each assault tick.
- Repair drones, fabrication queue, and stock outputs exist (`REPAIR_DRONE`, `TURRET_AMMO`, inventory tiers).
- Defense doctrine/allocation and fortification levels already influence assault pressure.

Not implemented now:
- Player-placed structures at transit nodes.
- Transit-node-specific pre-engagement interception effects.
- A direct operator command that spends materials to modify inbound approaches.

## Design Constraints

- No new rendering/UI requirements.
- Keep world mutation in simulation tick paths (`step_world` and assault/approach helpers).
- Reuse existing resources (`materials`, `turret_ammo_stock`, `repair_drone_stock`, fortification, policies).
- Preserve deterministic behavior for seeded runs/tests.

## Recommended Live Phase

## Phase A: Transit Interception (No New UI)

Add a deterministic pre-engagement interception layer while assaults traverse `T_NORTH`/`T_SOUTH`.

### Mechanics

1. Interception trigger:
- In `core/assaults.py::advance_assaults`, when an approach is on a transit node, run interception once per node pass.

2. Resource gate:
- Interception requires `state.turret_ammo_stock >= 1`.
- If ammo is available, spend 1 ammo.
- If ammo is not available, no interception mitigation is applied.

3. Mitigation effect:
- Store approach-local mitigation on `AssaultApproach` (new field, e.g. `threat_mult` default `1.0`).
- Apply a bounded reduction (example: multiply by `0.9`) per successful intercept.
- Scale intercept strength by existing fortification/readiness signals (small bonus only).

4. Engagement handoff:
- When approach reaches target and `_start_assault` is called from `advance_assaults`, convert mitigation to assault `threat_budget` scaling.
- Clamp to safe bounds (example floor `0.7`, ceiling `1.0`) to avoid nullifying assaults.

5. Operator feedback:
- Append concise line to `state.last_assault_lines` when intercept fires, e.g. `[INTERCEPT] T_NORTH DELAYED HOSTILES`.
- Keep output fidelity-gated via existing WAIT rendering behavior.

### Why this phase first

- Uses existing assault movement model.
- Uses existing resource stocks.
- Requires no new command surface to be useful.
- Creates immediate link between fabrication/defense prep and assault severity.

## Phase B: Explicit Material Spend (Command-Level)

After Phase A stabilizes, add an operator command to spend materials on lane prep.

Command:
- `FORTIFY T_NORTH <0-4>` or a dedicated command (recommended: keep existing `FORTIFY` and extend accepted targets).

Behavior:
- Transit fortification level contributes to interception multiplier in Phase A.
- Uses existing fortification semantics and policy load tradeoffs.

## Phase C: Salvage Coupling

Refine salvage to reflect resource burn and intercept effectiveness.

Locked formula:

`FINAL_SALVAGE = clamp(BASE_OUTCOME_SALVAGE + INTERCEPTION_EFFICIENCY_MOD - RESOURCE_BURN_PENALTY, MIN[outcome], MAX[outcome])`

1. Base outcome salvage (deterministic):
- `none -> 30`
- `partial -> 20`
- `severe -> 10`

2. Interception efficiency:
- `intercept_ratio = clamp(intercepted_units / total_assault_units, 0.0, 1.0)`
- `efficiency_bonus = round(10 * intercept_ratio)` (range `0..10`)

3. Resource burn penalty:
- `burn_score = intercept_ammo_spent * 1.0 + tactical_ammo_spent * 0.5 + transit_fortification_wear * 2.0`
- `burn_penalty = clamp(round(burn_score / 10), 0, 12)`

4. Outcome clamp envelopes:
- `none: min=25 max=45`
- `partial: min=15 max=35`
- `severe: min=5 max=20`

5. Locked edge handling:
- If `total_assault_units == 0`, use `partial` tier for base/clamp.
- Deterministic only; no extra RNG.

6. Accounting:
- Ledger is assault-scoped (`AssaultInstance.salvage_ledger`).
- Final salvage mutates `GameState.materials`.
- Burn metrics are not persisted after assault resolution.

7. Operator surfacing:
- After-action summary includes concise salvage breakdown lines:
  - Base salvage
  - Interception efficiency
  - Resource burn
  - Final salvage

## Required Code Touchpoints

Primary:
- `game/simulations/world_state/core/assaults.py`
  - `AssaultApproach` state extension.
  - `advance_assaults` interception hook.
  - `_start_assault` threat-budget scaling from approach mitigation.

Secondary:
- `game/simulations/world_state/core/state.py`
  - Optional tracking counters for post-action reporting (intercepts triggered, ammo spent pre-engagement).

Presentation:
- `game/simulations/world_state/terminal/commands/wait.py`
  - Reuse existing assault line surfacing; only add formatting if needed.
- `game/simulations/world_state/terminal/commands/status.py`
  - Optional concise indicator (example: `INTERCEPT: READY/DEPLETED`).

## Test Plan (Must Add)

1. `advance_assaults` spends ammo and applies mitigation at transit nodes.
2. No ammo means no mitigation.
3. Mitigation affects resulting assault threat budget at engagement.
4. Bounds hold (mitigation cannot reduce below configured floor).
5. WAIT output includes interception signal line when triggered.
6. Determinism check with fixed seed.

## Non-Goals (for this feature)

- No turret placement UI.
- No projectile simulation.
- No free-form build grid.
- No new combat subsystem.

## Decision

Implement Phase A first. It is directly compatible with the current architecture and creates immediate, understandable resource-to-assault coupling with minimal risk.
