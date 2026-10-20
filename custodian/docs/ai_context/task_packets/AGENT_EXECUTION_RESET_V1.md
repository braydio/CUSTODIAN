# CUSTODIAN EXECUTION RESET V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-execution-reset-v1`
- Status: `ready`
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
- Current measured state: At `origin/main@94b17d41`, `dispatch.py audit --json` reports 51 claimed, 213 dependency_lock_blocked, 65 invalid_recovery, 1 manual_ready, 47 parked_draft, and 2 ready_auto packets. Two remote dispatch-claim refs have no matching agent branch. The local audit found no paired-review runner, dispatcher claim, or workstream lifecycle process at inspection time; remote process ownership remains unobservable. A claimable visual feature packet, `operator-motion-foundry-blender-2d-rig-v1`, exists.
- Evidence: `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/workflow_control.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; live audit at `origin/main@94b17d41`.
- Task-specific authority: Root `AGENTS.md` execution reset authorization dated 2026-10-20; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; current dispatch and workstream implementation.
- Work surface: `custodian/tools/agent/legacy_claim_quarantine.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/test_legacy_claim_quarantine.py`; `custodian/tools/agent/test_dispatch.py`; `custodian/tools/agent/test_workstream.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; this packet and its paired review; `AGENT_EXECUTION_RESET_V1_CLAUDE_SUMMARY.md`.
- Publication inputs: `custodian/tools/agent/dispatch.py`, `custodian/tools/agent/workstream.py`, `custodian/tools/agent/workflow_control.py`, `custodian/tools/agent/test_dispatch.py`, `custodian/tools/agent/test_workstream.py`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Change:
  1. Add a read-only inventory/plan and exact-owner, append-only `legacy_quarantined` record for stranded legacy claims. Bind the record to the workstream, run/claim identity when present, exact remote ref names and SHAs, local worktree/evidence manifest hashes, reset generation, and plan digest. Require CAS against the original refs on apply.
  2. Preserve claim identity for duplicate prevention. Quarantine is not `complete`, `passed`, `released`, `PARKED`, or accepted review, and never satisfies a dependency.
  3. Integrate with dispatch so only a current, exact, independently verified quarantine record can remove that owner's execution lock from conflict calculations. Missing, stale, malformed, mismatched, or changed-ref records restore conservative lock occupancy. Unknown/cross-host owners remain isolated with their lock held.
  4. Prevent ordinary start/resume/finish from automatically reopening a quarantined identity. Require an explicit, fenced unquarantine transition that re-verifies the record and exact refs; do not implement a bulk release.
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
  4. Start/resume/finish cannot silently reactivate quarantined work; explicit unquarantine is exact-owner and one-time.
  5. Backup manifests cover original refs, commit ancestry, worktree paths/status, tracked modifications, untracked files, symlinks, and protected run evidence, with SHA-256 verification for copied payloads.
  6. Recovery proposals superseded by this reset remain inspectable with truthful administrative metadata; no review is rewritten as PASS or canonical findings.
  7. Dispatcher audit reports before/after claimability and distinguishes packet readiness from active lock eligibility.
  8. One existing gameplay/visual/asset implementation packet is normally claimed, validated, and landed, with its scope and validation recorded.
- Validation: Focused `python3 -m unittest custodian.tools.agent.test_legacy_claim_quarantine custodian.tools.agent.test_dispatch custodian.tools.agent.test_workstream`; CLI plan/apply/unquarantine tests against a temporary bare remote and two clones; targeted packet authoring validation; `task_packet_index.py --write` then check; `dispatch.py audit --json` before and after; `git diff --check`; run the feature packet's exact focused validation and required changed validation. No broad Godot sweep unless its feature packet requires it.
- Task overrides: `TASK OVERRIDE: this reset authorizes one exact, evidence-bound legacy quarantine transition after backup and validation; it does not authorize deleting refs, stopping unknown processes, releasing active/ambiguous owners, changing review verdicts, or using quarantine as accepted review.`
- Deferred: General host-supervised OR1/OR2 recovery; reactivation of quarantined claims; independent disposition of held review runs; human art approval of candidate assets.

## Next Handoff

- Next workstream: `review-agent-execution-reset-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: Fresh-context independent review of the reset's exact-owner fencing, preservation, lock separation, generation behavior, and live evidence.
- Blockers or open questions: Cross-host owner state is not locally observable; such owners must remain lock-isolated unless independently fenced.
