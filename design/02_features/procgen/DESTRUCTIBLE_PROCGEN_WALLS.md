# Destructible Procgen Walls

**Project:** CUSTODIAN  
**Status:** In Progress  
**Created:** 2026-03-26

## Goal

Make procgen walls feel like real world geometry instead of permanent invisible blockers.

## Runtime Behavior

- Procgen wall tiles can take projectile damage.
- Each wall tile tracks its own health.
- When a wall tile is destroyed:
  - the wall tile is removed
  - a floor tile is restored at that location
  - nearby wall visuals are refreshed
  - runtime wall collision is rebuilt
  - navigation is rebuilt so AI can path through the breach

## Collision Model

Runtime procgen collision now uses one wall body per wall tile when destructible walls are enabled.

This is heavier than merged strip collision, but it allows:

- per-tile damage
- accurate projectile-to-wall hits
- small breaches instead of deleting whole wall runs

## Visual Source

Live procgen walls now use the `TX Tileset Wall` atlas source in `dungeon_tileset.tres` instead of the older placeholder dungeon low-wall source.

## Non-Goals

- melee wall destruction
- repairing breached procgen wall tiles
- structural collapse propagation
- authored weak-point logic

Those can be layered later if the feel is good.
