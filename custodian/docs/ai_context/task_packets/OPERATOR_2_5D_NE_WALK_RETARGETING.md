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
- Current measured state: R2 accepted motion geometry but rejected final art after F07 distal fragments. ChatGPT-authored SHA-pinned R3 post-composite owner/sole-bridge script passed synthetic motion+negative controls; one real-preview Iteration008 authorized only. R2 remains staged and branch 8413c67f unchanged.
- Evidence: Actual R2 six-artifact Dropbox `/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/iter-007-motion-anchored-art-r2/REVIEW_MANIFEST.json`; candidate SHA256 `51e196c0a6b7dd34a9eb53557ff52528e3ef4cc7bd84b3fab6df8b8cdbc95047`, audit SHA256 `35465c45bad31d5edf557f15e4cad1a044a39396c7a10616c038aa8688accdab`; no new branch commit. Bundle-authored R2 code in prior canonical Iteration 007 Git history.
- Task-specific authority: `design/01_systems/ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`; `custodian/content/data/operator/authoring/operator_art_profile.json`; accepted rig/donor/crossover receipts named above; `custodian/docs/ai_context/VISUAL_REVIEW_HANDOFF.md`.
- Work surface: `custodian/tools/operator/ne_walk_retarget/{continuity.py,crossover.py,motion_plan.py,batch.lua,calibration.lua,occlusion.lua,rigid_raster.lua,review_viewer.py,run.py,annotations.json,README.md}`; focused `custodian/tools/validation/{operator_ne_motion_plan_smoke.py,operator_ne_rigid_raster_smoke.py,operator_ne_rig_master_audit_smoke.py,validation_manifest.json}` only when required.
- Change: Execute only authenticated R3 script/runner without Luna-designed art or IK changes; final composite topology and source sole invariant fail closed.
- Preserve: Exact original `SINGLE_FRAME.aseprite` SHA256 `0f5b3346044e60581db6e38e41fc292bd2b49ca05c291ada9591495765166149`; accepted rig SHA256 `b7002e66df5928a53d4a42e7b74e7bdf82f6ef8006a2bed11a8dcdae815a0ff5`; authoritative `Knight_NE_Reference.png` SHA256 `20d462e69e172785d91a8f2b450b1127ea33f32ebc92b96a7216c20fc85383ba`; original source pixels/palette, 135 traced donor landmark inputs and reviewed calibration; 128x128 cells, 1920x128 horizontal strip, root (64,106), center x64, ground Y107, original projected near/far sole planes; no source mutation.
- Non-goals: No master/rig recovery redo; no replacement donor or reinterpretation as east-facing; no reannotation/recoloring without explicit chat-authored change; no blanket limb-order swap; no unrequested general 3D transformation; no audio/VFX/runtime/Asset V2 promotion; no authoritative FPS.
- Acceptance: Final evidence must show both NE gait crossovers/lead-order changes (2→3 and 7→8), credible weight/support handoffs (6→7 and 13→14), continuous F15→F1, anatomically coherent occlusion/costume and upper-body/robe secondary motion, and any marked alpha gaps explicitly classified. Mechanically preserve 15/15 rendered contact + geometry + continuity, zero IK branch flips, original <=8px fit/adjacent-step, <=60deg adjacent rotation, sole x<=2px/y<=1px, exact lengths, immutable hashes, RGBA palette/bounds. A numeric PASS does not waive human art acceptance. Validate deviations from the accepted five calibration poses and unfiltered donor mapping; never conceal smoothing/boot-pitch costs.
- Validation: Run first `python3 custodian/tools/validation/operator_ne_motion_plan_smoke.py` and `python3 custodian/tools/validation/operator_ne_rigid_raster_smoke.py` (real Aseprite when available), plus focused new negative control for any changed behavior. Run the actual `custodian/tools/operator/ne_walk_retarget/run.py` with the locked NE bundle and rig to an entirely NEW local output directory; require its full report and exact hash/contact/crossover/seam checks. After focused pass run `python3 custodian/tools/validation/run_validation.py --changed --base HEAD --json`, `git diff --check`; check free memory and avoid concurrent broad sweeps. Do not call a failed run successful or weaken existing limits.
- Task overrides: `TASK OVERRIDE: Manual one-run Iteration008, existing workstream/branch, no overwrite of R2 inputs. Exact bundled script and validation, six Dropbox artifacts then STOP. No Iteration009, main landing/archiving, FPS or runtime promotion.`
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
| Iteration 007 | `iter-007-motion-anchored-art-r2` · Dropbox 6 files · candidate `51e196c0` | **MOTION PRESERVATION PASS; ART REJECTED FOR CONTINUITY** | 3,076 changed pixels; accepted skeleton/support and actual planted sole retained; F07 orphan distal pixels and jagged boot/apron outlines remain. Staged tests 46/46 complete; no implementation commit. |
| Iteration 008 | `authorized 2026-10-17` · R3 ZIP `16460864...e221b4` | **EXECUTOR-ONLY POST-COMPOSITE BOOT/SOLE FIX** | ChatGPT-authored final-mask connectivity, synthetic negative controls, six Dropbox review files, STOP. |

## Authorized Iteration

- Iteration ID: `iter-008-boot-continuity-art-r3`
- State: `AUTHORIZED: EXACT R3 SCRIPT EXECUTION ONLY / ONE PREVIEW / HUMAN STOP`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe`
- Source branch: `agent/operator-2-5d-ne-walk-retargeting@8413c67f`; its staged R2 authored scripts/references must stay unchanged. Do not make a new workstream or land main.
- New input ZIP: `operator_ne_boot_continuity_r3_codex_bundle.zip`, SHA256 `164608648271483e4d080eb556034b0de031c6d10cdf3118b2ee264fd9e221b4`; user forwards to Luna. Check all eight archive members and the seven individual file SHA256 entries in `docs/R3_PACKAGE_MANIFEST.json`. All are NEW R3 code/docs paths. Do not overwrite any R2 source-work images, accepted rig, original animation or report. Stop if file collisions or SHA mismatch.
- Execute exactly `bash custodian/tools/operator/ne_walk_retarget/run_silhouette_cleanup_r3.sh` from the repository root. Luna must not modify the authored art algorithm or parameters, choose other art, refit IK, or make multiple candidates.
- Specific correction: The rejected R2 preview `51e196c0a6b7dd34a9eb53557ff52528e3ef4cc7bd84b3fab6df8b8cdbc95047` preserved the valid 15-frame motion but had isolated F07 distal pixels. R3 reproduces that exact R2 preview, follows accepted near/far semantic rig foot/shin owner masks, and bridges anatomical support sole to the main body if separated, only if <=9px distance and <=8 new existing-boot-palette pixels. Also connects strictly bounded novel owner-labeled distal islands in the FINAL composited image, or fails. Exact original source sole pixels, upper 68 rows and original 15-frame motion report are immutable.
- Local verification already performed by ChatGPT: synthetic test passes 15 moving frames with support handoffs, a 4px disconnected-sole repair, wrong sole and missing-anchor negative controls, novel distal island detection/repair, exact R2 hash guard and idempotent R3 validation registration. These are NOT proof of real F07 art quality. If the accepted real rig or F07 needs a larger repair, STOP and return diagnostics; no parameter changes by Luna.
- Source/validation: Stage only authored new R3 scripts, test and docs. The exact runner verifies SHA-pinned existing R2 files, accepted rig, Iteration004 strip/report and R2 candidate, runs the focused tests and changed-file validation with complete coverage, and refuses to publish if checks fail. Existing R2 reference-manifest coverage remains active.
- Dropbox handoff: `/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/iter-008-boot-continuity-art-r3/REVIEW_MANIFEST.json`, exactly six files: 1920x128 15-frame RGBA R3 candidate, full 15-frame R2/R3 comparison, 10 enlarged boot closeups, per-frame `R3_TOPOLOGY_AUDIT.json`, authenticated `REVIEW_PIXELS.json`, notes. Art is REVIEW_ONLY, not runtime-ready. Stop after publishing.
- After success, Luna may checkpoint/commit/push approved staged R2 + exact new R3 files only on retained implementation branch with `[skip render]`; report SHA/coverage/bridge pixels/Dropbox manifest, then STOP. No Iteration009, merge, archive, FPS lock, Asset Pipeline V2 normalized intake or runtime publication.
- Detailed executable spec inside authenticated ZIP: `docs/R3_AUTHORING_SPEC.md` and `docs/R3_EXECUTION.md`.

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
- Refresh instruction: `R2 semantic bone retargeting preserved pose authority and placed soles correctly, but visual crop F07 shows an isolated distal fragment and other boots remain jagged. R2 build_frame validates raw per-part joint distances rather than final composited near/far silhouette; two-row support sole restoration can strand pixels. ChatGPT authors a narrowly scoped R3 compositor/connectivity script with negative controls, then one Dropbox review. No executor design or final motion/FPS/runtime acceptance.`

## Next Handoff

- Next workstream: `operator-2-5d-ne-walk-retargeting`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe`
- Summary backlink: `Include the exact Authoring chat URL in every durable implementation, review, correction, recovery, closeout summary and Next Handoff`
- Refresh reason: `NE full-cycle gait, occlusion and secondary-motion acceptance requires human review before specifying further corrections`
- Next action: `User forwards authenticated R3 ZIP to Luna, who verifies member SHA and executes bash custodian/tools/operator/ne_walk_retarget/run_silhouette_cleanup_r3.sh from repo root; handoff Dropbox manifest then STOP.`
- Blockers or open questions: `Real accepted-rig F07 semantic boot attachment is untested. If bridge >9px, too many new pixels, missing owner, failed coverage or art defect: return to ChatGPT, no override. Runtime/FPS/landing still unapproved.`
