# Procedural-Generation-Forward Prototype Roadmap

## Purpose

Define a development roadmap that shifts CUSTODIAN from "deterministic systems with light text variation" to a prototype where procedural generation is a primary gameplay driver across world setup, threats, logistics pressure, and operator decision space.

This document is a `planned` feature roadmap and process guide. It is intentionally implementation-facing.

## Problem Statement (Current State)

Current procgen value is real but mostly concentrated in output texture and event selection. The lived loop still reads as fixed-pattern because:

- Sector topology is static and known.
- Strategic chokepoints are mostly constant across runs.
- Threat timing profiles become legible quickly.
- Recovery arcs are similar even with seed changes.
- UI projection does not yet surface high-contrast run identity.

## Design Goals

1. Preserve deterministic replay: same seed + same command stream => same world and outcomes.
2. Increase run-to-run strategic variance: route control, pressure sequencing, and scarcity profile should change.
3. Keep information discipline: degraded fidelity still withholds or generalizes truth.
4. Keep systems-first architecture: procgen changes simulation state, UI only projects results.
5. Ship in stable slices with test gates at every phase.

## Non-Goals

- No real-time engine coupling.
- No nondeterministic runtime generation.
- No freeform narrative generation that can invent non-authoritative facts.
- No UI-only randomness disconnected from simulation state.

## Procgen Pillars

1. Topology Generation: transit graph and approach lanes vary per seed under locked invariants.
2. Threat Doctrine Generation: hostile profile drives behavior trees and pacing weights.
3. Economy/Infrastructure Generation: repair bottlenecks, salvage pools, and fabrication strain differ by run.
4. Event Chain Generation: events form deterministic chains with branch constraints, not isolated rolls.
5. Objective and Scenario Generation: runs present different operational priorities and failure pressure.
6. Signal Surface Generation: output language/telemetry remains deterministic and fidelity-bound, but variation reflects actual run state.

## Locked Invariants

- Command contract remains `CommandResult(ok, text, lines?, warnings?)`.
- Status fidelity rules in `design/10_systems/procgen/INFORMATION_DEGRADATION.md` remain authoritative.
- Internal tokens can remain shorthand; user-facing surfaces must use full names.
- Core entrypoints remain stable (`python -m game`, `--ui`, `--sim`, `--repl`) unless explicitly migrated.
- Snapshot compatibility must be maintained or migrated with versioned adapters.

## Roadmap Overview

## Phase 0: Instrumentation Baseline

### Scope

- Add run fingerprint telemetry to snapshots and dev traces.
- Define objective variability metrics so "more procgen" is measurable.

### Implementation Targets

- `game/simulations/world_state/core/state.py`
- `game/simulations/world_state/core/simulation.py`
- `game/simulations/world_state/tests/test_snapshot.py`

### Deliverables

- `run_fingerprint` object in snapshot (topology hash, threat profile hash, economy profile hash).
- `debug procgen report` output in dev mode (no gameplay effect).
- Baseline variability script/check for N seeded runs.

### Exit Criteria

- Deterministic replay unchanged.
- Snapshot tests updated and passing.
- Can compare seeds with explicit, machine-readable procgen fingerprints.

## Phase 1: Seeded Topology Profiles

### Scope

- Generate transit and ingress profile variants from seed under hard constraints.
- Keep canonical sectors, vary connective pressure and interception lanes.

### Implementation Targets

- `game/simulations/world_state/core/location_registry.py`
- `game/simulations/world_state/core/tactical_bridge.py`
- `game/simulations/world_state/core/assaults.py`
- `game/simulations/world_state/core/display_names.py`
- `game/simulations/world_state/tests/test_transit_fortification.py`

### Deliverables

- Topology profile generator with deterministic template families.
- Seeded route-class assignments (for example high-risk north corridor vs distributed ingress).
- Status/snapshot fields exposing generated topology summary.

### Exit Criteria

- Same seed reproduces identical topology graph.
- Different seed frequently changes route pressure profile.
- No user-facing shorthand leaks in generated labels.

## Phase 2: Threat Doctrine Generator Expansion

### Scope

- Move from faction label flavor to behaviorally distinct doctrine packages.
- Doctrine affects assault cadence, target selection weighting, and chain likelihoods.

### Implementation Targets

- `game/simulations/world_state/core/factions.py`
- `game/simulations/world_state/core/assaults.py`
- `game/simulations/world_state/core/events.py`
- `game/simulations/world_state/tests/test_assault_doctrine_variation.py`

### Deliverables

- Deterministic doctrine package schema (`tempo`, `priority_bias`, `harassment_bias`, `attrition_bias`).
- Doctrine-specific assault/event policy hooks.
- Seed-stable doctrine projection in snapshots.

### Exit Criteria

- Cross-seed doctrine mix creates meaningfully different pressure rhythms within first 50 ticks.
- Existing assault determinism tests pass with updated expectations.

## Phase 3: Economy and Logistics Profile Generation

### Scope

- Generate initial scarcity model and throughput constraints per run.
- Make fabrication and repair planning diverge by seed.

### Implementation Targets

- `game/simulations/world_state/core/logistics.py`
- `game/simulations/world_state/core/fabrication.py`
- `game/simulations/world_state/core/repairs.py`
- `game/simulations/world_state/tests/test_colony_sim_features.py`

### Deliverables

- Deterministic economy profile (`material_inflow_curve`, `wear_pressure`, `repair_tax`).
- Profile-aware queue and repair pacing behavior.
- Operator-visible policy pressure lines in `STATUS FULL`.

### Exit Criteria

- Run archetypes emerge (repair-starved, power-starved, balanced).
- No profile makes early game unwinnable by default without policy error.

## Phase 4: Event Chain Graph System

### Scope

- Replace mostly independent event triggers with chain-capable graph progression.
- Add deterministic precondition and cooldown edges.

### Implementation Targets

- `game/simulations/world_state/core/events.py`
- `game/simulations/world_state/core/event_records.py`
- `game/simulations/world_state/core/state.py`
- `game/simulations/world_state/tests/test_assault_trace.py`

### Deliverables

- Event graph config with typed nodes and edges.
- Chain-state tracker in `GameState`.
- Structured event trace output for dev validation.

### Exit Criteria

- Chains remain deterministic and reproducible.
- Event pacing feels less "single-roll random" and more "developing incident pattern."

## Phase 5: Scenario and Objective Generation

### Scope

- Generate seeded objective packages that change what the player must prioritize.
- Tie objective pressure to archive risk, relay stabilization, and infrastructure burden.

### Implementation Targets

- `game/simulations/world_state/core/hub.py`
- `game/simulations/world_state/core/state.py`
- `game/simulations/world_state/terminal/commands/status.py`
- `game/simulations/world_state/tests/test_hub_and_campaign.py`

### Deliverables

- Objective package generator (`primary objective`, `secondary constraint`, `time pressure`).
- Snapshot and status exposure of current objective pressure.
- Failure/recovery hooks aligned to objective type.

### Exit Criteria

- First 10-20 command decisions change based on objective package.
- Objective generation remains bounded and readable in terminal output.

## Phase 6: Procgen Surface and UX Readability

### Scope

- Make procgen state legible without violating fidelity rules.
- Expand map overlays and terminal summaries to show run identity signals.

### Implementation Targets

- `custodian-terminal/sector-map.js`
- `custodian-terminal/terminal.js`
- `game/simulations/world_state/terminal/commands/status.py`
- `game/simulations/world_state/tests/test_snapshot.py`

### Deliverables

- Run identity panel (doctrine, topology profile, economy profile) using full-name labels.
- Seeded but deterministic variant summaries in non-authoritative text surfaces.
- Updated tutorial/help text for procgen-aware operator guidance.

### Exit Criteria

- New users can identify what is unique about a run within 30 seconds.
- UI remains compliant with no-shorthand user-facing naming policy.

## Testing Strategy (Per Phase)

Every phase must include:

- Unit tests for new generators and invariants.
- Determinism tests (same seed replay).
- Cross-seed variance tests (minimum variability threshold checks).
- Snapshot compatibility tests (versioned migrations where needed).
- Terminal contract tests for command output shape.

## Variability KPIs

Track these metrics on a fixed seed suite:

1. Topology diversity index across N seeds.
2. Threat cadence entropy for first 100 ticks.
3. Economy pressure spread (repair backlog and resource floor variance).
4. Objective divergence score (different optimal opening commands).
5. Duplicate-run similarity score for adjacent seeds.

Target: increase cross-seed divergence without reducing same-seed replay fidelity.

## Planned Feature Dev Process

Use this process for each roadmap phase:

1. Create or update a phase-specific feature doc in `design/20_features/planned/`.
2. Define scope, impacted files, invariants, tests, migration concerns, and acceptance criteria.
3. Move doc to `design/20_features/in_progress/` only when implementation starts.
4. Implement in coherent slices with tests after each slice.
5. Update relevant `design/10_systems/*` docs as behavior lands.
6. Update `design/CHANGELOG.md` and `ai/CURRENT_STATE.md` when code behavior changes.
7. Move phase doc to `design/20_features/completed/` only after tests pass and docs are synchronized.

## Suggested Phase Documents To Create Next

- `PROCGEN_PHASE0_INSTRUMENTATION.md`
- `PROCGEN_PHASE1_TOPOLOGY_PROFILES.md`
- `PROCGEN_PHASE2_DOCTRINE_BEHAVIOR.md`
- `PROCGEN_PHASE3_ECONOMY_PROFILES.md`
- `PROCGEN_PHASE4_EVENT_CHAIN_GRAPH.md`
- `PROCGEN_PHASE5_OBJECTIVE_GENERATION.md`
- `PROCGEN_PHASE6_SURFACE_READABILITY.md`

## Review Checklist

- Does this phase increase strategic variance, not just text variance?
- Are deterministic invariants explicit and testable?
- Are user-facing labels full-name and non-shorthand?
- Is snapshot compatibility preserved?
- Are acceptance criteria observable within a short operator session?
