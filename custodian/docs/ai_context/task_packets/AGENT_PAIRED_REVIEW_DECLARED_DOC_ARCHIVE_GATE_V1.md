# Paired Review Declared Documentation Archive Gate V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-declared-doc-archive-gate-v1`
- Kind: `implementation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `paired-review-source-provenance`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, workflow`
- Paired review workstream: `review-agent-paired-review-declared-doc-archive-gate-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `high-impact paired-review source-span validation gate`
- Reviewed main: `5c659db5d9bfac7cacfd3cc67391af757dc7237c`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad41ae1-c654-83ea-ba9f-2b4dc4dde401`
- Authoring handoff: `auto`
- Visual review: `none`
- Goal: Allow a source-bearing archive to include only Markdown documentation paths explicitly declared in the archived implementation packet's Work surface.
- Completion boundary: The source-span validator accepts the declared `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md` change and rejects undeclared Markdown paths while preserving all existing source/test, claim, archive, and ancestry checks.
- Current measured state: Review run `20261019T100457Z-dc3179d68792` for `review-agent-paired-review-invalid-disposition-recovery-v1` is held with its claim and worktree intact. Host validation stopped before reviewer launch with `archive-only landing contains unrelated paths`; the landed implementation archive includes the explicitly declared `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Evidence: `origin/main@5c659db5d9bfac7cacfd3cc67391af757dc7237c`; preserved review-run metadata and `host_validation_error`; archived implementation packet work surface.
- Task-specific authority: `custodian/tools/agent/paired_review_host_validation.py` owns source-span acceptance. `custodian/tools/agent/task_packet_contract.py::header_field` provides the shared packet field grammar. The exact archived implementation packet is the authority for its Work surface.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; focused regressions in `custodian/tools/agent/test_paired_review_runner.py`.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/task_packet_contract.py`.
- Change:
  1. Keep `_IMPLEMENTATION_SUFFIXES` and its existing source/test rules unchanged.
  2. For source-bearing archives, permit an additional `.md` path only when the exact repository-relative path appears in the archived implementation packet's `Work surface` field.
  3. Add a positive regression for the declared lifecycle document and a negative regression for an undeclared Markdown path, including one mentioned elsewhere in the packet but absent from Work surface.
- Preserve: Existing claim-trace identity and ancestry checks; source-span boundary; archive packet creation/deletion and file-mode checks; implementation/test suffix allowlist; source documentation and validation-coverage checks; held review claim/worktree/evidence.
- Non-goals: General Markdown allowance; directory/glob/prefix matching; weakening source/test documentation or validation coverage; modifying the blocked review claim/run; changing the landed invalid-disposition recovery implementation; applying or launching the historical plan.
- Acceptance:
  1. A source-bearing archive with `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md` in the archived packet's Work surface resolves successfully.
  2. A Markdown path absent from Work surface is rejected, even if the path appears in another packet section.
  3. Existing source/test suffix, exact path documentation, executable/non-regular file, archive-boundary, claim identity, trace continuity, and ancestry regressions remain green.
  4. The held support review claim/worktree/run remains unchanged; after this correction is independently reviewed, host validation resumes against its existing run without making a replacement claim.
- Validation: `python3 custodian/tools/agent/test_paired_review_runner.py`; `python3 -m py_compile custodian/tools/agent/paired_review_host_validation.py`; `python3 custodian/tools/validation/run_validation.py --changed --json`; `git diff --check`.
- Task overrides: `none`.
- Deferred: Resuming the held support review host-validation run until this correction's independent PASS; the historical source-bearing recovery plan remains prohibited.

## Next Handoff
- Next workstream: `review-agent-paired-review-declared-doc-archive-gate-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad41ae1-c654-83ea-ba9f-2b4dc4dde401`
- Refresh reason: `none`
- Next action: `Run the fresh-context paired review of the declared-documentation source-span correction.`
- Blockers or open questions: `The existing invalid-disposition support review remains held pending this correction's independent PASS.`
