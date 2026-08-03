# Authored Underlay Plate Pipeline

**Status:** implementation-ready  
**Runtime:** Godot 4.x  
**Source authority:** repository-level `art_source/` master  
**Runtime authority:** generated plate manifest and PNG plates

## Purpose

Support large continuous painted levels without loading one 8K–16K texture
as a single runtime resource.

## Contracts

- Source masters live outside the Godot project root.
- Runtime plates live under `custodian/content/`.
- Core size defaults to 2048 pixels.
- Bleed defaults to 16 pixels.
- Plate cores never overlap.
- Bleed pixels are sampled but are not duplicate world coverage.
- JSON owns source/world registration.
- Runtime plate scenes own presentation only.
- Collision, navigation, markers, interactions, occlusion, and state remain
  mapper/level authorities.

## Implementation files

```text
custodian/tools/content/slice_authored_underlay.py
custodian/game/world/presentation/authored_underlay_plate_loader.gd
custodian/tools/validation/authored_underlay_plate_pipeline_smoke.gd
```

## Determinism

The same source bytes and command arguments produce identical:

- grid ordering;
- filenames;
- manifest ordering;
- source core rectangles;
- world rectangles;
- visible plate pixels.

The manifest records source and output SHA-256 hashes.

## Streaming

The runtime loader compares each plate world rectangle with the active
Camera2D world view.

- preload margin controls early loading;
- unload margin is larger to prevent thrashing;
- the initial view can load synchronously;
- later loads are capped per refresh;
- missing camera fails visibly by loading all plates.

## Documentation drift follow-up

When adopted, update:

```text
custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/FILE_INDEX.md
custodian/docs/ai_context/VALIDATION_RECIPES.md
```

For every authored level, record its:

- source master;
- plate manifest;
- runtime plate scene;
- preview/mapper scene;
- world origin;
- units-per-pixel registration.
