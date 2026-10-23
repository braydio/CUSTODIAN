# Carrow Yard Marble Perimeter · Real-Asset Assembly Gallery V1

**Workstream:** `carrow-yard-marble-perimeter-source-intake-v1`
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad5eb5a-598c-83ea-b982-531d4ff5418f
**Status:** execution acceptance spec, not a record of completed examples.
**Source truth:** `source_batch.md` beside this document; SHA-pinned Dropbox ZIP and manifest. The three actual static RGBA PNGs are the ONLY marble wall subjects. Never regenerate, approximate, scale, stretch, rotate, flip, or paint over these sources to manufacture a pass.

## What to build

A **focused, reproducible Godot 4.x review-only scene**, using the actual project's Operator, Camera2D, native 32px world grid, real source textures, and the in-game zoom (confirm the live Camera2D value; the previous candidate preview used 0.84; do not blindly hardcode stale zoom). No full Carrow map changes, no runtime asset ingest, no world-route changes, no new traversal or collision authority.

Suggested output owners:
- `custodian/scenes/debug/carrow_marble_perimeter_assembly_gallery.tscn`
- `custodian/tools/asset_authoring/carrow_yard_marble_perimeter_v1/carrow_marble_assembly_gallery.gd` (bounded controller/helper only, if required)
- `custodian/tools/validation/carrow_marble_assembly_gallery_smoke.gd`
- `custodian/tools/asset_authoring/carrow_yard_marble_perimeter_v1/assembly_placements.json` (generated evidence, commit in workstream)
- Review captures: `reports/carrow_yard_marble_perimeter/<run_id>/` with six overview PNGs, all seam closeups, `assemblies.json`, and `findings.md`; commit durable evidence/report in the appropriate repo review path if reports are ignored, do not promise untracked-only evidence.

## Exact source states

| ID | filename under `custodian/asset_drop/source_work/carrow_yard/carrow_yard_perimeter_walls_v1/` | Original dimension, one frame |
|---|---|---|
| E-W | `wall_marble_ew_straight_01_source.png` | 805×684 RGBA |
| N-S | `wall_marble_ns_straight_01_source.png` | 492×505 RGBA |
| Corner | `wall_marble_corner_ne_01_source.png` | 507×684 RGBA |

Before any examples: fetch, SHA-check and stage sources via the already-published source batch and audited installer, or reuse exact hash-verified source_work files if already present. No replacement of earlier seven sources. The source PNG dimensions are **not** world-space footprints.

**Calibrated starting assembly only:** exact original-L reconstruction offsets in unscaled source pixels: E-W at (0,505), N-S at (820,0), Corner at (805,505). This is the initial control; `assembly_placements.json` must explicitly distinguish `source_px` and `game_world_px` coordinates. These source reconstruction offsets do not establish 32px-grid registration or repeated seam pitch.

## Six separately selectable views

1. **`ew_repeat_three`**: THREE actual E-W instances connected end-to-end. Determine candidate crop/pitch by preserving source pixels, testing copies with only positional offsets, and choosing alignment based on real shared visual landmarks. Show whole run and enlarged left/right joins with checkerboard and neutral-ground variants; state FAIL if seam overlaps towers or creates discontinuity. Do not assume a full 805px cut is mathematically periodic.
2. **`ns_repeat_three`**: THREE actual N-S sections. Demonstrate user's two-layer `front/main` and `back/underlap` approach, with measured dx/dy, exact crop, z-index and overlap mask for each. Include an overlay with the occluded layer tinted for diagnosis; main photograph must show genuine unchanged source art. If no reliable pitch, save best candidate and FAIL with a visible defect; no speculative regenerated art.
3. **`corner_l_approved_shape`**: Combine E-W, NE corner and N-S into the actual approved L. First reproduce the lossless source arrangement. Then show a production-candidate placement with N-S underlap at the bend. Separately report pixel-exact source reconstruction (expected PASS) vs independent junction seams (not pre-approved).
4. **`south_gate_gap`**: E-W west/east runs separated by a debug **five-world-cell (160px) minimum clear passage**, anchored to a game-ground 32px grid, without painting a gate or inventing art. Explain if projected facade overlaps visually despite clear ground path. Show proposed gate-adjacent termination outlines or candidate masks as diagnostics ONLY. No alpha-driven collision.
5. **`four_side_perimeter_proposal`**: A site-scale *design study* of an enclosure, gate and walking lane. E-W and N-S accepted source pieces may be reused at same orientation where credible. Other corner orientations, opposing-facing facade and terminals MUST remain visibly marked `MISSING ART` or dashed plan geometry, not mirrored sprites masquerading as production. Demonstrate realistic spacing and list extra states genuinely required.
6. **`operator_native_scale`**: Actual Operator alongside the E-W wall, N-S wall, and L corner with unmodified runtime Camera2D, zoom and 32px overlay. Show front/behind occlusion or roof-fade as exploratory layer order only, no new gameplay collision. Capture at game-scale 1x, not editor-fit or an enlarged promotional render.

## Controls and reproducibility

- Tabs/buttons or number hotkeys `1..6` select scenes. `G` toggles grid; `S` toggles seam debug / tile-anchor overlays; `O` shows underlap source vs occlusion; `C` switches checkerboard vs neutral yard ground. Keep test geometry anchored to the same camera and world origin, with center/framing adjusted independently.
- Each example's root and every piece records: source filename + SHA, source crop rectangle `[x0,y0,x1,y1]` if any, source dimensions, unscaled sprite origin, world placement, draw order, image-space overlap, measured connector endpoint coordinates, claimed/seeking repeat pitch, and status `pass|fail|unverified`. A row missing evidence cannot claim PASS.
- Screenshot filenames: `01_ew_repeat_three.png`, `02_ns_repeat_three.png`, `03_corner_l_approved_shape.png`, `04_south_gate_gap.png`, `05_four_side_perimeter_proposal.png`, `06_operator_native_scale.png`. Include `*_seam_detail.png` or `*_underlap_debug.png` as necessary.
- Output `assemblies.json` schema `custodian.carrow_marble_assembly_gallery.v1` with `source_batch_sha256`, `game_grid_px:32`, `camera_path`, `camera_zoom`, `scenes` array keyed by the six ids, `pieces` and `interfaces` per scene, exact `xy` placement/draw order/crop, per-interface `status` and `defects`. Specify all numbers in units, no bare ambiguous offsets. Include screenshot relative paths.
- Test invalid source hashes, missing textures, unknown scene IDs, bad crops/bounds, wrong source dimensions, missing camera/Operator, missing screenshots, unmeasured connector transforms, and false PASS from the control reconstruction. Fail closed with a useful error; never silently fall back to placeholders except the explicitly labeled four-side planning geometry.

## Acceptance / handoff

- Six selectable live examples load and capture deterministically in headless or supported Godot renderer using actual PNG file hashes and real camera/Operator.
- Every screenshot and `assemblies.json` comes from that run, not a Photoshop collage or fabricated position list.
- A source hash mismatch, a blocked seam, or a visually implausible camera must be reported as an explicit FAIL, not hidden by masking/clipping.
- `corner_l_approved_shape` source control still reconstructs the 1312×1199 master exactly (under existing alpha<=3 cleanup), while true repeat joins are graded independently.
- `south_gate_gap` documents valid 160px gameplay-space opening even if presentation art needs new end pieces.
- `four_side_perimeter_proposal` documents missing orientations/end caps as proposed asset family states, with source path `custodian/asset_drop/source_work/carrow_yard/carrow_yard_perimeter_walls_v1/<new_state>_source.png`, one RGBA frame and **pixel dimensions left provisional pending measured world/shot approval**. Do not fabricate assets or ingest anything.
- Save native full-frame captures and 2x nearest-neighbor review enlargements, with tests plus `git diff --check`.
- Human review decides art quality, corner orientation, entrance geometry and subsequent normalization. Completing this gallery is **not** automatic production approval.

## Quick source preflight (from repo root)

```bash
set -euo pipefail
STAGE="$(mktemp -d)"
rclone copyto 'git-dropbox-sync:/CUSTODIAN/asset_batches/custodian_carrow_yard_marble_corner_slices_handoff_v1.zip' "$STAGE/batch.zip"
printf '%s  %s\n' '9079d308412f3c1cef3840d730bb9234da074ad8f09232e8db6be20509b92392' "$STAGE/batch.zip" | sha256sum -c -
unzip -q "$STAGE/batch.zip" -d "$STAGE"
PKG="$STAGE/custodian_carrow_yard_marble_corner_slices_handoff_v1"
python3 custodian/tools/asset_authoring/carrow_yard_marble_perimeter_v1/verify_marble_slices.py "$PKG"
cp custodian/tools/assets/asset_handoff_installer.py "$PKG/INSTALL_INTO_REPO.py"
python3 "$PKG/INSTALL_INTO_REPO.py" --repo "$(git rev-parse --show-toplevel)" --dry-run
```
