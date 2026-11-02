# REVIEW: AWAKENING HANDOFF READINESS + ART CONVERGENCE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-awakening-handoff-readiness-art-convergence-v1`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `awakening-handoff-readiness-art-convergence-v1-r1`
- Locks: `awakening-runtime, awakening-art-registration`
- Review: `none`
- Review target workstream: `awakening-handoff-readiness-art-convergence-v1-r1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AWAKENING_HANDOFF_READINESS_ART_CONVERGENCE_V1.md`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Correction threshold: A confirmed acceptance defect or material evidence gap; the subjective 04/05 composition remains governed by the prior user lock.
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `c298b1da2d5730d3e84ad6780655584298a369b9`
- Goal: Independently verify the landed Awakening convergence slice against its registration, seam, progression, asset-consumption, and South Reach handoff-readiness contract.
- Review focus: Exact Layout-to-art registration; no speculative resizing; preservation of the reviewed direct-source 04→05 connector canvas/transform without source cropping; preservation of the reviewed interaction prompt/readout lifetime and once-only Crèche console activation contract; preservation of the reviewed one-passage 05→06 lower→upper spine; machine seam metrics and compact ROI evidence for late joins rather than repeated full-frame review; Road/Approach join; Gate pylon alignment and central-body non-collision decision; exactly-once console+P-9 completion; production-named handoff seam without scene transition; no duplicate fixture rendering; no Contract prewarm; documentation truth.
- Acceptance: Produce a findings-first independent review of live `main`. Either record a clean `passed` receipt or concrete findings. Blocking findings create the bounded correction pair through the normal review lifecycle. Do not patch reviewed implementation/runtime code inside this review workstream.
- Non-goals: Do not implement the Hub, change Twin Solaria gameplay, create missing P1 art, redesign the Layout, enlarge Gate center collision, or add procgen/startup work during review.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Required Review Evidence

1. Recompute all nine zone art rectangles from live Layout envelopes and live scene sprites; prove exact `grow(64)` registration and underlay/foreground parity.
2. Prove the 04→05 runtime state is the reviewed exact-source `full_plate_underlay`, with canvas and world transform matching the archived direct-connector correction evidence. Prove all nontransparent `connector.png` silhouette survives and neither the rejected 832×384 plate nor legacy crop-derived 1024×576 registration remains live.
3. Reuse the implementation's committed registration report, runtime presentation probes, seam-metrics JSON, ordered capture manifest, and generated late-seam ROI images. Verify that the implementation recorded completion of the required human kitty/xdg-open review sequence. Do not perform a second subjective model-vision acceptance pass; only inspect/regenerate imagery if evidence is missing, stale, contradictory, or changed after human approval.
4. Verify the reviewed Awakening interaction prompt contract still holds: actionable targets remain continuously visible, readout/confirmation text retains its >=4.0s dwell, context/modal suppression clears it, and the exact existing 8-frame/8 FPS Crèche activation FX remains consumed and once-only.
5. Verify the reviewed 05→06 semantic passage remains one continuous 128×96 route from Dust Lung into Undergate and that a real Operator can continue through the mandatory later-half route without teleport/loading or presentation occlusion.
6. Verify the Approach/Road seam uses the existing Road offset, y=-6144 anchor, 192 px south gap, and presentation-only correction if any correction was needed.
7. Verify Gate west/east pylon blockers remain 240×496 and the central visual-route mismatch was not “fixed” by blocking the route.
8. Exercise South Reach before console acknowledgment, after console but before P-9, and after both. Only the final case may complete.
9. Prove the production-named completion event emits once and any retained `blockout_completed` compatibility emission comes from the same authority.
10. Prove no scene change, Hub transition, Twin transition, or Contract generation is added.
11. Reconcile the live generated asset catalog with the documented BAKED_ONLY / specialized / partial / unpublished classifications.
12. Confirm CURRENT_STATE and related docs no longer describe rejected connector registrations or missing Road art as current truth.
13. Confirm existing Awakening geometry/progression, Road production, asset-pipeline, and changed-file validation remain green.
14. Verify the coding agent, not the user, launched the ordered kitty/xdg-open sequence and blocked final closeout until it completed. If relevant art/registration changed after that gate, require regenerated captures and a new human sequence. Escalate only genuinely subjective Gate/art-composition questions.

## Human Decision Gate

Closing each review kitty window in the implementation workstream is the user's per-capture approval/advance signal. The paired review agent should validate the durable evidence of that gate, not substitute its own visual judgment.

If the central Gate sealed-body composition still visually hides a legal Operator position and the only credible fix requires a different authored Gate state/composition, record that exact evidence as `human_required`. Do not invent art or move collision.

Aesthetic preferences beyond objective seam/registration correctness are not automatic review failures.

## Handoff

- Next workstream: `awakening-handoff-readiness-art-convergence-v1-r1-review-corrections-1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a`
- Refresh reason: `none`
- Next action: Claim the bounded validation/contract correction after this review lands and archives, then obtain its fresh paired review before the Awakening→Hub integration packet proceeds.
- Blockers or open questions: `R0-01` must be resolved; preserve the approved 04/05 composition unchanged.

## Independent Review Result

- Status: `findings`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Blocking defects: `0`
- Material evidence gaps: `1`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `R0-01`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Human visual lock: Satisfied by the archived fade-repair packet's explicit 1502×2048/root/order lock and the current user's instruction. The five compact ROI captures were reused without agent vision or a second subjective review. No UI sequence was attempted; `kitty` is unavailable.

### Findings

- **R0-01 — `evidence_gap`, domain `implementation`, disposition `correction`.** Affected acceptance: review acceptance #1 (derive all zone art rectangles from Layout and prove exact grow64 registration and underlay/foreground parity). `awakening_art_registration_smoke.gd` checks only zones 01–03 and 06–09 as standalone plates using hard-coded expected values. It does not derive their rectangles from `AwakeningLayout.ZONES`. Zones 04/05 are checked as the active shared composition, but no consolidated test/report states their explicit approved exception, hidden legacy plate status, and intentional Locker foreground deferral alongside the seven grow64 pairs. `awakening_04_05_registered_composition_v1.json` proves the accepted shared composition's source hashes, alpha bounds/overlaps, root transform, and 1,025 floor samples; it does not prove the acceptance's all-zone registration/parity statement. Existing `awakening_first_return_smoke.gd` hard-codes 1502×2048 legacy textures for Zones04/05, confirms they are hidden, and confirms the Locker foreground is deferred. The accepted prior human lock makes the shared composition an intentional exception; it does not resolve the missing exact machine-checkable contract. Correction pair: `awakening-handoff-readiness-art-convergence-v1-r1-review-corrections-1` and its paired review.

### Verification

- Passed after one headless editor import in this fresh worktree: `awakening_art_registration`, `awakening_first_return`, `awakening_first_return_geometry`, `awakening_first_return_progression`, `awakening_registered_composition_traversal`, `awakening_connector_asset_contract`, `road_of_witnesses_production`, and `hud_interaction_prompt_lease`.
- The first cold-cache registration run failed because the fresh worktree had no imported `.ctex` resources or initialized global-class cache. After editor import, the focused test passed. Only the nine generated untracked Operator reference `.import` sidecars are disposable validation output; they are excluded from the review commit.
- Committed seam evidence is present and internally ordered 01–05: five 400×200 ROIs, corresponding metrics, contact sheet, manifest source run `20261009T112518-0400`; every ROI reports zero void ratio and no detected matte color. The discontinuity values remain diagnostic, with no threshold claiming aesthetic approval.
- Production completion/snapshot and legacy emission share one guarded decision; the progression smoke verifies prereq cases, exactly-once event+compatibility, and no Node reference. Interaction readout dwell/suppression is covered by `hud_interaction_prompt_lease`; Crèche activation remains 8 frames at 8 FPS and once-only in progression coverage. Road, pylon and central route geometry checks pass. Live source contains no Hub transition or Contract prewarm path.
- The live asset ledger distinguishes BAKED_ONLY/specialized/published-but-unbound/unpublished families; active current-state docs call Road modules live and point to the reviewed direct-source connector registration. The stale manual Awakening README section that still described the earlier fade repair as active was removed. Old rejected transforms occur only in explicitly historical/superseded records.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes` (independent review completed with findings)
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes` (review receipt and bounded correction/re-review pair are complete; target acceptance remains pending R0-01)
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: Findings-first review, seven core Awakening/asset checks plus Road and HUD focused validation, recorded human-lock evidence, compact seam artifacts, source/runtime inspection, and paired correction/re-review packet preflight.
- Deferred work: R0-01 correction and fresh paired review.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `low`
- What went wrong: The first registration run used a cold worktree and failed before meaningful assertions because imported assets/global classes were not initialized.
- Root cause / contributing factors: Fresh Godot worktrees have no project import/class cache; the validation recipe assumes one exists.
- Prevention / pipeline improvement: Run one headless editor import before focused Godot checks in a fresh worktree, then remove only exact untracked generated `.import` sidecars.
- Tooling / docs drift discovered: R0-01 is the remaining material registration-proof gap. Repository-wide `check_ai_context.py` reports 10 unrelated findings in `ASH_BELL_RITUALANT_STATIC_ASSET_INTAKE.md`; those were left untouched.
- Follow-up: `awakening-handoff-readiness-art-convergence-v1-r1-review-corrections-1`
- What worked: Existing structured evidence avoided any subjective image adjudication.
