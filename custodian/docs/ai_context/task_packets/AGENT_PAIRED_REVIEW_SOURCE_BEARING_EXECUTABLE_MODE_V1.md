# PAIRED REVIEW SOURCE-BEARING ARCHIVE EXECUTABLE MODE VALIDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-source-bearing-executable-mode-v1`
- Category: `agent-ops`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `none`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-source-bearing-executable-mode-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `A narrow host-validation correction changes how authenticated Git modes are interpreted at a security-sensitive archive boundary; a fresh independent review materially reduces false-acceptance risk.`
- Reviewed main: `549ebd4830e52d7fb878e638b23e168bd9eb9c18`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae98bea-2dfc-83e8-a5ff-863e52d79ac0`
- Visual review: `none`
- Goal: Allow authenticated source-bearing archive validation to preserve an already-executable implementation source file while continuing to reject unauthorized executable paths and metadata.
- Completion boundary: Correct and test the paired-review host validator's archive-landing mode checks for source-bearing history. Complete through normal implementation validation, commit, landing, summary, and required independent post-land review. The original WIRE review remains a protected downstream recovery prerequisite and is not modified or resumed by this workstream.
- Current measured state: The WIRE implementation landed at `4b9a5b8de5d7aff148d5011771e4f7f7a65963e0`. Its authenticated base/archive parent is `e93a75edcf37a28dde58bea61266df2389ba81ea`. `custodian/tools/iteration/wire_pilot.py` is mode `100755` with blob `1f029dc7e9edc082f7d17c918ec32a783cb9546a` at base and archive parent, and mode `100755` with blob `34597799be8093a67abcb1e429199f341b6fca00` at landing; the transition is a content modification with no mode change. The current validator rejects the archive landing with `archive landing contains an executable or non-regular path`.
- Evidence: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/docs/ai_context/task_packets/archived/AGENT_WIRE_PILOT_EXPORTER_RECONCILIATION_V1.md`; `AGENT_WIRE_PILOT_EXPORTER_RECONCILIATION_V1_CLAUDE_SUMMARY.md`; `custodian/docs/ai_context/task_packets/REVIEW_AGENT_WIRE_PILOT_EXPORTER_RECONCILIATION_V1.md`; authenticated Git tree entries at the base, archive parent and landing SHAs listed above.
- Task-specific authority: `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/task_packets/README.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; the existing paired-review host-validation and source-bearing archive contracts in `paired_review_host_validation.py` and its tests.
- Work surface: Primary owner `custodian/tools/agent/paired_review_host_validation.py`; regression coverage `custodian/tools/agent/test_paired_review_runner.py`; consumers `custodian/tools/agent/paired_review_runner.py` and its canonical recovery-plan path.
- Publication inputs: `AGENTS.md`; `custodian/AGENTS.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/VALIDATION_RECIPES.md`; `custodian/docs/ai_context/TASK_PACKET_CATEGORIES.json`; `custodian/docs/ai_context/TASK_PACKET_CATEGORY_AUTHORING.md`; `custodian/docs/ai_context/task_packets/README.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_WIRE_PILOT_EXPORTER_RECONCILIATION_V1.md`; `custodian/docs/ai_context/task_packets/REVIEW_AGENT_WIRE_PILOT_EXPORTER_RECONCILIATION_V1.md`; `custodian/docs/ai_context/worktree_profiles/wire_pilot_exporter_reconciliation_v1.json`; `AGENT_WIRE_PILOT_EXPORTER_RECONCILIATION_V1_CLAUDE_SUMMARY.md`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/task_packet_contract.py`; `custodian/tools/agent/validate_task_packet_authoring.py`; `custodian/tools/agent/check_packet_categories.py`; `custodian/tools/agent/task_packet_index.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/tools/agent/worktree_provisioning.py`; `custodian/tools/agent/land_main.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/tools/agent/review_outcome.py`
- Change: Permit an executable archived path only when it is a regular blob, is explicitly within the implementation packet's authorized source scope, is mode `100755` at the authenticated implementation base, remains `100755` across every commit in the authenticated source span and at archive landing without any mode transition, and continues to pass existing content hash, trace, identity, ancestry, and validation coverage checks. Continue to require `100644` for ordinary files, archive metadata, packets, summaries, review receipts, and generated indexes. No filename suffix, executable bit, or packet prose alone confers authority.
- Preserve: Keep all existing identity, source-hash, authenticated trace, ancestry, validation coverage, archive-only, and source-bearing checks. Preserve the exact original WIRE run, dispatcher claim/ref, branch, attached checkout, recovery metadata, and failed reports. Do not alter historical Git modes or the reviewed WIRE implementation.
- Non-goals: Do not edit `custodian/tools/iteration/wire_pilot.py`, archived WIRE packet or summary, original WIRE review packet/branch/worktree/recovery evidence; do not apply WIRE recovery, launch its reviewer, release its claim, alter unrelated validators, weaken negative tests, or add new execution/dispatch behavior.
- Acceptance: (1) The exact authenticated WIRE source-bearing landing validates with its original trace and proves the preexisting executable mode stayed unchanged. (2) Existing executable Python sources modified without mode transitions are accepted only when authorized. (3) Ordinary `100644` source and archive-only histories remain valid. (4) New `100755` files, `100644` to `100755` transitions, removed/toggled executable bits, executable packet/review metadata, summaries or indexes, undeclared executable Python, executable non-Python without explicit applicable authority, symlink/submodule entries, forged base/source/landing/trace, and unrelated executable paths are rejected. (5) No existing negative test is weakened; all mode-sensitive fixtures use temporary Git repositories.
- Validation: Run the targeted `test_paired_review_runner.py` cases and relevant host-validation tests in actual temporary Git repositories; run packet authoring and category checks for the pair; run the repository's required focused validation recipe for Python agent tooling. Record exact commands and results in the workstream evidence and closing summary. Do not apply the original WIRE recovery plan until this correction lands and its independent review is accepted.
- Task overrides: `none`
- Deferred: Resume the exact protected original WIRE review only after this correction is implemented, independently reviewed and accepted; then construct a fresh authenticated recovery plan from a clean coordination checkout. Root checkout synchronization and disk reconciliation remain deferred until protected review closeout permits them.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: The validator now requires authorized Python source executability at authenticated base, every source-span revision, and archive landing with no mode changes, while retaining existing regular-file, scope, hash, trace, identity, ancestry, and validation checks. The exact historical WIRE source-bearing archive and adversarial temporary-Git mode/path cases pass. Canonical changed-file validation reports complete coverage and both selected validation groups passed.

## Handoff

- Next workstream: `review-agent-wire-pilot-exporter-reconciliation-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae98bea-2dfc-83e8-a5ff-863e52d79ac0`
- Refresh reason: `none`
- Next action: After this correction pair is implemented and independently accepted, continue exact-run host-validation recovery for the protected original WIRE review.
- Blockers or open questions: `The original WIRE review claim/worktree remains protected in host_validation_recovery; no reviewer verdict exists.`
