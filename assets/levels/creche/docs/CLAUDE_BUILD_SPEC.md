# CLAUDE EXECUTION HANDOFF: CUSTODIAN / Nameless_Creche room

## Mandate
Build the complete, editable architectural **blockout** for the Nameless_Creche room based on the three supplied images, and prepare labeled insertion sockets for the fourteen extracted modular architectural source images/GLBs. Run every specified command and fix failures rather than claiming success based on script existence. Do not silently change the chosen scale, wall sizes, gameplay openings, image UV layout, or source orientation. Do not assume all AI-derived GLBs have consistent size, topology, UVs, or color. Inspect the actual existing game repository before deciding on an engine-specific integration. **Do not push, deploy, overwrite existing levels, delete files, or change main** without approval.

## Evidence hierarchy
- **Directly established from supplied artwork:** full composite is 1464x1074 px. Floor and extracted wall layers are both 960x704 px with shared coordinates. Wall-layer coverage places the north facade footprint around source Y=200..225, the west/east inner perimeter near X=64/X=896, south facade near Y=620..660, four north pilaster groups centered approximately at X=164, 348, 608, 792, four south pilasters centered at X=180, 358, 602, 779. The opening near bottom center spans about X=453..507 pixels in the wall layer. Windows/alcoves are visually clear, but these images **do not encode true 3D height or depth**.
- **Fixed authoring choices for a reproducible blockout:** exactly **32 px per Blender meter**, 5.25 m walls, 0.75 m wall thickness, 3.45 m opening clear height, 2.70 m rectangular window clear heights. These are not factual measurements extracted from illustration. Treat them as editable design decisions, not claims of architectural ground truth.

## Output organization
Extract the supplied kit as `assets/levels/creche/` within the CUSTODIAN repository. Preserve these files:

```text
assets/levels/creche/
  references/
    creche_complete_1464x1074.png
    creche_floor_960x704.png
    creche_walls_960x704.png
    modular_14_contact_sheet.png
  docs/
    CLAUDE_BUILD_SPEC.md
    creche_blockout_plan.png
  scripts/
    build_creche_blockout.py
  build/  (generated)
    creche_blockout.blend
    creche_blockout.glb
    creche_blockout_topdown.png
    creche_manifest.json
    creche_build.log
```

## Required commands, in order

**On Arch Linux (from a terminal with the CUSTODIAN repo checked out):**

```bash
set -euo pipefail
pwd
git rev-parse --show-toplevel
git status --short --branch
find . -maxdepth 3 \( -name 'project.godot' -o -name 'package.json' -o -name '*.uproject' -o -name '*.unity' -o -name 'Cargo.toml' \) -print | head -60
command -v blender || { echo 'Blender missing. Ask permission before installing system software.'; exit 1; }
blender --version | head -3
```

**After the user-provided `creche_level_blockout_kit.zip` has been placed in the current working directory** (adjust the ZIP path explicitly if elsewhere):

```bash
mkdir -p assets/levels/creche
unzip -n creche_level_blockout_kit.zip -d assets/levels/creche
python assets/levels/creche/scripts/check_reference_dimensions.py
python -m py_compile assets/levels/creche/scripts/build_creche_blockout.py
blender --background --factory-startup --python assets/levels/creche/scripts/build_creche_blockout.py \
  2>&1 | tee assets/levels/creche/build/creche_build.log
```

**Check the actual artifacts; do not treat a zero exit as sufficient:**

```bash
for file in \
  assets/levels/creche/build/creche_blockout.blend \
  assets/levels/creche/build/creche_blockout.glb \
  assets/levels/creche/build/creche_blockout_topdown.png \
  assets/levels/creche/build/creche_manifest.json; do
  test -s "$file" || { echo "MISSING / EMPTY: $file"; exit 1; }
done
python - <<'PY'
import json
from pathlib import Path
f=Path('assets/levels/creche/build/creche_manifest.json')
d=json.loads(f.read_text())
assert d['pixel_scale_px_per_meter']==32
assert d['interior_dimensions_m']==[26.0,13.0]
assert d['outer_dimensions_m']==[27.5,14.5]
assert d['door_south_m']['width']==1.75
assert len(d['sockets']) >= 20
print('Creche manifest VALID:',len(d['sockets']),'sockets,',len(d['zones']),'zones')
PY
file assets/levels/creche/build/creche_blockout.glb
blender --background assets/levels/creche/build/creche_blockout.blend \
  --python assets/levels/creche/scripts/verify_creche_scene.py \
  2>&1 | tee assets/levels/creche/build/creche_verify.log
```

If there is an error, capture exact traceback in `build/creche_build.log`, fix only the relevant script and rerun. The included script is Python syntax-checked but has **not been executed under Blender in this handoff environment**; runtime compatibility must be proven by you. Do not claim it was executed until the `.blend`, `.glb`, and preview are actually present and verified.

**Optional visual verification in Blender:**

```bash
blender assets/levels/creche/build/creche_blockout.blend
```

Then switch to top orthographic view (Numpad 7), and examine wall placements against `references/creche_complete_1464x1074.png` and `docs/creche_blockout_plan.png`.

## Coordinate system (MANDATORY)

- Blender unit: 1 m. World axes X=east, Y=north (positive toward windowed wall), Z=up.
- Reference canvas **960 x 704 px**. Reference origin at pixel (480,352).
- Pixel-to-world: **X = (px - 480) / 32; Y = (352 - py) / 32**.
- Source floor is applied without stretching: u=(X+15)/30; v=(Y+11)/22. Full 960x704 source view corresponds to 30 m x 22 m world coverage.
- Camera: true top-down orthographic, centered at (0,0,40), orthographic span 30 m horizontally, 960x704 output. Do not interpret the drawn north-wall elevation as a photogrammetrically correct 3D photograph.

## Exact construction dimensions and positions (meters)

The numbers below are THE construction contract, even when they are inferred.

| Item | Center XYZ (m) | Dimensions XYZ (m) | Notes |
|---|---|---|---|
| Interior floor | (0,-2.125,0) | 26.00 x 13.00 x 0 surface | Bounds X[-13,13] Y[-8.625,4.375] |
| Floor collider | (0,-2.125,-0.125) | 26.00 x 13.00 x 0.25 | Separate collision / navigation placeholder |
| Full outer shell | X[-13.75,13.75] Y[-9.375,5.125] | 27.50 x 14.50 | No ceiling planned |
| North facade wall | (0,4.75,2.625) | 27.50 x 0.75 x 5.25 | Segmented for three real window openings |
| South facade wall | (0,-9.00,2.625) | 27.50 x 0.75 x 5.25 | Segmented for a centered entrance |
| West wall | (-13.375,-2.125,2.625) | 0.75 x 14.50 x 5.25 | Continuous |
| East wall | (13.375,-2.125,2.625) | 0.75 x 14.50 x 5.25 | Continuous |
| South wall west solid portion | (-7.3125,-9,2.625) | 12.875 x 0.75 x 5.25 | X[-13.75,-0.875] |
| South wall east solid portion | (7.3125,-9,2.625) | 12.875 x 0.75 x 5.25 | X[0.875,13.75] |
| South centered door opening | (0,-9,1.725) | **1.75 clear width x 3.45 clear height** | Actual gap through wall |
| South doorway lintel | (0,-9,4.35) | 1.75 x 0.75 x 1.80 | Above opening |
| North window 1 (left) | (-1.85,4.75,2.70) | 1.35 x 0.75 x 2.70 | Aperture, sill Z1.35, top Z4.05 |
| North window 2 (center) | (0,4.75,2.70) | 1.35 x 0.75 x 2.70 | Aperture, sill Z1.35, top Z4.05 |
| North window 3 (right) | (1.85,4.75,2.70) | 1.35 x 0.75 x 2.70 | Aperture, sill Z1.35, top Z4.05 |
| South threshold continuation | (0,-9.4375,0) | 2.50 x 1.625 surface | Exterior approach patch, not a full other room |

**Actual pier/capital structural proxies** (all Z center 2.625; height 5.25):

- North x centers: **-9.875, -4.125, 4.000, 9.750**; center Y 4.45; dims **1.25 x 1.10 x 5.25** each.
- South x centers: **-9.375, -3.8125, 3.8125, 9.34375**; center Y -8.80; dims **1.75 x 1.14 x 5.25** each.
- West side x center -13.08 and east +13.08. Each uses Y centers **0.53125, -4.21875, -7.90625**; dims **1.05 x 1.15 x 5.25**. These are approximate side-wall motif locations inferred from the extracted wall silhouettes.

## Architectural asset sockets: fixed reserves, NOT imported meshes

Art sockets are non-colliding wire volumes with metadata. The builder writes all final socket transforms to `build/creche_manifest.json`. The essential groups are:

1. **Four north sleeping alcoves:** image centers X=104,260,700,856 px, i.e. world X **-11.75,-6.875,6.875,11.75**. Socket center Y=3.95, Z=2.55; reserve **2.95 wide x 1.10 deep x 3.55 tall** each. Three use simple `Wall_Creche` references; fourth may use damaged variant. Solid backing wall remains until a finished mesh can be fitted safely. Do NOT mistakenly create exterior holes.
2. **Triple gothic window group:** centered at (0,4.22,2.80), reserve **6.20 wide x 0.85 deep x 4.60 tall** for modular reference `02_Back_Window_Detailed`, with independent real glazing apertures listed above. Detailed/simple versions are *alternatives*, not simultaneous overlapping meshes.
3. **North piers:** four generated column-family fittings, center X as above, reserve **1.45 wide x 0.85 deep x 5.25 tall**. Preserve pilaster spacing and trim height.
4. **South piers:** four generated columns, reserve **1.80 x 0.85 x 5.25** each.
5. **Side wall pier skins:** three per side, reserve **1.20 x 1.25 x 5.25** each.
6. **South door arch:** centered (0,-8.78,2.62), reserve **3.0 x 1.15 x 5.24** for `05_Door_Archway` and/or `07_LeftArm_ArchLeg`. The arch dressing must not reduce the 1.75 m playable opening unless expressly approved.
7. **South door leaf:** centered (0,-8.72,1.72), reserve **1.75 x 0.28 x 3.44** for `06_Door_Body`. Keep leaf separate from structural collider for later door interaction.
8. **North / south crown moldings:** center Z 4.85, reserve each **25.5 x 0.42 x 0.65**, visually repeated from `08_Stone_Crown_Molding` / `04_Decorative_Crown_Molding`. Trim is a repeated kit, not one stretched 25 m GLB; split into regular and corner pieces before finalizing.
9. **Rubble corners:** world x ±11.65, y 2.70 and -7.15, reserve each **2.15 x 1.50 x 0.65**, to be filled with `02_Stone_Rubble` variants. Maintain circulation clearance.
10. **Low wall:** `02_Low_Wall` stays in the reusable asset library; do not invent its placement in this particular room merely to use every extracted asset.

## Gameplay zone preservation

- Central motif approximately image (480,404), world center **(0,-1.625)**. Keep a **4.65 x 4.65 m** central reservation free of permanent tall scenery.
- West floor bay: center **(-7.1,-1.9)**; guide size **7.65 x 8.1 m**, no permanent geometry until encounter design is checked.
- East floor bay: center **(7.1,-1.9)**; guide size **7.65 x 8.1 m**.
- South exit clearance: center **(0,-7.3)**; reserve **2.35 x 3.65 m**, to Z3.3; keep a continuous walkable passage through south door.
- North glazing sightline: center **(0,3.0)**; reserve **5.8 x 2.0 m** as a presentation guide.
- Four sleeping-bay access rectangles: each X at the respective alcove; Y3.54; size **3.05 x 1.15 m**. These are reservations, not gameplay colliders.

## Integration with the actual CUSTODIAN project

1. Inspect the checked-out repo for its actual engine, scene formats, unit conventions, and existing Creche level. Never guess Godot/Unity/Unreal or overwrite a working level.
2. Build and visually verify the Blender master first. Preserve the full-resolution masters and separate blockout copies.
3. Only after inspection, integrate `build/creche_blockout.glb` (or native geometry reconstruction) into the existing engine. Preserve the saved socket names; derive placements from `build/creche_manifest.json`.
4. Find actual completed GLBs, if present, under e.g. `~/windows_image3d_results/` and the Windows-export copies. Map them by asset stem and explicitly log which sockets remain empty.
5. Normalize generated asset scales **individually** by inspecting their bounds; never assume image PNG canvas size gives physical mesh dimensions. Prefer uniform scale if possible; nonuniform art-fitting only after visual approval. Keep each imported GLB under its named socket parent. Do not destructively overwrite original geometry.
6. Use cheap proxy collision; no 700k-polygon generated asset should be used for direct physics. Do not import all pieces en masse unless the preview remains usable. Test 1 arch, 1 pier, 1 alcove, 1 window group first.
7. Capture an overhead screenshot aligned 960x704, a camera-angle screenshot from the actual game's playable camera, screenshot(s) of art sockets, and an import report naming all placed/missing assets.
8. Deliver a concise summary with exact command lines used, repo branch, any errors/fixes, generated file sizes, verified entrance/window openings, and remaining artistic uncertainties. Never claim physical measurements or architecture occlusion are photo-accurate.

## Acceptance criteria (must test)

- Correct image-to-world scale and alignment; reference floor image visible inside clear interior, no stretched texture.
- Four perimeter walls exactly as specified, window apertures and south entrance are actual geometry gaps.
- Four alcoves, eight front/back pier skins, six side pier skins, doors, trim and rubble sockets explicitly named and positioned.
- Save and verify `.blend`, `.glb`, preview PNG and JSON manifest.
- Blender scene remains editable, with separately toggleable structural walls, collision placeholders, reference art, sockets and gameplay zones.
- No changes to source PNGs/GLBs, no accidental game deploy, no destructive cleanup of unrelated work.
