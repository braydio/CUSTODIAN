# REVIEW: CARROW YARD VOLUMETRIC PERIMETER

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-carrow-yard-volumetric-perimeter`
- Kind: `review`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `carrow-yard-volumetric-perimeter`
- Locks: `none`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review target workstream: `carrow-yard-volumetric-perimeter`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/CARROW_YARD_VOLUMETRIC_PERIMETER.md`
- Reviewed main: `b3f320b9829972411c15060c55d1536eaa1b0c32`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad5eb5a-598c-83ea-b982-531d4ff5418f`
- Visual review: `required`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Independently falsify the three Carrow perimeter modules' projection, source-to-runtime identity, alpha, seam, registration, family contract and lifecycle claims after the implementation reaches a reviewable landing.
- Review target acceptance: `A1-A8` in the implementation packet.
- Review evidence: Exact implementation SHA; source hashes and alpha report; geometry/connector measurements; repeated-straight and corner seam pixel report; actual Operator/Camera2D native-scale captures; Asset V2 plan/status/doctor outputs; prior seven-source reconciliation; human visual approval receipt if claimed.
- Correction threshold: Any doubled/broken join, mismatched projection or scale, walkway under four clear cells, alpha matte/halo, unsupported final dimensions, missing source provenance, live intake without human approval, false production-ready state, or gameplay collision/navigation authority leak blocks PASS.
- Focused validation: Re-run the listed structural/pixel checks and preview smoke against the exact reviewed SHA; inspect no more than the two durable review captures unless they are stale or insufficient; run Asset V2 plan/status/doctor and changed-file validation. Treat human visual approval as a separate owner decision.
- Acceptance: Findings-first independent review. PASS only if technical acceptance is evidenced and all source/family lifecycle claims are truthful. The reviewer does not approve aesthetics or infer user approval.
- Non-goals: Modify the implementation, generate replacement art, approve the camera or art direction, authorize elevated navigation, or alter unrelated Carrow sources.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Blockers

- Do not claim until the implementation is complete, lands, and archives its packet. Current candidate seams and game-grid registration fail, so no PASS is available.
- Human review owns subjective art/camera approval; do not infer approval from a renderer capture or technical green state.

## Next Handoff

- Next workstream: `none`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad5eb5a-598c-83ea-b982-531d4ff5418f`
- Refresh reason: `A fresh implementation context must resolve the detailed art and connector defects and receive human visual approval before intake.`
- Next action: `Resume the implementation workstream only after the human decision and required source/registration corrections are recorded.`
- Blockers or open questions: `Implementation remains incomplete; art/camera approval and source-family reconciliation remain open.`
