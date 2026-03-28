# FREE-ROAM PRE-ASSAULT WALKTHROUGH

**Project:** CUSTODIAN
**Last Updated:** 2026-03-19
**Status:** Active implementation plan

## Purpose

Convert the current Godot runtime from "boot straight into wave defense" into a mission flow where the player can:

1. Spawn into a traversable procgen compound
2. Explore and scavenge before combat starts
3. Prepare defenses through real world and terminal interactions
4. Manually trigger the assault when ready

This document is implementation-first. It is grounded in the current runtime, not the legacy Python sim.

## Current Runtime Reality

The current runtime is still a combat slice:

- Contract generation and procgen world promotion are implemented
- Operator, spawn nodes, terminal, and item anchors are repositioned into procgen space by `ContractWorldLoader`
- Camera procgen support exists in `camera.gd` and the camera already joins the `camera` group
- Waves still auto-start from `WaveManager`
- `GameState` is too thin to drive mission phases
- The terminal is mostly read-only snapshot/status output
- Sector identity is still hybrid: procgen positions are used, but sectors are not yet a full prep-gameplay authority layer

## What Already Exists

These are not plan items unless verification shows they are still broken:

- `ContractWorldLoader.set_runtime_map(...)` path into camera refresh
- Camera procgen bound rebuilding in `res://scenes/camera.gd`
- Camera group registration in `res://scenes/camera.gd`
- Procgen repositioning for:
  - operator
  - spawn nodes
  - command terminal
  - item anchors

The plan below starts from what is actually missing now.

## Target Mission Flow

```
CONTRACT_BRIEFING
    ->
FREE_ROAM_PREP
    ->
ASSAULT_ACTIVE
    ->
POST_ASSAULT
    ->
EXFIL
```

### Phase Intent

| Phase | Player Experience | WaveManager |
|---|---|---|
| `CONTRACT_BRIEFING` | Spawn, reveal contract, orient player | Off |
| `FREE_ROAM_PREP` | Traverse, scavenge, route power, fortify, fabricate | Off |
| `ASSAULT_ACTIVE` | Defend against waves | On |
| `POST_ASSAULT` | Cleanup, summary, secure compound | Off |
| `EXFIL` | Leave mission space | Off |

## Blockers Before Free-Roam Feels Real

### 0. Procgen Handoff Verification and Cleanup

This is the first implementation slice because free-roam will feel fake if world-space is still unstable.

### Required checks

1. Confirm camera limits come from procgen map bounds in live play
2. Confirm camera snaps to the procgen operator spawn after contract generation
3. Confirm mouse aim is correct after procgen handoff
4. Confirm terminal and ammo caches are actually reachable in procgen space

### Repo-grounded notes

- Camera support is already present in `custodian/scenes/camera.gd`
- Camera refresh is already called from `custodian/core/systems/contract_world_loader.gd`
- Terminal and item anchor repositioning are already implemented in `custodian/core/systems/contract_world_loader.gd`
- `operator.gd` still uses `get_global_mouse_position()` for aim/fire and needs runtime verification under procgen handoff

### Deliverable

When this slice is done:

- player movement feels local to the procgen map
- aiming tracks the cursor correctly
- the terminal and caches are placed where the player can reasonably use them

## Phase 1: Mission State Machine

This is the real structural start of pre-assault gameplay.

### Problem

`WaveManager` currently auto-starts combat on boot. There is no mission phase authority and almost no run-state beyond pause/game-over.

### Required runtime changes

#### 1. Extend `GameState`

Add:

- phase enum
- current phase
- phase start tick
- assault started tick
- materials
- defense rating
- prep-related mission flags

Suggested minimum:

```gdscript
extends Node
class_name GameState

enum Phase {
    CONTRACT_BRIEFING,
    FREE_ROAM_PREP,
    ASSAULT_ACTIVE,
    POST_ASSAULT,
    EXFIL,
}

signal phase_changed(old_phase: int, new_phase: int)
signal resources_changed()

var tick := 0
var paused := false
var game_over := false
var game_over_reason := ""

var current_phase: int = Phase.CONTRACT_BRIEFING
var phase_start_tick: int = 0
var assault_started_tick: int = -1

var materials: int = 0
var defense_rating: float = 0.0

func set_phase(new_phase: int) -> void:
    if current_phase == new_phase:
        return
    var old_phase := current_phase
    current_phase = new_phase
    phase_start_tick = tick
    phase_changed.emit(old_phase, new_phase)

func can_start_assault() -> bool:
    return current_phase == Phase.FREE_ROAM_PREP and not game_over

func start_assault() -> bool:
    if not can_start_assault():
        return false
    assault_started_tick = tick
    set_phase(Phase.ASSAULT_ACTIVE)
    return true
```

#### 2. Gate `WaveManager` by phase

Replace boot-time auto-start behavior with phase-driven activation.

Required behavior:

- `WaveManager` stays idle in briefing and prep
- entering `ASSAULT_ACTIVE` starts the first wave
- leaving assault stops timers and pending spawns
- completing all waves advances state to `POST_ASSAULT`

#### 3. Add explicit briefing -> prep transition

Simple first version:

- game starts in `CONTRACT_BRIEFING`
- closing briefing UI or pressing a continue action moves to `FREE_ROAM_PREP`

### Deliverable

The game should boot into a quiet traversal state, not immediate combat.

## Phase 2: Manual Assault Trigger

This is the minimum feature that makes pre-assault agency real.

### Player-facing rule

The assault starts only when the player deliberately triggers it.

### First implementation surface

Use the existing command terminal first. Keep the interaction surface narrow before adding more UI.

### Required commands

| Command | Result |
|---|---|
| `STATUS` | Shows phase, prep resources, assault readiness |
| `START_ASSAULT` | If in prep phase, enters `ASSAULT_ACTIVE` |
| `HELP PREP` | Lists prep commands |

### Important note

The current local terminal implementation in `custodian/scenes/ui.gd` is mostly snapshot/status only. This phase requires the terminal to stop pretending prep commands exist and start wiring them to runtime systems.

### Deliverable

Player can:

- explore during prep
- walk to terminal
- trigger assault intentionally

## Phase 3: Authoritative Sector Roles

Free-roam only becomes meaningful if the world has real places with distinct function.

### Problem

The procgen compound currently has positioned sector-like footprints, but sector gameplay authority is still hybrid and static-scene-biased.

### Required sector roles

| Sector | Prep Function |
|---|---|
| `COMMAND` | Mission state, assault trigger, tactical overview |
| `POWER` | Rerouting, restoration, system uptime |
| `DEFENSE` | Turret readiness, fortification, defensive bonuses |
| `FABRICATION` | Item crafting, ammo, field repair support |
| `STORAGE` | Resource pickup/cache gameplay |
| `ARCHIVE` | Intel, contract lore, optional objectives |

### Implementation direction

Do not spawn an entirely separate abstract strategy layer first.

Instead:

1. Keep using the procgen-aligned sector footprints from `ContractWorldLoader`
2. Promote sector nodes into authoritative runtime interaction points
3. Add per-sector scripts or components where needed
4. Treat them as both world objects and gameplay systems

### Deliverable

Each major sector has a clear function during prep and combat.

## Phase 4: Real Prep Systems

This is the layer that turns exploration into preparation instead of dead air.

### 4.1 Materials and scavenging

Required first:

- material pickups in world space
- supply drops or scavenging nodes that can yield more than ammo
- `GameState.materials` or a dedicated runtime resource authority

Start simple:

- spawn pickups in procgen rooms or near non-critical paths
- use direct pickup interactions
- no inventory grid yet

### 4.2 Fabrication

Required first recipes:

- ammo crate
- repair kit or repair charge
- temporary defense boost
- power cell

This should likely live behind `FABRICATION` sector access or terminal command access while near fabrication.

### 4.3 Fortification

Required first fortify actions:

- spend materials to boost compound defense rating
- optionally spend resources to reinforce ingress lanes
- apply simple, deterministic combat bonuses during assault

First-pass bonuses can be modest and global:

- lower incoming threat multiplier
- extra turret uptime
- reduced structure damage

### 4.4 Power prep decisions

Do not build an overcomplicated sim first.

First-pass requirements:

- surface power status clearly
- allow power to be redirected toward defense or fabrication
- make low power visibly constrain prep options

### Deliverable

The player can gather resources and spend them on prep choices that actually change assault outcomes.

## Phase 5: Terminal and World Prep Interface

The terminal should become a real control surface, but not the only one.

### Terminal commands for first playable prep loop

| Command | Purpose |
|---|---|
| `STATUS` | Current phase, materials, defense, power |
| `FAB <item>` | Fabricate a supported item |
| `FORTIFY` | Spend materials for defense bonus |
| `POWER <target> <amount>` or equivalent | Redirect limited power |
| `START_ASSAULT` | Begin combat |
| `HELP PREP` | Command list |

### World interaction requirements

- sector prompts should explain what interaction does
- major prep actions should be possible from world objects, not terminal only
- the player should be able to do at least one useful prep action without reading a doc

### Deliverable

The prep loop works through both:

- in-world traversal and interaction
- terminal command execution

## Phase 6: Assault Outcome Coupling

Prep must matter once the assault begins.

### Required coupling

At minimum, prep should feed into one or more of:

- threat budget
- lane pressure
- turret effectiveness
- structure survivability
- available repair/ammo/power reserves

### First pass recommendation

Keep the math explicit and deterministic:

- `defense_rating` reduces assault budget by a bounded multiplier
- fabricated assets spawn as usable world support
- routed power changes which systems stay online under pressure

### Deliverable

The player should feel the difference between:

- entering assault unprepared
- entering assault after meaningful prep

## Implementation Order

### Slice A: Verify and finish procgen handoff

Files:

- `custodian/scenes/camera.gd`
- `custodian/core/systems/contract_world_loader.gd`
- `custodian/entities/operator/operator.gd`

Goals:

- verify bounds
- verify snap
- verify aim
- verify reachable anchors

### Slice B: Add mission phases and stop auto-waves

Files:

- `custodian/core/state/game_state.gd`
- `custodian/core/systems/wave_manager.gd`
- `custodian/scenes/game.tscn`
- `custodian/scenes/ui.gd`

Goals:

- add `Phase`
- add phase transitions
- remove boot-time forced combat
- display current phase

### Slice C: Add manual assault start

Files:

- `custodian/scenes/ui.gd`
- `custodian/entities/terminal/command_terminal.gd`

Goals:

- terminal starts assault
- status shows prep state

### Slice D: Promote sectors into prep gameplay anchors

Files:

- `custodian/core/systems/contract_world_loader.gd`
- `custodian/entities/sector/*`
- any new sector scripts needed

Goals:

- real role per sector
- world prompts
- sector-driven prep actions

### Slice E: Add minimum viable prep systems

Files:

- new prep/resource scripts as needed
- `custodian/scenes/ui.gd`
- relevant sector scripts

Goals:

- materials
- scavenging
- fabrication
- fortification
- power decisions

## First Playable Definition

This feature is considered first-playable when all of the following are true:

1. The game boots into `FREE_ROAM_PREP` instead of immediate combat
2. The player can traverse the procgen map cleanly
3. The player can collect at least one kind of prep resource
4. The player can spend that resource on at least one prep action
5. The player must manually trigger assault
6. That prep action has a visible effect once the assault begins

## Out of Scope for First Pass

These can wait until the above is playable:

- full save/persistence
- campaign map progression
- ARRN relay progression
- elaborate terminal parser
- deep economy simulation
- exfil complexity beyond a simple endpoint

## Open Design Calls

These still need decisions during implementation:

1. Should `materials` live directly in `GameState` first, or in a dedicated resource system with `GameState` mirroring it?
2. Should `FABRICATION` be a promoted sector from existing compound pads or a new runtime-spawned node type?
3. Should fortification apply globally first, or per ingress/lane first?
4. Should the first assault always be manually triggered from `COMMAND`, or should the terminal prop remain the primary trigger?

## Recommendation

Use this document as the active plan.

Do not write a second competing plan unless implementation exposes a hard contradiction. The immediate coding sequence should be:

1. verify procgen handoff in runtime
2. implement mission phases
3. stop auto-wave start
4. add manual assault trigger
5. add one real prep resource and one real prep spend
