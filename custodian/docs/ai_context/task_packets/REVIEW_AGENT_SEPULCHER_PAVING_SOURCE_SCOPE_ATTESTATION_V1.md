# REVIEW: Exact Sepulcher Native Quad Source-Scope Attestation

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-sepulcher-paving-source-scope-attestation-v1`
- Category: `agent-ops`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `agent-sepulcher-paving-source-scope-attestation-v1`
- Locks: `paired-review-source-provenance`
- Review: `none`
- Review target workstream: `agent-sepulcher-paving-source-scope-attestation-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_SEPULCHER_PAVING_SOURCE_SCOPE_ATTESTATION_V1.md`
- Reviewed main: `9c8ce8d7774d9cbb1bf6a63dde0eda96bd426a2e`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: `Independently falsify the four-path historical source-scope exception, especially early activation, fake source or approval provenance, unexpected paths, and any mutation of the preserved original Sepulcher review.`
- Reviewed implementation acceptance: `Exact Acceptance and complete immutable source inventory in the archived AGENT_SEPULCHER_PAVING_SOURCE_SCOPE_ATTESTATION_V1.md; prior to accepted correction review PASS the original host gate must still reject.`
- Review evidence: `Fresh read of original preserved review run/claim/checkout and source-span host evidence; immutable Git tree/blob/mode identities; attestation bytes; new disposable-Git negative/positive tests; correction implementation completion and non-mutated original claim receipts.`
- Correction threshold: `Any extra or mismatched source path, blob/mode, original review identity/run, unpinned source span/archive parent/tree, early exception activation, forged/missing independent approval, incorrect coordinator evidence digest, mutated prior review, or blanket source-scope relaxation is blocking.`
- Focused validation: `PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v; python3 -m py_compile custodian/tools/agent/paired_review_host_validation.py; python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json; git diff --check. No Godot/visual art tests needed.`
- Review focus: `The original Sepulcher scene implementation landed unchanged; historical source path omission consisted of four Git tree-exact files. The attestation applies to one exact no-verdict preserved review and only after this correction review receives canonical accepted PASS. Do not conflate source reviewability with technical reviewer acceptance or user artistic acceptance.`
- Acceptance: `Fresh findings-first R0-NN receipt with adversarial original Git provenance replay and preapproval negative; PASS only if exact postapproval fixture succeeds after real canonical approved provenance and all wrong/forged histories remain rejected. No implementation edits inside review; any blocking finding routes to bounded correction/re-review.`
- Non-goals: `No original implementation edit, no archived packet rewrite, no original review launch/recovery apply, no player art evaluation or Asset V2 approval, no system-wide source-scope relaxations.`
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after `agent-sepulcher-paving-source-scope-attestation-v1` completes and its archived packet lands on main. Use a fresh reviewer context and independently reread source Git identities, without copying the executor's conclusions.
2. Independently falsify every original-case and forged-approval failure, including a real `pre-approval rejects` check, exact source span/file blobs/modes and review claim/run preservation.
3. Review the code's behavior before claiming any correction PASS; an unauthenticated JSON attestation cannot authorize any source exception.
4. Publish canonical review receipt. After accepted PASS, leave original Sepulcher review unaltered; hand off read-only `--recover-host-validation --plan` and only then digest-matched apply through original claim under a separately authorized control.

## Next Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Summary backlink: `not-recorded`
- Refresh reason: `none; correction review verdict unlocks a later original-run recovery plan, not original-run success or an art approval`
- Next action: `If and only if this correction review is accepted PASS, run the preserved original Sepulcher review's read-only recovery plan and report exact authorization state for safe original-claim continuation. Human visual decision remains independent.`
- Blockers or open questions: `Original preserved review's claim/run exact IDs must be authenticated from host evidence before any later apply; no duplicate claim or evidence rewrite permitted.`
