# Claude task 007 — round the Operator cowl, NOTHING ELSE

**Decision:** exp-006 is **HOLD / NOT ART-APPROVED**. The verified 3D Blender pipeline, capeless garment topology, sole construction, and frozen proof are valuable technical advancements. User and agent report a tall spire hood, thin limbs, reflective pauldrons and stiff motion; image and GIF pixels have **not** been independently inspected by ChatGPT via current Dropbox connector. Do not claim a subjective review of unseen pixels.

**Baseline:** existing branch `agent/operator-3d-master-modeling-proof-v1`; immutable `exp-006` SHA256 GLB `33160633a98b263013da28561cecb99376ad6365cd18ab9df5f9e963faa5b254`; prior `exp-005`. The exp-006 art is NOT canonical. `exp-006` source used `config/shape_v006.json` (`model_version: 6`), `scripts/generate_mesh_v6.py`. Main untouched. Do not set best-candidate or edit runtime.

## Exact one-candidate task (exp-007)

1. In the **existing** art worktree, check `git status`; fetch/fast-forward existing branch only if clean. Do not redo Blender MCP setup, alternate tool research, broad audits, prior experiments, or another worktree.
2. Add an optional `hood_profile_rings` configuration override **only** for `Head__hood_shell` in `scripts/generate_mesh_v6.py`, with current hard-coded ring list as the exact unchanged default. The ring schema is `(z, width_x, depth_y, center_y)`. Existing exp-006 **without the new key must regenerate byte-identically**; frozen exp-001..005 unaffected. Do not rename objects or change rig groups. If deterministic regeneration fails, revert the refactor and use a copied versioned builder for 007.
3. Copy `config/shape_v006.json` to `config/shape_v007.json`, retain `model_version: 6`, change only the candidate name and **hood_profile_rings**. The current spire originates in these actual v6 upper rings: `(1.95,.14,.155,-.05), (2.03,.07,.09,-.10), (2.075,.012,.03,-.155)`. They narrow steeply and push the top forward. Target a **rounded, full crown with a blunt domed apex**, not a pointed cowl; keep apex height near 2.075m and visor/face opening unchanged. Initial deterministic test profile (lower rings unchanged):
   ```json
   [
     [1.50,0.30,0.25,0.05],
     [1.60,0.27,0.235,0.04],
     [1.72,0.245,0.220,0.02],
     [1.84,0.225,0.205,0.00],
     [1.95,0.185,0.180,-0.015],
     [2.03,0.125,0.130,-0.025],
     [2.075,0.035,0.055,-0.025]
   ]
   ```
   These are **starting proportions**, not artistic truth. Evaluate them against the 8-dir **real locked idle** at native 128px, especially N, NE, E, S, and SE. If the profile still reads as a spike, allow **one** adjustment to this candidate's source config **before** creating/finalizing the exp-007 immutable directory; do not overwrite a built/frozen experiment. If necessary, create a staged copy of the config and preview in a temporary non-candidate location until the chosen values are ready. There is no need to use Blender MCP for a parameter-only change.
4. Run the existing deterministic source-work pipeline **once** for the committed v007 configuration:
   ```bash
   cd custodian/asset_drop/source_work/operator/operator_3d_master
   python scripts/experiments.py new --id exp-007 --config config/shape_v007.json
   python scripts/run_blender.py --experiment exp-007
   python scripts/build_review.py --experiment exp-007
   python scripts/build_candidate_sheet.py review_pack/candidates_exp005_exp006_exp007.png exp-005 exp-006 exp-007
   python scripts/freeze_proof.py --experiment exp-007 --notes 'Hood-only rounded-cowl experiment; art approval pending'
   ```
   Do not run `select-best`. Never rewrite/freeze exp-006 again.
5. Structural guards: `Cloak__` remains **zero**, hood+visor+tabard intact, same rig/cameras/animation/materials/foot z, 128x128 and root (64,106). Compare manifest object names/material/rigtags between exp-006 and 007: **only the `Head__hood_shell` geometry may change**. Verify regenerated exp-006 bytes against frozen sha; if blocked, diagnose only that discrepancy and stop.
6. Review output: one compact 8-dir source/006/007 sheet, one S/SE/NE head crop at nearest-neighbor 4×, and the existing exp-006 walk GIF **linked for reference**, not rerendered as a newly improved walk. Include native 128px hood acceptance findings, camera registration, per-view IoU, and hashes. Do not assert art acceptance. Upload through existing Dropbox review workflow if operational, preserve immutable local proof and commit/push on this existing branch only. Stop for human comparison; leave worktree intact and project-root `~/Projects/CUSTODIAN` clean on main.

## Keep these known issues separate and open

**Do not attempt to fix in task 007:** chrome pauldrons, thin limbs, dotted gold trim, flat tunic panels, stiff walk, foot movement solver or render exposure. One variable per experiment keeps causal attribution clear.

**Known measured registration:** exp-006 vs source has N width 58 vs 46px, E 29 vs 33px, NE 47 vs 41px, and SE/SW bottom y=114 vs source y=106. Changing the hood must not masquerade as a camera/root correction. Mean 8-view alpha IoU for exp-006 = **0.637**, lower than exp-005 = **0.678**. IoU is triage, **not** character approval.

**Contact claim correction:** exp-006 audit reports `planted_body_frame_step_mean_m=0.0602` and `planted_skate_max_dev_mm_per_frame=0.0`; zero **variation** in body-frame step is not proof of zero ground/world-space sliding. Stance world-space/root-translation compensation must be tested in a future motion-only task. NE animation is **mechanically plausible / artistically unverified**, preview cadence not approved.

**Token budget:** execute these exact steps and report in **<=180 words** with proof links and blockers. No speculative redesign plans, no repeated status narration.
