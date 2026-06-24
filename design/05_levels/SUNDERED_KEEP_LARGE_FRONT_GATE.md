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
- `custodian/game/world/sundered_keep/sundered_keep_map.gd` applies level ops to Sprite2D layers and keeps simulation/state behavior local to the map script.
- Return Mooring behavior remains diegetic return travel through existing connected-map return logic.
- The Main Gate still starts closed, checks `sundered_gate_key`, swaps closed/open portcullis sprites, and removes the portcullis collision blocker after opening.
- Side gatehouse blockers remain after the portcullis opens so the player cannot walk around the gate curtain.
- The Great Hall door remains a separate openable blocker.

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
