# REVIEW OPERATOR MOTION FOUNDRY SOURCE BRIDGE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-motion-foundry-source-bridge-v1`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `operator-motion-foundry-source-bridge-v1`
- Locks: `operator-motion-foundry, operator-assets`
- Review: `none`
- Review target workstream: `operator-motion-foundry-source-bridge-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_MOTION_FOUNDRY_SOURCE_BRIDGE_V1.md`
- Reviewed main: `9bbe905a1ffcca2afca273ccc48a7ed2f794d0c8`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify MF2's source-work staging and preservation of the existing approval/publication authorities.
- Reviewed implementation acceptance: A-E of the archived `OPERATOR_MOTION_FOUNDRY_SOURCE_BRIDGE_V1.md`.
- Review evidence: Fresh independent inspection of exact current target plan/profile/ingress, output hashes and provenance, source-work collisions, SourceArtService authorization and unchanged canonical/Workbench/Asset V2 paths.
- Correction threshold: Arbitrary path/write, import/publish leakage, false approval/timing, stale/forged source identity, silent replacement or missing validation is a blocking finding with R0-NN ID.
- Focused validation: Re-run MF2 isolated export/source-acceptance with good and forged job, stale profile/reference, wrong target direction, wrong generation, content collision, repeated same export and canonical hash inventory before/after; run MF1/ingress/registration regression and changed validation.
- Review focus: The root `.ai` to authorized `asset_drop/source_work` boundary; no automatic Source Session.handoff or Workbench publish; targeted artifact source truth and never runtime promotion.
- Acceptance: Fresh findings-first independent review with pass only on exact bounded source-work rights and no material evidence gaps; otherwise create correction/re-review pair without touching implementation.
- Non-goals: No feature build, source-art approval, gameplay edit, timing decision or live Godot art cutover.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

Follow `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md` in a newly started reviewer context; launch through `paired_review_runner.py` without double-claiming.

## Next Handoff

- Next workstream: `none`
- Next packet state: `human-art-gated MF3 proposal`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh applies to: `successor`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Refresh reason: `A real Operator pilot requires explicit layered source, provenance, part choices and subjective art/timing approval before new packet authoring.`
- Next action: `Return MF1/MF2 proof and request a reviewed layered source for one 15f x 128px south Operator test; author MF3 only after human selection.`
- Blockers or open questions: `No approved rigged Operator part source yet; synthetic proof is not art approval.`
