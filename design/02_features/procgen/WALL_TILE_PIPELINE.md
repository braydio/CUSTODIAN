# Wall Tile Pipeline

Status: implementation-ready

## Purpose

Create an offline wall asset pipeline for the Godot runtime using the canonical authored source sheet at
`custodian/content/tiles/walls/source/procgen_wall_modules_source.png`.

The pipeline extracts separated wall modules from the source PNG, packs them into a clean atlas, emits JSON
metadata, and composes deterministic wall-run variants for later import into Godot as atlas/tile assets.

## Scope

In scope:

- Offline Python tooling under `tools/tiles/`.
- Generated wall assets under `custodian/assets/tiles/walls/generated/`.
- Alpha-island extraction from transparent PNG sources.
- Optional manual rectangle extraction when automatic detection is not appropriate.
- Deterministic variant composition using a seed.
- Godot import notes for pixel-art PNGs.

Out of scope:

- Runtime image generation.
- Gameplay code changes.
- Godot `TileSet` authoring automation.
- Destructive inference of individual bricks/stones from whole wall modules.

## Source And Outputs

Canonical input source:

- `custodian/content/tiles/walls/source/procgen_wall_modules_source.png`

Generated outputs:

- `custodian/assets/tiles/walls/generated/procgen_wall_source_parts/`
- `custodian/assets/tiles/walls/generated/procgen_wall_source_atlas.png`
- `custodian/assets/tiles/walls/generated/procgen_wall_source_parts.json`
- `custodian/assets/tiles/walls/generated/procgen_wall_composed_variants.png`

## Tools

| File | Role |
|------|------|
| `tools/tiles/extract_wall_parts.py` | Extracts wall modules, writes per-part PNGs, packs an atlas, and emits metadata. |
| `tools/tiles/compose_wall_variants.py` | Reads atlas metadata and composes deterministic wall-run variants. |
| `custodian/assets/tiles/walls/generated/README.md` | Documents how to regenerate and import outputs. |

## Extraction Behavior

`extract_wall_parts.py`:

1. Loads the source PNG as RGBA.
2. If `--rects` is supplied, extracts those explicit rectangles.
3. Otherwise detects connected non-transparent alpha islands using `alpha >= --alpha-threshold`.
4. Ignores tiny components below `--min-area` and records them in JSON.
5. Crops each kept island to its alpha bounding box.
6. Adds transparent padding around every extracted part.
7. Saves every part as an individual PNG.
8. Packs all parts into a simple shelf atlas.
9. Emits JSON metadata for each part.

Each part metadata object includes:

```json
{
  "id": "wall_part_000",
  "kind": "unclassified",
  "source_rect": [0, 0, 32, 32],
  "atlas_rect": [0, 0, 36, 36],
  "size_px": [36, 36],
  "size_tiles_guess": [1, 1],
  "tags": [],
  "anchor": "bottom_left"
}
```

## Classification Heuristics

Classification is intentionally conservative because the sheet contains whole wall modules, not atomic bricks.

- `width_tiles >= 5` and either `height_tiles <= 3` or the module is clearly wide (`aspect_ratio >= 1.7`): `long_straight`
- `width_tiles >= 3` and `width_tiles < 5`: `medium_straight`
- `width_tiles <= 2` and `height_tiles <= 3`: `short_straight`
- `height_tiles > width_tiles` and `width_tiles <= 2`: `vertical_end_or_pillar`
- square-ish and large: `corner_or_block`
- otherwise: `unclassified`

No detected part is discarded because it is unclassified.

## Composition Behavior

`compose_wall_variants.py`:

1. Loads metadata and atlas.
2. Builds horizontal wall-run variants.
3. Randomly chooses compatible left/middle/right modules using deterministic RNG from `--seed`.
4. Preserves bottom alignment for all pasted parts.
5. Keeps transparency.
6. Does not rescale or rotate artwork.
7. Packs composed variants into rows with 8 px transparent spacing by default.

Composition templates include:

- one long straight alone
- left cap + medium straight + right cap
- left cap + repeated short/medium middle + right cap
- long/medium run with an inserted damaged, moss, or rubble segment when such tagged/kind data exists

If no explicit cap pieces exist, the composer falls back to short/medium/vertical pieces and bottom-aligns them.

## Godot Import Notes

Generated PNGs should be imported as pixel art:

- filter off
- mipmaps off
- lossless compression
- no runtime scaling

Godot-side use should be a normal `TileSet` / atlas workflow. The generated atlas and metadata are intended to
support manual or future automated `TileSetAtlasSource` setup, not runtime image mutation.

## Documentation Drift Check

Checked paths:

- `custodian/content/tiles/walls/source/procgen_wall_modules_source.png` exists.
- `custodian/content/dev/in_progress/procgen_wall_tiles_source2.png` exists as the latest reviewed intake source and was copied to the canonical source path.
- `custodian/assets/tiles/` exists.
- `design/` exists.
- `custodian/docs/ai_context/` exists.
- `tools/tiles/` did not exist before this pipeline and is created by this implementation.
- `custodian/assets/tiles/walls/generated/` did not exist before this pipeline and is created by this implementation.
