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
- Current measured state: Retained implementation branch `ae346fbf` now has viewer-only Iteration 005 checkpoint `8413c67f`. Repaired generated JavaScript passes node --check and Firefox headless 158 zero-console-error playback controls, including F15→F01 wrap, preview 2/8fps and overlays; all input source and animated frame hashes unchanged. Functional viewer accepted; actual dynamic gait remains unjudged. No Iteration 006, main land, FPS or runtime publication.
- Evidence: `OPERATOR_2_5D_NE_WALK_RETARGETING_CLAUDE_SUMMARY.md` on branch `8413c67f`; current four-file Dropbox handoff `/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/iter-005-playback-viewer-syntax-repair/REVIEW_MANIFEST.json` with generated viewer SHA256 `fedc0ca4...f615117` and Firefox health receipt. Iteration 004 locked animation unchanged.
- Task-specific authority: `design/01_systems/ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`; `custodian/content/data/operator/authoring/operator_art_profile.json`; accepted rig/donor/crossover receipts named above; `custodian/docs/ai_context/VISUAL_REVIEW_HANDOFF.md`.
- Work surface: `custodian/tools/operator/ne_walk_retarget/{continuity.py,crossover.py,motion_plan.py,batch.lua,calibration.lua,occlusion.lua,rigid_raster.lua,review_viewer.py,run.py,annotations.json,README.md}`; focused `custodian/tools/validation/{operator_ne_motion_plan_smoke.py,operator_ne_rigid_raster_smoke.py,operator_ne_rig_master_audit_smoke.py,validation_manifest.json}` only when required.
- Change: Iteration 005 is technically complete. Hold all code/art changes until the user/ChatGPT explicitly judges moving-loop crossover, support handoffs, seam and secondary-motion/alpha. The executor must not infer artistic acceptance from Firefox UI tests.
- Preserve: Exact original `SINGLE_FRAME.aseprite` SHA256 `0f5b3346044e60581db6e38e41fc292bd2b49ca05c291ada9591495765166149`; accepted rig SHA256 `b7002e66df5928a53d4a42e7b74e7bdf82f6ef8006a2bed11a8dcdae815a0ff5`; authoritative `Knight_NE_Reference.png` SHA256 `20d462e69e172785d91a8f2b450b1127ea33f32ebc92b96a7216c20fc85383ba`; original source pixels/palette, 135 traced donor landmark inputs and reviewed calibration; 128x128 cells, 1920x128 horizontal strip, root (64,106), center x64, ground Y107, original projected near/far sole planes; no source mutation.
- Non-goals: No master/rig recovery redo; no replacement donor or reinterpretation as east-facing; no reannotation/recoloring without explicit chat-authored change; no blanket limb-order swap; no unrequested general 3D transformation; no audio/VFX/runtime/Asset V2 promotion; no authoritative FPS.
- Acceptance: Final evidence must show both NE gait crossovers/lead-order changes (2→3 and 7→8), credible weight/support handoffs (6→7 and 13→14), continuous F15→F1, anatomically coherent occlusion/costume and upper-body/robe secondary motion, and any marked alpha gaps explicitly classified. Mechanically preserve 15/15 rendered contact + geometry + continuity, zero IK branch flips, original <=8px fit/adjacent-step, <=60deg adjacent rotation, sole x<=2px/y<=1px, exact lengths, immutable hashes, RGBA palette/bounds. A numeric PASS does not waive human art acceptance. Validate deviations from the accepted five calibration poses and unfiltered donor mapping; never conceal smoothing/boot-pitch costs.
- Validation: Run first `python3 custodian/tools/validation/operator_ne_motion_plan_smoke.py` and `python3 custodian/tools/validation/operator_ne_rigid_raster_smoke.py` (real Aseprite when available), plus focused new negative control for any changed behavior. Run the actual `custodian/tools/operator/ne_walk_retarget/run.py` with the locked NE bundle and rig to an entirely NEW local output directory; require its full report and exact hash/contact/crossover/seam checks. After focused pass run `python3 custodian/tools/validation/run_validation.py --changed --base HEAD --json`, `git diff --check`; check free memory and avoid concurrent broad sweeps. Do not call a failed run successful or weaken existing limits.
- Task overrides: `TASK OVERRIDE: Human motion review HOLD after Iteration 005. Packet stays draft/manual. No automated dispatch, Iteration 006, source/art modifications, Aseprite render, workstream finish, merge/land, runtime promotion or FPS lock. Preserve implementation branch and Dropbox provenance; do not force-push/reset.`
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
| Iteration 006 | `not started` | **NOT AUTHORIZED** | Await actual moving-loop art verdict before any file-level changes. |

## Authorized Iteration

- Iteration ID: `pending-006`
- State: `HOLD / NO IMPLEMENTATION OR ART CHANGES AUTHORIZED`
- Review authority: This authoring chat `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe`.
- Last executed work: `agent/operator-2-5d-ne-walk-retargeting@8413c67f6e12b0044b2eb85c9faf0494c6b661b5`; exact Dropbox `/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/iter-005-playback-viewer-syntax-repair/REVIEW_MANIFEST.json`. This manifest's `git.commit=ae346fbf` identifies the baseline before the viewer-only correction; the final branch tip is `8413c67f`. Do not rewrite the manifest provenance or claim that its commit points to the final correction.
- Review verdict (2026-10-17): **Iteration 005 viewer technical PASS; subjective 15-frame dynamic animation acceptance PENDING.** The Python/JS template newline syntax error is fixed; repaired generated HTML SHA256 `fedc0ca4cb3ba4d17d11257b175b9b16e3172c5cad9287f463e4fa825f615117`. `VIEWER_HEALTH.json` SHA256 `f6b5573330a2f5e652382c9fda3c22261ab0c10663693a63a8c2452aec5738f5` verifies genuine `node --check` on extracted generated JS, regression negative control, Firefox headless 158.0 zero console errors, nonblank/distinct Knight and Operator canvases plus 240px detail, Previous/Next/arrow keys, F15→F01 wrap, alpha and pitch toggles, unset-rate guard, 2fps/8fps rate playback and Pause. This is tool functionality evidence, **not a perceptual gait verdict**.
- Immutable animation: Iteration 004 donor SHA256 `20d462e69e172785d91a8f2b450b1127ea33f32ebc92b96a7216c20fc85383ba`, Operator strip `e06daea3f55b6bb8c2787b5874978a72644a7607f0eb37519c03828b3b61bb6a`, report `88aa6469a76b986d0d3ccd2592dfed62903b5461ebe3e6e25c0fdb7f9519e83a`; original/rig/annotation acceptance retained. No Aseprite, solver, gait, source image, timing or FPS changes in Iteration 005. Earlier 15/15 mechanical PASS, zero leg drift, torso max 2.736°, adjacent 1.115°, torso seam 0.977° remain baseline evidence.
- Visual state: Previously inspected all-15 genuine Knight/Operator static sheet and 6-frame before/after torso images, with leg crossover and static alpha accepted for continued authoring. **Do not upgrade these still-image findings to approval of playback.** This session could inspect the latest Dropbox browser-health JSON and preview metadata, but the connector's HTML text extraction strips executable script and does not enable observing the loop in motion. The headless browser smoke is not a human motion review. Therefore (1) F05/F12 excursion readability through time, (2) F06→F07 and F13→F14 visible weight transfer, (3) F15→F01 rhythmic seam, and (4) late-cycle robe/hood and F13 small alpha negative space during playback are still **not determined**.
- Required next action, **no code**: Open the already-published repaired `LOOP_REVIEW.html` locally in Firefox, select illustrative review-only 2fps and 8fps, inspect each highlighted transition and loop several times, then supply the user/ChatGPT frame-specific visual observations in this chat. If the user wants ChatGPT to make the complete dynamic perceptual verdict instead of reporting their observations, provide a directly inspectable motion recording while keeping its source/upload within this SAME Dropbox workstream review root, with unique evidence run ID, source-hash provenance, no rerender, no timing authority; that requires a separate narrow packet amendment first. Do not automatically authorize a sixth iteration or request a new tool solely to produce another green test.
- Hold: Luna remains stopped. No rerender, source/rig/source-sprite edits, animation changes, new Dropbox bundle, Iteration 006, main merge/land, workstream closeout/archive, independent post-land review, Asset V2 promotion, Godot runtime wiring or authoritative FPS until human review records a concrete decision. Prior Dropbox evidence stays until review closure and the standard delete-after-review cleanup receipt are coordinated.


## Prior iteration evidence (read only)

- Rig and five-pose calibration accepted at `8a254e0f1` / `65369509d`.
- Iteration 001 pitch improvement at `4f7558f7` (15/15, 42.41%, visual acceptance held).
- Iteration 002 donor pairing fixed at `c834aa20`, SHA256 `adde4812e067e8f39c38fc2eab34187e0d798db8af809c31f1dd80c743e9bcfd`.
- Iteration 003 visual transport at `2498949b`, manifest `/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/iter-003-visual-byte-bridge/REVIEW_MANIFEST.json`. Original full detailed instructions remain in Git history. Do not rerun completed iterations.

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
- Refresh instruction: `Viewer-only Iteration 005 is technically complete at branch 8413c67f. Use the fixed Dropbox LOOP_REVIEW.html or the corresponding local file to inspect real playback. Distinguish 2/8fps review-rate tests from gameplay FPS. Record frame-specific aesthetic observations (both crossovers, F6/7 F13/14, F15/1, F10–14 and F13 void) before authorizing any new implementation. Art and runtime remain unaccepted.`

## Next Handoff

- Next workstream: `operator-2-5d-ne-walk-retargeting`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe`
- Summary backlink: `Include the exact Authoring chat URL in every durable implementation, review, correction, recovery, closeout summary and Next Handoff`
- Refresh reason: `NE full-cycle gait, occlusion and secondary-motion acceptance requires human review before specifying further corrections`
- Next action: `Open the repaired Iteration 005 Dropbox LOOP_REVIEW.html locally for actual visual playback; user/ChatGPT records specific motion verdict, then this packet can authorize the next exact correction if needed. Luna stays STOPPED.`
- Blockers or open questions: `Dynamic perceptual review still pending; UI works but headless controls do not establish gait aesthetics. No final animation/FPS/main landing/runtime acceptance.`
