# REVIEW: KENNEY ISOMETRIC BLOCKOUT FEASIBILITY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-kenney-isometric-blockout-feasibility`
- Kind: `review`
- Status: `complete`
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
- Reviewed main: `dc1110b819c590394a1e8cd90739294185e9028f`
- Landed implementation: `main@be3285c16ada` (K3D-1 archived complete; implemented from `main@9093c9ff1613`)
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
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
- Blockers or open questions: `user A/B judgment and planning refresh are required before K3D-2.`

## Independent Review

- Status: `passed`
- Review workstream: `review-kenney-isometric-blockout-feasibility`
- Reviewed on main: `dc1110b819c590394a1e8cd90739294185e9028f`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Blocking defects: `0`
- Material evidence gaps: `0`
- Non-blocking issues: `1`
- Optional improvements: `0`
- Correction finding IDs: `none`
- Next-slice finding IDs: `R0-01`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_KENNEY_ISOMETRIC_BLOCKOUT_FEASIBILITY_CLAUDE_SUMMARY.md`
- Follow-up workstream: `none`

### Finding R0-01 — Refresh the K3D-1 roadmap status during K3D-2 planning

- Class: `non_blocking_issue`
- Domain: `implementation`
- Affected acceptance: truthful roadmap handoff
- Evidence: `design/01_systems/KENNEY_PRESENTATION_FEASIBILITY_ROADMAP.md` still describes K3D-1 as awaiting paired review, while this receipt records the technical review as passed.
- Disposition: `next_slice`
- Rationale: no effect on experiment behavior, asset integrity, or technical acceptance. Update the roadmap when K3D-2 is re-authored so it records K3D-1 review completion and carries forward the user's A/B decision. The reviewer did not choose an art direction.

## Completion

- Review completed on `main@dc1110b819c590394a1e8cd90739294185e9028f`.
- Focused Kenney smoke passed. Seven archive identities and all 16 selected assets were independently checked through source-member, source-work, ingest receipt/archive, and runtime hashes; dimensions and alpha matched. Asset V2 plan/status checks for both families and `asset.py doctor` passed. Capture dimensions and exact A/B composition passed; the debug scene remains outside production boot/world-entry references.
- Technical review passed with no blocking defects or material evidence gaps. Human-owned A/B questions remain unanswered and must drive the recorded K3D-2 planning refresh.
- One non-blocking roadmap-status refresh is carried into K3D-2 as finding `R0-01`.
- Next action: return the report and comparison to the authoring chat for the user's A/B judgment, then re-author K3D-2 from current main.
