# World State Graph

Status: candidate
Category: world
Priority: P0
Maturity: system
Cost: high
Owner: Brayden
Last reviewed: 2026-07-20
Runtime: live — `custodian/game/systems/world/world_state_graph.gd`

## One-line pitch

A dependency graph where repairs, power, doors, terminals, lights, turrets, elevators, and enemy routes react to one another.

## Problem it solves

World changes should not be isolated booleans. Repairing one thing should alter a larger system.

## Why it fits CUSTODIAN

The player is not just completing quests. The player is restoring dead infrastructure.

## Player-facing effect

Repairing a generator can restore lights, unlock a terminal, open a gate, disable hostile turrets, or wake dormant machines.

## Systems touched

Repair gameplay, terminals, gates, doors, lighting, turrets, enemy objectives, sector state, save/load.

## Dependencies

Repair interaction system. Save/load eventually.

## Risks

Can become tangled if every object directly depends on every other object. Needs clear naming and dependency rules.

## Minimal version

Global state registry with named keys and dependency evaluation.

## Full version

Visual graph editor/debug view, save/load integration, sector-local state graphs, cascading state changes, world autopsy integration.

## Graduation criteria

Graduate when repair gameplay needs to affect more than one object or sector.

## Notes / references

Related: Repair Gameplay System, Terminal System, Persistent World History, Developer Observatory.

Active implementation authority: `design/01_systems/WORLD_STATE_GRAPH_SYSTEM.md` and `custodian/docs/ai_context/CURRENT_STATE.md`.

