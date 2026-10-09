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
- Visual review: `conditional`
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
- Review focus: No layout/pixel/transform/z-order movement; shared parent is registration-only and never distance-faded; Dust/Connector/Locker children fade independently from correct spatial authorities; the live Designation Locker closed→authorize/open-loaded→empty interaction sequence cannot change Locker Reliquary room-art alpha; hidden legacy Zone05 art cannot satisfy visual coverage tests; no per-frame scene/path lookup, image sampling, resource load, or event spam; deterministic probes rather than wrapped Observatory tail evidence; unrelated procgen/ranged findings remain out of scope.
- Acceptance: Findings-first receipt with stable IDs; zero blocking defects/material evidence gaps for pass; the fresh paired reviewer inspects the supplied compact visual evidence and confirms the previously accepted composition remains visually aligned while wrong-location floor fade/pop is gone. Do not create a user approval gate merely because the review mode includes visual. Escalate to the user only if the capture is materially ambiguous, contradicts objective probes, or reveals an actual change to the locked layout/order/art direction.
- Non-goals: No art redesign, connector re-registration, gameplay/collision/progression changes, procgen optimization, ranged/overheat/dodge changes, or broader zone-streaming rewrite.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Agent Handoff / Planning Decisions

- **Single-connector authority lock (2026-10-09):** the live 04→05 connector art is one registered 1502×2048 plate at `RegisteredComposition04_05/Connector`, sourced from `awakening_reliquary_dust_lung_connector_full_plate_underlay_1502x2048.png`. Do not interpret `04_05_A`, `04_05_B`, or `04_05_C` as art pieces. They are only `AwakeningLayout.CONNECTORS` Rect2 traversal/visibility checkpoints describing the dogleg.
- The retired three-piece connector interpretation is explicitly non-authoritative. Do not recreate, split, crop, or re-register the current single connector plate.
- **Recorded human visual decision:** the user states that the currently live single connector “looks incredible.” Treat the accepted connector layout/order/art direction as approved. The remaining review duty is objective: confirm the repair preserved that exact single-plate presentation and that room-floor visibility remains stable at the two interiors and the A/B/C **route checkpoints** in both directions.
- Reuse the existing human approval unless implementation changed the connector bytes/registration/order after the 2026-10-09 review handoff. Any such art/registration change invalidates the approval and requires a new visual gate.

- The user has already accepted layout and draw order. That decision is not pending and must not be re-requested. A reviewer finding that merely prefers a different position/composition is invalid unless the implementation actually changed the locked transform/pixels/order.
- The defect under review is presentation-alpha ownership, including the stale/vacuous lower→upper hidden-underlay test.
- The user playtest report is guardrail evidence only because it came from `game.tscn`, not the Awakening scene. Do not claim it reproduces the connector fade.
