# Procedural Prop Variant System

Status: complete
Last updated: 2026-05-02

## Goal

Provide a Godot-native visual variant system for pixel-art ruin props without AI generation or runtime image synthesis.

The system composes variants from:

- one authored base sprite
- optional authored overlay sprites
- optional authored rubble sprites
- conservative shader palette shifts
- deterministic seeded placement
- optional stable collision scene authored separately from visuals

## Runtime Files

- `custodian/content/props/ruins/scenes/ProceduralProp.tscn`
- `custodian/content/props/ruins/scripts/ProceduralProp.gd`
- `custodian/content/props/ruins/scripts/PropDefinition.gd`
- `custodian/content/props/ruins/scripts/PropVariantLayer.gd`
- `custodian/content/props/ruins/scripts/PropVariantGenerator.gd`
- `custodian/content/props/ruins/shaders/prop_palette_variation.gdshader`
- `custodian/content/props/ruins/README.md`

## Behavior

`ProceduralProp` is a visual `Node2D` assembly scene. It uses a `PropDefinition` resource plus `variant_seed` to regenerate the same variant at the same seed. `VariantIntensity` exposes four visual states:

- `ORIGINAL`: base sprite only
- `SUBTLE`: small tone shifts and light detail
- `DRAMATIC`: stronger tone shifts and more overlays/rubble
- `RETURNED`: near-original palette with a few residual details

Collision is never generated from visual output. `PropDefinition.collision_scene` supplies an authored stable footprint when needed.

## Asset Rules

Source sheets should be sliced into transparent prop PNGs under `custodian/content/props/ruins/extracted/`. Overlay and rubble sprites should live under `custodian/content/props/ruins/overlays/`.

If extracted sprites were cropped without padding, add transparent padding before authoring definitions. The recommended default is 16 px on every side:

```bash
mkdir -p padded
magick mogrify -path padded -background none -gravity center -extent "%[fx:w+32]x%[fx:h+32]" *.png
```

For ImageMagick builds that reject the expression form, this equivalent command can be used:

```bash
mkdir -p padded
magick mogrify -path padded -background none -bordercolor none -border 16x16 *.png
```

Use bottom-center `anchor_offset` conventions for floor props after padding.

## Pixel-Art Constraints

- Use nearest-neighbor filtering.
- Do not use arbitrary runtime rotation.
- Do not use non-integer runtime scaling.
- Do not derive gameplay collision from decorative overlays or rubble.
- Keep hue shifts conservative; most visual difference should come from authored overlays and rubble recombination.
