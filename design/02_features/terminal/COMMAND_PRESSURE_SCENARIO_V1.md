# Command Pressure Scenario V1

Status: active implementation authority
Scenario ID: `command_pressure_v1`
Title: `COMMAND POST UNDER PRESSURE: FIRST WATCH`

> **Command Pressure V1 is an authored orchestration of the live Godot game, not a miniature strategic simulator. The scenario decides what exists and when pressure arrives. Existing physical runtime systems decide what actually happens.**

## Purpose

This scenario is the first deterministic Command gameplay vertical slice. It
loads the ordinary `game.tscn` runtime, suppresses procgen and ambient cadence,
then arranges existing physical systems into a compact authored pressure test.
The terminal observes and commands those systems; it does not manufacture their
truth.

Launch with:

```bash
godot --path custodian res://scenes/game.tscn -- \
  --scenario command_pressure_v1
```

The scenario argument is development-only and does not alter the production
main scene or normal launches.

## Authority

| Concern | Runtime authority |
| --- | --- |
| Operator and enemy combat | live Operator and Enemy nodes |
| Assault creation | `WaveManager` plus authored `SpawnNode` |
| Movement and targeting | live Enemy behavior/navigation |
| Defense | actual `DefenseTurret` projectiles and power allocation |
| Generation and distribution | `Power`, `PowerNode`, and `Sector` |
| Integrity | physical `Damageable`/`Sector` health |
| Harvest and salvage | `ResourceNode` and `EnemyCorpseLoot` |
| Inventory and fabrication | `ResourceLedger`, `FabPipeline`, `BuildInventory` |
| Placement | `TurretPlacement` and `ConstructionPlacementController` |
| Command telemetry | `TerminalSnapshot` and `SensorIntelligenceReadModel` |
| Scenario setup | `CommandPressureScenarioDirector` |

The director owns authored setup, timing, objectives, and observation only. It
must never calculate combat outcomes, intercept attackers, mirror hit points,
award virtual salvage, or maintain a second economy.

## Isolation contract

Without the scenario argument, the bootstrap is inert. With it active:

- the command tutorial cannot create its prototype damage/setup;
- the contract loader does not claim generated placement;
- ambient enemies, ambient critters, and supply drops are disabled;
- automatic WaveManager cadence is disabled;
- procedural enemy variants are disabled;
- the fixed scene actors and systems remain the only runtime shell.

The scenario root may own presentation ground, five ResourceNodes, two service
ports, markers, and the director. It may not duplicate Operator, UI, Power,
WaveManager, navigation, fabrication, or placement systems.

## Authored layout and initial state

The scenario repositions only the existing nodes while active. Command remains
central; POWER is east, DEFENSE and the sole active north ingress are above it,
and service/fabrication spaces remain within walking distance. Exact transforms
and resource-node contracts live as constants in the director so setup and
validation read the same public scenario snapshot.

Initial physical state:

- POWER: 35% integrity;
- DEFENSE: 55% integrity;
- other sectors: full integrity;
- ResourceLedger: exactly five `ruin_scrap`, all other canonical resources zero;
- grid reserve: derived from live generation and demand to target 60–90 seconds
  of negative reserve at the default configuration;
- five physical resource nodes provide, in total, 24 scrap, 8 alloy,
  2 power components, 8 capacitor dust, and 1 resin clot.

The eight-alloy bottleneck makes `turret_basic` and `capacitor_bank_mk1`
mutually exclusive preparation choices without introducing scenario recipes.

## Command loop

The opening objective is `ACCESS COMMAND TERMINAL`; Command does not open
automatically. Terminal Overview derives degraded output, reserve trend,
sector integrity, contacts, resources, fabrication, and recommendations from
the existing snapshot/read-model path.

New world mutations route through `TerminalWorldActionService`, which invokes
public live APIs for sector toggles, priorities, emergency repair, fabrication,
and placement. Buttons and typed commands may share it. UI code must not mutate
physical state directly.

Remote emergency repair spends live electrical reserve. Physical service ports
require Operator proximity, uninterrupted hold time, ledger payment, and call
`repair()` on the same Sector. These are two costs applied to one authority.

## Assault contract

At 110 seconds of ordinary unpaused game delta, the director submits one
external authored wave:

```text
grunt, grunt, grunt, marine, grunt, grunt
lane: north
objective: destroy_power
procedural variants: disabled
```

`WaveManager.start_external_wave()` is the production ingress. It uses the
existing queue and spawn machinery but does not require the ordinary GameState
wave cadence. After spawning, the director makes no combat decisions. Enemies
target and attack actual scene nodes. Scenario turrets use zero spread; every
other acquisition, power, projectile, and damage rule remains live.

The authored shell uses the existing direct-movement fallback when no procgen
navigation graph is available. Enemies must still traverse collision normally;
teleporting is forbidden.

## Aftermath and outcome

Aftermath begins only after the authored wave has finished spawning, pending
spawns are zero, and living wave enemies are zero. The player must return to
Command. The after-action view reports physical final values and observed
deltas: sector HP, reserve/capacity/net, sector power state, fabrication,
placed structures, hostiles, repairs, collected resources, corpse salvage, and
the actual reserve low-water mark. It assigns no grade.

Success requires a cleared wave, living Operator, non-destroyed POWER, and a
return to Command. Existing Operator death remains failure; POWER destruction
is scenario failure.

## Determinism boundary

Authored and repeatable: layout, starting transforms and HP, starting ledger,
resource yields, reserve target, timing, composition, lane, objective, scenes,
variant policy, and turret spread.

Live outcomes: kill order, player damage, fighting/placement decisions, sector
switching, repair choices, damage incurred, corpse pickup, final resources,
reserve, and integrity.

## Validation

Automated validation is owned by:

- `command_pressure_scenario_setup_smoke.gd`
- `command_pressure_physical_loop_smoke.gd`

They prove isolation, exact setup, live harvesting/economy, authored-wave
spawning, movement, power consequences, physical combat/loot seams, Sensors,
and aftermath observation. Human balance and experiential playtesting are
explicitly outside automated acceptance and remain a developer review step.

## Scope exclusions

No procgen scenario, strategic outcome simulator, new resources/enemies/art,
campaign persistence, terminal-router rewrite, power rewrite, or assault-system
replacement belongs in V1.

## Next Agent Slice

Implement and validate the scenario bootstrap, root, director, world-action
service, generic physical repair interaction, WaveManager authored ingress,
terminal-derived scenario readout, two focused smokes, and documentation/index
updates. Preserve ordinary launch behavior and stage only task-owned files.
