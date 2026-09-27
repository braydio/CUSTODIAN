# Python Simulation → Godot Remap Tracker

Status: active
Authority: `design/04_architecture/PYTHON_SIM_TO_GODOT_MIGRATION.md`

This tracker records completion of the remaining useful pre-Godot simulation
semantics. It does not make `python-sim/` active authority. Historical Python
is archaeology/parity input only.

## Completion Target

The remap is complete when:

- all retained deterministic campaign/world semantics have Godot-native owners;
- `WorldSimulationRuntime` remains the single authoritative macro runtime;
- loaded physical gameplay is never replaced by abstract Python-era resolution;
- required state survives snapshot/restore deterministically;
- cross-runtime parity exists where exact legacy behavior is intentionally retained;
- campaign state can be persisted to disk without Python at runtime;
- remaining `python-sim/` code is historical/reference material only.

## Tracker

| ID | Slice | Scope | Status | Completion evidence |
|---|---|---|---|---|
| REMAP-0 | Runtime foundation | Clock/kernel, commands, snapshots, policies, resources, strategic power, logistics, repair/fabrication foundations, invariants, campaign outcome | COMPLETE | Existing migration suite and parity v2 |
| REMAP-1 | Macro world-state completion | Relay state, deterministic systemic-event weighting/state, strategic assault state/handoff | COMPLETE | Macro-order/determinism/snapshot continuation smoke; parity v3 fixtures; physical WaveManager handoff and completion-observation boundary; migration suite |
| REMAP-2 | Infrastructure degradation completion | Wear, fidelity, full repair semantics, ambient fabrication semantics | QUEUED | Focused parity + snapshot/restore + macro-order validation |
| REMAP-3 | Campaign persistence | Disk save/load for authoritative campaign/world state and durable route/domain state where applicable | QUEUED | Save → process restart → restore → deterministic continuation |
| REMAP-4 | Migration closeout | Expand final parity surface, reconcile docs, classify intentionally retired Python systems, mark migration complete | BLOCKED_BY_1_2_3 | Final migration suite green; no unresolved active Python dependency |

## REMAP-1 — Macro World-State Completion

### Relay state

Retain only simulation-relevant semantics:

- relay identity/state;
- stability and deterministic decay;
- relay packets/sync state;
- retained knowledge/progression effects needed by current design;
- deterministic macro interactions used by other retained simulation systems.

Do not replace or absorb the current physical/player-facing ARRN runtime merely
because historical Python also modeled relays.

### Systemic events

Port deterministic state and selection behavior required for world simulation:

- event context;
- deterministic weighted selection;
- recent-event suppression;
- category/state bookkeeping;
- state-changing consequences that still exist in active design.

Do not port terminal prose generation as simulation authority.

### Strategic assaults

Port the macro state necessary to represent strategic pressure, approach,
targeting, scheduling, warning/handoff, and persistent outcome bookkeeping.

Loaded combat remains physical Godot gameplay under
`design/02_features/assault/ASSAULT_DESIGN_GODOT.md`.

Do not port Python tactical autopilot as authority over a loaded assault.

## REMAP-2 — Infrastructure Degradation Completion

### Wear

Port deterministic infrastructure/equipment degradation semantics that still
serve the active campaign model.

### Fidelity

Move retained macro fidelity state into authoritative simulation rather than
leaving it as transitional/read-only compatibility state.

Keep presentation/intelligence rendering separate from simulation authority.

### Repairs

Complete intentionally retained Python repair progression semantics beyond the
existing Godot foundation.

Do not duplicate the physical hold-repair interaction layer.

### Ambient fabrication

Port the retained deterministic autonomous fabrication behavior currently
disabled by the parity bootstrap.

Explicit queued fabrication already has a Godot foundation and must remain one
system rather than gaining a parallel implementation.

## REMAP-3 — Campaign Persistence

Persist authoritative state across process restarts.

At minimum reconcile:

- `WorldSimulationRuntime` snapshot state;
- campaign/session identity and exactly-once outcome state;
- persistent Domain/campaign data;
- route state explicitly intended to survive a save;
- schema/version migration;
- deterministic continuation after restore.

Process-local `RouteStateStore` persistence does not satisfy this row.

## Intentionally Not Literal Ports

These Python-era areas do not automatically become migration work:

- terminal parser / `/command` transport;
- tactical bridge architecture;
- prose/display helpers;
- Python scene/topology abstractions superseded by Godot world authority;
- physical perception/detection behavior superseded by live actor systems;
- physical defenses/structures already owned by Godot scenes and systems;
- Python tactical assault autopilot for loaded combat.

If archaeology discovers behavior with no active equivalent, classify it as
one of:

`PORT` / `SUPERSEDED` / `RETIRED` / `DESIGN_DECISION_REQUIRED`.

Do not create implementation work merely because a historical module exists.

## Dependency Order

```text
REMAP-1
relay
  ↓
systemic events
  ↓
strategic assault state
  ↓
REMAP-2
wear + fidelity + repair/fabrication completion
  ↓
REMAP-3
campaign persistence
  ↓
REMAP-4
final parity + migration closeout
```

## Progress

- Runtime foundation: 100%
- Macro world-state completion: 100%
- Infrastructure degradation completion: 0%
- Campaign persistence: 0%
- Migration closeout: 0%

Overall remaining-remap program: **~40% complete by slice count**
(runtime foundation and macro world-state completion are done; persistence and closeout remain).

### REMAP-1 classifications

- **PORT:** stable relay identities/sectors/status/stability decay, packet and knowledge progression, dormancy pressure; event context counters, category thresholds/base weights/context multipliers, recent-key suppression and deterministic seeded selection; strategic approach/target/ETA/warning/handoff/history; seeded deterministic continuation.
- **SUPERSEDED:** Python event key catalog/cooldowns and exact selection sequence (the Godot catalog is intentionally compact and consumes the serialized Godot RNG); Python event consequences that mutate its parallel sector damage/power/effect model; Python assault target weights, route graph, intercept-ammo simulation, and tactical bridge results. Godot macro events only change current `SectorSimulationState` alertness/occupancy and ambient threat. Assault completion is recorded only after a physical WaveManager completion observation.
- **RETIRED:** terminal event prose/name generation, detection/prose randomness, Python tactical autopilot, simulated kills/HP/ammunition/salvage, and Python assault outcome resolution.
- **DESIGN_DECISION_REQUIRED:** none for the retained REMAP-1 surface. Macro relay data remains campaign snapshot state; the existing ARRN autoload continues to own player-facing relay interaction.
