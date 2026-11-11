# COMPOUND_CONNECTED_BUNKER_BLOCKOUT Summary

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488

## What changed

Type B (`connected_bunker`) now generates real layered geometry (`connected_bunker_subsurface_v1`)
instead of metadata over the legacy surface layout.

- **Planner** (`persistent_compound_layout_planner.gd`): splits the compound reservation into a
  surface band (yard plus two stable housings), a solid separator (2+ tiles), and a wall-filled
  subsurface region. All eight mandatory rooms sit on one 3-wide corridor spine with a compartment
  threshold cell per room; each housing is paired with a spine anchor through a reversible
  `vertical_entry` edge. The planner fails closed (`connected_bunker_bounds_too_small`,
  connectivity checks) and is deterministic per seed. `legacy` and `walled_yard` output is unchanged.
- **Tilemap** (`proc_gen_tilemap.gd`): stamps the layers through the single tile authority. Sealed
  cells (compound cells outside the surface band that are not planned underground floor) are
  refused by every floor writer; subsurface tiles are excluded from terrain-required cells; the
  generic constructed interior region is skipped for a layered compound.
- **Export / minimap**: level data adds `compound_layers`, `compound_surface_housings`,
  `compound_vertical_entries`, `compound_compartment_thresholds`, `compound_spine_cells`; the
  minimap projects both layers.
- **Validation**: new `compound_connected_bunker_smoke.gd` (planner contract on three compound
  sizes plus the real generator, seven seeds) registered as `compound_connected_bunker`; the
  profile smoke now expects Type B to own its topology.

## Evidence

All seven seeds pass on the real runtime: underground rooms are traversed over physical floor with
no room transfer, both housings reach the network and the outside, and no walkable cell crosses
the separator. Existing compound profile, layout, minimap and runtime smokes pass.

## Notes

- The first real-generator run exposed three stages writing floor through the separator (terrain
  reachability repair, route walkability enforcement, the generic interior region). All are fixed.
- A fresh worktree needs one Godot import before the compound smokes parse; the import leaves
  unrelated untracked `.uid` sidecars, which were removed rather than committed.
- Blocker logged (not this task): `agent-next-execution-boundary-v1-review-corrections-1` could not
  be claimed because `agent-workflow` is held by `agent-paired-review-godot-cache-access-v1`,
  claimed by another session right after the stranded review's claim was released.
- Parallel worktree reminder: switch back to your original branch after this task.
