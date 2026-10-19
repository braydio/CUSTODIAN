# Paired Review Strict Work-surface Authority V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-strict-work-surface-authority-v1`
- Kind: `implementation`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P0`
- Depends on: `none`
- Locks: `paired-review-source-provenance`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, workflow`
- Paired review workstream: `review-agent-paired-review-strict-work-surface-authority-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `high-impact authorization gate for source-bearing paired-review archives`
- Reviewed main: `d7061ab8f3ae7b641a91544465431db81574f735`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad41ae1-c654-83ea-ba9f-2b4dc4dde401`
- Authoring handoff: `auto`
- Visual review: `none`
- Goal: Ensure only Markdown paths explicitly authorized by one unambiguous top-level Work surface declaration can expand source-bearing archive eligibility.
- Completion boundary: The host validator accepts the exact declared lifecycle document and rejects malformed or ambiguous Work surface authority while preserving the ordinary source/test allowlist and provenance gates. The scoped workstream finish can leave the persistent root checkout untouched as the user directed.
- Current measured state: `origin/main@d7061ab8f3ae7b641a91544465431db81574f735` contains the initial permissive Work surface lookup. Direct probes show an indented declaration is accepted and duplicate top-level declarations resolve to the first value. The disputed review branch has local commit `ad2009ca91a8afec457c8b21c202f1b10b7ca086`, remote tip `f3a225c426a51736551b88c91ea2b786a69e8f5a`, and remains protected; this workstream must not modify it.
- Evidence: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/task_packet_contract.py::_header_field_with_continuations`; reproduced `header_field()` outputs for nested and duplicate declarations; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/workstream.py` root-sync deferral gate.
- Task-specific authority: The exact archived implementation packet header defines Work surface authorization. `paired_review_host_validation.py` owns source-bearing archive acceptance. `workstream.py` owns safe landing and persistent-root synchronization policy.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; regressions in `custodian/tools/agent/test_paired_review_runner.py`; narrowly scoped root-sync deferral authorization in `custodian/tools/agent/workstream.py` and `custodian/tools/agent/test_workstream.py`.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/task_packet_contract.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/test_workstream.py`.
- Change:
  1. Add a validator-local parser that examines only the archived packet header and requires exactly one unindented `- Work surface:` declaration.
  2. Fail closed for Markdown archive eligibility when the declaration is missing, duplicated, or accompanied by an indented competing `Work surface` declaration. Do not change the shared packet parser.
  3. Extract Markdown paths only from the unique field's own value and continuation lines, and require exact repository-relative path equality.
  4. Add exact workstream-scoped root-sync deferral authorization for this implementation/review pair, using the existing verified packet override, so normal finish leaves the persistent root checkout unchanged and reports synchronization pending.
- Preserve: `_IMPLEMENTATION_SUFFIXES`; exact source/test path documentation; archive integrity, file-mode, trace, claim identity, ancestry, source-span and validation-coverage checks; shared `task_packet_contract.py`; local `ad2009ca9`, its remote position, claim, continuation and evidence; held support review run `20261019T100457Z-dc3179d68792`; historical recovery-plan prohibition; persistent root checkout.
- Non-goals: Changing shared packet parsing; modifying, pushing, resetting, or closing either preserved review branch; producing or altering any review verdict; resuming the support review; running or applying the historical recovery plan; broadening Markdown or source/test eligibility.
- Acceptance:
  1. The exact declared `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md` path is accepted.
  2. An indented-only Work surface declaration is rejected for Markdown authorization.
  3. Duplicate top-level declarations are rejected, even when one contains the requested path.
  4. A nested competing declaration alongside a valid top-level declaration is rejected.
  5. A Markdown path mentioned elsewhere in the packet but absent from the unique Work surface value is rejected.
  6. Existing source/test allowlist, claim, trace, archive-boundary, file-mode, ancestry and source-span regressions remain green; shared parser behavior is unchanged.
  7. `workstream.py finish` permits `--defer-root-sync` only for this exact paired workstream under the packet's explicit override; the persistent root remains at its pre-finish commit and synchronization is reported pending.
  8. Dispatcher must continue to block claims while `paired-review-source-provenance` is held; do not bypass or rewrite that lock.
- Validation: Focused Work surface cases in `python3 custodian/tools/agent/test_paired_review_runner.py`; root-sync authorization cases in `python3 custodian/tools/agent/test_workstream.py`; `python3 -m py_compile custodian/tools/agent/paired_review_host_validation.py custodian/tools/agent/workstream.py`; `python3 custodian/tools/validation/run_validation.py --changed --json`; `git diff --check`; targeted `dispatch.py audit --json` after publication.
- Task overrides: `TASK OVERRIDE: Defer persistent root synchronization for this implementation and its paired review. Do not synchronize the root checkout; record synchronization pending.`
- Deferred: Claiming or implementing until dispatcher confirms the source-provenance lock is available. The disputed review remains unresolved and must not be treated as PASS or retroactively assigned findings by this implementation workstream.
