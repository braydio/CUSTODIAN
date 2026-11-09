# REVIEW: ISOMETRIC 2.5D PRESENTATION FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-isometric-2-5d-presentation-foundation`
- Kind: `review`
- Status: `blocked`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `isometric-2-5d-presentation-foundation`
- Locks: `world-presentation, presentation-experiments`
- Review: `none`
- Review target workstream: `isometric-2-5d-presentation-foundation`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/ISOMETRIC_2_5D_PRESENTATION_FOUNDATION.md`
- Reviewed main: `3d96a86a6c1957aa9a933e3433ecfba0f27481b0`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Review modes: `code, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Summary backlink: Every durable review/correction/closeout summary for this packet must include `Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4` exactly.
- Goal: Independently verify that the reusable 2.5D foundation makes visual elevation, ground-root sorting, semantic presentation bands, roof occlusion reuse, and contact grounding available without moving any gameplay authority out of the existing 2D runtime.
- Reviewed implementation acceptance: Reuse the implementation packet acceptance. In particular, authoritative ground XY must remain invariant while visual elevation changes; collision/navigation/camera state must remain unchanged; sorting must resolve from the ground/base anchor rather than elevated texture origin; semantic bands must remain presentation metadata rather than a second global depth authority; `RoofOccluder2D` and existing actor shadow authority must be reused rather than duplicated; and no Node3D/Camera3D/CharacterBody3D/3D collision/navigation path may appear.
- Review evidence: Archived foundation packet/summary; `ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`; the landed reusable profile/anchor/helper; focused fixture/smoke; existing `RoofOccluder2D`, BlobShadow and Gothic Compound sort precedents.
- Correction threshold: Any ground-position/collision/navigation mutation caused by presentation elevation, sorting from elevated texture origin, duplicate roof/shadow/depth authorities, unstable ordering, or hidden 3D gameplay migration is correction-worthy. Cosmetic naming or tuning preferences that do not alter the contract are non-blocking.
- Focused validation: Run the foundation smoke first, then inspect one real consumer fixture for ground-position invariance under multiple elevation/band values. Verify effective sort/base behavior rather than only resource existence. Confirm no production scene retrofit was smuggled into the foundation. Run `git diff --check`, packet/review pairing checks, and changed-file validation.
- Review focus: Treat this as a reusable primitive review, not a visual-art taste review. The foundation is ready for downstream Forum/Sundered slices only if it is boring, deterministic, 2D-authoritative infrastructure.
- Acceptance: Findings-first independent review. Blocking defects/material evidence gaps create `isometric-2-5d-presentation-foundation-review-corrections-1` plus paired re-review. A clean/non-blocking pass releases the foundation for downstream consumers. `sundered-keep-overlook-alternate-vertical-slice` may then proceed on its own dependency path; `isometric-2-5d-forum-vertical-slice` remains additionally gated by `operator-2-5d-animation-viability-audit` plus its human/ChatGPT refresh.
- Non-goals: Do not build the Forum or Sundered showcase, create new art, change production camera doctrine, or expand into live 3D.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `isometric-2-5d-presentation-foundation-review-corrections-1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Refresh reason: `none`
- Next action: Claim the bounded sort-anchor correction after this findings review lands and archives; then obtain its fresh paired re-review before downstream consumers proceed.
- Blockers or open questions: The parent foundation remains unaccepted until R0-01 and R0-02 are corrected and re-reviewed.

## Independent Review

- Status: `findings`
- Review workstream: `review-isometric-2-5d-presentation-foundation`
- Reviewed on main: `675ccf726bb79397b7242ef3059971a6f1a39448` (implementation commit `25db20fdcb0715b1b7d85ebc51524c717fb2b7b7`)
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, runtime`
- Blocking defects: `1`
- Material evidence gaps: `1`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `R0-01, R0-02`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_ISOMETRIC_2_5D_PRESENTATION_FOUNDATION_CLAUDE_SUMMARY.md`
- Follow-up workstream: `isometric-2-5d-presentation-foundation-review-corrections-1`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4

### Review Notes

- R0-01 — `blocking_defect`, domain `implementation`, disposition `correction`, affected acceptance: actual draw sorting follows the ground/base anchor and configured sort offset. `isometric_visual_anchor_2d.gd:55-57` adds `profile.sort_anchor_offset` only in `get_sort_world_position()`. `apply_profile()` does not write the offset into Godot's Y-sort input or another renderer-consumed hierarchy value; the repository has no runtime caller of the helper. Thus a profile offset changes the helper's return but cannot change effective draw order. Wire the supported offset component into the real sort authority, with ground position and gameplay unchanged.
- R0-02 — `evidence_gap`, domain `pipeline`, disposition `correction`, affected acceptance: the focused smoke proves actual ordering from ground/base roots. The smoke at lines 72-82 checks `y_sort_enabled`, a helper comparison, and elevation geometry, but it never reads rendered order. Its fixture rear polygon spans world Y 20-60 and front polygon spans Y 90-130, so they do not overlap and cannot reveal which draws on top. Add overlapping distinguishable geometry and an engine-backed/rendered order oracle, including a negative control that fails when effective sort-offset wiring is removed.

- Import/validation evidence: registered `run_validation.py --test isometric_2d_presentation_foundation --json` was blocked during Godot import by `TLS handshake error: -27648`; the direct headless smoke passed (`isometric_2_5d_presentation_foundation_smoke: OK`) but did not cover either finding. Historical changed-file validation against the implementation's parent selected 259 checks (88 passed, 2 failed, 169 skipped; coverage incomplete); failures were the already-observed Operator source-strip baseline assertion and unavailable `websockets` package for `operator_live_bridge`, neither of which resolves these focused review findings.

## Review Outcome

- Schema: `custodian.review_outcome.v1`
- Outcome: `findings`
- Review workstream: `review-isometric-2-5d-presentation-foundation`
- Review target workstream: `isometric-2-5d-presentation-foundation`
- Reviewed main: `675ccf726bb79397b7242ef3059971a6f1a39448`
- Reviewed implementation commit: `25db20fdcb0715b1b7d85ebc51524c717fb2b7b7`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Run ID: `20261017T033653Z-96c8a2cff3ef`
- Review cycle: `0`
- Finding IDs: `R0-01, R0-02`
