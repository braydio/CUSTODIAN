# REVIEW: Paired-review runner checkout-profile integration

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-runner-checkout-profile-v1`
- Category: `agent-ops`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-runner-checkout-profile-v1`
- Locks: `paired-review-runner-checkout-profile`
- Kind: `review`
- Review: `none`
- Review target workstream: `agent-paired-review-runner-checkout-profile-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_RUNNER_CHECKOUT_PROFILE_V1.md`
- Reviewed main: `f4c6c1fb388e49e11db5ae14d6fd7ec757233636`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae5d404-c86c-83ea-aec4-6cd3d75af933`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that paired-review runner profile selection reduces checkout allocation while retaining complete, authentic review evidence and unchanged acceptance.
- Completion boundary: Review the exact landed implementation, dependency-coverage validation, profile fixture and tests. Record only a fresh independent PASS or concrete findings through the canonical paired-review lifecycle.
- Current measured state: The existing runner omits the dispatcher's supported `--checkout-profile` argument, causing a 7,264,018,781-byte capacity requirement against 2,279,641,088 available bytes before claim creation. No reviewer claim or Codex review process was created for the failed attempt.
- Evidence: Exact landed implementation diff and archived implementation packet; the reviewer profile and its computed dependency closure; tests proving path completeness and fail-before-claim behavior; canonical changed-file validation report; retry receipt for the original provisioning review.
- Task-specific authority: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/worktree_provisioning.py`; `custodian/tools/agent/task_packet_contract.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; archived implementation packet.
- Work surface: Read-only inspection of the landed runner/profile implementation, tests, profile allocation evidence, original provisioning implementation/review packets and validation report. Only canonical review receipt, this review packet lifecycle/archive metadata and the required closing summary may be written.
- Publication inputs: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/test_dispatch.py`; `custodian/tools/agent/worktree_provisioning.py`; `custodian/tools/agent/task_packet_contract.py`; `custodian/tools/agent/workstream.py`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/VALIDATION_RECIPES.md`; `custodian/docs/ai_context/worktree_profiles/agent_ops_paired_review_bootstrap_v1.json`; `custodian/docs/ai_context/task_packets/archived/AGENT_WORKSTREAM_LIGHTWEIGHT_LFS_PROVISIONING_V1.md`; `custodian/docs/ai_context/task_packets/REVIEW_AGENT_WORKSTREAM_LIGHTWEIGHT_LFS_PROVISIONING_V1.md`.
- Review evidence: Full exact implementation diff, archived packet, all positive and negative profile tests, target-diff and packet-publication dependency coverage, dispatcher claim receipt, run metadata, allocated checkout measurement and complete changed-file validation report. Reconstruct source and claim behavior independently; do not trust implementation-authored summaries as proof.
- Correction threshold: Any profile omission, dependency list derived only from profile contents, unsafe/untracked profile, profile/digest mismatch, claim before dependency validation, silent fallback to full mode after an explicit profile error, second claim, or change to host validation/reviewer verdict semantics is blocking. Report specific findings; do not repair the implementation.
- Focused validation: Independently run the focused paired-review runner, provisioning and dispatcher tests; inspect new negatives and the exact profile closure; verify the real retry uses the canonical runner and records the same profile path/digest; inspect changed-file coverage and `git diff --check`. Never invoke same-claim recovery against the real Awakening identity.
- Review focus: (1) Confirm default behavior remains full checkout. (2) Confirm dependencies are derived from both exact published packets and the implementation commit diff before profile membership is assessed. (3) Confirm path normalization and directory-prefix coverage reject traversal, missing, untracked and ambiguous inputs. (4) Confirm `--checkout-profile` reaches the dispatcher and the claim receipt/run metadata bind the selected profile. (5) Confirm host validation, reviewer evidence, receipt and verdict contracts are unchanged. (6) Confirm the measured profile materially reduces actual allocation and includes all files needed for independent review.
- Acceptance: PASS only when all implementation acceptance claims have repeatable evidence, the exact profile cannot omit published review dependencies or target changes, the existing provisioning review completes through the ordinary fresh-context runner with unchanged acceptance, and protected claims/evidence remain untouched. The reviewer never performs actual Awakening recovery.
- Non-goals: Execute actual Awakening recovery; claim, park or release protected workstreams; alter implementation or review evidence; clean storage or LFS cache; perform visual/design approval.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure
1. Claim only after the implementation lands complete and dispatcher confirms this exact review is eligible.
2. Reconstruct the packet-derived dependency closure, target diff and exact profile identity from pinned repository evidence.
3. Run the focused tests and inspect both positive and adversarial cases.
4. Verify the original provisioning paired review was retried through the canonical runner with the selected profile and unchanged host/review acceptance.
5. Record PASS or concrete findings; never apply recovery to the real Awakening claim.
6. Close through the canonical paired-review lifecycle.

## Handoff
- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae5d404-c86c-83ea-aec4-6cd3d75af933`
- Summary backlink: Include the exact Authoring chat URL in every durable summary and final Next Handoff.
- Refresh reason: `none`
- Next action: After accepted PASS, retry the original provisioning review; consider protected Awakening recovery only after that independent PASS.
- Blockers or open questions: Original provisioning review still requires a fresh canonical runner invocation. No actual Awakening recovery is authorized by this review packet.
