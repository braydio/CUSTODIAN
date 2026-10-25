# Paired Review Canonical Metadata Source-Span V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-canonical-metadata-source-span-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-resumed-worktree-provenance-v1`
- Locks: `paired-review-canonical-metadata-source-span-v1`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-canonical-metadata-source-span-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `paired review is required because archive source-span validation is a coordinator trust boundary`
- Reviewed main: `597c2bd43061bafd567f63e555b89d87e1baaf7d`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad556b3-998c-83ea-8620-22173524205f`
- Visual review: `none`
- Goal: Accept the exact canonical paired-review metadata closeout required by a historical implementation archive while keeping review Markdown outside implementation source authority.
- Completion boundary: Add one authenticated source-span exception for the associated paired review packet's exact `Authoring chat` substitutions; prove the actual archive commit and original prelaunch/recovery plan; reject every other review-packet or provenance change.
- Current measured state: On `origin/main@597c2bd43061bafd567f63e555b89d87e1baaf7d`, `resolve_validation_source_span()` for the preserved resumed-worktree review fails with `archive-only landing contains unrelated paths`. Archive commit `2e898dddc82a596b0a2bd15c150b1645cf61f29c` changes the associated review packet at mode `100644`, blob `c42480201e604ecfbcb5be2be16c9a0f42bcd5ac` to `47ab64fb43f4e3961416ad6863965b0887722716`; its only content changes replace two `Authoring chat: not-recorded` values with the exact canonical URL recorded by the implementation packet.
- Evidence: Preserved run `20261023T064140Z-1a1e903471c9`; `metadata.json` SHA-256 `272c686fe0d3a1797706f573e92ffc37b5a9de012229f6d20954364a94d5d564`; `RECOVERY.md` SHA-256 `7dd33d79b6537391f9fa673395ba0b9bb246c1673be237b7d81239c6076c3687`; `claim-receipt.json` SHA-256 `c69cef007ff106231ef1fbbc45a4e3c1a9b429c1296bfa97a1975e904ca33dc3`; pinned implementation `2e898dddc82a596b0a2bd15c150b1645cf61f29c`; reviewed main `d5c6315979f1e3fd2ee55c6e15cae7f9e30c1f99`; current main `597c2bd43061bafd567f63e555b89d87e1baaf7d`.
- Task-specific authority: `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; archived implementation packet `custodian/docs/ai_context/task_packets/archived/PAIRED_REVIEW_RESUMED_WORKTREE_PROVENANCE_V1.md`; active review packet `custodian/docs/ai_context/task_packets/REVIEW_AGENT_PAIRED_REVIEW_RESUMED_WORKTREE_PROVENANCE_V1.md` (read-only).
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; root closing summary for this workstream. Do not edit the preserved implementation/review packets or the active claimed review worktree.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/task_packets/archived/PAIRED_REVIEW_RESUMED_WORKTREE_PROVENANCE_V1.md`; `custodian/docs/ai_context/task_packets/REVIEW_AGENT_PAIRED_REVIEW_RESUMED_WORKTREE_PROVENANCE_V1.md`.
- Change:
  1. Derive exactly one associated review packet path from the target implementation workstream and require its packet identity to name that review workstream, target workstream, and exact archived target packet.
  2. Permit the review packet as archive metadata only when its before/after Git tree entries are regular `100644` files and the complete byte diff is exactly two `Authoring chat: not-recorded` substitutions to the single canonical URL already present, unchanged, in both the active and archived implementation packet.
  3. Keep the metadata path outside the resolved implementation/source path set. Preserve all existing packet Work surface, trace identity, source hash, mode, merge, and coordinator validation gates. Never authorize a review Markdown path by suffix, prefix, similarity, or caller-supplied path alone.
  4. Add real-Git positive and adversarial fixtures for the actual archive commit, unexpected field/value edits, substitute review packets, extra paths, mode changes, and altered trace/provenance.
  5. Run actual `resolve_validation_source_span()` and coordinator/prelaunch verification against commit `2e898dddc82a596b0a2bd15c150b1645cf61f29c`, then regenerate the preserved run's read-only `--recover-host-validation --plan` and record its exact SHA-256. Do not apply the plan or launch the preserved reviewer in this workstream.
  6. Record the tooling/documentation drift: the prior resumed-worktree prelaunch simulation passed on synthetic archive fixtures but did not exercise this implementation's actual archive commit and paired-review metadata closeout.
- Preserve: Original run `20261023T064140Z-1a1e903471c9`, claim receipt and diagnostics byte-for-byte; original claim/worktree/branch and implementation SHA; conflict-resolution and import-recovery held reviews; Blender review claim/run/worktree and pinned implementation; all independent verdict and recovery boundaries.
- Non-goals: No generic review-Markdown allowlist; no retroactive edits to the historical implementation packet; no edits to the active resumed-worktree review packet; no claim release/replacement; no reviewer launch or recovery-plan apply before the exact original-run plan succeeds; no downstream held review launch or apply.
- Acceptance:
  - A1: The real historical archive commit `2e898dd...` resolves through the normal source-span path on its exact preserved trace and pinned reviewed-main identity.
  - A2: Only the uniquely derived associated review packet is eligible; its exact packet identity, unchanged canonical authoring URL, two allowed field substitutions, and regular file mode are verified from real Git objects.
  - A3: The review metadata file never appears in implementation source paths or expands the archived implementation Work surface.
  - A4: Real-Git negative controls reject unexpected field edits/values, substitute review packets, extra changed paths, wrong modes, malformed/duplicate metadata, and altered trace/claim/landing provenance.
  - A5: Full coordinator source-span/prelaunch verification succeeds against the actual landing commit; the preserved original run's read-only recovery plan succeeds and its SHA-256 is recorded. Stop before plan apply and before the preserved reviewer launch.
  - A6: Focused/full paired-review tests, changed-file validation with complete coverage and zero skips, `py_compile`, packet-index checks, and `git diff --check` pass.
  - A7: Closing evidence records that the earlier prelaunch simulation did not model this real archive closeout.
- Validation: Exact historical positive and adversarial tests; full `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; actual original-run `paired_review_runner.py review-agent-paired-review-resumed-worktree-provenance-v1 --continue-run 20261023T064140Z-1a1e903471c9 --recover-host-validation --plan`; `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`; `python3 -m py_compile custodian/tools/agent/paired_review_host_validation.py custodian/tools/agent/test_paired_review_runner.py`; `python3 custodian/tools/agent/task_packet_index.py`; `git diff --check`. No `--apply` and no reviewer launch for the preserved run.
- Task overrides: `none`
- Deferred: After this implementation's own fresh-context paired review passes, regenerate and inspect the original preserved run's authenticated plan; any apply/launch remains outside this packet's completion boundary.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: pending
- Root cause / contributing factors: pending
- Prevention / pipeline improvement: pending
- Tooling / docs drift discovered: Prior end-to-end prelaunch simulation exercised synthetic archive histories but omitted the actual `2e898dd...` archive's associated review-packet metadata closeout.
- Follow-up: pending
- What worked: pending

## Handoff

- Next workstream: `review-agent-paired-review-canonical-metadata-source-span-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad556b3-998c-83ea-8620-22173524205f`
- Summary backlink: `Include this exact Authoring chat URL in every durable summary and final Next Handoff.`
- Refresh reason: `none`
- Next action: `After implementation lands and its independent review passes, inspect a fresh read-only recovery plan for the preserved resumed-worktree review.`
- Blockers or open questions: `Original run and review claim are preserved; plan apply and reviewer launch remain gated.`
