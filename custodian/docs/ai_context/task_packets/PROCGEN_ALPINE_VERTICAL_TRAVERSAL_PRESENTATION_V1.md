# PROCGEN ALPINE VERTICAL TRAVERSAL PRESENTATION V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-alpine-vertical-traversal-presentation-v1`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-procgen-vertical-traversal-asset-v2`
- Locks: `procgen-presentation, procgen-terrain, asset-pipeline`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, visual, asset-pipeline`
- Paired review workstream: `review-procgen-alpine-vertical-traversal-presentation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `integrates reviewed traversal art with live cliff composition and needs human spatial/readability acceptance`
- Reviewed main: `350ee94e4b3b80010c0970903f3418966df3b851`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Visual review: `required`
- Goal: Bind A3 traversal art only to A2 semantic connectors so the route reads as a physical lower-to-upper Alpine ascent, ordinary cliffs remain truthful, and the upper crest/look-back reads clearly.
- Completion boundary: After refresh, semantic connector records select/suppress presentation only inside their reserved footprint; upper lip, lower talus and cliff depth remain truthful; streaming reproduces the same result; objective probes and human native-scale review pass.
- Current measured state: REFRESH REQUIRED. AP2 ordinary cliff/contact/fascia is separate presentation authority and must be inspected in its then-landed state. No traversal-specific runtime family is bound yet.
- Evidence: reviewed A2 geometry, A3 family/hashes and current AP2/AP3 presentation truth to be re-derived at refresh.
- Task-specific authority: A2 records own placement; A3 owns art identity; AP2/Region Frame own ordinary cliffs; ElevationMap/RuntimeWalkableBoundary remain gameplay truth.
- Work surface: reuse current Alpine macro/cliff presentation seam or one bounded connector presenter; connector resources; focused seam/streaming tests; compact Moment Forge evidence.
- Change:
  1. REFRESH FIRST against reviewed A2/A3 plus current AP2/AP3; reuse landed presentation owner rather than create a parallel renderer.
  2. Only semantic connector metadata may select traversal art. Pixels/opacity/proximity may not create climbability.
  3. Suppress/mask ordinary fascia/contact only inside the connector reservation where needed to avoid a fake solid wall; neighboring ordinary cliffs remain untouched.
  4. Compose upper lip so playable ground overlaps/occludes enough cliff crown to read as higher plane; lower talus/scree sits on the lower plane.
  5. Keep shelf/shoulder centerline and both landing footprints visually unobscured.
  6. Streaming unload/reload reproduces connector visuals deterministically without mutating traversal metadata.
  7. Capture minimum final evidence: lower approach, shelf/ascent, crest, upper stance/look-back; short motion only if stills cannot prove continuity.
- Preserve: A1 movement, A2 topology, A3 identities, AP2 ordinary cliffs, Region Frame depth/fog, collision/navigation and Archive Resolve.
- Non-goals: no art generation, hidden topology tuning, camera-pitch system, biome rewrite or true Z simulation.
- Acceptance:
  1. Non-connector cliffs still render through current ordinary Alpine path; suppression remains bounded to connector reservation.
  2. Objective probes prove presentation does not cover the actual walkable centerline or fabricate walkability; streaming roundtrip is identical.
  3. At normal zoom the route is recognizable before entry without UI arrows/saturated highlight.
  4. Human review passes lower/upper distinction, upper-lip occlusion, crest/look-back and geological/non-tiled read.
  5. Restoring the tiny 32px fallback as primary traversal cue fails asset-identity/presentation coverage.
- Validation: Refresh exact tests from landed A2/A3/AP2. Require connector presentation + cliff/Region Frame + streaming + Asset V2 + changed-file validation + `git diff --check`, then one delete-after-review human handoff.
- Task overrides: `none`
- Deferred: C1 closes integration; true mantle/climb animation remains future.

## Handoff
- Next workstream: `review-procgen-alpine-vertical-traversal-presentation-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Refresh reason: `A4 must consume exact landed topology, reviewed art and whatever AP2/AP3 APIs are current; visual acceptance is human-owned.`
- Next action: `After A3 review PASS, refresh, implement and publish compact human evidence; do not close without disposition.`
- Blockers or open questions: `reviewed A3 art and current AP2/AP3 integration seam`
