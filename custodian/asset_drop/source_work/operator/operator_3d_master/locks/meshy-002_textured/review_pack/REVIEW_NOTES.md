# meshy-002 textured — review notes (FROZEN_FOR_REVIEW_NOT_APPROVED)

Not approved, not selected, no runtime use. Every image is rendered from the imported textured GLB (no concept art, no painting, no edits).

**Model:** Meshy generation, user-reported permission (account deleted; only copies). decoded GLB sha256 `b9c2f68dfaa555e259a38b504698cfb44d86272683fea274ed03e948c6f33ad6`; container `e418978c13199b3f96c79388d27b4357fd821cf6665eaece5f0b7229fa5c1bf7`; original `.meshy` sha256 `c7994d921c68be74e5b222ebf2f4ee4d4595d64db2df56e1a42ea6d1a838a08e` (file itself not retained in repo). `.meshy` auth tag was NOT verified.
**Mesh:** 660,202 verts (625,807 position-welded) / 1,251,670 tris; 0 boundary edges, 27 non-manifold edges, 12 degenerate tris; UVMap; base colour 4096² (sRGB), metallic-roughness 2048² (Non-Color), normal 4096² (Non-Color); KHR_texture_transform became Mapping nodes (scale ~16); no extension ignored.
**Render contract:** Blender 5.2.3, EEVEE, view transform **AgX** (default, look None), orthographic 45° above horizon, 50 px/m (ortho 2.56), root (64,106), azimuths N 180 NE -135 E -90 SE -45 S 0 SW 45 W 90 NW 135 (unmirrored), one uniform scale x1.10542 (S-view fit to 85 px; other directions 85–91 px), sun 3.0 W/m² + world .45 grey strength .8. 128 px frames are native renders (filter 0); 512 frames are independent renders. Eye-level/detail/material/geometry frames use the same model, scale and lighting with different cameras (ortho 2.4 m eye-level; detail crops 20° elevation).
**Known mismatches (not hidden):** mid-stride pose (feet apart) vs the canonical idle; AgX view transform desaturates the gold vs the canonical sprites (material_proof shows Standard for comparison); IoU 0.668 vs exp-008 0.610 is not an equalised score; no rig, no retopology (1.25M tris), scale fit from the S view only.

**Questions for the reviewer (judgment is yours, not the agent's):**
a. Does the hood peak/crown/visible neck match the Operator better than exp-008?
b. Are the gold trim and dark armour material faithful at native 128 px?
c. Are pauldrons, tabard, feet and back silhouette coherent in all eight directions?
d. Is the mid-stride pose the main blocker to making this an idle master?
e. Is meshy-002 a better modeling base than the procedural build?
