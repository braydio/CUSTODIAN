# REVIEW: Operator 3D Visual Fidelity Candidate V2

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-3d-visual-fidelity-candidate-v2`
- Category: `operator-actors`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `operator-3d-visual-fidelity-candidate-v2`
- Locks: `operator-3d-visual-fidelity-candidate`
- Review: `none`
- Review target workstream: `operator-3d-visual-fidelity-candidate-v2`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_3D_VISUAL_FIDELITY_CANDIDATE_V2.md`
- Reviewed main: `f848228723513d21412aee0fdbd6bec6514db4e8`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ca33-99cc-83ea-b344-8d13b65268d1`
- Visual review: `required`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the bounded 12-pose candidate evidence, exact source lineage and technical render contract. Do not make the subjective art decision.
- Reviewed implementation acceptance: The v002 source is a new LFS-backed experimental derivative; original source/master/motion remain unchanged; mapping/rest/weights and textures are verified; the prescribed 12 poses and source candidates are rendered at native 128/512 under one camera/scale; nearest-neighbor reduction follows `pixelart --choose 1`; QA covers root, contact, alpha, direction/visor, metrics and temporal neighborhood; concise review bundle is hash-bound and published; no full animation render or runtime promotion occurred.
- Review evidence: Compare archived packet and workstream summary, source/master manifests, candidate hashes, rendering receipts, QA/texture/camera evidence, tests, and Dropbox package manifest; reuse the compact proof rather than recapturing.
- Correction threshold: File corrections only for confirmed implementation defects or missing proof. Human aesthetic concerns are `human_required`, not code findings.
- Focused validation: Recompute source and candidate LFS hashes; verify the exact 12-pose matrix and 128/512 output dimensions; inspect Blender dependency/rest signatures; run focused compiler/preview/QA tests and `git diff --check`; compare all referenced artifact hashes.
- Review focus: No original/master/motion mutation; source provenance and parent identity; rest/mapping invalidation correctness; pose selection and timing; fixed-scale/root/camera/direction contract; compliant pixelart conversion; visor hierarchy; contact/alpha/temporal proof; candidate-only status; human art gate; no unintended runtime changes.
- Acceptance: Record a findings-first fresh-context review with stable cycle IDs and dispositions. Technical pass does not grant art approval; any unresolved visual decision remains human-required.
- Non-goals: No candidate correction, model edit, full animation render, runtime integration, timing approval or aesthetic approval.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

Follow `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md` in a fresh reviewer context. Review objective evidence first; publish no duplicated visual package if the implementation bundle suffices. Keep the final artistic decision with the authoring chat/user.
