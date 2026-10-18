# R3 Boot Connection + Final Composite Topology | Operator NE Walk

**Workstream:** `operator-2-5d-ne-walk-retargeting` · Iteration 008 · `REVIEW_ONLY`

## Locked authority

- Original validated NE gait, 15×128×128 frames, support sides, joint positions: Iteration 004 strip/report, unchanged.
- Human-accepted rig: `operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite`, SHA locked in R2.
- Already-staged R2 compositor: `clean_silhouette_r2.py` SHA `9f96809956afe538df519cd62fa9fd0390b41de206392dea026121244c019b68`, source of the 3076-pixel-change candidate. Do not edit R2.
- Published R2 pixel candidate SHA `51e196c0a6b7dd34a9eb53557ff52528e3ef4cc7bd84b3fab6df8b8cdbc95047`. R3 requires exact pixel match when reconstructing R2 from canonical source files.
- R1 alternate strip remains a visual reference, never target gait authority. Idle jitter is a separate future slice.

## Exact authored R3 fix

1. Run unchanged `r2.build_frame()` to reproduce *exact* motion-anchored R2 pixels; verify 15-frame binary-alpha decoded pixels against published R2 candidate.
2. Construct owner-tagged near/far foot and shin rasters independently from the already-authoritative semantic rig and IK endpoints.
3. Identify main connected 8-neighbor component from immutable upper body, and anatomical planted sole by report-provided `rendered_boot_contact`, not by screen-left/right x partitions.
4. If the reported support sole is orphaned, bridge to a *body-connected anatomical foot/shin owner* only. Maximum Euclidean gap 9px, maximum newly introduced bridge pixels 8, only y=68..116. Copy only colors from accepted rig boot pixels, preserve exact original reported sole pixels; no interpolation, blur, new colors or tuning.
5. Check **FINAL composited raster** for changed detached distal islands within 12px of near/far knee/ankle/toe. For islands at most 10px, create at most three bounded owner-matched bridges using the same 9px/8-pixel constraints. If excessive, missing owner, unconnected, protected torso altered or source SHA wrong, FAIL CLOSED instead of creating artwork.
6. Preserve original upper 68 rows, locked source palette/binary alpha, full gait, and old animation assets byte-for-byte. F15→F01 alpha/silhouette difference is reported for human review, not certified smoothness.

## Tests / limitations

- Synthetic exact-color negative cases: detached sole repaired by four pixels; source sole tampering rejected; oversized gap/missing owner rejected; free-floating distal island detected and repaired; semantic parser original rig fixture; 15 moving-frame synthetic pass with support changes.
- **Never claim** actual accepted recovered rig, source animation or real visual F07 repair tested in ChatGPT container. These files are local to Luna's worktree and are verified when runner executes there.
- Changing only 1–8px per boot seam may not be artistically sufficient. If real F07 needs more than the bounded palette bridge, executor must STOP and return actual diagnostics for ChatGPT revision.
- No canonical animation FPS, Godot wiring, Asset Pipeline V2 normalized ingest, or main landing approved.

## Artwork map and paths

- Existing input: `custodian/asset_drop/source_work/operator/operator_ne_walk_cleanup_r1/`, RGBA 128×128 cells, 1f style/10f alt/15f alt/15f idle. This R3 package adds no new art reference family.
- Disposable candidate: `~/Downloads/operator_ne_master_audit_implementation_v1/iter_008_boot_continuity_art_r3/operator_ne_walk_r3_connected_candidate_15f_1920x128.png`, RGBA binary alpha, 15×128×128 frames, strip. Never normalize/ingest as runtime at this stage.
- Dropbox review: `/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/iter-008-boot-continuity-art-r3/REVIEW_MANIFEST.json`.
