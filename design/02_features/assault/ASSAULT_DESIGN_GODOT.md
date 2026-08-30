# Assault Design — Godot Runtime Authority

Status: active implementation authority
Last corrected: 2026-08-30

## Principle

Loaded assaults are physical Godot gameplay. `WaveManager` creates real Enemy
actors at real `SpawnNode`s; Enemy behavior selects and attacks real scene
objectives; turrets fire real projectiles; and physical health, power, loot,
and movement determine the result.

Determinism means authored or seeded inputs. It does not mean replacing loaded
combat with an abstract resolution model.

## Runtime ownership

```text
authored composition / point-budget cadence
                    ↓
              WaveManager
                    ↓
                SpawnNode
                    ↓
              physical Enemy
                    ↓
 behavior + navigation + target groups + combat
                    ↓
 Operator / turret / power_node / command_post
```

- `WaveManager` owns queueing, cadence, scene instantiation, lane selection,
  objective assignment, and observable wave status.
- `SpawnNode` is an authored physical lane marker with lane, weight, and active
  state.
- Enemy owns movement, targeting, attacks, damage reactions, death, and corpse
  loot after spawn.
- DefenseTurret owns acquisition and projectile fire subject to its actual
  power allocation.
- `SensorIntelligenceReadModel` observes living hostile actors; terminal pages
  consume projected read models rather than scenario-owned contact flags.

## Two ingress modes

Normal contract cadence uses GameState phase activation and deterministic
point-budget construction. `WaveManager` may choose eligible enemy types from
that budget and schedules subsequent waves.

Authored scenarios use:

```gdscript
start_external_wave(composition, lane, objective, behavior_profile)
```

This submits an exact composition through the same physical spawn path without
requiring automatic cadence. It is not a debug-spawn loop and does not resolve
outcomes. Scenario directors stop deciding combat after submission.

## Objective contract

Enemies resolve live targets through objective group priorities. Current
production objectives include `harass_player`, `destroy_power`,
`destroy_turrets`, and `breach_command`. Targets must be actual scene nodes in
the corresponding groups and must accept the normal combat damage contract.

## Navigation

Generated worlds use the current navigation system and walkability providers.
Authored shells may provide authored navigation data or use the existing direct
movement fallback when no graph exists. Actors still move through physics and
collision; teleporting or abstract travel is not an assault implementation.

## Economy and aftermath

Assaults do not spend or award strategic `GameState.materials` as their loaded
combat authority. Typed corpse salvage is rolled by the real enemy/corpse
runtime and reaches `ResourceLedger` only after physical collection. Turret
ammunition, sector damage, power loss, and repair remain owned by their live
systems.

## Explicit non-authorities

Do not use an abstract interception score, threat-point damage, simulated kill
count, simulated turret ammunition, mirrored infrastructure HP, or a
WorldSimulationRuntime outcome to decide a loaded assault. Strategic adapters
may observe a completed physical outcome for persistence; they do not choose
that outcome.

## Current proving scenario

`design/02_features/terminal/COMMAND_PRESSURE_SCENARIO_V1.md` defines the first
authored deterministic vertical slice. It fixes composition, lane, objective,
timing, and setup while preserving live physical outcomes.

## Validation

- WaveManager external plans instantiate the exact requested enemy scenes.
- Lane and objective reach every spawned actor.
- Actors move materially toward real targets.
- Turret projectiles reduce real Enemy HP.
- Enemy attacks reduce real infrastructure HP.
- PowerNode damage reduces actual generation.
- Sensors observe real hostiles.
- Wave completion observes pending spawns and living actors.

Historical pre-Godot implementations are archive material only and are not an
active design or runtime dependency.
