# REVIEW OPERATOR MOTION FOUNDRY CORE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-motion-foundry-core-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `operator-motion-foundry-core-v1`
- Locks: `operator-motion-foundry`
- Review: `none`
- Review target workstream: `operator-motion-foundry-core-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_MOTION_FOUNDRY_CORE_V1.md`
- Reviewed main: `9bbe905a1ffcca2afca273ccc48a7ed2f794d0c8`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify MF1 deterministic candidate-generation, identity and write-boundary acceptance.
- Reviewed implementation acceptance: A-E of the archived `OPERATOR_MOTION_FOUNDRY_CORE_V1.md`.
- Review evidence: Fresh checkout inspection of exact implementation/fixture commits, raw part/pose/report hashes, authoritative profile/reference, and registered core smoke. Synthetic fixture is not an Operator art approval.
- Correction threshold: A source mutation, canonical side effect, unconfined path, wrong signed rounding or nondeterministic candidate, clipping, false report approval or incomplete negative controls requires blocking finding with R0-NN ID.
- Focused validation: Re-run MF1 15-frame fixture twice in separate fresh temp roots; mutate wrong SHA/part/canvas, keyframes, locked root, contact, palette, symlink and output collision; compare report hashes; run canonical Operator 2.5D visual contract smoke and relevant changed validation.
- Review focus: Existing art/profile authority, no 96px rig runtime migration, exact RGBA/alpha and integer interpolation, body root distinct from alpha bounds, immutable source bytes, honest candidate-only status and full-path safety.
- Acceptance: Produce a fresh findings-first disposition; for PASS, zero blocking defects/material evidence gaps, one canonical receipt with immutable implementation SHA and objective proof of no canonical writes. Otherwise emit bounded correction/re-review via existing runner.
- Non-goals: No gameplay/art redesign, no manual art approval and no modification of reviewed implementation.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

Follow `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md` in a newly started reviewer context and use the supported `paired_review_runner.py` procedure without double-claiming.

## Next Handoff

- Next workstream: `operator-motion-foundry-source-bridge-v1`
- Next packet state: `dependency-gated`
- Refresh applies to: `successor`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Refresh reason: `none`
- Next action: `After a genuinely accepted core review, allow the source bridge to claim when dispatcher/locks permit.`
- Blockers or open questions: `none`
