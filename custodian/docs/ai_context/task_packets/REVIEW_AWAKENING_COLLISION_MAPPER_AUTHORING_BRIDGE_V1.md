# REVIEW AWAKENING COLLISION MAPPER AUTHORING BRIDGE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-awakening-collision-mapper-authoring-bridge-v1`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `awakening-collision-mapper-authoring-bridge-v1`
- Locks: `awakening-runtime, authored-level`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, workflow`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review target workstream: `awakening-collision-mapper-authoring-bridge-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AWAKENING_COLLISION_MAPPER_AUTHORING_BRIDGE_V1.md`
- Reviewed main: `17fd54aa9bf78887ff162f51af19176095284d8f`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Independently verify the Awakening mapper shows the true collision-vs-art correspondence and saves lossless author-owned pixel coordinates without changing canonical gameplay collision.
- Reviewed implementation acceptance: `A1–A6` from archived `AWAKENING_COLLISION_MAPPER_AUTHORING_BRIDGE_V1.md`, particularly no actual runtime collision mutation before user review.
- Review evidence: Pinned implementation SHA, real rendered gate/04→05 cropped overlays, current generated Collider2D node bounds, two canonical draft round-trip samples, stale SHA/route-overlap failures, Sundered Keep regression and unchanged baseline Layout byte hash.
- Correction threshold: Any invented/duplicate collider, source-space offset, missing actual collision contributor, silent mutation of Layout or gameplay, unlocked route closure, stale export accepted or missing regression test is blocking.
- Focused validation: Rerun Awakening mapper fixtures in a rendered or headless-compatible fixture harness as appropriate, exact gate-pylon measurements, 04→05 art origin and connector alignment, `awakening_first_return_geometry_smoke.gd`, `awakening_first_return_smoke.gd`, generic and Sundered Keep mapper smoke, changed-file and AI-context checks. Do not treat a screenshot alone as runtime collision proof.
- Review focus: Target scene/world transform, hidden scene underlays versus registered composite, static-vs-actual generated collider overlay, mappers' protected apply methods, world/pixel coordinate metadata, draft reopen and protected route negatives.
- Acceptance: Fresh-context findings-first review with stable R0-NN IDs, independence and exact production byte-preservation evidence. Only a genuine PASS receipt accepts the mapper for user collision authoring. Any findings follow the bounded correction process; do not change reviewed code in this workstream.
- Non-goals: Gameplay collision reauthoring, art generation, V2 Dust Lung cutover, new parallel mapper, migration of Sundered Keep authority.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Use a fresh pinned implementation context and reproduce actual colliders from the instantiated Awakening scene, not merely Layout constant values.
2. Verify exact painter interactions, save/reload and false-positive overlap cases; check source png/overlay ROI where actual art is necessary.
3. Confirm neither the production scene nor `awakening_layout.gd` was changed by draft save and that a stale/ambiguous promotion fails.
4. Verify Sundered Keep/other mapper paths and independently report PASS or concrete findings.

## Next Handoff

- Next workstream: `none`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `not-recorded`
- Refresh reason: `User draws and approves pixel-accurate collision draft before a separately gated spatial cutover.`
- Next action: Open the verified mapper, draw proposed blockers/void edges against live art, export the exact draft, then authorize production integration with geometry/route validation.
- Blockers or open questions: `Await user's authored draft before runtime collision changes; do not invent absent art-pixel extents.`
