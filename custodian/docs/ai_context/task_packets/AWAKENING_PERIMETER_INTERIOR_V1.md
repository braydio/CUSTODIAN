# INTERIOR PERIMETER SUPPORT: ZONES 01–04

- Packet schema: custodian.task_packet.v2
- Workstream: awakening-perimeter-interior-v1
- Status: draft
- Dispatch: manual
- Priority: P2
- Depends on: review-awakening-perimeter-support-foundation-v1
- Locks: awakening-runtime, awakening-art-registration, awakening-perimeter-support
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, runtime, visual, asset-pipeline
- Paired review workstream: review-awakening-perimeter-interior-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Reviewed main: 63f3e38608fa6f0c5778958858dab1abd764a056
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a
- Visual review: required
- Goal: Integrate approved Crèche, Ambulatory, Attestation, and Locker Reliquary perimeter backdrop states without redrawing their existing room plates or implying new playable spaces.
- Completion boundary: Publish and bind only approved 12 static 1-frame states, 3 each for 01–04, to the AP0 support host; close actual measured off-route visual gaps in those four environments and validate full operator wake→P-9 route behavior.
- Current measured state: The thirty planned asset prompts exist, but none of the 12 interior files is verified generated or user-approved yet; AP0 contract and 04→05 composition review precede binding. Region language: Dormant Recovery Stacks, Abandoned Processing Wards, Silent Registry, Sealed Armament Annex.
- Evidence: design/04_architecture/AWAKENING_PERIMETER_SUPPORT_V1.md; design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md; design/04_architecture/AWAKENING_PERIMETER_SUPPORT_IMPLEMENTATION_ROADMAP.md; custodian/game/world/awakening/awakening_layout.gd; custodian/game/world/awakening/awakening_first_return.gd; custodian/scenes/awakening_first_return.tscn; design/04_architecture/AWAKENING_ASSET_MANIFEST.md; design/04_architecture/ASSET_PIPELINE_V2.md.
- Task-specific authority: design/04_architecture/AWAKENING_PERIMETER_SUPPORT_V1.md; design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md; design/04_architecture/AWAKENING_PERIMETER_SUPPORT_IMPLEMENTATION_ROADMAP.md; actual live Asset V2 contract/parser and current authored Layout/runtime remain authoritative for technical details.
- Work surface: Perimeter support host from AP0, four existing family contracts for 01–04, source_work/awakening and inbox paths from prompt authority, Asset V2 catalog and scene binding; dedicated interior-scene/alpha/gap-focused smoke.
- Change: Require twelve approved checksum-recorded masters/handoff entries; inspect true alpha, seamless repeat-edge fit, per-state dimensions (512², 1024×512, 256²), native presentation scale and source-vs-runtime mapping. Plan/ingest via Asset V2; bind below the canonical zone art, with repeatable structural support, sparse distant architecture and controlled local edge decals. Preserve Crèche waking/console FX, processing shaft/void, steles, P-9 anchor and Locker geometry. No independently rescaled 04→05 support. Populate only needed nonplayable camera-visible rectangles derived from AP0 ledger; keep absent/rejected states visibly pending with default backdrop.
- Preserve: Gameplay route authority remains in Layout, existing zone underlays/foregrounds retain exact registration and pixels, accepted Dust→connector→Locker composition is never replaced, existing 05→06 passage and Road alignment remain unchanged; missing art is never fabricated; authored camera/lighting/progression owns gameplay.
- Non-goals: No playable area expansion, no new collisions, doors, traversal permissions, quests, combat, UI, procgen, scene handoff, repeated full-frame image adjudication or arbitrary edits to immutable source art.
- Acceptance: All approved interior states catalog-backed/consumer-bound, camera-visible support adds architectural continuation without opaque panel edges, all physical route geometry/trigger positions and source-registered 04→05 untouched; closeout ledger identifies skipped/unapproved images, no false completed states; one compact visual review for human judgement after objective pixel tests.
- Validation: Run focused Asset V2 status/doctor and requirements checks, new interior support alpha/coverage tests, Awakening geometry/progression, prompt lifetime and 04→05 registered composition regression, minimal Moment Forge no-capture traversal then one bounded evidence preview if needed.
- Task overrides: none
- Deferred: Depth 05–06, exterior 07–09, Road 10, unrelated Gate opened state, any new gameplay.

## Asset and review handoff

- Planned region coverage: 01–04.
- Asset dimensions and states are exact proposed contracts from the prompt authority: structural_support 512×512 / distant_structures 1024×512 / edge_transition 256×256, each omni static 1 frame, true alpha where defined; the real V2 family schema owns per-state frame size. No model-generated file is assumed to exist.
- Before touching runtime, inspect current origin/main, all predecessor implementation/review receipts and the relevant existing Asset V2 family contracts; reconcile stale planning numbers with measured truth.
- Human review/approval of all twelve 01–04 art states and their per-file source/provenance/handoff manifest is required before promoting implementation and paired review to ready/auto.
- Refresh required: do not claim this draft/manual packet or its blocked/manual paired review until exact approved artwork and provenance exist, predecessor review has archived complete, and the implementation + review are intentionally promoted together to ready/auto with authoring preflight and regenerated README index.
- Next action: Run the specified human-owned visual approval and Asset V2 source handoff, then refresh/promote this packet pair; never bypass the manual gate.
