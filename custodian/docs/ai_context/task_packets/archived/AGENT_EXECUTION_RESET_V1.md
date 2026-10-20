# CUSTODIAN EXECUTION RESET V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-execution-reset-v1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `custodian-execution-reset`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-execution-reset-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Administrative claim disposition and dispatcher lock behavior require independent proof because a false release can overlap writers or corrupt preserved work.`
- Reviewed main: `94b17d41e34fdf4157f26a254e2943a12eb4aa45`
- Authoring chat: `not-recorded`
- Authoring handoff: `auto`
- Visual review: `none`
- Goal: Restore a truthful, recoverable execution frontier while preserving unresolved historical work and allowing independent CUSTODIAN feature development.
- Completion boundary: Publish one auditable `legacy_quarantined` disposition distinct from completion, review acceptance, release, and ordinary parking; retain duplicate-claim protection; release execution locks only for exact verified inactive owners; protect ambiguous owners; document and test generation fencing; apply the disposition only to explicitly audited legacy claims; then use normal dispatch to land one useful gameplay, visual, or asset feature packet.
- Current measured state: At `origin/main@134e4c29`, the legacy dispatcher reports 1 claimable auto packet, 54 claimed, 213 dependency_lock_blocked, 65 invalid_recovery, 1 manual_ready, and 47 parked_draft. Nine `refs/custodian/legacy-quarantined/*` records are already present remotely, but this main revision does not read them and still reports no `legacy_quarantined` class. Against the same fetched packets and refs, the reset branch reports 9 verified quarantined identities and 2 claimable auto packets, including `agent-paired-review-claim-publication-main-advance-v1`. All nine same-host process traces currently verify exited; remote/local quarantine record SHAs match. The exact backup manifest is SHA-256 `a25387215f15de045c3b84258a934f0a93cfcbdea20fd7acb677e43e98c466b1`. The already-claimed visual workstream `operator-motion-foundry-blender-2d-rig-v1` landed at `origin/main` through `2e0ea6a67c4f`; its final changed-file suite passed 44/44. Its paired review is preserved but host validation is blocked before reviewer launch by `archive-only landing contains unrelated paths`.
- Evidence: `custodian/tools/agent/legacy_claim_quarantine.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/workflow_control.py`; `custodian/tools/agent/test_legacy_claim_quarantine.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; backup and recheck manifests named below.
- Task-specific authority: Root `AGENTS.md` execution reset authorization dated 2026-10-20; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; current dispatch and workstream implementation.
- Work surface: `custodian/tools/agent/legacy_claim_quarantine.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/workflow_control.py`; `custodian/tools/agent/test_legacy_claim_quarantine.py`; `custodian/tools/agent/test_dispatch.py`; `custodian/tools/agent/test_workstream.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/task_packets/README.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_EXECUTION_RESET_V1.md`; `custodian/docs/ai_context/task_packets/REVIEW_AGENT_EXECUTION_RESET_V1.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_CLAIM_PUBLICATION_MAIN_ADVANCE_V1.md`; `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_PAIRED_REVIEW_ADVANCED_HEAD_PASS_CLOSEOUT_V1.md`; `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_PAIRED_REVIEW_CLAIM_PUBLICATION_MAIN_ADVANCE_V1.md`; `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_PAIRED_REVIEW_EXACT_CLAIM_PARKING_V1.md`; `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_PAIRED_REVIEW_INVALID_DISPOSITION_RECOVERY_V1.md`; `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_PAIRED_REVIEW_PREVALIDATION_RECOVERY_PLAN_V1.md`; `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_PAIRED_REVIEW_SOURCE_BEARING_ARCHIVE_GATE_V1.md`; `AGENT_EXECUTION_RESET_V1_CLAUDE_SUMMARY.md`.
- Publication inputs: `custodian/tools/agent/dispatch.py`, `custodian/tools/agent/workstream.py`, `custodian/tools/agent/workflow_control.py`, `custodian/tools/agent/legacy_claim_quarantine.py`, `custodian/tools/agent/test_dispatch.py`, `custodian/tools/agent/test_workstream.py`, `custodian/tools/agent/test_legacy_claim_quarantine.py`, `custodian/tools/validation/validation_manifest.json`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Change:
  1. Add a read-only inventory/plan and exact-owner, append-only `legacy_quarantined` record for stranded legacy claims. Bind the record to the workstream, run/claim identity when present, exact remote ref names and SHAs, local worktree/evidence manifest hashes, reset generation, and plan digest. Require CAS against the original refs on apply.
  2. Preserve claim identity for duplicate prevention. Quarantine is not `complete`, `passed`, `released`, `PARKED`, or accepted review, and never satisfies a dependency.
  3. Integrate with dispatch so only a current, exact, independently verified quarantine record can remove that owner's execution lock from conflict calculations. Missing, stale, malformed, mismatched, or changed-ref records restore conservative lock occupancy. Unknown/cross-host owners remain isolated with their lock held.
  4. Prevent ordinary start/resume/finish from automatically reopening a quarantined identity. Quarantine is one-way in this bounded reset; future reactivation is outside scope and requires a separately authorized exact-owner procedure.
  5. Add a monotonic execution generation and tests for generation mismatch, duplicate claims, live-owner exclusion, lock collision, stale refs, cross-generation behavior, and review dependency truth.
  6. Preserve every affected local ref, worktree, untracked/symlink file, and reviewer evidence before any live disposition. Record checksummed backup inventory and before/after dispatch audits. Do not modify the protected Broken Warrant ignored `.blend` outputs as part of this workstream.
  7. Reconcile only explicitly superseded recovery proposals with truthful `legacy_quarantined` metadata; preserve original claims and verdicts. Leave ambiguous ownership and unrelated recovery history untouched.
  8. Apply only to claims that pass the exact safe-owner gate. If no claim can safely release a lock, leave that resource locked and demonstrate independent eligible work instead.
  9. Use normal dispatcher/lifecycle flow to claim, implement, validate, and land the existing visual feature `operator-motion-foundry-blender-2d-rig-v1`, unless a fresh audit identifies a more suitable claimable gameplay/visual/asset feature. Do not change runtime behavior to accommodate workflow state.
- Preserve: All remote agent branches, dispatch-claim refs, local-only commits, worktree files, untracked and ignored work, run evidence, reviewer summaries and verdicts. Preserve normal lock collision and accepted-review dependency rules. Keep the disputed declared-documentation review unresolved. Leave the Broken Warrant `.blend` masters/proofs untouched.
- Non-goals: Force push, reset/rebase/delete unique branches, remove evidence, declare old reviews passed, release live/unknown owners, implement generalized OR1/OR2 host process supervision, modify game behavior for workflow convenience, alter Broken Warrant assets, or apply the historical source-bearing recovery plan.
- Acceptance:
  1. Every quarantine transition is append-only, exact-owner, digest-pinned, CAS-fenced, and independently auditable; original refs and evidence are unchanged.
  2. A valid quarantined claim remains claimed for its own identity and cannot satisfy review dependencies; only its verified execution-lock occupancy is excluded.
  3. Missing/corrupt/stale records, changed refs, active owners, ambiguous cross-host state, lock collisions, duplicate claims, and reversed/stale generations fail closed.
  4. Start/resume/finish cannot silently reactivate quarantined work; no unquarantine command or automatic reactivation is introduced.
  5. Backup manifests cover original refs, commit ancestry, worktree paths/status, tracked modifications, untracked files, symlinks, and protected run evidence, with SHA-256 verification for copied payloads.
  6. Recovery proposals superseded by this reset remain inspectable with truthful administrative metadata; no review is rewritten as PASS or canonical findings.
  7. Dispatcher audit reports before/after claimability and distinguishes packet readiness from active lock eligibility.
  8. One existing gameplay/visual/asset implementation packet is normally claimed, validated, and landed, with its scope and validation recorded.
- Validation: Focused `python3 -m unittest custodian.tools.agent.test_legacy_claim_quarantine custodian.tools.agent.test_dispatch custodian.tools.agent.test_workstream`; snapshot and batch-plan/apply tests against temporary bare remotes and two clones; targeted packet authoring validation; `task_packet_index.py --write` then check; `dispatch.py audit --json` before and after; `git diff --check`; run the feature packet's exact focused validation and required changed validation. No broad Godot sweep unless its feature packet requires it.
- Task overrides: `TASK OVERRIDE: this reset authorizes one exact, evidence-bound legacy quarantine transition after backup and validation; it does not authorize deleting refs, stopping unknown processes, releasing active/ambiguous owners, changing review verdicts, or using quarantine as accepted review.`
- Deferred: General host-supervised OR1/OR2 recovery; reactivation of quarantined claims; independent disposition of held review runs; human art approval of candidate assets.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: `The reset implementation and 150 focused tests are committed on this workstream. Its local dispatch audit consumes all nine exact remote quarantine records, keeps all nine identities claimed, releases only their verified exited-owner lock occupancy, and reports two claimable auto packets versus one on current main. The existing Operator Blender visual feature landed on main with its full changed-file suite green. Existing records were reverified against the original SHA-256 backup, current branch/claim refs, current same-host process traces, and immutable reviewer evidence; no quarantine ref was created or rewritten by this run. The post-sync main audit will be recorded at finish.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `high`
- What went wrong: `The claimed Blender feature's paired review stopped before reviewer launch because the archived target commit also contained its source files. During reset re-audit, nine quarantine refs appeared remotely after the earlier read-only audit; they were preserved and independently rechecked rather than republished. A focused test exposed that the quarantine planner looked up remote record refs under an incorrect namespace and that apply could overwrite a pre-existing local candidate record; both cases now fail closed or reuse an exact record without rewriting it.`
- Root cause / contributing factors: `The feature archive closeout and source payload shared one commit, violating the host validator's archive-only path contract. Quarantine record handling did not distinguish local candidate records from remote canonical records.`
- Prevention / pipeline improvement: `Keep implementation commits separate from packet archive-only closeout commits. Reuse exact local quarantine record commits, bind their SHA in the plan, use compare-and-swap for new local refs, detect exact remote refs, and remove only refs created by the failed attempt.`
- Tooling / docs drift discovered: `The quarantine remote-tracking ref path contained an extra refs/ segment; owner and local-record regressions now cover exact existing records and remote record reuse/rejection.`
- Follow-up: `fixed-in-scope`
- What worked: `A single evidence-bound batch recheck established all nine original claim/worktree identities and same-host process-exit traces without altering any protected claim or review.`

## Next Handoff

- Next workstream: `review-agent-execution-reset-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: Fresh-context independent review of exact-owner fencing, preservation, lock separation, generation behavior, and the current remote record state. After the review, re-run `dispatch.py audit --json` on current main and confirm claimable work includes the existing paired-review main-advance packet.
- Blockers or open questions: The feature review remains preserved but blocked before reviewer launch; no PASS exists. The nine quarantine refs were already present remotely, and this workstream did not publish or rewrite them. Cross-host owners remain lock-isolated.
