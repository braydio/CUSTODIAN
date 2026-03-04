# Unified TODO

Last Updated: 2026-03-04

## Scope

Tracks active Godot-runtime work after the architecture pivot.

## Current Runtime Baseline (Already Landed)

- Godot project boot and run (`custodian/project.godot`)
- Main scene scaffold (`custodian/scenes/game.tscn`)
- GameState autoload (`custodian/core/state/game_state.gd`)
- Fixed-step simulation loop + pause toggle (`custodian/core/systems/simulation.gd`)
- Embodied operator movement (WASD) (`custodian/entities/operator/operator.gd`)

## High Priority

1. Combat Core (`OPEN`)
- Implement ranged slot (hitscan baseline)
- Implement melee slot
- Implement utility slot interactions
- Add damage reception pipeline

2. Sector Runtime (`OPEN`)
- Build sector scene/layout contract
- Add sector traversal and collision boundaries
- Define ingress points for assaults

3. Assault Runtime (`OPEN`)
- Spawn logic and wave pacing
- Enemy movement/targeting baseline
- Structural damage propagation into GameState

4. Save/Load (`OPEN`)
- Serialize full run state
- Restore deterministic state mid-assault
- Version save format

## Medium Priority

5. Infrastructure Systems (`OPEN`)
- Power model
- Logistics throughput model
- Fabrication queue and outputs
- ARRN relay progression loop

6. UI Command Surfaces (`OPEN`)
- Pause-time systems management panel
- Tactical state and warning overlays

## Legacy Note

Terminal-era Python features remain preserved in `python-sim/` for reference.
No new primary gameplay implementation should target the legacy stack unless explicitly requested.
