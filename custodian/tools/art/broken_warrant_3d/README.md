# Broken Warrant 3D material master

This source-only tool rebuilds the 503-mesh Broken Warrant GLB with deterministic semantic Blender materials, a rigid 15-bone pose rig, and fixed orthographic pixel proofs. It never projects full-character illustration fragments onto the model and does not modify the source GLB or reference image.

The staged immutable inputs and generated editable master/reports live under `custodian/asset_drop/source_work/actors/broken_warrant_playable_knight_3d/`. That directory is local source-work evidence and is not runtime art or Asset V2 intake. The imported GLB's axis adapter is deliberately retained in each mesh's world transform: source Z-up is represented by Blender import as world -Y, so the rig and cameras are authored against that measured intermediate frame. Mesh vertex data and world transforms are fingerprinted before/after material assignment.

Run from the repository root with Blender 5.2+ available on `PATH`:

```bash
python3 custodian/tools/art/broken_warrant_3d/test_surface_contract.py
blender --background --factory-startup --python custodian/tools/art/broken_warrant_3d/build_materials.py
blender --background --factory-startup --python custodian/tools/art/broken_warrant_3d/validate_materials.py
blender --background --factory-startup --python custodian/tools/art/broken_warrant_3d/render_pixel_proof.py
python3 custodian/tools/art/broken_warrant_3d/assemble_pixel_proof.py
```

Builder and Blender scripts also accept `--` followed by argparse options such as `--source`, `--reference`, `--palette`, `--output`, `--blend`, and `--output`. The assembler accepts `--proof-dir`. `material_palette.json` and `surface_contract.py` are the shared semantic assignment authority. The builder saves a packed, editable `.blend`; the renderer uses reversible in-memory LOD visibility and masks and never saves changes to that master.

The renderer strips Blender timestamp, file-path and render-time PNG chunks after saving; repeated renders are byte-identical while pixel content remains unchanged. The current pixel profile is 128×128 RGBA, root `(64,106)`, ground line `Y107`, fixed orthographic scale `5.0`, native and 4× output, then explicit Pillow nearest-neighbor reduction. The generated review bundle is exactly three views and one comparison sheet. Technical JSON reports remain local beside the proof PNGs. Human material/identity acceptance is still pending; the work is not production art and is not promoted to runtime.
