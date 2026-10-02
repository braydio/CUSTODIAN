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
- Reviewed main: `1c12e0900f031c09032e9cb673ab6a53f93c60df`
- Review modes: `code, architecture, runtime, visual`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the new Region Frame seam cleanly separates local biome, permanent exterior-world presentation and Archive Resolve without creating a new gameplay surface authority or silently relabeling placeholder underlay art as final Alpine content.
- Reviewed implementation acceptance: Reuse all acceptance criteria from the archived Region Frame foundation packet. Blocking examples include exterior-mask flooding from anything other than final CHASM semantics, internal chasms activating the global underlay, frame choice inferred from dominant biome, ocean leaking into the Alpine exterior mask, Drowned override breaking, Region Frame owning collision/navigation/streaming, or Archive Resolve state being absorbed into the frame owner.
- Review evidence: Archived implementation packet/summary; live `ProcgenRegionFrameProfile`; NonwalkableSurfaceClassifier exterior/internal mask output; ProcGenTilemap frame selection/debug/level-data seam; DepthBackdrop input; Drowned compatibility path; focused region-frame smoke; nonwalkable/cliff/underlay regressions; reviewed M6 cycle-1 correction/re-review evidence; S1.
- Correction threshold: Any gameplay-authority duplication, wrong exterior classification, underlay activation from internal-only chasms, silent fallback-as-final behavior, semantic/fingerprint change, or evidence gap preventing those claims is correction-worthy. Subjective Alpine art approval is not part of this foundation and must not be invented by review.
- Focused validation: Run the implementation-created region-frame smoke first, then nonwalkable surface, void-cliff face/integration, Drowned Basilica underlay, elevated-world asset contract, M6 residency, runtime-health, candidate materializer parity and S1. Prefer exact exterior/internal counts + profile/fallback IDs over full-frame imagery. Use at most one targeted gameplay-scale visual proof if needed to distinguish permanent underlay from an internal ravine.
- Review focus: One profile owner; exact boundary flood from map bounds; CHASM/OCEAN structural semantics unchanged; default Alpine frame vs development override; explicit fallback telemetry; DepthBackdrop exterior-only activation; Archive Resolve independence; no broad renderer/biome refactor.
- Acceptance: Produce a findings-first independent review on live main. Blocking defects or material evidence gaps create `procgen-region-frame-presentation-foundation-review-corrections-1` plus paired re-review. A clean/non-blocking-only pass makes the Alpine underlay asset integration packet dependency-eligible and records the frame foundation as stable presentation authority.
- Non-goals: Do not generate/approve Alpine art; do not implement Archive Resolve; do not add future frame types; do not change gameplay topology or biome classification; do not patch reviewed implementation code.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Agent Search Budget

Review only the archived foundation packet/summary, frame profile resource/script, nonwalkable classifier, DepthBackdrop/VoidCliffFace integration, narrow ProcGenTilemap frame hooks and named focused tests. No general procgen archaeology.

## Handoff

- Next action: Claim only after `procgen-region-frame-presentation-foundation` lands.
- Blockers or open questions: Subjective final Alpine art remains human-owned and is outside this review.
