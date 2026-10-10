# REVIEW: OPERATOR 2.5D WORKBENCH REVIEW AUTOMATION + RUNTIME SANDBOX

- Packet schema: custodian.task_packet.v2
- Workstream: review-operator-2-5d-workbench-review-automation
- Kind: review
- Status: ready
- Dispatch: auto
- Priority: P1
- Depends on: operator-2-5d-workbench-review-automation
- Locks: operator-workbench-ui, operator-art-agent, operator-review-automation, operator-runtime-preview
- Review: none
- Review target workstream: operator-2-5d-workbench-review-automation
- Review target packet: custodian/docs/ai_context/task_packets/archived/OPERATOR_2_5D_WORKBENCH_REVIEW_AUTOMATION.md
- Reviewed main: 119fa1a19427dce838977422d5186e3624e3457e
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Review modes: code, architecture, workflow, visual, runtime
- Review cycle: 0
- Max automatic review cycles: 2
- Goal: Independently verify that WB25-4 turns landed target/QA/polish evidence into truthful current review receipts, family/sequence review and sandbox proof without creating a second QA/mutation/publication/runtime authority.
- Reviewed implementation acceptance: The archived implementation packet Acceptance section is the exact contract.
- Review evidence: Reuse implementation receipts/fixtures first; gather fresh evidence only where acceptance is not established.
- Correction threshold: Correct confirmed acceptance/correctness defects or material proof gaps through bounded correction + re-review; subjective art-direction decisions remain human-owned; next-slice queue/promotion improvements are not WB25-4 corrections.
- Focused validation: Rerun the WB25-4 focused review smoke first, then affected WB25-3 polish, target projection, Sequence/Timeline, Workbench UI, Operator presentation-authority and runtime-animation-authority checks. Independently probe one stale receipt, one forged cached polish proposal, one sibling-incomplete family, one v1 legacy sequence + v2 2.5D sequence, one tampered sandbox request/frame, one successful real-Operator sandbox teardown, and before/after hashes of production runtime manifest/SpriteFrames. Finish with `git diff --check`.
- Review focus: (1) review receipts bind exact current evidence and become stale on any bound input change; (2) receipts/family state never authorize mutation; corrected WB25-3 apply re-derivation remains mandatory; (3) QA severity/class mapping consumes live v2 QA rather than a duplicate taxonomy; (4) family completion derives from target leaves + receipts with no sibling bleed; (5) sequence v1 compatibility and generation-aware v2 identity cannot alias legacy and 2.5D clips; (6) timing/contact facts are sourced, never invented; (7) sandbox uses exact 2.5D Workbench pixels on real Operator presentation context while `OperatorBodyPresenter` remains body-visibility authority; (8) request/frame tampering fails closed; (9) production runtime selector/catalog/manifest/SpriteFrames/assets remain byte-identical; (10) `runtime_verified` is truthful review+sandbox evidence while `PUBLISHED` remains separate/unowned until later slices.
- Acceptance: Findings-first receipt with stable IDs; zero blocking defects/material proof gaps for pass; do not patch reviewed implementation. A clean pass unlocks WB25-5's required authoring-chat refresh with actual landed receipt fields/counts.
- Non-goals: No implementation fixes, production art mutation, queue/brief implementation, 2.5D publication, runtime generation cutover, combat timing changes, or reviewer-authored aesthetic approval.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Agent Handoff / Planning Decisions — 2026-10-09

- Review against the corrected WB25-3 apply boundary, not the pre-correction packet. Any path that can replay cached erase/registration coordinates into mutation without fresh re-derivation is blocking.
- The first canonical 2.5D family still has no human-authorized production publication path. Do not fail WB25-4 merely because `PUBLISHED` remains false; fail it if WB25-4 **claims** publication or mutates publication/runtime authority.
- A successful sandbox is not runtime cutover. It is local hash-bound proof over exact selected pixels in an isolated real-Operator context.
- Successor WB25-5 intentionally requires an authoring-chat planning refresh. **That successor refresh is not a gate on this paired review itself.** The current review must run automatically once WB25-4 lands and is archived complete.

## Handoff

- Next workstream: operator-2-5d-workbench-production-queue
- Next packet state: refresh-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Summary backlink: include exact Authoring chat URL
- Refresh reason: WB25-5 must consume landed receipt schema, actual family/review counts and any WB25-4 review findings before final queue/NEXT/brief fields are frozen.
- Next action: After this review closes, return WB25-4 implementation/review evidence to the authoring chat and refresh WB25-5.
- Blockers or open questions: none for this review; successor refresh occurs only after this review is complete.
