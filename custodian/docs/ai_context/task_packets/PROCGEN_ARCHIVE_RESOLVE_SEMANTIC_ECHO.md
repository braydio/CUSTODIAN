# PROCGEN ARCHIVE RESOLVE SEMANTIC ECHO AND SPAWN

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-archive-resolve-semantic-echo`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `review-procgen-archive-resolve-shader, review-contract-world-playable-region-spawn-validity-fix`
- Locks: `procgen-presentation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, visual`
- Paired review workstream: `review-procgen-archive-resolve-semantic-echo`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial semantic-presentation/spawn choreography change; objective technical review plus separate human gameplay-scale visual approval`
- Reviewed main: `4cdabbd4671590282917397bd5eaba38fcf57ce0`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Summary backlink: Every durable implementation/review/recovery/correction/closeout summary for this packet must include `Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7` exactly.
- Goal: Complete Archive Resolve V1 with restrained semantic pre-echo, the one-time ingress/spawn resolution sequence, and a visibly lighter reacquisition treatment for previously resolved unloaded terrain.
- Completion boundary: Done when a small bounded presentation-class vocabulary can influence echo/timing without gaining gameplay authority; first contract entry presents a controlled local Archive Resolve expansion while preserving immediate player control inside the safety pocket; previously resolved unloaded terrain uses a shorter reacquisition treatment; and the final effect remains subtle enough that normal settled play contains no persistent reveal UI/VFX.
- Current measured state: AR1/ARR1 are reviewed complete. AR2 implementation + renderer recovery are landed and the fresh-context paired AR2 review passed with 0 blocking defects / 0 material evidence gaps; S1 remains `1773840677`. The live archived recovery receipt and recovery summary now both correctly record that ChatGPT/user visual approval occurred in this recorded authoring chat after review of the Dropbox contact sheet/keyframes, so the paired review's stale provenance note is resolved by current repository truth. A separate current-main playtest then reproduced an Operator spawn outside the accepted playable region over exterior underlevel/void presentation; that correctness defect is now owned by `contract-world-playable-region-spawn-validity-fix` and must pass review before AR3's one-time ingress presentation can execute. The design still locks five broad presentation classes at most: natural, constructed, road, wall/cliff, and major/hero landmark.
- Evidence: `design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`; reviewed AR1/ARR1/AR2 receipts; `PROCGEN_ARCHIVE_RESOLVE_SHADER_RECOVERY_1_CLAUDE_SUMMARY.md`; `REVIEW_PROCGEN_ARCHIVE_RESOLVE_SHADER_CLAUDE_SUMMARY.md`; Dropbox `/CUSTODIAN/visual_review/procgen-archive-resolve-shader-recovery-1/20261005T025507Z/REVIEW_MANIFEST.json`; live read-only semantic seams `ProcGenTilemap.get_surface_material_at_tile`, `is_road_surface_tile`, `get_elevation_data_at_tile`, wall TileMap authority, `is_sundered_keep_frontage_protected`, and the future-neutral authored-landmark material ID.
- Task-specific authority: `STREAMING_REVEAL_PRESENTATION_V1.md`; reviewed AR1/AR2 implementation; existing procgen surface/road/elevation/wall/authored-landmark owners queried read-only; reviewed `contract-world-playable-region-spawn-validity-fix` owns whether a final runtime spawn is valid. AR3 owns only how an already-valid arrival/reacquisition is presented.
- Work surface: `custodian/game/world/procgen/streaming/procgen_reveal_presentation.gd`, `archive_resolve.gdshader`, one small read-only presentation-class adapter under the same streaming namespace, the narrow `ProcGenTilemap` Archive Resolve adapter/API, and one bounded `ContractWorldLoader` call after final valid Operator placement. Add focused V1 smoke + a renderer-backed Moment Forge comparison. Do not move semantic or spawn-validity authority into presentation code.
- Change: Add no more than the design's bounded semantic presentation classes. Classify each tile only from existing read-only authorities: `road` from live road/ruined-road/soft-path authority; `constructed` from hardened civic/industrial/bridge surface material; `wall_cliff` from existing wall/elevation/edge metadata; `major_hero_landmark` only when an existing authored-landmark material/claim such as the Sundered Keep frontage already says so; otherwise `natural`. Do not depend on or pre-implement the not-yet-landed generic Landmark Vocabulary program. Encode the bounded class as render-only assignment data (the AR2 `.b` channel is reserved for AR3 if still clean) rather than caching a second semantic map.
- Change: Class differences stay subtle: natural remains mostly soot/dither; constructed may use slightly straighter registration; roads may show a brief interrupted vector; wall/cliff may pre-echo a faint contour; major/hero authored landmarks may silhouette roughly 100-150 ms early. No class may expose exact hidden content or alter request/commit order.
- Change: Add a one-time presentation-only ingress trigger on `ProcGenTilemap`, called by `ContractWorldLoader` only **after** the final Operator position has passed the reviewed playable-region spawn-validity contract. The trigger centers on the actual runtime Operator tile, keeps a small committed safety pocket completely settled/visible, and may re-veil/re-resolve already-committed nearby cells outward over roughly 1.0-1.5 seconds. It must not enqueue discovery, repaint/unpaint authoritative tiles, move the Operator, delay control, or mutate collision/navigation/topology. Generation's early `_prepare_streaming_reveal()` prime around `get_player_spawn()` remains streaming authority and is not the authored arrival choreography.
- Change: Reacquisition consumes AR1/AR2 lifecycle identity and the existing reacquisition custom-data bit; it skips/shortens semantic pre-echo, reduces registration/misregistration intensity, and settles roughly within 100-150 ms. First resolve and reacquisition must remain deterministic and independently measurable.
- Preserve: Every semantic owner remains read-only; hidden presentation conveys no quest/discovery knowledge; no uncommitted cell is exposed; reviewed spawn validity and ingress-clearance correctness; immediate player control once a valid spawn exists; AR1/AR2 batching/performance/pause/live-toggle/actor-order contracts; S1 fingerprint `1773840677` unless independently approved; no permanent overlay after settlement.
- Non-goals: No new landmark semantics; no map discovery mechanic; no audio production requirement; no gameplay gating on reveal completion; no lore text/UI; no generation changes; no broad per-biome special cases.
- Acceptance: (1) presentation classes are bounded to the locked vocabulary and are queried without copying semantic authority; (2) class assignment cannot leak exact hidden content or alter streaming/gameplay state; (3) ingress choreography starts only after the reviewed final spawn-validity path succeeds and centers on the actual runtime Operator position; (4) a committed safety pocket is immediately visible and control is never gated by presentation; (5) surrounding already-committed/normal reveal cells resolve outward over the tuned ~1.0-1.5s window without changing request/commit/lifecycle truth; (6) reacquisition is measurably shorter and visually weaker than first resolve, target ~100-150ms; (7) same seed/path produces identical class/echo/order identity; (8) pause/reduced-effects/disabled modes remain valid; (9) batching/material/custom-data write discipline from AR2 is preserved; (10) S1 remains `1773840677` unless independently approved; (11) gameplay-scale human review reads as Archive resolution rather than loading, fog fade, square pop, holographic grid, or persistent UI/VFX.
- Validation: Add focused class-mapping/read-only tests that deliberately mutate underlying surface/road/elevation/authored-claim fixtures and prove the adapter follows those owners without retaining a shadow semantic registry. Add an integration fixture that positions the Operator through the reviewed contract-world spawn path, invokes the new ingress presentation trigger at that actual final tile, asserts immediate control/safety pocket, and proves streaming/lifecycle/collision/navigation fingerprints are unchanged. Measure first resolve vs reacquisition duration/intensity and deterministic class identity; verify pause and disabled/reduced-effects fallbacks. Re-run `procgen_archive_resolve_shader`, `procgen_reveal_presentation`, pause-aware streaming, chunk lifecycle/cache/unload, runtime health, region frame, the reviewed playable-region spawn-validity smoke, and S1 quick. After objective checks pass, run the real graphical renderer/Moment Forge scenario (extend the reusable Archive Resolve scenario rather than duplicating it when clean) and publish compact evidence via `publish_review_artifacts.py --important` under workstream `procgen-archive-resolve-semantic-echo`. Ask whether ingress resolves outward without delaying control/obscuring threats, reacquisition is clearly lighter/shorter, semantic echo adds useful structure without leaking gameplay/discovery knowledge, and settled play stays ordinary. Record the Dropbox manifest plus explicit decision in the summary; the agent cannot self-approve aesthetics/game feel.
- Task overrides: `none`
- Deferred: Optional aggregate mechanical/relay audio, later accessibility presets beyond V1 controls, and any future biome-specific presentation nuance justified by actual visual review.

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

- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh instruction: Refresh completed in the recorded authoring chat after clean AR2 review; no further pre-implementation design refresh is required.

## Handoff

- Next workstream: `review-procgen-archive-resolve-semantic-echo`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh reason: `none after this packet's required pre-implementation refresh is completed`
- Next action: Wait only for `review-contract-world-playable-region-spawn-validity-fix`; then implement AR3, complete objective + real-renderer evidence, obtain explicit human visual/game-feel approval through the recorded authoring chat, and archive so the paired fresh-context AR3 review can claim automatically.
- Blockers or open questions: Reviewed AR2 and this planning refresh are complete. The only dependency gate is the separate reviewed playable-region spawn-validity fix. Keep semantic classes bounded; do not broaden class count or invent future Landmark Vocabulary authority.