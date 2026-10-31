# CUSTODIAN Operator South Visible-Surface Rig V1

- **Status:** source-work candidate; no artistic or runtime approval
- **Workstream:** `operator-motion-foundry-south-rig-pixel-segmentation-v1`
- **Chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- **Source:** `CUSTODIAN_OPERATOR_RUNTIME_REFERENCE_128.aseprite`; pinned SHA-256 `61c7518b31a28d7b98af5efdb035316550b769abea7eb33ff0466544040172a3`
- **Source meaning:** original user-provided eight **directional** 128×128 frames in one flattened Aseprite image layer, not a 15-frame authored idle animation.
- **Selected frame:** zero-based index 4, south-facing, 128×128, binary alpha.
- **Source geometry:** 2,440 visible pixels; alpha bbox `[40,20,89,105)` (exclusive maximum); absolute canvas root `(64,106)` and ground `(64,107)` from Operator design authority.
- **Method:** hand-traced pixel-coordinate semantic regions, exact pixel owner selection, nearest owned-pixel fallback for 23 boundary/fringe pixels. Entire source RGBA value of each visible pixel is copied *unchanged* onto exactly one 128×128 layer. All transparent pixels are cleared. Exact source/reassembly comparison and native Aseprite roundtrip check both pass.
- **Output:** 23 separately named 128×128 RGBA layers, of which **18 hold real visible source pixels** and **5 are intentionally blank** because their surfaces are occluded by other parts. Programmatic writer exports a 128×128 one-frame `.aseprite` with the 23 layers. This file has been structurally decoded and pixel-verified with the bundled Python reader but **not opened in Aseprite GUI**.
- **Part seam audit:** 494 visible pixels touch a different assigned region across a 4-connected edge. `pixel_ownership.csv` lists **every visible pixel** and its original RGBA values. Non-polygon fringe pixels are marked `nearest_fallback`. These numbers are not error rates.

## Deliverables

- `source/CUSTODIAN_OPERATOR_RUNTIME_REFERENCE_128.aseprite`: immutable supplied eight-direction source, included to make the bundle self-contained.
- `scripts/extract_operator_south_rig.py`: reproducible pixel extraction, validation and Aseprite layer writer.
- `scripts/test_extract_operator_south_rig.py`: seven independent tests (exact source, 2,440-pixel ledger, 128px MF1 rig contract, roundtrip, determinism, mutation rejection, static motion truth).
- `extracted/parts/*.png`: **23 RGBA 128×128**, all parts at original absolute positions, including five intentionally empty topology anchors.
- `extracted/operator_south_segmented_source.aseprite`: one-frame native layered review source, **NOT the original 8-frame document**.
- `extracted/source_south_visible_frame.png` and `extracted/reassembled_exact.png`: byte-identical RGBA pixels.
- `extracted/rig.json`: versioned `custodian.motion_foundry.rig.v1` for local MF1 CLI, profile SHA and part hashes.
- `extracted/motion_static_proof.json`: **15 identical neutral-pose frames only** (not a moving, approved animation), `fps=null`.
- `extracted/segmentation_manifest.json` and `extracted/hierarchy_and_overlap.json`: detailed provenance, frame/root, seam contacts, topology, uncertainty.
- `extracted/pixel_ownership.csv`: individual pixel x/y, unchanged RGBA, semantic part, polygon/fallback and cross-region seam flag.
- `extracted/preview/segmentation_comparison.png`: original → region ownership → exact reconstruction.
- `extracted/preview/parts_contact_sheet.png`: enlarged **preview crops only**, never source input.
- `extracted/preview/seam_review_mask_128.png`: pink flags for immediate boundary review.
- `asset_handoff_manifest.json`: family, source_work path, hashes, cell/frame geometry, all 23 part identities, provenance and ingest gating.

## Suggested hierarchy and visible-pixel inventory

Screen left/right describe **viewer-side positions**, not character's anatomical left/right. Parents and pivots are **estimates**, and MF1 only implements independent integer translations. The parent/pivot fields are a proposed foundation for later hierarchical transforms.

| Back-to-front owner | Visible pixels | Parent | Pivot (x,y) | Surface state |
|---|---:|---|---|---|
| `cape_back_left` | 0 | `world` | [53, 57] | **Empty: occluded** |
| `cape_back_right` | 0 | `world` | [76, 57] | **Empty: occluded** |
| `thigh_screen_left` | 0 | `pelvis` | [57, 75] | **Empty: occluded** |
| `shin_screen_left` | 39 | `thigh_screen_left` | [52, 84] | Visible surface |
| `boot_screen_left` | 74 | `shin_screen_left` | [52, 92] | Visible surface |
| `thigh_screen_right` | 0 | `pelvis` | [75, 76] | **Empty: occluded** |
| `shin_screen_right` | 58 | `thigh_screen_right` | [79, 86] | Visible surface |
| `boot_screen_right` | 101 | `shin_screen_right` | [79, 97] | Visible surface |
| `torso` | 140 | `world` | [64, 52] | Visible surface |
| `pelvis` | 0 | `torso` | [64, 61] | **Empty: occluded** |
| `tabard_screen_left` | 234 | `pelvis` | [57, 63] | Visible surface |
| `tabard_screen_right` | 165 | `pelvis` | [73, 63] | Visible surface |
| `tabard_center_fold` | 259 | `pelvis` | [64, 63] | Visible surface |
| `arm_upper_screen_left` | 58 | `torso` | [50, 45] | Visible surface |
| `arm_forearm_screen_left` | 78 | `arm_upper_screen_left` | [45, 54] | Visible surface |
| `hand_screen_left` | 66 | `arm_forearm_screen_left` | [45, 63] | Visible surface |
| `arm_upper_screen_right` | 61 | `torso` | [80, 45] | Visible surface |
| `arm_forearm_screen_right` | 66 | `arm_upper_screen_right` | [84, 54] | Visible surface |
| `hand_screen_right` | 71 | `arm_forearm_screen_right` | [85, 64] | Visible surface |
| `belt_clasp` | 213 | `pelvis` | [64, 59] | Visible surface |
| `hood` | 423 | `torso` | [64, 40] | Visible surface |
| `pauldron_screen_left` | 184 | `torso` | [51, 39] | Visible surface |
| `pauldron_screen_right` | 150 | `torso` | [80, 39] | Visible surface |

Parent graph (animation semantics, not current MF1 runtime behavior):

```text
world
├─ torso (fixed)
│  ├─ hood
│  ├─ pelvis (occluded, blank)
│  │  ├─ thigh_screen_left (blank) → shin_screen_left → boot_screen_left
│  │  ├─ thigh_screen_right (blank) → shin_screen_right → boot_screen_right
│  │  ├─ belt_clasp
│  │  └─ tabard_screen_left / tabard_center_fold / tabard_screen_right
│  ├─ arm_upper_screen_left → arm_forearm_screen_left → hand_screen_left
│  ├─ arm_upper_screen_right → arm_forearm_screen_right → hand_screen_right
│  ├─ pauldron_screen_left / pauldron_screen_right
│  └─ (future) cape_back_left / cape_back_right, both blank
```

The current `cape_back_*` anchors have `parent=null` in the MF1 static rig because the original image does not identify their attachment point. The conceptual parent assignment is still **unresolved**, and must be authored before hierarchical motion.

## Overlap / fold order and uncertainty

The following relationships are **visible-topology interpretations**, not recovered hidden surfaces. Detailed entries and uncertainty levels are in `hierarchy_and_overlap.json`.

- Cowl/hood visually fronts the collar and upper torso; pauldrons cover shoulder/upper-arm junctions. **Needs underpainting** for any meaningful head or arm swing.
- Forearm bracers precede gloved hands at the cuff. **Needs seam cleanup** if part offsets differ.
- Central gold-bordered hanging fold lies visually in front of the two side tabard panels. Gold trim meets side folds around y≈65–85. **Needs cloth-specific separation review**.
- Front drape hides pelvis and much of both thighs; the five intentionally empty layers make the lost depth information explicit. **Cannot recover without artist-supplied body/cloth underpaint**.
- Rear cape attachment and interior/back surface are not visible in the south-facing flattened image. The other directional frames may guide an artist but are not a pixel-aligned exact substitute.
- Root (64,106) is 2px below bottommost visible silhouette y=104. Do not recenter to the opaque bbox. No gameplay body translations or collider edits.

### Measured seam adjacency, first 13 by pixel boundary length

| Pixel-owner pair | 4-connected boundary edges |
|---|---:|
| `tabard_center_fold, tabard_screen_right` | 26 |
| `hood, pauldron_screen_left` | 25 |
| `tabard_center_fold, tabard_screen_left` | 25 |
| `hood, pauldron_screen_right` | 21 |
| `arm_upper_screen_left, pauldron_screen_left` | 19 |
| `belt_clasp, torso` | 18 |
| `hood, torso` | 18 |
| `arm_forearm_screen_right, arm_upper_screen_right` | 16 |
| `arm_upper_screen_right, pauldron_screen_right` | 16 |
| `belt_clasp, tabard_center_fold` | 13 |
| `boot_screen_left, shin_screen_left` | 13 |
| `shin_screen_right, tabard_screen_right` | 13 |
| `arm_forearm_screen_right, hand_screen_right` | 12 |

There are **24** distinct touching-part pairs. See `hierarchy_and_overlap.json` for all. Inspect the 23 nearest-assignment pixels and the 494 boundary-adjacent pixels before declaring an animation-ready rig. The neutral zero-diff test does **not** validate the semantic split or moving occlusions.

## Run the extractor and tests

From the extracted package directory:

```bash
python3 -m pip install Pillow
python3 scripts/test_extract_operator_south_rig.py
python3 scripts/extract_operator_south_rig.py \
  --source source/CUSTODIAN_OPERATOR_RUNTIME_REFERENCE_128.aseprite \
  --out extracted
```

This does not write to a Git checkout, edit your source, or publish artwork. Do not use `--allow-unpinned-source` to claim production authority: boundary coordinates are calibrated to the exact input SHA only.

## Operator Asset Pipeline V2 path contract

**Proposed source_work destination, relative to live repo:**

`custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1/`

Store source, scripts, pixel ledger, masks, rig JSON, source `.aseprite` and manifests together. The source graphics have already reached **128×128 RGBA 1-frame**, no resize, resample or mirroring. New raw assets are **not** placed directly into runtime nor Asset V2 inbox. Family is `operator_2_5d`, specialized Operator source/ingress; stage through the canonical source-work and approval process.

Once genuinely authored motion, underpaint, artist review, and MF1/MF2 review/bridge gates are satisfied, the potential candidate target is south `unarmed/posture/idle_relaxed_01`, **15×128×128**, horizontal strip **1920×128** at **unknown/null FPS** until explicit timing decision. Only the existing Operator2DIngress/SourceArtService and `custodian/asset_drop/inbox/operator_2_5d/` may handle specialized future intake. This bundle provides **no** approved inbox animation and **no** runtime sprite replacement.

## Limitations and implementation drift

1. The reference is an eight-view character source, not the separately approved canonical 15f idle; require visual lock comparison and a chosen representative frame before reauthoring production state.
2. MF1 accepts the generated `rig.json` and `motion_static_proof.json` schema conceptually; this bundle has independent tests but **has not executed the live MF1 CLI**, because repository code is not in this local artifact environment. Do that in a Codex isolated worktree as a next gate.
3. Native Aseprite writer passed self-decoding and exact pixel reconstruction. Validate that the generated document opens as expected in Aseprite itself before art editing.
4. MF1 only translates whole-canvas source parts; pivots/parents are data until a later rig transform module implements rotations/IK/deformation.
5. Repo design document `design/02_features/animation/CUSTODIAN_MOTION_FOUNDRY_V1.md` still says `not implemented` even though MF1 landed. Correct active status as documentation-only follow-up. The broad mention of 96px candidates is also wider than MF1's current Operator-only 128px accepted input. Do not alter immutable review evidence.
6. The original independent MF1 code review remains blocked by a separate infrastructure recovery, so no this-output production promotion should bypass those gates.
