# REVIEW: PROCGEN DISTANT CHUNK UNLOAD REVIEW CORRECTIONS 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-procgen-distant-chunk-unload-review-corrections-1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-distant-chunk-unload-review-corrections-1`
- Locks: `procgen-streaming, navigation-runtime`
- Review: `none`
- Review target workstream: `procgen-distant-chunk-unload-review-corrections-1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_DISTANT_CHUNK_UNLOAD_REVIEW_CORRECTIONS_1.md`
- Reviewed main: `<fill when the correction lands>`
- Review modes: `code, architecture, runtime`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Goal: Independently verify that correction cycle 1 actually closes `R0-01` through `R0-05` from the cycle-0 review without reopening accepted M6 scope or introducing a new defect.
- Reviewed implementation acceptance: Reuse the correction packet's own Acceptance (one falsifiable result per finding ID) and the original archived M6 packet's full 15-item Acceptance contract for anything the correction's work surface touches.
- Review evidence: Cycle-0 Independent Review receipt and findings `R0-01`-`R0-05` on the archived M6 packet; the correction packet's closing summary; the extended `procgen_distant_chunk_unload_smoke.gd`; live `_drain_residency_eviction()`/`_flush_streaming_visual_rebuilds()`/`_process_streaming_reveal_queue()`.
- Correction threshold: Report each of `R0-01`-`R0-05` as `fixed`, `unresolved`, or `regressed` using its original ID. A finding reported `fixed` must be independently re-verified (re-run the relevant new assertion/trace the relevant code path yourself), not accepted from the correction's own closing-summary claim. Any `unresolved` or `regressed` finding, or any newly discovered defect, is `blocking_defect`/`evidence_gap` under the same rules as cycle 0.
- Focused validation: Run the extended `procgen_distant_chunk_unload` smoke first and confirm it actually exercises a real `NavigationSystem` rebuild, a real protected-anchor (portal/ingress/clearance) source, foliage kind/cluster/collision/blocker-registration parity, and a combined before/after painted-cell/cache/road count fixture -- do not accept "the smoke is green" alone as proof those four sections exist and assert the right thing. Re-run the full regression list named in the correction packet's own Validation field, plus S1 quick requiring `determinism_ok=true` at fingerprint `1773840677`. Run packet/review-pairing/docs/manifest checks and `git diff --check`.
- Review focus: Verify `R0-01`'s fix actually changes the multi-frame cost profile (the eviction-triggered flush now batches on `streaming_visual_rebuild_interval_sec` rather than firing once per eviction-frame) rather than merely renaming the same unconditional call. Verify each of the four new smoke sections genuinely constructs the real object it claims to (a live `NavigationSystem`, a live portal/ingress/clearance source, the `_foliage_nodes` entry's own fields, real `get_used_cells()` counts) rather than re-asserting the same provider-level calls cycle 0 already found insufficient.
- Acceptance: Produce a findings-first independent review receipt on current live main. A clean pass (all five findings `fixed`, no new findings) closes S7 and makes D1/D2/D3 refresh-eligible. Any finding still `unresolved`/`regressed`, or any new blocking defect/material evidence gap, creates `procgen-distant-chunk-unload-review-corrections-2` plus its paired re-review (cycle 2) and keeps S7 open; cycle 2 is the max before `human_required`.
- Non-goals: No new findings outside what cycle-0 raised and what the correction's own work surface could plausibly regress. No implementation of D1-D3, GenerationGrid, or renderer batching. Do not edit the reviewed correction.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Agent Search Budget

Start from exactly: the correction packet's own Required correction list, its closing summary, the extended `procgen_distant_chunk_unload_smoke.gd`, and the exact `proc_gen_tilemap.gd` functions it names (`_drain_residency_eviction`, `_flush_streaming_visual_rebuilds`, `_process_streaming_reveal_queue`). Do not re-review the parts of M6 cycle 0 already passed cleanly.

## Handoff

- Next action: Claim after `procgen-distant-chunk-unload-review-corrections-1` completes/archives.
- Blockers or open questions: None at authoring time.
