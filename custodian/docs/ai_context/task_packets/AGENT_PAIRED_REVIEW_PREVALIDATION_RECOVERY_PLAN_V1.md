# Paired-review pre-validation recovery plan

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-prevalidation-recovery-plan-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-claim-base-ancestry-provenance-v1`
- Locks: `paired-review-prevalidation-recovery-plan`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, workflow`
- Paired review workstream: `review-agent-paired-review-prevalidation-recovery-plan-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `377644b00547c4a3430c4eb3f296c75822a49678`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad41ae1-c654-83ea-ba9f-2b4dc4dde401`
- Authoring handoff: `auto`
- Visual review: `none`
- Goal: Permit a read-only recovery plan for the exact held review run interrupted before host validation reports were created, without weakening provenance checks for validated or contradictory runs.
- Completion boundary: The paired-review planner can classify and plan the verified pre-validation interruption, regression tests establish the accepted and rejected evidence states, and implementation is landed and archived. The original plan is generated read-only only after this correction's independent review passes.
- Current measured state: `paired_review_runner.py::_host_recovery_plan_unlocked()` unconditionally requires `validation.json` and `coordinator-validation.json`, although `continue_run()` already validates afresh under `continuation-01/host-validation/`.
- Evidence: Historical run `20261019T024516Z-fcfcefa2d521` under the canonical source-bearing review run directory has original metadata and claim evidence but no host-validation reports; its source span must remain based at `8fa7c190936ce98ca5a9bb93f28fcb4862c9acb8`.
- Task-specific authority: `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/host_validation.py`, `custodian/tools/agent/test_paired_review_runner.py`, and the archived ancestry-provenance correction packet/review receipt.
- Work surface: `custodian/tools/agent/paired_review_runner.py`; regression coverage in `custodian/tools/agent/test_paired_review_runner.py`.
- Publication inputs: `none`
- Change: Classify a pre-validation interruption only when both report files are absent, original metadata contains no pinned host-validation result, original claim/worktree/source identities verify exactly, the evidence manifest is captured, and no continuation child exists. Permit a read-only plan in that state and direct continuation to fresh validation under `continuation-01/host-validation/`. Preserve the existing report hash and provenance requirements when both reports exist.
- Preserve: Source-span base `8fa7c190936ce98ca5a9bb93f28fcb4862c9acb8`; all held review claims, original traces, worktrees, and evidence; existing validated-run behavior; original evidence manifest; exact claim/worktree and target implementation identity checks.
- Non-goals: Applying the historical run's plan; launching its reviewer; continuing W1; changing source-span resolution; changing or recreating other held runs/worktrees; syncing or rewriting the root checkout; touching `custodian_grunt_runtime_ab_v1.zip`; general recovery audit.
- Acceptance:
  1. The exact historical run produces a read-only plan only after correction review passes; plan pins the original run/claim/worktree, source base exactly `8fa7c190936ce98ca5a9bb93f28fcb4862c9acb8`, and original evidence manifest without modifying it.
  2. Both original reports absent plus no metadata-pinned validation result is accepted only with exact original claim/worktree identity and no continuation child; plan identifies fresh continuation validation.
  3. Both reports present retain required hashes and provenance checks.
  4. Fail closed for partial report pairs, metadata that says validation already occurred while reports are absent, mismatched run/claim/worktree identity, changed evidence manifest, and any preexisting continuation child.
  5. Focused paired-review runner tests and Python parse checks pass; source/test commit is separate from archival closeout.
  6. Independent paired review passes before the original historical plan is generated. After generating it, verify its pins and stop without applying it or launching a reviewer.
- Validation: `python3 -m unittest custodian.tools.agent.test_paired_review_runner`; `python3 -m py_compile custodian/tools/agent/paired_review_runner.py custodian/tools/agent/test_paired_review_runner.py`; run the exact historical `--recover-host-validation --plan` command only after paired review PASS and compare its identities, source-span base, manifest hash, and evidence hashes to the preserved baseline.
- Task overrides:
  - `TASK OVERRIDE: Do not apply the historical recovery plan or launch its reviewer in this workstream.`
  - `TASK OVERRIDE: Preserve all existing held review claims, original traces, worktrees, and evidence; do not create replacement claims or worktrees.`
- Deferred: Applying the verified plan and launching the original reviewer require a separately verified recovery plan and authorization.

## Process and handoff

- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad41ae1-c654-83ea-ba9f-2b4dc4dde401`
- Refresh instruction: `none`
- Next Handoff: After independent review passes, generate the exact original recovery plan read-only, verify every pin against preserved evidence, and stop. Do not apply it or launch the reviewer.
