# Agent Longform Session Framework V1

Status: **planning / not implemented**. Reviewed `main@029c31b0396842bc566a5616c46ab03c0696ad80` (2026-10-13; reconciled after PR #70). Source: October 12, 2026 transcript-reconciled 15-packet audit; 12 attempted, 9 landed, three unresolved. Authoring Chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62.

## Contract and entrypoint

Use **one durable supervisory session over isolated per-packet Codex processes**. The supervisor may budget, launch, checkpoint, audit and report, but MUST NOT duplicate or bypass `dispatch.py` claim authority, `workstream.py finish` landing, `paired_review_runner.py` independent review, existing `RunTrace`, `next_execution_boundary.py` routing, `run_validation.py` acceptance, human review, or Asset Pipeline V2.

Once LF1 is implemented and independently accepted, the intended shell interface is:

```bash
scripts/custodian-longform start --max-attempts 3 --max-pairs 3 --max-minutes 180 --general-next
scripts/custodian-longform status --latest
scripts/custodian-longform resume --session <id>
scripts/custodian-longform stop --session <id> --reason operator-request
scripts/custodian-longform export --session <id> --format json
```

Corresponding Codex skill: `$custodian-longform`; a thin wrapper over the same CLI, not a second conversational scheduler. **Neither command is installed by this design change.** Default bounded invocation when explicitly requested: 3 attempted implementations / 3 accepted pairs / 180 active wall minutes. Named handoff sequence by default; global queue only when explicitly `--general-next`. The real `start` launches and supervises a Codex child, not merely creates metadata. `--plan` never claims or launches.

## Counting and independent evidence

An *attempt* increments exactly once on a verified dispatcher implementation claim, before coding, and remains consumed when later parked, blocked, partial or human-gated. Resuming the same verified claim never increments it twice. *Landed* requires SHA reachability from fetched `origin/main`, archived complete packet and finish evidence. *Accepted* additionally requires exact passed fresh paired review, or a required recorded manual disposition, or a documented `Review:none` exemption. A merely green focused test, archived prose summary, zero-selected review, review runner error, or unapproved visual does not count. Pair budget counts accepted pairs; attempt and time budgets independently bound runaway sessions. Always render attempted/landed/accepted/blocked/partial/human_required/unattempted separately. No review findings or unresolved active pair may be skipped to an unrelated packet to manufacture progress.

## Durable state and recovery

Store owner-private, gitignored evidence in `$(git rev-parse --git-common-dir)/custodian-longform/<id>/`: fsync+atomic `session.json` snapshot, append-only sequenced/hash-linked redacted `events.jsonl`, immutable per-claim receipts, sanitized capped child Codex JSONL/stderr, and a `RECOVERY.md` with exact branch/worktree/claim/review IDs. Event identities include executor, actual model when evidenced (otherwise unknown), session/child/claim IDs, SHA, validation selection and source hashes. Never infer executor from required legacy `*_CLAUDE_SUMMARY.md` filename. Rebuild state on resume from events plus revalidated live Git/RunTrace; never trust a mutable summary alone. Use supervisor `flock`, exact process identity, bounded claim backoff. Never delete locks, force reset/stash/clean, terminate live/foreign processes, steal claims, auto-park foreign claims, or erase untracked/user files. OR1/OR2 own orphan observation/fenced parking, and the existing paired-review findings-closeout, Godot-cache-access, same-run-continuation and coordination-root-guard workstreams own their own maintenance mechanisms. These implementations may land before their independent reviews pass. The supervisor differentiates implemented from independently accepted and cannot duplicate an unaccepted authority.

## Operational gates

1. **Preflight:** verify checkout and clean/dirty/diverged state, fetched main, dispatch audit and active/ambiguous claims, Codex CLI supported flags, disk/RAM/Godot single-job budget, review preflight, named scope and requested budgets. Dirty root is protected; root sync may remain pending, never forced.
2. **Claim:** exact dispatcher receipt/branch/worktree/run provenance verified; stale `last-claim` is never enough. Claim mutex busy -> bounded safe retry/audit, then blocked outcome. Never duplicate claim.
3. **Execute:** one fresh bounded implementation Codex subprocess per packet in its claimed worktree; use bounded context pack when available, avoid giant AGENTS/CURRENT_STATE dumps and repetitive media. Preserve raw logs privately with redaction/limits.
4. **Validate:** focused owned tests first; actual packet-specific end-to-end and Moment Forge checks remain required (packet #8 sidearm red despite 51/51 intermediate). The canonical final changed-file suite must be fresh and fully passing: failures, timeouts, skips, uncovered files or zero tests are red. Triage/baselines label cause but never waive. No invented timeout increase.
5. **Finish:** only `workstream.py finish` manages landing; supervisor independently verifies origin/main reachability and archival; safe fast-forward root sync or durable `ROOT_SYNC_BLOCKED`. No force operations.
6. **Review:** preflight read-only shared Git metadata and the reviewed least-privilege CUSTODIAN Godot cache/job-budget access **before** reviewer claim. Launch the exact `paired_review_runner.py` fresh-context review. An administratively concluded `findings` or `human_required` outcome is NOT an accepted PASS. Recover an exact previous run only with the separately reviewed same-claim continuation authority, a genuinely fresh reviewer decision and canonical summary/receipt; a coordinator green report alone does not decide PASS. Preserve existing claim and evidence; no duplicate claim.
7. **Human:** where required, publish explicit source Authoring chat and Dropbox manifest with reviewer questions; **both** subjective approval and technical green are necessary (packet #9 visual gate + 70/1 timeout/1 skip). Cleanup only after verdict. No automatic general-next on human gate.
8. **Checkpoint:** flush ledger before another claim. Stop on uncertain ownership, unresolved review/human gate or violation. Preserve partial work, count attempt. Cooperative stop/resume with exact provenance.
9. **Usage:** collect native Codex JSONL delta/cumulative token and cache fields without double counting; unknown values are null, not zero. Distinguish wall time/tool elapsed, compactions, retries, review overhead, tokens per *accepted* pair. Redact prompts/secrets.
10. **Standard adoption:** after LF1–LF3 fresh reviews pass, reuse pure receipts in ordinary single-pair `custodian-next` without altering its default budget, claim/review rights or validation policy.

## Explicit 2026-10-12 failure coverage

| Incident | Required negative control |
|---|---|
| False 7/9 landed count; Broken Warrant preserved | claim 9, land 6, never silently land failed attempt |
| Review Git/Godot permissions and zero selected | preclaim worktree permission probe; zero-selected red; original review recovery |
| Shared manifest fanout + procgen timeouts | deterministic owner-explain plan, no skip/baseline waiver |
| Sidearm real-scene failure after 51/51 | packet-required end-to-end scenario prevents finish |
| Archive human gate AND red sweep | two independent conjunctive gates |
| Reviewer R0-01 finding after green 38/38 | findings not passed; bounded correction lineage |
| Root tracked edits and 18 commits behind | preserve bytes; root-sync pending, no reset |
| Misleading CLAUDE summary naming | explicit Codex provenance; no bulk rename |
| Context compactions and output flood | minimal context, bounded stdout, fresh child per packet |
| Busy dispatcher/stale claim | exact receipt and bounded retry, no lock theft |
| Unknown native tokens | null/unknown; deduplicate cumulative events |
| Abrupt worker death | preserve original branch, owner/run/evidence before resume |


## Bounded maintenance and deadlock recovery (planned, not installed)

**Read-only first.** LF1 shall expose a maintenance status/plan for a stalled longform session: exact owner/lock, run ID, process/lease evidence, remote branch/claim, main and worktree SHAs, packet status, review outcome, dependent packet DAG, hashed dirty-file preservation evidence, validated reports and recommended next action. No `--force-unlock`, implicit apply, or unrestricted workflow bypass. Inactive PID or old branch alone is not abandonment. An unknown/foreign/live owner remains protected. A denied shell permission stops the operation, rather than triggering an alternate command.

| Failure / flow | Existing owner (reuse) | Non-negotiable gate |
|---|---|---|
| Blocking review findings, human decision | `agent-paired-review-findings-closeout-v1` and `paired_review_runner.py recover-closeout` | Conclude original run administratively, never write target PASS. Accepted-review dependencies require independently verified passed receipt; bounded correction lineage may use verified findings IDs. |
| Godot reviewer cache and shared job capacity | `agent-paired-review-godot-cache-access-v1` | Writable *narrow* cache, real shared Godot budget and lock, reviewer Git metadata still read-only. |
| Ephemeral reviewer exits before verdict | `agent-paired-review-same-run-continuation-v1` | Same original claim/run/worktree and pinned target; new *independent* reviewer context and actual reviewer-authored outcome/summary, not recreated prior model session. Previously green raw reports (including ambient's eight exact-seed reports) are reusable only with proven identical identity/coverage/freshness. |
| Orphaned executor / dirty UID sidecars | OR1 observability and OR2 fenced parking | No implicit lease release or branch retirement. Exact-hash preservation, protected owner, explicit accepted recovery authority. |
| Dirty persistent checkout | `coordination-root-dirty-prevention-recovery-v1` and `persistent_checkout_sync.py` | Read-only default; never reset, clean, stash, force-sync or delete user files. |
| Repair needs a lock held by the very broken review | The existing findings-closeout packet's isolated maintenance exception | User-approved, one-time, auditable narrow maintenance branch; preserve original owner, independent technical review and ordinary validation. Exact shell permission must separately permit the proposed command. No wildcard allow list, no disguised `git worktree add` after denial, no general dispatcher lock override. |

**Maintenance handoff:** LF1 records blocked/partial attempts and emits a compact evidence-based plan. LF2 may *delegate* maintenance only after each underlying owner has landed **and passed its independent review**. LF2 must not create a parallel dispatcher/review/claim/lease implementation. An authorized maintainer exception operates outside normal queue claims under its explicit policy, creates its own reviewer evidence, and never touches the blocked owner or treats an exception as review acceptance. LF3 accounts for report freshness and machine-wide resource cost; LF4 exports permission/exception/owner and administrative-versus-accepted statuses without leaking secrets or fabricating cost.

**Permission boundary:** Conversation authorization is not an execution-tool permission grant. Request interactive approval for one exact maintenance command when needed; if denied, preserve all state and report the blocker, never try another route around it. A properly archived findings review may free a lock but must not release downstream accepted-review dependencies or authorize LF1 unless its own live dispatcher audit approves.

**Validation:** Synthetic two-clone original-run/foreign-owner cases, a protected dirty pair of .gd.uid sidecars, interrupted maintenance journal, exact permission-denied no-fallback, concluded-findings dependency remains red, real accepted PASS, reviewer cache lock sharing, same-claim fresh review with stale eight-report rejection, and root dirty/AHEAD preservation.

## Implementation sequence

**LF1** `agent-longform-session-core-v1`: real command and skill, bounded session engine, fsynced event ledger, verified claim/land status, safe stop/resume.

**LF2** `agent-longform-review-and-gate-hardening-v1`: reviewer environment preflight, zero selected, exact recovery, manual/human conjunction, end-to-end acceptance. Integrate reviewed OR1/OR2 / paired review coordinator rather than parallelizing them.

**LF3** `agent-longform-validation-economy-v1`: owner-aware explainable test planning and measured fanout while retaining fail-closed canonical changed-file acceptance. Reuse validation evidence freshness/triage.

**LF4** `agent-longform-telemetry-and-standard-adoption-v1`: native JSONL provenance/tokens/cost visibility, low-volume export, common receipt adapters for standard tasks after reviews.

Each slice requires focused mock/bare-repo negative controls, current complete changed-file validation, an exact reviewed landing and an independent paired review.

## Planning PR reconciliation, 2026-10-17

Inspected origin/main at 418a719d69c59ca8ace43031fc342a7f8edf557f. PR #70's original October 12 branch contains nine files already published in newer form on main. Merge this reconciliation on top of CURRENT main, preserving the existing LF1 ready/auto packet and exact Authoring chat. LF2–LF4 and their paired reviews are authorized for the existing opt-in targeted authoring handoff: they remain draft/manual until the preflight promotes both sides to ready/auto and updates the managed index. Ready/auto never overrides real dependencies, active locks, or the passed-review acceptance requirement.

The original review-agent-next-execution-boundary-v1 review is now archived with a genuine findings outcome, R0-01 unresolved, **not** a passing target receipt. The findings-closeout and Godot-cache-access implementations are archived complete, but their independent paired reviews remained active at inspection; their implementations must not be counted as accepted until exact passed receipts exist. The old claim that MC1 still holds the active LF1 lock is stale. Always run dispatch.py audit --json at claim time; no lock occupancy is inferred from old prose. The proposed Longform supervisor and maintenance plan commands are not installed by this planning merge. OR1/OR2, same-run continuation and root hygiene remain separate original workstreams; no duplicate packets are created.