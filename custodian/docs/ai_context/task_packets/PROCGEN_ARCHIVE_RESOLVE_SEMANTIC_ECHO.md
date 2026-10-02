# PROCGEN ARCHIVE RESOLVE SEMANTIC ECHO AND SPAWN

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-archive-resolve-semantic-echo`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `procgen-archive-resolve-shader`
- Locks: `procgen-presentation`
- Kind: `implementation`
- Review: `manual`
- Review stage: `post-land`
- Review modes: `code, runtime, visual`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `36cb18230796ec844a7796f0a246085c96179e20`
- Goal: Complete Archive Resolve V1 with restrained semantic pre-echo, the one-time ingress/spawn resolution sequence, and a visibly lighter reacquisition treatment for previously resolved unloaded terrain.
- Completion boundary: Done when a small bounded presentation-class vocabulary can influence echo/timing without gaining gameplay authority; first contract entry presents a controlled local Archive Resolve expansion while preserving immediate player control inside the safety pocket; previously resolved unloaded terrain uses a shorter reacquisition treatment; and the final effect remains subtle enough that normal settled play contains no persistent reveal UI/VFX.
- Current measured state: The design locks five broad presentation classes at most: natural, constructed, road, wall/cliff, and major/hero landmark. AR1/AR2 are expected to provide deterministic ready/resolve scheduling, first-vs-reacquire identity, safety halo, shader phases, pause-safe time, and reduced-effects controls.
- Evidence: `design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`; AR1/AR2 packets; current procgen semantic surface/road/macro/landmark query authorities after refresh.
- Task-specific authority: `STREAMING_REVEAL_PRESENTATION_V1.md`; landed AR1/AR2 implementation; live semantic owners queried read-only.
- Work surface: AR presentation owner, one small presentation-class adapter/query, ingress/spawn initialization seam, optional aggregate audio callback stub only if trivial and unused by default, focused V1 smoke, and gameplay-scale comparison evidence.
- Change: Add no more than the design's bounded semantic presentation classes. Their only effects are tiny echo/timing/registration differences. Natural terrain remains mostly soot/dither; constructed surfaces may use slightly straighter registration; roads may show a brief interrupted vector; wall/cliff silhouettes may pre-echo slightly; major/hero landmarks may silhouette roughly 100-150 ms early. Initial spawn keeps a valid resolved safety pocket and allows control immediately while nearby committed terrain resolves outward over roughly 1-1.5 seconds. Reacquisition skips or shortens echo, reduces registration intensity, and settles roughly within 100-150 ms. All choices remain deterministic.
- Preserve: Every semantic owner remains read-only; hidden presentation conveys no quest/discovery knowledge; no uncommitted cell is exposed; player safety/readability; AR1/AR2 performance and pause contracts; no permanent overlay after settlement.
- Non-goals: No new landmark semantics; no map discovery mechanic; no audio production requirement; no gameplay gating on reveal completion; no lore text/UI; no generation changes; no broad per-biome special cases.
- Acceptance: Presentation classes are bounded and queried without copying semantic authority; semantic echo changes only presentation timing/style; initial spawn never delays control once safety pocket is valid; reacquisition is measurably shorter/weaker than first resolve; same seed/path yields the same echo/order identity; reduced-effects/disabled modes remain valid; full V1 gameplay-scale review reads as an Archive process rather than loading, fog fade, square pop, or neon hologram.
- Validation: Refresh against landed AR2 and current semantic owners. Add focused class-mapping/read-only tests, spawn-control/safety-halo timing checks, first-resolve vs reacquire duration/intensity checks, deterministic identity, pause, and disabled/reduced-effects fallbacks. Re-run AR1/AR2 focused smokes and affected streaming/runtime-health tests, then changed-file closeout. Final aesthetic approval remains human-owned.
- Task overrides: `none`
- Deferred: Optional aggregate mechanical/relay audio, later accessibility presets beyond V1 controls, and any future biome-specific presentation nuance justified by actual visual review.

## Temporary Refresh Gate — REMOVE WHEN THIS PACKET IS REFRESHED

This packet is intentionally pre-authored before AR2 and before the live Landmark/semantic owner surface is final.

After `procgen-archive-resolve-shader` lands:

1. fetch current `origin/main`;
2. re-audit the exact read-only semantic query owners for surface/road/wall-cliff/landmark classification;
3. update `Reviewed main`, measured state, work surface, class mapping, spawn seam, validation, and visual evidence plan;
4. remove this entire **Temporary Refresh Gate** section;
5. only then set `Status: ready`.

Do not create a second semantic registry for this effect.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `<fill at closeout>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `<fill at closeout>`
- Friction severity: `<fill at closeout>`
- What went wrong: `<fill at closeout>`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `<fill at closeout>`
- Tooling / docs drift discovered: `<fill at closeout>`
- Follow-up: `<fill at closeout>`

## Handoff

- Next action: Refresh after AR2 and the current landmark/semantic owner surface are live, then complete Archive Resolve V1.
- Best starting files: landed AR presentation owner/shader; current surface material, road semantics, terrain/macro/landmark query owners; spawn/streaming setup seam.
- Blockers or open questions: Semantic styling remains intentionally bounded; do not broaden class count without visual evidence.
