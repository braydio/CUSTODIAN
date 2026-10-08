# Operator 2.5D Visual Contract

## Authority and status

The approved design lock at `custodian/asset_drop/source_work/operator/operator_2_5d_design_reference/operator_2_5d_design_lock_v1_source.png` is the authority for anatomy, armor and cloak topology, projection, materials, palette, and directional identity. Its direction order is `N, NE, E, SE, S, SW, W, NW`. The exact 2048x256 RGBA source hash is `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`.

The supplied relaxed idle at `custodian/asset_drop/source_work/operator/operator_2_5d_first_animation/unarmed_posture_idle_relaxed_01_full_body_v1_source.png` is the first production animation authority: 15 frames per direction, 128x128 cells, eight direction rows in the same order, looping. Its source hash is `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`. No FPS is inferred from image data; timing remains unresolved until authored metadata is available.

The current 128px profile is **provisional**. The 96px profile remains readable and selectable as `legacy_96`; production selectors and runtime art remain unchanged. The design-derived 128px rotation reference uses one crisp sheet-wide scale and is authoring evidence, not runtime art. Profile/reference hashes and measurements are recorded under `reports/operator_presentation/canonical_visual_contract/`.

## Registration and canvas

The 128x128 body canvas uses center axis x=64. Candidate projected root y=106 and ground y=107 remain unaccepted pending semantic calibration. Registration is based on the projected root, hip center, left/right support contacts, and shadow origin. Alpha bounds report clipping and silhouette extent only; alpha bottom and head top are not registration invariants. Never recenter on the alpha box, weapon, effect, cloak tip, or extended limb.

Use one shared body scale across all eight directions. Direction-specific adjustment may use whole-sprite integer translation only. Do not independently scale, rotate, shear, or warp a direction or frame. Pose motion may move joints while preserving anatomy, body scale, costume topology, and the root/floor coordinate system. Weapons and effects may use separate presentation envelopes; they never justify shrinking the body.

## Visual identity and pixel contract

Preserve direction-specific projection and near/far overlap. Do not mirror a view to invent a missing direction. Preserve the approved palette and material brightness hierarchy, including the directional visor behavior in the design lock. Keep hard pixel clusters and true alpha. The immutable high-resolution source is never recolored or cleaned. Any proposed cleanup is limited to the normalized 128 reference and must preserve dimensions, alpha mask, connected-component topology, silhouette, root, pose, and scale, with exact before/after hashes and changed-pixel records.

## Review gates

Before accepting the 128 registration, review a single deterministic eight-direction overlay against the authored idle. It must show cell bounds, x=64, candidate root and ground, hip center, both support contacts, shadow origin, alpha bounds, and confirm that directions share scale. Candidate semantic points inferred from pixels are review marks, not accepted truth.

Before declaring 128 a universal body canvas, measure representative extremes: deep dodge/crouch, fast-chain extension, wide block reaction, overhead melee, long one-handed reach, ranged aim, hit recoil, and downed/death poses. The body must fit with a deliberate margin without scale reduction; weapon/effect overflow is handled separately. Record measured extents and keep unresolved classes explicit.

The current pre-migration full-body proxy scan is cautionary evidence only: mapping legacy anchor `[48,84]` to candidate root `[64,106]` by whole-sprite translation puts 46/180 fast-chain frames and 16/47 long one-handed reach frames outside the 128px canvas. The largest fast-chain proxy is `melee_1h/attack/fast_02`, east frame 4, with source alpha bounds `[35,11,136,85]` and translated bounds `[51,33,152,107]`. These legacy assets do not establish canonical 2.5D pose limits, so this does not by itself reject 128px; it does mean the universal envelope remains unproven. Ranged aim (modular union), wide block-hit, and all-direction locked-projection samples remain unmeasured. Human review must decide whether the fast02 frame is a valid maximum-body proxy and whether the canvas or pose-root policy needs revision, while preserving the locked design/projection.

Hard failures include wrong profile/cell size, per-frame or per-direction scaling, wrong direction order, clipping, invalid alpha/layer ownership, or a changed canonical reference hash. Structural warnings cover root/support registration and anatomy ratios. Palette/material differences are art-direction warnings. Valid pose-specific joint motion is informational unless it violates the hard contract. No automatic anatomy warping is allowed.
