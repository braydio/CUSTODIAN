# Ruin Prop Variant System

This folder contains procedural assembly support for pixel-art ruin props. Variants are built from authored sprites, overlays, rubble pieces, stable collision scenes, and conservative palette shifts. The system does not generate new pixel art at runtime.

## Layout

```text
content/props/ruins/
  source/                 # original source sheets
  extracted/              # sliced, transparent, padded prop PNGs
  overlays/               # moss, cracks, chips, dirt, vines, highlights
  data/prop_definitions/  # PropDefinition .tres resources
  shaders/                # prop palette shader
  scenes/                 # reusable ProceduralProp scene
  scripts/                # resources and generator scripts
```

## Runtime Entry

- `scenes/ProceduralProp.tscn`
- `scripts/ProceduralProp.gd`
- `scripts/PropDefinition.gd`
- `scripts/PropVariantLayer.gd`
- `scripts/PropVariantGenerator.gd`
- `scripts/WeightedPropEntry.gd`
- `scripts/PropSpawnSet.gd`
- `scripts/PropScatterer.gd`
- `data/ruin_prop_spawn_set.tres`

`PropDefinition.collision_scene` is optional. For simple blockers, `PropDefinition` can also describe an authored collision footprint directly. Tall props can opt into player-relative depth sorting so they render behind the player when the player is in front of them.

The prop root is the floor/contact anchor. `BaseSprite` is centered at `-anchor_offset`, and `collision_shape_offset` is the blocker center in that same root-local space. A bottom-anchored floor prop should normally keep its collision bottom at local `y=0` (within a small tolerance); set `collision_allows_below_anchor` only for an intentional, documented exception. Use `ProceduralProp.get_collision_alignment_report()` or the procgen `ruin_prop_force_collision_debug` override to inspect an instance without changing its shared definition.

## Procgen Placement

`ProcGenTilemap` can spawn decorative ruin props from `data/ruin_prop_spawn_set.tres` into `NavigationRegion2D/PropLayer`.

Current placement rules:

- floor cells only
- avoids near-wall cells
- avoids the player spawn and compound buildings
- enforces minimum distance between placed props
- uses deterministic tile-based seeds
- keeps collision authored on the `PropDefinition`, not generated from visual variants
- can opt into simple inline collision footprints for runtime physics without a bespoke collision scene
- registers an inline blocker's generated global collision rectangle—not merely the spawn tile—in the runtime prop-blocker overlay; authored multi-shape scenes retain shape-by-shape footprints so intentional lanes stay open
- disables/unregisters collision when that complete footprint crosses a protected route, spawn, structure, story, or combat clear zone while allowing the visual prop to remain
- can opt into player-relative depth sorting for tall props

## Pixel Padding

For cropped PNGs, add transparent padding without changing the original pixels. Run from the folder containing the cropped PNGs.

Recommended default, 16 px on each side:

```bash
mkdir -p padded
magick mogrify -path padded -background none -gravity center -extent "%[fx:w+32]x%[fx:h+32]" *.png
```

If the local ImageMagick build rejects the expression form, use the equivalent transparent border command:

```bash
mkdir -p padded
magick mogrify -path padded -background none -bordercolor none -border 16x16 *.png
```

Smaller props, 8 px on each side:

```bash
mkdir -p padded
magick mogrify -path padded -background none -gravity center -extent "%[fx:w+16]x%[fx:h+16]" *.png
```

Large ruin props, 24 px on each side:

```bash
mkdir -p padded
magick mogrify -path padded -background none -gravity center -extent "%[fx:w+48]x%[fx:h+48]" *.png
```

After padding, prefer a consistent bottom-center anchor in each `PropDefinition.anchor_offset`.

The initial flat prop PNGs in this folder were copied into `extracted/` with 16 px transparent padding on each side. The original flat PNGs were left unchanged.

## Import Settings

Use pixel-art imports:

```text
Filter: Off
Mipmaps: Off
Repeat: Disabled
Compress: Lossless
```

Avoid arbitrary rotation, non-integer scaling, skewing, and smooth deformation. Use flips, authored overlays, authored rubble pieces, alpha variation, integer pixel offsets, and conservative shader tone shifts.
