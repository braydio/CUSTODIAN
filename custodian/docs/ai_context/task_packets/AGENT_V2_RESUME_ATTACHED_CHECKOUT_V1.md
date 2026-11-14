# Agent V2 attached-checkout resume — DEBT-0001

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-v2-resume-attached-checkout-v1`
- Category: `agent-ops`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `none`
- Kind: `implementation`
- Review: `none`
- Review stage: `post-land`
- Review modes: `none`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Paired review retired 2026-11-12; exact temporary-Git fixtures prove authenticated checkout reuse, refusal cases, CLI routing, and checkpoint compatibility without a new reviewer claim.`
- Reviewed main: `4069e9ff709c34e063f2018370bae9d2b18404ea`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Make the public V2 `workstream.py resume <id>` command safely continue one already-attached, authenticated, clean turn checkout rather than attempting a second checkout and raising an attached-branch conflict (DEBT-0001).
- Completion boundary: The public CLI routes resume to a distinct V2 resume/adoption operation, retains the original acquisition/turn/run identity and attached worktree, rejects unsafe/ambiguous owners and provenance, and preserves existing fresh `begin`, dependency-metadata `reauthorize`, and verified `checkpoint` behavior. Focused negative and integration tests pass; do not require successful continuation of the real Operator claim as acceptance.
- Current measured state: At `origin/main@4069e9ff709c34e063f2018370bae9d2b18404ea`, `custodian/tools/agent/workstream.py` still routes both `start` and `resume` to `turn_dispatcher_v2.begin()`. `make_turn_checkout()` refuses the already-attached canonical branch, even for an otherwise clean original V2 checkout. Merged PR #150 supplies a *separate* dependency-metadata-only `reauthorize_checkout()`, not general resume; PR #151 classifies Linux kernel threads in the process-ownership scanner. DEBT-0001 remains P1/triaged, and no dedicated active implementation packet or matching `agent/v2-resume-attached-checkout-v1` branch was found at authoring time. The host coordination root is reported behind origin/main with three unrelated untracked procgen files; preserve it rather than making cleanup a prerequisite to remote packet authoring.
- Evidence: `custodian/docs/ai_context/debt/DEBT-0001-workstream-resume-rejects-attached-checkout.md`; `custodian/docs/ai_context/debt/REGISTER.md`; `custodian/tools/agent/workstream.py` public CLI dispatch; `custodian/tools/agent/turn_dispatcher_v2.py` checkout creation and existing acquisition/continuation receipts; merged GitHub PRs #150/#151; Codex host checkpoint on 2026-11-14 reporting 51 attached worktrees and preserved root untracked files.
- Task-specific authority: Root `AGENTS.md`, `custodian/AGENTS.md`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`, DEBT-0001 and `custodian/docs/ai_context/ARCH_DEBT_POLICY.md`. Workstream identity, original V2 acquisition, attached worktree and immutable remote branch are authoritative; historical legacy `RunTrace.resume` and paired-review recovery are not alternative admission paths.
- Work surface: `custodian/tools/agent/turn_dispatcher_v2.py` (one authenticated resume operation), `custodian/tools/agent/workstream.py` (public command routing), and focused tests in `custodian/tools/agent/test_turn_dispatcher_v2.py` and `custodian/tools/agent/test_workstream.py`. Update current lifecycle documentation only where materially necessary. Keep changes narrow.
- Publication inputs: `custodian/tools/agent/turn_dispatcher_v2.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/test_turn_dispatcher_v2.py`; `custodian/tools/agent/test_workstream.py`; `custodian/docs/ai_context/debt/DEBT-0001-workstream-resume-rejects-attached-checkout.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md` (all tracked on the reviewed main; new test cases are outputs of this packet).
- Change:
  1. Implement a purpose-specific V2 resume path and route only `workstream.py resume` through it; never silently convert fresh `begin()` into attached-worktree adoption.
  2. Authenticate exactly one V2 acquisition receipt and managed attached checkout for the requested workstream; verify Git common directory, canonical branch, checkout pool, original source ancestry, current remote branch, original run/turn identity, clean tracked/untracked state, unresolved ignored-data safety and matching packet provenance.
  3. Serialize resume/checkpoint against the existing continuation lock; use the established process-ownership scanner. Block live, uncertain, cross-host, conflicting, missing/duplicate or stale provenance without changing any checkout. Preserve original bytes, branch, receipts, source art and committed history.
  4. For no longer attached/retired checkouts, preserve existing authorized fresh-checkout resume semantics only if independently proven safe; never manufacture an original acquisition or rename its identity. Keep dependency-metadata reauthorization bounded to its current behavior.
  5. Add exact CLI integration and temporary bare-remote tests. Make repeat resume idempotent; do not create additional worktrees or acquisition records for an already-attached continuation.
- Preserve: Merged PR #150 reauthorization, PR #151 scanner classification, `turn_dispatcher_v2.begin`, `checkpoint`, original V2 acquisition/retirement/continuation records, valid historical claims, local-only files, all active worktrees, and root/main protection. Do not start the preserved Operator claim as a test.
- Non-goals: Root untracked-file relocation, mass worktree garbage collection, new dispatch/orchestration/reviewer framework, old paired-review recovery, validation-runner process-supervision rewrite, LFS/Asset V2 changes, and arbitrary cross-host takeover.
- Acceptance: (A) Attached-clean authentic resume returns exactly the same worktree and original identity; (B) repeated resume is idempotent; (C) public CLI dispatches to V2 resume, fresh start stays distinct; (D) original checkout can checkpoint normally after resume; (E) dirty/untracked/ignored ambiguity, wrong pool/branch/common directory, duplicate/missing receipts, remote drift, mismatched source and live/uncertain owners all fail closed without mutating source or creating worktrees; (F) unrelated root untracked paths stay untouched; (G) all focused tests and complete changed-file validation pass.
- Validation: `python3 -m unittest custodian.tools.agent.test_turn_dispatcher_v2 custodian.tools.agent.test_workstream`; add targeted CLI, receipt, process-owner and bare-remote fixtures in existing suites; `python3 custodian/tools/agent/validate_task_packet_authoring.py custodian/docs/ai_context/task_packets/AGENT_V2_RESUME_ATTACHED_CHECKOUT_V1.md`; `python3 custodian/tools/agent/check_ai_context.py`; `python3 custodian/tools/agent/task_packet_index.py`; `python3 custodian/tools/validation/run_validation.py --changed --json` when host resources allow; `git diff --check`. Never claim Godot or host liveness was verified by remote-only checks.
- Task overrides: `none`
- Deferred: DEBT-0002 coordination guard false positive, root contamination disposition, validation-runner normal-exit/cancellation child cleanup and protected historical reviewer recoveries remain separately owned.

## Next Handoff

- Next workstream: `none` (return to the existing gameplay work after this tooling correction lands).
- Next packet state: `none`
- ChatGPT/user planning refresh required: `no`
- First action: After this draft is automatically promoted by the current single-packet authoring workflow, verify `ready/auto` on fresh `origin/main`; acquire the workstream using canonical V2 dispatch in a suitable stable coordination context. Do not force synchronization or relocate the three unrelated untracked procgen files to make root clean.
- Closeout: Preserve evidence, run focused tests, land through GitHub CI/branch protection, verify source SHA and checkout-retirement receipts, and update DEBT-0001 only after acceptance is demonstrated.
