# REVIEW: AWAKENING 04→05 REGISTERED COMPOSITION FADE REPAIR V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-awakening-04-05-registered-composition-fade-repair-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `awakening-04-05-registered-composition-fade-repair-v1`
- Locks: `awakening-04-05-connector-presentation, awakening-runtime`
- Review: `none`
- Review target workstream: `awakening-04-05-registered-composition-fade-repair-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AWAKENING_04_05_REGISTERED_COMPOSITION_FADE_REPAIR_V1.md`
- Reviewed main: `52135e3401a9efd49b011e676171373c3bef37b2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb`
- Visual review: `required`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, runtime, visual, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the 04→05 repair changes only fade ownership, preserves the accepted registered composition byte-for-byte and transform-for-transform, fixes live room/passage coverage in both directions, and does not add per-frame discovery or telemetry cost.
- Reviewed implementation acceptance: The archived implementation packet Acceptance section is the exact contract.
- Review evidence: Reuse implementation receipts/fixtures first; gather fresh evidence only where acceptance is not established.
- Correction threshold: Correct confirmed fade-ownership, validation-vacuity, registration-preservation, performance-path, or proof defects through bounded correction + re-review; do not reopen accepted art direction.
- Focused validation: Rerun the repaired Awakening first-return fade checks, registered composition asset/render/traversal checks, lower→upper passage coverage, and `traversal/awakening_late_seams_v1` none-mode plus one compact capture. Independently probe parent alpha=1, per-child Zone04/Connector/Zone05 ownership, 05→06 live Dust coverage, forward/reverse equivalence, and unchanged art hashes/transform/order. Finish with `git diff --check`.
- Review focus: No layout/pixel/transform/z-order movement; shared parent is registration-only and never distance-faded; Dust/Connector/Locker children fade independently from correct spatial authorities; hidden legacy Zone05 art cannot satisfy visual coverage tests; no per-frame scene/path lookup, image sampling, resource load, or event spam; deterministic probes rather than wrapped Observatory tail evidence; unrelated procgen/ranged findings remain out of scope.
- Acceptance: Findings-first receipt with stable IDs; zero blocking defects/material evidence gaps for pass; visual evidence confirms the previously accepted composition remains visually aligned while wrong-location floor fade/pop is gone.
- Non-goals: No art redesign, connector re-registration, gameplay/collision/progression changes, procgen optimization, ranged/overheat/dodge changes, or broader zone-streaming rewrite.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Agent Handoff / Planning Decisions

- The user has already accepted layout and draw order. A reviewer finding that merely prefers a different position/composition is invalid unless the implementation actually changed the locked transform/pixels/order.
- The defect under review is presentation-alpha ownership, including the stale/vacuous lower→upper hidden-underlay test.
- The user playtest report is guardrail evidence only because it came from `game.tscn`, not the Awakening scene. Do not claim it reproduces the connector fade.
