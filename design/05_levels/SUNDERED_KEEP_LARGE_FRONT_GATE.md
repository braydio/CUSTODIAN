# Sundered Keep Large Front Gate

Status: implemented first pass
Last updated: 2026-05-30

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

This is presentation-only. It gives the level a silhouette plate and shape anchor beneath the authored tile/prop layers, but it does not own collision, traversal, blockers, interactables, or elevation authority.

The playable underlay debug scene now supports explicit mapped boundary rails for manual review:

- scene: `custodian/scenes/debug/sundered_keep_production_underlay_debug.tscn`
- mapper: `custodian/scenes/debug/sundered_keep_underlay_collision_mapper.tscn`
- runtime data home: `UNDERLAY_BOUNDARY_SEGMENTS` in `sundered_keep_production_underlay_debug.gd`

These rails are authored line segments over the underlay in world space. They are not generated from alpha and should remain review/debug collision until promoted deliberately into the final `SunderedKeepMap` layout data.

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
- Consider a dedicated TileSet/TileMapLayer authoring path if the JSON/Sprite2D level data becomes difficult to inspect or edit.
- Keep `ContractWorldLoader.debug_start_near_sundered_keep_entrance` disabled for normal contract progression; re-enable it only for focused Sundered Keep visual review.

## Next Agent Slice

Goal: consume the generated overlay-authoring guide to tighten authored floor/blocker/elevation data where the live front gate still drifts from the master silhouette.

Files:

- `custodian/content/levels/sundered_keep/sundered_keep_overlay_authoring.json`
- `custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json`
- `custodian/game/world/sundered_keep/sundered_keep_map.gd`

Constraints:

- Keep overlay-derived data advisory until a reviewed authored change is accepted.
- Do not let the PNG directly own collision, traversal, interactables, or elevation.
- Prefer deterministic JSON edits and focused smokes over ad hoc scene-only tweaks.

Acceptance:

- any consumed overlay-derived edits remain visible in the review scene
- Sundered Keep smokes still pass
- docs/context stay aligned with the chosen authoring contract
