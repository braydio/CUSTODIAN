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
- Reviewed main: `81494285dfdb41240045a55cb6117586b32f539f`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Review modes: `code, architecture, runtime, visual`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the new Region Frame seam cleanly separates local biome, permanent exterior-world presentation and Archive Resolve without creating a new gameplay surface authority or silently relabeling placeholder underlay art as final Alpine content.
- Reviewed implementation acceptance: Reuse all acceptance criteria from the archived Region Frame foundation packet. Blocking examples include exterior-mask flooding from anything other than final CHASM semantics, internal chasms activating the global underlay, frame choice inferred from dominant biome **or `planet_key`/climate profile**, the reusable generator globally forcing Alpine instead of the current starting-region scene explicitly selecting it, an explicit alternate frame ID being overwritten, ocean leaking into the Alpine exterior mask, Drowned override breaking, Region Frame owning collision/navigation/streaming, or Archive Resolve state being absorbed into the frame owner.
- Review evidence: Archived implementation packet/summary; live `ProcgenRegionFrameProfile`; NonwalkableSurfaceClassifier exterior/internal mask output; ProcGenTilemap frame selection/debug/level-data seam; DepthBackdrop input; Drowned compatibility path; focused region-frame smoke; nonwalkable/cliff/underlay regressions; reviewed M6 cycle-1 correction/re-review evidence; the RF1-carried M6 proof-hardening assertions (multi-frame coalescing count, actual A* reachability, guaranteed road-removal fixture); S1.
- Correction threshold: Any gameplay-authority duplication, wrong exterior classification, underlay activation from internal-only chasms, silent fallback-as-final behavior, semantic/fingerprint change, or evidence gap preventing those claims is correction-worthy. Subjective Alpine art approval is not part of this foundation and must not be invented by review.
- Focused validation: Run the hardened `procgen_distant_chunk_unload` proof first and verify it cannot skip the empty-queue/multi-frame coalescing case, A* reachability case, or road-removal case. Then run the implementation-created region-frame smoke, followed by nonwalkable surface, void-cliff face/integration, Drowned Basilica underlay, elevated-world asset contract, M6 residency again after integration, runtime-health, candidate materializer parity and S1. Prefer exact exterior/internal counts + profile/fallback IDs over full-frame imagery. Use at most one targeted gameplay-scale visual proof if needed to distinguish permanent underlay from an internal ravine.
- Review focus: First verify the carried-forward M6 proof hardening closes its three test-shape gaps without adding a second scheduler or broadening residency ownership; if RF1 changed production M6 code, inspect only the narrow failing seam that justified it. Then verify one profile owner; exact boundary flood from the classifier's real `map_size`; CHASM/OCEAN structural semantics unchanged; **explicit starting-region scene selection of Alpine with `PLANET_WORLD_PROFILES` remaining frame-agnostic**; alternate frame-ID passthrough; development Drowned override; explicit fallback telemetry; DepthBackdrop exterior-only activation; Archive Resolve independence; no broad renderer/biome refactor.
- Acceptance: Produce a findings-first independent review on live main. The review cannot pass if the carried-forward M6 proof still conditionally skips road removal, checks navigation membership without a real path/connectivity result, or fails to exercise multiple eviction frames under one rebuild interval. Blocking defects or material evidence gaps create `procgen-region-frame-presentation-foundation-review-corrections-1` plus paired re-review. A clean/non-blocking-only pass makes the Alpine underlay asset integration packet dependency-eligible and records the frame foundation as stable presentation authority.
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
