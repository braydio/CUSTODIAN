# CUSTODIAN authored-underlay plate pipeline

This bundle turns one large authored source master into:

1. runtime PNG plates;
2. a deterministic JSON manifest;
3. a streamed Godot runtime scene;
4. a static all-plates editor-preview scene;
5. exact source/core pixel verification;
6. a Godot headless smoke test.

## Repository layout

```text
art_source/
└── underlays/
    └── sundered_keep/
        └── approach/
            └── sundered_keep_approach_master.png
                # 8K/10K/16K editable source, outside Godot project

custodian/
├── content/backgrounds/sundered_keep/approach/runtime/
│   ├── plates/
│   │   ├── sundered_keep_approach__p_000_000.png
│   │   └── ...
│   └── sundered_keep_approach.plates.json
├── game/world/presentation/
│   └── authored_underlay_plate_loader.gd
├── game/world/approaches/sundered_keep/generated/
│   └── sundered_keep_approach_underlay_runtime.tscn
├── scenes/debug/generated/
│   └── sundered_keep_approach_underlay_preview.tscn
└── tools/
    ├── content/slice_authored_underlay.py
    └── validation/authored_underlay_plate_pipeline_smoke.gd
```

## Why the master stays outside `custodian/`

Godot imports images under the project root. Keeping the 10K source in
`art_source/` prevents the working master from becoming a runtime import.
Only the 2048-pixel plates enter the Godot project.

## Install

```bash
python -m pip install -r requirements-authored-underlay.txt
chmod +x examples/build_sundered_keep_approach_underlay.sh
```

Copy the bundle's `custodian/` files into the repository's live
`custodian/` directory.

## Build Sundered Keep approach plates

```bash
./examples/build_sundered_keep_approach_underlay.sh
```

## Core plus bleed

Each grid cell owns a unique, non-overlapping 2048×2048 core. The exported
texture also contains 16 neighboring source pixels where available.

At runtime, `Sprite2D.region_rect` renders only the unique core. The bleed
exists so linear filtering samples neighboring art instead of transparent
black at a plate boundary.

This prevents:

- doubled alpha from overlapping sprites;
- seams caused by filtering against transparent borders;
- world-space overlap between adjacent plates.

## Manifest authority

The manifest records:

- source dimensions and SHA-256;
- source-to-world registration;
- runtime resource paths;
- source core rectangles;
- texture core rectangles;
- world rectangles;
- texture sizes and hashes;
- runtime and preview scene paths;
- streaming settings.

The large master remains **source authority**. The manifest and plates are
**runtime presentation authority**.

## Generated runtime scene

```text
AuthoredUnderlayPlateSet
└── PlateRoot
```

The loader creates and removes `Sprite2D` nodes based on the active Camera2D
view plus preload/unload margins.

The initial view loads synchronously by default so control is not returned
over a blank underlay.

If the loader cannot find a camera, it deliberately loads every plate rather
than fail invisibly.

## Generated preview scene

The preview scene explicitly contains every Sprite2D and texture resource.

Use it for:

- mapper alignment;
- collision authoring;
- marker placement;
- whole-master inspection.

Do not use the preview scene as the production runtime underlay.

## Instance the runtime plate set

The safest path is to instance the generated runtime `.tscn` in the authored
level scene below collision, gameplay props, actors, and foreground
occluders.

Programmatic example:

```gdscript
const APPROACH_PLATES := preload(
	"res://game/world/approaches/sundered_keep/generated/"
	+ "sundered_keep_approach_underlay_runtime.tscn"
)


func _build_authored_underlay() -> void:
	var plate_set := APPROACH_PLATES.instantiate()
	plate_set.name = "AuthoredUnderlayPlates"
	add_child(plate_set)
	move_child(plate_set, 0)
```

The plate set must not own:

- collision;
- navigation;
- markers;
- doors;
- interactables;
- objective state;
- encounter state.

Those remain mapper/level authorities.

## Import settings

For generated plate PNGs:

- compression: lossless;
- filter: linear;
- mipmaps: enabled;
- repeat: disabled;
- alpha border fix: enabled for transparent masters.

The loader requests `LINEAR_WITH_MIPMAPS`. Godot must also import the PNGs
with mipmaps enabled. Multi-select the generated plate folder in the Import
dock, enable mipmaps, then reimport. Because filenames remain stable, future
rebuilds retain those import sidecars/settings.

## Rebuild safety

`--clean` removes only stale files matching:

```text
<asset-id>__p_*.png
```

It does not delete unrelated art.

All text/JSON and PNG writes are atomic. The pipeline verifies every rendered
core against the master unless `--skip-pixel-verification` is passed.

## Verify an existing build

```bash
python custodian/tools/content/slice_authored_underlay.py \
  --source art_source/underlays/sundered_keep/approach/sundered_keep_approach_master.png \
  --repo-root . \
  --godot-root custodian \
  --asset-id sundered_keep_approach \
  --verify-only \
  --verify-manifest \
    custodian/content/backgrounds/sundered_keep/approach/runtime/sundered_keep_approach.plates.json
```

## Tests

```bash
python -m unittest \
  custodian/tools/content/tests/test_slice_authored_underlay.py

godot --headless \
  --path custodian \
  --script res://tools/validation/authored_underlay_plate_pipeline_smoke.gd \
  -- \
  --manifest=res://content/backgrounds/sundered_keep/approach/runtime/sundered_keep_approach.plates.json \
  --scene=res://game/world/approaches/sundered_keep/generated/sundered_keep_approach_underlay_runtime.tscn
```

## Production acceptance

- Existing source registration remains unchanged.
- Preview scene matches the source master.
- No visible plate seams at all supported camera zooms.
- Entry-region plates exist before gameplay control returns.
- Streaming never unloads a plate inside the larger keep margin.
- Reverse traversal reloads plates correctly.
- Plate scene has no collision/navigation descendants.
- Mapper collision, markers, occlusion, and gameplay remain separate.
