# Operator 2.5D Visual Contract

## Authority and status

The approved design lock at `custodian/asset_drop/source_work/operator/operator_2_5d_design_reference/operator_2_5d_design_lock_v1_source.png` is the authority for anatomy, armor and cloak topology, projection, materials, palette, and directional identity. Its direction order is `N, NE, E, SE, S, SW, W, NW`. The exact 2048x256 RGBA source hash is `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`.

The supplied relaxed idle at `custodian/asset_drop/source_work/operator/operator_2_5d_first_animation/unarmed_posture_idle_relaxed_01_full_body_v1_source.png` is the accepted first canonical animation source family: 15 frames per direction, 128x128 cells, eight direction rows in the same order, looping. Its source hash is `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`. FPS remains `unknown/null`; timing is not inferred from image data and is not a visual-contract blocker.

The 128px profile is **accepted** as the canonical body/reference registration frame (profile SHA-256 `05e92192af68b2f4e7516f59a0938e536926f3525a31b42dd7695f61d77ca761`). The 96px profile remains readable and selectable as `legacy_96`; production selectors and runtime art remain unchanged. The design-derived 128px rotation reference uses one crisp sheet-wide scale and is an accepted comparison reference, not runtime art (SHA-256 `e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9`). Profile/reference hashes and measurements are recorded under `reports/operator_presentation/canonical_visual_contract/`.

## Registration and canvas

The 128x128 body/reference frame uses center axis x=64, projected root `[64,106]`, and shadow origin/ground `[64,107]`, fixed across all eight directions. Registration is based on the projected root, hip center, left/right support contacts, and shadow origin. Alpha bounds report clipping and silhouette extent only; alpha bottom and head top are not registration invariants. Never recenter on the alpha box, weapon, effect, cloak tip, or extended limb.

Use one shared body scale across all eight directions. Direction-specific adjustment may use whole-sprite integer translation only. Do not independently scale, rotate, shear, or warp a direction or frame. Pose motion may move joints while preserving anatomy, body scale, costume topology, and the root/floor coordinate system. Weapons and effects may use separate presentation envelopes; they never justify shrinking the body.

## Visual identity and pixel contract

Preserve direction-specific projection and near/far overlap. Do not mirror a view to invent a missing direction. Preserve the approved palette and material brightness hierarchy, including the directional visor behavior in the design lock. Keep hard pixel clusters and true alpha. The immutable high-resolution source is never recolored or cleaned. The normalized 128 reference is accepted unchanged at SHA-256 `e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9`; no cleanup pixels are authorized.

## Review gates

The accepted registration was reviewed against the authored idle in one deterministic eight-direction overlay. The registration decision is fixed; candidate semantic points inferred from pixels remain measurements and do not override approved coordinates.

The accepted 128px profile defines the canonical body/reference frame; **universal action-envelope fit is not asserted**. Future extreme actions receive per-action fit validation. If genuinely canonical body content cannot fit without clipping, distortion, or scale reduction, use a root-preserving expanded action envelope and/or modular presentation. Do not change global body scale or root to fit legacy proxy extents. Weapon/effect overflow remains separate.

The pre-migration proxy scan is cautionary evidence only: mapping legacy anchor `[48,84]` to accepted root `[64,106]` by whole-sprite translation puts 46/180 fast-chain frames and 16/47 long one-handed reach frames outside the 128px canvas. The largest fast-chain proxy is `melee_1h/attack/fast_02`, east frame 4, with source alpha bounds `[35,11,136,85]` and translated bounds `[51,33,152,107]`. Human review determined this legacy art is not a valid maximum-body proxy and does not redefine the canonical body frame, root, or scale. Universal action-envelope fit remains intentionally unasserted. Ranged aim (modular union), wide block-hit, and future extreme actions require their own validation and may use root-preserving action-specific envelopes.

Hard failures include wrong profile/cell size, per-frame or per-direction scaling, wrong direction order, clipping, invalid alpha/layer ownership, or a changed canonical reference hash. Structural warnings cover root/support registration and anatomy ratios. Palette/material differences are art-direction warnings. Valid pose-specific joint motion is informational unless it violates the hard contract. No automatic anatomy warping is allowed.
