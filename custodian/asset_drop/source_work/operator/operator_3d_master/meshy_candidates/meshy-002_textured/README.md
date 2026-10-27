# meshy-002 — textured imported Operator candidate (from `model(3).meshy`)

**Status: IMPORTED_REFERENCE_CANDIDATE — not approved, not canonical, not a runtime asset.**

- **Provenance:** user's own Meshy generation; the user's Meshy account was deleted and these export files are the only copies. User stated they obtained confirmation from Meshy that recovering them is permitted. `model(3).meshy` → GLB container via the user-supplied `scripts/reconstruct.py` (static-key AES-CTR prefix, auth tag not verified), then meshopt-decoded with `scripts/unmeshopt.mjs` (three.js decoder; Blender 5.2 on the dev box lacks its meshopt bridge). Hashes in `SHA256SUMS.txt`; the `.meshy` itself is not stored here.
- **Contents:** 1 mesh, 660,202 verts / 1,251,670 tris, ~1.90 m tall, UVMap present. Three embedded WebP textures: base colour 4096², metallic-roughness 2048², normal 4096², all with `KHR_texture_transform` (scale ~16). Unrigged, mid-stride pose, faces -Y.
- **`renders/`:** 8-direction renders (native 128 and 512) at the working 45°, 50 px/m projection, root (64,106), using the asset's own materials (`scripts/rend3.py`). Height not normalised to 84–88 px.
- Procedural `exp-001..008` and `meshy-001` are untouched. No select-best, no runtime/manifest change, no FPS claim. Still to do: rig/pose, decimation, height/ground normalisation, canonical-source comparison.
