# Persistent World History

Status: candidate
Category: world
Priority: P0
Maturity: system
Cost: high
Owner: Brayden
Last reviewed: 2026-07-08

## One-line pitch

The world records meaningful events and uses them to make locations remember what happened.

## Problem it solves

Rooms that reset feel fake. CUSTODIAN needs places that accumulate history.

## Why it fits CUSTODIAN

The game is about ruins, memory, return, loss, and maintenance. Persistent history makes the world feel wounded and remembered.

## Player-facing effect

Returning to a room may show dried blood, broken doors, looted containers, repaired machinery, enemy remains, power changes, or terminal logs.

## Systems touched

Save/load, combat, death, repair, loot, terminals, sector state, environmental storytelling.

## Dependencies

World State Graph for some events. Save/load for persistence.

## Risks

Can create save bloat. Must separate important history from disposable noise.

## Minimal version

Record sector events: player death, enemy killed, repair completed, container looted, door opened.

## Full version

World Autopsy terminals reconstruct local events from actual simulation history.

## Graduation criteria

Graduate when revisiting locations should visibly reflect previous player actions.

## Notes / references

Related: World Autopsy, World State Graph, Sector Heatmap, Developer Observatory.

Active implementation authority: `design/01_systems/WORLD_HISTORY_SYSTEM.md` and `custodian/docs/ai_context/CURRENT_STATE.md`.

