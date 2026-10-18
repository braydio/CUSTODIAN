# COMPOUND_WALLED_YARD_BLOCKOUT Summary

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488

## What changed

Type A (`walled_yard`) now generates its own geometry (`walled_yard_close_packed_v1`) instead of
metadata over the legacy surface layout.

- **Planner**: runs the semantic room planner on the tightest placement area that still places
  every mandatory building, then adds exactly two perimeter gates (primary and secondary, on
  different edges), one stable yard-facing exterior doorway per building, a `perimeter` record and
  the yard contract (at least 22 percent open yard). It fails closed if any gate, doorway,
  building or anchor is unreachable from the gates. `legacy` and `connected_bunker` are unchanged.
- **Tilemap**: stamps the perimeter in the existing floor/wall layer and seals every ring wall
  cell that is not a gate, reusing the sealed-cell guard from the connected bunker work, so roads,
  routes and terrain cannot breach the boundary.
- **Export**: level data adds `compound_perimeter`, `compound_gates`,
  `compound_building_doorways`; the accepted-world export parity pin was repinned (80 keys).
- **Validation**: new `compound_walled_yard_smoke.gd` (planner contract on three compound sizes
  plus the real generator, seven seeds) registered as `compound_walled_yard`; the profile smoke now
  expects Type A to own its geometry.

## Evidence

All seven seeds pass on the real runtime: the only walkable ring cells are the two gate corridors,
each gate alone admits the outside, with both shut the interior is unreachable, and every
building, doorway and anchor is reachable. With the perimeter seal disabled the smoke fails
with about 1,750 breached ring cells, so the check is real.

## Notes

- Gate open/closed is verified as a physical crossing only; no gate state machine ships here.
- Parallel worktree reminder: switch back to your original branch after this task.
