# PROCGEN VERTICAL TRAVERSAL ASSET V2
- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-vertical-traversal-asset-v2`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-procgen-elevation-connector-topology-v1`
- Locks: `asset-pipeline, procgen-vertical-traversal-assets`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `asset-pipeline, visual`
- Paired review workstream: `review-procgen-vertical-traversal-asset-v2`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `publishes new production art keyed to landed gameplay geometry and replaces user-rejected fallback readability`
- Reviewed main: `350ee94e4b3b80010c0970903f3418966df3b851`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Visual review: `required`
- Goal: Create and publish a production-readable Alpine traversal family sized/registered to the landed A2 connector instead of relying on the unreadable tiny ramp/cliff fallback.
- Completion boundary: After planning refresh and human-approved source art, exactly one family `procgen_alpine_vertical_traversal` publishes 14 semantic states with exact A2-derived canvases/anchors; source/inbox/runtime provenance, alpha and dimensions verify; no runtime consumer is wired here.
- Current measured state: REFRESH REQUIRED. User explicitly rejects existing 32px ramp/stair/cliff art as production verticality. AP2 large geology/contact art covers ordinary cliffs, not traversable-route modules. Exact A3 canvases cannot be truthfully locked until reviewed A2 exports its footprint.
- Evidence: Authoring-chat human decision; existing terrain tile inventory; AP2/rocky-upland families; landed A2 export to be added at refresh.
- Task-specific authority: Asset Pipeline V2; landed A2 geometry/anchors; current Alpine/AP2 material language; human source/style approval.
- Work surface: new family metadata; `asset_drop/source_work/procgen/procgen_alpine_vertical_traversal/`; matching inbox/runtime domain; Asset V2 validation.
- Change:
  1. REFRESH FIRST from A2 exact footprint/anchors and replace every dimensional placeholder with measured whole-32px canvases before promotion.
  2. Family ID is fixed: `procgen_alpine_vertical_traversal`. Required static states: N/S/E/W `ascent_01`, N/S/E/W `ascent_broken_01`, N/S/E/W `upper_lip_01`, `scree_talus_01`, `scree_talus_02` = 14 one-frame RGBA states.
  3. Raw/unprocessed masters save as `custodian/asset_drop/source_work/procgen/procgen_alpine_vertical_traversal/<state>_source.png`; normalized intake saves as `custodian/asset_drop/inbox/procgen_alpine_vertical_traversal/<state>.png`; runtime domain is `content/tiles/procgen_macro/runtime/alpine_vertical_traversal/`.
  4. Visual lock: broad multi-cell shelf/ascent, continuous cold-gray Alpine geology, upper playable lip visibly occluding cliff crown, lower talus on lower plane, no crop wall/matte/fake collision/UI/character/tiny repeated ramp icon as primary cue.
  5. Match AP2 material family without overwriting/repurposing ordinary AP2 assets. Route geometry, not saturated color, communicates traversability.
  6. Human source acceptance is mandatory. Placeholder/procedural fallback cannot be marked verified.
  7. Publish one compact native-scale contact sheet plus isolated alpha/registration proof; ask whether climbability is obvious, upper/lower levels are distinct, crest reads higher, and module reads geological.
- Preserve: A2 gameplay geometry/registration, AP2 ordinary cliff families, generic fascia fallback and no gameplay authority from alpha.
- Non-goals: no topology, movement or runtime consumer wiring; no rework of general Alpine underlay/weather; no acceptance of old ramp art because it exists.
- Acceptance:
  1. Refresh records exact dimensions, footprint cells and anchors from A2 before source generation/ingest.
  2. All 14 sources are human-approved and trace to source_work; normalized outputs preserve aspect/alpha/registration without nonuniform stretching.
  3. Asset V2 plan/status/doctor is green and hashes/dimensions/frame counts are recorded.
  4. Native-scale human review passes all four readability questions for exact runtime hashes.
  5. No AP2/generic cliff identity is overwritten or repurposed.
- Validation: At refresh lock exact Asset V2 commands/family smoke. Run plan/status/doctor, alpha/matte/dimension/registration and provenance checks, changed-file validation and `git diff --check`; use one compact delete-after-review handoff.
- Task overrides: `none`
- Deferred: A4 owns runtime composition.

## Handoff
- Next workstream: `review-procgen-vertical-traversal-asset-v2`
- Next packet state: `dependency-gated`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Refresh reason: `Exact canvases/anchors require reviewed A2 topology and source art requires human approval.`
- Next action: `After A2 review PASS, refresh exact dimensions, create/review source masters, then promote only when the asset gate is real.`
- Blockers or open questions: `reviewed A2 topology plus human-approved source art`
