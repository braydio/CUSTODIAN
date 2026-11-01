# Sepulcher Native Quad: Exact Historical Review Source-Scope Attestation

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-sepulcher-paving-source-scope-attestation-v1`
- Category: `agent-ops`
- Authoring handoff: `auto`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `sepulcher-paving-native-quad-playtest-v1`
- Locks: `paired-review-source-provenance`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-sepulcher-paving-source-scope-attestation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Post-hoc authorization of four historical source paths changes independent-review admission. It requires immutable provenance, fail-closed activation, adversarial tests, and fresh independent approval before original-review recovery.`
- Reviewed main: `9c8ce8d7774d9cbb1bf6a63dde0eda96bd426a2e`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: `Unblock the already-preserved Sepulcher native-quad independent technical review without editing its implementation/archived packet, losing its claim/run, fabricating a reviewer verdict, or weakening generic source-scope enforcement.`
- Completion boundary: `Implement one exactly pinned post-hoc `custodian.review_source_scope_attestation.v1` record and its narrow host-validation check for precisely four missing source-bearing paths. The exception remains inactive until this correction's own canonical independent review PASS is accepted on main. Then, separately plan recovery of the original review's *same* preserved run; no original review execution or approval in this implementation workstream.`
- Current measured state: `At main 9c8ce8d7774d9cbb1bf6a63dde0eda96bd426a2e, the Sepulcher playable scene is landed at 3ac23cda031d80fdaf283b5d9a8b5a88db2782e8 (implementation 1881a21ab1aa193e414d738a68dc37f7fbb0de9e, closeout 0944e66911856d708fd32318454ecbc86492bfd2). Godot/crop/LFS and three capture claims passed in the implementation closeout, but the original review claimed checkout /home/braydenchaffee/Projects/.custodian-worktrees/review-sepulcher-paving-native-quad-playtest-v1-20261101T111808Z-8aeb4953f9d4 was preserved without a verdict after its pre-review host gate rejected four non-explicit source code/scene paths. Original archived Work surface has only generic phrases for these four paths, and retrying its exact-run recovery plan encounters the same source-scope predicate. Review run/claim exact immutable IDs are host-private and MUST be discovered and pinned from existing coordinator evidence before this correction mutates verifier logic; do not invent them.`
- Evidence: `Git source commit 1881a21ab1aa193e414d738a68dc37f7fbb0de9e, base a772a2a6bf604bb6153c38882ee5d20e5b228ef4, source tree 25a103c9f98cf37fbe03609f861aa3e25f3775ee; closeout 0944e66911856d708fd32318454ecbc86492bfd2; archive 3ac23cda031d80fdaf283b5d9a8b5a88db2782e8, tree 19325b059513a05bb89654a48a38cd90719073ab; archived packet blob 77e659d96a6bdfc1bd5b7197beffa30c14c1a19c (100644); original preserved review identity and its preflight host evidence; four exact source blobs/modes in table below.`
- Task-specific authority: `custodian/tools/agent/paired_review_host_validation.py; custodian/tools/agent/paired_review_runner.py; custodian/tools/agent/review_outcome.py; custodian/tools/agent/review_receipt_delta.py; custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md; existing G2/Operator/Procession/Grunt accepted-review-gated source-scope attestation cases, tests and their pinned provenance contracts.`
- Work surface: `custodian/tools/agent/paired_review_host_validation.py; custodian/tools/agent/test_paired_review_runner.py; custodian/docs/ai_context/review_scope_attestations/sepulcher_paving_native_quad_v1.json; narrowly necessary source-scope fixtures only. No edits to the source gameplay implementation, archived Sepulcher packet or original review checkout/claims/evidence.`
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py, custodian/tools/agent/paired_review_runner.py, custodian/tools/agent/test_paired_review_runner.py, custodian/tools/agent/review_outcome.py, custodian/tools/agent/review_receipt_delta.py, custodian/tools/agent/task_packet_contract.py, custodian/docs/ai_context/task_packets/archived/SEPULCHER_PAVING_NATIVE_QUAD_PLAYTEST_V1.md, custodian/docs/ai_context/task_packets/REVIEW_SEPULCHER_PAVING_NATIVE_QUAD_PLAYTEST_V1.md, custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md, custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md, custodian/docs/ai_context/TASK_PACKET_CATEGORIES.json, custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`
- Change: `Add a post-hoc exact identity attestation for the single archived Sepulcher implementation and its preserved original review. Bind source base/head, archive commit/parent/tree, archived packet blob/mode, immutable original review run/claim/checkout, the *complete* original source-bearing path inventory and only the four omitted blob/mode identities below. Restrict exception to this one authenticated history; require separate correction implementation completion AND accepted canonical independent review PASS/receipt/ancestry on main before activation. Preserve independent reviewed-main and post-review coordinator re-verification. Unit-test historical preapproval rejection, exact postapproval acceptance, and comprehensive forgery/extra-file negatives. Return only a read-only original-review recovery plan after acceptance, not an apply or reviewer verdict.`
- Preserve: `All implementation/preview art, Godot scene, unchanged source blobs, original archived packet and immutable original review run/claim/branch/checkout/evidence; independent review strict source-scope safety; unrelated remote claims and current provenance lock owner; historical attestation cases. No branch deletion, reviewer second claim or lock release.`
- Non-goals: `No archived packet edit, retroactive in-place Work surface broadening, original review execution/relaunch/acceptance, generic directory/wildcard scope allowance, host run evidence mutation, Asset V2 source approval, Sepulcher art, Godot changes, unrelated claim recovery, or public copy of private host evidence.`
- Acceptance: `Preapproval: original exact-run preflight still rejects precisely the four missing entries. Postapproval: after an authentic canonical independent PASS for this correction, exactly that original history may pass, with all four source blobs/modes and complete source span pinned. Reject wrong run/claim/branch/worktree, wrong original or approval commits/trees/parents, changed archived packet bytes, missing/extra source, different blobs/modes, forged/cancelled/unaccepted approval, stale/foreign main, tampered coordinator provenance, non-pinned path or wildcard. Confirm no original-review verdict or claim mutation occurred in this correction.`
- Validation: `python3 -m py_compile custodian/tools/agent/paired_review_host_validation.py; PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v (focus new exact historical Sepulcher fixtures and existing G2/Operator/Procession/Grunt negatives); python3 custodian/tools/agent/check_packet_categories.py custodian/docs/ai_context/task_packets/AGENT_SEPULCHER_PAVING_SOURCE_SCOPE_ATTESTATION_V1.md custodian/docs/ai_context/task_packets/REVIEW_AGENT_SEPULCHER_PAVING_SOURCE_SCOPE_ATTESTATION_V1.md; python3 custodian/tools/agent/validate_task_packet_authoring.py custodian/docs/ai_context/task_packets/AGENT_SEPULCHER_PAVING_SOURCE_SCOPE_ATTESTATION_V1.md custodian/docs/ai_context/task_packets/REVIEW_AGENT_SEPULCHER_PAVING_SOURCE_SCOPE_ATTESTATION_V1.md; python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json; git diff --check. Python/source-scope only, no Godot sweep.`
- Task overrides: `none`
- Deferred: `Following this correction's independent accepted PASS, produce fresh read-only `--recover-host-validation --plan` from the original held Sepulcher review run; only a later explicitly authorized digest-matched apply with fresh reviewer context may resume THAT original claim. Its reviewer outcome and user aesthetic decision are entirely separate.`

## Exact immutable source file identity

The four following paths were present in original source implementation commit `1881a21ab1aa193e414d738a68dc37f7fbb0de9e` and are absent as **explicit** paths from the archived packet's Work surface. Paths, modes and Git blobs were read from the `25a103c9f98cf37fbe03609f861aa3e25f3775ee` Git tree:

| Omitted source path | Git blob SHA | Git mode |
|---|---|---|
| `custodian/game/world/levels/authored/dev/sepulcher_modular_material_pilot/sepulcher_modular_material_pilot_level.gd` | `c365591cd54720e85721efe2778070106a13f041` | `100644` |
| `custodian/game/world/levels/authored/dev/sepulcher_modular_material_pilot/sepulcher_modular_material_pilot_level.tscn` | `6402d623f84262c4dbf7bb9e34cd206c13b7e713` | `100644` |
| `custodian/tools/validation/levels/sepulcher_modular_material_pilot_capture.gd` | `da1ec53b552fe802400f5d2f012359f1a0fed603` | `100644` |
| `custodian/tools/validation/levels/sepulcher_modular_material_pilot_smoke.gd` | `096e41a08369e60a294553a408230cc1bc2688d1` | `100644` |

The original implementation also introduced other LFS assets, import metadata and the explicit wrapper scene `custodian/game/world/levels/authored/dev/sepulcher_modular_material_pilot/sepulcher_modular_material_pilot.tscn`, registered validation manifest, etc. **Do not claim these four are all source changes.** Construct and pin the *complete* actual source-span/archive inventory from Git and existing coordinator evidence. The host failed specifically on these four additional non-explicit paths; allowing these four is not permission to ignore any fifth source-bearing discrepancy. Keep ordinary approved explicit paths and metadata exclusions subject to existing validators.

## Host-first evidence and immutable approval binding

1. Verify exact original claim, immutable run ID, execution lock owner, branch/checkout, coordinator status `host_validation_recovery`, and zero reviewer verdict **read-only**. Compare with the user-reported preserved worktree. If evidence missing/ambiguous, stop `HOST_EVIDENCE_BLOCKED`; do not create a duplicate claim or invent IDs.
2. Replay current host source-scope check for the **original** run and record precisely the four rejects, the original reviewed-main and full implementation/archive path set. Compare against actual Git objects above. A new/unexpected path changes the problem and requires fresh scoped planning, not a silent exception.
3. Reuse existing canonical attestation format and activation design. The new `custodian/docs/ai_context/review_scope_attestations/sepulcher_paving_native_quad_v1.json` is an output of this task, not a preclaim dependency. Pin review claimant identities, source/head commits, archive tree/packet and all four source blobs/modes with `post_hoc: true`. The attestation alone is inert; no approval → no exception.
4. Add one exact Sepulcher-only host-validation branch and disposable-Git tests, proving the authorization gates listed in Acceptance. Do not change general Work surface glob/brace parsing or treat future `.gd`/`.tscn` additions as allowed.
5. Land only the correction code + JSON + tests through the owned workstream with its own independent review. After accepted PASS, inspect and return a fresh original-review recovery plan. Do not mutate/launch original review in this packet.

## Next Handoff

- Next workstream: `review-agent-sepulcher-paving-source-scope-attestation-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Summary backlink: `not-recorded`
- Refresh reason: `none; technical provenance acceptance follows already-pinned original history and host evidence, not new art direction`
- Next action: `Run fresh independent review for this exact attestation, then and only then re-plan original Sepulcher review recovery read-only. Do not apply/reclaim original without a new authorized plan.`
- Blockers or open questions: `Provenance execution lock may be held by unrelated workstream; preserved original run/claim ID must be read from host before edits, and any mismatch blocks this correction rather than authorizing a generic override.`
