# REVIEW: PROCGEN REGION FRAME PRESENTATION FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-procgen-region-frame-presentation-foundation`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-region-frame-presentation-foundation`
- Locks: `procgen-runtime, procgen-presentation`
- Review: `none`
- Review target workstream: `procgen-region-frame-presentation-foundation`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_REGION_FRAME_PRESENTATION_FOUNDATION.md`
- Reviewed main: `977488efdecf8bea72ffb2218b8bd0672e04f6ac`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Review modes: `code, architecture, runtime, visual`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the new Region Frame seam cleanly separates local biome, permanent exterior-world presentation and Archive Resolve without creating a new gameplay surface authority or silently relabeling placeholder underlay art as final Alpine content.
- Reviewed implementation acceptance: Reuse all acceptance criteria from the archived Region Frame foundation packet. Blocking examples include exterior-mask flooding from anything other than final CHASM semantics, internal chasms activating the global underlay, frame choice inferred from dominant biome **or `planet_key`/climate profile**, the reusable generator globally forcing Alpine instead of the current starting-region scene explicitly selecting it, an explicit alternate frame ID being overwritten, ocean leaking into the Alpine exterior mask, Drowned override breaking, Region Frame owning collision/navigation/streaming, or Archive Resolve state being absorbed into the frame owner.
- Review evidence: RF1 landed as `49cbd3982d145283ef7aeb85a921057f854ea88e`; archived implementation packet and `PROCGEN_REGION_FRAME_PRESENTATION_FOUNDATION_CLAUDE_SUMMARY.md`; live `ProcgenRegionFrameProfile` + `region_frames/alpine_plateau.tres`; NonwalkableSurfaceClassifier exterior/internal mask output; ProcGenTilemap frame selection/debug/level-data seam; DepthBackdrop input; Drowned compatibility path; implementation-created `procgen_region_frame_smoke.gd`; nonwalkable/cliff/underlay regressions; and all five MR6R1 next-slice proof-hardening items N1-01..N1-05: counted multi-frame flush coalescing with a direct-flush mutation failure, real A* path/connectivity plus genuinely UNSEEN exclusion, guaranteed road-decal removal, hermetic sole-source portal protection with in-test removal mutation, and non-trivial tree/trunk collision + runtime-blocker + cluster foliage parity. S1 remains at fingerprint `1773840677`.
- Correction threshold: Any gameplay-authority duplication, wrong exterior classification, underlay activation from internal-only chasms, silent fallback-as-final behavior, semantic/fingerprint change, or evidence gap preventing those claims is correction-worthy. Subjective Alpine art approval is not part of this foundation and must not be invented by review.
- Focused validation: Run manifest id `procgen_distant_chunk_unload` first and explicitly verify N1-01..N1-05 are all non-vacuous, including the two mutation-sensitive cases (direct flush and sole-source portal removal). Then run manifest id `procgen_region_frame`, followed by the live nonwalkable surface and void-cliff face/integration smokes, direct `drowned_basilica_underlay_smoke.gd`, manifest id `elevated_world_asset_contract`, manifest id `procgen_runtime_health`, the live `procgen_candidate_promotion_smoke.gd` fallback used by RF1 because `procgen_candidate_materializer_parity` is not registered/present, and S1 quick. Do not fail the review merely because the obsolete parity test name from the parent packet is absent. Prefer exact exterior/internal counts + profile/fallback IDs over full-frame imagery. Use at most one targeted gameplay-scale visual proof if machine evidence cannot distinguish permanent underlay from an internal ravine.
- Review focus: First verify all five N1 proof-hardening items are real and mutation-sensitive where claimed, and confirm RF1 did not change M6 production behavior merely to satisfy tests. Then verify one presentation-only frame profile owner; exact CHASM-only boundary flood from the classifier's real `map_size`; CHASM/OCEAN structural semantics unchanged; **explicit production-scene selection of Alpine while the reusable generator default and `PLANET_WORLD_PROFILES` remain frame-agnostic**; explicit alternate frame-ID passthrough; unresolved-frame fallback behavior; Drowned override precedence without semantic mutation; explicit `visual_fallback` telemetry on the Alpine stand-in; DepthBackdrop activation/bounds from exterior CHASM only; Archive Resolve independence; and no broad renderer/biome refactor.
- Acceptance: Produce a findings-first independent review on live main. The review cannot pass if any N1-01..N1-05 proof is vacuous or mutation-insensitive where its acceptance depends on the mutated source; if the starting-region scene/global generator distinction is wrong; if exterior/internal/ocean partitioning changes gameplay semantics; if internal-only chasms activate the permanent underlay; if Drowned override mutates semantics; or if fallback art is silently reported as final Alpine content. Blocking defects or material evidence gaps create `procgen-region-frame-presentation-foundation-review-corrections-1` plus paired re-review. A clean/non-blocking-only pass records Region Frame as stable presentation authority, dependency-unlocks the Alpine Asset V2 packet, and leaves that asset packet still human/source-art blocked until its six approved sources exist.
- Non-goals: Do not generate/approve Alpine art; do not implement Archive Resolve; do not add future frame types; do not change gameplay topology or biome classification; do not patch reviewed implementation code.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Agent Search Budget

Review only the archived foundation packet/summary; `CustodianContractMap._pick_planet_key`, `_build_planet_world_profile`, `_apply_map_generation_profile` plus `custodian_contract_map.tscn`; frame profile resource/script; nonwalkable classifier; DepthBackdrop/VoidCliffFace integration; narrow ProcGenTilemap frame hooks; and named focused tests. No general procgen archaeology.

## Handoff

- Next workstream: `procgen-alpine-plateau-underlay-assets`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh reason: The Alpine Asset V2 packet is technically scoped but remains source-art/human-approval gated; once the six sources exist, its reviewed-main/API binding should be reconciled here before ingest.
- Next action: After RFR1 passes and the six Alpine source images are available/approved, bring the RFR1 summary plus source-art decisions to the recorded ChatGPT planning chat and refresh the asset packet before ingest.
- Blockers or open questions: Six approved 1536x1024 source images and human art-direction approval remain required.
