# REVIEW: KENNEY ISOMETRIC BLOCKOUT FEASIBILITY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-kenney-isometric-blockout-feasibility`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `kenney-isometric-blockout-feasibility`
- Locks: `presentation-experiments, asset-pipeline`
- Review: `none`
- Review target workstream: `kenney-isometric-blockout-feasibility`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/KENNEY_ISOMETRIC_BLOCKOUT_FEASIBILITY.md`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `83d89fd85c5e`
- Landed implementation: `main@be3285c16ada` (K3D-1 archived complete; implemented from `main@9093c9ff1613`)
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Goal: Independently verify that K3D-1 produced a truthful, reproducible A/B presentation experiment with bounded Kenney source intake and no production-authority leakage.
- Review focus: seven-pack source inventory truth; bounded Isometric Miniature selection; Asset V2 source_work/archive-receipt/runtime/family/catalog health; exact shared-anchor/camera/route parity; debug-only ownership; production isolation; equivalent metrics; deterministic 1280x720 + 1280x720 → 2560x720 evidence; truthful roadmap/report handoff.
- Acceptance: Pass only if the landed experiment satisfies the archived K3D-1 acceptance contract, the two experimental Asset V2 families are healthy, A/B structural parity is independently reproducible, the comparison image is technically valid, and no production Hub/gameplay authority moved into the experiment. Do not pass or fail based on whether the reviewer personally prefers A or B.
- Non-goals: Do not choose the art direction. Do not implement K3D-2. Do not edit the reviewed runtime/debug implementation. Do not import 3D packs. Do not create a mesh/GLB asset contract. Do not add Retro Fantasy/Retro Urban.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Required Checks

1. Reconstruct the source inventory from the recorded local/archive evidence and verify all seven intended pack identities were accounted for without wholesale archive commits.
2. Verify K3D-1 selected no more than 24 PNGs total and that every selected source records pack, original member filename, hash, exact dimensions, alpha, semantic state, and use.
3. Verify each selected source followed:
   `asset_drop/source_work/experiments/kenney_presentation/<family>/<state>_source.png`
   → normalized `asset_drop/inbox/<family>/<state>.png`
   → Asset V2 ingest archive receipt
   → Asset V2-managed runtime output.
   The live inbox is expected to be empty after successful ingest; verify the consumed inbox path and hash through `k3d1_source_inventory.json`, the recorded ingest job/archive, and runtime hashes rather than requiring the normalized file to remain in inbox.
4. Verify both family contracts use the live `custodian.asset_family.v2` and `tile` kind contract, truthful per-state sizes, one static omni frame, and no hand-authored canonical runtime names.
5. Re-run current Asset V2 plan/status/doctor checks for both experimental families and inspect ingest/catalog receipts.
6. Re-run `python custodian/tools/validation/run_validation.py --test kenney_isometric_blockout_feasibility` and inspect `custodian/tools/validation/kenney_isometric_blockout_feasibility_smoke.gd`.
7. Independently verify the required anchors:
   - `Spawn_SouthReach=(-6,162)`
   - Forum South `(0,-2464)`
   - Adjudication Dais `(0,-3136)`
   - 32 px authored cell
   - 1280x720 evaluation viewport
8. Verify A and B share one spatial truth and equivalent camera transform; ensure B did not add a shortcut, different collision/navigation, or presentation-owned gameplay state.
9. Verify the debug experiment is absent from production boot/world-entry dependencies and disabling B leaves production/runtime state unchanged.
10. Verify `k3d1_metrics.json` uses exactly 30 settle + 120 sample frames for both modes, follows the existing `Performance.get_monitor()` patterns, and records unavailable metrics as null rather than zero. `selected_runtime_asset_count=16` is experiment-level loaded inventory in both modes, not a claim that native mode uses Kenney art; use presentation-node/instance/render counters for mode-density comparison.
11. Verify `k3d1_native.png` and `k3d1_kenney.png` are each 1280x720, use camera `(0,-2000)` / zoom `(0.30,0.30)`, and compose to `k3d1_ab_compare.png` at exactly 2560x720.
12. Verify the report and roadmap do not claim Kenney aesthetics are approved, do not declare CUSTODIAN 3D, and route K3D-2 back through the recorded authoring chat.

## Visual Review Boundary

The reviewer may verify technical visual facts such as:

- expected dimensions;
- same camera framing;
- no clipping caused by implementation defects;
- intended A/B labels/modes;
- correct selected assets rendering;
- no obvious stale/missing texture fallback.

The reviewer must not decide:

- whether miniature presentation is prettier;
- whether it feels sufficiently "CUSTODIAN";
- whether it is too toy-like;
- whether 3D should be adopted.

Those remain user/ChatGPT design decisions in the next planning refresh.

## Handoff

- Next workstream: `kenney-orthographic-3d-feasibility`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Refresh reason: `K3D-2 architecture and acceptance must reflect landed K3D-1 evidence plus the user's A/B judgment.`
- Next action: `Return the reviewed K3D-1 report/comparison to the authoring chat and re-author K3D-2 against current main.`
- Blockers or open questions: `none; K3D-1 is landed and archived complete. Review may run now.`
