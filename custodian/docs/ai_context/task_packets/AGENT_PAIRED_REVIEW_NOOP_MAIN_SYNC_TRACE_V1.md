# Paired Review: No-Op Main-Sync Trace Provenance V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-noop-main-sync-trace-v1`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `paired-review-noop-sync-provenance`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-noop-main-sync-trace-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `a security-critical fail-closed provenance check is preventing independent reviewer launch`
- Reviewed main: `0303fc4f3033fa74416d16c19505ce435f1cd0e1`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Visual review: `none`
- Goal: Admit an exact, already-synchronized two-parent source-first landing when its unique immutable lifecycle `main_sync` event truthfully records `changed=false`, without accepting forged or undocumented source spans.
- Completion boundary: The existing pinned host-validation source-span resolver accepts precisely the legitimate no-op retry shape, retains all current positive `changed=true` behavior and adversarial rejections, and proves the repair in focused real-Git tests. This tooling change does not manipulate any protected review claim or launch a reviewer.
- Current measured state: `custodian/tools/agent/workstream.py::sync_main()` returns false if `origin/main` is already ancestor of HEAD; `_finish_impl` records `main_sync(changed=that_result, head=HEAD, main_sha=origin/main)`. A valid source-first merge can already be HEAD on retry, producing a truthful false event. `custodian/tools/agent/paired_review_host_validation.py::_split_landing_source_span` currently filters `main_sync` events with `data.changed is True` (around lines 381-398 on `07d1180f`) before checking the merge's parents, causing `review-agent-paired-review-braced-work-surface-v1` run `20261019T130624Z-4c48a64653e0` to remain in `host_validation_recovery`. Its implementation correction landed `3b3d3893236f1ef61a00d03f0fb6dddaa3a48274`; the first parent is `c5e5b7032a1c0853cffac39931e703d81942bc03`, the second is `f6a9e745f6db34d0d8c79f2edc56eb5f8049e633`. The local trace's `main_sha`, branch and original run evidence have NOT been independently read by this authoring session.
- Evidence: `custodian/tools/agent/paired_review_host_validation.py::_split_landing_source_span`; `custodian/tools/agent/workstream.py::sync_main` and `_finish_impl`; `custodian/tools/agent/test_paired_review_runner.py::PairedReviewHostValidationTests`, especially `test_split_landing_rejects_main_sync_trace_without_changed_sync`; protected run `.git/custodian-review-runs/review-agent-paired-review-braced-work-surface-v1/20261019T130624Z-4c48a64653e0`; current existing recovery lifecycle contract.
- Task-specific authority: `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md` (host-validation recovery); current unique claim and trace pairing, canonical archive-versus-trace landing rules, `_source_code_paths` documentation gate and validation evidence verification; source-bearing archive tests.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; only update `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md` if a short clarification is necessary to avoid active-contract drift.
- Publication inputs: `none`
- Change:
  1. Modify only the narrow `main_sync` event predicate in `_split_landing_source_span` and matching focused tests. Keep the event filtered to the same unique target run/workstream/packet/trace, the same exact `head == trace_landing`, the same `main_sha == second Git parent`, the same two-parent first-parent == canonical archive rule, and the same ancestry and source/target byte-preservation checks. `changed` must be a literal boolean, never a truthy string, missing field or null. Do **not** generally allow false `main_sync` events to create source-span authority, including on a one-parent landing.
  2. Permit a unique `changed=false` event only when the actual Git parent graph independently establishes a preexisting archive-first/prior-main-second merge and the exact event `head` and `main_sha` match that graph. Retain all existing `changed=true` acceptance. Reject duplicate or contradictory qualifying events rather than arbitrarily choosing one. Never recalculate `main_sha` from current remote tips or infer review SHA from the latest main.
  3. Replace the overly broad negative-only test `test_split_landing_rejects_main_sync_trace_without_changed_sync` with an exact legitimate no-op positive plus separate **negative** tests for false on a single-parent landing, missing/duplicate/conflicting sync events, missing or wrong `head`, wrong prior-main SHA, reversed parent order, changed archived target/source, forged trace identity, extra code/asset changes and unrelated merges. Existing `changed=true` and historical review cases must remain green.
  4. When the existing remote historical trace ref and source commits are locally accessible, run a **read-only** exact resolver against the protected braced-work-surface case; require independently verified `main_sha` equals second parent `f6a9e745...`. If the historical trace has an additional mismatch, stop and report it, not invent a false positive or modify trace data. Do not access or mutate either held review worktree or run artifacts. Prefer fixtures for deterministic CI.
- Preserve: `agent/review-agent-paired-review-braced-work-surface-v1`, its existing protected claim/worktree/run `20261019T130624Z-4c48a64653e0`; `agent/review-operator-motion-foundry-core-v1` and its run `20261019T113817Z-30745c8a87a1`; original archived implementation packets, hash-locked references, current workstream tracer, authorization gates, all live gameplay and art assets. The new tool workstream has its own `paired-review-noop-sync-provenance` lock, not either held review's lock, because it writes only coordinator host-validation source and tests. Locally verify no other claimed writer overlaps this work surface before implementing.
- Non-goals: No claim/reclaim/cleanup or continuation/apply of either existing run, no trace rewriting, no fabricated `changed=true` event, no validation bypass, no MF1 art/asset changes, no general merge/rebase ancestry acceptance, no new reviewer.
- Acceptance: A real Git fixture with valid canonical archive and exact two-parent sync merge passes with `changed=false` and `changed=true`; the reported canonical archive SHA/source span remains unchanged in both. Forged/missing/ambiguous sync, wrong second parent, wrong workstream/branch/run, false one-parent trace, changed sources or archived packet, executable/symlink extras, unrelated code paths and absent selected coverage fail closed. Complete existing paired-review-host unit suite and changed-file validation. Report the preserved historical case as `not verified locally` if its trace isn't accessible, never as PASS.
- Validation: `python3 custodian/tools/agent/test_paired_review_runner.py`; `python3 custodian/tools/validation/run_validation.py --changed --json` including registered `paired_review_runner_unit`; `python3 -m py_compile custodian/tools/agent/paired_review_host_validation.py custodian/tools/agent/test_paired_review_runner.py`; `git diff --check`. Run exact historical source-span inspection **read-only** when its diagnostic trace is available; no protected run apply.
- Task overrides: `none`
- Deferred: After independent acceptance of this fix, resume the exact protected braced-work-surface review using only the host-validation recovery plan and explicit authorized apply; only after its genuine verdict resume protected MF1 review, then allow MF2's dependency gate to clear.

## Next Handoff

- Next workstream: `review-agent-paired-review-noop-main-sync-trace-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Refresh reason: `none`
- Next action: `Fresh independent review of this exact host-validator correction. Do not resume an original run from the implementation worker.`
- Blockers or open questions: `Two independently preserved review runs remain in host_validation_recovery; protected local evidence and trace main_sha require local verification.`
