# REVIEW OPERATOR MOTION FOUNDRY BLENDER 2D CUTOUT RIG V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-motion-foundry-blender-2d-rig-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `operator-motion-foundry-blender-2d-rig-v1`
- Locks: `operator-blender-2d-authoring`
- Review: `none`
- Review target workstream: `operator-motion-foundry-blender-2d-rig-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_MOTION_FOUNDRY_BLENDER_2D_RIG_V1.md`
- Reviewed main: `82892c37eaec466f59b58e8df52cb36e3a75a1e5`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, asset-pipeline, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify the 2D Blender Operator rig's source-identity, editable control, neutral pixel fidelity and no-runtime-publication gates.
- Reviewed implementation acceptance: Clauses (A)-(F) in the archived `OPERATOR_MOTION_FOUNDRY_BLENDER_2D_RIG_V1.md`; Blender 2D spec and actual landed source-work only.
- Review evidence: Exact source hashes/23 PNGs, new build/render code, saved packed .blend and transparent 15-frame proof, source-work receipt, minimal diff report, focused smoke and landed implementation summary.
- Correction threshold: Missing/incorrect Blender source, neutral render mismatch, wrong bone parenting, missing image plane, invented occluded geometry, camera/pivot/Z registration error, non-candidate runtime/publish side effect or untested Blender CLI are blocking; subjective seam/visual taste are human_required or next-slice, not agent PASS claims.
- Focused validation: In fresh environment run actual Blender CLI, inspect/reopen .blend, compare neutral rendered RGBA pixel-by-pixel to the source, move controlled bone and verify 1px change then reset, render 15 preview frames twice, falsify missing/altered PNG hashes, assert no canonical/inbox/Workbench/Godot touches; run owner smoke and changed validation. Confirm input receipt reflects predecessor truth and 18 visible + 5 blank parts; no fake 3D mesh character or copy of Broken Warrant rig.
- Review focus: Actual Blender render, source authority, Blender API compatibility, parent transforms, 2D-only textured image planes, deterministic alpha/palette, safe source-work output, and documented visual limits.
- Acceptance: Findings-first independent disposition; PASS only with zero blocking defects/material acceptance gaps. Separate human visual disposition when needed. Do not infer Operator art approval, MF1 acceptance or MF2 readiness.
- Non-goals: No reviewer implementation patch, no user-interface script-pasting, no gameplay/animation selector changes, no unresolved hidden-geometry fabrication, no re-claim of held reviews.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

Start a fresh independent reviewer under `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`; use the canonical paired runner and existing authoring chat. Reuse implementation proof and minimize extra images.

## Next Handoff

- Next workstream: `none`
- Next packet state: `human-art-gated pose/underpaint refinement`
- Refresh applies to: `successor`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Refresh reason: `Judge 15-frame visible idle seams and desired articulation against approved Operator identity before requesting underpaint or MF2.`
- Next action: `Return minimal neutral/pose proof and exact seam questions to this chat; do not classify as approved runtime art.`
- Blockers or open questions: `Five hidden parts and unpainted joint underlaps remain limitations of the cutout source.`
