# Sundered Keep Large Front Gate

Status: implemented first pass
Last updated: 2026-07-26

## Goal

Move the active Sundered Keep front-gate slice out of hard-coded rectangular map composition and into a larger data-driven level source while preserving the existing connected-map interaction behavior.

## Implemented Route

The active level data lives at:

- `custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json`

The runtime map now builds a `112x80` front-gate layout:

```text
storm ocean
-> broken southern approach platform
-> long irregular causeway with explicit edge overlays
-> outer landing
-> west Return Mooring alcove / east key-winch alcove
-> barbican and locked Main Gate
-> vestibule
-> irregular courtyard
-> Great Hall front, west service stub, east rampart branch
```

## Runtime Behavior

- `custodian/game/world/sundered_keep/sundered_keep_tilemap_loader.gd` loads `custodian.sundered_keep.level_tilemap.v1` JSON.
- `custodian/game/world/sundered_keep/sundered_keep_map.gd` applies level ops to Sprite2D layers, supports a top-level `underlay` world-space image contract, and keeps simulation/state behavior local to the map script.
- Return Mooring behavior remains diegetic return travel through existing connected-map return logic.
- The Main Gate still starts closed, checks `sundered_gate_key`, swaps closed/open portcullis sprites, and removes the portcullis collision blocker after opening.
- Side gatehouse blockers remain after the portcullis opens so the player cannot walk around the gate curtain.
- The Great Hall door remains a separate openable blocker.

## Underlay Contract

The active front-gate JSON may declare:

- `underlay.texture_path`
- `underlay.rect_tiles`
- optional `underlay.z_index`
- optional `underlay.modulate`
- optional `underlay.expand_camera_bounds`

The image remains presentation-only and never generates collision from alpha.
Reviewed manual rails now provide the corresponding static-boundary authority.

The playable underlay debug scene now supports explicit mapped boundary rails for manual review:

- scene: `custodian/scenes/debug/sundered_keep_production_underlay_debug.tscn`
- mapper: `custodian/scenes/debug/sundered_keep_underlay_collision_mapper.tscn`
- canonical data: `custodian/content/levels/sundered_keep/sundered_keep_underlay_collision.json`

`sundered_keep_underlay_collision.json` is the canonical static-boundary source
shared by the mapper, debug review scene, and production `SunderedKeepMap`.
Its capsule rails own permanent exterior walls, cliff edges, inaccessible art
masses, the walkable silhouette, and permanent route boundaries. Dynamic gate,
door, prop, encounter, and temporary-state blockers remain separate; the old
per-tile rectangular wall blockers are suppressed when mapped rails are active.

The same JSON owns reviewed placement markers for spawn, Vista backtrack,
gatehouse key, Main Gate, approved forward progression, and the first two siege
spawn lanes. Runtime marker diamonds and labels remain debug-only.

## Underlay Gameplay Tile Mapper

The collision-underlay pair now has a separate gameplay-tile authoring scene:

- scene: `custodian/scenes/debug/sundered_keep_underlay_gameplay_tile_mapper.tscn`
- mapping data: `custodian/content/levels/sundered_keep/sundered_keep_underlay_gameplay_tiles.json`
- validation: `custodian/tools/validation/sundered_keep_underlay_gameplay_tile_mapper_smoke.gd`

The mapper instantiates the same reviewed underlay debug scene and its 127
canonical collision rails. It does not reuse the current Front Gate gameplay
layout. Instead, it provides a blank adjacent staging area containing a stable
`01–99` palette of live Sundered Keep floor, wall, gate, door, and stair assets.
The palette is arranged as an `11x9` review grid. A second paint source can
drag-sample any rectangular set of visible underlay cells and reuse that region
as a multi-cell stamp without cropping or exporting a PNG.

The reviewed source region is `5048×3500` pixels mapped across the `112×80`
gameplay grid. Source rectangles therefore use fractional source-cell sizes
(`5048/112` by `3500/80`) and are rendered with `Sprite2D.region_rect`, scaled
back onto the 32 px gameplay grid. The imported PNG also contains unused pixels
below this reviewed region; those pixels are not underlay-stamp authority.

Authoring controls:

- `P`: focus the numbered palette
- `F`: focus the complete underlay
- `Q`: toggle underlay source-selection mode
- left-drag the underlay in source-selection mode: load that region as the
  active underlay stamp and return directly to placement mode
- `Tab`: switch active paint source between palette tile and underlay stamp
- left-click a palette cell: select its numbered asset
- left-click the underlay: place the active palette tile or underlay stamp on
  the shared `32 px` grid
- `Shift` + left-drag: repeat the active source across every crossed grid cell
- right-click the underlay: remove the top placement covering that cell
- `Ctrl+Z`: undo the last logical edit
- `Ctrl+Y` or `Ctrl+Shift+Z`: redo the last undone edit
- `G`: toggle the underlay grid
- `E`: toggle canonical collision rails
- `T`: toggle placed gameplay tiles
- `C`: copy the complete mapping document
- `Enter` or `U`: write the mapping JSON
- `F6`, `L`, or `R`: reload the saved mapping without restarting the scene
- `Delete`: clear placements as one undoable edit

Floor and architecture/traversal placements use separate replacement lanes, so
a floor and a wall module may intentionally share one grid cell. Explicitly
saving the mapping makes its visual/floor-authoring placements available to the
Front Gate consumer; unsaved previews remain mapper-local. The underlay PNG
still never generates collision, and the gameplay-tile mapping never modifies
the canonical collision JSON. The mapper retains up to 100 complete placement
snapshots; a repeated drag and a reload each consume one undo state, not one
state per crossed cell.

## Overlay Authoring Pipeline

The master overlay now also has a deterministic authoring-guide pipeline:

- generator: `custodian/tools/levels/generate_sundered_keep_overlay_authoring.py`
- generated guide: `custodian/content/levels/sundered_keep/sundered_keep_overlay_authoring.json`
- review scene: `custodian/scenes/debug/sundered_keep_overlay_authoring_review.tscn`

The generator reads the overlay alpha, samples it into the authored tile grid, and emits:

- suggested floor footprint spans/rects
- suggested border-void spans/rects
- suggested enclosed-void spans/rects
- a centroid anchor for the main keep mass

This remains authoring guidance, not direct gameplay authority. Designers can use it to reshape floor fills, blocker coverage, elevation bands, and route grammar so the playable layout follows the master silhouette more closely without letting decorative pixels own collision.

## Review Workflow

From the repository root:

```bash
python custodian/tools/levels/generate_sundered_keep_overlay_authoring.py
cd custodian
godot scenes/debug/sundered_keep_overlay_authoring_review.tscn
```

The review scene draws:

- green: suggested solid footprint
- red: edge-connected void outside the keep mass
- yellow: enclosed void pockets

Use this scene to compare the authored live map against the master silhouette before changing blockers, floors, or elevation metadata.

## Asset Rules

No placeholder assets were generated for this pass. The layout references live Sundered Keep game32/runtime PNG assets from:

- `custodian/content/runtime/sundered_keep/`
- `custodian/content/tiles/sundered_keep/`
- `custodian/content/tiles/sundered_keep/entrance/`
- `custodian/content/tiles/sundered_keep/walls/gatehouse/`
- `custodian/content/tiles/sundered_keep/return_mooring/`
- `custodian/content/props/sundered_keep/return_mooring/`

## Validation

Run from the repository root:

```bash
cd custodian
godot --headless --script res://tools/validation/sundered_keep_asset_smoke.gd
godot --headless --script res://tools/validation/sundered_keep_layout_smoke.gd
godot --headless --script res://tools/validation/sundered_keep_large_layout_smoke.gd
godot --headless --script res://tools/validation/sundered_keep_underlay_collision_mapper_smoke.gd
godot --headless --script res://tools/validation/sundered_keep_underlay_gameplay_tile_mapper_smoke.gd
```

Also useful after manifest changes:

```bash
python - <<'PY'
from pathlib import Path
import json
for manifest in [
    Path("custodian/content/sundered_keep_manifest.game32.json"),
    Path("custodian/content/metadata/game32/sundered_keep.game32.json"),
    Path("custodian/content/metadata/game32/return_mooring.game32.json"),
]:
    if not manifest.exists():
        continue
    data = json.loads(manifest.read_text())
    refs = []
    def walk(obj):
        if isinstance(obj, dict):
            for k, v in obj.items():
                if k in {"path", "runtime_path", "metadata_path", "manifest", "domain_home", "master_sheet_path"} and isinstance(v, str):
                    refs.append(v)
                walk(v)
        elif isinstance(obj, list):
            for item in obj:
                walk(item)
    walk(data)
    missing = []
    for ref in sorted(set(refs)):
        if ref.startswith("res://"):
            disk = Path("custodian") / ref.removeprefix("res://")
            if ref.endswith((".json", ".tres", ".gd", ".png")) and not disk.exists():
                missing.append((ref, disk))
    print(f"{manifest}: missing file refs={len(missing)}")
PY
```

## Future Work

- Persist `sundered_gate_key`, Main Gate open state, and Great Hall door state if connected maps become save/load persistent.
- Add encounter composition and tactical cover review after the layout stabilizes visually.
- Visually approve and curate the saved palette/stamp composition before
  treating it as production Front Gate dressing.
- Consider a dedicated TileSet/TileMapLayer runtime adapter if the reviewed
  JSON/Sprite2D mapping becomes difficult to maintain.
- Keep `ContractWorldLoader.debug_start_near_sundered_keep_entrance` disabled for normal contract progression; re-enable it only for focused Sundered Keep visual review.

## Next Agent Slice

Goal: use palette tiles and sampled underlay-region stamps to author and
visually approve the gameplay composition against the fixed underlay/collision
pair.

Files:

- `custodian/scenes/debug/sundered_keep_underlay_gameplay_tile_mapper.tscn`
- `custodian/content/levels/sundered_keep/sundered_keep_underlay_gameplay_tiles.json`
- `custodian/content/levels/sundered_keep/sundered_keep_underlay_collision.json`

Constraints:

- Keep the underlay and canonical collision rails fixed during tile review.
- Refer to palette assets by their stable `01–99` numbers.
- Keep sampled stamps as source-cell rectangles; do not crop or export new PNGs.
- Saved placements are consumed as visual/floor-authoring sprites only and must
  not create collision, blockers, navigation, or elevation authority.

Acceptance:

- the complete mapped gameplay tile composition follows the underlay silhouette
- placed floor/wall/traversal modules remain aligned to the shared 32 px grid
- debug and production collision remain shape-for-shape identical
