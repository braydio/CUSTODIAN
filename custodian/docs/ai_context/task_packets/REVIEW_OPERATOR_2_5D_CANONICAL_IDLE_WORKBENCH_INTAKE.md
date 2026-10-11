# REVIEW: OPERATOR 2.5D CANONICAL IDLE WORKBENCH INTAKE

- Packet schema: custodian.task_packet.v2
- Workstream: review-operator-2-5d-canonical-idle-workbench-intake
- Kind: review
- Status: ready
- Dispatch: auto
- Priority: P1
- Depends on: operator-2-5d-canonical-idle-workbench-intake
- Locks: operator-art-agent, operator-source-normalization, operator-workbench-ui, operator-art-generation-schema
- Review: none
- Review target workstream: operator-2-5d-canonical-idle-workbench-intake
- Review target packet: custodian/docs/ai_context/task_packets/archived/OPERATOR_2_5D_CANONICAL_IDLE_WORKBENCH_INTAKE.md
- Reviewed main: 6ff9c52b3315c9f3afc2a7ce42576b564df26673
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Review modes: code, asset-pipeline, workflow
- Review cycle: 0
- Max automatic review cycles: 2
- Goal: Independently verify the byte-exact eight-direction source-master-to-Workbench intake while preserving the zero-promotion boundary and honest per-direction evidence.
- Reviewed implementation acceptance: Archived implementation packet Acceptance section, including no runtime mutation, owns this review.
- Review evidence: Read source-work master manifest, accepted `d4a6...` hash, current plan/profile/reference, the exact package report and physical authored workspace. Recheck actual LFS hydration; a Git LFS text pointer does not count as the 541981-byte accepted PNG.
- Focused validation: Independently recombine eight output strips in the locked order, hash/compare RGBA pixels to the master, verify exact 128×128 grid and 15f count, inspect all real `workbench.json` and `workbench.aseprite` files, rerun the narrow ingress/target queue smokes, and compare pre/post runtime file hashes. If the source or ignored workspace is not available to the reviewer, report a **material evidence gap**, not success based only on implementation summary.
- Review focus: Confirm no source-master repaint/resize, no invented FPS, no alternate Generic Asset V2 family/identity, no bypass of WB25-2 Source Session/target-binding/inbox and WB25-4 current receipts, no runtime sync/catalog/SpriteFrames mutation. Confirm any blocked cells are truthfully blocked and that the review does not mark verified or PUBLISHED merely for an editable Workbench.
- Acceptance: Findings-first, stable IDs; passed only when eight independently byte-valid direction-to-Workbench cells and untouched runtime are proven. If input unavailable or missing documents, review cannot pass; leave an explicit evidence gap or block with exact recovery condition.
- Non-goals: Production runtime generation selection, human artistic judgments, approving unknown timing, art polish, changes to reviewed implementation.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Procedure

Follow custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md from fresh context.

## Handoff

- Next workstream: operator-2-5d-runtime-promotion
- Next packet state: refresh-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Summary backlink: include exact Authoring chat URL
- Refresh reason: after intake, exact family reviews/timing and dependency-closed cohort are still needed before runtime promotion
- Next action: verify idle family with WB25-4 sandbox, then resolve cohort selection
- Blockers or open questions: WB25-6 remains draft/manual and cannot be claimed merely because intake was reviewed
