# Scene Hierarchy Specification

Last updated: 2026-03-12

Scale contract reference: `res://docs/WORLD_SCALE_CONTRACT.md`

## Active Main Scene

`res://scenes/game.tscn`

## Current Structure

- `GameRoot` (`Node2D`)
- `World` (`Node2D`)
- `World/Sectors` (`Node2D`)
- `World/Enemies`
- `World/SpawnNodes/*`
- `World/Projectiles`
- `World/Items`
- `World/ContractMap` (instance: `res://game/world/procgen/custodian_contract_map.tscn`)
- `World/ProcGenRuntime` (created at runtime by `ContractWorldLoader`)
- `World/LevelLoader` (persistent authored-level staging/activation service)
- `World/RouteTraversalManager` (persistent directed-route/session authority)
- `World/Operator`
- `World/CommandTerminal` (instance: `res://game/actors/terminal/command_terminal.tscn`)
- `World/Camera2D`
- `Simulation`
- `Combat`
- `Power`
- `WaveManager`
- `EnemyDirector`
- `SupplyDropManager`
- `ContractWorldLoader`
- `UI`
- `UI/TerminalPanel`

## Runtime Ownership

- `World/ContractMap` owns contract generation and procgen map instantiation.
- `ContractWorldLoader` owns promotion of the generated map into visible runtime world space.
- `World/ProcGenRuntime` becomes the active traversed map container once contract generation completes.
- `World/Sectors` currently remains as compatibility/runtime-support content and is hidden/deactivated during procgen play.
- Direct base-world gameplay and presentation children use the `world_origin_branch` group. `WorldIngressSite` captures every grouped direct child of `World`, hides and processing-disables that exact set for the full authored-route session, and restores each branch's captured state only on route exfil.
- Dynamically created `World/ProcGenRuntime` containers are always classified by `ContractWorldLoader`; `ConnectedMaps` remains a compatibility lookup until that retired container is removed.
- `World/Operator`, `World/Camera2D`, shared lighting, `World/LevelLoader`, and `World/RouteTraversalManager` are intentionally outside `world_origin_branch` and remain active while Vista, Return Causeway, or Front Gate owns the route presentation.
- Authored route instances are staged as temporary direct `World` children but are never classified as origin branches or pre-authored into `game.tscn`.

## Interaction Surfaces

- In-world command terminal prop is currently placed directly under `World`, not under a command sector subtree.
- Operator consumes `interactable` group membership for proximity-based interaction prompts and `G` input handling.

## Expansion Targets

Near-term changes should preserve this split:

- Procgen-authored compound structures promoted into dedicated runtime containers
- Enemy ingress/spawn containers still under `World`
- UI-only presentation remains under `UI`
- Static compatibility content isolated from authoritative runtime geometry
