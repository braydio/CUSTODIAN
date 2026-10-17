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
- Current measured state: Retained branch `agent/operator-2-5d-ne-walk-retargeting@ae346fbf` completed Iteration 004. 15/15 rendered checks and 2/2 changed-file validation passed; 0px leg geometry changed. Updated torso max 2.736°, step 1.115°, seam 0.977°. Static art accepted for continued authoring (subtle benefit), but actual moving-loop weight transfer/seam and F13 alpha cluster remain unapproved. NO Iteration 005, main land, runtime publication or FPS.
- Evidence: `OPERATOR_2_5D_NE_WALK_RETARGETING_CLAUDE_SUMMARY.md` at retained branch `ae346fbf`; latest six-artifact Dropbox review `/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/iter-004-upper-body-lead-followthrough/REVIEW_MANIFEST.json` bound to implementation commit `5119bdf0`; earlier source authenticity verified in Iterations 002/003. Original rig/donor/annotation receipts unchanged.
- Task-specific authority: `design/01_systems/ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`; `custodian/content/data/operator/authoring/operator_art_profile.json`; accepted rig/donor/crossover receipts named above; `custodian/docs/ai_context/VISUAL_REVIEW_HANDOFF.md`.
- Work surface: `custodian/tools/operator/ne_walk_retarget/{continuity.py,crossover.py,motion_plan.py,batch.lua,calibration.lua,occlusion.lua,rigid_raster.lua,review_viewer.py,run.py,annotations.json,README.md}`; focused `custodian/tools/validation/{operator_ne_motion_plan_smoke.py,operator_ne_rigid_raster_smoke.py,operator_ne_rig_master_audit_smoke.py,validation_manifest.json}` only when required.
- Change: Iteration 004 implemented and statically reviewed; no further code change authorized. Keep Luna executor-only; ChatGPT/user decides the next exact implementation after moving-loop and F13 close-up inspection.
- Preserve: Exact original `SINGLE_FRAME.aseprite` SHA256 `0f5b3346044e60581db6e38e41fc292bd2b49ca05c291ada9591495765166149`; accepted rig SHA256 `b7002e66df5928a53d4a42e7b74e7bdf82f6ef8006a2bed11a8dcdae815a0ff5`; authoritative `Knight_NE_Reference.png` SHA256 `20d462e69e172785d91a8f2b450b1127ea33f32ebc92b96a7216c20fc85383ba`; original source pixels/palette, 135 traced donor landmark inputs and reviewed calibration; 128x128 cells, 1920x128 horizontal strip, root (64,106), center x64, ground Y107, original projected near/far sole planes; no source mutation.
- Non-goals: No master/rig recovery redo; no replacement donor or reinterpretation as east-facing; no reannotation/recoloring without explicit chat-authored change; no blanket limb-order swap; no unrequested general 3D transformation; no audio/VFX/runtime/Asset V2 promotion; no authoritative FPS.
- Acceptance: Final evidence must show both NE gait crossovers/lead-order changes (2→3 and 7→8), credible weight/support handoffs (6→7 and 13→14), continuous F15→F1, anatomically coherent occlusion/costume and upper-body/robe secondary motion, and any marked alpha gaps explicitly classified. Mechanically preserve 15/15 rendered contact + geometry + continuity, zero IK branch flips, original <=8px fit/adjacent-step, <=60deg adjacent rotation, sole x<=2px/y<=1px, exact lengths, immutable hashes, RGBA palette/bounds. A numeric PASS does not waive human art acceptance. Validate deviations from the accepted five calibration poses and unfiltered donor mapping; never conceal smoothing/boot-pitch costs.
- Validation: Run first `python3 custodian/tools/validation/operator_ne_motion_plan_smoke.py` and `python3 custodian/tools/validation/operator_ne_rigid_raster_smoke.py` (real Aseprite when available), plus focused new negative control for any changed behavior. Run the actual `custodian/tools/operator/ne_walk_retarget/run.py` with the locked NE bundle and rig to an entirely NEW local output directory; require its full report and exact hash/contact/crossover/seam checks. After focused pass run `python3 custodian/tools/validation/run_validation.py --changed --base HEAD --json`, `git diff --check`; check free memory and avoid concurrent broad sweeps. Do not call a failed run successful or weaken existing limits.
- Task overrides: `TASK OVERRIDE: Human visual hold after Iteration 004. Status draft/manual; no auto dispatch, claim, rerender, parameter sweep, Iteration 005, packet finish/land, runtime promotion or FPS decision. Source locks and retained branch preserved; no force-push/reset. ChatGPT/user must amend Authorized Iteration after next visual verdict.`
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
| Iteration 005 | `not started` | **NOT AUTHORIZED** | Await recorded moving-loop visual verdict and frame-specific change request. |

## Authorized Iteration

- Iteration ID: `pending-005`
- State: `HOLD / NO IMPLEMENTATION OR ART CHANGES AUTHORIZED`
- Review authority: This exact authoring chat `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe`.
- Last executed implementation: `agent/operator-2-5d-ne-walk-retargeting@ae346fbf9ff0f4b273af98254eb5b79529a79f51`, implementation code commit `5119bdf07bf1dba52f167653ed52791043a32e1c`. Evidence `/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/iter-004-upper-body-lead-followthrough/REVIEW_MANIFEST.json`; accurate manifest git pointer is `5119bdf0`, later `ae346fbf` is the receipt-only checkpoint.
- Human visual decision, 2026-10-17: **Iteration 004 technical PASS, static visual ACCEPTED for continued authoring only; full 15-frame motion NOT accepted.** The authenticated donor/Operator grid and F02/F05/F07/F11/F12/F13 original/candidate comparisons were inspected. The `base_angle - 0.75 * normalized_stride` torso/hood/arm response is coherent and does not visibly harm the accepted stride but its artistic improvement is subtle, not proof of finished upper-body game feel. F10–F13 did not acquire any blatant torso/arm disconnection in the static sheet. Original versus candidate leg geometry is exactly unchanged 0px; 15/15 contacts/continuity, support identities and crossover signs remain PASS. Numeric torso maximum 2.7362476° <=3°, largest adjacent step 1.1146091° <=2°, seam 0.9770249° <=1°. Focused and changed-file checks passed per executor receipt (2/2 changed checks).
- Support/seam status: F06→F07 and F13→F14 still only **structurally credible, dynamic not accepted**; F15→F01 torso step passes but is close to its 1° limit, and inherited near-toe 15→1 step 7.6px is close to existing 8px bound. Neither passing threshold establishes perceptually smooth playback at any specific FPS.
- Transparency status: Previous Iteration 001 candidate max enclosed alpha 13px, new Iteration 004 max 17px (F13). F13 largest component 13px, bounding box `[74,69,79,77]`, near front torso/arm edge; F11 8px and F12 12px. This remains **UNCLASSIFIED visually**, NOT an authorized defect/repaint. Existing magnified overlays sometimes exaggerate tiny bbox regions, so any classification must use unadorned actual pixels or outlines scaled to exact bbox dimensions.
- Current pending review: Open the existing `LOOP_REVIEW.html` in the **same Iteration 004 Dropbox bundle** and use user-selected, explicitly NON-authoritative preview playback rates to judge F06/07 and F13/14 perceived weight transfer, F15→01 loop recovery, F10–13 torso response, and F13 front torso/arm pixel separation. Review recorded here must say which frame/transition fails and why before another art iteration is authorized. No new reference, source ingestion or output required for this review. If connected tools cannot play motion, do NOT infer motion acceptance from static art or scalar thresholds.
- Mandatory stop: Luna must not run Iteration 004 again, generate Iteration 005, change any tracked source, clean the just-reviewed manifest before its durable decision/cleanup are coordinated, land/merge, archive, promote assets to runtime or choose FPS. After the next **specific** human visual/playback findings, ChatGPT will update this exact block with new file-level changes or a final closeout plan. Paired independent review stays dormant until actual land.

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
- Refresh instruction: `Iteration 004 has passed mechanical and static comparison review; the added torso motion is subtle and acceptable for continued authoring. Open the existing Dropbox LOOP_REVIEW.html and judge both support handoffs, 15→1 seam, F10–13 motion and F13 front torso/arm alpha pixels at user-selected preview rates. Record findings here. Do not authorize another code pass without precise visual evidence or accept animation timing by selecting preview FPS.`

## Next Handoff

- Next workstream: `operator-2-5d-ne-walk-retargeting`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe`
- Summary backlink: `Include the exact Authoring chat URL in every durable implementation, review, correction, recovery, closeout summary and Next Handoff`
- Refresh reason: `NE full-cycle gait, occlusion and secondary-motion acceptance requires human review before specifying further corrections`
- Next action: `Human reviews existing Iteration 004 Dropbox LOOP_REVIEW.html playback and F13 arm/torso gap; records frame-specific verdict in this exact chat. Luna remains STOPPED until the same packet is amended.`
- Blockers or open questions: `Dynamic handoff/seam and torso follow-through acceptance; F13 alpha component classified only as unresolved diagnostic; final animation, FPS, merge, packet archive and runtime publication remain withheld.`
