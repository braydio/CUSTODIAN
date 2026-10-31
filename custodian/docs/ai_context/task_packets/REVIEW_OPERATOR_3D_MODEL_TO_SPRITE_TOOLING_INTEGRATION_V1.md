# REVIEW: Operator 3D Source and Static Sprite Tooling Integration V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-3d-model-to-sprite-tooling-integration-v1`
- Category: `assets-art`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `operator-3d-model-to-sprite-tooling-integration-v1`
- Locks: `operator-3d-model-to-sprite-tooling`
- Review: `none`
- Review target workstream: `operator-3d-model-to-sprite-tooling-integration-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_3D_MODEL_TO_SPRITE_TOOLING_INTEGRATION_V1.md`
- Reviewed main: `f848228723513d21412aee0fdbd6bec6514db4e8`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ca33-99cc-83ea-b344-8d13b65268d1`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify source provenance and static model-to-sprite tooling without conflating it with rigged animation or runtime publication.
- Reviewed implementation acceptance: Verify exact LFS hydration and content identities; complete source lineage; static-versus-rigged separation; safe GLB inspection, canonical eight-direction 128/512 proof, immutable dependency receipts; safe CLI/package review; no `.meshy` default, model edits or runtime changes; accurate docs and focused tests.
- Review evidence: Reuse the pinned source archive and manifest, landed source/master manifest, focused test results, Blender inspect/render receipts, and implementation summary; rerun only stale or missing validation.
- Correction threshold: Correct confirmed acceptance defects or blocking evidence gaps only. Route non-blocking suggestions to the later model-fidelity task; artistic judgment is not part of this review.
- Focused validation: Recompute original source/LFS hashes, run model-to-sprite tests and CLI smoke on valid and invalid inputs, inspect receipt dependency hashes and test reports, run `git diff --check`; verify no runtime assets changed.
- Review focus: Schema extension backward compatibility; exact source provenance/derivation; no false LFS hydration; unsafe path handling; static renderer rejecting rigged assets; no second animation pipeline or registry; vendored decoder notice and legacy `.meshy` decoder exclusion; fixed 128/512 projection and alpha/root contract; candidate-only publication.
- Acceptance: Produce a findings-first independent review of the landed implementation, with stable cycle-scoped IDs and dispositions. Record `passed` only if all acceptance claims are evidenced; do not infer art approval or runtime eligibility.
- Non-goals: Do not edit the implementation, source master, animation compiler, model geometry, runtime or review artifacts. Do not approve the experimental model.
- Task overrides: `TASK OVERRIDE: Paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

Follow the complete reviewer procedure in `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`. Reconstruct from landed packet, archived implementation packet, source snapshot manifest, tests and live code. Use a fresh reviewer context. If an important human-owned art decision emerges, record `human_required` and link only the compact evidence; do not self-approve.
