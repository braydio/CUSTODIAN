# COMPOUND_CONNECTED_BUNKER_BLOCKOUT_REVIEW_CORRECTIONS_1 Summary

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488

## What changed

Corrects R0-01 and R0-02 from the fresh different-agent review of the connected bunker.

- **R0-01 (transfer):** new `CompoundVerticalEntryController`, attached by `ProcGenTilemap` to a
  layered compound. Standing on a housing threshold moves the operator to its paired underground
  anchor and back, reversibly, with a lockout until the operator leaves the arrival tile. The
  active layer is derived from position, so `ProcGenTilemap` remains the only layer authority.
  The camera's authored bounds are set to the underground content and restored on return.
  New tilemap accessors: `get_compound_vertical_entries`, `get_compound_layer_at_tile`,
  `get_compound_layer_world_bounds`.
- **R0-02 (evidence):** `compound_connected_bunker_smoke.gd` now, on seeds 1 and 42, enables real
  wall collision (physics point queries), builds the project's real `NavigationSystem` graph,
  traverses both entries in both directions with the real `CameraController`, and asserts the
  camera bounds never intersect the surface and are restored.

## Evidence

The smoke passes for all seven seeds plus the physical subset. Two negative controls fail it:
removing the controller attachment (the original R0-01 gap), and removing the sealed-cell guard
(separator and navigation leaks, collision failures).

## Notes

- The scene `NavigationRegion2D` bakes to an empty polygon; the real navigation authority is
  `NavigationSystem`, which is what the smoke uses.
- Parallel worktree reminder: switch back to your original branch after this task.
