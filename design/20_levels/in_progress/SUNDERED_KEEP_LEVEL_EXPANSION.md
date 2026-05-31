# Sundered Keep Level Expansion

Status: implemented first pass
Last updated: 2026-05-30

## Goals

- Replace the simple rectangular phase-1 chain with a readable haunted cliff-island castle layout.
- Add a diegetic Return Mooring near the entrance using live game32 runtime assets.
- Make the Main Gate portcullis start closed, block movement, and open only after the player acquires `sundered_gate_key`.
- Preserve connected-map entry, return travel, camera bounds, and smoke-test coverage.

## Implemented Route

The active route in `custodian/game/world/sundered_keep/sundered_keep_map.gd` is:

`Storm Causeway -> Gatehouse / Locked Main Gate -> Courtyard -> Great Hall -> East Rampart`

The map now also includes a west cliff service path, a lower gatehouse alcove, broken courtyard corners, a collapsed Great Hall side exposing ocean, and upper stair, lower stair, and hatch traversal stubs.

The current composition pass prioritizes silhouette and route logic over new assets: the ocean is a dark backdrop with sparse water tiles instead of a checker fill, the island is built from irregular row spans and larger sea cuts, large gothic facade runs are reserved for the gatehouse, temporary vertical wall roles resolve to rampart parapet slices, the storm causeway extends south to a walkable tip spawn with blocked submerged mainland continuation, and the Great Hall threshold is a closed/open double-door interaction rather than a free wall hole.

The causeway edge line uses `custodian/content/tiles/sundered_keep/entrance/entrance_causeway_edge_*.png` for cardinal and diagonal exposed borders. The southern submerged continuation uses `entrance_causeway_broken_gap_01` plus collision blockers so it reads as the old mainland route without becoming walkable.

For current visual review, `ContractWorldLoader.debug_start_near_sundered_keep_entrance` is enabled and places the Operator beside the main-map Sundered Keep travel gate after contract generation.

## Return Mooring

The Return Mooring is built from live assets under:

- `custodian/content/tiles/sundered_keep/return_mooring/`
- `custodian/content/props/sundered_keep/return_mooring/`
- `custodian/content/runtime/sundered_keep/return_mooring/return_mooring_module.game32.json`
- `custodian/content/metadata/game32/return_mooring.game32.json`

The module places a 3x3 mooring pad inside a 5x5 lower gatehouse alcove. The center tile owns the interaction target and calls the existing connected-map return behavior through `return_to_main(actor)`. The beacon and ruined console are visual landmarks with blockers; the mooring floor remains walkable.

## Gate Key Behavior

The Main Gate uses:

- `main_gate_portcullis_closed`
- `main_gate_portcullis_open`
- `sundered_gate_key`

The portcullis starts closed and has a four-tile `MainPortcullisBlocker`. Interacting without the key prints `Requires Sundered Gate Key. The portcullis winch is locked.` The key pickup is placed before the gate in the winch alcove and grants `sundered_gate_key` through `InventoryManager` when available, with a local fallback state kept inside the map script. Opening the gate swaps the closed/open portcullis sprites and queues the gate blocker for removal.

## Great Hall Door

The first interior threshold at the Great Hall uses `gothic_double_door_closed_n` and `gothic_double_door_open_n`. It starts closed with `GreatHallDoorBlocker`, exposes an `OPEN GREAT HALL DOOR` interaction, and removes only that blocker when opened. This keeps the courtyard-to-hall route readable while preserving the Main Gate key gate as the earlier required objective.

## Validation Commands

```bash
cd /home/braydenchaffee/Projects/CUSTODIAN

find custodian/content/tiles/sundered_keep/return_mooring -maxdepth 3 -type f | sort || true
find custodian/content/props/sundered_keep/return_mooring -maxdepth 2 -type f | sort || true
find custodian/content/runtime/sundered_keep/return_mooring -maxdepth 2 -type f | sort || true

cd custodian
godot --headless --script res://tools/validation/sundered_keep_asset_smoke.gd
godot --headless --script res://tools/validation/sundered_keep_layout_smoke.gd
```

## Future Work

- Persist Sundered Keep key/gate state across save/load and connected-map unloading.
- Disable `ContractWorldLoader.debug_start_near_sundered_keep_entrance` before normal contract progression review.
- Add encounter composition and combat pacing now that the courtyard loop and Great Hall choke points exist.
- Continue visual playtesting for cliff-edge readability and remaining rectangular wall/floor impressions.
- Decide whether to mirror the authored Sprite2D grammar into a TileSet/TileMapLayer workflow for easier long-term tile editing.
- Add final hand-authored art polish for collapsed edges, hazards, and multi-floor traversal.
