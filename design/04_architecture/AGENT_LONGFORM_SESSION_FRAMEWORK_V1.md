# Agent Longform Session Framework V1

Status: **planning / not implemented**. Reviewed `main@85cabcfe6aa546fe0eb97d6bc5650c02277bb7d8` (2026-10-13; reconciled after PR #70). Source: October 12, 2026 transcript-reconciled 15-packet audit; 12 attempted, 9 landed, three unresolved. Authoring Chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62.

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

Store owner-private, gitignored evidence in `$(git rev-parse --git-common-dir)/custodian-longform/<id>/`: fsync+atomic `session.json` snapshot, append-only sequenced/hash-linked redacted `events.jsonl`, immutable per-claim receipts, sanitized capped child Codex JSONL/stderr, and a `RECOVERY.md` with exact branch/worktree/claim/review IDs. Event identities include executor, actual model when evidenced (otherwise unknown), session/child/claim IDs, SHA, validation selection and source hashes. Never infer executor from required legacy `*_CLAUDE_SUMMARY.md` filename. Rebuild state on resume from events plus revalidated live Git/RunTrace; never trust a mutable summary alone. Use supervisor `flock`, exact process identity, bounded claim backoff. Never delete locks, force reset/stash/clean, terminate live/foreign processes, steal claims, auto-park foreign claims, or erase untracked/user files. OR1/OR2 pending work owns future orphan fencing; this supervisor fails closed until its reviewed authority exists.

## Operational gates

1. **Preflight:** verify checkout and clean/dirty/diverged state, fetched main, dispatch audit and active/ambiguous claims, Codex CLI supported flags, disk/RAM/Godot single-job budget, review preflight, named scope and requested budgets. Dirty root is protected; root sync may remain pending, never forced.
2. **Claim:** exact dispatcher receipt/branch/worktree/run provenance verified; stale `last-claim` is never enough. Claim mutex busy -> bounded safe retry/audit, then blocked outcome. Never duplicate claim.
3. **Execute:** one fresh bounded implementation Codex subprocess per packet in its claimed worktree; use bounded context pack when available, avoid giant AGENTS/CURRENT_STATE dumps and repetitive media. Preserve raw logs privately with redaction/limits.
4. **Validate:** focused owned tests first; actual packet-specific end-to-end and Moment Forge checks remain required (packet #8 sidearm red despite 51/51 intermediate). The canonical final changed-file suite must be fresh and fully passing: failures, timeouts, skips, uncovered files or zero tests are red. Triage/baselines label cause but never waive. No invented timeout increase.
5. **Finish:** only `workstream.py finish` manages landing; supervisor independently verifies origin/main reachability and archival; safe fast-forward root sync or durable `ROOT_SYNC_BLOCKED`. No force operations.
6. **Review:** preflight writable Git common metadata and Godot import/cache **before** reviewer claim. Launch exact `paired_review_runner.py` fresh-context review. Findings, no selected tests, post-exit recovery and sandbox errors stay not accepted. Preserve exact existing claim and evidence, no fresh duplicate claim.
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

## Implementation sequence

**LF1** `agent-longform-session-core-v1`: real command and skill, bounded session engine, fsynced event ledger, verified claim/land status, safe stop/resume.

**LF2** `agent-longform-review-and-gate-hardening-v1`: reviewer environment preflight, zero selected, exact recovery, manual/human conjunction, end-to-end acceptance. Integrate reviewed OR1/OR2 / paired review coordinator rather than parallelizing them.

**LF3** `agent-longform-validation-economy-v1`: owner-aware explainable test planning and measured fanout while retaining fail-closed canonical changed-file acceptance. Reuse validation evidence freshness/triage.

**LF4** `agent-longform-telemetry-and-standard-adoption-v1`: native JSONL provenance/tokens/cost visibility, low-volume export, common receipt adapters for standard tasks after reviews.

Each slice requires focused mock/bare-repo failure-injection tests, exact manifest ownership, full changed-file closeout and fresh paired review. The eight packets are staged `draft/manual` pending live authoring preflight, explicit promotion and dispatcher claim; the current authoring chat URL is recorded. Do not treat this branch as production runner.

## Reconciliation against current main

Compared PR #70 with `origin/main@85cabcfe6aa546fe0eb97d6bc5650c02277bb7d8`. The intervening main changes concern the Ritualant planning lane; no execution, dispatch, paired-review or validation owner API changed. The live owners remain `dispatch.py`, `workstream.py`, `run_trace.py`, `paired_review_runner.py`, `next_execution_boundary.py` and `run_validation.py`; this framework delegates to them and creates no competing claim/acceptance authority.

OR1/OR2 remain the authoritative future orphan-supervision/recovery series. Read-only reconciliation found MC1 on current main as `draft/manual`, while `dispatch.py audit` classifies it as `claimed` solely because `origin/agent/agent-mission-control-data-model-v1` exists; the same audit reports OR1 blocked by `agent-workflow` held by MC1. There is no remote `dispatch-claims/agent-mission-control-data-model-v1` ref. Its attached worktree is behind main and has two untracked `.uid` files. RunTrace `20261012T050753Z-d21e8fbdf9fb` records a direct start with null packet/agent, then `remote_claim_released` and `start_completed`; the branch points at `59a1176`, an ancestor of reconciled main `85cabcfe`. Thus the live dispatcher treats the retained branch as ownership, but the evidence does not show a current dispatcher claim or active process. This is stranded/retained ownership and must remain untouched until its owner/recovery path resolves it; LF1 must not bypass its lock. The validation-evidence-freshness packet remains dependency-gated behind bounded-task-context. LF1 remains independently specified and fails closed on ambiguous/orphan ownership; LF2 and LF3 must integrate the reviewed owners if they land before those slices execute, and must not duplicate their authority. These are live queue observations, not fabricated packet dependencies; re-check through `dispatch.py audit` at promotion/claim time.
