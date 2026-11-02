# Operator South 2D Blender Rig

This folder builds an **unapproved, source-work-only** Blender cutout candidate
from the landed `operator_south_visible_surface_v1` bundle. It does not add
runtime animation, approve the art, infer hidden surfaces, or import anything
into Asset V2.

## Build and render

Run from the repository root with Blender 5.2 or a compatible Blender CLI and
Pillow available to the host Python:

```bash
python3 custodian/tools/validation/operator_motion_foundry_blender_2d_smoke.py
```

The smoke builds and packs
`custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1/blender/operator_south_cutout_rig_v1.blend`,
renders 15 frames twice, checks the neutral render against the pinned source,
and stores normalized proof under
`.ai/operator_motion_foundry/blender/south_idle_v1/`.

The generated `.blend` has 23 named part bones, 18 image planes using the exact
source cells, and five empty guide controls. Plane textures are packed in the
file. Each plane is a full registered 128×128 cell weighted to its declared
part bone; the source manifest supplies pivots, parent links, and draw order.
The preview only keys a restrained upper-arm motion. The legs/root stay fixed;
frame 1 and frame 15 reset to the neutral source pose. Preview playback uses
12 fps, while canonical authored FPS remains `null`.

Blender renders 16-bit RGBA PNGs using EEVEE, orthographic registration,
nearest texture sampling, a binary-alpha threshold, transparent film, and one
render sample. The smoke converts those files to normalized 8-bit RGBA for
pixel-exact source comparison and compact review. The bit-depth normalization
avoids one-level 8-bit shader-output rounding while retaining the actual
Blender-rendered alpha, pose, and registered image data.

Outputs:

- `source_work/.../blender/operator_south_cutout_rig_v1.blend` — editable,
  packed Blender candidate.
- `source_work/.../blender/rig_build_receipt.json` — source identities, rig
  structure, Blender version, and measured neutral proof.
- `.ai/operator_motion_foundry/blender/south_idle_v1/` — normalized neutral,
  15 frames, 1920×128 preview strip, hashes, and proof report. This folder is
  ignored and is review evidence, not a runtime asset.

## Manual inspection

Open the `.blend`, select `Operator South • Cutout Controls`, and enter Pose
Mode to inspect the named part controls. Use frame 1 for neutral, frames 1–15
for the preview, and frame 1 again to reset. The armature and planes are
editable; source PNGs and original source-work are immutable inputs.

The cutouts contain no hidden underpaint. Any exposed joint gaps, missing
underlaps, or subjective idle-quality concerns remain human art-review items.
This engineering proof does not authorize runtime use, source approval, MF1/MF2
acceptance, or Operator 2.5D art promotion.
