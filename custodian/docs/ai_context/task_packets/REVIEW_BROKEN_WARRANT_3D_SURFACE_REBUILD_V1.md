# REVIEW Broken Warrant 3D Surface Rebuild

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-broken-warrant-3d-surface-rebuild`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `broken-warrant-3d-surface-rebuild`
- Locks: `broken-warrant-3d-source`
- Review: `none`
- Review target workstream: `broken-warrant-3d-surface-rebuild`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/BROKEN_WARRANT_3D_SURFACE_REBUILD_V1.md`
- Reviewed main: `052ccc20901f953348b1b5e5f27d7dc1e5b30d0e`
- Authoring handoff: `auto`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad67690-d998-83ea-a107-ff3417ee482a`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the landed source-only material master and deterministic pixel proof against the exact implementation acceptance and handoff inputs.
- Reviewed implementation acceptance: Original assets/hashes unchanged; 503 meshes, 45,998 triangles, one 15-bone rig; complete intentional material and bone assignments; no rejected atlas or source-fragment projection; packed editable master reopens; deterministic 128px and 4x transparent renders preserve `(64,106)` anchor/ground 107 without clipping; one comparison sheet and machine-readable reports; no runtime or production-art claim.
- Review evidence: Exact landed implementation commit and archived packet; tracked handoff ZIP and manifest; source hash report; Blender build/reopen logs; material assignment and rig census; focused test output; proof JSON/CSV and the single comparison sheet.
- Correction threshold: Any changed source bytes, mesh/triangle/bone mismatch, missing/ambiguous material or bone mapping, unresolved packed dependency, retired atlas use, alpha hole, invalid camera/registration, clipping, unreported render-only omission, nondeterministic output, or missing reproducible validation evidence.
- Focused validation: Recompute source and artifact hashes; run `custodian/tools/art/broken_warrant_3d/test_surface_contract.py`; independently reopen the Blender master and render the three fixed views; verify PNG dimensions, RGBA alpha, root/ground and bounds; inspect one native-plus-4x comparison sheet only for gross technical anomalies. Report artistic similarity separately to the user; do not approve it.
- Review focus: Source immutability, exact geometry/rig preservation, material classification correctness, packed/editable Blender validity, renderer determinism, registration/alpha/clipping, source-only boundaries, and documentation drift.
- Acceptance: Findings-first independent receipt with zero blocking defects and no material evidence gap; no subjective production art approval is implied.
- Non-goals: No implementation edits, art direction iteration, runtime or Asset V2 changes, animation/FPS decision, or promotion of the character as approved art.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad67690-d998-83ea-a107-ff3417ee482a`
- Next action: Record the technical review verdict and leave the user-owned artistic acceptance pending until the user responds to the comparison sheet.
- Blockers or open questions: none beyond implementation landing.
