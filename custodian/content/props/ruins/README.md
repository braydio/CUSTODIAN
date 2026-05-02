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

`PropDefinition.collision_scene` is optional, but collision should be authored separately and kept stable across visual variants.

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
