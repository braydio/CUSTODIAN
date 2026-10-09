# TASK PACKET QUEUE RECONCILIATION V1

- Packet schema: custodian.task_packet.v2
- Workstream: task-packet-queue-reconciliation-v1
- Status: complete
- Dispatch: auto
- Priority: P0
- Depends on: none
- Locks: agent-dispatch, task-packet-contract, task-packet-index
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, workflow
- Paired review workstream: review-task-packet-queue-reconciliation-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: shared control-plane recovery and bulk queue lifecycle changes warrant an independent safety and eligibility audit
- Reviewed main: ca678018d2a44299f82d424a752a5955e6d63188
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a
- Visual review: none
- Goal: Recover and reconcile every outstanding CUSTODIAN packet/workstream, safely organize its active versus archived state, and make the existing dispatcher enforce one auditable, durable organization contract so real work cannot silently strand again.
- Completion boundary: Done when fresh live inventory and actual dispatcher eligibility agree; all five known malformed ready packets are repaired; recoverable orphaned work is restored or protected with an actionable disposition; abandoned claims and historical completed-packet debris are safely reconciled where affirmative evidence permits; a shared-authority queue audit and preventative checks exist; packet index, agent guidance and durable ledger match the resulting truth; focused validation and paired review can prove no work was lost.
- Current measured state: Historical main d6028a6d audit counted 231 top-level active-directory Markdown files, 107 canonical managed packets (56 implementation-ish and 51 paired reviews), 53 complete-looking packets in the active directory, four canonical agent branches all zero ahead (one plausibly live, three possibly stranded), five ready packets invalid/invisible to the managed queue, and at least eight obvious no-dependency candidates. THESE COUNTS ARE A HISTORICAL BASELINE, NOT CURRENT DISPATCH TRUTH. By authoring, main had advanced through 58350dbc and backlink commits to ca678018. Existing dispatcher/parser/index already distinguish READY, CLAIMED, DEPENDENCY/LOCK BLOCKED, MANUAL READY, PARKED DRAFT and INVALID/RECOVERY; reuse rather than replace those controls.
- Evidence: custodian/tools/agent/dispatch.py; task_packet_contract.py; task_packet_index.py; validate_task_packet_authoring.py; workstream.py; workflow_control.py; branch_hygiene.py; their focused tests; custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md; task_packets/README.md; archived/TASK_PACKET_QUEUE_STRANDING_HARDENING.md; the current four Vehicle and one Sundered invalid packet examples.
- Task-specific authority: task_packet_contract.py is the sole schema and queue-validation authority; dispatch.py is the sole effective eligibility, claim and status authority; task_packet_index.py renders only the bounded README projection; workstream.py/workflow_control.py own local/remote branch, claim and worktree safety. No parallel scheduler, queue parser or persistent source-of-truth database.
- Work surface: custodian/tools/agent/ controls and focused fixtures; directly implicated task_packets/ and archived/ metadata, generated README block, AGENTS/next-skill/workstream authoring guidance, and a concise durable queue reconciliation ledger under custodian/docs/ai_context/. Repository code and design outside agent tooling are read-only unless a specific broken cross-reference is proven.
- Change: Perform the evidence-led cleanup and hardening sequence below, preserving identities and claim ownership and introducing no speculative task implementations.
- Preserve: Active dirty worktrees and private commits; existing remote claim CAS/mutex and workstream finish safety; complete historical packet bodies; dependencies and review/correction gates; explicit ready/manual user holds; automated ready/auto wake-up when dependencies archive; current priority/locks; local main safe-sync rules and agent ownership.
- Non-goals: No gameplay/asset feature work, background daemon, duplicate queue engine, wholesale V2 migration of legitimate legacy history, fabricated completion, blind remote branch deletion, force push, destructive reset/clean/stash, automatic human-design decisions or unconditional conversion of manual to auto.
- Acceptance: All measured before/after counts and per-identity dispositions are reproducible; the five known malformed packets parse and enter the correct managed state; no legitimate ready/auto packet is unindexed without a specific blocked/invalid reason; claim releases and archives are evidence-proven and lossless; dispatcher audit classification agrees with actual claim behavior; prevention catches regressions; a second repair/audit run is idempotent; no previously eligible work regresses without explicit documented cause.
- Validation: First the packet-authoring preflight on each changed active packet/pair, then focused custodian/tools/agent/test_task_packet_contract.py, test_dispatch.py, test_task_packet_index.py, test_workstream.py and new recovery/audit fixtures. Follow with dispatch.py status, task_packet_index.py check/--write as needed, validate_review_pairing.py, check_ai_context.py, changed-file validation and git diff --check. Report pre-existing unrelated failures honestly. Moment Forge not applicable to control-plane/document changes.
- Task overrides: none
- Deferred: Continuous external queue dashboard, time-based notifications, multi-machine leasing redesign and speculative cleanup of evidence-incomplete historical artifacts.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: `TASK_PACKET_QUEUE_RECONCILIATION_V1_LEDGER.md` records the before/after dispatcher identities/counts, five specified malformed packet repairs, additional evidence-backed latest-main metadata fixes, all 24 byte-preserving archives, 22 completion-ambiguous active records retained, branch/claim ownership dispositions, and protected blockers. `dispatch.py audit --json` and `status` agree on final live classes; second repair apply is idempotent; generated index, shared context validation and 48 review-pair checks pass; seven focused unittest modules pass (168 tests); changed-packet authoring preflight and git diff checks pass. No claimed branch, worktree, lock, or ambiguous legacy packet was removed.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `origin/main advanced repeatedly during reconciliation and its NPA-4 landing changed packet paths while audits were running; an initial combined unittest run exposed order-sensitive stdout capture failures although each affected module passed in a fresh process.`
- Root cause / contributing factors: `The reconciliation was operating across a live shared queue; candidate-tree and fetched-main state differed at multiple points. Some test modules share global process state when combined.`
- Prevention / pipeline improvement: `Re-fetch/merge before final audit and lifecycle finish; run focused CLI test modules in isolated processes; audit uses dispatcher eligibility and explicit tree selection.`
- Tooling / docs drift discovered: `Three newly landed packets had a stale validation script or incomplete paired-review metadata/override; fixed mechanically and recorded above. Existing historical invalid/recovery entries remain explicitly classified.`
- Follow-up: `fixed-in-scope`
- What worked: `Deterministic repair previews and dispatcher-backed audit made identity-preserving cleanup reproducible.`

## Implementation contract

### A. Baseline and recovery ledger

1. Fetch origin/main and capture its exact SHA before touching metadata. Run python3 custodian/tools/agent/dispatch.py status on the live checkout and record counts for READY, CLAIMED, DEPENDENCY/LOCK BLOCKED, MANUAL READY, PARKED DRAFT and INVALID/RECOVERY. Separately inventory top-level Markdown, valid managed implementation/review/correction, manual and legacy entries, complete-looking active files, archived-complete history, remote agent branches, interrupted dispatch-claims and locally attached worktrees. A Status: ready string alone is not an eligibility finding.
2. Compare active IDs, archived IDs, metadata/pair/dependency graph, remote refs, available diagnostic traces, closing summaries and Next Handoff links. Each orphan/stranded/redundant identity must have one evidence-backed row recording path, problem, branch/claim/ref ownership, remedy, before/after eligibility and any outstanding protected blocker. Write a compact durable ledger in custodian/docs/ai_context/ (not a second manually maintained queue database). Compare current facts to the historical d6028a6d counts rather than reusing them.

### B. Recover concrete invalid packets

3. Reinspect and fix these four exact workstreams: vehicle-diagnosis-knowledge-v1; review-vehicle-diagnosis-knowledge-v1; vehicle-part-fabrication-recovery-v1; review-vehicle-part-fabrication-recovery-v1. Their Review modes currently include unsupported persistence. Remove/replace only that illegal mode with supported values after checking the live parser; retain all persistence/save-load obligations in acceptance and review prose. Fix sundered-keep-overlook-alternate-vertical-slice by setting its top-level Visual review header to required and moving/retaining the human review instructions and questions in the body. Verify pairs, valid dependencies and authoring preflight. Ready/auto but dependency-gated is a valid result; do not falsely promise instant eligibility.
4. Search for additional ready/auto packets invisible to managed queue due to malformed enum, field wrapping, required metadata, duplicate ID, invalid pairing, validation reference, absent dependency or stale generated index. Repair mechanical contract drift directly. Recover genuinely unfinished orphaned work into a current-main packet with original stable intent/provenance when possible; do not reopen already-complete work or manufacture an implementable contract from absent evidence. Preserve ambiguous cases visibly as INVALID/RECOVERY with a specific remedy.

### C. Reconcile claims and lifecycle debris safely

5. Check the historical candidates awakening-handoff-readiness-art-convergence-v1-r1, ash-bell-ritualant-runtime-truth-closeout, operator-mobile-guard-composition and review-bridged-falls-generated-region-lifecycle-review-corrections-1 if still present, plus all newly discovered agent and dispatch-claim refs. Inspect git ancestry/ahead-by, local git worktree list --porcelain, dirty/staged/untracked state, published diagnostics, run traces and credible owner activity. A zero-ahead branch, age or stale diagnostic is insufficient alone. Explicitly protect any plausibly live Awakening session, dirty worktree, unique commit, uncertain ownership or lease. Only release a claim through the established branch-hygiene/lifecycle safety path after affirmative no-owner/no-unique-work evidence; log its disposition. Never unlink dispatch mutex files or bypass Git CAS.
6. Reassess the historical 53 completed-looking Markdown files still inside active task_packets/. Move only unambiguously complete, reviewed or deliberately final-without-review, content-reachable records into archived/ through the current lifecycle; preserve content and summary/backlink identity and reconcile dependents/index. Leave uncertain/legacy debris with explicit disposition, not a forged Status: complete. Archive/recovery must be idempotent and reversible using Git history.

### D. Make organization enforceable, without a second source of truth

7. Extend dispatch.py and shared contract minimally with a deterministic read-only full queue audit (human and machine JSON) or an equivalent canonical entrypoint. For each workstream show ID, path, kind, declared status/dispatch/priority, actual class, eligible-now boolean, precise reason(s) for ineligibility, dependencies/review pairing, current claim and recovery disposition when provable; summarize all classes and distinguish raw file count from managed count and claimable count. The index remains a generated VIEW of valid ready/auto packets, not selection authority. If classification currently diverges among index/dispatcher/validator, consolidate the shared decision rather than copying it.
8. Add a bounded dry-run repair plan with itemized before/after changes and an apply path for only safe deterministic metadata/index/archive migrations, or a tightly scripted one-time migration with identical preview/safety/idempotence guarantees. Do not automate destructive branch/worktree cleanup under repair --apply. Fail closed on ambiguous completion, local ownership or intent. Make error output give one actionable correction. A second run must produce zero new changes.
9. Wire authoring and CI/pre-landing checks through existing test/validation infrastructure: invalid active V2 enum or draft/auto, duplicate active ID, nonexistent dependency identity, paired review/correction mismatch, invalid script reference, unowned ready/auto, and stale README index must be detectable before another packet lands. Preserve legacy and ready/manual semantics. Update root/custodian AGENTS, custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md, task_packets/README.md, AGENT_WORKSTREAM_LIFECYCLE.md, .agents/skills/custodian-next/SKILL.md and related guides only where authority or wording is actually stale. All agents must author through the same preflight, claim through dispatch, and archive/update index at finish; do not proliferate boilerplate.

### E. Adversarial proof and closeout

10. Build focused temporary-repository fixtures: malformed persistence Review modes, prose Visual review field, duplicate ID, missing dependency identity, complete-dependency wake-up, manual ready versus parked draft, paired review and correction blocking, lock conflict, claimed-ready, abandoned temporary claim, zero-ahead dirty occupied worktree, orphaned packet and ambiguous completed legacy record. Assert actual claimability matches reported class, negative cases fail closed, archive preserves bytes/history, JSON stable order, and repair idempotence. Add a before/after identity set comparison proving no previously valid work silently disappeared.
11. Publish ledger with exact live SHA, baseline and final counts, identities of all five named repairs, claim dispositions, archived filenames, orphan recovery outcomes, unresolved protected blockers, remaining claimable IDs, test commands/results and relevant documentation drift. Rebuild/check the generated README and run dispatch status after changes. Landing and paired review follow the normal workstream lifecycle.

## Refresh Planning Authority

- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a
- Refresh instruction: Recalculate all counts, dependency eligibility and claim/worktree ownership from latest origin/main at claim time. Resolve mechanical queue drift without another planning round. Stop only on a genuinely ambiguous destructive ownership decision or new user-owned manual/design gate; complete independent safe repairs despite protected blockers.

## Handoff

- Next workstream: review-task-packet-queue-reconciliation-v1
- Next packet state: dependency-gated
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a
- Next action: After this implementation lands and archives complete, claim review-task-packet-queue-reconciliation-v1 in a fresh reviewer context.
- Blockers or open questions: No planning blocker to claiming. Ambiguous claim ownership is an item-specific safety stop, never permission to delete work.
