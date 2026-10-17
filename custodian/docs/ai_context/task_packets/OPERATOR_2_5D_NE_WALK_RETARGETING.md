# Operator 2.5D NE Walk Retargeting | Iterative Visual Acceptance

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-2-5d-ne-walk-retargeting`
- Kind: `implementation`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `operator-ne-walk-authoring`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, visual, workflow`
- Paired review workstream: `review-operator-2-5d-ne-walk-retargeting`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `nontrivial IK/animation solver and raster-authoring correctness, independent technical review after human animation acceptance`
- Reviewed main: `675ccf726bb79397b7242ef3059971a6f1a39448`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe`
- Visual review: `required`
- Goal: Deliver a human-accepted, visibly alternating, northeast-facing 15-frame Operator walk from the exact approved Knight NE donor, without modifying source art or publishing unapproved animation.
- Completion boundary: One continuous implementation workstream across as many *human-directed* visual iterations as needed; final 15-frame loop is accepted here, mechanical/artifact regressions pass, and only then may the implementation workstream follow normal land/archive and fresh-context paired technical review. Runtime asset ingestion, selector wiring, and authoritatively selecting animation FPS are separately authorized work and not silently included.
- Current measured state: Human rejected the active Iteration 004 NE gait **art**, retaining its validated solver motion. Iteration 006 R1.1 authored silhouette transplant ran and published six Dropbox artifacts. Genuine before/after imagery improves leg/apron integrity but substitutes alternate strip pose shapes, breaking F05/F12/F13 walk semantics; 18,235 pixels changed, 14/15 heuristic foot-contact warnings, selected checks pass but reference-manifest file coverage incomplete. R1 art and runtime REJECTED; Iteration 007 on HOLD until ChatGPT writes a new motion-anchored cleanup script.
- Evidence: Six-artifact Dropbox review `/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/iter-006-silhouette-transplant-r1/REVIEW_MANIFEST.json`, candidate SHA256 `066f2c66eec48d42a3ab2a87273c8119e6de67cc26b2a390ffceb4757a3698ba`, `CLEANUP_REPORT.json` SHA256 `f09ac2cdf27101fb4e9ceb1830b7f8290e26f2c4a7140bfba592eaaf78762c3e`; correct R1.1 ZIP SHA in Iteration 006 historical receipt. No inference about a new commit from manifest base SHA `8413c67f`.
- Task-specific authority: `design/01_systems/ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`; `custodian/content/data/operator/authoring/operator_art_profile.json`; accepted rig/donor/crossover receipts named above; `custodian/docs/ai_context/VISUAL_REVIEW_HANDOFF.md`.
- Work surface: `custodian/tools/operator/ne_walk_retarget/{continuity.py,crossover.py,motion_plan.py,batch.lua,calibration.lua,occlusion.lua,rigid_raster.lua,review_viewer.py,run.py,annotations.json,README.md}`; focused `custodian/tools/validation/{operator_ne_motion_plan_smoke.py,operator_ne_rigid_raster_smoke.py,operator_ne_rig_master_audit_smoke.py,validation_manifest.json}` only when required.
- Change: No code or art changes presently authorized. ChatGPT will author a new frame-local semantic part cleanup script that preserves the validated motion/contacts; Luna will only execute exact script after new approval and hash verification.
- Preserve: Exact original `SINGLE_FRAME.aseprite` SHA256 `0f5b3346044e60581db6e38e41fc292bd2b49ca05c291ada9591495765166149`; accepted rig SHA256 `b7002e66df5928a53d4a42e7b74e7bdf82f6ef8006a2bed11a8dcdae815a0ff5`; authoritative `Knight_NE_Reference.png` SHA256 `20d462e69e172785d91a8f2b450b1127ea33f32ebc92b96a7216c20fc85383ba`; original source pixels/palette, 135 traced donor landmark inputs and reviewed calibration; 128x128 cells, 1920x128 horizontal strip, root (64,106), center x64, ground Y107, original projected near/far sole planes; no source mutation.
- Non-goals: No master/rig recovery redo; no replacement donor or reinterpretation as east-facing; no reannotation/recoloring without explicit chat-authored change; no blanket limb-order swap; no unrequested general 3D transformation; no audio/VFX/runtime/Asset V2 promotion; no authoritative FPS.
- Acceptance: Final evidence must show both NE gait crossovers/lead-order changes (2→3 and 7→8), credible weight/support handoffs (6→7 and 13→14), continuous F15→F1, anatomically coherent occlusion/costume and upper-body/robe secondary motion, and any marked alpha gaps explicitly classified. Mechanically preserve 15/15 rendered contact + geometry + continuity, zero IK branch flips, original <=8px fit/adjacent-step, <=60deg adjacent rotation, sole x<=2px/y<=1px, exact lengths, immutable hashes, RGBA palette/bounds. A numeric PASS does not waive human art acceptance. Validate deviations from the accepted five calibration poses and unfiltered donor mapping; never conceal smoothing/boot-pitch costs.
- Validation: Run first `python3 custodian/tools/validation/operator_ne_motion_plan_smoke.py` and `python3 custodian/tools/validation/operator_ne_rigid_raster_smoke.py` (real Aseprite when available), plus focused new negative control for any changed behavior. Run the actual `custodian/tools/operator/ne_walk_retarget/run.py` with the locked NE bundle and rig to an entirely NEW local output directory; require its full report and exact hash/contact/crossover/seam checks. After focused pass run `python3 custodian/tools/validation/run_validation.py --changed --base HEAD --json`, `git diff --check`; check free memory and avoid concurrent broad sweeps. Do not call a failed run successful or weaken existing limits.
- Task overrides: `TASK OVERRIDE: Iteration 006 has completed its review experiment but ART FAILS. Human HOLD before Iteration 007. No automatic retry, IK/gait refit, new artistically chosen mask, source substitution, packet completion, merge/land, Asset V2 runtime promotion or FPS. A fresh ChatGPT-authored and tested script plus exact manifest/register ownership correction is required before any executor work.`
- Deferred: Final source/Workbench/Asset V2 promotion, FPS decision and Godot runtime consumption require separate explicit acceptance/authorization; paired fresh-context engineering review follows land only after user visually approves the complete animation.

## Iteration Register (durable, append only)

| Iteration | Source/branch evidence | Decision | Result |
|---|---|---|---|
| Rig recovery | `8a254e0f1` | Human-accepted source-locked anatomy candidate | 6/6 probes; preserved |
| Five-pose crossover | `65369509d` | Human-accepted for continuity fitting | 5/5 static poses; preserved |
| Cyclic continuity | `2f72765c` | **REVIEWED: needs targeted correction; full animation NOT accepted** | Correct NE donor; 15/15 geometry/contact/continuity. Dropbox numeric/report evidence supports boot-pitch repair and transparency review; full-resolution pixels could not be examined through the connected reader. |
| Iteration 001 | `4f7558f7` · Dropbox `iter-001-pitch-and-gap-audit` | **TECHNICAL PASS; subjective visual judgment PENDING** | 42.41% weighted pitch reduction, 15/15 rendered checks, 2/2 changed-file checks. Original acceptance unchanged; image pixels not inspectable by the connected review reader. |
| Iteration 002 | `c834aa20` · Dropbox `iter-002-reference-sheet-integrity` | **TECHNICAL PASS: review-source identity corrected; aesthetics PENDING** | Verified Knight donor left/Operator candidate right, per-frame pixel hashes, exact unmodified source and output. Corrected sheet SHA256 `adde4812...e9bcfd`. |
| Iteration 003 | `2498949b` · Dropbox `iter-003-visual-byte-bridge` | **VISUAL REVIEW EVIDENCE VERIFIED** | Authentic Knight/Operator contact sheet and alpha closeups inspected; no animation modified. |
| Iteration 004 | `5119bdf0` implementation · `ae346fbf` receipt · Dropbox `iter-004-upper-body-lead-followthrough` | **TECHNICAL PASS; static visual acceptance for continued authoring, final animation PENDING** | 15/15 checks, zero leg drift, 2.736° maximum torso rotation; subtle improved follow-through. F13 alpha diagnostics and dynamic seam/handoffs need final inspection. |
| Iteration 005 | `8413c67f` · Dropbox `iter-005-playback-viewer-syntax-repair` | **TECHNICAL PASS; playback UI functional; subjective gait verdict pending** | Firefox headless 158 zero JS errors, all review controls and 2/8fps playback pass. No animation pixels or source changed. |
| Iteration 006 | `iter-006-silhouette-transplant-r1` · Dropbox 6 files · candidate `066f2c66` | **ART REJECTED, EXPERIMENT COMPLETE** | 18,235 pixel changes; cleaner NE near-leg/apron contours but separate source poses broke validated gait; 14/15 footprint alarms are heuristic and unresolved; uncovered `docs/REFERENCE_MANIFEST.json` validation ownership. |
| Iteration 007 | `not started` | **NOT AUTHORIZED** | ChatGPT must author/test a new motion-anchored region-aware script before Luna executes any changes. |

## Authorized Iteration

- Iteration ID: `iter-007-motion-anchored-art-r2`
- State: `AUTHORIZED MANUAL EXECUTION-ONLY, SINGLE REVIEW CANDIDATE, THEN STOP`
- ZIP: `operator_ne_motion_anchored_cleanup_r2_codex_bundle.zip`; SHA256 `c4de7edd3cefc9f5926533f73b642567db04344090ec75a3aaad19aaf94dbb7a`. User supplies it to Luna. Exact ZIP contents and individual SHA256s live in `docs/R2_PACKAGE_MANIFEST.json`. Refuse any changed member, colliding destination or hash drift. Skip identical previously-extracted source-work PNGs; do not overwrite other files.
- Branch: existing `agent/operator-2-5d-ne-walk-retargeting@8413c67f`; keep retained worktree and claim. Read this canonical latest `origin/main` packet.
- Execute ONLY `bash custodian/tools/operator/ne_walk_retarget/run_silhouette_cleanup_r2.sh` from repository root. No changes by Luna to the ChatGPT-authored algorithm, constants or masks. Do not rerun Iteration 006 or change the original walk, rig, annotations, contact limits or FPS.
- Design contract: R1 direct lower-half donor transplant was REJECTED because it destroyed accepted F05/F12/F13 poses. R2 reads actual Iteration 004 hip/knee/ankle/toe positions per leg; source art comes from the accepted semantic Aseprite near/far thigh, shin, boot and apron parts. It inverse-warps those parts to the *accepted motion* and preserves original planted-sole raster and upper 68 rows. Alternate 15-frame art and idle are read-only contour references, NOT new gait targets. Full details `docs/R2_AUTHORING_SPEC.md` in ZIP.
- Evidence boundary: ChatGPT passed synthetic 15-frame semantic parser, near/far target-warp, exact upper/sole preservation, and wrong-rig negative controls on the original layered fixture. The accepted recovered rig and Iteration004 strip are local to Luna, **NOT actually tested by ChatGPT**. Runner pins accepted rig/strip/report SHA, validates semantic layers and joint attachment max 4.5px; if any gate fails STOP without adjusting code or claiming art success. Output remains REVIEW ONLY.
- Validation: ZIP registers the missing owner for `docs/REFERENCE_MANIFEST.json` as focused `operator_ne_r2_reference_manifest`, verifies four source-work PNG hashes, stages only bundle-owned paths, runs focused tests, changed-file coverage and `git diff --check`. Selected PASS with incomplete file coverage is still FAIL; no Dropbox publish on failures.
- Dropbox: `/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/iter-007-motion-anchored-art-r2/REVIEW_MANIFEST.json`. Exactly six review files including 1920x128 RGBA 15f candidate, all-15 before/after, 10 apron/boot closeups, per-frame motion/contact audit, text-readable authenticated image bridge and notes. Runner owns publishing.
- Luna reports branch SHA, tests/coverage, candidate hash, specific joint/sole diagnostics and manifest; then **STOP** for visual review here. No Iteration 008, landing/main merge, runtime publication, canonical Asset Pipeline V2 normalization, independent closeout or timing approval. Idle-jitter cleanup remains a future separate slice.

## Per-Iteration Engineering Contract (applies after a reviewed authorization)

1. At start, fetch `origin/main` and retained branch/worktree, verify actual checkout/claim before mutation, read this packet and `## Authorized Iteration`; do not re-claim a live workstream, create duplicate branch or reset worktree. Merge/sync only through existing safe lifecycle. STOP if any authority or SHA disagrees.
2. Change **only** named target files from the current authorized delta. `continuity.py` owns temporal IK/fitting, crossover/lead and calibrated pose envelopes; `crossover.py` is the established static donor-to-rig mapper; `motion_plan.py` contains shared length, branch and transition checks; `batch.lua` applies planned transforms; `occlusion.lua` measures owner/robe/sole overlap; `rigid_raster.lua` rasterizes exact source colors; `run.py` owns fail-closed preflight and reporting; `review_viewer.py` owns full-loop inspection. No second competing solver or data authority. Locked donor, accepted rig and original source are **read-only**.
3. For objective regression, report per-frame support/contact, crossover signs and near/far visible pixels, any smoothing/fitted joint/foot-pitch deviation, 15→1 seam, void bounding boxes and source hashes. Diff against the *last human-reviewed* iteration, not a superseded east donor. Do not hide previously failing metrics by changing their definitions.
4. For a subjective visual question, prepare one paired 15-frame NE-donor/Operator contact sheet (1920x128 native strips or compact comparison), **one** self-contained `LOOP_REVIEW.html` with step/loop/overlay and user-selected NON-authoritative preview playback rate, plus an optional five-pose before/after crop, `report.json` and concise `REVIEW_NOTES.md`. Do not upload 15 separate PNGs, Aseprite source, bulk intermediate logs, image duplicates, or videos unless this packet's next delta explicitly justifies the exception.
5. Publish **only via Dropbox** using `custodian/tools/iteration/publish_review_artifacts.py` with `--important --workstream operator-2-5d-ne-walk-retargeting --run-id iter-NNN-<short-purpose> --source <small-curated-review-directory> --max-files 6 --max-keyframes 5 --reason <why subjective review is needed> --question <exact review question>`. Always pass `--authoring-chat https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe` and record that same exact URL in the summary and handoff. Reuse stable workstream root `/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/`; **each run-id must be new**, preserving `LATEST.json` as the latest pointer. Never overwrite another run or use a new unrelated Dropbox folder.
6. Confirm uploader returned a manifest with exact paths and artifact hashes. Commit/push code plus concise summary/receipt **only on the retained branch** with `[skip render]` for non-Render changes; no main landing or runtime publication. Report a minimal response: workstream ID, checkpoint SHA, changed files, focused/broad validation PASS/FAIL, exact Dropbox `REVIEW_MANIFEST.json` path, and three concrete reviewer questions. **STOP and await ChatGPT/user instruction**. Do not self-review images or start next slice.
7. ChatGPT reads the Dropbox uploads through the linked Dropbox source in this authoring conversation, makes/records the human visual decision, and then updates **this same packet** before the next Luna execution. After recording the review verdict and implementation receipt, execute the exact manifest cleanup command (`delete-after-review` unless an iteration explicitly requests retained remote evidence). Keep durable decisions and hashes in Git, not duplicate Dropbox media.
8. If an objective validation fails, report that failure honestly and stop with an actionable diagnostic; do not publish a misleading acceptance claim. If new artistic/architectural choices appear, STOP and request the user/ChatGPT to update this packet; no autonomous scope expansion.

## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe`
- Refresh instruction: `Iteration 006 direct apron/leg swap improved contours but fundamentally changed the accepted animation's gait poses. Do not rerun it. The next script must be authored by ChatGPT and retarget separate near/far legs and apron to the accepted motion landmarks, with true anatomical sole/ankle checks; also close incomplete docs/REFERENCE_MANIFEST.json changed-file owner. Preserve original locked assets, Dropbox review root, no FPS or runtime publication.`

## Next Handoff

- Next workstream: `operator-2-5d-ne-walk-retargeting`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe`
- Summary backlink: `Include the exact Authoring chat URL in every durable implementation, review, correction, recovery, closeout summary and Next Handoff`
- Refresh reason: `NE full-cycle gait, occlusion and secondary-motion acceptance requires human review before specifying further corrections`
- Next action: `ChatGPT designs/writes/tests a motion-anchored component-level cleanup script from original rig + intact Operator references, then amends this same packet with exact package and run command; Luna remains STOPPED.`
- Blockers or open questions: `No motion-preserving cleanup script R2 yet; near/far anatomical donor mapping and apron deformation require correct reference ownership; R1 lost gait/foot alignment; validation_manifest owner for docs/REFERENCE_MANIFEST.json missing; final art, landing, runtime and FPS withheld.`
