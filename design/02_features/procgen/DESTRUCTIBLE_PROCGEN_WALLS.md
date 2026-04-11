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

Top-exposed horizontal runs can also spawn ruined marble overlay strips sourced from `marble_ruined_walls_3x4_96x96.png`, using left-cap / repeatable-middle / right-cap composition at runtime, with taller collision on the exposed row.
Left/right-exposed vertical runs can reuse the same ruined sheet with rotated repeated segments so corridor walls and corner edges stay visually heavy.
Runtime wall collision can now expand to cover those taller exposed rows and side-clad faces instead of remaining a single puny tile box.
A runtime debug overlay can be enabled to inspect the actual generated collision boxes during tuning.

## Non-Goals

- melee wall destruction
- repairing breached procgen wall tiles
- structural collapse propagation
- authored weak-point logic

Those can be layered later if the feel is good.
