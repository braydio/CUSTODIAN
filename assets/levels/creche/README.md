# CUSTODIAN Creche room blockout kit

This kit contains **three user-provided room images**, the modular-asset contact sheet, an image-aligned **Blender construction script**, a dimensioned schematic, and exact instructions to give Claude.

## Start here

Open `docs/CLAUDE_BUILD_SPEC.md`. It specifies what Claude should inspect, which commands to execute, and how to verify outputs.

The supplied script is syntactically checked but has not been run in Blender in this environment. The first Claude run must validate or fix any Blender-version-specific runtime errors.

Check references first: `python scripts/check_reference_dimensions.py`.

With Blender installed:

```bash
blender --background --factory-startup --python scripts/build_creche_blockout.py
```

Results appear under `build/`.

## Scale

960×704 source pixels; 32 px/m; 26×13 m interior floor; 27.5×14.5 m outer footprint; 0.75 m walls; 5.25 m design wall height; south exit 1.75 m wide. Physical heights/depths are authoring assumptions, not recoverable metric observations from the images.

## Caution

Includes collision proxy and reserved art sockets, **not** fully populated asset GLBs or an integrated engine level. Claude must inspect the actual game project to select correct integration steps. The source floor/wall layers are approximate segmented projections, not a metrically consistent photogrammetry scan.

Then verify with Blender: `blender --background build/creche_blockout.blend --python scripts/verify_creche_scene.py`.
