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
- Current measured state: Existing active branch `agent/operator-2-5d-ne-walk-retargeting@2f72765c79a7fb1f4583c654b1eedec92b71da87`. Human-accepted rig and five-pose crossover calibration are locked. Correct-NE-donor cyclic continuation now renders 15/15 geometry/contact/continuity frames and 11/11 changed-file checks, but *full-loop visual acceptance is pending*. Six formerly failing transitions now pass numerically. F12/F15 fitted near-joint changes exceed 5px; frame 5 has 21 visible far-leg pixels and F7 has two visible far-sole pixels. Boot-pitch cap and enclosed transparency remain visual review items. These measurements are not blanket animation approval.
- Evidence: `OPERATOR_2_5D_NE_WALK_RETARGETING_CLAUDE_SUMMARY.md` at active branch tip; `custodian/tools/operator/ne_walk_retarget/{CROSSOVER_CORRECTION_BRIEF.md,README.md,crossover_acceptance.json,donor_authority.json,rig_acceptance.json}`; current Dropbox review `/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/v6-crossover-continuity-loop-r1/REVIEW_MANIFEST.json`.
- Task-specific authority: `design/01_systems/ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`; `custodian/content/data/operator/authoring/operator_art_profile.json`; accepted rig/donor/crossover receipts named above; `custodian/docs/ai_context/VISUAL_REVIEW_HANDOFF.md`.
- Work surface: `custodian/tools/operator/ne_walk_retarget/{continuity.py,crossover.py,motion_plan.py,batch.lua,calibration.lua,occlusion.lua,rigid_raster.lua,review_viewer.py,run.py,annotations.json,README.md}`; focused `custodian/tools/validation/{operator_ne_motion_plan_smoke.py,operator_ne_rigid_raster_smoke.py,operator_ne_rig_master_audit_smoke.py,validation_manifest.json}` only when required.
- Change: Implement **only** the exact next-iteration file/behavior/test delta in `## Authorized Iteration` below after ChatGPT/user updates that section. Luna is the executor, not the owner of artistic interpretation, next-iteration scope, source selection, or acceptance. Reuse existing solvers and evidence machinery; no speculative new system.
- Preserve: Exact original `SINGLE_FRAME.aseprite` SHA256 `0f5b3346044e60581db6e38e41fc292bd2b49ca05c291ada9591495765166149`; accepted rig SHA256 `b7002e66df5928a53d4a42e7b74e7bdf82f6ef8006a2bed11a8dcdae815a0ff5`; authoritative `Knight_NE_Reference.png` SHA256 `20d462e69e172785d91a8f2b450b1127ea33f32ebc92b96a7216c20fc85383ba`; original source pixels/palette, 135 traced donor landmark inputs and reviewed calibration; 128x128 cells, 1920x128 horizontal strip, root (64,106), center x64, ground Y107, original projected near/far sole planes; no source mutation.
- Non-goals: No master/rig recovery redo; no replacement donor or reinterpretation as east-facing; no reannotation/recoloring without explicit chat-authored change; no blanket limb-order swap; no unrequested general 3D transformation; no audio/VFX/runtime/Asset V2 promotion; no authoritative FPS.
- Acceptance: Final evidence must show both NE gait crossovers/lead-order changes (2→3 and 7→8), credible weight/support handoffs (6→7 and 13→14), continuous F15→F1, anatomically coherent occlusion/costume and upper-body/robe secondary motion, and any marked alpha gaps explicitly classified. Mechanically preserve 15/15 rendered contact + geometry + continuity, zero IK branch flips, original <=8px fit/adjacent-step, <=60deg adjacent rotation, sole x<=2px/y<=1px, exact lengths, immutable hashes, RGBA palette/bounds. A numeric PASS does not waive human art acceptance. Validate deviations from the accepted five calibration poses and unfiltered donor mapping; never conceal smoothing/boot-pitch costs.
- Validation: Run first `python3 custodian/tools/validation/operator_ne_motion_plan_smoke.py` and `python3 custodian/tools/validation/operator_ne_rigid_raster_smoke.py` (real Aseprite when available), plus focused new negative control for any changed behavior. Run the actual `custodian/tools/operator/ne_walk_retarget/run.py` with the locked NE bundle and rig to an entirely NEW local output directory; require its full report and exact hash/contact/crossover/seam checks. After focused pass run `python3 custodian/tools/validation/run_validation.py --changed --base HEAD --json`, `git diff --check`; check free memory and avoid concurrent broad sweeps. Do not call a failed run successful or weaken existing limits.
- Task overrides: `TASK OVERRIDE: Explicit iterative human visual hold. Every coding iteration must checkpoint only the retained agent branch, publish its compact visual evidence to Dropbox, then STOP. Do not call workstream.py finish, merge/land to main, promote source/runtime art, approve timing, self-approve subjective visual quality, auto-claim another task, or autonomously begin another iteration while a ChatGPT/user visual decision is pending. Keep required lifecycle/dispatch/validation safety gates; no force-push, reset, or checkout overwrite.`
- Deferred: Final source/Workbench/Asset V2 promotion, FPS decision and Godot runtime consumption require separate explicit acceptance/authorization; paired fresh-context engineering review follows land only after user visually approves the complete animation.

## Iteration Register (durable, append only)

| Iteration | Source/branch evidence | Decision | Result |
|---|---|---|---|
| Rig recovery | `8a254e0f1` | Human-accepted source-locked anatomy candidate | 6/6 probes; preserved |
| Five-pose crossover | `65369509d` | Human-accepted for continuity fitting | 5/5 static poses; preserved |
| Cyclic continuity | `2f72765c` | **AWAITING ChatGPT/user visual decision** | Correct NE donor, 15/15 numeric, no final art approval |
| Next iteration | `none` | **NOT AUTHORIZED** | Author exact delta here after review |

## Authorized Iteration

- Iteration ID: `pending-human-visual-review`
- State: `HOLD / NO CODE CHANGES AUTHORIZED`
- Current evidence root: `/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/`
- Active review manifest: `/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/v6-crossover-continuity-loop-r1/REVIEW_MANIFEST.json`
- Review questions: Does the entire NE cycle keep both leg crossovers and readable opposite lead (especially F05)? Are 6→7 and 13→14 support handoffs visually credible? Are F12/F15 fitted-pose changes, F15→1 seam, upper body/robe and bounded transparent regions acceptable?
- Luna's only authorized immediate action: read this packet + current branch, verify evidence and **STOP**, returning the exact Dropbox manifest path. Do not implement guessed corrections or regenerate the same evidence while awaiting the decision.
- Next authorization: ChatGPT/user records the actual verdict here and replaces this hold with a numbered, file-specific delta, exact regression, maximum evidence budget and stop condition. Resume same workstream/branch; no new task packet per iteration.

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
- Refresh instruction: `The current complete NE walk is technically validated but human visual acceptance is pending on the linked Dropbox manifest. Bring the manifest/metrics to this chat, resolve each visual defect, append the iteration decision and exact patch to this packet, then authorize one more execution. The human controls timing, merge and publication separately.`

## Next Handoff

- Next workstream: `operator-2-5d-ne-walk-retargeting`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe`
- Summary backlink: `Include the exact Authoring chat URL in every durable implementation, review, correction, recovery, closeout summary and Next Handoff`
- Refresh reason: `NE full-cycle gait, occlusion and secondary-motion acceptance requires human review before specifying further corrections`
- Next action: `Read v6-crossover-continuity-loop-r1 from the stable Dropbox workstream review root, record visual decision, and edit Authorized Iteration with a precise file-level delta`
- Blockers or open questions: `Current animation has no human full-loop acceptance; no subsequent implementation authorized`
