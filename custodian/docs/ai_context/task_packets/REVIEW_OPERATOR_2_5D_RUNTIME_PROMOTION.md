# REVIEW: OPERATOR 2.5D RUNTIME PROMOTION

- Packet schema: custodian.task_packet.v2
- Workstream: review-operator-2-5d-runtime-promotion
- Kind: review
- Status: ready
- Dispatch: auto
- Priority: P1
- Depends on: operator-2-5d-runtime-promotion
- Locks: operator-runtime-animation, operator-art-generation-schema, operator-workbench-publish
- Review: none
- Review target workstream: operator-2-5d-runtime-promotion
- Review target packet: custodian/docs/ai_context/task_packets/archived/OPERATOR_2_5D_RUNTIME_PROMOTION.md
- Reviewed main: 84c7eb1f8a2ee8c2e4936b9df9afa8ea7e1672d1
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Review modes: code, architecture, runtime, asset-pipeline, workflow
- Review cycle: 0
- Max automatic review cycles: 2
- Goal: Independently verify the landed implementation against its archived packet and live behavior.
- Reviewed implementation acceptance: The archived implementation packet Acceptance section is the exact contract.
- Review evidence: Reuse the WB25-6 exact policy/dry-run/journal receipts and fixture tests, then independently reconstruct the reviewed cohort-selection closure, effective current `Operator2DReview.current_receipt()` proofs, actual source/frame/timing hashes, generated manifest/SpriteFrames parity, and live rollback state. WB25-5's fresh paired review is complete/passed but measured zero verified families in its checkout; do not treat the 69/552 target plan or accepted idle source as release proof. A fixture-only WB25-6 system cannot be graded as a successfully released real 2.5D cohort.
- Correction threshold: Correct confirmed correctness/authority defects or material proof gaps through bounded correction + re-review; route polish to the next slice.
- Focused validation: Re-run fixture-first policy/sync/manifest/catalog/SpriteFrames, currently verified 0/0 hard-stop, sparse/caller-forged approval, exact source/timing, overlapping-cohort, fault-injected rollback, selector and unchanged legacy negative controls from the archived implementation. Then original runtime animation authority, path audit, spriteframes import, WB25-5 queue and real Workbench receipt smokes where relevant, Godot import once per clean project, changed validation and `git diff --check`.
- Review focus: Audit the **real selected cohort's human decision and dependency closure** across idle/ready/locomotion/transitions, all required directions/layers, weapon-owner semantics and timing contracts. Confirm preflight re-derives effective receipt approval/QA/sandbox proof, source/art-workspace identities and hash-binds each complete leaf, rather than trusting cached `runtime_verified` flags or accepted source. Critically reject the old circular `PUBLISHED`-before-promotion gate: publication is validated post-commit runtime truth, not authorization for its own mutation. Check the legacy-default policy no-op, whole-cohort one-generation selection, simultaneous semantic sibling collisions, staged Godot rebuild, bit-exact rollback from every injected failure, pending-land/no-owner/stale/hash-mismatch refusals, immutable journal and interrupted-promotion recovery. Confirm `OperatorAnimationSelector`, semantic requests, one runtime manifest/catalog/SpriteFrames and unrelated legacy cohorts remain unchanged; SOUTH fallback stays where still needed. Confirm WB25-5 queue publication now reflects materialized policy/runtime truth and never mislabels fixture proof as production. The independent reviewer may reuse objective evidence and request one compact Dropbox human visual review only when material subjective continuity remains.
- Acceptance: Findings-first receipt with stable IDs; zero blocking defects/material proof gaps for pass. A fixture-only capability is **not** a production-cutover approval. If no real human-approved verified cohort exists, the review must not claim successful live art promotion. Do not patch reviewed implementation.
- Non-goals: No redesign, implementation fixes, production art mutation, or successor implementation.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Procedure

Follow custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md from fresh context.

## Handoff

- Next workstream: none
- Next packet state: none
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Summary backlink: include exact Authoring chat URL
- Refresh reason: none
- Next action: Proceed only through declared dependency/claim gates.
- Blockers or open questions: none beyond declared dependencies
