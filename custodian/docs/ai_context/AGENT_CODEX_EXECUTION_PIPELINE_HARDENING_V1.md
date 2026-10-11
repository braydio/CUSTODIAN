# CUSTODIAN · Codex Execution Pipeline Hardening V1

**Status:** Authoring authority, implementation not yet claimed or accepted.  
**Program:** `agent-codex-execution-efficiency-v1`  
**Baseline:** Current main snapshot at `2ffbbec13d55a939096750d059602ea56047cae3` (2026-10-11).  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1

## Scope and source evidence

The user's October 11, 2026 Codex conversation export has 90,686 lines and 6,774,898 bytes. It includes multiple implementation/review pairs, including Awakening interactible Asset V2, PF1 feedback ledger, PF2 validation attribution, PF3 Godot truth gate and correction, NPA Showcase, and more. This was not all idle execution; the audit separates useful implementation from runner recoveries and repeated validation. In the exported trace, the coordinator was directed to implement the *next* packet but crossed into multiple unrelated pairs. It repeatedly printed massive status/AGENTS dumps, waited for validation, and hit false review-closeout blockers. Do not treat this export as proof of host-resource usage or the total elapsed wall-clock time for any one packet.

Concrete occurrences in the export:
- `paired_review_runner: BLOCKED: Codex exited 0 without durable review state` appears for multiple independent reviews.
- `fatal: path 'origin/main:<SUMMARY>.md' does not exist in 'origin/main'` appears for feedback ledger, Godot truth gate, Crèche Console and NPA Showcase reviews.
- The long dump of all root `*_CLAUDE_SUMMARY.md` handoffs and `cat AGENTS.md; cat custodian/AGENTS.md; cat CURRENT_STATE.md; cat <packet>` inflate context.
- Broad validation sweeps get rerun after synchronization as manifest/main advances, with insufficient input-difference attribution.

Static current-main bug: `paired_review_runner.py` obtains `summary_matches` from `git grep -l ... origin/main -- '*_CLAUDE_SUMMARY.md'`, which can return `origin/main:<path>`. Later `git show f'origin/main:{summary_path}'` constructs `origin/main:origin/main:<path>`. It also chooses the first summary text mention rather than verifying the exact review summary identity, and silently suppresses an unsuccessful post-exit `git fetch`. These are specific falsifiable defects, not a general permission to weaken review rules.

## Ordered implementation and independent reviews

| Order | Existing/new | Implementation workstream | Packets | Dispatch |
| --- | --- | --- | --- | --- |
| EH1 | refresh existing PF5 | `agent-paired-review-coordinator-boundary-v1` | `AGENT_PAIRED_REVIEW_COORDINATOR_BOUNDARY_V1.md` + `REVIEW_AGENT_PAIRED_REVIEW_COORDINATOR_BOUNDARY_V1.md` | ready/auto P0 |
| EH2 | new | `agent-next-execution-boundary-v1` | `AGENT_NEXT_EXECUTION_BOUNDARY_V1.md` + `REVIEW_AGENT_NEXT_EXECUTION_BOUNDARY_V1.md` | ready/auto P0, depends on accepted EH1 review |
| EH3 | new | `agent-bounded-task-context-v1` | `AGENT_BOUNDED_TASK_CONTEXT_V1.md` + `REVIEW_AGENT_BOUNDED_TASK_CONTEXT_V1.md` | ready/auto P1, depends on accepted EH2 review |
| EH4 | new | `agent-validation-evidence-freshness-v1` | `AGENT_VALIDATION_EVIDENCE_FRESHNESS_V1.md` + `REVIEW_AGENT_VALIDATION_EVIDENCE_FRESHNESS_V1.md` | ready/auto P1, depends on accepted EH3 review |

All packet paths are relative to `custodian/docs/ai_context/task_packets/`. Reviews remain dependent on the matching implementation and require fresh context and post-land provenance. The following order is recommended but the dispatcher owns actual eligibility and locks. Future reviews with material defects may introduce correction cycles that must be accepted before successor execution; do not infer that an archived review marked complete necessarily means its reviewed implementation passed independent acceptance when the receipt is `findings`.

## Engineering boundaries

1. **Review completion and coordinator Git ownership (EH1/PF5).** The runner is the only review orchestrator. Fix exact-summary Git lookup, positive review identity/receipt checks, explicit fetch failure, and idempotent post-exit recovery. In restricted worktrees, coordinator does authorized Git metadata work, reviewer supplies bounded independent evidence; no second finisher, no self-review or free reviewer Git write.
2. **Execution control (EH2).** Normal 'next packet' means one implementation + mandatory paired review. Multi-packet execution requires `continuous-chain`, explicit positive max-pair budget and scope. A user-named dependency DAG remains authorized only to fulfill its named goal; no unrelated queue hopping. At every pair, present compact progress and persist exact SHA/provenance.
3. **Context economy (EH3).** Replace routine all-summary grep and unconditional full document dumps with a read-only, bounded, SHA-keyed navigation card and exact source-range drilldowns. New worktrees and independent review contexts must still read mandatory original AGENTS and authority sources; no machine-generated summary supersedes them. Existing Repomix and graph tooling stay optional.
4. **Validation-evidence provenance (EH4).** Fingerprint all defensibly relevant inputs and explain changed-tree staleness, unknowns and rerun rationale. Prior green output may guide focused review but never substitutes for required canonical `run_validation.py` or `workstream.py finish` post-sync green reports.

## Measures to collect during implementation

Baseline per exact workflow: false BLOCKED outcomes after confirmed review closeout; minutes spent in paired-review launch/recovery versus independent review; accidental extra implementation claims from single-pair commands; output lines/bytes emitted before first useful edit; duplicate entire-doc reads; changed-tree reruns with unexplained invalidation; failed/timeout/skipped tests and exact selected owner; success/failure of final archival/summary/ref synchronization. Keep diagnostic payload concise and redact secrets. Report before-and-after from controlled fixtures or valid run artifacts, not estimates from unstructured terminal scrollback.

## Non-goals

No changes to Godot game balance, runtime gameplay, visual art, Asset Pipeline V2, ULTRA worker design, dispatcher remote claim-ref semantics, root checkout preservation, LFS network hydration policy, paired-review independence or final validation approval rules. No new daemon, scheduler or broad LLM observability service.

## Provenance and documentation drift

The earlier `AGENT_PIPELINE_FEEDBACK_IMPROVEMENTS_V1.md` still presents PF5 as conditional draft/manual. This addendum **supersedes only PF5 scheduling state and its sharpened scope**, not the PF1-PF4 historical outcomes or their completed packet records. EH1's source-level double-prefix failure and user approval satisfy the planning gate; the read-only Git denial fixture remains a mandatory *implementation* reproduction before any privilege-boundary mutation. Update the earlier program document's PF5 status reference only if explicitly authorized by the same scoped publication; do not rewrite history or mutate previously archived packets. The Ready/Auto block in `task_packets/README.md` is generated, not claim authority. Dispatch status/index correctness is to be verified after landing.

**Next exact claim:** `agent-paired-review-coordinator-boundary-v1` through the normal dispatcher after publication, assuming no newer conflicting claim/ref.
