# PROCGEN ARCHIVE RESOLVE SEMANTIC ECHO AND SPAWN

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-archive-resolve-semantic-echo`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `review-procgen-archive-resolve-shader`
- Locks: `procgen-presentation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, visual`
- Paired review workstream: `review-procgen-archive-resolve-semantic-echo`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial semantic-presentation/spawn choreography change; objective technical review plus separate human gameplay-scale visual approval`
- Reviewed main: `73a3239fbb81df50a8b7bdc108291961b165896b`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Goal: Complete Archive Resolve V1 with restrained semantic pre-echo, the one-time ingress/spawn resolution sequence, and a visibly lighter reacquisition treatment for previously resolved unloaded terrain.
- Completion boundary: Done when a small bounded presentation-class vocabulary can influence echo/timing without gaining gameplay authority; first contract entry presents a controlled local Archive Resolve expansion while preserving immediate player control inside the safety pocket; previously resolved unloaded terrain uses a shorter reacquisition treatment; and the final effect remains subtle enough that normal settled play contains no persistent reveal UI/VFX.
- Current measured state: AR1/ARR1 are reviewed complete. AR2 implementation is landed on main (parent implementation commit `085a38a5`) but its original closeout lacked the mandatory graphical-renderer/human visual evidence, so `procgen-archive-resolve-shader-recovery-1` now owns that missing gate and `review-procgen-archive-resolve-shader` depends on the recovery. The design still locks five broad presentation classes at most: natural, constructed, road, wall/cliff, and major/hero landmark. Do not finalize their live query mapping until the recovered AR2 review passes.
- Evidence: `design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`; AR1/AR2 packets; current procgen semantic surface/road/macro/landmark query authorities after refresh.
- Task-specific authority: `STREAMING_REVEAL_PRESENTATION_V1.md`; landed AR1/AR2 implementation; live semantic owners queried read-only.
- Work surface: AR presentation owner, one small presentation-class adapter/query, ingress/spawn initialization seam, optional aggregate audio callback stub only if trivial and unused by default, focused V1 smoke, and gameplay-scale comparison evidence.
- Change: Add no more than the design's bounded semantic presentation classes. Their only effects are tiny echo/timing/registration differences. Natural terrain remains mostly soot/dither; constructed surfaces may use slightly straighter registration; roads may show a brief interrupted vector; wall/cliff silhouettes may pre-echo slightly; major/hero landmarks may silhouette roughly 100-150 ms early. Initial spawn keeps a valid resolved safety pocket and allows control immediately while nearby committed terrain resolves outward over roughly 1-1.5 seconds. Reacquisition skips or shortens echo, reduces registration intensity, and settles roughly within 100-150 ms. All choices remain deterministic.
- Preserve: Every semantic owner remains read-only; hidden presentation conveys no quest/discovery knowledge; no uncommitted cell is exposed; player safety/readability; AR1/AR2 performance and pause contracts; no permanent overlay after settlement.
- Non-goals: No new landmark semantics; no map discovery mechanic; no audio production requirement; no gameplay gating on reveal completion; no lore text/UI; no generation changes; no broad per-biome special cases.
- Acceptance: Presentation classes are bounded and queried without copying semantic authority; semantic echo changes only presentation timing/style; initial spawn never delays control once safety pocket is valid; reacquisition is measurably shorter/weaker than first resolve; same seed/path yields the same echo/order identity; reduced-effects/disabled modes remain valid; full V1 gameplay-scale review reads as an Archive process rather than loading, fog fade, square pop, or neon hologram.
- Validation: **Refresh in the recorded planning chat after the paired AR2 review passes before implementation.** Re-audit current semantic owners, then add focused class-mapping/read-only tests, spawn-control/safety-halo timing checks, first-resolve vs reacquire duration/intensity checks, deterministic identity, pause, and disabled/reduced-effects fallbacks. Re-run reviewed AR1/AR2 focused smokes and affected streaming/runtime-health tests before changed-file closeout. Only after objective checks pass, publish the smallest gameplay-scale evidence through `python3 custodian/tools/iteration/publish_review_artifacts.py --important ...` under workstream `procgen-archive-resolve-semantic-echo`, following `VISUAL_REVIEW_HANDOFF.md`. Ask whether initial ingress resolves without delaying control or obscuring threats, reacquisition is visibly lighter/shorter than first resolve, and semantic echo adds useful structure without leaking gameplay/discovery knowledge or becoming visual clutter. Record the Dropbox manifest path in the completion summary; the execution agent does not self-approve game feel/art direction.
- Task overrides: `none`
- Deferred: Optional aggregate mechanical/relay audio, later accessibility presets beyond V1 controls, and any future biome-specific presentation nuance justified by actual visual review.

## Temporary Refresh Gate — REMOVE WHEN THIS PACKET IS REFRESHED

**DO NOT IMPLEMENT THIS PACKET UNTIL IT HAS BEEN REFRESHED WITH THE USER IN THIS CHAT:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7

Bring the landed predecessor implementation summary, Independent Review receipt, and any human visual-review manifest/decision back to that conversation. The execution agent must not perform this architecture/design refresh on its own.

This packet is intentionally pre-authored before the final reviewed AR2 renderer contract and before the live Landmark/semantic owner surface is final.

After `review-procgen-archive-resolve-shader` passes following `procgen-archive-resolve-shader-recovery-1`:

1. bring the recovered AR2 summary, paired-review receipt, Dropbox manifest, and explicit user/ChatGPT visual decision to https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7;
2. fetch current `origin/main`;
3. re-audit the exact read-only semantic query owners for surface/road/wall-cliff/landmark classification;
4. update `Reviewed main`, measured state, work surface, class mapping, spawn seam, validation, and visual evidence plan;
5. remove this entire **Temporary Refresh Gate** section;
6. only then set `Status: ready` / `Dispatch: auto`.

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


## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh instruction: Bring the landed predecessor implementation/review summary and any new live-state evidence back to this ChatGPT conversation. Re-derive this packet here with the user against current `main` before changing it to `ready/auto`. Do not let the execution agent silently reinterpret architecture, scope, sequencing, visual direction, or acceptance during the refresh.

## Handoff

- Next workstream: `review-procgen-archive-resolve-semantic-echo`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh reason: `none after this packet's required pre-implementation refresh is completed`
- Next action: After reviewed AR2 lands, return to the recorded planning chat and refresh this packet in place; once implemented, objectively validated, and human visual/game-feel approval is recorded through Dropbox, complete/archive AR3 so its paired fresh-context technical review can claim automatically.
- Blockers or open questions: This packet must not be implemented before reviewed AR2 and the required planning refresh. Keep semantic classes bounded; do not broaden class count without reviewed visual evidence.
