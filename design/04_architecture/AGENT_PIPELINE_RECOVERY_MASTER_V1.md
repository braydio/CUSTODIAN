# CUSTODIAN Pipeline Recovery Master V1

- Status: proposed master architecture and queue-consolidation authority; no implementation/recovery authorization until the paired bootstrap packet lands and passes independent review
- Program/workstream family: `agent-pipeline-recovery-master-v1`
- Investigated `main`: `7b82b9630e9a63c52e86f8b4805c577a85496aa5` (2026-10-24 07:44 UTC)
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6adb61f3-35fc-83ea-87ed-ba961c7b5925
- Bootstrap implementation: `custodian/docs/ai_context/task_packets/AGENT_PIPELINE_RECOVERY_MASTER_V1.md`
- Bootstrap independent review: `custodian/docs/ai_context/task_packets/REVIEW_AGENT_PIPELINE_RECOVERY_MASTER_V1.md`

## Purpose and central decision

Deliver a reliable **self-diagnosing and proof-gated self-repairing** execution pipeline that can recover interrupted packets, reviewer runs, claims, worktrees, and queue metadata **without deleting unique work, stealing a live owner's lock, forging review acceptance, or bypassing the existing dispatcher**. "Bug-free" is an engineering objective, not a guarantee. Every automatic action requires an explicit safe predicate, bounded idempotence, a verified receipt, and a recovery route when the action itself fails.

**Do not create a second dispatcher, reviewer, owner registry, review gate, worktree finisher, queue parser, or unconditional daemon.** Existing single authorities are:

- `task_packet_contract.py`: packet semantics and dependency identity.
- `dispatch.py`: fetched-main eligibility, lock conflicts and exclusive claim.
- `workflow_control.py`: short-lived claim mutex and trace.
- `workstream.py`, `land_main.py`, `branch_hygiene.py`: owner continuation, guarded landing and proven retirement.
- `paired_review_runner.py`, `paired_review_host_validation.py`, `review_outcome.py`: fresh independent review, immutable review evidence and receipt acceptance.
- `queue_frontier.py`, `worktree_backlog_census.py`, `check_ai_context.py`, `task_packet_index.py`, `process_feedback.py`: existing inspection, graph/root cause and bounded derived views.
- `legacy_claim_quarantine.py`, `review_claim_parking.py`: narrowly authorized legacy recovery, **not** general-purpose lock stealing.

The master is a **program of bounded packets**, not a single gigantic implementation that needs every workflow lock, changes all owners, and cannot be recovered. Its bootstrap is the only new P0-frontier packet. Later slices reuse their existing exact workstream IDs.

## Snapshot and constraints

At the investigated main tree, the task packet directory contains **429 active top-level packet Markdown files** (excluding README) and **536 archived packet Markdown files**. Those are file counts, not distinct managed workstreams, eligible claims, or accepted deliveries. On the same day, GitHub exposed **five** remote `dispatch-claims/*` refs (conflict-resolution merge provenance, resumed-worktree provenance, Operator elevation traversal, procgen authored-claim registry, bidirectional Dropbox review). A remote ref proves claim identity/presence, not host process liveness or abandoned ownership.

The prior host-bound W1 census dated October 17 measured 63 canonical worktree paths with 20 dirty-or-unique preservation-first and 65 invalid/recovery records in its then-current dispatcher snapshot. That is historical, **not** an October 24 host census. A new host capture is required before repairing or releasing any of those items.

Live `AGENT_AUTOMATION_BACKLOG.md` still contains time-bound statements about MC1 blocking LF1, earlier PF5 status, legacy queue counters, and index work as pending after some code landed. Refresh against exact current main in the implementing slice rather than repeating stale snapshot counts. The README Ready/Auto block is metadata, **not** dispatcher claimability.

The existing `paired_review_runner.py` (~4,229 lines), `paired_review_host_validation.py` (~2,877 lines), and `workstream.py` (~2,520 lines) contain substantial historical special-case recovery logic and pinned case-specific evidence. These are maintenance/convergence risks; line count alone is not a confirmed bug. New repair code must share general evidence/transition primitives and must not append further one-off case IDs into these files as the default.

## Master state machine

Exactly one projection of the underlying authorities, with orthogonal dimensions rather than conflated labels:

1. **Packet:** draft, ready, claimed, implementation-landed, review-pending, review-findings, accepted, explicitly human-gated, invalid.
2. **Ownership:** verified-live, verified-exited, parked-with-preserved-bytes, foreign/unknown, claim-only-interrupted, quarantined, no-claim.
3. **Evidence:** immutable original and current hashes, source-bearing commit span, genuine review outcome, validation selected tests/changed inputs, run IDs, snapshot health.
4. **Repair:** inspect-only, safe-auto, plan-and-fenced-apply, human-required, unavailable/unknown.

A deterministic incident key is `(root_workstream, failure_kind, pinned_claim_or_run_id, evidence_revision)`. One root blocker owns each incident. Duplicated child errors do not create parallel recovery claims. Subtasks may append evidence, never declare the root solved without the authoritative receipt.

## Recovery policy

| State / fault | Allowed autonomous action | Forbidden inference / mutation |
| --- | --- | --- |
| Stale generated README, report cache, or derivable metadata | Recompute from pinned authoritative packet tree; compare expected digest; publish via existing bounded updater after CAS/fresh preflight | Rewrite packet identity, complete a task, widen an unknown queue state |
| Interrupted authoring promotion or publication race | Retry the existing opt-in publisher with limited attempts and exact unchanged inputs | Force-push main; treat authored packet as claimed |
| Failed fetch, GitHub/network outage, validation-timeout, local resource exhaustion | Preserve exact checkpoint and trace, classify infrastructure; retry after bounded backoff/health recheck | Call timeout PASS; repeatedly run broad tests; discard original checkout |
| Review host prevalidation or receipt closeout failure | Reuse existing runner-specific plan/continuation for the **same claim/run**, revalidate fresh owner/scope, retain original evidence | Duplicate reviewer claim; mutate original immutable evidence; synthesize PASS |
| Review recorded as `findings` or `human_required` | Generate bounded correction candidate or explicit human gate; continue unrelated eligible work | Count archived review as accepted; bypass independent re-review |
| Clean interrupted worktree, owner proven exited | Exact-owner resume/checkpoint/finish under existing lifecycle; if future OR2 accepted, verified park-and-release execution occupancy | Infer exit from branch age or an expired remote timestamp |
| Dirty/untracked/ignored/LFS/unique-commit worktree | First obtain W1/W2 verified bytes and checksum preservation, then exact-owner fenced plan; otherwise preserve & escalate | Reset/clean/stash/delete/force; presume Git-tracked backup covers ignored/private bytes |
| Claim-only remote ref, foreign host, conflicting ref, unknown supervisor | Report immutable reason and park as protected; schedule no destructive action | Steal/delete claim or release its lock from stale age alone |
| Bootstrap supervisor/CI itself fails | Stateless read-only recovery command using stdlib + Git, test fixtures and pinned last-known-good instructions; independently scheduled remote CI status probe; report fault and stop mutations | Give self an exemption from claim/review/validation; start new overlapping writers |

Only deterministic non-destructive safe-auto classes are auto-applied without a separate human decision. Irreversible external transfer, credential access, remote-host enrollment, branch retirement of unique history, unknown-owner lock recovery, and subjective review require normal owner authorization or escalation.

## Program order (existing packets retained)

**R0: Bootstrap / fail-safe recovery orchestration** (`agent-pipeline-recovery-master-v1`): new bounded read-only `pipeline_recovery.py` snapshot/plan command, grounded in dispatcher audit + queue_frontier + verified W1 census, presenting one incident per root, exact safe next action, available/disjoint work and a machine-readable blocked/no-progress receipt. No writes to claims, refs, packets or worktrees. It can run from a clean disposable checkout or isolated host, not just the coordination root. Standard-library/offline last-good emergency entrypoint must be packaged with this first slice. Review adversarially before activating any mutator.

**R1: Review/finish strandings**: consume the existing active exact-owner recovery/correction packets `PAIRED_REVIEW_PREVALIDATION_CHECKOUT_RECOVERY_V1`, `PAIRED_REVIEW_DIRECT_TAIL_RECEIPT_CLOSEOUT_V1`, `AGENT_NEXT_EXECUTION_BOUNDARY_V1_REVIEW_CORRECTIONS_1` and active `REVIEW_AGENT_PAIRED_REVIEW_*.md` repair lineage. Resolve only authentic original claims and accepted review-gated successors. One reviewed repair primitive before any generic closeout automation.

**R2: Preserve/rescue worktrees**: reuse `WORKTREE_BACKLOG_DIRTY_AND_UNIQUE_PRESERVATION_V1`, `WORKTREE_BACKLOG_QUEUE_INVALID_CLAIM_TRIAGE_V1`, `WORKTREE_BACKLOG_OWNED_WORK_RECOVERY_V1`, `WORKTREE_BACKLOG_ARCHIVED_AND_DETACHED_RECONCILIATION_V1`, and `COORDINATION_ROOT_DIRTY_PREVENTION_RECOVERY_V1`; respect each original dependency, claimed packet and artifact boundary. W1's accepted-review status must be independently established before W2 descendants activate. No bulk `Status: complete` or branch disposal.

**R3: General recovery/liveness**: reuse `AGENT_ORPHAN_RECOVERY_OBSERVABILITY_V1` then independently reviewed `AGENT_ORPHAN_RECOVERY_FENCED_PARKING_V1`. Supervise only opted-in spawned processes; run token, host/boot/PID-start fencing, negative two-host tests. Non-supervised and foreign hosts remain unknown; do not convert old claims to leases by decree. Safely support `LIVE -> VERIFIED_EXITED -> PRESERVED -> PARKED` and verified resumption, never `UNKNOWN -> FREE`.

**R4: Close the loop / efficiency**: reuse `AGENT_BLOCKER_INBOX_PUBLISHER_V1` -> `AGENT_BLOCKER_CAPTURE_HOOKS_V1` -> `AGENT_BLOCKER_RECOVERY_RECONCILIATION_V1`; `AGENT_BOUNDED_TASK_CONTEXT_V1`, `AGENT_VALIDATION_EVIDENCE_FRESHNESS_V1`; and the four `AGENT_LONGFORM_*` packets in their pre-existing dependency order. Blocker inbox is publication/notification, not claim authority; longform is bounded invocation, not another dispatcher.

**R5: Optional/adjacent visualization and remote worker**: `AGENT_MISSION_CONTROL_DATA_MODEL_V1` and later MC UI remain separate optional presentation/adapters; `ULTRA_CODEX_PACKET_WORKER.md` is a separate remote execution host with external credentials/authority and must not be an implicit master bootstrap dependency. `WORKTREE_SEEDBOX_TEMP_STORAGE_FEASIBILITY_V1` remains explicit manual/read-only feasibility only.

**Already landed or historical:** do not re-open `AGENT_TASK_DISPATCH`, `AGENT_REVIEW_PIPELINE`, `AGENT_GODOT_VALIDATION_TRUTH_GATE`, `AGENT_WORKSTREAM_CLOSEOUT_PREFLIGHT`, `AGENT_PROCESS_FEEDBACK_LEDGER`, queue reconciliation and earlier fixed PF4/PF5 cycles as if unimplemented. Preserve their archived identities and correction history. Refresh docs whose narrative describes old states rather than rewriting historical packets.

This is logical consolidation: all named existing packet identities and their mandatory paired reviewers remain the execution ledger. **No deletion, retitling, supersession or status/lock/dependency editing of an already-claimed, archived, review-findings or ambiguously-owned packet.** Candidate merges of unclaimed duplicate scope require exact-ID audit and a separate guarded packet migration, paired preflight, proof of zero lost dependency edges, and a clean main publication.

## Autonomy without self-stranding

- Bootstrap packet has `Priority: P0`, `Depends on: none`, and a new narrow `pipeline-recovery-bootstrap` lock. Its source surface is a new read-only adapter + tests + this master spec, not a simultaneous rewrite of `dispatch.py` or the reviewer. Claim it **by exact ID** through the existing dispatcher after it has been promoted, regardless of lexicographic P0 ordering. Do not override active locks.
- Existing packet series are **not** all raised to P0. Front-run only R0, then execute shortest proved root-unblocking slice while allowing independent gameplay/art work to proceed. Record every deferred root cause and owner.
- A fail-closed off-path rescue exists before core changes: stable branch/PR and pinned main + fixture scripts, with GitHub Actions health reporting; it cannot magically resurrect lost host-local bytes.
- Every step must be restartable from a persistent journal and current immutable inputs; re-run means no-op or verified continuation. Mutation requires an exact fresh revision/owner token and dry-run diff, never a broad unconditional repair pass.
- Automatic retry budget applies per exact failure fingerprint; no infinite correction packet spawning. Repeated identical failures switch to `ESCALATED` while unrelated claimable work remains available.
- One outside observer must be able to say `HEALTHY`, `DEGRADED/PROTECTED`, or `UNAVAILABLE` with last healthy main SHA and reason; the observer cannot mark the actual reviewer/dispatcher healthy by fiat.
- Reversibility: retention of original refs, two-phase bytes-first preservation, CAS commits, after-action readback, independent paired review, and non-force main publication. If all verification paths fail, preserve ownership and stop, **never guess an unlock**.

## Acceptance measures

1. Exact test fixture: duplicate remote claims, two-host concurrent ownership, PID reuse/host reboot, clean/dirty/ignored/symlink/LFS/unique-head recovery, missing review checkout, malformed/fake PASSED receipt, true `findings`, missing authoring input, coordinator-root dirty, failed fetch, disk-full partial snapshot, interrupted publication, changed main, self-crash between plan/apply and untrusted event injection.
2. Zero lost unique file bytes, zero wrongly released live/unknown locks, zero duplicate claimed writers, zero falsely accepted review outcomes in the entire adversarial matrix.
3. Every eligible root blocker has exactly one classification, source revision, named current owner and actionable next safe step; unknown must be reported rather than silently cleared.
4. Read-only bootstrap produces the same ordered incident/queue plan on two identical snapshots and makes **no** branch/ref/packet/worktree mutation. At least one proven disjoint eligible workstream is shown when the targeted recovery is blocked; otherwise an explicit no-safe-frontier receipt.
5. Full canonical targeted authoring, agent unit/integration, task index and AI-context checks. Later mutating slices require real isolated Git remote races, interrupted-run durability and fresh independent reviews.
6. Measure per week from genuine receipts: implementation-landed rate, independently `passed` rate, median time from landing to accepted review, review recovery overhead, stranded-owner age **with liveness confidence**, claimable frontier count, repeated identical repairs, validation time/coverage. Never infer acceptance from archived count.
7. Demonstrate master bootstrap recovering from its own simulated crash using the separate unchanged emergency instructions and pinned evidence, with no privilege escalation.

## Scope / document drift check

When any existing program doc conflicts with current repo/receipt status, keep the old historical observation labeled by SHA and date, add a current measured state only after an exact audit. Candidate drift sources: `AGENT_AUTOMATION_BACKLOG.md`, `AGENT_CODEX_EXECUTION_PIPELINE_HARDENING_V1.md`, `AGENT_PIPELINE_FEEDBACK_IMPROVEMENTS_V1.md`, `AGENT_WORKSTREAM_LIFECYCLE.md`, `AGENT_MISSION_CONTROL_TUI_V1.md`, `task_packets/README.md`, `CURRENT_STATE.md`, `FILE_INDEX.md`. Do not manually edit the generated Ready/Auto block; use its current owner.

## Safe next execution

1. Merge the complete master program/implementation/review authoring package only after validating scoped publication and rebasing onto current main; check whether the requested Authoring chat URL has been supplied.
2. Trigger normal `packet_authoring_handoff.py` opt-in promotion of **the two paired bootstrap packets only**, then confirm both are ready/auto on fetched main. CI authors only; it does not claim.
3. Use `python3 custodian/tools/agent/dispatch.py audit --json`, then `python3 custodian/tools/agent/dispatch.py claim agent-pipeline-recovery-master-v1 --agent codex` from an authorized clean local coordination checkout, never from GitHub/ChatGPT alone.
4. Implement R0 and validate, land to main and run its **fresh-context** paired review; if nonpassing, capture bounded findings/corrections rather than reporting acceptance. Only after independent PASS may R1+ repair applications operate.
