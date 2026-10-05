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
- Reviewed main: `35cedfb2a74409b700875c64274cacfb837b4818`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Summary backlink: Every durable implementation/review/recovery/correction/closeout summary for this packet must include `Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4` exactly.
- Goal: Complete Archive Resolve V1 with restrained semantic pre-echo, the one-time ingress/spawn resolution sequence, and a visibly lighter reacquisition treatment for previously resolved unloaded terrain.
- Completion boundary: Done when a small bounded presentation-class vocabulary can influence echo/timing without gaining gameplay authority; first contract entry presents a controlled local Archive Resolve expansion while preserving immediate player control inside the safety pocket; previously resolved unloaded terrain uses a shorter reacquisition treatment; and the final effect remains subtle enough that normal settled play contains no persistent reveal UI/VFX.
- Current measured state: AR1/ARR1 are reviewed complete. AR2 implementation + renderer recovery + human Dropbox approval + fresh-context paired review are complete/passed; S1 remains `1773840677`. The separate P0 `contract-world-playable-region-spawn-validity-fix` is now also implemented and independently reviewed/passed with 0 blocking defects / 0 material evidence gaps. Its production invariant is: final Operator spawn on `ProcGenTilemap` must be painted floor outside ingress clearance, pass `is_valid_spawn_cell()`, pass `is_runtime_navigation_walkable()`, and belong to `get_main_playable_component()`; both compound selection and `player_spawn` fallback use the same predicate and fail closed before moving the Operator. Review findings R0-01..03 are non-blocking/deferred: R0-01 notes repeated fresh full-map component fills during one contract install; AR3 must not add another component query or cache/change that authority. R0-02 concerns only the non-`ProcGenTilemap` fallback and is not part of production contract-world AR3. R0-03 notes that the spawn-fix smoke did not drive the full `_on_contract_generated()` path with a real registered ingress + real compound or reproduce the original underlevel-void playtest end to end; AR3 validation now owns that full-path proof because its ingress presentation is attached exactly there.
- Evidence: `design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`; reviewed AR1/ARR1/AR2 receipts; `PROCGEN_ARCHIVE_RESOLVE_SHADER_RECOVERY_1_CLAUDE_SUMMARY.md`; `REVIEW_PROCGEN_ARCHIVE_RESOLVE_SHADER_CLAUDE_SUMMARY.md`; Dropbox `/CUSTODIAN/visual_review/procgen-archive-resolve-shader-recovery-1/20261005T025507Z/REVIEW_MANIFEST.json`; archived `CONTRACT_WORLD_PLAYABLE_REGION_SPAWN_VALIDITY_FIX.md`; `REVIEW_CONTRACT_WORLD_PLAYABLE_REGION_SPAWN_VALIDITY_FIX_CLAUDE_SUMMARY.md`; live `ContractWorldLoader._on_contract_generated/_position_operator`; live read-only semantic seams `ProcGenTilemap.get_surface_material_at_tile`, `is_road_surface_tile`, `get_elevation_data_at_tile`, wall TileMap authority, `is_sundered_keep_frontage_protected`, and authored-landmark material/claim authority.
- Task-specific authority: `STREAMING_REVEAL_PRESENTATION_V1.md`; reviewed AR1/AR2 implementation; existing procgen surface/road/elevation/wall/authored-landmark owners queried read-only; reviewed playable-region spawn validity owns whether a final runtime spawn is valid. AR3 must consume the already-final Operator position after `ContractWorldLoader._position_operator()` succeeds. It may not call `get_main_playable_component()` itself, introduce a spawn-validity cache, or revalidate/move the Operator.
- Work surface: `custodian/game/world/procgen/streaming/procgen_reveal_presentation.gd`, `archive_resolve.gdshader`, one small read-only presentation-class adapter under the same streaming namespace, the narrow `ProcGenTilemap` Archive Resolve adapter/API, and one bounded `ContractWorldLoader` call after final valid Operator placement. Add focused V1 smoke + a renderer-backed Moment Forge comparison. Do not move semantic or spawn-validity authority into presentation code.
- Change: Add no more than the design's bounded semantic presentation classes. Classify each tile only from existing read-only authorities: `road` from live road/ruined-road/soft-path authority; `constructed` from hardened civic/industrial/bridge surface material; `wall_cliff` from existing wall/elevation/edge metadata; `major_hero_landmark` only when an existing authored-landmark material/claim such as the Sundered Keep frontage already says so; otherwise `natural`. Do not depend on or pre-implement the not-yet-landed generic Landmark Vocabulary program. Encode the bounded class as render-only assignment data (the AR2 `.b` channel is reserved for AR3 if still clean) rather than caching a second semantic map.
- Change: Class differences stay subtle: natural remains mostly soot/dither; constructed may use slightly straighter registration; roads may show a brief interrupted vector; wall/cliff may pre-echo a faint contour; major/hero authored landmarks may silhouette roughly 100-150 ms early. No class may expose exact hidden content or alter request/commit order.
- Change: Add a one-time presentation-only ingress trigger on `ProcGenTilemap`, called by `ContractWorldLoader` only **after** `_position_operator()` returns success **and after the remaining contract-world placement phase completes, including `_place_gothic_compound_connection()` when enabled**, in the real `_on_contract_generated()` flow, immediately before `_refresh_camera()` / contract-ready closeout. The trigger consumes the Operator's already-final world/tile position; it does not query `get_main_playable_component()`, choose a spawn, cache validity, or move the Operator. It centers the effect on that actual runtime tile, keeps a small committed safety pocket completely settled/visible, and may re-veil/re-resolve already-committed nearby cells outward over roughly 1.0-1.5 seconds. It must not enqueue discovery, repaint/unpaint authoritative tiles, delay control, or mutate collision/navigation/topology. Generation's early `_prepare_streaming_reveal()` prime around `get_player_spawn()` remains streaming authority and is not the authored arrival choreography.
- Change: Reacquisition consumes AR1/AR2 lifecycle identity and the existing reacquisition custom-data bit; it skips/shortens semantic pre-echo, reduces registration/misregistration intensity, and settles roughly within 100-150 ms. First resolve and reacquisition must remain deterministic and independently measurable.
- Preserve: Every semantic owner remains read-only; hidden presentation conveys no quest/discovery knowledge; no uncommitted cell is exposed; reviewed spawn validity and ingress-clearance correctness; immediate player control once a valid spawn exists; AR1/AR2 batching/performance/pause/live-toggle/actor-order contracts; S1 fingerprint `1773840677` unless independently approved; no permanent overlay after settlement.
- Non-goals: No new landmark semantics; no map discovery mechanic; no audio production requirement; no gameplay gating on reveal completion; no lore text/UI; no generation changes; no broad per-biome special cases.
- Acceptance: (1) presentation classes are bounded to the locked vocabulary and queried without copying semantic authority; (2) class assignment cannot leak exact hidden content or alter streaming/gameplay state; (3) ingress choreography is invoked only from the real successful `_on_contract_generated()` flow after final Operator placement **and after late contract-world placement including the real Gothic compound connection/gate**, immediately before camera refresh/ready, and centers on that exact final tile; (4) AR3 performs no component flood fill/cache/spawn revalidation and never moves the Operator; (5) a committed safety pocket is immediately visible and control is never gated by presentation; (6) surrounding already-committed/normal reveal cells resolve outward over the tuned ~1.0-1.5s window without changing request/commit/lifecycle truth; (7) reacquisition is measurably shorter and visually weaker than first resolve, target ~100-150ms; (8) same seed/path produces identical class/echo/order identity; (9) pause/reduced-effects/disabled modes remain valid; (10) batching/material/custom-data write discipline from AR2 is preserved; (11) S1 remains `1773840677` unless independently approved; (12) the full contract-generated integration proof includes a real compound and registered world ingress and asserts the final Operator tile is canonically valid/in the main component before the AR3 trigger, closing spawn-review R0-03's evidence shape; (13) gameplay-scale human review reads as Archive resolution rather than loading, fog fade, square pop, holographic grid, or persistent UI/VFX.
- Validation: First add one **end-to-end contract-world integration fixture** that drives `ContractWorldLoader._on_contract_generated()` with a real generated `ProcGenTilemap`, real compound data, and at least one registered world ingress. It must prove ordering: registered ingress placement -> reviewed final Operator placement -> canonical validity/main-component assertion -> remaining contract-world placement including a real Gothic compound connection/gate -> AR3 ingress trigger -> camera refresh/control-ready; it must also prove the trigger receives the actual final Operator tile and that no underlevel/exterior/disconnected tile can become the arrival center. This is the explicit carry-forward closure for spawn-review R0-03. Do not satisfy it with source-text ordering checks alone. Then add focused class-mapping/read-only tests that mutate underlying surface/road/elevation/authored-claim fixtures and prove the adapter follows those owners without retaining a shadow semantic registry. Measure first resolve vs reacquisition duration/intensity and deterministic class identity; verify pause and disabled/reduced-effects fallbacks. Re-run `contract_world_playable_region_spawn_validity`, `contract_world_ingress_spawn_clearance`, real world-ingress placement coverage, `procgen_archive_resolve_shader`, `procgen_reveal_presentation`, pause-aware streaming, chunk lifecycle/cache/unload, runtime health, region frame, camera handoff, and S1 quick. Require S1 `1773840677` unless independently approved. R0-01 is observability only here: record if AR3 adds any new `get_main_playable_component()` call (it should add zero); do not optimize/cache the existing spawn query in this packet. After objective checks pass, run the real graphical renderer/Moment Forge gameplay-scale scenario and publish compact evidence via `publish_review_artifacts.py --important` under workstream `procgen-archive-resolve-semantic-echo`. Ask whether ingress resolves outward without delaying control/obscuring threats, reacquisition is clearly lighter/shorter, semantic echo adds useful structure without leaking gameplay/discovery knowledge, and settled play stays ordinary. Record the Dropbox manifest plus explicit user/ChatGPT decision in the summary; the agent cannot self-approve aesthetics/game feel. Every durable implementation/closeout summary must include exactly: `Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`.
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
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Refresh instruction: Refresh completed in the recorded authoring chat after clean AR2 review; no further pre-implementation design refresh is required.

## Handoff

- Next workstream: `review-procgen-archive-resolve-semantic-echo`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Refresh reason: `none after this packet's required pre-implementation refresh is completed`
- Next action: Spawn correctness is reviewed/passed. Claim AR3 now; implement the full-path post-placement ingress trigger + bounded semantic echo/reacquisition, complete objective + real-renderer evidence, obtain explicit human visual/game-feel approval through the recorded authoring chat, and archive so the paired fresh-context AR3 review can claim automatically.
- Blockers or open questions: None. Reviewed AR2, this planning refresh, and reviewed playable-region spawn validity are complete. Keep semantic classes bounded; do not broaden class count, invent future Landmark Vocabulary authority, or fold R0-01 component-query optimization into AR3.